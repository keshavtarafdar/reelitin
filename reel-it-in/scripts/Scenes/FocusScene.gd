extends Node2D

var iOSConnection: Variant = null

@export var start_focus_button: Button
@export var stop_focus_button: Button

# Connection logic to the plugin
func _ready() -> void:

	# Set up focus buttons
	if start_focus_button:
		start_focus_button.connect("pressed", self._on_start_focus_pressed)
	if stop_focus_button:
		stop_focus_button.connect("pressed", self._on_stop_focus_pressed)
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
	
	elif message == "Block started for 1 hour.":
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
		$Label.text = "Starting 1-hour block..."
		iOSConnection.start_focus_block()

func _on_stop_focus_pressed() -> void:
	if iOSConnection:
		$Label.text = "Stopping block..."
		iOSConnection.stop_focus_block()

func _on_log_out_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
