# scenes/main.gd
# 메인 씬: 하늘·태양·낮밤 시각 연출 총괄
extends Node3D

@onready var sun: DirectionalLight3D   = $Sun
@onready var world_env: WorldEnvironment = $WorldEnvironment

var sky_mat: ProceduralSkyMaterial

func _ready() -> void:
	_setup_sky()
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.day_changed.connect(_on_day_changed)

func _setup_sky() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color     = Color(0.18, 0.50, 0.90)
	sky_mat.sky_horizon_color = Color(0.60, 0.80, 1.00)
	sky_mat.ground_bottom_color   = Color(0.25, 0.60, 0.25)
	sky_mat.ground_horizon_color  = Color(0.38, 0.72, 0.38)
	sky_mat.sun_angle_max = 30.0

	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode         = Environment.BG_SKY
	env.sky                     = sky
	env.ambient_light_source    = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy    = 0.5
	env.tonemap_mode            = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure        = 1.0

	world_env.environment = env

func _on_time_updated(t: float) -> void:
	# t: 0.0 → 1.0 (한 사이클)
	# 태양 회전: 정오(t=0.25)에 정점, 자정(t=0.75)에 지하
	sun.rotation.x = (t * TAU) - PI * 0.5

	if t < 0.1:           # 새벽
		var f := t / 0.1
		sky_mat.sky_top_color     = Color(0.05, 0.05, 0.15).lerp(Color(0.18, 0.50, 0.90), f)
		sky_mat.sky_horizon_color = Color(0.80, 0.40, 0.20).lerp(Color(0.60, 0.80, 1.00), f)
		sun.light_color           = Color(1.0, 0.65, 0.35).lerp(Color.WHITE, f)
		sun.light_energy          = f * 1.5
	elif t < 0.4:         # 낮
		sky_mat.sky_top_color     = Color(0.18, 0.50, 0.90)
		sky_mat.sky_horizon_color = Color(0.60, 0.80, 1.00)
		sun.light_color           = Color.WHITE
		sun.light_energy          = 1.5
	elif t < 0.5:         # 황혼
		var f := (t - 0.4) / 0.1
		sky_mat.sky_top_color     = Color(0.18, 0.50, 0.90).lerp(Color(0.05, 0.05, 0.15), f)
		sky_mat.sky_horizon_color = Color(0.60, 0.80, 1.00).lerp(Color(0.80, 0.25, 0.05), f)
		sun.light_color           = Color.WHITE.lerp(Color(1.0, 0.50, 0.20), f)
		sun.light_energy          = (1.0 - f) * 1.5
	else:                 # 밤
		sky_mat.sky_top_color     = Color(0.01, 0.01, 0.05)
		sky_mat.sky_horizon_color = Color(0.02, 0.02, 0.10)
		sun.light_energy          = 0.0
		world_env.environment.ambient_light_energy = 0.05

func _on_day_changed(is_day: bool) -> void:
	if is_day:
		world_env.environment.ambient_light_energy = 0.5
