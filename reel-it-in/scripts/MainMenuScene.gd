extends Control

@onready var _animation_player: AnimationPlayer = $ColorRect/AnimationPlayer

var iOSConnection: Variant = null
@onready var focus_button = $FocusButton

# Connection logic to the plugin
func _ready() -> void:
	if iOSConnection == null and ClassDB.class_exists("GodotPlugin"):
		iOSConnection = ClassDB.instantiate("GodotPlugin")
	if iOSConnection:
		print("Plugin instantiated as: " + iOSConnection)


func _on_go_fish_button_pressed() -> void:
	_animation_player.animation_finished.connect(_on_animation_finished)
	_animation_player.play("Fade")

func _on_animation_finished(_anim_name: String) -> void:
	get_tree().change_scene_to_file("res://scenes/RiverScene.tscn")

func _on_focus_mode_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/FocusScene.tscn")
