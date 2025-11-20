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
	countdown_timer.timeout.connect(_on_countdown_tick)
	
	# Setup notification for when resuming timer (re-entering app)
	get_tree().get_root().files_dropped.connect(_on_files_dropped)
	
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


# Detect when app comes back from background
func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		print("App resumed! Updating timer...")
		if target_end_time > 0:
			_on_countdown_tick() # Force immediate update


func pluginTest(message: String) -> void:
	print("Signal 'output' received: " + message)
	$Label.text = message
	
	if message == "Auth status: approved":
		if target_end_time == 0.0:
			iOSConnection.present_app_picker()
		
	elif message == "Selection updated successfully.":
		start_focus_button.disabled = false
		stop_focus_button.disabled = true
	
	elif message.begins_with("Block started"):
		start_focus_button.disabled = true
		stop_focus_button.disabled = false
	
	elif message == "Block stopped manually.":
		reset_ui_state()
		
	elif message.begins_with("Error:"):
		$Label.text = message

func _on_start_focus_pressed() -> void:
	if iOSConnection:
		var h = hours_input.value
		var m = minutes_input.value
		var duration = (h * 3600) + (m * 60)

		if duration <= 0:
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
	reset_ui_state()
	
func reset_ui_state():
	countdown_timer.stop()
	target_end_time = 0.0
	update_timer_label(0)
	save_focus_state()
	start_focus_button.disabled = false
	stop_focus_button.disabled = true
	$Label.text = "Focus stopped."
	
# This runs every 1 second locally in Godot to update the UI
func _on_countdown_tick():
	if target_end_time == 0.0:
		countdown_timer.stop()
		return

	var current_time = Time.get_unix_time_from_system()
	var remaining = target_end_time - current_time
	
	if remaining > 0:
		update_timer_label(remaining)
	else:
		reset_ui_state()
		$Label.text = "Focus Complete!"
		
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
		
		if saved_end_time > current_time:
			print("Resuming active session...")
			target_end_time = saved_end_time
			start_focus_button.disabled = true
			stop_focus_button.disabled = false
			$Label.text = "Resuming..."
			countdown_timer.start()
			_on_countdown_tick()
		else:
			target_end_time = 0.0
			update_timer_label(0)

func _on_files_dropped(_files, _pos):
	pass
		
func _on_log_out_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
