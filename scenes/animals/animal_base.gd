# scenes/animals/animal_base.gd
# 동물 공통 베이스: 배회 AI, 도주, 피격, 드롭
extends CharacterBody3D

@export var max_health   : int   = 3
@export var move_speed   : float = 2.0
@export var wander_range : float = 10.0
@export var animal_name  : String = "동물"

var health         : int
var home_pos       : Vector3
var target_pos     : Vector3
var wander_timer   : float = 0.0
var flee_from      : Node3D = null

const GRAVITY := 12.0

var dropped_item_scene: PackedScene

func _ready() -> void:
	health             = max_health
	home_pos           = global_position
	target_pos         = global_position
	dropped_item_scene = preload("res://scenes/resources/dropped_item.tscn")
	add_to_group("animals")

func _physics_process(delta: float) -> void:
	# 중력
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	wander_timer -= delta

	if flee_from and is_instance_valid(flee_from):
		# 도주
		var dir := (global_position - flee_from.global_position)
		dir.y = 0.0
		if dir.length() > 0.01:
			dir = dir.normalized()
		velocity.x = dir.x * move_speed * 2.2
		velocity.z = dir.z * move_speed * 2.2
	else:
		# 배회
		if wander_timer <= 0.0:
			wander_timer = randf_range(3.0, 8.0)
			var angle := randf() * TAU
			var dist  := randf_range(2.0, wander_range)
			target_pos = home_pos + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

		var dir := target_pos - global_position
		dir.y = 0.0
		if dir.length() > 0.6:
			dir = dir.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)
			velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()

	# 이동 방향을 향해 회전
	var flat_vel := Vector2(velocity.x, velocity.z)
	if flat_vel.length() > 0.2:
		var look_dir := Vector3(velocity.x, 0.0, velocity.z).normalized()
		look_at(global_position + look_dir, Vector3.UP)

func take_hit() -> void:
	health -= 1
	_flash_red()

	# 플레이어로부터 도주
	var player := get_tree().get_first_node_in_group("player")
	if player:
		flee_from = player
		get_tree().create_timer(3.5).timeout.connect(func(): flee_from = null)

	if health <= 0:
		_die()

func _flash_red() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var mat: StandardMaterial3D = child.get_active_material(0) as StandardMaterial3D
			if mat == null:
				continue
			var orig: Color = mat.albedo_color
			var tween := create_tween()
			tween.tween_property(mat, "albedo_color", Color.RED, 0.08)
			tween.tween_property(mat, "albedo_color", orig,      0.12)

func _die() -> void:
	for drop_type in _get_drops():
		var drop := dropped_item_scene.instantiate()
		drop.item_type       = drop_type
		drop.global_position = global_position + Vector3(
			randf_range(-0.4, 0.4), 0.05, randf_range(-0.4, 0.4)
		)
		get_parent().add_child(drop)
	queue_free()

## 서브클래스에서 오버라이드
func _get_drops() -> Array:
	return []
