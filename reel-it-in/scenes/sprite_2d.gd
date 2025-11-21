extends Sprite2D

@export var scroll_speed := Vector2(-15, 0)
@export var min_x := -200.0
@export var max_x := 200.0

var min_pos
var max_pos
func _ready():
	min_pos = position.x + min_x
	max_pos = position.x + max_x


func _process(delta):
	# Move background
	position += scroll_speed * delta

	# If we hit a boundary, reverse direction
	if position.x <= min_pos or position.x >= max_pos:
		scroll_speed.x *= -1  # reverse direction
