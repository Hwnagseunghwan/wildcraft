# scenes/animals/pig.gd
extends "res://scenes/animals/animal_base.gd"

func _ready() -> void:
	animal_name  = "돼지"
	max_health   = 3
	move_speed   = 2.8
	super._ready()

func _get_drops() -> Array:
	return [ItemData.ItemType.PORK]
