extends Node
## GameClock — in-game time, day/night, calendar, seasons. Fully pausable.

const REAL_SECONDS_PER_GAME_MINUTE: float = 1.0  # 1 real second = 1 game minute
const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const DAYS_PER_MONTH: int = 30
const MONTHS_PER_YEAR: int = 12
const SEASONS: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]

var time_scale: float = 1.0
var is_paused: bool = false

var game_minute: int = 0
var game_hour: int = 8
var game_day: int = 1
var game_month: int = 3   # March = Spring
var game_year: int = 1

var _accumulator: float = 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if is_paused or get_tree().paused:
		return
	_accumulator += delta * time_scale
	while _accumulator >= REAL_SECONDS_PER_GAME_MINUTE:
		_accumulator -= REAL_SECONDS_PER_GAME_MINUTE
		_advance_minute()

func _advance_minute() -> void:
	game_minute += 1
	if game_minute >= MINUTES_PER_HOUR:
		game_minute = 0
		game_hour += 1
		EventBus.time_of_day_changed.emit(game_hour)
		if game_hour >= HOURS_PER_DAY:
			game_hour = 0
			game_day += 1
			EventBus.day_changed.emit(game_day)
			if game_day > DAYS_PER_MONTH:
				game_day = 1
				var prev_season = get_season()
				game_month += 1
				if game_month > MONTHS_PER_YEAR:
					game_month = 1
					game_year += 1
				var new_season = get_season()
				if new_season != prev_season:
					EventBus.season_changed.emit(new_season)

func get_season() -> String:
	var idx = int((game_month - 1) / 3) % 4
	return SEASONS[idx]

func get_time_string() -> String:
	return "%02d:%02d" % [game_hour, game_minute]

func get_date_string() -> String:
	return "Day %d, Month %d, Year %d" % [game_day, game_month, game_year]

func get_day_progress() -> float:
	return (game_hour * MINUTES_PER_HOUR + game_minute) / float(HOURS_PER_DAY * MINUTES_PER_HOUR)

func is_daytime() -> bool:
	return game_hour >= 6 and game_hour < 20

func set_time(hour: int, minute: int) -> void:
	game_hour = clamp(hour, 0, 23)
	game_minute = clamp(minute, 0, 59)

func get_state() -> Dictionary:
	return {
		"minute": game_minute, "hour": game_hour, "day": game_day,
		"month": game_month, "year": game_year, "time_scale": time_scale
	}

func restore_state(data: Dictionary) -> void:
	game_minute = data.get("minute", 0)
	game_hour = data.get("hour", 8)
	game_day = data.get("day", 1)
	game_month = data.get("month", 3)
	game_year = data.get("year", 1)
	time_scale = data.get("time_scale", 1.0)

func pause_clock() -> void:
	is_paused = true

func resume_clock() -> void:
	is_paused = false
