extends CharacterBody2D

const COLLECTION_ID = "player_stats"

@export var max_speed: float = 120.0
@export var acceleration: float = 30.0
@export var friction: float = 30.0
@export var player_joystick: Joystick
@export var winding: WindAndCast

# Two seperate animation players to allow boat to be different direction of player
@onready var _player_anim_tree: AnimationTree = $PlayerAnimTree
@onready var _player_anim_state = _player_anim_tree["parameters/playback"]
@onready var playerAnimationPlayer = $PlayerAnimPlayer

@onready var _boat_anim_tree: AnimationTree = $BoatAnimTree
@onready var _boat_anim_state = _boat_anim_tree["parameters/playback"]
@onready var boatAnimationPlayer = $BoatAnimPlayer

@onready var hook = get_node("Hook")
@onready var money_label = $Camera2D/UIScale/MoneyLabel
var money: int = 0
@onready var hand = $Hand
@onready var water = $"../WaterSurface"

const STAMINA_MAX = 100.0
const CASTING_COST = 10.0 # stamina cost to cast the hook
var stamina = 0.0 # default starting value if never played before

var caught_fish

var can_move = true
var _last_direction: float = 1.0 # 1 = right, -1 = left
var rod_power: float = 0.25 # How much a fishing rod can control a fish
var joystick_disabled: bool = false # Tracks if joystick input should be ignored

func _ready() -> void:	
	load_stats_from_db()
	#update_stamina_display()
	_player_anim_tree.active = true
	_boat_anim_tree.active = true
	# Tell the Hook node who the player is so it can reel back to us
	if hook:
		hook.player = self

func save_to_db(data: Dictionary):
	var auth = Firebase.Auth.auth
	if auth.localid:
		var collection: FirestoreCollection = Firebase.Firestore.collection(COLLECTION_ID)
		var document = await collection.get_doc(auth.localid)
		if document:
			print("Document exist, update it")
			for k in data.keys():
				document.add_or_update_field(k, data[k])
			await collection.update(document)
		else:
			print("Document not exist, add new")
			await collection.add(auth.localid, data)

func load_stats_from_db():
	var auth = Firebase.Auth.auth
	if auth.localid:
		var collection: FirestoreCollection = Firebase.Firestore.collection(COLLECTION_ID)
		var document = await collection.get_doc(auth.localid)
		if document:
			if document.get_value("money"):
				money = document.get_value("money")
				money_label.text = str(money)
			if document.get_value("stamina"):
				stamina = document.get_value("stamina")
				print("Loaded stamina: " + str(stamina))
				
			if document.get_value("stamina"):
				stamina = document.get_value("stamina")
			update_stamina_display()
				
		elif document:
			print(document.error)
		else:
			print("No document found")

func updateMoney(moneyDelta):
	money += moneyDelta
	money_label.text = str(money)

func _physics_process(delta: float) -> void:
	global_position.y = water.get_height_at_x(global_position.x)
	if can_move:
		if _player_anim_state.get_current_node() in ["Idle", "Row"]:
			boatMove(delta)
		if _player_anim_state.get_current_node() in ["Fish", "Reel", "Bite"]:
			reel_in()
		castAndFish()


func reel_in() -> void:
	var input_dir: Vector2 = player_joystick.position_vector
	if _player_anim_state.get_current_node() == "Fish" or _player_anim_state.get_current_node() == "Reel" or _player_anim_state.get_current_node() == "Bite":
		_boat_anim_state.travel("Fish")
		
		if input_dir != Vector2(0, 0):
			SFX.play(SFX.reel, -35, true, true)
			_player_anim_state.travel("Reel")
			hook.start_reel_in()
		else:
			SFX.stop_sound(SFX.reel)
			_player_anim_state.travel("Fish")
			hook.stop_reel_in()
		if hook.get_current_state() == "INVISIBLE":
			set_to_idle()
			
	return


func castAndFish() -> void:
	if winding.isPressing and (_player_anim_state.get_current_node() in ["Wind", "Idle"]):
		_boat_anim_state.travel("Fish")
		if winding.facing == "right":
			_player_anim_tree.set("parameters/Wind/BlendSpace1D/blend_position", -1.0)
			_player_anim_state.travel("Wind")
			_last_direction = -1.0
		elif winding.facing == "left":
			_player_anim_tree.set("parameters/Wind/BlendSpace1D/blend_position", 1.0)
			_player_anim_state.travel("Wind")
			_last_direction = 1.0
	elif _player_anim_state.get_current_node() == "Wind":
		if winding.facing == "right":
			_player_anim_tree.set("parameters/Cast/BlendSpace1D/blend_position", -1.0)
			_player_anim_tree.set("parameters/Reel/BlendSpace1D/blend_position", -1.0)
			_player_anim_tree.set("parameters/Fish/BlendSpace1D/blend_position", -1.0)
			_player_anim_state.travel("Cast")
			SFX.play(SFX.woosh, -1, true)
		elif winding.facing == "left":
			_player_anim_tree.set("parameters/Cast/BlendSpace1D/blend_position", 1.0)
			_player_anim_tree.set("parameters/Reel/BlendSpace1D/blend_position", 1.0)
			_player_anim_tree.set("parameters/Fish/BlendSpace1D/blend_position", 1.0)
			_player_anim_state.travel("Cast")
			SFX.play(SFX.woosh, -1, true)
	#if not winding.isPressing and _anim_state.get_current_node() == "Cast" and (hook.get_current_state() == "INVISIBLE" or hook.get_current_state() == "DEBUG"):
		# Hook will read the launch vector directly from the Wind/TouchArea node
		#hook.start_cast()

func cast_animation_finished():
	_player_anim_state.travel("Fish")


func call_hook_cast():
	if stamina >= CASTING_COST: # check that you have energy first
		if hook:
			hook.start_cast()
			reduce_stamina(CASTING_COST)

func reduce_stamina(amount):
	stamina -= amount
	update_stamina_display()
	save_to_db({"stamina": stamina})

func increase_stamina(amount):
	stamina += amount
	if stamina > STAMINA_MAX:
		stamina = STAMINA_MAX

	update_stamina_display()
	save_to_db({"stamina": stamina})

func update_stamina_display():
	var ratio = float(stamina) / STAMINA_MAX
	var full_height = 186.0 # experimentally seemed to be the best max height
	%EnergyFill.size.y = full_height * ratio

func playRowSound():
	SFX.play(SFX.row, -10, true, true)


func boatMove(delta: float) -> void:
	if joystick_disabled:
		return # Skip joystick input while disabled
	
	var input_dir: float = player_joystick.position_vector.x
	if _player_anim_state.get_current_node() == "Idle" or _player_anim_state.get_current_node() == "Row":
		if input_dir != 0:
			SFX.play(SFX.row, -10, true, true)
			_last_direction = sign(input_dir)
			velocity.x = move_toward(velocity.x, input_dir * max_speed, acceleration * delta)
			_player_anim_tree.set("parameters/Row/BlendSpace1D/blend_position", _last_direction)
			_boat_anim_tree.set("parameters/Row/BlendSpace1D/blend_position", _last_direction)
			_boat_anim_tree.set("parameters/Fish/BlendSpace1D/blend_position", _last_direction)
			_player_anim_state.travel("Row")
			_boat_anim_state.travel("Row")
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			if _player_anim_state.get_current_node() != "Cast":
				_player_anim_tree.set("parameters/Idle/BlendSpace1D/blend_position", -_last_direction)
				_boat_anim_tree.set("parameters/Idle/BlendSpace1D/blend_position", _last_direction)
				_boat_anim_tree.set("parameters/Fish/BlendSpace1D/blend_position", _last_direction)
				_player_anim_state.travel("Idle")
				_boat_anim_state.travel("Idle")
	if input_dir != 0:
		_last_direction = sign(input_dir)
		velocity.x = move_toward(velocity.x, input_dir * max_speed, acceleration * delta)
		_player_anim_tree.set("parameters/Row/BlendSpace1D/blend_position", _last_direction)
		_boat_anim_tree.set("parameters/Row/BlendSpace1D/blend_position", _last_direction)
		_boat_anim_tree.set("parameters/Fish/BlendSpace1D/blend_position", _last_direction)
		_player_anim_state.travel("Row")
		_boat_anim_state.travel("Row")
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if _player_anim_state.get_current_node() != "Cast":
			_player_anim_tree.set("parameters/Idle/BlendSpace1D/blend_position", -_last_direction)
			_boat_anim_tree.set("parameters/Idle/BlendSpace1D/blend_position", _last_direction)
			_boat_anim_tree.set("parameters/Fish/BlendSpace1D/blend_position", _last_direction)
			_player_anim_state.travel("Idle")
			_boat_anim_state.travel("Idle")

	move_and_slide()

func set_to_idle() -> void:
	# Helper used by the Hook when reeling completes.
	_player_anim_state.travel("Idle")
	
	# Disable joystick for 0.3 seconds
	joystick_disabled = true
	await get_tree().create_timer(0.3).timeout
	joystick_disabled = false
	_boat_anim_state.travel("Idle")

func bite() -> void:
	var direction = _player_anim_tree.get("parameters/Fish/BlendSpace1D/blend_position")
	_player_anim_tree.set("parameters/Bite/BlendSpace1D/blend_position", direction)
	_player_anim_state.travel("Bite")

func raise_fish() -> void:
	if is_instance_valid(caught_fish):
		caught_fish.position.y -= 1

func fish_stored():
	can_move = true
	_player_anim_tree.active = true
	_boat_anim_tree.active = true


func hold_fish() -> void:
	var dir = _last_direction
	can_move = false
	_player_anim_tree.active = false
	_boat_anim_tree.active = false

	# Pick animation based on facing direction
	if dir > 0:
		playerAnimationPlayer.play("CatchRight", -1, 0.33)
	else:
		playerAnimationPlayer.play("CatchLeft", -1, 0.33)
	


func store_fish() -> void:
	var dir = _last_direction
	_player_anim_tree.active = false
	_boat_anim_tree.active = false
	
	if dir > 0:
		playerAnimationPlayer.play("CatchRight", -1, -0.33)
	else:
		playerAnimationPlayer.play("CatchLeft", -1, -0.33)


func _on_main_menu_button_pressed() -> void:
	SFX.play(SFX.button_click, -5)
	SFX.stop_sound(SFX.ambient_sounds)
	if hand.item == {}:
		get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
