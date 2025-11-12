extends Node2D

@onready var item_icon = $ItemIcon
var can_drop: bool = true
var item: Dictionary
var item_count: int = 0

func _physics_process(delta: float) -> void:
	self.global_position = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("") and can_drop:
		drop_item()

func add_item(new_item, count) -> void:
	item = new_item
	item_count = count
	item_icon.texture = item['inv_icon']

func drop_item() -> void:
	if item != {}:
		pass # Add sell to shop logic here
	
	item_icon.texture = null
	item = {}
	item_count = 0
