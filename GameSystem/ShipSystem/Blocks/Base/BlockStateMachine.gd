extends Node
class_name BlockStateMachine

enum State {
	BLUEPRINT,
	BUILDING,
	BUILT,
	DESTROYED
}

signal state_changed(old_state: State, new_state: State)

var current_state: State = State.BLUEPRINT
@onready var block: BlockBase = get_parent() as BlockBase

func _ready() -> void:
	_apply_state(current_state)

func transition_to(new_state: State) -> void:
	if current_state == new_state:
		return
		
	var old_state = current_state
	current_state = new_state
	
	_apply_state(new_state)
	state_changed.emit(old_state, new_state)

func _apply_state(state: State) -> void:
	if not block: return
	
	match state:
		State.BLUEPRINT:
			if block.visual:
				block.visual.modulate.a = 0.5
		State.BUILDING:
			if block.visual:
				block.visual.modulate.a = 0.8
		State.BUILT:
			if block.visual:
				block.visual.modulate.a = 1.0
			block.on_built()
		State.DESTROYED:
			block.on_destroyed()

func is_built() -> bool:
	return current_state == State.BUILT

func is_blueprint() -> bool:
	return current_state == State.BLUEPRINT
