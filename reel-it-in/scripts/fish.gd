extends CharacterBody2D

@export var hook : CharacterBody2D
@export var player : CharacterBody2D
@onready var fish_anim = get_node("FishAnim")
@onready var player_anim_tree : AnimationTree = player.get_node("AnimationTree")
@onready var anim_state = player_anim_tree["parameters/playback"]

# Swimming physics variables
var fish_max_speed: int = 25
var fish_acceleration: float = 200
var friction: float = 10

# Bite physics variables
var bounce_speed: float = 10
var bounce_acceleration: float = 60
var bounce_duration: float = 0.15
var wait_duration: float = 0.75

# Hook interaction variables
var mouth_to_center = 0 # Pixels from the fishes location to its mouth used to make the fish snap to the hook correctly

# Fish behavior parameters
var scare_chance: float = 0.0016 # Chance to go into SCARED
var move_chance: float = 0.0064 # Chance to go inot SWIMMING
var calm_chance: float = 0.0016 # Chance to go into IDLE
var hook_chance: float = 0.35 # Chance to go into HOOKED
var break_chance: float = 0.0016 # Chance break off of the line 

# Advanced fish behavior parameters
var depth_explore_range: float = 30 # Max number of degrees the fish swims vertically 
var swim_dir_duration: float = 3 # Controls how long a fish swims in one direction
var energy: float = 0.00004 # Increase for a more active fish --> More state changes
var ideal_depth: float = 50 # What y coordinate the fish prefers to stay at
var max_depth_diff: float = 25 # How far away a fish can go from its ideal depth

# Tracking variables
var activity_level: float = 0.0 # A variable that cumulatively sums on itself. This makes it more likely for fish to change state the longer they are in one state.
var bounce_timer: float = 0.0
var isHooked: bool = false
var last_direction: Vector2 = Vector2(0,0)
var swim_dir_timer: float = 0.0


# State tracking

enum mobState {
	IDLE,
	SWIMMING,
	INTERESTED,
	SCARED,
	BITING,
	HOOKED,
	CAUGHT
}
var current_state: int


##### FUNCTIONS #####


func _ready():
	current_state = mobState["IDLE"]

# Helper function that changes states 
func change_state(state: String) -> void:
	current_state = mobState[state]
	activity_level = 0
	bounce_timer = 0
	swim_dir_timer = 0

# Helper function to the physics process function that controls fish movement.
func swim_physics(state_switch_rand: float, delta: float) -> void:
	fish_anim.play("Swim")
	if swim_dir_timer > 0:
		self.velocity = velocity.move_toward(last_direction * fish_max_speed, fish_acceleration * delta)
		swim_dir_timer -= delta
	else:
		# Determine swim angle --> depends on the fish's ideal depth
		var vertical_offset = ideal_depth - self.global_position.y
		var normalized_offset = clamp(vertical_offset / max_depth_diff, -1.0, 1.0)
		var depth_bias = 0.5 + 0.5 * tanh(normalized_offset * 2.0)
		var min_angle = -depth_explore_range * (1.0 - depth_bias)
		var max_angle = depth_explore_range * depth_bias
		var angle = deg_to_rad(randf_range(min_angle, max_angle))
		
		# Determine left or right movement
		var direction_rand = sign(randf() - 0.5)
		var swim_direction = Vector2(direction_rand*cos(angle), sin(angle)).normalized()
		
		self.velocity = velocity.move_toward(swim_direction * fish_max_speed, fish_acceleration * delta)
		last_direction = swim_direction
		swim_dir_timer = swim_dir_duration
	
	if state_switch_rand < calm_chance :
		change_state("IDLE")



func _physics_process(delta: float) -> void:
	if is_instance_valid(hook):

		var direction_to_hook = (hook.global_position - self.global_position).normalized()
		var distance_to_hook = (hook.global_position - self.global_position)
		var state_switch_rand = randf_range(0,1) - activity_level
		activity_level += energy

		match current_state:

			mobState["IDLE"]:
				self.velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
				fish_anim.play("Idle")
				if state_switch_rand < move_chance :
					change_state("SWIMMING")

			mobState["SWIMMING"]:
				fish_anim.play("Swim")
				if swim_dir_timer > 0:
					self.velocity = velocity.move_toward(last_direction * fish_max_speed, fish_acceleration * delta)
					swim_dir_timer -= delta
				else:
					# Determine swim angle --> depends on the fish's ideal depth
					var vertical_offset = ideal_depth - self.global_position.y
					var normalized_offset = clamp(vertical_offset / max_depth_diff, -1.0, 1.0)
					var depth_bias = 0.5 + 0.5 * tanh(normalized_offset * 2.0)
					var min_angle = -depth_explore_range * (1.0 - depth_bias)
					var max_angle = depth_explore_range * depth_bias
					var angle = deg_to_rad(randf_range(min_angle, max_angle))
					
					# Determine left or right movement
					var direction_rand = sign(randf() - 0.5)
					var swim_direction = Vector2(direction_rand*cos(angle), sin(angle)).normalized()
					
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
				if state_switch_rand < scare_chance :
					change_state("SCARED")
					last_direction = -direction_to_hook
					
				if bounce_timer > 0:
					bounce_timer -= delta
					self.velocity = velocity.move_toward(-direction_to_hook * bounce_speed, bounce_acceleration * delta)
				else:
					if distance_to_hook.length() > 11: # TODO this is super janky and needs to be changed in the future. 11 is a random number that worked
						self.velocity = velocity.move_toward(direction_to_hook * fish_max_speed, fish_acceleration * delta)
						if randf_range(0,1) < hook_chance:
							change_state("HOOKED")
					else:
						bounce_timer = bounce_duration
						self.velocity = velocity.move_toward(-direction_to_hook * bounce_speed, bounce_acceleration * delta)

			mobState["SCARED"]:
				fish_anim.play("Swim")
				self.velocity = velocity.move_toward(-direction_to_hook * fish_max_speed, fish_acceleration * delta)
				if randf_range(0,1) < calm_chance :
					change_state("IDLE")

			mobState["HOOKED"]:
				fish_anim.play("Swim")
				self.velocity = hook.velocity 

			mobState["CAUGHT"]:
				fish_anim.play("Idle")

		if last_direction.x < 0:
			fish_anim.flip_h = true
		else:
			fish_anim.flip_h = false

		move_and_slide()
		#print("Current state: %s | Velocity: %v | Distance To Hook: %f" % [current_state, velocity, distance_to_hook.length()])

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
