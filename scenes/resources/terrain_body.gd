# scenes/resources/terrain_body.gd
# 지형 충돌체 - 좌클릭(채굴)하면 돌 드롭
extends StaticBody3D

const DROP_COOLDOWN : float = 0.8   # 연속 채굴 방지

var _cooldown : float = 0.0
var _dropped_item_scene : PackedScene

func _ready() -> void:
	_dropped_item_scene = preload("res://scenes/resources/dropped_item.tscn")

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

func take_hit() -> void:
	if _cooldown > 0.0:
		return
	_cooldown = DROP_COOLDOWN

	# 플레이어가 바라보는 방향의 지면 위치에 돌 드롭
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var drop := _dropped_item_scene.instantiate()
	drop.item_type = ItemData.ItemType.STONE
	# 플레이어 발 앞 지면에 드롭
	var forward: Vector3 = -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	drop.global_position = player.global_position + forward * 1.2 + Vector3(0, 0.1, 0)
	get_parent().get_parent().add_child(drop)
