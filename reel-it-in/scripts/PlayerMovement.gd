extends CharacterBody2D

@export var max_speed: float = 120.0
@export var acceleration: float = 100.0
@export var friction: float = 100.0
@export var player_joystick: Joystick
@export var winding: WindAndCast

@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _anim_state = _anim_tree["parameters/playback"]
@onready var animationPlayer = $AnimationPlayer
@onready var hook = get_node("Hook")

var _last_direction: float = 1.0 # 1 = right, -1 = left
var rod_power: float = 0.4 # How much a fishing rod can control a fish

func _ready() -> void:
	_anim_tree.active = true
	winding = $TouchArea
	# Tell the Hook node who the player is so it can reel back to us
	if hook:
		hook.player = self


func _physics_process(delta: float) -> void:
	boatMove(delta)
	castAndFish()
	reel_in()
	

func reel_in() -> void:
	var input_dir: float = player_joystick.position_vector.x
	if _anim_state.get_current_node()=="Fish" or _anim_state.get_current_node()=="Reel":
		if input_dir !=0:
			_anim_state.travel("Reel")
			hook.start_reel_in()
		else:
			_anim_state.travel("Fish")
			hook.stop_reel_in()
		if hook.get_current_state() =="INVISIBLE":
			set_to_idle()
		
			
	return

func castAndFish() -> void:
	if winding.isPressing and (_anim_state.get_current_node()=="Wind" or _anim_state.get_current_node()=="Idle"):
		if winding.facing == "right":
			_anim_tree.set("parameters/Wind/BlendSpace1D/blend_position", -1.0)
			_anim_state.travel("Wind")
			_last_direction = -1.0
		elif winding.facing=="left":
			_anim_tree.set("parameters/Wind/BlendSpace1D/blend_position", 1.0)
			_anim_state.travel("Wind")
			_last_direction = 1.0
	elif _anim_state.get_current_node()=="Wind":
		if winding.facing == "right":
			_anim_tree.set("parameters/Cast/BlendSpace1D/blend_position", -1.0)
			_anim_tree.set("parameters/Reel/BlendSpace1D/blend_position", -1.0)
			_anim_tree.set("parameters/Fish/BlendSpace1D/blend_position", -1.0)
			_anim_state.travel("Cast")
		elif winding.facing=="left":
			_anim_tree.set("parameters/Cast/BlendSpace1D/blend_position", 1.0)
			_anim_tree.set("parameters/Reel/BlendSpace1D/blend_position", 1.0)
			_anim_tree.set("parameters/Fish/BlendSpace1D/blend_position", 1.0)
			_anim_state.travel("Cast")
	#if not winding.isPressing and _anim_state.get_current_node() == "Cast" and (hook.get_current_state() == "INVISIBLE" or hook.get_current_state() == "DEBUG"):
		# Hook will read the launch vector directly from the Wind/TouchArea node
		#hook.start_cast()

func cast_animation_finished():
	_anim_state.travel("Fish")
	

func call_hook_cast():
	if hook:
		hook.start_cast()

func boatMove(delta: float) -> void:
	var input_dir: float = player_joystick.position_vector.x
	
	if _anim_state.get_current_node()=="Idle" or _anim_state.get_current_node()=="Row":
		if input_dir != 0:
			_last_direction = sign(input_dir)
			velocity.x = move_toward(velocity.x, input_dir * max_speed, acceleration * delta)
			_anim_tree.set("parameters/Row/BlendSpace1D/blend_position", _last_direction)
			_anim_state.travel("Row")
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			if _anim_state.get_current_node()!="Cast":
				_anim_tree.set("parameters/Idle/BlendSpace1D/blend_position", _last_direction)
				_anim_state.travel("Idle")

	move_and_slide()

func set_to_idle() -> void:
	# Helper used by the Hook when reeling completes.
	_anim_state.travel("Idle")
