extends Node2D

var iOSConnection: Variant = null

# Connection logic to the plugin
func _ready() -> void:
	if iOSConnection == null and ClassDB.class_exists("GodotPlugin"):
		iOSConnection = ClassDB.instantiate("GodotPlugin")
		iOSConnection.connect("output_message", pluginSignalTest)
	if iOSConnection:
		iOSConnection.trigger_swift_signal()
		$Label2.text = "Triggered swift signal."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func pluginSignalTest(input) -> void:
	$Label.text = "Signal 'output' received: "+input
