extends Node2D

@onready var joystick = $"../UI/Joystick"


func _on_exit_button_pressed() -> void:
	self.visible = false
	joystick.visible = true
