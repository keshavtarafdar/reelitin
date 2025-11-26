extends Sprite2D

@onready var player = $"../Player"
@onready var joystick = $"../Player/UI/Joystick"
@onready var interaction_range = $Area2D/CollisionShape2D
@onready var shop_bubble_anim = $ShopBubbleAnim
@onready var shop_bubble = $ShopBubble
@onready var shop_interface = $"../Player/ShopInterface"
@onready var inventory = $"../Player/Inventory"
@onready var bag_button = $"../Player/Camera2D/UIScale/InventoryButton"

var inv_offset = Vector2(-69,-9)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shop_bubble_anim.animation_finished.connect(_on_shop_anim_finished)


func _on_enter_shop_button_pressed() -> void:
	if shop_interface.visible == false:
		SFX.play(SFX.shop, -10, true)
		shop_interface.visible = true
		inventory.visible = true
		joystick.visible = false
		bag_button.visible = false
		inventory.position += inv_offset


func _on_area_2d_area_entered(_area: Area2D) -> void:
	shop_bubble.visible = true
	shop_bubble_anim.play("shopBubble")


func _on_area_2d_area_exited(_area: Area2D) -> void:
	shop_bubble_anim.stop()
	shop_bubble.visible = false


func _on_shop_anim_finished(anim_name: StringName) -> void:
	if anim_name == "shopBubble":
		shop_bubble_anim.play("coinSpin", 0, 0.35)
