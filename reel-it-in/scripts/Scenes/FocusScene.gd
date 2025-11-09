extends Node2D

var iOSConnection: Variant = null

# Connection logic to the plugin
func _ready() -> void:
	if !ClassDB.class_exists("GodotPlugin"):
		print("Plugin does not exist!")
	
	if iOSConnection == null and ClassDB.class_exists("GodotPlugin"):
		iOSConnection = ClassDB.instantiate("GodotPlugin")
		iOSConnection.connect("output_message", pluginSignalTest)
	if iOSConnection:
		var methods = iOSConnection.get_method_list()
		for m in methods:
			print("Method: ",m.name)

		iOSConnection.trigger_swift_signal()
		$Label2.text = "Triggered swift signal."
		
		iOSConnection.request_authorization()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func pluginSignalTest(input) -> void:
	$Label.text = "Signal 'output' received: "+input


func _on_log_out_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
