extends Node2D

@export var fish_scene: PackedScene = preload("res://scenes/Fish/Fish1.tscn")

# Spawn settings
@export var initial_fish: int = 2
@export var max_fish: int = 7
@export var spawn_interval: float = 5
@export var fish_lifetime: float = 60

# Axis-aligned spawn area (in RiverScene local coordinates)
@export var spawn_min: Vector2 = Vector2(-450, 30)
@export var spawn_max: Vector2 = Vector2(150, 120)

@onready var _player: Node = $Player
@onready var _hook: Node = $Player/Hook

var _spawn_timer: Timer
var _default_item_scene: PackedScene = null
var _default_item_res: Item = null

func _ready() -> void:
	# Randomize RNG for varied spawns
	randomize()

	# Ensure player/hook references exist (fallback to find_node if needed)
	#if _player == null:
		#_player = find_node("Player", true, false)
	#if _hook == null and _player and _player.has_node("Hook"):
		#_hook = _player.get_node("Hook")
	#if _hook == null:
		#_hook = find_node("Hook", true, false)

	# Try to learn default fish item settings from any existing fish instance in the scene
	# IMPORTANT: Do this BEFORE spawning new fish so defaults are available
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

func _spawn_fish() -> void:
	if fish_scene == null:
		push_error("RiverScene: fish_scene is not assigned")
		return
	var fish = fish_scene.instantiate()
	# Assign references (Fish scene exposes these exported vars)
	if _player:
		fish.player = _player
	if _hook:
		fish.hook = _hook
	# Ensure item drop configuration exists
	if fish is Fish:
		if not fish.item_scene and _default_item_scene:
			fish.item_scene = _default_item_scene
		if not fish.item_res and _default_item_res:
			fish.item_res = _default_item_res
		
		# Warn if still null after attempting to assign defaults
		if not fish.item_scene:
			push_warning("RiverScene: Spawned fish has no item_scene assigned (no defaults available)")
		if not fish.item_res:
			push_warning("RiverScene: Spawned fish has no item_res assigned (no defaults available)")

	# Position and depth preference
	fish.position = _rand_between(spawn_min, spawn_max)
	# Encourage the fish to cruise around its spawn Y (Fish script has this var)
	if fish is Fish:
		fish.ideal_depth = fish.global_position.y

	# Ensure fish is in the Fish group (Fish1 already is, but keep robust)
	if not fish.is_in_group("Fish"):
		fish.add_to_group("Fish")

	add_child(fish)
	_attach_lifetime_timer(fish)

func _attach_lifetime_timer(fish: Node) -> void:
	var t := Timer.new()
	t.one_shot = true
	# Small random jitter so all fish don't despawn at once
	t.wait_time = max(1.0, fish_lifetime + randf_range(-5.0, 3.0))
	# Keep timer under the fish so it auto-cleans if fish is freed early (e.g., caught)
	fish.add_child(t)
	t.timeout.connect(_on_fish_lifetime_timeout.bind(fish, t))
	t.start()

func _on_spawn_timer_timeout() -> void:
	if _current_fish_count() < max_fish:
		_spawn_fish()

func _on_fish_lifetime_timeout(fish: Node, t: Timer) -> void:
	# If fish is gone, nothing to do
	if not is_instance_valid(fish):
		return
	# If fish is hooked or already caught, postpone despawn
	var can_free := true
	if fish is Fish:
		var st = fish.current_state
		if st == fish.mobState["HOOKED"] or st == fish.mobState["CAUGHT"]:
			can_free = false

	if can_free:
		fish.queue_free()
	else:
		# Give it a few more seconds to finish the interaction
		if is_instance_valid(t):
			t.wait_time = 5.0
			t.start()
