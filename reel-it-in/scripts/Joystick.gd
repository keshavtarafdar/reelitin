class_name Joystick
extends Control

@onready var knob: Sprite2D = $Knob
@onready var ring: Sprite2D = $Ring
var position_vector: Vector2 = Vector2.ZERO
var _is_pressing: bool = false
var center: Vector2

# Calculate center of joystick control based on size, put knob there
func _ready() -> void:
	center = size / 2.0
	knob.position = center
	ring.position = center

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_is_pressing = event.is_pressed()
	if event is InputEventMouseMotion and _is_pressing:
		knob.position = get_local_mouse_position()

func _process(delta: float) -> void:
	var knob_max_length = knob.get("max_length")
	
	var pos_offset: Vector2 = knob.position
	var distance: float = (pos_offset - center).length()
	var current_max_length: float = knob_max_length * scale.x
	
	# Normalize inputs which are outside of the joystick's range/ring
	if distance > current_max_length:
		knob.position = center + (pos_offset - center).normalized() * current_max_length
	
	# Smoothly slide back to center of ring
	if not _is_pressing:
		knob.position = knob.position.lerp(center, delta * 10.0)

	_calculate_vector()


func _calculate_vector() -> void:
	var knob_max_length = knob.get("max_length")
	var knob_dead_zone = knob.get("dead_zone")

	var diff: Vector2 = knob.position - center
	var current_max_length: float = knob_max_length * scale.x

	var output_vector := Vector2.ZERO
	if abs(diff.x) >= knob_dead_zone:
		output_vector.x = diff.x / current_max_length
	if abs(diff.y) >= knob_dead_zone:
		output_vector.y = diff.y / current_max_length

	position_vector = output_vector.clamp(Vector2(-1, -1), Vector2(1, 1))
