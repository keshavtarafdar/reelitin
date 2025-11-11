extends Node2D

@onready var item_icon = $ItemIcon
@onready var count_label = $ItemCountLabel


var slot_num : Vector2i
var item : Dictionary
var item_count = 0

func add_item(new_item: Dictionary) -> bool:
	if (item_count != 0 and (item['name'] == new_item['name']) and item_count < item['stack_amount']) or item == {}:
		item_count += 1
		item = new_item
		item_icon.texture = item['inv_icon']
		refresh_label()
		return true
	return false

func refresh_label() -> void:
	count_label.text = str(item_count)
	
