extends Node2D

@onready var joystick = $"../UI/Joystick"
@onready var bag_button = $"../Camera2D/UIScale/InventoryButton"
@onready var inventory = $"../Inventory"
@onready var hand = $"../Hand"
@onready var sell_overlay = $UI/LabelScale/SellOverlay
@onready var sell_overlay_text = $UI/LabelScale/SellOverlay/LabelScale/Label

var sell_overlay_on = false
var inv_offset = Vector2(-69, -9)

# Fade speeds
var fade_in_speed = 0.75    # seconds to fully appear
var fade_out_speed = 0.2   # seconds to fully disappear

func _on_exit_button_pressed() -> void:
	SFX.play(SFX.button_click, -5, true)
	self.visible = false
	joystick.visible = true
	bag_button.visible = true
	inventory.visible = false
	inventory.position -= inv_offset

func _process(delta: float) -> void:
	var target_alpha = 0.0
	
	# Decide target alpha based on whether hand is holding something
	if hand.item != {}:
		target_alpha = 0.75
	else:
		target_alpha = 0.0
	# Smoothly interpolate current alpha toward target
	var speed = fade_in_speed if target_alpha > sell_overlay.modulate.a else fade_out_speed
	var new_alpha = lerp(sell_overlay.modulate.a, target_alpha, delta / speed)
	sell_overlay.modulate.a = new_alpha
