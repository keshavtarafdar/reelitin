extends Node2D

var iOSConnection: Variant = null

@export var start_focus_button: Button
@export var stop_focus_button: Button
@onready var hours_input = $HBoxContainer/HoursInput
@onready var minutes_input = $HBoxContainer/MinutesInput
@onready var timer_label = $TimerLabel
@onready var countdown_timer = $CountdownTimer

var target_end_time: float = 0.0
const SAVE_PATH = "user://focus_state.cfg"

# Connection logic to the plugin
func _ready() -> void:
	start_focus_button.disabled = true
	stop_focus_button.disabled = true
	update_timer_label(0)
	
	if !ClassDB.class_exists("GodotPlugin"):
		print("Plugin does not exist!")
		return
	
	if iOSConnection == null and ClassDB.class_exists("GodotPlugin"):
		iOSConnection = ClassDB.instantiate("GodotPlugin")
		iOSConnection.connect("output_message", self.pluginTest)
		
	if iOSConnection:
		iOSConnection.trigger_swift_signal()
		$Label2.text = "Triggered swift signal."
		
		iOSConnection.request_authorization()
		load_focus_state() # Check for a previously started focus block


func pluginTest(message: String) -> void:
	print("Signal 'output' received: " + message)
	$Label.text = message
	
	if message == "Auth status: approved":
		print("Authorization approved! Presenting app picker...")
		if target_end_time == 0.0:
			iOSConnection.present_app_picker()
	
	elif message.begins_with("Auth status: denied"):
		$Label.text = "Authorization denied. Please enable in Settings."
		
	elif message == "Selection updated successfully.":
		$Label.text = "App selection complete!"
		start_focus_button.disabled = false
		stop_focus_button.disabled = true
	
	elif message == "Error: No apps, categories, or websites selected.":
		$Label.text = "Please choose apps to block first."
		start_focus_button.disabled = false
	
	elif message.begins_with("Block started for"):
		$Label.text = "Focus block active!"
		start_focus_button.disabled = true
		stop_focus_button.disabled = false
	
	elif message == "Block stopped manually.":
		$Label.text = "Focus stopped. Ready to start again."
		start_focus_button.disabled = false
		stop_focus_button.disabled = true
		target_end_time = 0.0
		save_focus_state() # Clear save
		
	elif message.begins_with("Error:"):
		$Label.text = message

func _on_start_focus_pressed() -> void:
	if iOSConnection:
		var h = hours_input.value
		var m = minutes_input.value
		var duration = (h * 3600) + (m * 60)

		if duration < 0:
			$Label.text = "Please set a time greater than 0."
			return
		
		target_end_time = Time.get_unix_time_from_system() + duration
		save_focus_state()
		
		$Label.text = "Starting block..."
		countdown_timer.start()
		_on_countdown_tick()
		iOSConnection.start_focus_block(float(duration))

func _on_stop_focus_pressed() -> void:
	if iOSConnection:
		iOSConnection.stop_focus_block()
	countdown_timer.stop()
	target_end_time = 0.0
	update_timer_label(0)
	save_focus_state() # Save "0" to indicate no active block
	
# This runs every 1 second locally in Godot to update the UI
func _on_countdown_tick():
	var current_time = Time.get_unix_time_from_system()
	var remaining = target_end_time - current_time
	
	if remaining > 0:
		update_timer_label(remaining)
		if countdown_timer.is_stopped():
			countdown_timer.start()
	else:
		countdown_timer.stop()
		target_end_time = 0.0
		update_timer_label(0)
		save_focus_state()
		$Label.text = "Focus Complete!"
		start_focus_button.disabled = false
		stop_focus_button.disabled = true

func update_timer_label(time_in_seconds: float):
	var total_int = int(time_in_seconds)
	var h = int(total_int / 3600)
	var m = int((total_int % 3600) / 60)
	var s = int(total_int % 60)
	timer_label.text = "%02d:%02d:%02d" % [h, m, s]

# Persistence logic (storing focus end time in a .cfg file)
func save_focus_state():
	var config = ConfigFile.new()
	config.set_value("Focus", "end_time", target_end_time)
	config.save(SAVE_PATH)

func load_focus_state():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err == OK:
		var saved_end_time = config.get_value("Focus", "end_time", 0.0)
		var current_time = Time.get_unix_time_from_system()
		
		# If we have a saved time AND it is in the future
		if saved_end_time > current_time:
			print("Resuming active session...")
			target_end_time = saved_end_time
			
			# Resume UI immediately
			start_focus_button.disabled = true
			stop_focus_button.disabled = false
			$Label.text = "Resuming Focus..."
			countdown_timer.start()
			_on_countdown_tick()
		else:
			# Old session finished while app was closed
			target_end_time = 0.0
			update_timer_label(0)
	
func _on_log_out_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
