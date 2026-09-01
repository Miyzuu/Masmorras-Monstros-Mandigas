extends Node

const SLOT_COUNT := 3
const SAVE_SCHEMA_VERSION := 1
const CHECKPOINT_EXPLORATION := "exploration"
const CHECKPOINT_DUNGEON := "dungeon"
const CHECKPOINT_COMPLETED := "completed"
const EXPLORATION_SCENE := "res://scenes/exploration.tscn"
const DUNGEON_SCENE := "res://scenes/dungeon.tscn"
const BOSS_SCENE := "res://scenes/main.tscn"

const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 1.0
const DEFAULT_EFFECTS_VOLUME := 1.0
const DEFAULT_FULLSCREEN := false
const DEFAULT_VSYNC := true

var active_slot := 0
var storage_root := "user://"
var master_volume := DEFAULT_MASTER_VOLUME
var music_volume := DEFAULT_MUSIC_VOLUME
var effects_volume := DEFAULT_EFFECTS_VOLUME
var fullscreen_enabled := DEFAULT_FULLSCREEN
var vsync_enabled := DEFAULT_VSYNC


func _ready() -> void:
	load_settings()
	call_deferred("apply_settings")


func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT


func has_any_save() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		var summary := get_slot_summary(slot)
		if bool(summary.get("exists", false)) and bool(summary.get("valid", false)):
			return true
	return false


func create_new_game(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	active_slot = slot
	GameState.reset_session()
	return save_active_slot(CHECKPOINT_EXPLORATION)


func load_slot(slot: int) -> String:
	if not is_valid_slot(slot):
		return ""
	var save_data := _read_slot_data(slot)
	if save_data.is_empty():
		return ""
	var game_state_data: Variant = save_data.get("game_state", {})
	if not game_state_data is Dictionary:
		return ""

	active_slot = slot
	GameState.import_save_data(game_state_data)
	var checkpoint := str(save_data.get("checkpoint", CHECKPOINT_EXPLORATION))
	match checkpoint:
		CHECKPOINT_DUNGEON:
			GameState.dungeon_active = true
			if GameState.get_current_dungeon_room_number() >= GameState.get_implemented_dungeon_room_count():
				return BOSS_SCENE
			return DUNGEON_SCENE
		CHECKPOINT_COMPLETED:
			GameState.dungeon_active = false
			GameState.reset_dungeon_progress()
			GameState.returning_from_dungeon = true
			return EXPLORATION_SCENE
		_:
			GameState.dungeon_active = false
			GameState.returning_from_dungeon = true
			return EXPLORATION_SCENE


func save_active_slot(checkpoint_override: String = "") -> bool:
	if not is_valid_slot(active_slot):
		return false
	var checkpoint := checkpoint_override
	if checkpoint.is_empty():
		checkpoint = _infer_checkpoint()
	var save_data := {
		"schema_version": SAVE_SCHEMA_VERSION,
		"saved_at": _format_local_datetime(),
		"checkpoint": checkpoint,
		"game_state": GameState.export_save_data(),
	}
	return _write_slot_data(active_slot, save_data)


func delete_slot(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return true
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error != OK:
		return false
	if active_slot == slot:
		active_slot = 0
	return true


func get_slot_summary(slot: int) -> Dictionary:
	if not is_valid_slot(slot):
		return {"exists": false, "valid": false}
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {
			"exists": false,
			"valid": true,
			"local": "Vazio",
			"saved_at": "",
		}

	var save_data := _read_slot_data(slot)
	if save_data.is_empty():
		return {
			"exists": true,
			"valid": false,
			"local": "Save inválido",
			"saved_at": "",
		}
	var game_state_data: Variant = save_data.get("game_state", {})
	if not game_state_data is Dictionary:
		return {
			"exists": true,
			"valid": false,
			"local": "Save inválido",
			"saved_at": "",
		}
	return {
		"exists": true,
		"valid": true,
		"local": _location_label(save_data, game_state_data),
		"saved_at": str(save_data.get("saved_at", "Data indisponível")),
	}


func set_audio_setting(setting_name: String, value: float) -> void:
	var safe_value := clampf(value, 0.0, 1.0)
	match setting_name:
		"master": master_volume = safe_value
		"music": music_volume = safe_value
		"effects": effects_volume = safe_value
		_: return
	apply_settings()
	save_settings()


func set_fullscreen_enabled(enabled: bool) -> void:
	fullscreen_enabled = enabled
	apply_settings()
	save_settings()


func set_vsync_enabled(enabled: bool) -> void:
	vsync_enabled = enabled
	apply_settings()
	save_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(_settings_path()) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	effects_volume = clampf(float(config.get_value("audio", "effects", DEFAULT_EFFECTS_VOLUME)), 0.0, 1.0)
	fullscreen_enabled = bool(config.get_value("video", "fullscreen", DEFAULT_FULLSCREEN))
	vsync_enabled = bool(config.get_value("video", "vsync", DEFAULT_VSYNC))


func save_settings() -> bool:
	if not _ensure_storage_directory():
		return false
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "effects", effects_volume)
	config.set_value("video", "fullscreen", fullscreen_enabled)
	config.set_value("video", "vsync", vsync_enabled)
	return config.save(_settings_path()) == OK


func apply_settings() -> void:
	if is_inside_tree() and get_tree().root.has_node("AudioManager"):
		var audio_manager := get_tree().root.get_node("AudioManager")
		audio_manager.call("set_master_volume", master_volume)
		audio_manager.call("set_bgm_volume", music_volume)
		audio_manager.call("set_sfx_volume", effects_volume)

	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen_enabled
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED
		if vsync_enabled
		else DisplayServer.VSYNC_DISABLED
	)


func set_storage_root_for_tests(new_root: String) -> void:
	storage_root = new_root


func _infer_checkpoint() -> String:
	if GameState.dungeon_active:
		return CHECKPOINT_DUNGEON
	if GameState.dungeon_completed:
		return CHECKPOINT_COMPLETED
	return CHECKPOINT_EXPLORATION


func _location_label(save_data: Dictionary, game_state_data: Dictionary) -> String:
	var checkpoint := str(save_data.get("checkpoint", CHECKPOINT_EXPLORATION))
	if checkpoint == CHECKPOINT_COMPLETED:
		return "Concluída"
	if checkpoint == CHECKPOINT_DUNGEON:
		var room_index := clampi(
			int(game_state_data.get("dungeon_room_index", 0)),
			0,
			GameState.get_implemented_dungeon_room_count() - 1
		)
		return "Masmorra — Sala %d/%d" % [
			room_index + 1,
			GameState.get_implemented_dungeon_room_count(),
		]
	return "Exploração"


func _format_local_datetime() -> String:
	var datetime := Time.get_datetime_dict_from_system(false)
	return "%02d/%02d/%04d às %02d:%02d" % [
		int(datetime["day"]),
		int(datetime["month"]),
		int(datetime["year"]),
		int(datetime["hour"]),
		int(datetime["minute"]),
	]


func _slot_path(slot: int) -> String:
	return storage_root.path_join("save_slot_%d.json" % slot)


func _settings_path() -> String:
	return storage_root.path_join("settings.cfg")


func _write_slot_data(slot: int, save_data: Dictionary) -> bool:
	if not _ensure_storage_directory():
		return false
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(save_data, "\t"))
	return file.get_error() == OK


func _read_slot_data(slot: int) -> Dictionary:
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	if int(parsed.get("schema_version", 0)) != SAVE_SCHEMA_VERSION:
		return {}
	return parsed


func _ensure_storage_directory() -> bool:
	var absolute_root := ProjectSettings.globalize_path(storage_root)
	if DirAccess.dir_exists_absolute(absolute_root):
		return true
	return DirAccess.make_dir_recursive_absolute(absolute_root) == OK
