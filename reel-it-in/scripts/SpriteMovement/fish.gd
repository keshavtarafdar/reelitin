extends CharacterBody2D
class_name Fish

@export var hook : CharacterBody2D
@export var player : CharacterBody2D
@export var item_scene : PackedScene
@export var item_res : Item
@onready var fish_anim = get_node("FishAnim")
@onready var player_anim_tree : AnimationTree = player.get_node("AnimationTree")
@onready var anim_state = player_anim_tree["parameters/playback"]

# Swimming physics variables
var fish_max_speed: int = 25
var fish_acceleration: int = 200
var friction: int = 10

# Bite physics variables
var bounce_speed: float = 10
var bounce_acceleration: float = 60
var bounce_duration: float = 0.15

# Controls where the fish item spawns after fish is caught
var player_fish_hold_pos: Vector2 = Vector2.ZERO

# Hook interaction variables
var mouth_to_center = 8 # Pixels from the fishes location to its mouth used to make the fish snap to the hook correctly
var fish_power: float = 0.1 # How much a fish can resist fishing rod movement

# Fish behavior parameters
var interest_chance: float = 0.05 # Chance that fish gets INTERESTED when close enough to hook
var bite_chance: float = 1 # Chance that the fish goes in to BITING state when close enough to hook
var scare_chance: float = 0.0008 # Chance to go into SCARED when hooked, biting, or interested
var move_chance: float = 0.0064 # Chance to go into SWIMMING
var idle_chance: float = 0.0032 # Chance to go into IDLE when in SWIMMING
var calm_chance: float = 0.0064 # Chance to go into IDLE when SCARED
var hook_chance: float = 0.5 # Chance to go into HOOKED
var break_chance: float = 0.000 # Chance to go into SCARED when in HOOKED

# Advanced fish behavior parameters
var depth_explore_range: float = 30 # Max number of degrees the fish swims vertically 
var swim_dir_duration: float = 3 # Controls how long a fish swims in one direction
var energy: float = 0.00002 # Increase for a more active fish --> More state changes
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
	print(state)

# Helper function to the physics process function that controls fish movement.
func swim_physics(delta: float) -> Vector2:
	
	var swim_velocity: Vector2 = self.velocity
	
	if swim_dir_timer > 0:
		swim_velocity = self.velocity.move_toward(last_direction * fish_max_speed, fish_acceleration * delta)
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
		
		swim_velocity = self.velocity.move_toward(swim_direction * fish_max_speed, fish_acceleration * delta)
		last_direction = swim_direction
		swim_dir_timer = swim_dir_duration
	
	return swim_velocity

# Method to detect if there is a hook within the interest range radias of a fish
func detectHook() -> void:
	if hook.current_state == hook.mobState['FLOATING']:
		var bodies = $InterestRange.get_overlapping_bodies()
		if bodies.size() > 0:
			for body in bodies:
				if body.is_in_group("Hook") and randf_range(0,1) < interest_chance:
					change_state("INTERESTED")

# Method to detect if there is a hook within the bite range radias of a fish
func biteHook() -> void:
	var bodies = $BiteRange.get_overlapping_bodies()
	if bodies.size() > 0:
		for body in bodies:
			if body.is_in_group("Hook") and randf_range(0,1) < bite_chance:
				change_state("BITING")

# Houses the fish state machine
func _physics_process(delta: float) -> void:
	if is_instance_valid(hook):

		var direction_to_hook = (hook.global_position - self.global_position).normalized()
		var distance_to_hook = (hook.global_position - self.global_position)
		var state_switch_rand = randf_range(0,1) - activity_level
		activity_level += energy
		
		if get_parent() == hook:
			if hook.get_current_state() == "INVISIBLE":
				current_state = mobState["CAUGHT"]
		
		match current_state:
			mobState["IDLE"]:
				detectHook()
				self.velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
				fish_anim.play("Idle")
				if state_switch_rand < move_chance :
					change_state("SWIMMING")

			mobState["SWIMMING"]:
				detectHook()
				fish_anim.play("Swim")
				self.velocity = swim_physics(delta)
				if state_switch_rand < idle_chance :
					change_state("IDLE")

			mobState["INTERESTED"]:
				biteHook()
				self.velocity = velocity.move_toward(direction_to_hook * fish_max_speed * 0.5, fish_acceleration * delta)
				last_direction = direction_to_hook
				fish_anim.play("Swim")

			mobState["BITING"]:
				if state_switch_rand < scare_chance :
					change_state("SCARED")
					
				if bounce_timer > 0:
					bounce_timer -= delta
					self.velocity = velocity.move_toward(-direction_to_hook * bounce_speed, bounce_acceleration * delta)
				else:
					if distance_to_hook.length() > 11: # TODO this is super janky and needs to be changed in the future. 11 is a random number that worked
						self.velocity = velocity.move_toward(direction_to_hook * fish_max_speed, fish_acceleration * delta)
					else:
						if randf_range(0,1) < hook_chance:
							change_state("HOOKED")
						bounce_timer = bounce_duration
						self.velocity = velocity.move_toward(-direction_to_hook * bounce_speed, bounce_acceleration * delta)

			mobState["SCARED"]:
				last_direction = -direction_to_hook
				fish_anim.play("Swim")
				self.velocity = velocity.move_toward(-direction_to_hook * fish_max_speed, fish_acceleration * delta)
				if randf_range(0,1) < calm_chance :
					change_state("IDLE")

			mobState["HOOKED"]:
				fish_anim.play("Swim")
				# Set collision mask to not see fish so fish can phase into the hook
				self.set_collision_mask_value(3, false)
				
				# line up the fish mouth with the hook properly
				var fish_orientation = sign(-last_direction.x)
				
				# Have the fish follow the hook --> all movement logic is now controlle by the hook
				self.reparent(hook)
				self.position = Vector2(fish_orientation * mouth_to_center, 0)
				
				
				# Fish breaks off from hook
				# Dynamic break chance: lower if player input matches fish trying-to-go direction, otherwise increase
				var dynamic_break = break_chance
				# Use hook.player.player_joystick.position_vector when available to determine input match
				if is_instance_valid(hook) and hook.player:
					var joy_vec = Vector2.ZERO
					if "player_joystick" in hook.player and hook.player.player_joystick:
						joy_vec = hook.player.player_joystick.position_vector
					# Only consider horizontal matching primarily (reeling left/right)
					if joy_vec.length() > 0.2:
						var dot = joy_vec.normalized().dot(last_direction.normalized())
						if dot > 0.5:
							# player is pushing roughly in same direction as fish -> reduce chance of break
							dynamic_break *= 0.25
						else:
							# player not matching -> increase chance
							dynamic_break *= 1.8
					else:
						# no input -> moderately higher chance to break
						dynamic_break *= 1.0

				if state_switch_rand < dynamic_break :
					if self.get_parent() == hook:
						# might need to change this if hook becomes child of player
						self.reparent(hook.get_parent()) 
					change_state("SCARED")

					self.set_collision_mask_value(3, true)
					last_direction = -direction_to_hook
			mobState["CAUGHT"]:
				self.visible = false
				spawn_item()
				# DO SOMETHING WITH INVENTORY NED!!!!! VAMOS

		if last_direction.x < 0:
			fish_anim.flip_h = true
		else:
			fish_anim.flip_h = false
		move_and_slide()
		#print("Current state: %s | Velocity: %v | Distance To Hook: %f" % [current_state, velocity, distance_to_hook.length()])
		

func spawn_item() -> void:
	var fish_item_instance = item_scene.instantiate()
	fish_item_instance.fish_CPU = self
	fish_item_instance.item_res = item_res
	fish_item_instance.global_position = player_fish_hold_pos
	get_tree().current_scene.add_child(fish_item_instance)
	
