extends CharacterBody2D

@export var player : CharacterBody2D
@export var fish : CharacterBody2D # Dynamically assigned
# Hook physics variables
var water_friction: int = 10



# State tracking
enum mobState {
	HOOKED,
	CASTED,
	FLOATING,
	INVISIBLE
}
var current_state: int

func _ready():
	current_state = mobState["FLOATING"] # Set to floating for testing


func _physics_process(delta: float) -> void:
	
	match current_state:
		
		mobState["HOOKED"]:
			pass
		mobState["CASTED"]:
			pass
		mobState["FLOATING"]:
			self.velocity = velocity.move_toward(Vector2.ZERO, water_friction * delta)
