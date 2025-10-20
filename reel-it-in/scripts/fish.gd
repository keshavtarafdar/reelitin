extends CharacterBody2D

@export var hook : CharacterBody2D
@export var player : CharacterBody2D
@onready var fish_anim = get_node("FishAnim")
@onready var player_anim_tree : AnimationTree = player.get_node("AnimationTree")
@onready var anim_state = player_anim_tree["parameters/playback"]

# Fish movement varoables
var fish_max_speed: int = 25
var isHooked: bool = false
var last_direction: Vector2 = Vector2(0,0)
var fish_acceleration: float = 200

# Variables to deal with bite physics
var bounce_speed: float = 10
var bounce_acceleration: float = 60
var bounce_duration: float = 0.15
var bounce_timer: float = 0.0
var wait_timer: float = 0.0
var wait_duration: float = 0.75

enum mobState {
	IDLE,
	SWIMMING,
	INTERESTED,
	SCARED,
	BITING,
	HOOKED,
	CAUGHT
}

var current_state

func _ready():
	current_state = mobState["IDLE"]

func _physics_process(delta: float) -> void:
	if is_instance_valid(hook):
		var direction_to_hook = (hook.global_position - self.global_position).normalized()
		var distance_to_hook = (hook.global_position - self.global_position)
		match current_state:
			mobState["IDLE"]:
				velocity = Vector2(0,0)
				fish_anim.play("Idle")
			mobState["SWIMMING"]:
				fish_anim.play("Swim")
			mobState["INTERESTED"]:
				self.velocity = velocity.move_toward(direction_to_hook*fish_max_speed*0.5, fish_acceleration * delta)
				last_direction = direction_to_hook
				fish_anim.play("Swim")
			mobState["BITING"]:
				# Small chance every frame to get scared
				if randf_range(0,1) < 0.0001 :
					current_state = mobState["SCARED"]
				if bounce_timer > 0:
					bounce_timer -= delta
					self.velocity = velocity.move_toward(-direction_to_hook * bounce_speed, bounce_acceleration * delta)
				else:
					if distance_to_hook.length() > 11: # TODO this is super janky and needs to be changed in the future. 11 is a random number that worked
						velocity = velocity.move_toward(direction_to_hook * fish_max_speed, fish_acceleration * delta)
					else:
						bounce_timer = bounce_duration
						velocity = velocity.move_toward(-direction_to_hook * bounce_speed, bounce_acceleration * delta)
			mobState["SCARED"]:
				fish_anim.play("Swim")
				velocity = velocity.move_toward(-direction_to_hook * fish_max_speed, fish_acceleration * delta)
			mobState["HOOKED"]:
				pass
			mobState["CAUGHT"]:
				fish_anim.play("Idle")

		if last_direction.x < 0:
			fish_anim.flip_h = true
		else:
			fish_anim.flip_h = false
		
		move_and_slide()
		print(bounce_timer)
		print("Current state: %s | Velocity: %v | Distance To Hook: %f" % [current_state, velocity, distance_to_hook.length()])

func _on_interest_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		current_state = mobState["INTERESTED"]

func _on_interest_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		current_state = mobState["IDLE"]

func _on_bite_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		current_state = mobState["BITING"]

func _on_bite_range_body_exited(_body: Node2D) -> void:
	pass
