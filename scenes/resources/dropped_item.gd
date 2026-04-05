# scenes/resources/dropped_item.gd
# 바닥 위 떠 있는 드롭 아이템 - 플레이어 접근 시 인벤토리로 흡수
extends Area3D

const PICKUP_RANGE : float = 1.6   # 자동 흡수 거리

var item_type: int = ItemData.ItemType.NONE

@onready var mesh_inst : MeshInstance3D = $MeshInstance3D
@onready var lbl       : Label3D        = $Label3D

var _bob_time : float = 0.0
var _player   : Node3D = null

func _ready() -> void:
	# 아이템 색상 적용
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ItemData.get_item_color(item_type)
	mat.metallic     = 0.2
	mat.roughness    = 0.6
	mesh_inst.set_surface_override_material(0, mat)

	lbl.text     = ItemData.get_item_name(item_type)
	lbl.position = Vector3(0, 0.18, 0)

	# 플레이어 캐시
	_player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	# 둥실 떠다니는 효과
	_bob_time += delta
	mesh_inst.position.y = sin(_bob_time * 2.5) * 0.04

	# 거리 기반 픽업 (신호 방식보다 안정적)
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return

	if global_position.distance_to(_player.global_position) <= PICKUP_RANGE:
		if InventoryManager.add_item(item_type):
			queue_free()
