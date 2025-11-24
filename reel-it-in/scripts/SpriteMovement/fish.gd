extends CharacterBody2D
class_name Fish

@export var hook : CharacterBody2D
@export var player : CharacterBody2D
@export var item_scene : PackedScene
@export var item_res : Item
@onready var fish_anim = get_node("FishAnim")

@export var catchdifficulty: float = 1.0

# Hook swim variables
var angle = 0.0
var angular_velocity = 0.0
var angular_velocity_target = 0.0
var angle_change_timer = 0.0


# Swimming physics variables
@export var fish_max_speed: int = 25
@export var fish_acceleration: int = 200
var friction: int = 10

# Bite physics variables
var bounce_speed: float = 10
var bounce_acceleration: float = 60
var bounce_duration: float = 0.15

# Controls where the fish item spawns after fish is caught
@export var player_fish_hold_pos: Vector2 = Vector2(6,-8)

# Hook interaction variables
var mouth_to_center = 8 # Pixels from the fishes location to its mouth used to make the fish snap to the hook correctly
@export var fish_power: float = 0.05 # How much a fish can resist fishing rod movement

# Fish behavior parameters
@export var interest_chance: float = 0.05 # Chance that fish gets INTERESTED when close enough to hook
@export var bite_chance: float = 1 # Chance that the fish goes in to BITING state when close enough to hook
@export var scare_chance: float = 0.0008 # Chance to go into SCARED when hooked, biting, or interested
@export var move_chance: float = 0.0064 # Chance to go into SWIMMING
@export var idle_chance: float = 0.0032 # Chance to go into IDLE when in SWIMMING
@export var calm_chance: float = 0.0064 # Chance to go into IDLE when SCARED
@export var hook_chance: float = 0.5 # Chance to go into HOOKED
@export var break_chance: float = 0.001 # Chance to go into SCARED when in HOOKED

# Advanced fish behavior parameters
@export var depth_explore_range: float = 30 # Max number of degrees the fish swims vertically 
@export var swim_dir_duration: float = 3 # Controls how long a fish swims in one direction
@export var energy: float = 0.00002 # Increase for a more active fish --> More state changes
@export var ideal_depth: float = 50 # What y coordinate the fish prefers to stay at
@export var max_depth_diff: float = 25 # How far away a fish can go from its ideal depth
@export var scare_radius: float = 60.0 # Radius within which other fish get scared by bites/hooks

# Tracking variables
var activity_level: float = 0.0 # A variable that cumulatively sums on itself. This makes it more likely for fish to change state the longer they are in one state.
var bounce_timer: float = 0.0
var isHooked: bool = false
var last_direction: Vector2 = Vector2(0,0)
var swim_dir_timer: float = 0.0
var item_dropped: bool = false

# Water and physics
var water_level: float = 0.0  # Y-coordinate where water surface is (0 or positive values are in water)
var gravity: float = 400.0  # Gravity acceleration for falling

# State tracking
enum mobState {
	IDLE,
	SWIMMING,
	INTERESTED,
	SCARED,
	BITING,
	HOOKED,
	CAUGHT,
	FALLING
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
	# If this fish starts biting or gets hooked, nearby fish should get scared
	if state == "BITING" or state == "HOOKED":
		scare_nearby_fish()


func scare_nearby_fish() -> void:
	# Notify nearby fish to enter SCARED state when this fish bites or is hooked
	var fishes = get_tree().get_nodes_in_group("Fish")
	for f in fishes:
		if f == self:
			continue
		if not is_instance_valid(f):
			continue
		if not (f is Fish):
			continue
		# Don't override if already hooked or caught
		if f.current_state == f.mobState["HOOKED"] or f.current_state == f.mobState["CAUGHT"]:
			continue
		var d = (f.global_position - self.global_position).length()
		if d <= scare_radius:
			f.change_state("SCARED")




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

func hooked_swim_physics(delta: float) -> Vector2:
	var swim_velocity: Vector2 = self.velocity

	angle_change_timer -= delta
	if angle_change_timer <= 0.0:
		# Random value between -max_turn_speed and +max_turn_speed
		var max_turn_speed = catchdifficulty * 2.0  # radians/sec
		angular_velocity_target = randf_range(-max_turn_speed, max_turn_speed)

		# Harder fish = more frequent changes
		var base_time = 0.5
		var interval = base_time / max(catchdifficulty, 0.1)
		angle_change_timer = interval

	var angular_accel := 3.0 * catchdifficulty  # how fast it can change angular velocity
	angular_velocity = lerp(
		angular_velocity,
		angular_velocity_target,
		angular_accel * delta
	)

	angle += angular_velocity * delta
	swim_velocity = Vector2.from_angle(angle) * 0.5 * fish_max_speed

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
		var break_rand = randf_range(0,1)
		activity_level += energy
		
		if get_parent() == hook:
			if hook.get_current_state() == "INVISIBLE":
				current_state = mobState["CAUGHT"]
				
		else:
			if global_position.y < 0:
				current_state = mobState['FALLING']
		
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
						player.bite()
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
				
				if self.velocity.y < 0:
					self.velocity.y *= -1
				
				# Start with base break chance
				var dynamic_break = break_chance

				# Handles catch mechanic
				if is_instance_valid(hook) and hook.player:
					
					var joy_vec := Vector2.ZERO
					if "player_joystick" in hook.player and hook.player.player_joystick:
						joy_vec = player.player_joystick.position_vector.normalized()
					var fish_dir = hook.velocity.normalized()
					if joy_vec.length() > 0.05:
						
						var alignment := fish_dir.dot(joy_vec)
						if alignment > 0.8:
							hook.indicator.modulate = Color(0, 1, 0)
							dynamic_break *= 0
						elif alignment > 0.2:
							hook.indicator.modulate = Color(1, 1, 1)
							dynamic_break *= 0.25
						else:
							hook.indicator.modulate = Color(1, 0, 0)
							dynamic_break *= 5
					else:
						hook.indicator.modulate = Color(1, 1, 1)

				if break_rand < dynamic_break:
					if self.get_parent() == hook:
						self.reparent(get_tree().get_current_scene())
						
					self.set_collision_mask_value(3, true)
				
				# Check if fish is above water when breaking off
					if self.global_position.y < water_level:
					# Fish is above water - make it fall
						change_state("FALLING")
					else:
					# Fish is in water - swim away scared
						change_state("SCARED")
						last_direction = -direction_to_hook
		
			mobState["FALLING"]:
				fish_anim.play("Idle")
			# Apply gravity to fall down quickly
				self.velocity.y += gravity * delta
			# Keep minimal horizontal velocity (slight drift)
				self.velocity.x = move_toward(self.velocity.x, 0, friction * delta * 0.5)
			
			# Check if fish has reached water level
				if self.global_position.y >= water_level+5:
				# Splash into water and become scared
					self.velocity.y = 0  # Stop falling
					change_state("SCARED")
				# Swim away in a random horizontal direction
					last_direction = Vector2(sign(randf() - 0.5), 0.5).normalized()
		
			mobState["CAUGHT"]:
				self.reparent(hook.get_parent().get_parent()) 
				spawn_item()
				player.hold_fish()
				self.queue_free()
		if last_direction.x < 0:
			fish_anim.flip_h = true
		else:
			fish_anim.flip_h = false
		move_and_slide()
		#print("Current state: %s | Velocity: %v | Distance To Hook: %f" % [current_state, velocity, distance_to_hook.length()])

func spawn_item() -> void:
	# Safety check: ensure item_scene is assigned before trying to instantiate
	if item_scene == null:
		push_error("Fish.spawn_item: item_scene is null - cannot spawn item")
		item_dropped = true  # Mark as dropped to prevent repeated errors
		return
	
	var fish_item_instance = item_scene.instantiate()
	fish_item_instance.item_res = item_res
	fish_item_instance.player = player
	fish_item_instance.global_position = player.global_position + player_fish_hold_pos
	player.caught_fish = fish_item_instance
	
	# Rotate it by 90 degrees clockwise
	fish_item_instance.rotation = deg_to_rad(90)
	
	get_tree().current_scene.add_child(fish_item_instance)
	item_dropped = true
