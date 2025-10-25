extends CharacterBody2D

@export var player : CharacterBody2D
@export var fish : CharacterBody2D # Dynamically assigned


# Hook physics variables
var water_friction: int = 10

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
	current_state = mobState["FLOATING"] # Set to floating for testing

func checkForFish() -> void:
	for child in self.get_children():
		if child.is_in_group("Fish"):
			fish = child
			current_state = mobState['HOOKED']

func _physics_process(delta: float) -> void:
	
	match current_state:
		
		mobState["HOOKED"]:
			checkForFish()
			var fish_velocity = fish.swim_physic(delta)
			
		mobState["CASTED"]:
			pass
		mobState["FLOATING"]:
			self.velocity = velocity.move_toward(Vector2.ZERO, water_friction * delta)
		mobState["REELING"]:
			pass
	
	move_and_slide()
