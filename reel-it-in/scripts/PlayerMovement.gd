extends CharacterBody2D

@export var max_speed: float = 120.0
@export var acceleration: float = 100.0
@export var friction: float = 100.0
@export var player_joystick: Joystick

@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _anim_state = _anim_tree["parameters/playback"]

var _last_direction: float = 1.0 # 1 = right, -1 = left

func _ready() -> void:
	_anim_tree.active = true

func _physics_process(delta: float) -> void:
	var input_dir: float = player_joystick.position_vector.x

	if input_dir != 0:
		_last_direction = sign(input_dir)
		velocity.x = move_toward(velocity.x, input_dir * max_speed, acceleration * delta)
		_anim_tree.set("parameters/Row/BlendSpace1D/blend_position", _last_direction)
		_anim_state.travel("Row")
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		_anim_tree.set("parameters/Idle/BlendSpace1D/blend_position", _last_direction)
		_anim_state.travel("Idle")

	move_and_slide()
