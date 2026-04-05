# scripts/item_data.gd
# 아이템 정의 및 데이터 - 자동 로드 싱글톤
extends Node

enum ItemType {
	NONE     = 0,
	# 자원
	WOOD     = 1,
	STONE    = 2,
	COAL     = 3,
	IRON_ORE = 4,
	GOLD_ORE = 5,
	DIAMOND  = 6,
	# 동물 드롭
	WOOL         = 7,
	MUTTON       = 8,
	LEATHER      = 9,
	BEEF         = 10,
	PORK         = 11,
	FEATHER      = 12,
	CHICKEN_MEAT = 13,
}

const ITEM_NAMES: Dictionary = {
	ItemType.NONE:         "",
	ItemType.WOOD:         "나무",
	ItemType.STONE:        "돌",
	ItemType.COAL:         "석탄",
	ItemType.IRON_ORE:     "철광석",
	ItemType.GOLD_ORE:     "금광석",
	ItemType.DIAMOND:      "다이아몬드",
	ItemType.WOOL:         "양털",
	ItemType.MUTTON:       "양고기",
	ItemType.LEATHER:      "가죽",
	ItemType.BEEF:         "소고기",
	ItemType.PORK:         "돼지고기",
	ItemType.FEATHER:      "깃털",
	ItemType.CHICKEN_MEAT: "닭고기",
}

const ITEM_COLORS: Dictionary = {
	ItemType.WOOD:         Color(0.55, 0.35, 0.15),
	ItemType.STONE:        Color(0.55, 0.55, 0.55),
	ItemType.COAL:         Color(0.12, 0.12, 0.12),
	ItemType.IRON_ORE:     Color(0.75, 0.62, 0.50),
	ItemType.GOLD_ORE:     Color(1.0,  0.85, 0.0),
	ItemType.DIAMOND:      Color(0.4,  0.9,  1.0),
	ItemType.WOOL:         Color(0.92, 0.92, 0.92),
	ItemType.MUTTON:       Color(0.85, 0.30, 0.30),
	ItemType.LEATHER:      Color(0.60, 0.38, 0.18),
	ItemType.BEEF:         Color(0.72, 0.20, 0.20),
	ItemType.PORK:         Color(0.95, 0.65, 0.65),
	ItemType.FEATHER:      Color(0.95, 0.90, 0.75),
	ItemType.CHICKEN_MEAT: Color(0.95, 0.75, 0.55),
}

func get_item_name(item_type: int) -> String:
	return ITEM_NAMES.get(item_type, "알 수 없음")

func get_item_color(item_type: int) -> Color:
	return ITEM_COLORS.get(item_type, Color.WHITE)

## 아이템 타입별 3D 메시 생성
func create_mesh(item_type: int) -> Mesh:
	match item_type:
		ItemType.WOOD:
			var m := CylinderMesh.new()
			m.top_radius      = 0.052
			m.bottom_radius   = 0.062
			m.height          = 0.16
			m.radial_segments = 10
			return m
		ItemType.STONE:
			var m := SphereMesh.new()
			m.radius          = 0.072
			m.height          = 0.10
			m.radial_segments = 8
			m.rings           = 4
			return m
		ItemType.COAL:
			var m := BoxMesh.new()
			m.size = Vector3(0.10, 0.08, 0.10)
			return m
		ItemType.IRON_ORE, ItemType.GOLD_ORE, ItemType.DIAMOND:
			var m := BoxMesh.new()
			m.size = Vector3(0.11, 0.11, 0.11)
			return m
		ItemType.WOOL:
			var m := SphereMesh.new()
			m.radius = 0.08
			m.height = 0.11
			return m
		ItemType.FEATHER:
			var m := CylinderMesh.new()
			m.top_radius    = 0.005
			m.bottom_radius = 0.018
			m.height        = 0.18
			m.radial_segments = 6
			return m
		ItemType.LEATHER:
			var m := BoxMesh.new()
			m.size = Vector3(0.14, 0.02, 0.10)
			return m
		_:
			var m := BoxMesh.new()
			m.size = Vector3(0.10, 0.08, 0.10)
			return m
