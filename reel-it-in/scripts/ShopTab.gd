extends TextureRect

var item: Item
var inventory

@onready var item_desc = $LabelScale/ItemDesc
@onready var price_label = $LabelScale/PriceLabel
@onready var purchase_button = $LabelScale/PurchaseButton
@onready var icon = $Item_Icon

func setup(item_data: Item, player_inventory) -> void:
	inventory = player_inventory
	item = item_data
	item_desc.text = item.description
	price_label.text = str(item.price)
	icon.texture = item.inv_icon

	purchase_button.pressed.connect(_buy_item)

func _buy_item() -> void:
	var item_dict = inventory.prep_item_from_resource(item)
	inventory.add_item(item_dict)
