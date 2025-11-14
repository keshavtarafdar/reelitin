extends Node2D

@export var item_res : Item
@export var player : CharacterBody2D
@onready var inv = $"../Player/Inventory"


func _on_timer_timeout() -> void:
	$Button.disabled = false

func _on_button_pressed() -> void:
	if inv.add_item(inv.prep_item(self)):
		player.store_fish()
		self.queue_free()

#Function to have the fish match the player animation of picking up the fish
func picking_up():
	self.position.y -= 1
