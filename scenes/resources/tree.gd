# scenes/resources/tree.gd
# 나무 전용 스크립트 - 쓰러지는 애니메이션 포함
extends "res://scenes/resources/resource_node.gd"

func take_hit() -> void:
	health -= 1
	if health <= 0:
		_start_fall()
	else:
		_flash()
		_shake()

# ─── 피격 시 살짝 흔들림 ─────────────────────────────────────
func _shake() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation:z",  0.08, 0.07)
	tween.tween_property(self, "rotation:z", -0.08, 0.07)
	tween.tween_property(self, "rotation:z",  0.04, 0.05)
	tween.tween_property(self, "rotation:z",  0.0,  0.05)

# ─── 쓰러지는 애니메이션 ─────────────────────────────────────
func _start_fall() -> void:
	# 충돌 비활성화 (쓰러지는 동안 플레이어가 막히지 않게)
	for child in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true

	# 랜덤 방향으로 쓰러짐 (X/Z 축 회전)
	var angle   := randf() * TAU
	var lean    := PI * 0.5 - 0.05           # 거의 눕는 각도
	var target  := Vector3(cos(angle) * lean, rotation.y, sin(angle) * lean)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)

	# 1. 쓰러지기 직전 살짝 반대로 기울었다가 (중력 느낌)
	var pre_lean := Vector3(-cos(angle) * 0.06, rotation.y, -sin(angle) * 0.06)
	tween.tween_property(self, "rotation", pre_lean, 0.12)

	# 2. 쭉 쓰러짐
	tween.tween_property(self, "rotation", target, 0.85)

	# 3. 착지 후 바닥에서 튕기는 느낌 (살짝 되튀기)
	var bounce := Vector3(cos(angle) * (lean - 0.08), rotation.y, sin(angle) * (lean - 0.08))
	tween.tween_property(self, "rotation", bounce, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", target, 0.08)

	# 4. 완전히 쓰러진 뒤 드롭 + 삭제
	tween.tween_callback(func() -> void:
		_spawn_drop()
		queue_free()
	)
