extends Node2D

@onready var inv = $"../Inventory"
@onready var item_icon = $ItemIcon
@onready var label = $"LabelScale/Label"

var can_drop: bool = true
var item: Dictionary
var item_count: int = 0

func _physics_process(_delta: float) -> void:
	self.global_position = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	# Detect touch or mouse release
	if (event is InputEventScreenTouch and not event.pressed) or (event is InputEventMouseButton and not event.pressed):
		if can_drop:
			drop_item()

func add_item(new_item, count) -> void:
	item = new_item
	item_count = count
	item_icon.texture = item['inv_icon']
	label.text = item['name']

func drop_item() -> void:
	if item != {}:
		pass # Add sell to shop logic here
	
	#item_icon.texture = null
	#item = {}
	#item_count = 0

func add_items(new_item, slot_count, slot_num):
	if new_item != {}:
		if item['name'] != new_item['name']:
			return
	
	if new_item == {}:
		new_item = item
	
	var amount = min(item_count, new_item['stack_amount'] - slot_count)
	
	if amount >= item_count:
		item_icon.texture = null
		item = {}
		item_count = 0
	else:
		item_count -= amount
	
	for i in amount:
		inv.items[slot_num.x][slot_num.y].add_item(new_item)
