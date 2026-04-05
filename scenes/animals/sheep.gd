# scenes/animals/sheep.gd
extends "res://scenes/animals/animal_base.gd"

func _ready() -> void:
	animal_name  = "양"
	max_health   = 3
	move_speed   = 2.5
	super._ready()

func _get_drops() -> Array:
	return [ItemData.ItemType.WOOL if randf() < 0.5 else ItemData.ItemType.MUTTON]
