extends Control

@onready var _animation_player: AnimationPlayer = $ColorRect/AnimationPlayer

func _on_go_fish_button_pressed() -> void:
	_animation_player.animation_finished.connect(_on_animation_finished)
	_animation_player.play("Fade")

func _on_animation_finished(_anim_name: String) -> void:
	get_tree().change_scene_to_file("res://scenes/RiverScene.tscn")

func _on_focus_mode_button_pressed() -> void:
	# ready for when focus mode scene is made
	pass
