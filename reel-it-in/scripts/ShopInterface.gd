extends Node2D

@onready var joystick = $"../UI/Joystick"
@onready var bag_button = $"../Camera2D/UIScale/InventoryButton"
@onready var inventory = $"../Inventory"
@onready var hand = $"../Hand"


var inv_offset = Vector2(-69, -9)

func _on_exit_button_pressed() -> void:
	SFX.play(SFX.button_click, -5, true)
	self.visible = false
	joystick.visible = true
	bag_button.visible = true
	inventory.visible = false
	inventory.position -= inv_offset
