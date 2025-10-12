extends Sprite2D

@export var max_length: float = 15.0 # max drag length
@export var dead_zone: float = 5.0   # min drag to be recognized as input

var _parent_joystick: Node = null
var _is_pressing: bool = false

func _ready() -> void:
	_parent_joystick = get_parent()
	if _parent_joystick == null:
		push_error("Knob: Parent Joystick node not found!")

func _input(event: InputEvent) -> void:
	if not _is_pressing:
		return

	if event is InputEventMouseMotion:
		position = get_parent().get_local_mouse_position()

func _process(delta: float) -> void:
	var pos_offset: Vector2 = position
	var distance: float = pos_offset.length()
	var current_max_length: float = max_length * get_parent().scale.x

	if distance > current_max_length:
		position = pos_offset.normalized() * current_max_length

	if not _is_pressing:
		position = position.lerp(Vector2.ZERO, delta * 10.0)

	_calculate_vector()


func _on_touch_button_pressed() -> void:
	print("Joystick Pressed!")
	_is_pressing = true

func _on_touch_button_released() -> void:
	_is_pressing = false

func _calculate_vector() -> void:
	var diff: Vector2 = position
	var current_max_length: float = max_length * get_parent().scale.x

	var output_vector := Vector2.ZERO
	if abs(diff.x) >= dead_zone:
		output_vector.x = diff.x / current_max_length
	if abs(diff.y) >= dead_zone:
		output_vector.y = diff.y / current_max_length

	if _parent_joystick != null and "position_vector" in _parent_joystick:
		_parent_joystick.position_vector = output_vector.clamp(Vector2(-1, -1), Vector2(1, 1))
