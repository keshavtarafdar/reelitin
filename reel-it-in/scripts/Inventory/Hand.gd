extends Node2D

@onready var inv = $"../Inventory"
@onready var item_icon = $ItemIcon
@onready var label = $"LabelScale/Label"
@onready var sell_area = $"../ShopInterface/SellArea/SellShape"
@onready var shop_interface = $"../ShopInterface"
@onready var player = $"../../Player"

var item: Dictionary
var item_count: int = 0

func _physics_process(_delta: float) -> void:
	self.global_position = get_global_mouse_position()

func _input(event):
	if shop_interface.visible and event is InputEventScreenTouch and item != {}:
		print(self.global_position)
		if sell_area.shape.get_rect().has_point(self.position):
			SFX.play(SFX.money, -10, true)
			sell_item(item['price'])

func sell_item(price):
	var moneyDelta = item_count * price
	player.updateMoney(moneyDelta)
	item_icon.texture = null
	item = {}
	item_count = 0
	label.text = ""
	
	var data = inv.prepare_inventory_data()
	player.save_to_db({"money": player.money, "inventory" : data})

# Add item to hand
func add_item(new_item, count) -> void:
	item = new_item
	item_count = count
	item_icon.texture = item['inv_icon']
	label.text = item['name']

# Add items to an already full hand
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
		print(inv.items[slot_num.x][slot_num.y].add_item(new_item))
