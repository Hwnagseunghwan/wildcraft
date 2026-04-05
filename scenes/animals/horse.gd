# scenes/animals/horse.gd
extends "res://scenes/animals/animal_base.gd"

func _ready() -> void:
	animal_name  = "말"
	max_health   = 6
	move_speed   = 5.0
	wander_range = 15.0
	super._ready()

func _get_drops() -> Array:
	return [ItemData.ItemType.LEATHER]
