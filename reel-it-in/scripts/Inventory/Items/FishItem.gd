extends Node2D

@export var item_res : Item
@export var player : CharacterBody2D
@export var size = 1.0
@onready var inv = $"../Player/Inventory"

func _ready() -> void:
	self.scale *= size

func _on_timer_timeout() -> void:
	$Button.disabled = false

func _on_button_pressed() -> void:
	if inv.add_item(inv.prep_item(self)):
		player.store_fish()
		self.queue_free()

#Function to have the fish match the player animation of picking up the fish
func picking_up():
	self.position.y -= 1
