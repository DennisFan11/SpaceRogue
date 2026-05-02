extends Node
class_name ThrusterController

@onready var ship_input: ShipInput = $"../ShipInput"
@onready var physics_body: RigidBody2D = $".."
@onready var ship: Ship = $"../.."

# 參數調整
const L_SCALE = 100.0 # 像素轉公尺，避免 Torque 數值遠大於 Force 造成梯度爆炸
const ITERATIONS = 20

var _target_heading: float = 0.0
var _heading_locked: bool = false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(ship_input) or not is_instance_valid(physics_body): return
	
	var virtual_thrusters: Array[Dictionary] = []
	var all_blocks = ship.blocks_container.get_children()
	
	# 1. 建立虛擬推進器矩陣
	for block in all_blocks:
		if block is BlockBase and block.state_machine.is_built():
			_register_virtual_thrusters(block, virtual_thrusters)
			
	if virtual_thrusters.is_empty(): return
	
	var max_F = 0.0
	var max_T = 0.0
	var sum_F_sq = 0.0
	for vt in virtual_thrusters:
		var force_mag = Vector2(vt.V.x, vt.V.y).length()
		max_F += force_mag
		max_T += abs(vt.V.z)
		sum_F_sq += force_mag * force_mag
		
	if max_F == 0.0: return
	
	# 2. 定義目標向量 E_req
	var E_req = _calculate_target_demand(max_F, max_T)
	
	# 3. 投影梯度下降最佳化 (Projected Gradient Descent)
	var N = virtual_thrusters.size()
	var a: Array[float] = []
	a.resize(N)
	a.fill(0.0)
	
	# 只針對 Force 計算學習率
	var lr = 1.0 / (sum_F_sq + 1.0)
	
	for step in range(ITERATIONS):
		# 步驟 A: 針對推力 (Force) 進行梯度下降
		var current_F = Vector2.ZERO
		for i in range(N):
			current_F += Vector2(virtual_thrusters[i].V.x, virtual_thrusters[i].V.y) * a[i]
			
		var err_F = current_F - Vector2(E_req.x, E_req.y)
		
		for i in range(N):
			var vt_F = Vector2(virtual_thrusters[i].V.x, virtual_thrusters[i].V.y)
			var grad_F = err_F.dot(vt_F)
			a[i] -= lr * grad_F
			
		# 步驟 B: 針對力矩 (Torque) 進行零空間投影 (嚴格強制力矩滿足需求，防止旋轉飄移)
		var current_T = 0.0
		var sum_T_sq = 0.0
		for i in range(N):
			current_T += virtual_thrusters[i].V.z * a[i]
			sum_T_sq += virtual_thrusters[i].V.z * virtual_thrusters[i].V.z
			
		if sum_T_sq > 0.0001:
			var err_T = current_T - E_req.z
			for i in range(N):
				a[i] -= err_T * virtual_thrusters[i].V.z / sum_T_sq
				
		# 步驟 C: 限制物理邊界
		for i in range(N):
			a[i] = clamp(a[i], 0.0, 1.0)
			
	# 4. 推力應用與還原
	_apply_allocations(virtual_thrusters, a)

func _register_virtual_thrusters(block: BlockBase, list: Array[Dictionary]) -> void:
	var pos = block.global_position - physics_body.global_position
	
	if block is ThrusterFixed:
		var F = Vector2.UP.rotated(block.global_rotation) * block.thrust_force
		var T = pos.cross(F) / L_SCALE
		list.append({ "block": block, "type": "fixed", "V": Vector3(F.x, F.y, T) })
		
	elif block is ThrusterAngled:
		# 左極限 (-15度)
		var F_l = Vector2.UP.rotated(block.global_rotation + deg_to_rad(-15.0)) * block.thrust_force
		var T_l = pos.cross(F_l) / L_SCALE
		list.append({ "block": block, "type": "angled_l", "V": Vector3(F_l.x, F_l.y, T_l) })
		# 右極限 (+15度)
		var F_r = Vector2.UP.rotated(block.global_rotation + deg_to_rad(15.0)) * block.thrust_force
		var T_r = pos.cross(F_r) / L_SCALE
		list.append({ "block": block, "type": "angled_r", "V": Vector3(F_r.x, F_r.y, T_r) })
		
	elif block is ThrusterRCS:
		# RCS 分解為四個方向的虛擬推進器 (以局部坐標為基準)
		var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		for d in dirs:
			var F = d.rotated(physics_body.global_rotation) * block.thrust_force
			var T = pos.cross(F) / L_SCALE
			list.append({ "block": block, "type": "rcs", "dir": d, "V": Vector3(F.x, F.y, T) })

func _calculate_target_demand(max_F: float, max_T: float) -> Vector3:
	var input_move = ship_input.get_movement_vector()
	var input_rot = ship_input.get_rotation_input()
	var auto_brake = ship_input.should_auto_brake()
	
	var lin_v = physics_body.linear_velocity
	var ang_v = physics_body.angular_velocity
	
	# 將全局線速度轉為相對於飛船的局部速度
	var local_v = physics_body.global_transform.basis_xform_inv(lin_v)
	var desired_local_force = Vector2.ZERO
	
	# 處理 X 軸 (左右平移與側滑煞車)
	if abs(input_move.x) > 0.01:
		desired_local_force.x = input_move.x * max_F
	elif auto_brake:
		desired_local_force.x = clamp(-local_v.x * (max_F / 100.0), -max_F, max_F)
		
	# 處理 Y 軸 (前後平移與前進煞車)
	if abs(input_move.y) > 0.01:
		desired_local_force.y = input_move.y * max_F
	elif auto_brake:
		desired_local_force.y = clamp(-local_v.y * (max_F / 100.0), -max_F, max_F)
		
	# 轉回全局受力方向
	var desired_force = physics_body.global_transform.basis_xform(desired_local_force)
	
	# 處理旋轉與姿態鎖定 (Heading Lock)
	var desired_torque = 0.0
	if abs(input_rot) > 0.01:
		desired_torque = input_rot * max_T
		_heading_locked = false
	else:
		if not _heading_locked and abs(ang_v) < 0.05:
			# 當角速度趨近於零且沒有輸入時，鎖定當前角度
			_target_heading = physics_body.global_rotation
			_heading_locked = true
			
		if _heading_locked:
			# 姿態鎖定模式：強力修正任何偏移
			var angle_diff = wrapf(physics_body.global_rotation - _target_heading, -PI, PI)
			var correction = -angle_diff * 5.0 - ang_v * 2.0
			desired_torque = clamp(correction * max_T, -max_T, max_T)
		elif auto_brake:
			# 純減速模式：只抵銷角速度
			desired_torque = clamp(-ang_v * (max_T / 1.0), -max_T, max_T)
		
	return Vector3(desired_force.x, desired_force.y, desired_torque)

func _apply_allocations(virtual_thrusters: Array[Dictionary], a: Array[float]) -> void:
	# 先按方塊聚合結果
	var alloc_map: Dictionary = {}
	for i in range(virtual_thrusters.size()):
		var vt = virtual_thrusters[i]
		var block = vt.block
		if not alloc_map.has(block):
			alloc_map[block] = []
		alloc_map[block].append({ "vt": vt, "a": a[i] })
		
	# 執行物理應用
	for block in alloc_map:
		var allocs = alloc_map[block]
		if block is ThrusterFixed:
			var amount = allocs[0].a
			if amount > 0.01:
				block.apply_thrust(physics_body, amount)
				
		elif block is ThrusterAngled:
			var a_l = allocs[0].a
			var a_r = allocs[1].a
			var total_a = max(a_l, a_r)
			if total_a > 0.01:
				# 根據左右推力極限的使用比例，反推出 Gimbal 偏移角度
				var ratio = a_r / (a_l + a_r) if (a_l + a_r) > 0 else 0.5
				var gimbal = lerp(-15.0, 15.0, ratio)
				block.apply_thrust(physics_body, total_a, gimbal)
				
		elif block is ThrusterRCS:
			var final_dir = Vector2.ZERO
			var max_a = 0.0
			for alloc in allocs:
				# 將局部方向轉為全局方向，因為 apply_thrust 預期全局推進方向
				final_dir += alloc.vt.dir.rotated(physics_body.global_rotation) * alloc.a
				max_a = max(max_a, alloc.a)
			if max_a > 0.01 and final_dir.length_squared() > 0.01:
				block.apply_thrust(physics_body, final_dir.normalized(), max_a)
