extends Node
class_name RulesManager

enum RollState { IDLE, ROLLING, MATCHING }

const MAP_WIDTH = 6
const MAP_HEIGHT = 6

var state = RollState.IDLE
var rng = RandomNumberGenerator.new()
export (PackedScene) var dice_scene

var turns_til_next_spawn = 6
var turns_per_dice = 6
var dice_until_difficulty_spike = 6

func _physics_process(delta):
	var tree = get_tree();
	match state:
		RollState.IDLE:
			if Input.is_action_pressed("ui_up"):
				_take_turn(Vector3.FORWARD)
			if Input.is_action_pressed("ui_down"):
				_take_turn(Vector3.BACK)
			if Input.is_action_pressed("ui_left"):
				_take_turn(Vector3.LEFT)
			if Input.is_action_pressed("ui_right"):
				_take_turn(Vector3.RIGHT)
			if Input.is_action_just_pressed("ui_accept"):
				spawn_die()
		RollState.ROLLING:
			if _done_rolling_dice():
				tree.call_group("dice", "match_neighbors")
				state = RollState.MATCHING
		RollState.MATCHING:
			if _done_rolling_dice():
				state = RollState.IDLE

	var num_dice = len(get_tree().get_nodes_in_group("dice"))
	if num_dice == 0:
		turns_til_next_spawn = 1
		_update_dice_spawn()

func _take_turn(dir: Vector3):
	var tree = get_tree();
	tree.call_group("dice", "roll", dir)
	_update_dice_spawn()
	state = RollState.ROLLING

func _done_rolling_dice():
	var done_rolling = true
	for node in get_tree().get_nodes_in_group("dice"):
		if node.is_rolling():
			done_rolling = false;
			break;
	return done_rolling

func _update_dice_spawn():
	turns_til_next_spawn -= 1
	print(turns_til_next_spawn, dice_until_difficulty_spike, turns_per_dice)
	if turns_til_next_spawn <= 0:
		spawn_die()
		turns_til_next_spawn = turns_per_dice
		dice_until_difficulty_spike -= 1
		if dice_until_difficulty_spike <= 0:
			dice_until_difficulty_spike = 6
			turns_per_dice = max(turns_per_dice - 1, 1)

func spawn_die():
	var spawn_pos = find_spawn_pos()
	if spawn_pos:
		var die = dice_scene.instance()
		get_tree().get_root().add_child(die)
		
		die.translation = spawn_pos
	else:
		print("game over")

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
				return spawn_pos
	return null
