using Godot;
public partial class Knob : Sprite2D
{
	[Export] public float MaxLength {get; set; } = 50.0f;
	[Export] public float DeadZone {get; set; } = 5.0f;
	
	private Joystick _parentJoystick;
	private bool _isPressing = false;
	
	public override void _Ready()
	{
		if (_isPressing)
		{
			Vector2
		}
	}
}
