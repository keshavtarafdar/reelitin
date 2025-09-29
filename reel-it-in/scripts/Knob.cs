using Godot;
public partial class Knob : Sprite2D
{
	[Export] public float MaxLength {get; set; } = 15.0f; // max drag length
	[Export] public float DeadZone {get; set; } = 5.0f; // min drag to be recognized as input
	
	private Joystick _parentJoystick;
	private bool _isPressing = false;
	
	// Ran when the node is added to the scene (just adding reference to parent)
	public override void _Ready()
	{
		_parentJoystick = GetParent<Joystick>();
		if (_parentJoystick == null)
		{
			GD.PrintErr("Knob: Parent Joystick node not found!");
		}
	}
	
	// Ran whenever any input happend
	public override void _Input(InputEvent @event)
	{
		if (!_isPressing)
			return;
		
		if (@event is InputEventMouseMotion mouseMotionEvent)
		{
			Position = GetParent<Control>().GetLocalMousePosition();
		}
	}

	// Runs on every single frame, handles knob moving
	public override void _Process(double delta)
	{
		Vector2 offset = Position;
		float distance = offset.Length();
		
		float currentMaxLength = MaxLength * GetParent<Control>().Scale.X;

		if (distance > currentMaxLength)
		{
			Position = offset.Normalized() * currentMaxLength;
		}
		
		if (!_isPressing)
		{
			Position = Position.Lerp(Vector2.Zero, (float)delta * 10.0f);
		}

		CalculateVector();
	}

	// Called when TouchButton is pressed
	private void _on_TouchButton_pressed()
	{
		GD.Print("Joystick Pressed!"); // Add this line
		_isPressing = true;
	}

	// Called when TouchButton is released
	private void _on_TouchButton_released()
	{
		_isPressing = false;
	}

	// Calculates the joystick's output vector (normalized)
	private void CalculateVector()
	{
		Vector2 diff = Position;
		float currentMaxLength = MaxLength * GetParent<Control>().Scale.X;
		
		Vector2 outputVector = Vector2.Zero;
		if (Mathf.Abs(diff.X) >= DeadZone)
		{
			outputVector.X = diff.X / currentMaxLength;
		}
		if (Mathf.Abs(diff.Y) >= DeadZone)
		{
			outputVector.Y = diff.Y / currentMaxLength;
		}
		
		_parentJoystick.PositionVector = outputVector.Clamp(new Vector2(-1, -1), new Vector2(1, 1));
	}
}
