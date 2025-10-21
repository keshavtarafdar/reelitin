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
var scare_chance: float = 0.0016 # Chance to go into SCARED
var move_chance: float = 0.0064 # Chance to go inot SWIMMING
var calm_chance: float = 0.0016 # Chance to go into IDLE
var hook_chance: float = 0.35 # Chance to go into HOOKED
var break_chance: float = 0.0016 # Chance break off of the line 

# Advanced fish behavior parameters
var depth_explore_range: float = 20 # Max number of degrees the fish swims vertically 
var swim_dir_duration: float = 2.5 # Controls how long a fish swims in one direction
var energy: float = 0.00005 # Increase for a more active fish --> More state changes
var ideal_depth: float = 50 # What y coordinate the fish prefers to stay at
var depth_pref_level: float = 1 # How much a fish wants to stay at its ideal depth
var depth_adherence: float = 10 # The max angle (degrees) of swimming depth correction when far away from ideal depth

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
					
					# Determine swim angle
					var vertical_offset = self.global_position.y - ideal_depth
					var depth_bias = clamp(vertical_offset * depth_pref_level, -depth_adherence, depth_adherence) # Correct fish movement to go to its desired depth
					var base_angle = randf_range(-depth_explore_range, depth_explore_range)
					var swim_angle = deg_to_rad(base_angle + (depth_explore_range + depth_bias))
					
					var direction_rand = sign(randf() - 0.5) # Determines R/L movement, (1,-1)
					var swim_direction = Vector2(direction_rand*cos(swim_angle), sin(swim_angle)).normalized()
					print(swim_direction )
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
