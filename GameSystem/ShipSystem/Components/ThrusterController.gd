extends Node
class_name ThrusterController

@onready var ship_input: ShipInput = $"../ShipInput"
@onready var physics_body: RigidBody2D = $".."
@onready var ship: Ship = $"../.."

# 參數調整
const L_SCALE = 100.0 # 像素轉公尺，避免 Torque 數值遠大於 Force 造成梯度爆炸
const ITERATIONS = 40

func _physics_process(delta: float) -> void:
	if not is_instance_valid(ship_input) or not is_instance_valid(physics_body): return
	
	var virtual_thrusters: Array[Dictionary] = []
	var all_blocks = ship.blocks_container.get_children()
	
	# 取得當前全局質心 (CoM)
	var world_com = physics_body.global_transform.origin + physics_body.center_of_mass.rotated(physics_body.global_rotation)
	
	# 1. 建立虛擬推進器矩陣
	for block in all_blocks:
		if block is BlockBase and block.state_machine.is_built():
			_register_virtual_thrusters(block, virtual_thrusters, world_com)
			
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
	
	# 3. 最佳化分配 (Unbounded Gradient Descent)
	var N = virtual_thrusters.size()
	var a: Array[float] = []
	a.resize(N)
	a.fill(0.0)
	
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
			
		# 步驟 B: 針對力矩 (Torque) 進行投影 (嚴格滿足力矩需求)
		var current_T = 0.0
		var sum_T_sq = 0.0
		for i in range(N):
			current_T += virtual_thrusters[i].V.z * a[i]
			sum_T_sq += virtual_thrusters[i].V.z * virtual_thrusters[i].V.z
			
		if sum_T_sq > 0.0001:
			var err_T = current_T - E_req.z
			for i in range(N):
				a[i] -= err_T * virtual_thrusters[i].V.z / sum_T_sq
				
		# 步驟 C: 僅非負約束 (無上限限制)
		for i in range(N):
			a[i] = max(a[i], 0.0)
			
	# 4. 全局等比例縮放 (Global Scaling)
	# 為了維持力矩與力的比例，當任何組件超出極限時，縮放全體輸出
	var alloc_map = _group_allocations(virtual_thrusters, a)
	var global_max = 1.0
	for block in alloc_map:
		var allocs = alloc_map[block]
		var block_a = 0.0
		if block is ThrusterFixed:
			block_a = allocs[0].a
		elif block is ThrusterAngled:
			var v_l = Vector2.UP.rotated(deg_to_rad(-15.0)) * allocs[0].a
			var v_r = Vector2.UP.rotated(deg_to_rad(15.0)) * allocs[1].a
			block_a = (v_l + v_r).length()
		elif block is ThrusterRCS:
			var v_sum = Vector2.ZERO
			for al in allocs:
				v_sum += al.vt.dir * al.a
			block_a = v_sum.length()
		global_max = max(global_max, block_a)
		
	if global_max > 1.0:
		for i in range(N):
			a[i] /= global_max
			
	# 5. 推力應用
	_apply_allocations(alloc_map)

func _register_virtual_thrusters(block: BlockBase, list: Array[Dictionary], world_com: Vector2) -> void:
	var pos = block.global_position - world_com
	
	if block is ThrusterFixed:
		var F = Vector2.UP.rotated(block.global_rotation) * block.thrust_force
		var T = pos.cross(F) / L_SCALE
		list.append({ "block": block, "type": "fixed", "V": Vector3(F.x, F.y, T) })
		
	elif block is ThrusterAngled:
		var F_l = Vector2.UP.rotated(block.global_rotation + deg_to_rad(-15.0)) * block.thrust_force
		var T_l = pos.cross(F_l) / L_SCALE
		list.append({ "block": block, "type": "angled_l", "V": Vector3(F_l.x, F_l.y, T_l) })
		var F_r = Vector2.UP.rotated(block.global_rotation + deg_to_rad(15.0)) * block.thrust_force
		var T_r = pos.cross(F_r) / L_SCALE
		list.append({ "block": block, "type": "angled_r", "V": Vector3(F_r.x, F_r.y, T_r) })
		
	elif block is ThrusterRCS:
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
	
	var local_v = physics_body.global_transform.basis_xform_inv(lin_v)
	var desired_local_force = Vector2.ZERO
	
	# 平移需求
	if abs(input_move.x) > 0.01:
		desired_local_force.x = input_move.x * max_F * 0.8
	elif auto_brake:
		desired_local_force.x = clamp(-local_v.x * (max_F / 50.0), -max_F, max_F)
		
	if abs(input_move.y) > 0.01:
		desired_local_force.y = input_move.y * max_F * 0.8
	elif auto_brake:
		desired_local_force.y = clamp(-local_v.y * (max_F / 50.0), -max_F, max_F)
		
	var desired_force = physics_body.global_transform.basis_xform(desired_local_force)
	
	# 旋轉需求 (移除角度修正，僅保留阻尼)
	var desired_torque = 0.0
	if abs(input_rot) > 0.01:
		desired_torque = input_rot * max_T
	elif auto_brake:
		desired_torque = clamp(-ang_v * (max_T / 0.5), -max_T, max_T)
		
	return Vector3(desired_force.x, desired_force.y, desired_torque)

func _group_allocations(virtual_thrusters: Array[Dictionary], a: Array[float]) -> Dictionary:
	var alloc_map: Dictionary = {}
	for i in range(virtual_thrusters.size()):
		var vt = virtual_thrusters[i]
		var block = vt.block
		if not alloc_map.has(block):
			alloc_map[block] = []
		alloc_map[block].append({ "vt": vt, "a": a[i] })
	return alloc_map

func _apply_allocations(alloc_map: Dictionary) -> void:
	for block in alloc_map:
		var allocs = alloc_map[block]
		if block is ThrusterFixed:
			var amount = allocs[0].a
			if amount > 0.01:
				block.apply_thrust(physics_body, amount)
				
		elif block is ThrusterAngled:
			var a_l = allocs[0].a
			var a_r = allocs[1].a
			# 計算合成向量以獲得真實推力大小與 Gimbal 角度
			var v_l = Vector2.UP.rotated(deg_to_rad(-15.0)) * a_l
			var v_r = Vector2.UP.rotated(deg_to_rad(15.0)) * a_r
			var v_sum = v_l + v_r
			var total_a = v_sum.length()
			if total_a > 0.01:
				var gimbal = rad_to_deg(v_sum.angle_to(Vector2.UP))
				block.apply_thrust(physics_body, total_a, -gimbal)
				
		elif block is ThrusterRCS:
			var final_dir = Vector2.ZERO
			for alloc in allocs:
				final_dir += alloc.vt.dir.rotated(physics_body.global_rotation) * alloc.a
			var total_a = final_dir.length() / (block.thrust_force / block.thrust_force) # 這裡直接用長度即可
			if total_a > 0.01:
				block.apply_thrust(physics_body, final_dir.normalized(), total_a)
