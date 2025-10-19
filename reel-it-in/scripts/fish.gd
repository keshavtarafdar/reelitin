extends CharacterBody2D

@export var hook : CharacterBody2D
@export var player : CharacterBody2D

var speed: int = 100
var isBiting: bool = false

enum mobState {
	IDLE,
	SWIMMING,
	INTERESTED,
	SCARED,
	BITE,
	HOOKED,
	CAUGHT
}

var current_state

func _ready():
	current_state = "IDLE"

func _physics_process(delta):
	if is_instance_valid(hook):
		var direction_to_hook = (hook.global_position - self.global_position).normalized()
		
		match current_state:
			mobState["IDLE"]:
				velocity = Vector2(0,0)
			mobState["SWIMMING"]:
				pass # idk ill think of something
			mobState["INTERESTED"]:
				pass # add a small chance to ented scared when in interested mode
			mobState["HOOKED"]:
				velocity = direction_to_hook*speed*delta #TODO replace speed with the speed of the hook --> maybe a script or some form
			mobState["SCARED"]:
				pass # move away from hook quickly then go to idle 
			mobState["BITE"]:
				pass # accelerate, bounce off hook with a chance of going in to caught state
				# set isBiting to false after one bounce
			mobState["CAUGHT"]:
				pass


func _on_interest_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		current_state = "INTERESTED"


func _on_bite_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hook") and !isBiting:
		current_state = "BITE"
