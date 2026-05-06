extends Node
class_name Interactor

@export var interact_radius: float = 150.0
var _nearest_interactable: Interactable = null

func _process(_delta: float) -> void:
	if not is_instance_valid(get_parent()): return
	
	# 單次搜尋 (PhysicsShapeQueryParameters2D)
	var space_state = get_parent().get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = interact_radius
	query.shape = circle
	query.transform = get_parent().global_transform
	query.collision_mask = BitmaskManager.LAYER_INTERACTABLE
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var results = space_state.intersect_shape(query)
	var new_nearest: Interactable = null
	var min_dist: float = interact_radius
	
	for result in results:
		var collider = result.collider
		if collider is Interactable:
			var dist = (collider.global_position - get_parent().global_position).length()
			if dist < min_dist:
				min_dist = dist
				new_nearest = collider
				
	if _nearest_interactable != new_nearest:
		if is_instance_valid(_nearest_interactable):
			_nearest_interactable.hide_prompt()
		if is_instance_valid(new_nearest):
			new_nearest.show_prompt()
		_nearest_interactable = new_nearest

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_nearest_interactable):
		if event.is_action_pressed(_nearest_interactable.action_name):
			_nearest_interactable.trigger_interaction(get_parent())
			get_viewport().set_input_as_handled()
