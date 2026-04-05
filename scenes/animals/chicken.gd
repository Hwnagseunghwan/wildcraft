# scenes/animals/chicken.gd
extends "res://scenes/animals/animal_base.gd"

func _ready() -> void:
	animal_name  = "닭"
	max_health   = 2
	move_speed   = 3.2
	wander_range = 6.0
	super._ready()

func _get_drops() -> Array:
	return [ItemData.ItemType.FEATHER if randf() < 0.5 else ItemData.ItemType.CHICKEN_MEAT]
