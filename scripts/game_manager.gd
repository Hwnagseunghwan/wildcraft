# scripts/game_manager.gd
# 낮/밤 사이클 관리 (각 10분 = 600초)
extends Node

signal day_changed(is_day: bool)
signal time_updated(normalized_time: float)

const DAY_DURATION: float = 600.0   # 10분(낮) + 10분(밤) = 총 20분
var current_time: float   = 0.0     # 0.0 ~ DAY_DURATION
var is_day: bool          = true

func _process(delta: float) -> void:
	current_time += delta
	if current_time >= DAY_DURATION:
		current_time -= DAY_DURATION

	var was_day := is_day
	is_day = current_time < DAY_DURATION * 0.5

	if was_day != is_day:
		day_changed.emit(is_day)

	time_updated.emit(current_time / DAY_DURATION)

func get_normalized_time() -> float:
	return current_time / DAY_DURATION
