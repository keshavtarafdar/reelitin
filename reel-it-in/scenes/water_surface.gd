extends Line2D

@export var amplitude: float = 1.3
@export var wavelength: float = 75.0
@export var speed: float = 1.0

@export var drift_amount: float = 2.0
@export var drift_speed: float = 1.0

var base_points: PackedVector2Array
var noise: FastNoiseLite
var drift_noise: FastNoiseLite

var time := 0.0

func _ready() -> void:
	generate_points(-1000, 1000, 2)
	base_points = points.duplicate()

	# Smooth noise for gentle micro-motion
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.01

	# Very slow noise for drifting waves
	drift_noise = FastNoiseLite.new()
	drift_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	drift_noise.frequency = 0.002


func generate_points(start_x: int, end_x: int, step: int) -> void:
	var arr := PackedVector2Array()
	for x in range(start_x, end_x + 1, step):
		arr.append(Vector2(x, 0))
	points = arr

func get_height_at_x(x: float) -> float:
	# --- main sine wave ---
	var wave = sin((x / wavelength) + time) * amplitude

	# --- smooth coherent noise ---
	var n = noise.get_noise_2d(x * 0.2, time * 0.8) * 1.2

	# --- slow drifting shape ---
	var drift = drift_noise.get_noise_2d(x * 0.1, time * drift_speed) * drift_amount

	return wave + n + drift


func _process(delta: float) -> void:
	time += delta * speed

	var new_points := PackedVector2Array()

	for i in base_points.size():
		var p = base_points[i]

		# --- main sine wave (smooth) ---
		var wave = sin((p.x / wavelength) + time) * amplitude

		# --- smooth coherent noise (no jagged jitter) ---
		var n = noise.get_noise_2d(p.x * 0.2, time * 0.8) * 0.6

		# --- slow drifting shape ---
		var drift = drift_noise.get_noise_2d(p.x * 0.1, time * drift_speed) * drift_amount

		var final_y = p.y + wave + n + drift

		new_points.append(Vector2(p.x, final_y))

	points = new_points
