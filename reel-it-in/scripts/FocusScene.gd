extends Node2D

var iOSConnection: Variant = null
@onready var focus_button = $FocusButton

# Connection logic to the plugin
func _ready() -> void:
	if iOSConnection == null and ClassDB.class_exists("GodotPlugin"):
		iOSConnection = ClassDB.instantiate("GodotPlugin")
		iOSConnection.connect("Output", pluginSignalTest)
	if iOSConnection:
		$Label2.text = iOSConnection.connectToGodot()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func pluginSignalTest(input) -> void:
	$Label.text = "Signal 'output' received: "+input
