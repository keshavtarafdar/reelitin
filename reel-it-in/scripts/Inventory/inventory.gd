extends Node2D

const ITEM_SLOT = preload("res://scenes/ItemSlot.tscn")

var row_size = 10
var col_size = 2
var items = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range(row_size):
		items.append([])
		
		for y in range(col_size):
			items[x].append([])
			
			var item_slot = ITEM_SLOT.instantiate()
			item_slot.global_position = Vector2(x*21, y*21)
			item_slot.slot_num = Vector2i(x,y)
			add_child(item_slot)
			items[x][y] = item_slot
