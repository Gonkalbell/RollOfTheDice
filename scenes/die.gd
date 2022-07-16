extends Spatial

var current_grid_pos: Vector2
var target_grid_pos: Vector2
var camera: Camera

const MOVE_TIME = 0.1

func _ready():
	current_grid_pos = Vector2(translation.x, translation.z).floor();
	target_grid_pos = current_grid_pos;

func _process(delta):
	var target_pos = Vector3(target_grid_pos.x, 0, target_grid_pos.y)
	if translation.is_equal_approx(target_pos):
		translation = target_pos
		if Input.is_action_just_pressed("ui_up"):
			target_grid_pos += Vector2(0, -1)
		if Input.is_action_just_pressed("ui_down"):
			target_grid_pos += Vector2(0, 1)
		if Input.is_action_just_pressed("ui_left"):
			target_grid_pos += Vector2(-1, 0)
		if Input.is_action_just_pressed("ui_right"):
			target_grid_pos += Vector2(1, 0)
	else:
		translation = translation.move_toward(target_pos, delta / MOVE_TIME)
	
	
