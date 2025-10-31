extends Node2D

var iOSConnection: Variant = null
@onready var focus_button = $FocusButton

# Connection logic to the plugin
func _ready() -> void:
	if iOSConnection == null and ClassDB.class_exists("GodotPlugin"):
		iOSConnection = ClassDB.instantiate("GodotPlugin")
		iOSConnection.connect("output", pluginTest)
	if iOSConnection:
		$Label2.text = "Connection instantiated"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func pluginTest() -> void:
	$Label.text = "Signal 'output' received"
