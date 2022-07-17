extends Node
class_name RulesManager

enum RollState { IDLE, ROLLING, MATCHING }

const MAP_WIDTH = 10
const MAP_HEIGHT = 10

var state = RollState.IDLE
var rng = RandomNumberGenerator.new()
export (PackedScene) var dice_scene

func _physics_process(delta):
	var tree = get_tree();
	match state:
		RollState.IDLE:
			if Input.is_action_pressed("ui_up"):
				tree.call_group("dice", "roll", Vector3.FORWARD)
				state = RollState.ROLLING
			if Input.is_action_pressed("ui_down"):
				tree.call_group("dice", "roll", Vector3.BACK)
				state = RollState.ROLLING
			if Input.is_action_pressed("ui_left"):
				tree.call_group("dice", "roll", Vector3.LEFT)
				state = RollState.ROLLING
			if Input.is_action_pressed("ui_right"):
				tree.call_group("dice", "roll", Vector3.RIGHT)
				state = RollState.ROLLING
			if Input.is_action_just_pressed("ui_accept"):
				spawn_die()
		RollState.ROLLING:
			if _done_rolling_dice():
				tree.call_group("dice", "match_neighbors")
				state = RollState.MATCHING
		RollState.MATCHING:
			if _done_rolling_dice():
				state = RollState.IDLE

func _done_rolling_dice():
	var done_rolling = true
	for node in get_tree().get_nodes_in_group("dice"):
		if node.is_rolling():
			done_rolling = false;
			break;
	return done_rolling

func spawn_die():
	var spawn_pos = find_spawn_pos()
	if spawn_pos:
		var die = dice_scene.instance()
		get_tree().get_root().add_child(die)
		
		die.translation = spawn_pos

func find_spawn_pos():
	var x = rng.randi_range(0, MAP_WIDTH - 1)
	var z = rng.randi_range(0, MAP_HEIGHT - 1)
	var spawn_pos = Vector3.ZERO

	var space = get_tree().root.get_world().direct_space_state
	# avoid spawning inside of something else
	var can_spawn = false
	for dx in range(0, MAP_WIDTH - 1):
		for dz in range(0, MAP_HEIGHT - 1):
			var x2 = (x + dx) % MAP_WIDTH
			var z2 = (z + dz) % MAP_HEIGHT
			spawn_pos = 2 * Vector3(x2, 0, z2) + Vector3(1 - MAP_WIDTH, 0, 1 - MAP_HEIGHT)

			var intersections = space.intersect_point(spawn_pos + Vector3(0, 1, 0), 1)
			if len(intersections) == 0:
				print(spawn_pos)
				return spawn_pos
			else:
				print("overlap!")
	return null
