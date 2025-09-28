using Godot;

public partial class Joystick : Node2D
{
	// Hold the normalized input from joystick (between -1 and 1)
	public Vector2 PositionVector {get; set; } = Vector2.Zero;
}
