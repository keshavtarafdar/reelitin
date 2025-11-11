extends Node2D

@export var item_res : Item
@export var fish_CPU : Fish

@onready var inv = $"../Player/Inventory"


func _on_timer_timeout() -> void:
	$Button.disabled = false

func _on_button_pressed() -> void:
	print(1)
	if inv.add_item(inv.prep_item(self)):
		fish_CPU.queue_free()
		self.queue_free()
