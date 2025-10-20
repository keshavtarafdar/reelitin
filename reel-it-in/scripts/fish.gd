extends CharacterBody2D

@export var hook : CharacterBody2D
@export var player : CharacterBody2D
@onready var fish_anim = get_node("FishAnim")
@onready var player_anim_tree : AnimationTree = player.get_node("AnimationTree")
@onready var anim_state = player_anim_tree["parameters/playback"]

# Swimming physics variables
var fish_max_speed: int = 25
var fish_acceleration: float = 200

# Bite physics variables
var bounce_speed: float = 10
var bounce_acceleration: float = 60
var bounce_duration: float = 0.15
var wait_duration: float = 0.75

# Fish behavior parameters
var scare_chance: float = 0.0016
var move_chance: float = 0.0064
var calm_chance: float = 0.0016
var depth_explore_range: float = 30 # degrees
var swim_dir_duration: float = 2.5 # Controls how long a fish swims in one direction
var swim_dir_timer: float = 0.0
var energy: float = 0.00005 # Value that increments activity level. Increase for a more active fish.
var ideal_depth: float = 0 # What y coordinate the fish prefers to stay at

# Tracking variables
var activity_level: float = 0.0 # A variable that cumulatively sums on itself. This makes it more likely for fish to change state the longer they are in one state.
var bounce_timer: float = 0.0
var isHooked: bool = false
var last_direction: Vector2 = Vector2(0,0)


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

# Helper function that changes states 
func change_state(state: String) -> void:
	current_state = mobState[state]
	activity_level = 0

func _physics_process(delta: float) -> void:
	if is_instance_valid(hook):

		var direction_to_hook = (hook.global_position - self.global_position).normalized()
		var distance_to_hook = (hook.global_position - self.global_position)
		var state_switch_rand = randf_range(0,1) - activity_level
		activity_level += energy

		match current_state:

			mobState["IDLE"]:
				self.velocity = Vector2(0,0)
				fish_anim.play("Idle")
				if state_switch_rand < move_chance :
					change_state("SWIMMING")

			mobState["SWIMMING"]:
				fish_anim.play("Swim")
				if swim_dir_timer > 0:
					self.velocity = velocity.move_toward(last_direction * fish_max_speed, fish_acceleration * delta)
					swim_dir_timer -= delta
				else:
					var swim_angle = deg_to_rad(randf_range(-depth_explore_range, depth_explore_range))
					var direction_rand = sign(randf() - 0.5) # Determines R/L movement, (1,-1)
					var swim_direction = Vector2(direction_rand*cos(swim_angle), sin(swim_angle)).normalized()
					self.velocity = velocity.move_toward(swim_direction * fish_max_speed, fish_acceleration * delta)
					last_direction = swim_direction
					swim_dir_timer = swim_dir_duration
				
				if state_switch_rand < calm_chance :
					change_state("IDLE")

			mobState["INTERESTED"]:
				self.velocity = velocity.move_toward(direction_to_hook*fish_max_speed*0.5, fish_acceleration * delta)
				last_direction = direction_to_hook
				fish_anim.play("Swim")

			mobState["BITING"]:
				# Small chance every frame to get scared
				if state_switch_rand < scare_chance :
					change_state("SCARED")
					last_direction = -direction_to_hook
				if bounce_timer > 0:
					bounce_timer -= delta
					self.velocity = velocity.move_toward(-direction_to_hook * bounce_speed, bounce_acceleration * delta)
				else:
					if distance_to_hook.length() > 11: # TODO this is super janky and needs to be changed in the future. 11 is a random number that worked
						self.velocity = velocity.move_toward(direction_to_hook * fish_max_speed, fish_acceleration * delta)
					else:
						bounce_timer = bounce_duration
						self.velocity = velocity.move_toward(-direction_to_hook * bounce_speed, bounce_acceleration * delta)

			mobState["SCARED"]:
				fish_anim.play("Swim")
				self.velocity = velocity.move_toward(-direction_to_hook * fish_max_speed, fish_acceleration * delta)
				if randf_range(0,1) < calm_chance :
					change_state("IDLE")

			mobState["HOOKED"]:
				pass

			mobState["CAUGHT"]:
				fish_anim.play("Idle")

		if last_direction.x < 0:
			fish_anim.flip_h = true
		else:
			fish_anim.flip_h = false

		move_and_slide()
		print("Current state: %s | Velocity: %v | Distance To Hook: %f" % [current_state, velocity, distance_to_hook.length()])

func _on_interest_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		change_state("INTERESTED")

func _on_interest_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		change_state("IDLE")

func _on_bite_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		change_state("BITING")

func _on_bite_range_body_exited(_body: Node2D) -> void:
	pass
