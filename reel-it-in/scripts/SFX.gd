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

var active_players := []
var music_player: AudioStreamPlayer = null
var music_fade_task_running := false


func play(sound, volume_db := 0, random_pitch := false, single_instance := false, looped := false):
	if single_instance:
		for player in active_players:
			if player.stream == sound:
				return

	var p = AudioStreamPlayer.new()
	p.stream = sound
	p.volume_db = volume_db
	
	if random_pitch:
		p.pitch_scale = 1.0 + randf_range(-0.05, 0.05)

	add_child(p)
	p.play()

	active_players.append(p)

	if not looped:
		p.connect("finished", Callable(self, "_on_player_finished").bind(p))


func _on_player_finished(player):
	if player in active_players:
		active_players.erase(player)
	player.queue_free()


func stop_sound(sound):
	var to_remove := []
	for player in active_players:
		if player.stream == sound:
			player.stop()
			player.queue_free()
			to_remove.append(player)
	for player in to_remove:
		active_players.erase(player)


# Perceptually linear fade
func _fade_volume_perceptual(player: AudioStreamPlayer, duration: float, target_db: float, start_db: float = -60.0) -> void:
	var time := 0.0
	var start_gain := pow(10.0, start_db / 20.0)
	var end_gain := pow(10.0, target_db / 20.0)

	while time < duration:
		var t := time / duration
		# Apply quadratic easing to slow down the start
		var eased_t := t * t
		var gain = lerp(start_gain, end_gain, eased_t)
		player.volume_db = 20.0 * log(max(gain, 0.0001)) / log(10)
		await get_tree().process_frame
		time += get_process_delta_time()

	player.volume_db = target_db




func _on_music_finished():
	if music_player:
		music_player.play()


func play_random_fading_music(min_silence := 15, max_silence := 45, 
							  fade_in_time := 30.0, fade_out_time := 30.0,
							  min_play_time := 60.0, max_play_time := 120.0,
							  volume := -21):

	if music_fade_task_running:
		return

	music_fade_task_running = true

	while true:
		await get_tree().create_timer(randf_range(min_silence, max_silence)).timeout

		music_player = AudioStreamPlayer.new()
		music_player.stream = music
		music_player.volume_db = -60   # start very silent
		add_child(music_player)

		music_player.connect("finished", Callable(self, "_on_music_finished"))

		var stream_length := music.get_length()
		var start_pos := randf_range(0.0, stream_length)
		music_player.play(start_pos)

		await _fade_volume_perceptual(music_player, fade_in_time, volume, -60)

		await get_tree().create_timer(randf_range(min_play_time, max_play_time)).timeout

		await _fade_volume_perceptual(music_player, fade_out_time, -60, volume)

		music_player.stop()
		music_player.queue_free()
		music_player = null
