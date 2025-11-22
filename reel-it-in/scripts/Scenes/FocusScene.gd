extends Node2D

var iOSConnection: Variant = null

@onready var player = $"."

@onready var start_focus_button = $StartButton
@onready var stop_focus_button = $CancelButton
@onready var stop_button_label = $CancelButton/Label

@onready var hours_input = $HBoxContainer/HoursInput
@onready var minutes_input = $HBoxContainer/MinutesInput
@onready var timer_label = $TimerLabel
@onready var countdown_timer = $CountdownTimer

var target_end_time: float = 0.0
const SAVE_PATH = "user://focus_state.cfg"

# Hold-to-cancel variables
var hold_time: float = 0.0
var is_holding: bool = false
var original_button_color: Color
var original_button_text: String
const HOLD_DURATION: float = 5.0

# global duration - i.e. how long did the player start to focus for
var duration = 0
const SECS_PER_STAMINA = 60.0 * 2 # how many seconds of focussing is required to gain one stamina

func _ready() -> void:
	start_focus_button.disabled = true
	stop_focus_button.disabled = true
	update_timer_label(0)
	countdown_timer.timeout.connect(_on_countdown_tick)
	
	# Setup hold-to-cancel signals
	stop_focus_button.button_down.connect(_on_stop_button_down)
	stop_focus_button.button_up.connect(_on_stop_button_up)
	original_button_color = stop_focus_button.modulate
	
	original_button_text = stop_button_label.text
	
	# Setup notification for when resuming timer (re-entering app)
	get_tree().get_root().files_dropped.connect(_on_files_dropped)
	
	print("Checking for GodotPlugin class...")
	var plugin_exists = ClassDB.class_exists("GodotPlugin")
	
	if !plugin_exists:
		print("Plugin does not exist! Aborting.")
		return
	
	if iOSConnection == null and plugin_exists:
		iOSConnection = ClassDB.instantiate("GodotPlugin")
		if iOSConnection:
			iOSConnection.connect("output_message", self.pluginTest)
		
	if iOSConnection:
		iOSConnection.trigger_swift_signal()
		iOSConnection.request_authorization()
		load_focus_state()
		

# Detect when app comes back from background
func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		print("App resumed! Updating timer...")
		if target_end_time > 0:
			_on_countdown_tick() # Force immediate update

func _process(delta: float) -> void:
	if is_holding:
		hold_time += delta
		var remaining_hold = int(ceil(HOLD_DURATION - hold_time))
		stop_button_label.text = str(remaining_hold)
		
		# Flash red slowly
		var t = (sin(hold_time * 10.0) + 1.0) / 2.0
		stop_focus_button.modulate = original_button_color.lerp(Color.RED, 0.5 + (t * 0.5))
		
		if hold_time >= HOLD_DURATION:
			perform_stop_focus()
			_on_stop_button_up() # Reset button state

func _on_stop_button_down() -> void:
	SFX.play(SFX.button_click, -5, true)
	if !stop_focus_button.disabled:
		is_holding = true
		hold_time = 0.0

func _on_stop_button_up() -> void:
	is_holding = false
	hold_time = 0.0
	stop_button_label.text = original_button_text
	stop_focus_button.modulate = original_button_color

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

		# Force minutes to snap to nearest 5
		m = int(round(m / 5.0)) * 5
		minutes_input.value = m

		duration = (h * 3600) + (m * 60)

		# Minimum 15 minutes
		if duration < 15 * 60:
			$Label.text = "Minimum focus time is 15 minutes."
			return

		# Maximum 3 hours
		if duration > 3 * 3600:
			$Label.text = "Maximum focus time is 3 hours."
			return

		target_end_time = Time.get_unix_time_from_system() + duration
		save_focus_state()

		$Label.text = "Starting block..."
		countdown_timer.start()
		_on_countdown_tick()
		iOSConnection.start_focus_block(float(duration))


func _on_stop_focus_pressed() -> void:
	SFX.play(SFX.button_click, -5, true)
	pass

func perform_stop_focus() -> void:
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
		# award stamina here!
		player.increase_stamina(duration / SECS_PER_STAMINA) # based on focus length

		
func update_timer_label(time_in_seconds: float):
	var total_int = int(time_in_seconds)
	var h = int(total_int / 3600)
	var m = int((total_int % 3600) / 60)
	var s = int(total_int % 60)
	timer_label.text = "%02d:%02d:%02d" % [h, m, s]
	
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
	SFX.play(SFX.button_click, -5, true)
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
