extends Node2D

var fish_scene = preload("res://scenes/Fish/Fish1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var fish1 = fish_scene.instantiate()
	var fish2 = fish_scene.instantiate()
	var fish3 = fish_scene.instantiate()
	
	fish1.player = $Player
	fish2.player = $Player
	fish3.player = $Player
	
	fish1.hook = $Hook
	fish2.hook = $Hook
	fish3.hook = $Hook

	fish1.position = Vector2(-50, 50)
	fish2.position = Vector2(-70, 60)
	fish3.position = Vector2(-100, 75)
	
	add_child(fish1)
	add_child(fish2)
	add_child(fish3)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
