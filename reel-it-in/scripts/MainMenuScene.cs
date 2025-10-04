using Godot;
using System;

public partial class MainMenuScene : Control
{
	private AnimationPlayer _animationPlayer;
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		_animationPlayer = GetNode<AnimationPlayer>("ColorRect/AnimationPlayer");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	
	private void _on_go_fish_button_pressed()
	{
		_animationPlayer.Connect("animation_finished", new Callable(this, nameof(OnAnimationFinished)));
		_animationPlayer.Play("Fade");
		
		
	}
	private void OnAnimationFinished(string animName){
		
		GetTree().ChangeSceneToFile("res://scenes/RiverScene.tscn");
	}
	
	private void _on_focus_mode_button_pressed()
	{
		// ready for when focus mode scene is made
	}
}
