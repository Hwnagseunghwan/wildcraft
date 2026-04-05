# scenes/resources/dropped_item.gd
# 바닥 위 떠 있는 드롭 아이템 - 아이템별 3D 메시 + 픽업
extends Area3D

const PICKUP_RANGE : float = 1.6

var item_type: int = ItemData.ItemType.NONE

@onready var mesh_inst : MeshInstance3D = $MeshInstance3D
@onready var lbl       : Label3D        = $Label3D

var _bob_time  : float  = 0.0
var _spin_time : float  = 0.0
var _player    : Node3D = null

func _ready() -> void:
	# 아이템 타입별 메시 + 색상 적용
	mesh_inst.mesh = ItemData.create_mesh(item_type)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ItemData.get_item_color(item_type)
	mat.metallic     = 0.15
	mat.roughness    = 0.65
	mesh_inst.set_surface_override_material(0, mat)

	lbl.text     = ItemData.get_item_name(item_type)
	lbl.position = Vector3(0, 0.22, 0)

	_player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	_bob_time  += delta
	_spin_time += delta

	# 둥실 + 천천히 회전
	mesh_inst.position.y      = sin(_bob_time * 2.5) * 0.04
	mesh_inst.rotation_degrees.y = _spin_time * 60.0

	# 거리 기반 픽업
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	if global_position.distance_to(_player.global_position) <= PICKUP_RANGE:
		if InventoryManager.add_item(item_type):
			queue_free()
