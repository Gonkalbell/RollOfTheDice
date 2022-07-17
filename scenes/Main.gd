extends Node

class_name Main

enum RollState { IDLE, ROLLING, MATCHING }

const MAP_WIDTH = 6
const MAP_HEIGHT = 6

var state = RollState.MATCHING
var rng = RandomNumberGenerator.new()
export (PackedScene) var dice_scene

var dice_cleared = 0
var moves_left = 20
var is_playing = false

func _ready():
	$Gui.update_moves_left(moves_left)
	$Gui.update_dice_cleared(dice_cleared)

func game_over():
	$Gui.show_game_over()
	get_tree().call_group("dice", "queue_free")
	is_playing = false

func new_game():
	dice_cleared = 0
	$Gui.update_moves_left(moves_left)
	moves_left = 20
	$Gui.update_dice_cleared(dice_cleared)
	$Gui.show_message("Go!")
	is_playing = true

func _physics_process(delta):
	if is_playing:
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
			RollState.ROLLING:
				if _done_rolling_dice():
					yield($NextMoveTimer, "timeout")
					tree.call_group("dice", "match_neighbors")
					state = RollState.MATCHING
			RollState.MATCHING:
				var num_dice = len(get_tree().get_nodes_in_group("dice"))
				if num_dice <= 0:
					_update_dice_spawn()

				if _done_rolling_dice():
					state = RollState.IDLE

func _take_turn(dir: Vector3):
	var tree = get_tree();
	tree.call_group("dice", "roll", dir)
	_update_dice_spawn()
	moves_left -= 1
	if moves_left <= 0:
		game_over()
	$Gui.update_moves_left(moves_left)
	state = RollState.ROLLING
	$NextMoveTimer.start()

func _done_rolling_dice():
	var done_rolling = true
	for node in get_tree().get_nodes_in_group("dice"):
		if node.is_rolling() or !node.is_alive:
			done_rolling = false;
			break;
	return done_rolling

func _update_dice_spawn():
	spawn_die()

func spawn_die():
	var spawn_pos = find_spawn_pos()
	if spawn_pos:
		var die = dice_scene.instance()
		get_tree().get_root().add_child(die)
		
		die.translation = spawn_pos
	else:
		game_over()

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

func on_die_cleared():
	moves_left += 1
	$Gui.update_moves_left(moves_left)
	dice_cleared += 1
	$Gui.update_dice_cleared(dice_cleared)


func start_game():
	pass # Replace with function body.
