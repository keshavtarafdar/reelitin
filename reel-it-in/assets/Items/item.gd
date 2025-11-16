extends Resource
class_name Item

@export var name: String
@export_enum("Fish", "Equipment", "Bait") var type: String
@export var inv_icon: Texture2D
@export var item_path: String
@export var stack_amount: int
@export var price: int
