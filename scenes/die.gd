extends Spatial

var grid_pos: Vector2
var orientation: Quat

const MOVE_TIME = 0.1

export var speed = 4.0

onready var pivot = $Pivot
onready var mesh = $Pivot/MeshInstance
onready var tween = $Tween

func _process(delta):
	if Input.is_action_pressed("ui_up"):
		roll(Vector3.FORWARD)
	if Input.is_action_pressed("ui_down"):
		roll(Vector3.BACK)
	if Input.is_action_pressed("ui_left"):
		roll(Vector3.LEFT)
	if Input.is_action_pressed("ui_right"):
		roll(Vector3.RIGHT)

func roll(dir):
	# Do nothing if we're currently rolling.
	if tween.is_active():
		return

	## Step 1: Offset the pivot
	pivot.translate(dir)
	mesh.global_translate(-dir)

	## Step 2: Animate the rotation
	var axis = dir.cross(Vector3.DOWN)
	tween.interpolate_property(pivot, "transform:basis",
			null, pivot.transform.basis.rotated(axis, PI/2),
			1/speed, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_all_completed")

	## Step3: Finalize movement and reverse the offset
	transform.origin += dir * 2
	var basis = mesh.global_transform.basis
	pivot.transform = Transform.IDENTITY
	mesh.transform.origin = Vector3(0, 1, 0)
	mesh.global_transform.basis = basis

	print_debug(get_top_face())

func _on_Tween_tween_step(object, key, elapsed, value):
	pivot.transform = pivot.transform.orthonormalized()

func get_top_face() -> int:
	var top_face_dir = mesh.global_transform.basis.inverse() * Vector3.UP
	var min_distance = 10000
	var face_value = -1
	print(top_face_dir)

	var face_dirs = [Vector3.BACK, Vector3.RIGHT, Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.FORWARD]
	
	for i in range(len(face_dirs)):
		var distance = top_face_dir.distance_squared_to(face_dirs[i])
		if distance < min_distance:
			min_distance = distance
			face_value = i + 1
	
	return face_value
