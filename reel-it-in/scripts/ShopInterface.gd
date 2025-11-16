extends Node2D

@onready var joystick = $"../UI/Joystick"
@onready var bag_button = $"../Camera2D/UIScale/InventoryButton"
@onready var inventory = $"../Inventory"

var inv_offset = Vector2(-130, -57)


func _on_exit_button_pressed() -> void:
	self.visible = false
	joystick.visible = true
	bag_button.visible = true
	inventory.visible = false
	inventory.position -= inv_offset
