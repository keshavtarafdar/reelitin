extends CharacterBody2D

@export var max_speed: float = 120.0
@export var acceleration: float = 100.0
@export var friction: float = 100.0
@export var player_joystick: Node

var _anim_tree: AnimationTree
var _anim_state
var _last_direction: float = 1.0 # 1 = right, -1 = left

func _ready() -> void:
	_anim_tree = $AnimationTree
	_anim_tree.active = true
	_anim_state = _anim_tree.get("parameters/playback")

func _physics_process(delta: float) -> void:
	var vel = self.velocity

	var input_dir = player_joystick.position_vector.x if player_joystick else 0.0

	if input_dir != 0:
		_last_direction = sign(input_dir)
		vel.x = move_toward(vel.x, input_dir * max_speed, acceleration * delta)
		_anim_tree.set("parameters/Row/BlendSpace1D/blend_position", _last_direction)
		_anim_state.travel("Row")
	else:
		vel.x = move_toward(vel.x, 0, friction * delta)
		_anim_tree.set("parameters/Idle/BlendSpace1D/blend_position", _last_direction)
		_anim_state.travel("Idle")

	self.velocity = vel
	move_and_slide()
