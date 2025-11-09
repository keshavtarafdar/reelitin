extends Node2D

var row_size = 10
var col_size = 2
var items = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range([]):
		items.append([])
		
		for y in range(col_size):
			items[x].append([])
	
	items[5][2] = "Hello"
