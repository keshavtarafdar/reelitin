extends CharacterBody2D
class_name Fish

@export var hook : CharacterBody2D
@export var player : CharacterBody2D
@export var item_scene : PackedScene
@export var item_res : Item
@onready var fish_anim = get_node("FishAnim")

# QTE (Quick Time Event) variables
var qte_direction: Vector2 = Vector2.ZERO  # Current required direction
var qte_timer: float = 0.0  # Time until direction changes
var qte_interval: float = 0.5  # How often direction changes (seconds)
var qte_indicator: Label = null  # Visual indicator for player

# Swimming physics variables
var fish_max_speed: int = 25
var fish_acceleration: int = 200
var friction: int = 10

# Bite physics variables
var bounce_speed: float = 10
var bounce_acceleration: float = 60
var bounce_duration: float = 0.15

# Controls where the fish item spawns after fish is caught
var player_fish_hold_pos: Vector2 = Vector2(6,-8)

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
var break_chance: float = 0.001 # Chance to go into SCARED when in HOOKED

# Advanced fish behavior parameters
var depth_explore_range: float = 30 # Max number of degrees the fish swims vertically 
var swim_dir_duration: float = 3 # Controls how long a fish swims in one direction
var energy: float = 0.00002 # Increase for a more active fish --> More state changes
var ideal_depth: float = 50 # What y coordinate the fish prefers to stay at
var max_depth_diff: float = 25 # How far away a fish can go from its ideal depth
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
	_setup_qte_indicator()

# Helper function that changes states 
func change_state(state: String) -> void:
	current_state = mobState[state]
	activity_level = 0
	bounce_timer = 0
	swim_dir_timer = 0
	print(state)
	# If this fish starts biting or gets hooked, nearby fish should get scared
	if state == "BITING" or state == "HOOKED":
		scare_nearby_fish()
	
	# Initialize QTE when hooked
	if state == "HOOKED":
		_start_qte()
	# Clean up QTE when leaving hooked state
	elif current_state != mobState["HOOKED"]:
		_stop_qte()

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

func _setup_qte_indicator() -> void:
	# Create visual indicator for directional input
	qte_indicator = Label.new()
	qte_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qte_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	qte_indicator.add_theme_font_size_override("font_size", 48)
	qte_indicator.modulate = Color(1, 1, 0, 1)  # Yellow
	qte_indicator.position = Vector2(-24, -60)  # Above fish
	qte_indicator.visible = false
	qte_indicator.z_index = 100
	add_child(qte_indicator)

func _start_qte() -> void:
	qte_timer = 0.0
	_pick_new_direction()
	if qte_indicator:
		qte_indicator.visible = true

func _stop_qte() -> void:
	qte_direction = Vector2.ZERO
	qte_timer = 0.0
	if qte_indicator:
		qte_indicator.visible = false

func _pick_new_direction() -> void:
	# Randomly pick one of four directions
	var directions = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]
	qte_direction = directions[randi() % 4]
	qte_timer = qte_interval
	
	# Update visual indicator
	if qte_indicator:
		if qte_direction == Vector2.UP:
			qte_indicator.text = "↑"
		elif qte_direction == Vector2.DOWN:
			qte_indicator.text = "↓"
		elif qte_direction == Vector2.LEFT:
			qte_indicator.text = "←"
		elif qte_direction == Vector2.RIGHT:
			qte_indicator.text = "→"

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
				
				# Update QTE timer and pick new direction when needed
				qte_timer -= delta
				if qte_timer <= 0:
					_pick_new_direction()
				
				# Fish breaks off from hook
				# Dynamic break chance: lower if player matches QTE direction, otherwise increase
				var dynamic_break = break_chance
				# Use hook.player.player_joystick.position_vector when available to determine input match
				if is_instance_valid(hook) and hook.player:
					var joy_vec = Vector2.ZERO
					if "player_joystick" in hook.player and hook.player.player_joystick:
						joy_vec = hook.player.player_joystick.position_vector
					# Check if player input matches required QTE direction
					if joy_vec.length() > 0.2:
						# Normalize and compare to required direction
						var dot = joy_vec.normalized().dot(qte_direction.normalized())
						if dot > 0.7:
							# Player matched the direction! -> reduce break chance significantly
							dynamic_break *= 0.1
							# Flash indicator green on success
							if qte_indicator:
								qte_indicator.modulate = Color(0, 1, 0, 1)
						else:
							# Player pushed wrong direction -> massively increase break chance
							dynamic_break *= 3.0
							# Flash indicator red on failure
							if qte_indicator:
								qte_indicator.modulate = Color(1, 0, 0, 1)
					else:
						# No input -> moderate increase to break chance
						dynamic_break *= 1.5
						# Reset indicator to yellow
						if qte_indicator:
							qte_indicator.modulate = Color(1, 1, 0, 1)
				if state_switch_rand < dynamic_break:
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
				if self.global_position.y >= water_level:
				# Splash into water and become scared
					self.velocity.y = 0  # Stop falling
					change_state("SCARED")
				# Swim away in a random horizontal direction
					last_direction = Vector2(sign(randf() - 0.5), 0.5).normalized()
		
			mobState["CAUGHT"]:
				self.reparent(hook.get_parent().get_parent()) 
				if !item_dropped:
					spawn_item()
					player.hold_fish()
					self.visible = false
				elif !is_instance_valid(item_scene):
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
	
	# Rotate it by 90 degrees clockwise
	fish_item_instance.rotation = deg_to_rad(90)
	
	get_tree().current_scene.add_child(fish_item_instance)
	item_dropped = true
