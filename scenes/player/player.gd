# scenes/player/player.gd
# 플레이어 이동, 시점, 팔 휘두르기, 레이캐스트 공격
extends CharacterBody3D

const SPEED           : float = 5.0
const JUMP_VELOCITY   : float = 5.0
const GRAVITY         : float = 12.0
const MOUSE_SENS      : float = 0.002
const REACH           : float = 3.5
const HIT_COOLDOWN    : float = 0.45

@onready var camera   : Camera3D      = $Camera3D
@onready var arm_mesh : MeshInstance3D = $Camera3D/ArmPivot/ArmMesh

var hit_timer : float = 0.0

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# 중력
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# 점프
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# WASD 이동
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_dir  := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if move_dir:
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()

	# 공격 쿨다운
	if hit_timer > 0.0:
		hit_timer -= delta

func _input(event: InputEvent) -> void:
	# 마우스 시점 조작
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		camera.rotate_x(-event.relative.y * MOUSE_SENS)
		camera.rotation.x = clamp(camera.rotation.x, -PI / 2.1, PI / 2.1)

	# ESC → 마우스 커서 토글
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

	# 좌클릭 공격
	if event.is_action_pressed("attack") and hit_timer <= 0.0:
		_perform_hit()

# ─── 공격 처리 ───────────────────────────────────────────────
func _perform_hit() -> void:
	hit_timer = HIT_COOLDOWN
	_animate_arm()

	var space    := get_world_3d().direct_space_state
	var ray_from := camera.global_position
	var ray_to   := ray_from + (-camera.global_transform.basis.z) * REACH

	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [self]
	var result := space.intersect_ray(query)

	if result.is_empty():
		return

	var collider: Node3D = result["collider"] as Node3D

	# 직접 hit 가능 노드인지 확인
	if collider.has_method("take_hit"):
		collider.take_hit()
	elif collider.get_parent().has_method("take_hit"):
		collider.get_parent().take_hit()

# ─── 팔 스윙 애니메이션 ──────────────────────────────────────
func _animate_arm() -> void:
	var pivot := $Camera3D/ArmPivot
	var tween  := create_tween()
	tween.tween_property(pivot, "rotation:x", -0.6, 0.08)
	tween.tween_property(pivot, "rotation:x",  0.0, 0.12)
