extends Node2D

@export var item_res : Item
@onready var inv = $"../Inventory"

func _on_timer_timeout() -> void:
	$Button.disble = false
