# scenes/animals/cow.gd
extends "res://scenes/animals/animal_base.gd"

func _ready() -> void:
	animal_name  = "소"
	max_health   = 5
	move_speed   = 2.0
	super._ready()

func _get_drops() -> Array:
	return [ItemData.ItemType.LEATHER if randf() < 0.5 else ItemData.ItemType.BEEF]
