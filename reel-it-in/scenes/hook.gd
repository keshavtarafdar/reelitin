extends CharacterBody2D

@export var player : CharacterBody2D
@export var fish : CharacterBody2D # Dynamically assigned when a fish becomes a child node


# Hook physics variables
var water_friction: int = 30
var offset: Vector2
var gravity: float = 400.0
var target_y: float = 25.0
var water_level: float = 0.0
var cast_angle: float = 0.0
var cast_speed: float = 0.0
var cast_start_pos: Vector2





# State tracking
enum mobState {
	DEBUG,
	INVISIBLE,
	CASTING,
	CASTED,
	FLOATING,
	HOOKED,
	REELING
}
var current_state: int

func _ready():
	current_state = mobState["INVISIBLE"] # Set to floating for testing

func checkForFish() -> void:
	for child in self.get_children():
		if child.is_in_group("Fish"):
			fish = child
			current_state = mobState['HOOKED']

func _physics_process(delta: float) -> void:
	

	match current_state:
		mobState["DEBUG"]:
			self.visible = true
			var horizontal_offset = Vector2(1 * player._last_direction, -45)
			global_position = player.global_position + horizontal_offset
			
		mobState["INVISIBLE"]:
			self.visible = false
			var horizontal_offset = Vector2(1 * player._last_direction, -45)
			global_position = player.global_position + horizontal_offset
		
		mobState["HOOKED"]:
			checkForFish()
			var fish_velocity = fish.swim_physics(delta)
			
			var hook_influence = 0.5 * (tanh(player.rod_power - fish.fish_power) + 1.0)
			self.velocity = fish_velocity.lerp(self.velocity, hook_influence)
			
			if fish.current_state != fish.mobState["HOOKED"]:
				current_state = mobState["FLOATING"]


		mobState["CASTING"]:
			pass
		mobState["CASTED"]:
			# Apply gravity
			velocity.y += gravity * delta
			# Stop when it hits water level
			if global_position.y >= water_level:
				velocity.x = 0
			if global_position.y >= target_y:
				global_position.y = target_y
				velocity = Vector2.ZERO
				current_state = mobState["FLOATING"]
			

		mobState["FLOATING"]:
			checkForFish()
			self.velocity = velocity.move_toward(Vector2.ZERO, water_friction * delta)
			
			if is_instance_valid(fish):
				if fish.current_state == fish.mobState["HOOKED"]:
					current_state = mobState["HOOKED"]

		mobState["REELING"]:
			pass

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
	return "none"

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
	print("Velocity: ", velocity)
	cast_start_pos = global_position
	visible = true
