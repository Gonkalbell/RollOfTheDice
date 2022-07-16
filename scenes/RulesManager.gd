extends Node
class_name RulesManager

enum RollState { IDLE, ROLLING, MATCHING }

var state = RollState.IDLE

func _process(delta):
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
