using Godot;

public partial class Joystick : Control
{
	// Hold the normalized input from joystick (between -1 and 1)
	public Vector2 PositionVector {get; set; } = Vector2.Zero;
}
