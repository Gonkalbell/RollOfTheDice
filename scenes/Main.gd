extends Node

class_name Main

enum RollState { IDLE, ROLLING, SPAWNING, MATCHING }

const MAP_WIDTH = 6
const MAP_HEIGHT = 6

var state = RollState.IDLE
var rng = RandomNumberGenerator.new()
export (PackedScene) var dice_scene

var dice_cleared = 0
var moves_left = 15
var is_playing = false

func _ready():
	rng.randomize()
	$Gui.update_moves_left(moves_left)
	$Gui.update_dice_cleared(dice_cleared)

func game_over():
	$Gui.show_game_over()
	get_tree().call_group("dice", "queue_free")
	is_playing = false

func new_game():
	state = RollState.IDLE
	dice_cleared = 0
	moves_left = 15
	is_playing = true
	$Gui.update_dice_cleared(dice_cleared)
	$Gui.update_moves_left(moves_left)
	$Gui.show_message("Go!")
	$NextMoveTimer.start()
	spawn_die()

func _physics_process(delta):
	if is_playing and _done_rolling_dice() and $NextMoveTimer.is_stopped():
		var tree = get_tree();
		match state:
			RollState.IDLE:
				if Input.is_action_pressed("ui_up"):
					_take_turn(Vector3.FORWARD)
				elif Input.is_action_pressed("ui_down"):
					_take_turn(Vector3.BACK)
				elif Input.is_action_pressed("ui_left"):
					_take_turn(Vector3.LEFT)
				elif Input.is_action_pressed("ui_right"):
					_take_turn(Vector3.RIGHT)

			RollState.ROLLING:
				spawn_die()
				state = RollState.SPAWNING

			RollState.SPAWNING:
				tree.call_group("dice", "match_neighbors")
				state = RollState.MATCHING

			RollState.MATCHING:
				state = RollState.IDLE
				if moves_left <= 0:
					game_over()

func _take_turn(dir: Vector3):
	var tree = get_tree();
	tree.call_group("dice", "roll", dir)
	moves_left -= 1
	$Gui.update_moves_left(moves_left)
	state = RollState.ROLLING
	$NextMoveTimer.start()

func _done_rolling_dice():
	var done_rolling = true
	var nodes = get_tree().get_nodes_in_group("dice")
	for node in nodes:
		if node.is_rolling() or !node.is_alive:
			done_rolling = false;
			break;
	return done_rolling

func spawn_die():
	var spawn_pos = find_spawn_pos()
	if spawn_pos:
		var die = dice_scene.instance()
		get_tree().get_root().add_child(die)
		
		die.translation = spawn_pos
		die.randomize_direction(rng)
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
