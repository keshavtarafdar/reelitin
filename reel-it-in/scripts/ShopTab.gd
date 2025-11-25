extends TextureRect

var item: Item
var inventory
var player

@onready var item_desc = $LabelScale/ItemDesc
@onready var price_label = $LabelScale/PriceLabel
@onready var purchase_button = $LabelScale/PurchaseButton
@onready var icon = $Item_Icon

func setup(item_data: Item, player_inventory, _player) -> void:
	inventory = player_inventory
	player = _player
	item = item_data
	item_desc.text = item.description
	price_label.text = str(item.price) + "g"
	icon.texture = item.inv_icon

	purchase_button.pressed.connect(_buy_item)

func _buy_item() -> void:
	if player.money >= item.price:
		player.updateMoney(-item.price)
		SFX.play(SFX.money, -5, true)
		var item_dict = inventory.prep_item_from_resource(item)
		inventory.add_item(item_dict)
		self.queue_free()
