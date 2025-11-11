extends Node2D

const ITEM_SLOT = preload("res://scenes/ItemSlot.tscn")

var row_size = 5
var col_size = 4
var items = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range(row_size):
		items.append([])
		
		for y in range(col_size):
			items[x].append([])
			
			var item_slot = ITEM_SLOT.instantiate()
			item_slot.global_position = Vector2(x*20, y*20)
			item_slot.slot_num = Vector2i(x,y)
			add_child(item_slot)
			items[x][y] = item_slot

func prep_item(new_item: Node2D) -> Dictionary:
	var item = {}
	item['name'] = new_item.item_res.name
	item['inv_icon'] = new_item.item_res.inv_icon
	item['item_path'] = new_item.item_res.item_path
	item['stack_amount'] = new_item.item_res.stack_amount
	
	return item

func add_item(item: Dictionary):
	for y in range(col_size):
		for x in range(row_size):
			var slot = items[x][y]
			
			if slot.add_item(item):
				return true
	return false


func _on_inventory_button_pressed() -> void:
	self.visible = !self.visible
