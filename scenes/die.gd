extends Spatial
class_name Die

# Shamelessly stolen from http://kidscancode.org/godot_recipes/3d/rolling_cube/
export var tween_time = 1 / 4.0

onready var pivot = $Pivot
onready var mesh = $Pivot/MeshInstance
onready var tween = $Tween
onready var manager = get_node("../RulesManager")

var is_alive = true;

# Cast a ray before moving to check for obstacles
func can_roll(dir: Vector3) -> bool:
	var space = get_world().direct_space_state
	var collision = space.intersect_ray(mesh.global_transform.origin, mesh.global_transform.origin + dir * 2, [self])
	if collision:
		if collision.collider.has_method("can_roll"):
			# it's inefficient to make this recursive, but oh well
			return collision.collider.can_roll(dir)
		else:
			return false
	return true

func roll(dir:Vector3):
	# Do nothing if we're currently rolling.
	if is_rolling():
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
			tween_time, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_all_completed")

	## Step3: Finalize movement and reverse the offset
	transform.origin += dir * 2
	transform.origin = transform.origin.floor()
	var basis = mesh.global_transform.basis
	pivot.transform = Transform.IDENTITY
	mesh.transform.origin = Vector3(0, 1, 0)
	mesh.global_transform.basis = basis

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

func is_rolling() -> bool:
	return tween.is_active()


func match_neighbors():
	return
	print("---")
	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	var space = get_world().direct_space_state
	var top_face = get_top_face()
	var start = mesh.global_transform.origin
	for dir in directions:
		var collision = space.intersect_ray(start, start + dir * 2.5, [self])
		print("%s : %d - %s - %s" % [start, top_face, dir, collision])
		if collision and collision.collider.has_method("get_top_face"):
			var other_top_face = collision.collider.get_top_face()
			print("%s : %d --- %s : %d" % [translation, top_face, collision.position, other_top_face])
			if top_face == other_top_face:
				destroy()

func destroy():
	is_alive = false
	tween.interpolate_property(pivot, "scale", null, Vector3(0, 0, 0), tween_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()

func _on_Tween_tween_step(object, key, elapsed, value):
	if is_alive:
		pivot.transform = pivot.transform.orthonormalized()
