extends Node
## WeatherSystem — simulates weather cycles, rain particles, fog, lighting shifts.

enum WeatherType { CLEAR, CLOUDY, OVERCAST, LIGHT_RAIN, HEAVY_RAIN }

var current_weather: WeatherType = WeatherType.CLEAR
var _weather_timer: float = 0.0
var _weather_duration: float = 300.0   # seconds until possible change
var _rain_particles: GPUParticles3D = null
var _transition_timer: float = 0.0

# Probabilities by season
const SEASON_WEIGHTS = {
	"Spring":  [0.3, 0.25, 0.2, 0.15, 0.1],
	"Summer":  [0.5, 0.25, 0.1, 0.1, 0.05],
	"Autumn":  [0.2, 0.2, 0.25, 0.2, 0.15],
	"Winter":  [0.25, 0.2, 0.25, 0.2, 0.1],
}

func _ready() -> void:
	ServiceRegistry.register("WeatherSystem", self)
	EventBus.season_changed.connect(_on_season_changed)
	_setup_rain_particles()
	_set_weather(WeatherType.CLEAR)

func _process(delta: float) -> void:
	_weather_timer += delta
	if _weather_timer >= _weather_duration:
		_weather_timer = 0.0
		_weather_duration = randf_range(120.0, 600.0)
		_pick_next_weather()

func _pick_next_weather() -> void:
	var season = GameClock.get_season()
	var weights = SEASON_WEIGHTS.get(season, SEASON_WEIGHTS["Summer"])
	var r = randf()
	var cumulative = 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if r <= cumulative:
			_set_weather(i as WeatherType)
			return
	_set_weather(WeatherType.CLEAR)

func _set_weather(type: WeatherType) -> void:
	current_weather = type
	var type_name = WeatherType.keys()[type].to_lower().replace("_", " ")
	EventBus.weather_changed.emit(WeatherType.keys()[type].to_lower())
	# Rain particles
	if _rain_particles:
		_rain_particles.emitting = (type == WeatherType.LIGHT_RAIN or type == WeatherType.HEAVY_RAIN)
		if type == WeatherType.HEAVY_RAIN:
			_rain_particles.amount = 500
		elif type == WeatherType.LIGHT_RAIN:
			_rain_particles.amount = 150
	# Notify player
	if type != WeatherType.CLEAR:
		EventBus.notification_requested.emit("Weather: %s" % type_name, "info", 3.0)

func _setup_rain_particles() -> void:
	_rain_particles = GPUParticles3D.new()
	_rain_particles.amount = 300
	_rain_particles.lifetime = 1.5
	_rain_particles.emitting = false
	_rain_particles.position = Vector3(0, 15, 0)
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0.1, -1, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 12.0
	pm.initial_velocity_max = 18.0
	pm.gravity = Vector3(0, -9.8, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(20, 1, 20)
	pm.scale_min = 0.05
	pm.scale_max = 0.08
	var rain_mat = StandardMaterial3D.new()
	rain_mat.albedo_color = Color(0.7, 0.8, 0.9, 0.6)
	rain_mat.flags_transparent = true
	rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.02, 0.3)
	mesh.material = rain_mat
	_rain_particles.draw_pass_1 = mesh
	_rain_particles.process_material = pm
	add_child(_rain_particles)

func _on_season_changed(_season: String) -> void:
	_pick_next_weather()

func get_weather_name() -> String:
	return WeatherType.keys()[current_weather]

func is_raining() -> bool:
	return current_weather == WeatherType.LIGHT_RAIN or current_weather == WeatherType.HEAVY_RAIN
