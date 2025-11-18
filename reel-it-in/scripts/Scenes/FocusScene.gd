extends Node2D

var iOSConnection: Variant = null

@export var start_focus_button: Button
@export var stop_focus_button: Button
@onready var hours_input = $HBoxContainer/HoursInput
@onready var minutes_input = $HBoxContainer/MinutesInput
@onready var timer_label = $TimerLabel
@onready var countdown_timer = $CountdownTimer

var remaining_seconds = 0

# Connection logic to the plugin
func _ready() -> void:
	start_focus_button.disabled = true
	stop_focus_button.disabled = true
	
	if !ClassDB.class_exists("GodotPlugin"):
		print("Plugin does not exist!")
		return
	
	if iOSConnection == null and ClassDB.class_exists("GodotPlugin"):
		iOSConnection = ClassDB.instantiate("GodotPlugin")
		iOSConnection.connect("output_message", self.pluginTest)
		
	if iOSConnection:
		var methods = iOSConnection.get_method_list()
		for m in methods:
			print("Method: ", m.name)

		iOSConnection.trigger_swift_signal()
		$Label2.text = "Triggered swift signal."
		
		iOSConnection.request_authorization()
		countdown_timer.timeout.connect(_on_countdown_tick)


func pluginTest(message: String) -> void:
	print("Signal 'output' received: " + message)
	$Label.text = message
	
	if message == "Auth status: approved":
		print("Authorization approved! Presenting app picker...")
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
		
	elif message.begins_with("Error:"):
		$Label.text = message

func _on_start_focus_pressed() -> void:
	if iOSConnection:
		var h = hours_input.value
		var m = minutes_input.value
		var total_duration = (h * 3600) + (m * 60)

		if total_duration < 0:
			$Label.text = "Please set a time greater than 0."
			return
		
		remaining_seconds = total_duration
		update_timer_label()
		countdown_timer.start()

		$Label.text = "Starting block..."
		iOSConnection.start_focus_block(float(total_duration))

func _on_stop_focus_pressed() -> void:
	if iOSConnection:
		iOSConnection.stop_focus_block()
		countdown_timer.stop()
		timer_label.text = "00:00:00"

# This runs every 1 second locally in Godot to update the UI
func _on_countdown_tick():
	if remaining_seconds > 0:
		remaining_seconds -= 1
		update_timer_label()
		countdown_timer.start()
	else:
		countdown_timer.stop()
		_on_stop_focus_pressed()

func update_timer_label():
	var h = floor(remaining_seconds / 3600)
	var m = floor((remaining_seconds % 3600) / 60)
	var s = remaining_seconds % 60
	timer_label.text = "%02d:%02d:%02d" % [h, m, s]

func _on_log_out_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
