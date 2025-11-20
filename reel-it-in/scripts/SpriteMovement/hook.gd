extends CharacterBody2D

@export var player : CharacterBody2D
@export var fish : CharacterBody2D # Dynamically assigned when a fish becomes a child node

@onready var indicator = $"Indicator"
var indicator_distance := 16.0  # how far from the hook you want it


# Reeling configuration
var reel_speed: float = 80 # pixels per second when reeling
var close_threshold: float = 1 # distance in pixels to snap back to player
var catch_threshold: float = 30

# Hook physics variables
var water_friction: int = 1800
var surface_tension: int = 3000
var hook_weight: int = 600
var offset: Vector2
var gravity: float = 400.0
var water_level: float = 0.0
var cast_angle: float = 0.0
var cast_speed: float = 0.0
var cast_start_pos: Vector2
var target_y_level: float = 50.0


# State tracking
enum mobState {
	DEBUG,
	INVISIBLE,
	CASTING,
	CASTED,
	FLOATING,
	HOOKED,
	REELING,
	FALLING
}
var current_state: int

func _ready():
	current_state = mobState["INVISIBLE"] # Set to floating for testing

func checkForFish() -> void:
	for child in self.get_children():
		if child.is_in_group("Fish"):
			fish = child
			current_state = mobState['HOOKED']
		else:
			# No fish attached - check if above water
			if self.global_position.y < water_level:
				current_state = mobState['FALLING']
			else:
				current_state = mobState['FLOATING']

func update_indicator():
	indicator.visible = true
	if fish == null:
		indicator.visible = false
		return
		
	# Direction the fish is currently swimming
	var dir: Vector2 = self.velocity.normalized()
	if dir == Vector2.ZERO:
		return  # fish is not moving
	
	# 1. Position the indicator at a distance along the direction vector
	indicator.position = dir * indicator_distance
	
	# 2. Rotate the indicator so it POINTS in the direction of movement
	indicator.rotation = dir.angle()


func _physics_process(delta: float) -> void:	
	match current_state:
		mobState["DEBUG"]:
			self.visible = true
			var horizontal_offset = Vector2(1 * player._last_direction, -45)
			global_position = player.global_position + horizontal_offset
			
		mobState["INVISIBLE"]:
			self.visible = false
			indicator.visible = false
			var horizontal_offset = Vector2(1 * player._last_direction, -45)
			global_position = player.global_position + horizontal_offset
		
		mobState["HOOKED"]:
			update_indicator()
			checkForFish()
			var fish_velocity = fish.hooked_swim_physics(delta)
			
			var hook_influence = 0.5 * (tanh(player.rod_power - fish.fish_power) + 1.0)
			self.velocity = fish_velocity.lerp(self.velocity, hook_influence)

		mobState["CASTED"]:
			# Apply gravity
			self.velocity.y += gravity * delta
			# Apply water resistance
			if self.position.y >= 0:
				if self.position.y < 1:
					self.velocity = velocity.move_toward(Vector2.ZERO, surface_tension * delta)
				self.velocity = velocity.move_toward(Vector2.ZERO, water_friction * delta)
			
			if self.velocity.length() == 0:
				current_state = mobState["FLOATING"]

		mobState["FALLING"]:
			# Hook is falling through air without a fish
			self.velocity.y += gravity * delta
			# Slight horizontal air resistance
			self.velocity.x = move_toward(self.velocity.x, 0, 50 * delta)
		
		# Check if hook has reached water level
			if self.global_position.y >= water_level:
			# Transition to CASTED to apply water physics
				current_state = mobState["CASTED"]
	
		mobState["FLOATING"]:
			checkForFish()
			self.velocity.y = hook_weight * delta
			self.velocity.x = 0
			if self.position.y >= target_y_level:
				self.velocity.y = 0
			if is_instance_valid(fish):
				if fish.current_state == fish.mobState["HOOKED"]:
					current_state = mobState["HOOKED"]

		mobState["REELING"]:
			var threshold
			
			if is_instance_valid(fish) and fish.get_parent() == self:
				update_indicator()
				var fish_velocity = fish.hooked_swim_physics(delta)
				var hook_influence = 0.5 * (tanh(player.rod_power - fish.fish_power) + 1.0)
				self.velocity = fish_velocity.lerp(self.velocity, hook_influence)
				threshold = catch_threshold
			else:
				threshold = close_threshold
			# Move the hook toward the player's attach offset while reeling
			visible = true

			var horizontal_offset = Vector2(34 * player._last_direction, -36)
			var target_pos = player.global_position + horizontal_offset
			var to_target = target_pos - global_position
			var dist = to_target.length()
			
			if dist <= threshold:
				# Reached player: hide hook and notify player to go to idle
				current_state = mobState["INVISIBLE"]
				visible = false
				# Clear any attached fish reference (if applicable)
				if is_instance_valid(fish):
					fish = null

				# Prefer a clean API if player exposes set_to_idle()
				if player.has_method("set_to_idle"):
					player.set_to_idle()
				else:
					# Fallback: try to drive animation tree directly if present
					if "_anim_tree" in player and "_anim_state" in player:
						player._anim_tree.set("parameters/Idle/BlendSpace1D/blend_position", player._last_direction)
						player._anim_state.travel("Idle")
			else:
				# Move toward the player at a fixed speed
				var move_amt = 0
				if is_instance_valid(fish) and fish.get_parent() == self: # Move slower with a fish
					move_amt = reel_speed * delta * player.rod_power
				else:
					indicator.visible = false
					move_amt = reel_speed * delta
				
				var step = to_target.normalized() * min(move_amt, dist)
				var x_scale = (tanh(dist / 100) + 1.0) * 0.5
				var y_scale = 1 - x_scale
				
				var step_scale = Vector2(x_scale * step.x, y_scale * step.y).normalized()
				var scaled_step = step_scale * step.length()
				
				global_position += scaled_step
	move_and_slide()


func get_current_state() -> String:
	match current_state:
		mobState["DEBUG"]:
			return "DEBUG"
		mobState["INVISIBLE"]:
			return "INVISIBLE"
		mobState["HOOKED"]:
			return "HOOKED"
		mobState["CASTING"]:
			return "CASTING"
		mobState["CASTED"]:
			return "CASTED"
		mobState["FLOATING"]:
			return "FLOATING"
		mobState["REELING"]:
			return "REELING"
		mobState["FALLING"]:
			return "FALLING"
	return "none"

func start_reel_in():
	# Allow reeling to start from FLOATING or when a fish is HOOKED
	var cs = get_current_state()
	if cs == "FLOATING" or cs == "HOOKED":
		current_state = mobState["REELING"]

func stop_reel_in():
	if get_current_state() == "REELING":
		# If a fish is attached, return to HOOKED state; otherwise go to FLOATING
		if is_instance_valid(fish):
			current_state = mobState["HOOKED"]
		else:
			current_state = mobState["FLOATING"]

func start_cast() -> void:
	# Attempt to find the WindAndCast node (TouchArea) on the player and read its launch values
	var wind = null
	if player:
		# prefer a direct child named "TouchArea"
		if player.has_node("TouchArea"):
			wind = player.get_node("TouchArea")
		else:
			wind = player.find_node("TouchArea", true, false)
	# fallback: try parent's subtree (in case player wasn't exported/assigned)
	if not wind:
		var p = get_parent()
		if p:
			if p.has_node("TouchArea"):
				wind = p.get_node("TouchArea")
			else:
				wind = p.find_node("TouchArea", true, false)

	if not wind:
		push_error("Hook.start_cast: could not find WindAndCast (TouchArea) node to read launch vector")
		return

	# Verify it's the expected script/class
	if not (wind is WindAndCast):
		push_error("Hook.start_cast: found node 'TouchArea' but it is not WindAndCast")
		return

	var drag_vector = Vector2(wind.xLaunch, wind.yLaunch)

	# Existing cast logic (uses the computed drag_vector)
	current_state = mobState["CASTED"]
	# Normalize scaling between drag distance and actual velocity
	var scale_factor = 1  # tweak this to tune feel
	# Convert drag to velocity
	var x_vel = clamp(drag_vector.x * scale_factor, -400.0, 400.0)
	var y_vel = clamp(drag_vector.y * scale_factor, -600.0, 600.0)
	velocity = Vector2(x_vel, y_vel)
	cast_start_pos = global_position
	visible = true
