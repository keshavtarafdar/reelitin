extends Node

var ambient_sounds = preload("res://assets/sounds/ambientNoise.mp3")
var button_click = preload("res://assets/sounds/buttonClick.mp3")
var reel = preload("res://assets/sounds/reel.mp3")
var hook_drop = preload("res://assets/sounds/hookDrop.mp3")
var woosh = preload("res://assets/sounds/woosh.mp3")
var select = preload("res://assets/sounds/select.mp3")
var row = preload("res://assets/sounds/row.mp3")
var money = preload("res://assets/sounds/money.mp3")
var shop = preload("res://assets/sounds/shop.mp3")
var music = preload("res://assets/sounds/Patience.wav")

# Keep track of currently playing AudioStreamPlayers
var active_players := []
var music_player: AudioStreamPlayer = null
var music_fade_task_running := false

func play(sound, volume_db := 0, random_pitch := false, single_instance := false, looped := false):
	if single_instance:
		for player in active_players:
			if player.stream == sound:
				return

	var p = AudioStreamPlayer.new()

	if looped:
		var clone = sound.duplicate()
		clone.loop = true
		p.stream = clone
	else:
		p.stream = sound

	p.volume_db = volume_db
	
	if random_pitch:
		p.pitch_scale = 1.0 + randf_range(-0.05, 0.05)  # ±5% pitch variation

	add_child(p)
	p.play()

	active_players.append(p)

	if not looped:
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


func _fade_volume(player: AudioStreamPlayer, from_db: float, to_db: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, duration).from(from_db)
	await tween.finished



func play_random_fading_music(min_silence := 10.0, max_silence := 20.0, 
							  fade_in_time := 3.0, fade_out_time := 3.0,
							  min_play_time := 20.0, max_play_time := 40.0, volume := -10):

	if music_fade_task_running:
		return  # prevent duplicate loops

	music_fade_task_running = true

	while true:
		await get_tree().create_timer(randf_range(min_silence, max_silence)).timeout

		music_player = AudioStreamPlayer.new()
		music_player.stream = music
		music_player.loop = true
		music_player.volume_db = volume
		add_child(music_player)

		music_player.play()

		await _fade_volume(music_player, volume, 0, fade_in_time)

		await get_tree().create_timer(randf_range(min_play_time, max_play_time)).timeout

		await _fade_volume(music_player, 0, volume, fade_out_time)

		music_player.stop()
		music_player.queue_free()
		music_player = null
