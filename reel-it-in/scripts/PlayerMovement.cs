using Godot;
using System;

public partial class PlayerMovement : CharacterBody2D
{
	[Export] public float Speed = 200f;

	public override void _PhysicsProcess(double delta)
	{
		Vector2 velocity = Velocity;

		// Only horizontal movement
		velocity.X = 0;
		velocity.Y = 0; // optional if you never move vertically

		if (Input.IsActionPressed("ui_left"))
			velocity.X = -Speed;
		else if (Input.IsActionPressed("ui_right"))
			velocity.X = Speed;

		Velocity = velocity;
		MoveAndSlide();
	}
}
