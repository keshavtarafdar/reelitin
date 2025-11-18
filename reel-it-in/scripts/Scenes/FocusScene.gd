extends Node2D

var iOSConnection: Variant = null

# Connection logic to the plugin
func _ready() -> void:
	if !ClassDB.class_exists("GodotPlugin"):
		print("Plugin does not exist!")
	
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


func _on_log_out_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")