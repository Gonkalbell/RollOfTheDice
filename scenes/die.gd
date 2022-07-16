extends Spatial
class_name Die

# Shamelessly stolen from http://kidscancode.org/godot_recipes/3d/rolling_cube/
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

# Cast a ray before moving to check for obstacles
func can_roll(dir: Vector3) -> bool:
	var space = get_world().direct_space_state
	var collision = space.intersect_ray(mesh.global_transform.origin, mesh.global_transform.origin + dir * 2.5, [self])
	if collision:
		if collision.collider.has_method("can_roll"):
			# it's inefficient to make this recursive, but oh well
			return collision.collider.can_roll(dir)
		else:
			return false
	return true

func match_neighbors():
	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	var space = get_world().direct_space_state
	var top_face = get_top_face()
	print(top_face)
	for dir in directions:
		var collision = space.intersect_ray(mesh.global_transform.origin, mesh.global_transform.origin + dir * 2, [self])
		if collision and collision.collider.has_method("get_top_face"):
			var other_top_face = collision.collider.get_top_face()
			print(top_face, other_top_face)
			if get_top_face() == collision.collider.get_top_face():
				print("%s and %s both had face %d" % [self, collision.collider, get_top_face()])

func roll(dir:Vector3):
	# Do nothing if we're currently rolling.
	if tween.is_active():
		return

	# Also do nothing if we can't roll this way
	if not can_roll(dir):
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

func _on_Tween_tween_step(object, key, elapsed, value):
	pivot.transform = pivot.transform.orthonormalized()

func get_top_face() -> int:
	var top_face_dir = mesh.global_transform.basis.inverse() * Vector3.UP
	var min_distance = 10000
	var face_value = -1

	var face_dirs = [Vector3.BACK, Vector3.RIGHT, Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.FORWARD]
	
	for i in range(len(face_dirs)):
		var distance = top_face_dir.distance_squared_to(face_dirs[i])
		if distance < min_distance:
			min_distance = distance
			face_value = i + 1
	
	return face_value
