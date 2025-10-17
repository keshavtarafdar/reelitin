class_name WindAndCast
extends Area2D

@onready var player = get_parent()
@onready var touchArea: CollisionShape2D = $TouchAreaFish
var isPressing: bool = false
var initialPos: Vector2
var currentPos: Vector2
var moving: bool

func _ready() -> void:
	isPressing = false
	initialPos = Vector2.ZERO
	currentPos = Vector2.ZERO
	moving = false

func _process(delta: float) -> void:
	moving = is_player_moving()
	if isPressing and Input.is_action_pressed("Left_Mouse"):
		currentPos = get_global_mouse_position()
		print(currentPos)
	elif isPressing:
		isPressing = false
		currentPos = Vector2.ZERO
		initialPos = Vector2.ZERO
		print("here")

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not moving and not isPressing:
		isPressing = true
		initialPos = get_global_mouse_position()
		print(initialPos)
		

func is_player_moving() -> bool:
	if player and player is CharacterBody2D:
		return player.velocity.length() > 0.01
	return false
