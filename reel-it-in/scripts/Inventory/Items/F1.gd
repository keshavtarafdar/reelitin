extends Node2D

@export var item_res : Item
@onready var inv = $"../Player/Inventory"


func _on_timer_timeout() -> void:
	$Button.disabled = false

func _on_button_pressed() -> void:
	if inv.add_item(inv.prep_item(self)):
		self.queue_free()
