# scenes/ui/hud.gd
# HUD: 7칸 인벤토리, 시간 표시, 크로스헤어
extends CanvasLayer

const SLOT_SIZE   := Vector2(64, 64)
const SLOT_COUNT  := 7

var slot_ui_list: Array = []   # [{panel, color_rect, count_label, name_label}]

func _ready() -> void:
	_build_ui()
	InventoryManager.inventory_changed.connect(_update_inventory)
	GameManager.time_updated.connect(_update_time)
	_update_inventory()

# ─── UI 구성 ─────────────────────────────────────────────────
func _build_ui() -> void:
	# ── 크로스헤어 ──
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 28)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -8
	crosshair.offset_top  = -14
	add_child(crosshair)

	# ── 시간 라벨 ──
	var time_lbl := Label.new()
	time_lbl.name = "TimeLabel"
	time_lbl.text = "12:00"
	time_lbl.add_theme_font_size_override("font_size", 20)
	time_lbl.add_theme_color_override("font_color", Color.WHITE)
	time_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	time_lbl.offset_left  = -100
	time_lbl.offset_top   = 10
	time_lbl.offset_right = -10
	add_child(time_lbl)

	# ── 인벤토리 바 (화면 하단 중앙) ──
	var hbox := HBoxContainer.new()
	hbox.name = "InventoryBar"
	hbox.anchor_left   = 0.5
	hbox.anchor_right  = 0.5
	hbox.anchor_top    = 1.0
	hbox.anchor_bottom = 1.0
	var bar_w: float = SLOT_SIZE.x * SLOT_COUNT + 6 * (SLOT_COUNT - 1)
	hbox.offset_left   = -bar_w / 2.0
	hbox.offset_top    = -SLOT_SIZE.y - 16
	hbox.offset_right  =  bar_w / 2.0
	hbox.offset_bottom = -16
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)

	for i in SLOT_COUNT:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = SLOT_SIZE

		# 반투명 배경 스타일
		var style := StyleBoxFlat.new()
		style.bg_color        = Color(0, 0, 0, 0.55)
		style.border_color    = Color(0.8, 0.8, 0.8, 0.6)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", style)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(38, 38)
		color_rect.color               = Color.TRANSPARENT

		var count_lbl := Label.new()
		count_lbl.text = ""
		count_lbl.add_theme_font_size_override("font_size", 13)
		count_lbl.add_theme_color_override("font_color", Color.WHITE)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var name_lbl := Label.new()
		name_lbl.text = ""
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		vbox.add_child(color_rect)
		vbox.add_child(count_lbl)
		vbox.add_child(name_lbl)
		panel.add_child(vbox)
		hbox.add_child(panel)

		slot_ui_list.append({
			"panel":       panel,
			"color_rect":  color_rect,
			"count_label": count_lbl,
			"name_label":  name_lbl,
		})

# ─── 업데이트 ─────────────────────────────────────────────────
func _update_inventory() -> void:
	for i in SLOT_COUNT:
		var slot: Dictionary = InventoryManager.slots[i]
		var ui: Dictionary   = slot_ui_list[i]

		if slot["item"] != ItemData.ItemType.NONE and slot["count"] > 0:
			(ui["color_rect"] as ColorRect).color = ItemData.get_item_color(slot["item"])
			(ui["count_label"] as Label).text      = str(slot["count"])
			(ui["name_label"] as Label).text       = ItemData.get_item_name(slot["item"])
		else:
			(ui["color_rect"] as ColorRect).color = Color.TRANSPARENT
			(ui["count_label"] as Label).text      = ""
			(ui["name_label"] as Label).text       = ""

func _update_time(normalized_time: float) -> void:
	# 0.0 = 자정, 0.5 = 정오 기준으로 시각 표시
	var total_min := normalized_time * 20.0   # 총 20분 사이클
	var hour      := int(total_min * 1.2) % 24
	var minute    := int(fmod(total_min * 60.0, 60.0))
	var lbl       := get_node_or_null("TimeLabel")
	if lbl:
		lbl.text = "%02d:%02d" % [hour, minute]
