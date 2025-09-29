using Godot;
using System;

public partial class PlayerMovement : CharacterBody2D
{
	[Export] public float MaxSpeed = 120f;
	[Export] public float Acceleration = 100f;
	[Export] public float Friction = 100f;

	private AnimationTree _animTree;
	private AnimationNodeStateMachinePlayback _animState;

	private float _lastDirection = 1f; // 1 = right, -1 = left

	public override void _Ready()
	{
		_animTree = GetNode<AnimationTree>("AnimationTree");
		_animTree.Active = true;

		_animState = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/playback");
	}

	public override void _PhysicsProcess(double delta)
	{
		Vector2 velocity = Velocity;
		float deltaF = (float)delta;

		// Input (-1 = left, 1 = right, 0 = none)
		float inputDir = Input.GetActionStrength("ui_right") - Input.GetActionStrength("ui_left");
		
		// Update last facing direction if input exists
		if (inputDir != 0)
			_lastDirection = inputDir;

		if (inputDir != 0)
		{
			// Move character
			velocity.X = Mathf.MoveToward(velocity.X, inputDir * MaxSpeed, Acceleration * deltaF);

			// Update Row blend based on last direction
			_animTree.Set("parameters/Row/BlendSpace1D/blend_position", _lastDirection);

			// Switch to Row animation
			_animState.Travel("Row");
		}
		else
		{
			// Apply friction
			velocity.X = Mathf.MoveToward(velocity.X, 0, Friction * deltaF);

			// Set Idle blend based on last direction
			_animTree.Set("parameters/Idle/BlendSpace1D/blend_position", _lastDirection);

			// Switch to Idle
			_animState.Travel("Idle");
		}

		Velocity = velocity;
		MoveAndSlide();
	}
}
