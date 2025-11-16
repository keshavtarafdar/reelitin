extends Node2D

@onready var inv = $"../../Inventory"
@onready var item_icon = $ItemIcon
@onready var count_label = $ItemCountLabel
@onready var hand = $"../../Hand"


var slot_num : Vector2i 
var item : Dictionary
var item_count = 0

func add_item(new_item: Dictionary) -> bool:
	hand.label.text = ""
	if (item_count != 0 and (item['name'] == new_item['name']) and item_count < item['stack_amount']) or item == {}:
		item_count += 1
		item = new_item
		item_icon.texture = item['inv_icon']
		refresh_label()
		return true
	return false

func refresh_label() -> void:
	if item_count == 1 or item_count == 0:
		count_label.text = ""
	else:
		count_label.text = str(item_count)


func _on_button_pressed() -> void:
	if hand.item == {} and item!= {}:
		inv.remove_item(slot_num)
	elif hand.item != {}:
		hand.add_items(item, item_count, slot_num)
