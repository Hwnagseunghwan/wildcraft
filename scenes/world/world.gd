# scenes/world/world.gd
# 무한 지형 청크 생성 및 오브젝트/동물 스폰
extends Node3D

const CHUNK_SIZE      : int   = 16
const RENDER_DISTANCE : int   = 4     # 청크 단위

var chunks       : Dictionary = {}
var player_chunk : Vector2i   = Vector2i(-9999, -9999)

# 노이즈 레이어 (옥타브 합성으로 자연스러운 지형)
var noise_base   : FastNoiseLite  # 큰 산/평원 형태
var noise_detail : FastNoiseLite  # 중간 굴곡
var noise_rough  : FastNoiseLite  # 미세한 돌기

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
	var base_seed := randi()

	# 큰 지형 (산맥·평원)
	noise_base            = FastNoiseLite.new()
	noise_base.seed       = base_seed
	noise_base.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_base.frequency  = 0.018
	noise_base.fractal_type    = FastNoiseLite.FRACTAL_FBM
	noise_base.fractal_octaves = 4
	noise_base.fractal_lacunarity = 2.0
	noise_base.fractal_gain     = 0.5

	# 중간 굴곡 (언덕·골짜기)
	noise_detail            = FastNoiseLite.new()
	noise_detail.seed       = base_seed + 1
	noise_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_detail.frequency  = 0.06
	noise_detail.fractal_type    = FastNoiseLite.FRACTAL_FBM
	noise_detail.fractal_octaves = 3

	# 미세 표면 (돌기·거친 느낌)
	noise_rough            = FastNoiseLite.new()
	noise_rough.seed       = base_seed + 2
	noise_rough.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_rough.frequency  = 0.18

	tree_scene    = preload("res://scenes/resources/tree.tscn")
	stone_scene   = preload("res://scenes/resources/stone.tscn")
	mineral_scene = preload("res://scenes/resources/mineral.tscn")
	sheep_scene   = preload("res://scenes/animals/sheep.tscn")
	cow_scene     = preload("res://scenes/animals/cow.tscn")
	pig_scene     = preload("res://scenes/animals/pig.tscn")
	chicken_scene = preload("res://scenes/animals/chicken.tscn")
	horse_scene   = preload("res://scenes/animals/horse.tscn")

	# 시작 시 플레이어 주변 청크만 미리 생성 (3x3)
	for cx in range(-1, 2):
		for cz in range(-1, 2):
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

## 지형 높이값 반환 (월드 좌표) - 3개 노이즈 합성
func get_height(wx: float, wz: float) -> float:
	var h: float = 0.0
	h += noise_base.get_noise_2d(wx, wz)   * 14.0   # 큰 산/평원
	h += noise_detail.get_noise_2d(wx, wz) *  4.0   # 중간 언덕
	h += noise_rough.get_noise_2d(wx, wz)  *  0.8   # 표면 거칠기
	# 낮은 지역은 더 평평하게 (절벽보다 완만한 계곡 느낌)
	if h < 0.0:
		h *= 0.5
	return h

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
	var subdivs := 24  # 세분도 높일수록 지형 굴곡이 부드럽고 자세해짐
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

	# 충돌 + 채굴 스크립트 (땅을 때리면 돌 드롭)
	var static_body        := StaticBody3D.new()
	static_body.set_script(preload("res://scenes/resources/terrain_body.gd"))
	var col_shape          := CollisionShape3D.new()
	col_shape.shape        = arr_mesh.create_trimesh_shape()
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

	# 돌은 지형에서 채굴 → 지표면 스폰 없음

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
		var animal: Node3D = animal_scenes[rng.randi_range(0, animal_scenes.size() - 1)].instantiate() as Node3D

		var lx := rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var lz := rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var wx := chunk_pos.x * CHUNK_SIZE + lx
		var wz := chunk_pos.y * CHUNK_SIZE + lz
		chunk_node.add_child(animal)
		animal.global_position = Vector3(wx, get_height(wx, wz) + 1.0, wz)

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
	chunk_node.add_child(node)
	node.global_position = Vector3(wx, h, wz)

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
