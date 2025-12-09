extends HBoxContainer

#Disable keyboard pop up
func _ready() -> void:
	var line_edit1 = $HoursInput.get_line_edit()
	line_edit1.virtual_keyboard_enabled = false
	
	var line_edit2 = $MinutesInput.get_line_edit()
	line_edit2.virtual_keyboard_enabled = false
