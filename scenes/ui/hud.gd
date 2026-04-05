# scenes/ui/hud.gd
# HUD: 7칸 인벤토리(SubViewport 3D 프리뷰), 시간 표시, 크로스헤어
extends CanvasLayer

const SLOT_SIZE  := Vector2(70, 80)
const SLOT_COUNT := 7

# 슬롯별 {mesh_inst, mat, count_label, name_label}
var slot_ui_list: Array = []

func _ready() -> void:
	_build_ui()
	InventoryManager.inventory_changed.connect(_update_inventory)
	GameManager.time_updated.connect(_update_time)
	_update_inventory()

# ─── UI 구성 ──────────────────────────────────────────────────
func _build_ui() -> void:
	# ── 크로스헤어 ──
	var ch := Label.new()
	ch.text = "+"
	ch.add_theme_font_size_override("font_size", 28)
	ch.add_theme_color_override("font_color", Color.WHITE)
	ch.set_anchors_preset(Control.PRESET_CENTER)
	ch.offset_left = -8
	ch.offset_top  = -14
	add_child(ch)

	# ── 시간 라벨 ──
	var time_lbl := Label.new()
	time_lbl.name = "TimeLabel"
	time_lbl.text = "06:00"
	time_lbl.add_theme_font_size_override("font_size", 20)
	time_lbl.add_theme_color_override("font_color", Color.WHITE)
	time_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	time_lbl.offset_left  = -110
	time_lbl.offset_top   = 10
	time_lbl.offset_right = -10
	add_child(time_lbl)

	# ── 인벤토리 바 (하단 중앙) ──
	var hbox := HBoxContainer.new()
	hbox.name = "InventoryBar"
	var bar_w := SLOT_SIZE.x * SLOT_COUNT + 6.0 * (SLOT_COUNT - 1)
	hbox.anchor_left   = 0.5
	hbox.anchor_right  = 0.5
	hbox.anchor_top    = 1.0
	hbox.anchor_bottom = 1.0
	hbox.offset_left   = -bar_w / 2.0
	hbox.offset_top    = -SLOT_SIZE.y - 12
	hbox.offset_right  =  bar_w / 2.0
	hbox.offset_bottom = -12
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)

	for _i in SLOT_COUNT:
		var slot_data := _build_slot(hbox)
		slot_ui_list.append(slot_data)

func _build_slot(parent: HBoxContainer) -> Dictionary:
	# 슬롯 패널
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SLOT_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.0, 0.0, 0.0, 0.6)
	style.border_color = Color(0.8, 0.8, 0.8, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)

	# ── SubViewport 3D 프리뷰 ──
	var vp_container := SubViewportContainer.new()
	vp_container.custom_minimum_size = Vector2(52, 52)
	vp_container.stretch = true

	var vp := SubViewport.new()
	vp.size                      = Vector2i(96, 96)
	vp.transparent_bg            = false
	vp.own_world_3d              = true   # 각 슬롯이 독립된 3D 월드 사용
	vp.world_3d                  = World3D.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# 배경 환경 (GL Compatibility에서 transparent_bg 비신뢰 → 어두운 배경 사용)
	var env_node := WorldEnvironment.new()
	var env      := Environment.new()
	env.background_mode  = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.10, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(1.0, 1.0, 1.0)
	env.ambient_light_energy = 1.2
	env_node.environment = env
	vp.add_child(env_node)

	# 조명
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy     = 1.5
	vp.add_child(light)

	# 카메라 — 정면에서 약간 위쪽에서 내려다보는 구도
	var cam := Camera3D.new()
	cam.projection       = Camera3D.PROJECTION_ORTHOGONAL
	cam.size             = 0.26
	cam.near             = 0.01
	cam.far              = 10.0
	cam.position         = Vector3(0.0, 0.06, 0.5)
	cam.rotation_degrees = Vector3(-7.0, 0.0, 0.0)
	vp.add_child(cam)

	# 아이템 메시 (처음엔 숨김)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.visible          = false
	mesh_inst.rotation_degrees = Vector3(20, 40, 8)
	var mat := StandardMaterial3D.new()
	vp.add_child(mesh_inst)

	vp_container.add_child(vp)
	vbox.add_child(vp_container)

	# 수량 라벨
	var count_lbl := Label.new()
	count_lbl.text = ""
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color.WHITE)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(count_lbl)

	# 아이템 이름 라벨
	var name_lbl := Label.new()
	name_lbl.text = ""
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	panel.add_child(vbox)
	parent.add_child(panel)

	return {
		"mesh_inst":   mesh_inst,
		"mat":         mat,
		"count_label": count_lbl,
		"name_label":  name_lbl,
	}

# ─── 인벤토리 업데이트 ────────────────────────────────────────
func _update_inventory() -> void:
	for i in SLOT_COUNT:
		var slot: Dictionary = InventoryManager.slots[i]
		var ui: Dictionary   = slot_ui_list[i]
		var mesh_inst: MeshInstance3D = ui["mesh_inst"]
		var mat: StandardMaterial3D   = ui["mat"]

		if slot["item"] != ItemData.ItemType.NONE and slot["count"] > 0:
			mesh_inst.mesh = ItemData.create_mesh(slot["item"])
			# 메시 설정 후 material 적용 (surface 0 존재 확인 후)
			mat.albedo_color = ItemData.get_item_color(slot["item"])
			mesh_inst.set_surface_override_material(0, mat)
			mesh_inst.visible = true
			(ui["count_label"] as Label).text = str(slot["count"])
			(ui["name_label"]  as Label).text = ItemData.get_item_name(slot["item"])
		else:
			mesh_inst.visible = false
			(ui["count_label"] as Label).text = ""
			(ui["name_label"]  as Label).text = ""

# ─── 시간 업데이트 ────────────────────────────────────────────
func _update_time(normalized_time: float) -> void:
	var hour   := int(normalized_time * 24.0) % 24
	var minute := int(fmod(normalized_time * 24.0 * 60.0, 60.0))
	var lbl    := get_node_or_null("TimeLabel")
	if lbl:
		lbl.text = "%02d:%02d" % [hour, minute]
