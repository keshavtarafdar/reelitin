class_name WindAndCast
extends Area2D

@onready var player = get_parent()
@onready var touchArea: CollisionShape2D = $TouchAreaFish
var isPressing: bool = false
var initialPos: Vector2
var currentPos: Vector2
var moving: bool
var facing: String
var powerLevel: float
var yLaunch: float
var xLaunch: float

func _ready() -> void:
	isPressing = false
	initialPos = Vector2.ZERO
	currentPos = Vector2.ZERO
	facing = ""
	moving = false
	powerLevel = 0

func _process(_delta: float) -> void:
	moving = is_player_moving()
	if isPressing and Input.is_action_pressed("Left_Mouse"):
		currentPos = get_global_mouse_position()
		powerLevel = abs(currentPos.x-initialPos.x)
		if powerLevel > 150:
			powerLevel = 150
		else:
			powerLevel = powerLevel*2/3
		if currentPos.x < initialPos.x:
			facing = "left"
		else:
			facing="right"
	elif isPressing:
		isPressing = false
		yLaunch = initialPos.y - currentPos.y 
		xLaunch = initialPos.x - currentPos.x
		currentPos = Vector2.ZERO
		initialPos = Vector2.ZERO
		
		

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not moving and not isPressing:
		isPressing = true
		initialPos = get_global_mouse_position()
		currentPos = initialPos

func is_player_moving() -> bool:
	if player and player is CharacterBody2D:
		return player.velocity.length() > 0.01
	return false
