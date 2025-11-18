extends Node2D


const COLLECTION_ID = "player_stats"
const ITEM_SLOT = preload("res://scenes/ItemSlot.tscn")

@onready var hand = $"../Hand"
@onready var player = $"../../Player"

var row_size = 5
var col_size = 4
var items = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instantiate_inventory()
	fill_inventory()
	print(items)
	print(items[0][0].item)

func instantiate_inventory():
	for x in range(row_size):
		items.append([])
		
		for y in range(col_size):
			items[x].append([])
			
			var item_slot = ITEM_SLOT.instantiate()
			item_slot.global_position = Vector2(x*22, y*22)
			item_slot.slot_num = Vector2i(x,y)
			add_child(item_slot)
			items[x][y] = item_slot

func fill_inventory():
	var auth = Firebase.Auth.auth
	if auth.localid:
		var collection: FirestoreCollection = Firebase.Firestore.collection(COLLECTION_ID)
		var document = await collection.get_doc(auth.localid)
		if document:
			if document.get_value("inventory"):
				var raw_inventory = document.get_value("inventory")
				for i in range(raw_inventory.size()):
					@warning_ignore("integer_division")
					var y = i / row_size
					var x = i % row_size
					
					# we are storing the texture path, so now need to lead the texture from it
					if raw_inventory[i].icon_path:
						var icon_tex = load(raw_inventory[i].icon_path) as Texture2D
						raw_inventory[i].item["inv_icon"] = icon_tex
						
					items[x][y].item = raw_inventory[i]["item"]
					items[x][y].item_count = raw_inventory[i]["item_count"]
					
					items[x][y].refresh_icon()
					items[x][y].refresh_label()

		else:
			print("No document found.")


func prep_item(new_item: Node2D) -> Dictionary:
	var item = {}
	item['name'] = new_item.item_res.name
	item['inv_icon'] = new_item.item_res.inv_icon
	item['item_path'] = new_item.item_res.item_path
	item['stack_amount'] = new_item.item_res.stack_amount
	item['price'] = new_item.item_res.price
	
	return item

func add_item(item: Dictionary) -> bool:
	print(item)
	for y in range(col_size):
		for x in range(row_size):
			var slot = items[x][y]
			
			if slot.add_item(item):
				return true
	return false


func _on_inventory_button_pressed() -> void:
	if hand.item == {}:
		self.visible = !self.visible


func remove_item(slot_num: Vector2i) -> void:
	var slot = items[slot_num.x][slot_num.y]
	
	if slot.item != {}:
		if hand.item == {}:
			hand.add_item(slot.item, 1)
	
	if slot.item_count == 1:
		slot.item = {}
		slot.item_icon.texture = null
	
	slot.item_count -= 1
	slot.refresh_label()

func remove_stack(slot_num: Vector2i) -> void:
	var slot = items[slot_num.x][slot_num.y]
	
	if slot.item != {}:
		if hand.item == {}:
			hand.add_item(slot.item, slot.item_count)
		
		slot.item_count = 0
		slot.refresh_label()
		slot.icon_texture = null
		slot.item = {}


func prepare_inventory_data():
	var data = []
	
	for row in items:
		for slot in row:
			var icon_path = ""
			if slot.item.get("inv_icon"):
				# can't store texture, store path instead
				print(slot.item["inv_icon"].load_path)
				icon_path = slot.item["inv_icon"].load_path
				
			data.append({"item": slot.item, "item_count": slot.item_count, "icon_path": icon_path})
	
	return data
