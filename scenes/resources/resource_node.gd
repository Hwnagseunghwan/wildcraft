# scenes/resources/resource_node.gd
# 나무·돌·광물 공통 베이스: 체력, 피격, 드롭 아이템 생성
extends StaticBody3D

@export var resource_type : int    = ItemData.ItemType.WOOD
@export var max_health    : int    = 3
@export var display_name  : String = "자원"

var health            : int
var dropped_item_scene: PackedScene

func _ready() -> void:
	health             = max_health
	dropped_item_scene = preload("res://scenes/resources/dropped_item.tscn")

func take_hit() -> void:
	health -= 1
	_flash()
	if health <= 0:
		_spawn_drop()
		queue_free()

func _flash() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var mat: StandardMaterial3D = child.get_active_material(0) as StandardMaterial3D
			if mat == null:
				continue
			var orig: Color = mat.albedo_color
			var tween := create_tween()
			tween.tween_property(mat, "albedo_color", Color.WHITE, 0.05)
			tween.tween_property(mat, "albedo_color", orig,        0.08)

func _spawn_drop() -> void:
	var drop := dropped_item_scene.instantiate()
	drop.item_type = resource_type
	var spawn_pos  := global_position + Vector3(0.0, 0.5, 0.0)
	get_parent().add_child(drop)
	# add_child 이후 global_position 설정해야 정상 작동
	drop.global_position = spawn_pos
