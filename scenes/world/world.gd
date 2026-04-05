# scenes/world/world.gd
# 무한 지형 청크 생성 및 오브젝트/동물 스폰
extends Node3D

const CHUNK_SIZE      : int   = 16
const RENDER_DISTANCE : int   = 4     # 청크 단위
const HEIGHT_AMP      : float = 5.0   # 지형 높낮이 폭

var chunks       : Dictionary = {}
var player_chunk : Vector2i   = Vector2i(-9999, -9999)
var noise        : FastNoiseLite

# 씬 레퍼런스
var tree_scene    : PackedScene
var stone_scene   : PackedScene
var mineral_scene : PackedScene
var sheep_scene   : PackedScene
var cow_scene     : PackedScene
var pig_scene     : PackedScene
var chicken_scene : PackedScene
var horse_scene   : PackedScene

func _ready() -> void:
	noise           = FastNoiseLite.new()
	noise.seed      = randi()
	noise.frequency = 0.04

	tree_scene    = preload("res://scenes/resources/tree.tscn")
	stone_scene   = preload("res://scenes/resources/stone.tscn")
	mineral_scene = preload("res://scenes/resources/mineral.tscn")
	sheep_scene   = preload("res://scenes/animals/sheep.tscn")
	cow_scene     = preload("res://scenes/animals/cow.tscn")
	pig_scene     = preload("res://scenes/animals/pig.tscn")
	chicken_scene = preload("res://scenes/animals/chicken.tscn")
	horse_scene   = preload("res://scenes/animals/horse.tscn")

	# 시작 시 플레이어 주변 청크 미리 생성
	for cx in range(-3, 4):
		for cz in range(-3, 4):
			generate_chunk(Vector2i(cx, cz))
	player_chunk = Vector2i(0, 0)

func _process(_delta: float) -> void:
	var player := get_node_or_null("/root/Main/Player")
	if player == null:
		return

	var px := int(floor(player.global_position.x / CHUNK_SIZE))
	var pz := int(floor(player.global_position.z / CHUNK_SIZE))
	var new_chunk := Vector2i(px, pz)

	if new_chunk != player_chunk:
		player_chunk = new_chunk
		_update_chunks()

## 지형 높이값 반환 (월드 좌표)
func get_height(wx: float, wz: float) -> float:
	return noise.get_noise_2d(wx, wz) * HEIGHT_AMP

func _update_chunks() -> void:
	var desired: Array[Vector2i] = []

	for cx in range(player_chunk.x - RENDER_DISTANCE, player_chunk.x + RENDER_DISTANCE + 1):
		for cz in range(player_chunk.y - RENDER_DISTANCE, player_chunk.y + RENDER_DISTANCE + 1):
			var cp := Vector2i(cx, cz)
			desired.append(cp)
			if not chunks.has(cp):
				generate_chunk(cp)

	# 멀리 있는 청크 제거
	var to_remove: Array = []
	for cp in chunks.keys():
		if not desired.has(cp):
			to_remove.append(cp)

	for cp in to_remove:
		if is_instance_valid(chunks[cp]):
			chunks[cp].queue_free()
		chunks.erase(cp)

func generate_chunk(chunk_pos: Vector2i) -> void:
	var chunk_node := Node3D.new()
	chunk_node.name     = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk_node.position = Vector3(chunk_pos.x * CHUNK_SIZE, 0.0, chunk_pos.y * CHUNK_SIZE)
	add_child(chunk_node)
	chunks[chunk_pos] = chunk_node

	# --- 지형 메시 생성 ---
	var subdivs := 16
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(subdivs):
		for x in range(subdivs):
			var step := float(CHUNK_SIZE) / subdivs
			var lx0 := x       * step
			var lx1 := (x + 1) * step
			var lz0 := z       * step
			var lz1 := (z + 1) * step

			var wx0 := chunk_pos.x * CHUNK_SIZE + lx0
			var wx1 := chunk_pos.x * CHUNK_SIZE + lx1
			var wz0 := chunk_pos.y * CHUNK_SIZE + lz0
			var wz1 := chunk_pos.y * CHUNK_SIZE + lz1

			var h00 := get_height(wx0, wz0)
			var h10 := get_height(wx1, wz0)
			var h01 := get_height(wx0, wz1)
			var h11 := get_height(wx1, wz1)

			var v00 := Vector3(lx0, h00, lz0)
			var v10 := Vector3(lx1, h10, lz0)
			var v01 := Vector3(lx0, h01, lz1)
			var v11 := Vector3(lx1, h11, lz1)

			# 삼각형 1
			st.set_uv(Vector2(float(x) / subdivs,       float(z) / subdivs))
			st.add_vertex(v00)
			st.set_uv(Vector2(float(x + 1) / subdivs,   float(z) / subdivs))
			st.add_vertex(v10)
			st.set_uv(Vector2(float(x) / subdivs,       float(z + 1) / subdivs))
			st.add_vertex(v01)

			# 삼각형 2
			st.set_uv(Vector2(float(x + 1) / subdivs,   float(z) / subdivs))
			st.add_vertex(v10)
			st.set_uv(Vector2(float(x + 1) / subdivs,   float(z + 1) / subdivs))
			st.add_vertex(v11)
			st.set_uv(Vector2(float(x) / subdivs,       float(z + 1) / subdivs))
			st.add_vertex(v01)

	st.generate_normals()

	var terrain_mat := StandardMaterial3D.new()
	terrain_mat.albedo_color = Color(0.28, 0.62, 0.22)
	st.set_material(terrain_mat)

	var arr_mesh := st.commit()

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = arr_mesh
	chunk_node.add_child(mesh_inst)

	# 충돌
	var static_body  := StaticBody3D.new()
	var col_shape    := CollisionShape3D.new()
	col_shape.shape  = arr_mesh.create_trimesh_shape()
	static_body.add_child(col_shape)
	mesh_inst.add_child(static_body)

	# 오브젝트 스폰
	_spawn_objects(chunk_pos, chunk_node)

func _spawn_objects(chunk_pos: Vector2i, chunk_node: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk_pos)

	# 나무 (3~8그루)
	for _i in rng.randi_range(3, 8):
		_spawn_resource(tree_scene, chunk_pos, chunk_node, rng, ItemData.ItemType.WOOD)

	# 돌 (2~5개)
	for _i in rng.randi_range(2, 5):
		_spawn_resource(stone_scene, chunk_pos, chunk_node, rng, ItemData.ItemType.STONE)

	# 광물 (30% 확률)
	if rng.randf() < 0.3:
		var mineral_types := [
			ItemData.ItemType.COAL,
			ItemData.ItemType.IRON_ORE,
			ItemData.ItemType.GOLD_ORE,
			ItemData.ItemType.DIAMOND,
		]
		var weights := [0.5, 0.3, 0.15, 0.05]
		var mtype := _weighted_pick(rng, mineral_types, weights)
		_spawn_resource(mineral_scene, chunk_pos, chunk_node, rng, mtype)

	# 동물 (40% 확률)
	if rng.randf() < 0.4:
		var animal_scenes := [sheep_scene, cow_scene, pig_scene, chicken_scene, horse_scene]
		var animal := animal_scenes[rng.randi_range(0, animal_scenes.size() - 1)].instantiate()

		var lx := rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var lz := rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var wx := chunk_pos.x * CHUNK_SIZE + lx
		var wz := chunk_pos.y * CHUNK_SIZE + lz
		animal.global_position = Vector3(wx, get_height(wx, wz) + 1.0, wz)
		chunk_node.add_child(animal)

func _spawn_resource(
		scene: PackedScene,
		chunk_pos: Vector2i,
		chunk_node: Node3D,
		rng: RandomNumberGenerator,
		res_type: int
) -> void:
	var lx := rng.randf_range(1.0, CHUNK_SIZE - 1.0)
	var lz := rng.randf_range(1.0, CHUNK_SIZE - 1.0)
	var wx := chunk_pos.x * CHUNK_SIZE + lx
	var wz := chunk_pos.y * CHUNK_SIZE + lz
	var h  := get_height(wx, wz)

	var node := scene.instantiate()
	if node.has_method("set") and "resource_type" in node:
		node.resource_type = res_type
	node.global_position = Vector3(wx, h, wz)
	chunk_node.add_child(node)

func _weighted_pick(rng: RandomNumberGenerator, items: Array, weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	var acc := 0.0
	for i in items.size():
		acc += weights[i]
		if r <= acc:
			return items[i]
	return items[-1]
