extends ScrollContainer

@onready var vbox = $VBoxContainer
var shop_tab_scene = preload("res://scenes/ShopTab.tscn")
@onready var player_inventory = get_tree().get_root().get_node("RiverScene/Player/Inventory")
@onready var player = get_tree().get_root().get_node("RiverScene/Player")

var shop_items: Array[Item] = []


func _ready():
	load_items()
	populate_shop()


func load_items():
	var scene = load("res://scenes/Items/BetaTestTrophy.tscn")
	shop_items = []
	for i in range(4): # Arbitrary for testing
		shop_items.append(scene.instantiate().item_res)


func populate_shop():
	for item in shop_items:
		var tab = shop_tab_scene.instantiate()
		vbox.add_child(tab) # add first
		tab.call_deferred("setup", item, player_inventory, player)
