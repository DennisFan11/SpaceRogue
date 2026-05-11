extends Node2D
class_name RayManager

## 管理雷達射線、標記與被標記的敵人

const RAY_LIFETIME: float = 1.0

var _tagged_enemies: Dictionary = {} # Node2D -> float (expire_time)
var _active_rays: Array[Dictionary] = [] # {line: Line2D, source: Node2D}

func _ready() -> void:
	DI.register("_ray_manager", self)

func _process(delta: float) -> void:
	# 清理過期的標記
	var current_time = Time.get_ticks_msec() / 1000.0
	var to_remove = []
	for enemy in _tagged_enemies:
		if not is_instance_valid(enemy) or current_time >= _tagged_enemies[enemy]:
			to_remove.append(enemy)
	for enemy in to_remove:
		_tagged_enemies.erase(enemy)
		
	# 更新射線起點與雷達同步
	var i = _active_rays.size() - 1
	while i >= 0:
		var item = _active_rays[i]
		var line = item.get("line")
		var source = item.get("source")
		if is_instance_valid(line) and is_instance_valid(source):
			line.set_point_position(0, source.global_position)
		else:
			_active_rays.remove_at(i)
		i -= 1
		


## 發射雷達射線
## origin: 發射起點 (global)
## direction: 方向向量 (不需要 normalized)
## max_length: 最大射程
func fire_radar_ray(source: Node2D, origin: Vector2, direction: Vector2, max_length: float, ray_color: Color = Color.GREEN) -> void:
	var space_state = get_world_2d().direct_space_state
	var dir_norm = direction.normalized()
	var target_pos = origin + dir_norm * max_length
	var query = PhysicsRayQueryParameters2D.create(origin, target_pos)
	
	# 碰撞層：敵人和牆體 (TileBlock)
	query.collision_mask = BitmaskManager.LAYER_ENEMY | BitmaskManager.LAYER_WALL
	
	var result = space_state.intersect_ray(query)
	
	var hit_pos = target_pos
	var hit_obj = null
	
	if result:
		hit_pos = result.position
		hit_obj = result.collider
		
	# 繪製射線 (Line2D)
	_create_visual_ray(source, origin, hit_pos, ray_color)
	
	# 建立標記
	if hit_obj:
		var name_to_display = hit_obj.name
		for child in hit_obj.get_children():
			if child is RadarTarget:
				name_to_display = child.display_name
				break
				
		if hit_obj.collision_layer & BitmaskManager.LAYER_ENEMY != 0:
			_create_tag(hit_pos, name_to_display, Color.RED)
			_tagged_enemies[hit_obj] = (Time.get_ticks_msec() / 1000.0) + RAY_LIFETIME
		elif hit_obj.collision_layer & BitmaskManager.LAYER_WALL != 0:
			_create_tag(hit_pos, name_to_display, Color.GREEN)
	else:
		# 無碰撞，顯示在射線末端
		_create_tag(target_pos, "無碰撞", Color.GRAY)

func _create_visual_ray(source: Node2D, from: Vector2, to: Vector2, color: Color = Color.GREEN) -> void:
	var line = Line2D.new()
	line.points = [from, to]
	line.default_color = Color(color, 0.0) # 從透明開始
	line.width = 10.0
	add_child(line)
	
	_active_rays.append({"line": line, "source": source})
	
	var tween = create_tween()
	# 快速淡入
	tween.tween_property(line, "default_color", Color(color, 1.0), 0.1)
	# 緩慢淡出
	tween.tween_property(line, "default_color", Color(color, 0.0), RAY_LIFETIME - 0.1)
	tween.tween_callback(func():
		var i = 0
		while i < _active_rays.size():
			if _active_rays[i].get("line") == line:
				_active_rays.remove_at(i)
				break
			i += 1
		line.queue_free()
	)

func _create_tag(pos: Vector2, text: String, color: Color) -> void:
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "[color=#%s]%s[/color]" % [color.to_html(false), text]
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	var container = Node2D.new()
	container.global_position = pos
	container.add_child(label)
	container.modulate.a = 0.0 # 從透明開始
	add_child(container)
	
	# 設定初始縮放
	var camera = get_viewport().get_camera_2d()
	if camera:
		container.scale = Vector2.ONE / camera.zoom
		
	# 稍微偏移避免重疊
	label.position = Vector2(-20, -20)
	
	# 標記時效，淡入淡出
	var tween = create_tween()
	# 快速淡入
	tween.tween_property(container, "modulate:a", 1.0, 0.1)
	# 緩慢淡出
	tween.tween_property(container, "modulate:a", 0.0, RAY_LIFETIME - 0.1)
	tween.tween_callback(container.queue_free)

func get_tagged_enemies() -> Array:
	return _tagged_enemies.keys()

func get_nearest_tagged_enemy(from_pos: Vector2) -> Node2D:
	var best: Node2D = null
	var min_dist_sq = INF
	for enemy in _tagged_enemies:
		if is_instance_valid(enemy):
			var d = from_pos.distance_squared_to(enemy.global_position)
			if d < min_dist_sq:
				min_dist_sq = d
				best = enemy
	return best
