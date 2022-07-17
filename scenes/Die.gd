extends Spatial
class_name Die

# Shamelessly stolen from http://kidscancode.org/godot_recipes/3d/rolling_cube/
export var tween_time = 1 / 8.0

onready var pivot = $Pivot
onready var mesh = $Pivot/MeshInstance
onready var tween = $Tween

var is_alive = false;
var is_rolling = false;

func _ready():
	tween.interpolate_property(pivot, "scale", Vector3.ZERO, Vector3.ONE, tween_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	is_alive = true

func randomize_direction(rng: RandomNumberGenerator):
	var face_dirs = [Vector3.BACK, Vector3.FORWARD, Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]
	var at_i = rng.randi_range(0, 5)
	# trick to not pick the same or opposite face
	var up_i = (2 * (at_i / 2) + rng.randi_range(2, 5)) % 6
	mesh.transform.basis = Transform.IDENTITY.looking_at(face_dirs[at_i], face_dirs[up_i]).basis

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

	is_rolling = true

	# Also do nothing if we can't roll this way
	if not can_roll(dir):
		is_rolling = false
		return

	## Step 1: Offset the pivot
	pivot.translate(dir)
	mesh.global_translate(-dir)

	## Step 2: Animate the rotation
	var axis = dir.cross(Vector3.DOWN)
	tween.interpolate_property(pivot, "transform:basis",
			null, pivot.transform.basis.rotated(axis, PI/2),
			tween_time, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_all_completed")

	## Step3: Finalize movement and reverse the offset
	transform.origin += dir * 2
	transform.origin = transform.origin.floor()
	var basis = mesh.global_transform.basis
	pivot.transform = Transform.IDENTITY
	mesh.transform.origin = Vector3(0, 1, 0)
	mesh.global_transform.basis = basis
	is_rolling = false

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
	return is_rolling or tween.is_active()

func match_neighbors():
	# wait 3 physics frames for godot to stop drooling
	for i in range(0, 3):
		yield(get_tree(), "physics_frame")
	var raycasts = [$ForwardRayCast, $RightRayCast, $BackRayCast, $LeftRayCast]
	var top_face = get_top_face()
	for raycast in raycasts:
		if raycast.is_colliding() and raycast.get_collider().has_method("get_top_face"):
			var other_top_face = raycast.get_collider().get_top_face()
			if top_face == other_top_face:
				destroy()

func destroy():
	if is_alive:
		is_alive = false
		get_tree().call_group("dice_watcher", "on_die_cleared")
		tween.interpolate_property(pivot, "scale", null, Vector3.ZERO, tween_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		yield(tween, "tween_all_completed")
		queue_free()

func _on_Tween_tween_step(object, key, elapsed, value):
	if is_alive:
		pivot.transform = pivot.transform.orthonormalized()
