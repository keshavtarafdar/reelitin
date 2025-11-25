extends Node2D

# Holds all fish and their spawn chances
@export var fish_table = {
	preload("res://scenes/Fish/Fish3.tscn"): 0.5,  # 50% chance
	preload("res://scenes/Fish/Fish1.tscn"): 0.3,  # 30% chance
	preload("res://scenes/Fish/Fish2.tscn"): 0.2,  # 20% chance
}

# Spawn settings
@export var initial_fish: int = 3
@export var max_fish: int = 15
@export var spawn_interval: float = 3
@export var fish_lifetime: float = 30

# Axis-aligned spawn area (in RiverScene local coordinates)
@export var spawn_min: Vector2 = Vector2(-300, 104)
@export var spawn_max: Vector2 = Vector2(380, 110)

@onready var _player: Node = $Player
@onready var _hook: Node = $Player/Hook

var _spawn_timer: Timer
var _default_item_scene: PackedScene = null
var _default_item_res: Item = null
var _despawning_fish: Dictionary = {}  # Track fish that are swimming down to despawn

func _ready() -> void:
	# Randomize RNG for varied spawns
	randomize()
	SFX.play(SFX.ambient_sounds, -25)

	var existing_fish = get_tree().get_nodes_in_group("Fish")
	if existing_fish.size() > 0:
		var f0 = existing_fish[0]
		if f0 is Fish:
			if f0.item_scene:
				_default_item_scene = f0.item_scene.duplicate(true)
			if f0.item_res:
				_default_item_res = f0.item_res.duplicate(true)
				

	# Spawn initial batch
	for i in range(initial_fish):
		if _current_fish_count() < max_fish:
			_spawn_fish()

	# Set up periodic spawns to keep population up to max
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.wait_time = max(spawn_interval, 0.1)
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	_spawn_timer.start()

func _current_fish_count() -> int:
	return get_tree().get_nodes_in_group("Fish").size()

func _rand_between(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(randf_range(min(a.x, b.x), max(a.x, b.x)), randf_range(min(a.y, b.y), max(a.y, b.y)))


func spawn_rand_fish(value: float) -> PackedScene:
	var cumulative := 0.0
	for fish_scene in fish_table.keys():
		cumulative += fish_table[fish_scene]
		if value <= cumulative:
			return fish_scene

	return fish_table.keys()[0]

func _spawn_fish() -> void:
	var spawn_chance = randf()
	var fish_size = randf_range(0.8, 1.2) # Add some random size to the fish

	var fish = spawn_rand_fish(spawn_chance).instantiate()
	fish.size *= fish_size
	fish.item_res.size *= fish_size
	
	if _player:
		fish.player = _player
	if _hook:
		fish.hook = _hook
	
	# Position and depth preference
	fish.position = _rand_between(spawn_min, spawn_max)

	add_child(fish)
	_attach_lifetime_timer(fish)

func _attach_lifetime_timer(fish: Node) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = max(1.0, fish_lifetime + randf_range(-5.0, 3.0))
	fish.add_child(t)
	t.timeout.connect(_on_fish_lifetime_timeout.bind(fish, t))
	t.start()

func _on_spawn_timer_timeout() -> void:
	if _current_fish_count() < max_fish:
		_spawn_fish()

func _on_fish_lifetime_timeout(fish: Node, t: Timer) -> void:
	if not is_instance_valid(fish):
		return

	var can_free := true
	if fish is Fish:
		var st = fish.current_state
		if st == fish.mobState["HOOKED"] or st == fish.mobState["CAUGHT"]:
			can_free = false

	if can_free:
		if fish.position.y >= 104:
			if _despawning_fish.has(fish):
				_despawning_fish.erase(fish)
			fish.queue_free()
		else:
			if not _despawning_fish.has(fish):
				_despawning_fish[fish] = true
				if fish is Fish:
					fish.ideal_depth = 125
					fish.current_state = fish.mobState["SWIMMING"]
			if is_instance_valid(t):
				t.wait_time = 0.5 
				t.start()
	else:
		if is_instance_valid(t):
			t.wait_time = 5.0
			t.start()


### FISHING LINE LOGIC ###

@onready var fishing_line = $FishingLine
var rod_offset = Vector2(34, -39)

@export var min_points := 50
@export var max_points := 200
@export var point_density := 10.0    # pixels per segment

const WATER_Y = 0.0
const WATER_SAG_MULT = 0.60
const AIR_SAG_MULT = 12.0

@export var wobble_strength_air := 3.0
@export var wobble_strength_water := 6.0
@export var wobble_speed := 1.5
@export var horizontal_noise := 1.8
@export var time_scale := 1.0

var wobble_offset := randf() * 1000.0   # randomize phase so each line instance looks unique


func _process(_delta):
	if not _hook:
		fishing_line.points = []
		return

	fishing_line.visible = _hook.visible
	
	var adjusted_rod_pos = Vector2(rod_offset.x * _player._last_direction, rod_offset.y)
	
	var p1 = fishing_line.to_local(_player.global_position + adjusted_rod_pos)
	var p2 = fishing_line.to_local(_hook.global_position)
	
	var dist = p1.distance_to(p2)

	var point_count = int(clamp(dist / point_density, min_points, max_points))
	var points: Array[Vector2] = []

	var t_accum = (Time.get_ticks_msec() / 1000.0) * wobble_speed + wobble_offset

	for i in range(point_count + 1):
		var t = i / float(point_count)
		var pos = p1.lerp(p2, t)

		# base parabola sag
		var sag_strength = dist * 0.12
		var base_sag = -4 * sag_strength * pow(t - 0.5, 2) + sag_strength

		# apply sag differently above/below water
		var under = pos.y >= WATER_Y
		if under:
			var water_sag = base_sag * WATER_SAG_MULT
			var blend = clamp((pos.y - WATER_Y) / 30.0, 0.0, 1.0)
			pos.y += lerp(base_sag, water_sag, blend)
		else:
			pos.y += base_sag

		if i == 0 or i == point_count:
			# Do NOT apply noise, wobble, or looseness
			points.append(pos)
			continue

		# small horizontal soft noise
		pos.x += sin(t_accum + i * 0.15) * horizontal_noise

		# vertical wobble (stronger underwater)
		var wobble = sin(t_accum * 0.6 + t * 6.0)
		var wobble_amount = lerp(
			wobble_strength_air,
			wobble_strength_water,
			1.0 if under else 0.0
		)
		pos.y += wobble * wobble_amount

		# tiny additional floaty looseness
		pos.y += sin((t_accum + i * 0.8) * 0.5) * 0.7

		points.append(pos)

	fishing_line.points = points
