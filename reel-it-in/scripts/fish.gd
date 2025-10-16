extends CharacterBody2D

@export var hook : CharacterBody2D
var speed: int = 100

enum mobState {
	IDLE,
	SWIMMING,
	INTERESTED,
	HOOKED,
	SCARED,
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
				pass
			mobState["INTERESTED"]:
				pass
			mobState["HOOKED"]:
				velocity = direction_to_hook*speed*delta #TODO replace speed with the speed of the hook --> maybe a script or some form
			mobState["SCARED"]:
				pass
			mobState["CAUGHT"]:
				pass


func _on_interest_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("fish"):
		pass # Replace with function body.
