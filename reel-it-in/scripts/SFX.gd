extends Node

var ambient_sounds = preload("res://assets/sounds/ambientNoise.mp3")
var button_click = preload("res://assets/sounds/buttonClick.mp3")
var reel = preload("res://assets/sounds/reel.mp3")
var hook_drop = preload("res://assets/sounds/hookDrop.mp3")
var woosh = preload("res://assets/sounds/woosh.mp3")
var select = preload("res://assets/sounds/select.mp3")

# Keep track of currently playing AudioStreamPlayers
var active_players := []

func play(sound, volume_db := 0, random_pitch := false, single_instance := false):
	# If single_instance is true, don't play if the sound is already active
	if single_instance:
		for player in active_players:
			if player.stream == sound:
				return  # already playing, skip

	var p = AudioStreamPlayer.new()
	p.stream = sound
	p.volume_db = volume_db
	
	# Apply slight random pitch change if enabled
	if random_pitch:
		p.pitch_scale = 1.0 + randf_range(-0.05, 0.05)  # ±5% pitch variation

	add_child(p)
	p.play()
	active_players.append(p)
	p.connect("finished", Callable(self, "_on_player_finished").bind(p))

func _on_player_finished(player):
	if player in active_players:
		active_players.erase(player)
	player.queue_free()

# Stop a specific sound type
func stop_sound(sound):
	var to_remove := []
	for player in active_players:
		if player.stream == sound:
			player.stop()
			player.queue_free()
			to_remove.append(player)
	for player in to_remove:
		active_players.erase(player)
