extends CharacterBody2D

@export var hook : CharacterBody2D
@export var player : CharacterBody2D
@onready var fish_anim = get_node("FishAnim")

var fish_speed: int = 1000
var isHooked: bool = false
var last_direction: Vector2 = Vector2(0,0)

#Variables for bite mechanic
var bounce_speed: float = 500.0  # speed away from hook
var bounce_duration: float = 1.0  # how long fish moves away
var bounce_timer: float = 0.0


enum mobState {
	IDLE,
	SWIMMING,
	INTERESTED,
	SCARED,
	BITING,
	HOOKED,
	CAUGHT
}

var current_state

func _ready():
	current_state = mobState["IDLE"]

func _physics_process(delta: float) -> void:
	if is_instance_valid(hook):
		var direction_to_hook = (hook.global_position - self.global_position).normalized()
		var distance_to_hook = (hook.global_position - self.global_position)
		match current_state:
			mobState["IDLE"]:
				velocity = Vector2(0,0)
				fish_anim.play("Idle")
			mobState["SWIMMING"]:
				fish_anim.play("Swim")
			mobState["INTERESTED"]:
				velocity = direction_to_hook*delta*fish_speed*0.5
				last_direction = direction_to_hook
				fish_anim.play("Swim")
			mobState["BITING"]:
				if bounce_timer > 0:
					bounce_timer -=delta
					self.velocity = -direction_to_hook * bounce_speed
				else:
					if distance_to_hook.length() > 20:
						velocity = direction_to_hook * fish_speed
					else:
						bounce_timer = bounce_duration
						velocity = -direction_to_hook * bounce_speed
						
			mobState["SCARED"]:
				fish_anim.play("Swim")
			mobState["HOOKED"]:
				pass
			mobState["CAUGHT"]:
				fish_anim.play("Idle")

		# Flip animations to last direction
		if last_direction.x < 0:
			fish_anim.flip_h = true
		else:
			fish_anim.flip_h = false
		
		move_and_slide()
		print("Current state: %s | Velocity: %v | Direction To Hook: %v" % [current_state, velocity, direction_to_hook])


#InterestRange logic
func _on_interest_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		current_state = mobState["INTERESTED"]

func _on_interest_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		current_state = mobState["IDLE"]

#BiteRange logic
func _on_bite_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		current_state = mobState["BITING"]

func _on_bite_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Hook"):
		current_state = mobState["INTERESTED"]
