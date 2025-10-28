extends CharacterBody2D

@export var player : CharacterBody2D
@export var fish : CharacterBody2D # Dynamically assigned when a fish becomes a child node


# Hook physics variables
var water_friction: int = 30

# State tracking
enum mobState {
	INVISIBLE,
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
		mobState["INVISIBLE"]:
			self.visible = false
		
		mobState["HOOKED"]:
			checkForFish()
			var fish_velocity = fish.swim_physics(delta)
			
			var hook_influence = 0.5 * (tanh(player.rod_power - fish.fish_power) + 1.0)
			self.velocity = fish_velocity.lerp(self.velocity, hook_influence)
			
			if fish.current_state != fish.mobState["HOOKED"]:
				current_state = mobState["FLOATING"]

		mobState["CASTED"]:
			pass

		mobState["FLOATING"]:
			checkForFish()
			self.velocity = velocity.move_toward(Vector2.ZERO, water_friction * delta)
			
			if is_instance_valid(fish):
				if fish.current_state == fish.mobState["HOOKED"]:
					current_state = mobState["HOOKED"]

		mobState["REELING"]:
			pass

	move_and_slide()
