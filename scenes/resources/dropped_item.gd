# scenes/resources/dropped_item.gd
# 바닥 위 떠 있는 드롭 아이템 - 플레이어 접근 시 인벤토리로 흡수
extends Area3D

var item_type: int = ItemData.ItemType.NONE

@onready var mesh_inst : MeshInstance3D = $MeshInstance3D
@onready var lbl       : Label3D        = $Label3D

var _bob_time: float = 0.0

func _ready() -> void:
	# 아이템 색상 적용
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ItemData.get_item_color(item_type)
	mat.metallic     = 0.2
	mat.roughness    = 0.6
	mesh_inst.set_surface_override_material(0, mat)

	lbl.text     = ItemData.get_item_name(item_type)
	lbl.position = Vector3(0, 0.18, 0)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# 위아래 둥둥 떠다니는 효과 (지면에서 살짝 위에 고정)
	_bob_time += delta
	mesh_inst.position.y = sin(_bob_time * 2.0) * 0.03

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if InventoryManager.add_item(item_type):
			queue_free()
