# scripts/inventory_manager.gd
# 인벤토리 관리 - 7칸 슬롯 시스템
extends Node

const MAX_SLOTS = 7

signal inventory_changed

# 각 슬롯: { "item": ItemType, "count": int }
var slots: Array = []

func _ready() -> void:
	slots.resize(MAX_SLOTS)
	for i in MAX_SLOTS:
		slots[i] = {"item": ItemData.ItemType.NONE, "count": 0}

## 아이템 추가. 인벤토리가 가득 차면 false 반환
func add_item(item_type: int, amount: int = 1) -> bool:
	# 기존 슬롯에 스택 시도
	for i in MAX_SLOTS:
		if slots[i]["item"] == item_type and slots[i]["count"] > 0:
			slots[i]["count"] += amount
			inventory_changed.emit()
			return true

	# 빈 슬롯 탐색
	for i in MAX_SLOTS:
		if slots[i]["item"] == ItemData.ItemType.NONE or slots[i]["count"] == 0:
			slots[i]["item"]  = item_type
			slots[i]["count"] = amount
			inventory_changed.emit()
			return true

	return false  # 인벤토리 가득 참

func is_full() -> bool:
	for slot in slots:
		if slot["item"] == ItemData.ItemType.NONE or slot["count"] == 0:
			return false
	return true
