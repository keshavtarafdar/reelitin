extends ColorRect

var _animation_player: AnimationPlayer

func _ready() -> void:
	_animation_player = $AnimationPlayer
	# print("Here")
	_animation_player.play("FadeIn")

func _process(_delta: float) -> void:
	pass
