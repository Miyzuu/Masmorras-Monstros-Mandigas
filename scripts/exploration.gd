extends Node2D

const PauseMenuScript = preload("res://scripts/pause_menu.gd")

enum Weapon {
	RIFLE,
	KNIFE,
}

enum EnemyState {
	PATROL,
	CHASE,
	RETURN,
}

const MAP_SIZE := Vector2i(16, 12)
const TILE_SIZE := Vector2(64.0, 32.0)
const HALF_TILE := TILE_SIZE * 0.5
const PLAYER_SPEED := 140.0
const PLAYER_COLLISION_STEP := 4.0
const MOVEMENT_EPSILON := 0.001
const PLAYER_FOOTPRINT_RADIUS := Vector2(7.0, 3.0)
const PLAYER_PATH_REPLAN_INTERVAL := 0.15
const PLAYER_MAX_HP := 100
const CLOSE_ZOOM := Vector2(1.45, 1.45)
const CAMERA_FOLLOW_SPEED := 8.0
const CAMERA_TRANSITION_TIME := 0.28
const FADE_DURATION := 0.5
const DUNGEON_SCENE := "res://scenes/dungeon.tscn"
const CHARACTER_ATLAS: Texture2D = preload("res://assets/art/characters/animations/personagens_completo_se_animacoes_640x256_16c.png")
const GROUND_TILESET: Texture2D = preload("res://assets/art/tilesets/tileset_caatinga_terra_rachada.png")
const PATH_TILESET: Texture2D = preload("res://assets/art/tilesets/tileset_caminho_batido.png")
const DUNGEON_TILESET: Texture2D = preload("res://assets/art/tilesets/tileset_masmorra_pedra.png")
const VEGETATION_TILESET: Texture2D = preload("res://assets/art/tilesets/tileset_vegetacao_caatinga.png")
const TAIPA_TILESET: Texture2D = preload("res://assets/art/tilesets/tileset_paredes_taipa.png")
const CHARACTER_FRAME_SIZE := Vector2(64.0, 64.0)
const CHARACTER_FOOT_ANCHOR := Vector2(32.0, 60.0)
const TERRAIN_TILE_FRAME_SIZE := Vector2(64.0, 32.0)
const ENVIRONMENT_PROP_FRAME_SIZE := Vector2(64.0, 64.0)
const VEGETATION_FOOT_ANCHOR := Vector2(32.0, 60.0)
const TAIPA_FOOT_ANCHOR := Vector2(32.0, 48.0)
const CHARACTER_ATLAS_COLUMNS := 10
const CHARACTER_ATLAS_ROWS := 4
const PLAYER_RIFLE_ROW := 0
const CAPANGA_ATLAS_ROW := 1
const PLAYER_KNIFE_ROW := 2
const CABRA_CABRIOLA_ROW := 3
const ANIMATION_IDLE := 0
const ANIMATION_WALK := 1
const IDLE_FIRST_COLUMN := 0
const IDLE_FRAME_COUNT := 4
const IDLE_FPS := 4.0
const WALK_FIRST_COLUMN := 4
const WALK_FRAME_COUNT := 6
const WALK_FPS := 10.0

const RIFLE_STARTING_AMMO := 5
const RIFLE_RELOAD_DURATION := 1.5
const RIFLE_RANGE := 5
const RIFLE_INTERVAL := 1.2
const RIFLE_DAMAGE := 25
const RIFLE_CRITICAL_DAMAGE := 40
const RIFLE_HIT_CHANCE := 0.90
const KNIFE_RANGE := 1
const KNIFE_INTERVAL := 0.8
const KNIFE_DAMAGE := 20
const KNIFE_CRITICAL_DAMAGE := 30
const PLAYER_CRITICAL_CHANCE := 0.25
const WEAPON_SWITCH_COOLDOWN := 0.5

const CAPANGA_MAX_HP := 150.0
const CAPANGA_PATROL_SPEED := 70.0
const CAPANGA_CHASE_SPEED := 150.0
const CAPANGA_DETECTION_RANGE := 6
const CAPANGA_DISENGAGE_RANGE := 10
const CAPANGA_ATTACK_RANGE := 1
const CAPANGA_ATTACK_INTERVAL := 1.5
const CAPANGA_BASIC_DAMAGE := 15
const CAPANGA_HEAVY_DAMAGE := 30
const CAPANGA_HEAVY_WARNING := 0.7
const CAPANGA_REGEN_PER_SECOND := 5.0
const CAPANGA_REPATH_INTERVAL := 0.2
const CAPANGA_PATROL_PAUSE := 0.6

const FAILED_PARRY_STUN := 0.7
const DAMAGE_NUMBER_DURATION := 0.8
const PARRY_TEXT_DURATION := 0.5
const DAMAGE_BORDER_DURATION := 0.15
const HIT_FLASH_DURATION := 0.12
const STEP_DISTANCE := 42.0

const COLOR_VOID := Color("17120d")
const COLOR_GROUND_A := Color("a97945")
const COLOR_GROUND_B := Color("9b693d")
const COLOR_PATH_A := Color("c49a61")
const COLOR_PATH_B := Color("b98d55")
const COLOR_MAGIC := Color("44d6b3")
const COLOR_ROUTE := Color(0.27, 0.84, 0.70, 0.45)
const COLOR_TEXT := Color("f2dfbd")
const COLOR_NORMAL_DAMAGE := Color("f2dfbd")
const COLOR_CRITICAL_DAMAGE := Color("df3328")
const COLOR_PLAYER_DAMAGE := Color("ef6a52")
const COLOR_HEALTH_BACKGROUND := Color("3b211b")
const COLOR_ENEMY_HEALTH := Color("d15a3f")
const COLOR_ALERT := Color("ed3128")
const COLOR_DOOR_FRAME := Color("3f3028")
const COLOR_DOOR_LOCKED := Color("5e493c")
const COLOR_DOOR_OPEN := Color("31977f")
const COLOR_LOCK := Color("d7b56d")

const PLAYER_START := Vector2i(1, 10)
const CAPANGA_ID := "capanga_01"
const DUNGEON_DOOR_CELL := Vector2i(15, 3)
const DUNGEON_ENTRY_CELL := Vector2i(14, 3)
const START_LANDMARK_CELL := Vector2i(5, 11)
const COMBAT_LANDMARK_CELL := Vector2i(9, 5)
const DUNGEON_LANDMARK_CELL := Vector2i(12, 3)
const CAPANGA_PATROL_CELLS := [
	Vector2i(8, 6),
	Vector2i(11, 4),
]
const ROAD_OBSTACLES = [
	Vector2i(5, 9),
	Vector2i(5, 11),
	Vector2i(6, 8),
	Vector2i(9, 5),
	Vector2i(12, 3),
]

@onready var player_anchor: Node2D = $PlayerAnchor
@onready var capanga_anchor: Node2D = $CapangaAnchor
@onready var camera: Camera2D = $Camera2D
@onready var player_hit_flash: Sprite2D = $PlayerAnchor/HitFlash
@onready var capanga_hit_flash: Sprite2D = $CapangaAnchor/HitFlash
@onready var dust_particles: CPUParticles2D = $PlayerAnchor/DustParticles
@onready var rifle_muzzle_flash: Node2D = $PlayerAnchor/RifleMuzzleFlash
@onready var status_label: Label = $Interface/TopPanel/Status
@onready var hint_panel: ColorRect = $Interface/HintPanel
@onready var version_label: Label = $Interface/Version
@onready var health_fill: ColorRect = $Interface/CombatHUD/HealthBack/HealthFill
@onready var health_label: Label = $Interface/CombatHUD/HealthBack/HealthLabel
@onready var weapon_label: Label = $Interface/CombatHUD/WeaponLabel
@onready var lapada_pip1: ColorRect = $Interface/CombatHUD/LapadaContainer/Pip1
@onready var lapada_pip2: ColorRect = $Interface/CombatHUD/LapadaContainer/Pip2
@onready var lapada_pip3: ColorRect = $Interface/CombatHUD/LapadaContainer/Pip3
@onready var realtime_hud: RealtimeHUD = $Interface/RealtimeHUD
@onready var damage_border: Control = $Interface/DamageBorder
@onready var dungeon_prompt: Control = $DialogLayer/DungeonPrompt
@onready var dungeon_yes_button: Button = $DialogLayer/DungeonPrompt/Dialog/YesButton
@onready var dungeon_no_button: Button = $DialogLayer/DungeonPrompt/Dialog/NoButton
@onready var fade: ColorRect = $FadeLayer/Fade

var astar := AStarGrid2D.new()
var movement_path := PackedVector2Array()
var path_index := 0
var destination_marker := Vector2.ZERO
var has_destination := false
var player_repath_remaining := 0.0
var slide_axis_preference := 0
var step_distance_accumulator := 0.0
var player_animation_state := ANIMATION_IDLE
var player_animation_frame := 0
var player_animation_elapsed := 0.0
var capanga_animation_state := ANIMATION_IDLE
var capanga_animation_frame := 0
var capanga_animation_elapsed := 0.0
var overview_enabled := false
var camera_transitioning := false
var camera_tween: Tween
var fade_tween: Tween

var player_hp: int:
	get:
		return GameState.player_hp
	set(value):
		GameState.set_player_hp(value)
var rifle_ammo: int:
	get:
		return GameState.rifle_ammo
	set(value):
		GameState.set_rifle_ammo(value)
var rifle_reserve_ammo: int:
	get:
		return GameState.rifle_reserve_ammo
	set(value):
		GameState.set_rifle_reserve_ammo(value)
var current_weapon: int:
	get:
		return GameState.current_weapon
	set(value):
		GameState.set_current_weapon(value)
var player_attack_cooldown := 0.0
var weapon_switch_cooldown := 0.0
var is_reloading := false
var reload_remaining := 0.0
var stun_remaining := 0.0
var skip_next_player_attack := false

var capanga_active := true
var capanga_hp := CAPANGA_MAX_HP
var capanga_state := EnemyState.PATROL
var capanga_patrol_target_index := 1
var capanga_return_target_index := 0
var capanga_path := PackedVector2Array()
var capanga_path_index := 0
var capanga_repath_remaining := 0.0
var capanga_patrol_pause_remaining := 0.0
var capanga_attack_cooldown := CAPANGA_ATTACK_INTERVAL
var capanga_basic_attack_count := 0
var heavy_warning_active := false
var heavy_warning_remaining := 0.0

var damage_border_remaining := 0.0
var player_hit_flash_remaining := 0.0
var capanga_hit_flash_remaining := 0.0
var combat_popups: Array[Dictionary] = []
var dungeon_prompt_visible := false
var door_contact_latched := false
var scene_transitioning := false
var pause_menu


func _ready() -> void:
	_setup_pause_menu()
	_setup_pathfinding()
	var start_position := _cell_to_world(PLAYER_START)
	var returned_from_combat: bool = GameState.returning_from_combat
	var returned_from_dungeon: bool = GameState.returning_from_dungeon
	var returned_to_exploration := returned_from_combat or returned_from_dungeon
	player_anchor.position = GameState.consume_return_position(start_position)
	capanga_anchor.position = _cell_to_world(CAPANGA_PATROL_CELLS[0])
	capanga_active = returned_to_exploration or not GameState.is_encounter_defeated(CAPANGA_ID)
	door_contact_latched = returned_from_dungeon
	camera.zoom = CLOSE_ZOOM
	camera.position = _clamp_camera_position(player_anchor.position, camera.zoom)
	version_label.text = str(ProjectSettings.get_setting("application/config/version", "V.0.0.0"))
	hint_panel.visible = false
	dungeon_prompt.visible = false
	dungeon_yes_button.pressed.connect(_confirm_dungeon_entry)
	dungeon_no_button.pressed.connect(_cancel_dungeon_entry)

	if returned_to_exploration:
		scene_transitioning = true
		fade.mouse_filter = Control.MOUSE_FILTER_STOP
		fade.modulate.a = 1.0
		fade_tween = create_tween()
		fade_tween.tween_property(fade, "modulate:a", 0.0, FADE_DURATION)
		fade_tween.finished.connect(_finish_entry_fade, CONNECT_ONE_SHOT)
		GameState.acknowledge_return()
	else:
		fade.modulate.a = 0.0

	if returned_to_exploration and GameState.is_encounter_defeated(CAPANGA_ID):
		_update_status("Capanga renasceu — progresso mantido.")
	elif capanga_active:
		_update_status("Capanga patrulhando adiante.")
	else:
		_update_status("Capanga derrotado — a porta da masmorra está liberada.")
	_update_hud()
	_update_damage_border()
	_update_hit_flash_overlays()
	queue_redraw()


func _setup_pause_menu() -> void:
	var pause_layer := CanvasLayer.new()
	pause_layer.name = "PauseLayer"
	pause_layer.layer = 200
	add_child(pause_layer)
	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_layer.add_child(pause_menu)
	pause_menu.configure(false, Callable(self, "_can_open_pause_menu"))


func _can_open_pause_menu() -> bool:
	return not scene_transitioning and not dungeon_prompt_visible


func _physics_process(delta: float) -> void:
	if dungeon_prompt_visible or scene_transitioning:
		return

	_advance_realtime(delta)

	if not overview_enabled and not camera_transitioning:
		var follow_weight := 1.0 - exp(-CAMERA_FOLLOW_SPEED * delta)
		var camera_target := _clamp_camera_position(player_anchor.position, camera.zoom)
		camera.position = camera.position.lerp(camera_target, follow_weight)


func _advance_realtime(
	delta: float,
	hit_roll: float = -1.0,
	critical_roll: float = -1.0
) -> void:
	_advance_timers(delta)
	var player_previous_position := player_anchor.position
	if stun_remaining <= 0.0:
		_move_player(delta)
	_update_player_animation(delta, player_previous_position)
	if _check_dungeon_door_contact():
		_update_hud()
		queue_redraw()
		return
	var capanga_previous_position := capanga_anchor.position
	_advance_capanga_ai(delta)
	_update_capanga_animation(delta, capanga_previous_position)
	_attempt_auto_attack(hit_roll, critical_roll)
	_advance_capanga_attack(delta)
	_update_hud()
	_update_hit_flash_overlays()
	queue_redraw()


func _advance_timers(delta: float) -> void:
	player_attack_cooldown = maxf(0.0, player_attack_cooldown - delta)
	weapon_switch_cooldown = maxf(0.0, weapon_switch_cooldown - delta)
	player_repath_remaining = maxf(0.0, player_repath_remaining - delta)
	stun_remaining = maxf(0.0, stun_remaining - delta)
	damage_border_remaining = maxf(0.0, damage_border_remaining - delta)
	player_hit_flash_remaining = maxf(0.0, player_hit_flash_remaining - delta)
	capanga_hit_flash_remaining = maxf(0.0, capanga_hit_flash_remaining - delta)
	_update_damage_border()

	if is_reloading:
		reload_remaining = maxf(0.0, reload_remaining - delta)
		if reload_remaining <= 0.0:
			_complete_reload()

	for index in range(combat_popups.size() - 1, -1, -1):
		var popup := combat_popups[index]
		popup["elapsed"] = float(popup["elapsed"]) + delta
		if float(popup["elapsed"]) >= float(popup["duration"]):
			combat_popups.remove_at(index)


func _update_player_animation(delta: float, previous_position: Vector2) -> void:
	var result := _next_character_animation(
		player_animation_state,
		player_animation_frame,
		player_animation_elapsed,
		not player_anchor.position.is_equal_approx(previous_position),
		delta
	)
	player_animation_state = int(result["state"])
	player_animation_frame = int(result["frame"])
	player_animation_elapsed = float(result["elapsed"])


func _update_capanga_animation(delta: float, previous_position: Vector2) -> void:
	var result := _next_character_animation(
		capanga_animation_state,
		capanga_animation_frame,
		capanga_animation_elapsed,
		capanga_active and not capanga_anchor.position.is_equal_approx(previous_position),
		delta
	)
	capanga_animation_state = int(result["state"])
	capanga_animation_frame = int(result["frame"])
	capanga_animation_elapsed = float(result["elapsed"])


func _next_character_animation(
	current_state: int,
	current_frame: int,
	current_elapsed: float,
	moved: bool,
	delta: float
) -> Dictionary:
	var target_state := ANIMATION_WALK if moved else ANIMATION_IDLE
	if current_state != target_state:
		return {
			"state": target_state,
			"frame": 0,
			"elapsed": 0.0,
		}

	var frame_count := WALK_FRAME_COUNT if target_state == ANIMATION_WALK else IDLE_FRAME_COUNT
	var frames_per_second := WALK_FPS if target_state == ANIMATION_WALK else IDLE_FPS
	var frame_duration := 1.0 / frames_per_second
	var next_elapsed := maxf(0.0, current_elapsed) + maxf(0.0, delta)
	var frames_advanced := floori(next_elapsed / frame_duration)
	if frames_advanced > 0:
		next_elapsed = fmod(next_elapsed, frame_duration)

	return {
		"state": target_state,
		"frame": (current_frame + frames_advanced) % frame_count,
		"elapsed": next_elapsed,
	}


func _reset_character_animations_to_idle() -> void:
	player_animation_state = ANIMATION_IDLE
	player_animation_frame = 0
	player_animation_elapsed = 0.0
	capanga_animation_state = ANIMATION_IDLE
	capanga_animation_frame = 0
	capanga_animation_elapsed = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if scene_transitioning:
		get_viewport().set_input_as_handled()
		return

	if dungeon_prompt_visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if _handle_dungeon_prompt_key(event.keycode):
				get_viewport().set_input_as_handled()
				return
		if event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_toggle_overview()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_Q:
			_toggle_weapon()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_E:
			_attempt_lapada_seca()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_R:
			_start_reload()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_SPACE:
			_attempt_parry()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if stun_remaining > 0.0:
				_update_status("Atordoado — aguarde 0,7 s.")
			else:
				_set_destination(get_global_mouse_position())
			get_viewport().set_input_as_handled()


func _handle_dungeon_prompt_key(keycode: int) -> bool:
	if keycode == KEY_ENTER or keycode == KEY_KP_ENTER or keycode == KEY_SPACE:
		_confirm_dungeon_entry()
		return true
	if keycode == KEY_ESCAPE:
		_cancel_dungeon_entry()
		return true
	return false


func _check_dungeon_door_contact() -> bool:
	var touching_entry := _world_to_cell(player_anchor.position) == DUNGEON_ENTRY_CELL
	if not touching_entry:
		door_contact_latched = false
		return false
	if door_contact_latched:
		return false

	door_contact_latched = true
	movement_path.clear()
	path_index = 0
	has_destination = false
	if not _is_dungeon_door_unlocked():
		_update_status("Porta trancada — derrote o Capanga para entrar.")
		return false

	_open_dungeon_prompt()
	return true


func _is_dungeon_door_unlocked() -> bool:
	return GameState.is_encounter_defeated(CAPANGA_ID)


func _open_dungeon_prompt() -> void:
	if dungeon_prompt_visible or scene_transitioning:
		return
	dungeon_prompt_visible = true
	dungeon_prompt.visible = true
	movement_path.clear()
	path_index = 0
	has_destination = false
	_reset_character_animations_to_idle()
	_update_status("Entrar na masmorra?")
	dungeon_yes_button.grab_focus()


func _cancel_dungeon_entry() -> void:
	if not dungeon_prompt_visible or scene_transitioning:
		return
	dungeon_prompt_visible = false
	dungeon_prompt.visible = false
	_update_status("Entrada cancelada — afaste-se da porta para tentar novamente.")


func _prepare_dungeon_entry() -> void:
	GameState.begin_dungeon(
		_cell_to_world(DUNGEON_ENTRY_CELL),
		player_hp,
		rifle_ammo,
		current_weapon
	)


func _confirm_dungeon_entry() -> void:
	if not dungeon_prompt_visible or scene_transitioning or not _is_dungeon_door_unlocked():
		return
	dungeon_prompt_visible = false
	dungeon_prompt.visible = false
	scene_transitioning = true
	_prepare_dungeon_entry()
	_start_scene_transition(DUNGEON_SCENE)


func _start_scene_transition(scene_path: String) -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_tween = create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, FADE_DURATION)
	fade_tween.finished.connect(_change_scene.bind(scene_path), CONNECT_ONE_SHOT)


func _finish_entry_fade() -> void:
	scene_transitioning = false
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _change_scene(scene_path: String) -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file(scene_path)


func _toggle_weapon() -> bool:
	if stun_remaining > 0.0:
		_update_status("Atordoado — não é possível trocar de arma.")
		return false
	if is_reloading:
		_update_status("Recarga ativa — Q bloqueado.")
		return false
	if weapon_switch_cooldown > 0.0:
		_update_status("Q em recarga por %.1f s." % weapon_switch_cooldown)
		return false
	current_weapon = Weapon.KNIFE if current_weapon == Weapon.RIFLE else Weapon.RIFLE
	weapon_switch_cooldown = WEAPON_SWITCH_COOLDOWN
	_play_audio("ui_click")
	if current_weapon == Weapon.RIFLE:
		_update_status("Rifle equipado — ataques automáticos em até 5 tiles.")
	else:
		_update_status("Peixeira equipada — ataques automáticos em 1 tile.")
	_update_hud()
	return true


func _start_reload() -> bool:
	if scene_transitioning or dungeon_prompt_visible:
		return false
	if is_reloading:
		_update_status("O Rifle já está sendo recarregado.")
		return false
	if stun_remaining > 0.0:
		_update_status("Atordoado — não é possível recarregar.")
		return false
	if current_weapon != Weapon.RIFLE:
		_update_status("Equipe o Rifle [Q] para recarregar.")
		return false
	if rifle_ammo >= RIFLE_STARTING_AMMO:
		_update_status("O pente do Rifle já está cheio.")
		return false
	if rifle_reserve_ammo <= 0:
		_update_status("Sem balas na reserva.")
		return false

	is_reloading = true
	reload_remaining = RIFLE_RELOAD_DURATION
	_update_status("RECARREGANDO — mova; ataque/E/Q bloqueados.")
	_update_hud()
	return true


func _complete_reload() -> int:
	if not is_reloading:
		return 0
	is_reloading = false
	reload_remaining = 0.0
	var transferred_ammo: int = GameState.reload_rifle_magazine()
	if transferred_ammo > 0:
		_play_audio("ui_click")
		_update_status("Recarga concluída — pente %d/%d, reserva %d." % [
			rifle_ammo,
			RIFLE_STARTING_AMMO,
			rifle_reserve_ammo,
		])
	else:
		_update_status("Recarga encerrada sem transferir munição.")
	_update_hud()
	return transferred_ammo


func _cancel_reload(reason: String) -> bool:
	if not is_reloading:
		return false
	is_reloading = false
	reload_remaining = 0.0
	_update_status(reason)
	_update_hud()
	return true


func _attempt_parry() -> bool:
	if is_reloading:
		_cancel_reload("Recarga cancelada para tentar o aparo.")
	if stun_remaining > 0.0:
		return false
	if heavy_warning_active:
		heavy_warning_active = false
		heavy_warning_remaining = 0.0
		capanga_basic_attack_count = 0
		capanga_attack_cooldown = CAPANGA_ATTACK_INTERVAL
		_play_audio("parry")
		_trigger_screenshake(0.4)
		_spawn_popup("HÁ", player_anchor.position, Color.WHITE, 22, true, PARRY_TEXT_DURATION)
		_update_status("HÁ — ataque pesado aparado.")
		queue_redraw()
		return true

	stun_remaining = FAILED_PARRY_STUN
	skip_next_player_attack = true
	_update_status("Aparo falhou — stun de 0,7 s e próximo ataque perdido.")
	return false


func _attempt_auto_attack(hit_roll: float = -1.0, critical_roll: float = -1.0) -> bool:
	if (
		not capanga_active
		or stun_remaining > 0.0
		or player_attack_cooldown > 0.0
		or is_reloading
	):
		return false

	var attack_range := RIFLE_RANGE if current_weapon == Weapon.RIFLE else KNIFE_RANGE
	if _tile_distance_between_positions(player_anchor.position, capanga_anchor.position) > attack_range:
		return false
	if current_weapon == Weapon.RIFLE and rifle_ammo <= 0:
		var empty_message := (
			"PENTE VAZIO — pressione R para recarregar."
			if rifle_reserve_ammo > 0
			else "SEM MUNIÇÃO — pressione Q para usar a Peixeira."
		)
		if status_label.text != empty_message:
			_update_status(empty_message)
		return false

	var attack_interval := RIFLE_INTERVAL if current_weapon == Weapon.RIFLE else KNIFE_INTERVAL
	player_attack_cooldown = attack_interval
	if current_weapon == Weapon.RIFLE:
		rifle_ammo -= 1
		_play_audio("shoot")
		_emit_rifle_muzzle_flash()
	else:
		_play_audio("knife")

	if skip_next_player_attack:
		skip_next_player_attack = false
		_spawn_popup("ERROU", capanga_anchor.position, COLOR_NORMAL_DAMAGE, 14, false)
		_update_status("Aparo mal executado — ataque perdido.")
		return true

	var resolved_hit_roll := randf() if hit_roll < 0.0 else hit_roll
	if current_weapon == Weapon.RIFLE and resolved_hit_roll >= RIFLE_HIT_CHANCE:
		_spawn_popup("ERROU", capanga_anchor.position, COLOR_NORMAL_DAMAGE, 14, false)
		_update_status("Disparo errou — %d bala(s) restante(s)." % rifle_ammo)
		return true

	var resolved_critical_roll := randf() if critical_roll < 0.0 else critical_roll
	var critical := resolved_critical_roll < PLAYER_CRITICAL_CHANCE
	var damage := 0
	if current_weapon == Weapon.RIFLE:
		damage = RIFLE_CRITICAL_DAMAGE if critical else RIFLE_DAMAGE
		if critical:
			GameState.add_lapada_charge()
	else:
		damage = KNIFE_CRITICAL_DAMAGE if critical else KNIFE_DAMAGE

	_damage_capanga(damage, critical)
	return true


func _damage_capanga(amount: int, critical: bool, play_impact_audio: bool = true) -> void:
	capanga_hp = maxf(0.0, capanga_hp - float(amount))
	capanga_hit_flash_remaining = HIT_FLASH_DURATION
	_update_hit_flash_overlays()
	if critical:
		if play_impact_audio:
			_play_audio("critical")
		_trigger_screenshake(0.5)
	elif play_impact_audio:
		_play_audio("hit")
	_spawn_popup(
		str(amount),
		capanga_anchor.position,
		COLOR_CRITICAL_DAMAGE if critical else COLOR_NORMAL_DAMAGE,
		22 if critical else 15,
		critical
	)
	if capanga_hp <= 0.0:
		_defeat_capanga()
		return

	_set_capanga_state(EnemyState.CHASE)
	var result := "CRÍTICO: %d" % amount if critical else "Dano causado: %d" % amount
	if current_weapon == Weapon.RIFLE:
		result += " — %d bala(s)." % rifle_ammo
	_update_status(result)


func _defeat_capanga() -> void:
	capanga_active = false
	capanga_path.clear()
	heavy_warning_active = false
	GameState.mark_encounter_defeated(CAPANGA_ID)
	if _world_to_cell(player_anchor.position) == DUNGEON_ENTRY_CELL:
		door_contact_latched = false
	_update_status("Capanga derrotado — a porta da masmorra foi liberada.")


func _damage_player(amount: int) -> bool:
	player_hp = maxi(0, player_hp - amount)
	damage_border_remaining = DAMAGE_BORDER_DURATION
	player_hit_flash_remaining = HIT_FLASH_DURATION
	_update_hit_flash_overlays()
	_play_audio("hit")
	_trigger_screenshake(0.35)
	_spawn_popup(str(amount), player_anchor.position, COLOR_PLAYER_DAMAGE, 16, true)
	_update_damage_border()
	if player_hp <= 0:
		_handle_player_defeat()
		return true
	return false


func _handle_player_defeat() -> void:
	GameState.respawn_player()
	player_anchor.position = _cell_to_world(PLAYER_START)
	movement_path.clear()
	path_index = 0
	has_destination = false
	is_reloading = false
	reload_remaining = 0.0
	stun_remaining = 0.0
	skip_next_player_attack = false
	player_attack_cooldown = 0.0
	heavy_warning_active = false
	heavy_warning_remaining = 0.0
	capanga_basic_attack_count = 0
	capanga_attack_cooldown = CAPANGA_ATTACK_INTERVAL
	_reset_character_animations_to_idle()
	if capanga_active:
		capanga_return_target_index = _nearest_patrol_index()
		_set_capanga_state(EnemyState.RETURN)
	_update_status("Derrota — retorno com 40% de vida e munição preservada.")


func _advance_capanga_ai(delta: float) -> void:
	if not capanga_active or heavy_warning_active:
		return

	var distance := _tile_distance_between_positions(capanga_anchor.position, player_anchor.position)
	match capanga_state:
		EnemyState.PATROL:
			capanga_hp = minf(CAPANGA_MAX_HP, capanga_hp + CAPANGA_REGEN_PER_SECOND * delta)
			if distance <= CAPANGA_DETECTION_RANGE:
				_set_capanga_state(EnemyState.CHASE)
				return
			_advance_patrol(delta)
		EnemyState.CHASE:
			if distance > CAPANGA_DISENGAGE_RANGE:
				capanga_return_target_index = _nearest_patrol_index()
				_set_capanga_state(EnemyState.RETURN)
				return
			if distance > CAPANGA_ATTACK_RANGE:
				_move_capanga_toward(
					_world_to_cell(player_anchor.position),
					CAPANGA_CHASE_SPEED,
					delta
				)
		EnemyState.RETURN:
			var return_cell: Vector2i = CAPANGA_PATROL_CELLS[capanga_return_target_index]
			_move_capanga_toward(return_cell, CAPANGA_PATROL_SPEED, delta)
			if capanga_anchor.position.distance_to(_cell_to_world(return_cell)) <= 1.0:
				capanga_anchor.position = _cell_to_world(return_cell)
				capanga_patrol_target_index = 1 - capanga_return_target_index
				_set_capanga_state(EnemyState.PATROL)


func _advance_patrol(delta: float) -> void:
	if capanga_patrol_pause_remaining > 0.0:
		capanga_patrol_pause_remaining = maxf(0.0, capanga_patrol_pause_remaining - delta)
		return

	var target_cell: Vector2i = CAPANGA_PATROL_CELLS[capanga_patrol_target_index]
	_move_capanga_toward(target_cell, CAPANGA_PATROL_SPEED, delta)
	if capanga_anchor.position.distance_to(_cell_to_world(target_cell)) <= 1.0:
		capanga_anchor.position = _cell_to_world(target_cell)
		capanga_patrol_target_index = 1 - capanga_patrol_target_index
		capanga_patrol_pause_remaining = CAPANGA_PATROL_PAUSE
		capanga_path.clear()


func _move_capanga_toward(target_cell: Vector2i, speed: float, delta: float) -> void:
	capanga_repath_remaining = maxf(0.0, capanga_repath_remaining - delta)
	if capanga_repath_remaining <= 0.0 or capanga_path_index >= capanga_path.size():
		_rebuild_capanga_path(target_cell)
		capanga_repath_remaining = CAPANGA_REPATH_INTERVAL
	if capanga_path_index >= capanga_path.size():
		return

	var waypoint := capanga_path[capanga_path_index]
	capanga_anchor.position = capanga_anchor.position.move_toward(waypoint, speed * delta)
	if capanga_anchor.position.distance_to(waypoint) <= 0.5:
		capanga_anchor.position = waypoint
		capanga_path_index += 1


func _rebuild_capanga_path(target_cell: Vector2i) -> void:
	capanga_path.clear()
	capanga_path_index = 0
	var start_cell := _nearest_walkable_cell(capanga_anchor.position)
	if not astar.is_in_boundsv(target_cell) or astar.is_point_solid(target_cell):
		return
	if start_cell == target_cell:
		capanga_path.append(_cell_to_world(target_cell))
		return
	var id_path := astar.get_id_path(start_cell, target_cell)
	for index in range(1, id_path.size()):
		capanga_path.append(_cell_to_world(id_path[index]))


func _set_capanga_state(new_state: int) -> void:
	if capanga_state == new_state:
		return
	capanga_state = new_state
	capanga_path.clear()
	capanga_path_index = 0
	capanga_repath_remaining = 0.0
	if new_state != EnemyState.CHASE:
		capanga_attack_cooldown = CAPANGA_ATTACK_INTERVAL


func _advance_capanga_attack(delta: float) -> void:
	if not capanga_active:
		return

	if heavy_warning_active:
		heavy_warning_remaining = maxf(0.0, heavy_warning_remaining - delta)
		if heavy_warning_remaining <= 0.0:
			heavy_warning_active = false
			if _capanga_can_attack_player():
				var defeated := _damage_player(CAPANGA_HEAVY_DAMAGE)
				if not defeated:
					_update_status("Ataque pesado: 30 de dano.")
			else:
				_update_status("O ataque pesado não alcançou o Cangaceiro.")
			capanga_basic_attack_count = 0
			capanga_attack_cooldown = CAPANGA_ATTACK_INTERVAL
		return

	if capanga_state != EnemyState.CHASE or not _capanga_can_attack_player():
		capanga_attack_cooldown = CAPANGA_ATTACK_INTERVAL
		return

	capanga_attack_cooldown = maxf(0.0, capanga_attack_cooldown - delta)
	if capanga_attack_cooldown > 0.0:
		return

	if capanga_basic_attack_count < 3:
		var defeated := _damage_player(CAPANGA_BASIC_DAMAGE)
		if not defeated:
			capanga_basic_attack_count += 1
			capanga_attack_cooldown = CAPANGA_ATTACK_INTERVAL
			_update_status("Capanga atacou: 15 de dano.")
	else:
		heavy_warning_active = true
		heavy_warning_remaining = CAPANGA_HEAVY_WARNING
		_update_status("Ataque pesado chegando — pressione Espaço!")


func _capanga_can_attack_player() -> bool:
	return _tile_distance_between_positions(
		capanga_anchor.position,
		player_anchor.position
	) <= CAPANGA_ATTACK_RANGE


func _nearest_patrol_index() -> int:
	var distance_a := capanga_anchor.position.distance_to(_cell_to_world(CAPANGA_PATROL_CELLS[0]))
	var distance_b := capanga_anchor.position.distance_to(_cell_to_world(CAPANGA_PATROL_CELLS[1]))
	return 0 if distance_a <= distance_b else 1


func _setup_pathfinding() -> void:
	astar.region = Rect2i(Vector2i.ZERO, MAP_SIZE)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			if not _is_road(cell):
				astar.set_point_solid(cell)

	for obstacle in ROAD_OBSTACLES:
		astar.set_point_solid(obstacle)
	astar.set_point_solid(DUNGEON_DOOR_CELL)


func _is_road(cell: Vector2i) -> bool:
	var lower_path := cell.x <= 6 and cell.y >= 9
	var first_turn := cell.x >= 4 and cell.x <= 7 and cell.y >= 6 and cell.y <= 10
	var middle_path := cell.x >= 6 and cell.x <= 12 and cell.y >= 4 and cell.y <= 7
	var upper_path := cell.x >= 10 and cell.y >= 1 and cell.y <= 5
	return lower_path or first_turn or middle_path or upper_path


func _set_destination(clicked_world_position: Vector2) -> void:
	var target_cell := _world_to_cell(clicked_world_position)
	if target_cell == DUNGEON_DOOR_CELL or _is_dungeon_door_click(clicked_world_position):
		target_cell = DUNGEON_ENTRY_CELL
	if not astar.is_in_boundsv(target_cell):
		_update_status("Destino fora do mapa.")
		return
	if astar.is_point_solid(target_cell):
		_update_status("Esse terreno está bloqueado.")
		return

	var final_position := _position_inside_cell(clicked_world_position, target_cell)
	if not _is_walkable_player_footprint(final_position):
		final_position = _cell_to_world(target_cell)
	destination_marker = final_position
	has_destination = true
	player_repath_remaining = 0.0
	if not _rebuild_player_path():
		has_destination = false
		_update_status("Não há caminho até esse ponto.")
		return
	_update_status("Caminhando — ataques automáticos não interrompem o movimento.")


func _rebuild_player_path() -> bool:
	movement_path.clear()
	path_index = 0
	if not has_destination:
		return false

	var target_cell := _world_to_cell(destination_marker)
	if not astar.is_in_boundsv(target_cell) or astar.is_point_solid(target_cell):
		return false

	var start_cell := _nearest_walkable_cell(player_anchor.position)
	var capanga_cell := _world_to_cell(capanga_anchor.position)
	var block_capanga := capanga_active and astar.is_in_boundsv(capanga_cell)
	var capanga_cell_was_solid := false
	if block_capanga:
		capanga_cell_was_solid = astar.is_point_solid(capanga_cell)
		astar.set_point_solid(capanga_cell, true)
	var id_path := astar.get_id_path(start_cell, target_cell)
	if block_capanga:
		astar.set_point_solid(capanga_cell, capanga_cell_was_solid)
	if id_path.is_empty():
		return false

	for index in range(1, id_path.size()):
		movement_path.append(_cell_to_world(id_path[index]))
	if movement_path.is_empty():
		movement_path.append(destination_marker)
	else:
		movement_path[movement_path.size() - 1] = destination_marker
	return true


func _player_path_requires_replan() -> bool:
	if not capanga_active or path_index >= movement_path.size():
		return false
	var capanga_cell := _world_to_cell(capanga_anchor.position)
	var last_index := mini(path_index + 2, movement_path.size())
	for index in range(path_index, last_index):
		if _world_to_cell(movement_path[index]) == capanga_cell:
			return true
	return false


func _wait_for_player_path() -> void:
	movement_path.clear()
	path_index = 0
	player_repath_remaining = PLAYER_PATH_REPLAN_INTERVAL
	_update_status("Passagem ocupada — ajustando a rota.")


func _is_dungeon_door_click(world_position: Vector2) -> bool:
	var door_position := _cell_to_world(DUNGEON_DOOR_CELL)
	return Rect2(door_position + Vector2(-24.0, -46.0), Vector2(48.0, 50.0)).has_point(world_position)


func _move_player(delta: float) -> void:
	var keyboard_input := _keyboard_movement_vector()
	if not keyboard_input.is_zero_approx():
		_move_player_with_input(delta, keyboard_input)
		return
	_move_player_along_path(delta)


func _keyboard_movement_vector() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	return direction.normalized()


func _move_player_with_input(delta: float, raw_input: Vector2) -> bool:
	if raw_input.is_zero_approx() or delta <= 0.0:
		return false

	var had_click_destination := has_destination or not movement_path.is_empty()
	movement_path.clear()
	path_index = 0
	has_destination = false
	player_repath_remaining = 0.0
	if had_click_destination:
		_update_status("Rota cancelada.")

	var direction := raw_input.normalized()
	var remaining_distance := PLAYER_SPEED * delta
	var moved_distance := 0.0
	while remaining_distance > MOVEMENT_EPSILON:
		var step_length := minf(PLAYER_COLLISION_STEP, remaining_distance)
		var accepted_motion := _resolve_player_motion(direction * step_length)
		if accepted_motion.is_zero_approx():
			break
		player_anchor.position += accepted_motion
		var accepted_distance := accepted_motion.length()
		moved_distance += accepted_distance
		remaining_distance = maxf(0.0, remaining_distance - accepted_distance)

	_emit_step_feedback(moved_distance)
	return moved_distance > 0.0


func _resolve_player_motion(motion: Vector2) -> Vector2:
	if _is_walkable_player_position(player_anchor.position + motion):
		return motion

	var horizontal_motion := Vector2(motion.x, 0.0)
	var vertical_motion := Vector2(0.0, motion.y)
	var horizontal_allowed := not horizontal_motion.is_zero_approx() and _is_walkable_player_position(
		player_anchor.position + horizontal_motion
	)
	var vertical_allowed := not vertical_motion.is_zero_approx() and _is_walkable_player_position(
		player_anchor.position + vertical_motion
	)
	if horizontal_allowed and vertical_allowed:
		slide_axis_preference = 1 - slide_axis_preference
		return horizontal_motion if slide_axis_preference == 0 else vertical_motion
	if horizontal_allowed:
		return horizontal_motion
	if vertical_allowed:
		return vertical_motion
	return Vector2.ZERO


func _is_walkable_player_position(world_position: Vector2) -> bool:
	var origin_cell := _world_to_cell(player_anchor.position)
	var cell := _world_to_cell(world_position)
	if not _is_walkable_player_footprint(world_position):
		return false
	if cell.x != origin_cell.x and cell.y != origin_cell.y:
		if not _is_walkable_player_cell(Vector2i(cell.x, origin_cell.y)):
			return false
		if not _is_walkable_player_cell(Vector2i(origin_cell.x, cell.y)):
			return false
	return true


func _is_walkable_player_footprint(world_position: Vector2) -> bool:
	var samples := [
		world_position,
		world_position + Vector2(PLAYER_FOOTPRINT_RADIUS.x, 0.0),
		world_position - Vector2(PLAYER_FOOTPRINT_RADIUS.x, 0.0),
		world_position + Vector2(0.0, PLAYER_FOOTPRINT_RADIUS.y),
		world_position - Vector2(0.0, PLAYER_FOOTPRINT_RADIUS.y),
		world_position + PLAYER_FOOTPRINT_RADIUS,
		world_position + Vector2(PLAYER_FOOTPRINT_RADIUS.x, -PLAYER_FOOTPRINT_RADIUS.y),
		world_position + Vector2(-PLAYER_FOOTPRINT_RADIUS.x, PLAYER_FOOTPRINT_RADIUS.y),
		world_position - PLAYER_FOOTPRINT_RADIUS,
	]
	for sample in samples:
		if not _is_walkable_player_cell(_world_to_cell(sample)):
			return false
	return true


func _is_walkable_player_cell(cell: Vector2i) -> bool:
	if not astar.is_in_boundsv(cell) or astar.is_point_solid(cell):
		return false
	return not capanga_active or cell != _world_to_cell(capanga_anchor.position)


func _move_player_along_path(delta: float) -> void:
	if not has_destination or delta <= 0.0:
		return

	if path_index >= movement_path.size():
		if player_repath_remaining > 0.0:
			return
		if not _rebuild_player_path():
			_wait_for_player_path()
			return

	var remaining_distance := PLAYER_SPEED * delta
	var moved_distance := 0.0
	var rebuilt_this_frame := false
	while remaining_distance > MOVEMENT_EPSILON and has_destination:
		if path_index >= movement_path.size():
			movement_path.clear()
			path_index = 0
			has_destination = false
			_update_status("Destino alcançado.")
			break

		if _player_path_requires_replan():
			if rebuilt_this_frame or not _rebuild_player_path():
				_wait_for_player_path()
				break
			rebuilt_this_frame = true
			_update_status("Rota ajustada ao movimento do Capanga.")
			continue

		var waypoint := movement_path[path_index]
		var distance_to_waypoint := player_anchor.position.distance_to(waypoint)
		if distance_to_waypoint <= 0.5:
			player_anchor.position = waypoint
			path_index += 1
			continue

		var step_length := minf(
			PLAYER_COLLISION_STEP,
			minf(remaining_distance, distance_to_waypoint)
		)
		var motion := player_anchor.position.direction_to(waypoint) * step_length
		var accepted_motion := _resolve_player_motion(motion)
		if accepted_motion.is_zero_approx():
			if rebuilt_this_frame or not _rebuild_player_path():
				_wait_for_player_path()
				break
			rebuilt_this_frame = true
			continue

		player_anchor.position += accepted_motion
		moved_distance += accepted_motion.length()
		remaining_distance = maxf(0.0, remaining_distance - accepted_motion.length())

	_emit_step_feedback(moved_distance)


func _emit_step_feedback(distance: float) -> void:
	if distance <= 0.0:
		return
	step_distance_accumulator += distance
	while step_distance_accumulator >= STEP_DISTANCE:
		step_distance_accumulator -= STEP_DISTANCE
		_emit_step_dust()
		_play_audio("step")


func _emit_step_dust() -> void:
	_restart_one_shot_particles(dust_particles)


func _emit_rifle_muzzle_flash() -> void:
	if rifle_muzzle_flash == null:
		return
	_restart_one_shot_particles(rifle_muzzle_flash.get_node_or_null("Sparks") as CPUParticles2D)
	_restart_one_shot_particles(rifle_muzzle_flash.get_node_or_null("Smoke") as CPUParticles2D)


func _restart_one_shot_particles(particles: CPUParticles2D) -> void:
	if particles == null:
		return
	particles.emitting = false
	particles.restart()
	particles.emitting = true


func _update_hit_flash_overlays() -> void:
	var player_row := PLAYER_KNIFE_ROW if current_weapon == Weapon.KNIFE else PLAYER_RIFLE_ROW
	_update_hit_flash_overlay(
		player_hit_flash,
		player_row,
		player_animation_state,
		player_animation_frame,
		player_hit_flash_remaining
	)
	_update_hit_flash_overlay(
		capanga_hit_flash,
		CAPANGA_ATLAS_ROW,
		capanga_animation_state,
		capanga_animation_frame,
		capanga_hit_flash_remaining
	)


func _update_hit_flash_overlay(
	overlay: Sprite2D,
	atlas_row: int,
	animation_state: int,
	animation_frame: int,
	remaining: float
) -> void:
	if overlay == null:
		return
	overlay.texture = CHARACTER_ATLAS
	overlay.region_enabled = true
	overlay.region_rect = _character_sprite_region(atlas_row, animation_state, animation_frame)
	var intensity := clampf(remaining / HIT_FLASH_DURATION, 0.0, 1.0)
	overlay.visible = intensity > 0.0
	var flash_material := overlay.material as ShaderMaterial
	if flash_material != null:
		flash_material.set_shader_parameter("flash_modifier", intensity)


func _play_audio(sound_name: String) -> void:
	if is_inside_tree() and get_tree().root.has_node("AudioManager"):
		var mgr := get_tree().root.get_node("AudioManager")
		match sound_name:
			"shoot": mgr.call("play_shoot")
			"knife": mgr.call("play_knife")
			"step": mgr.call("play_step")
			"parry": mgr.call("play_parry")
			"hit": mgr.call("play_hit")
			"critical": mgr.call("play_critical")
			"lapada_seca": mgr.call("play_lapada_seca")
			"ui_click": mgr.call("play_ui_click")
			"ui_hover": mgr.call("play_ui_hover")
			"door": mgr.call("play_door_open")
			_: mgr.call("play_sfx", sound_name)


func _trigger_screenshake(amount: float) -> void:
	if is_inside_tree():
		ScreenShake.shake_camera(get_tree(), amount)


func _clamp_camera_position(target_position: Vector2, target_zoom: Vector2) -> Vector2:
	var safe_zoom := Vector2(
		maxf(absf(target_zoom.x), 0.001),
		maxf(absf(target_zoom.y), 0.001)
	)
	var half_view := get_viewport_rect().size * 0.5 / safe_zoom
	var bounds := _map_bounds()
	var minimum := bounds.position + half_view
	var maximum := bounds.end - half_view
	var result := target_position
	if minimum.x > maximum.x:
		result.x = bounds.get_center().x
	else:
		result.x = clampf(result.x, minimum.x, maximum.x)
	if minimum.y > maximum.y:
		result.y = bounds.get_center().y
	else:
		result.y = clampf(result.y, minimum.y, maximum.y)
	return result


func _toggle_overview() -> void:
	overview_enabled = not overview_enabled
	camera_transitioning = true
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()

	var target_position := _clamp_camera_position(player_anchor.position, CLOSE_ZOOM)
	var target_zoom := CLOSE_ZOOM
	if overview_enabled:
		target_position = _map_bounds().get_center()
		var viewport_size := get_viewport_rect().size
		var bounds_size := _map_bounds().size + TILE_SIZE * 2.0
		var fit_zoom: float = minf(viewport_size.x / bounds_size.x, viewport_size.y / bounds_size.y)
		target_zoom = Vector2.ONE * minf(fit_zoom, 0.9)

	camera_tween = create_tween().set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "position", target_position, CAMERA_TRANSITION_TIME)
	camera_tween.tween_property(camera, "zoom", target_zoom, CAMERA_TRANSITION_TIME)
	camera_tween.finished.connect(_on_camera_transition_finished)
	_update_status("Visão geral ativada." if overview_enabled else "Câmera acompanhando o Cangaceiro.")


func _on_camera_transition_finished() -> void:
	camera_transitioning = false


func _nearest_walkable_cell(world_position: Vector2) -> Vector2i:
	var origin := _world_to_cell(world_position)
	if astar.is_in_boundsv(origin) and not astar.is_point_solid(origin):
		return origin

	for radius in range(1, maxi(MAP_SIZE.x, MAP_SIZE.y)):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var candidate := Vector2i(x, y)
				if astar.is_in_boundsv(candidate) and not astar.is_point_solid(candidate):
					return candidate
	return PLAYER_START


func _position_inside_cell(clicked_position: Vector2, cell: Vector2i) -> Vector2:
	var center := _cell_to_world(cell)
	var offset := clicked_position - center
	var diamond_distance: float = absf(offset.x) / HALF_TILE.x + absf(offset.y) / HALF_TILE.y
	if diamond_distance <= 0.78:
		return clicked_position
	return center


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		(cell.x - cell.y) * HALF_TILE.x,
		(cell.x + cell.y) * HALF_TILE.y
	)


func _world_to_cell(world_position: Vector2) -> Vector2i:
	var grid_x := world_position.x / TILE_SIZE.x + world_position.y / TILE_SIZE.y
	var grid_y := world_position.y / TILE_SIZE.y - world_position.x / TILE_SIZE.x
	return Vector2i(roundi(grid_x), roundi(grid_y))


func _tile_distance_between_positions(first: Vector2, second: Vector2) -> int:
	var first_cell := _world_to_cell(first)
	var second_cell := _world_to_cell(second)
	return absi(first_cell.x - second_cell.x) + absi(first_cell.y - second_cell.y)


func _map_bounds() -> Rect2:
	var corners: Array[Vector2] = [
		_cell_to_world(Vector2i(0, 0)),
		_cell_to_world(Vector2i(MAP_SIZE.x - 1, 0)),
		_cell_to_world(Vector2i(0, MAP_SIZE.y - 1)),
		_cell_to_world(MAP_SIZE - Vector2i.ONE),
	]
	var minimum: Vector2 = corners[0]
	var maximum: Vector2 = corners[0]
	for corner in corners:
		minimum.x = minf(minimum.x, corner.x)
		minimum.y = minf(minimum.y, corner.y)
		maximum.x = maxf(maximum.x, corner.x)
		maximum.y = maxf(maximum.y, corner.y)
	minimum -= HALF_TILE
	maximum += HALF_TILE
	return Rect2(minimum, maximum - minimum)


func _spawn_popup(
	text: String,
	world_position: Vector2,
	color: Color,
	font_size: int,
	bold: bool,
	duration: float = DAMAGE_NUMBER_DURATION
) -> void:
	combat_popups.append({
		"text": text,
		"position": world_position,
		"color": color,
		"font_size": font_size,
		"bold": bold,
		"duration": duration,
		"elapsed": 0.0,
	})


func _update_status(message: String) -> void:
	status_label.text = message


func _update_hud() -> void:
	var ratio := float(player_hp) / float(PLAYER_MAX_HP)
	health_fill.size.x = 240.0 * clampf(ratio, 0.0, 1.0)
	health_label.text = "VIDA  %d / %d" % [player_hp, PLAYER_MAX_HP]
	if is_reloading:
		weapon_label.text = "RECARREGANDO... %.1f s  •  PENTE %d/%d  •  RESERVA %d" % [
			reload_remaining,
			rifle_ammo,
			RIFLE_STARTING_AMMO,
			rifle_reserve_ammo,
		]
	elif current_weapon == Weapon.RIFLE:
		weapon_label.text = "RIFLE  •  PENTE %d/%d  •  RESERVA %d  •  [R] RECARREGAR" % [
			rifle_ammo,
			RIFLE_STARTING_AMMO,
			rifle_reserve_ammo,
		]
		if GameState.has_lapada_ready():
			weapon_label.text += "  •  [E] LAPADA PRONTA"
	else:
		weapon_label.text = "PEIXEIRA  •  Q PARA TROCAR"
	if stun_remaining > 0.0:
		weapon_label.text += "  •  ATORDOADO"
	_update_lapada_pips()
	realtime_hud.set_hud_state(
		player_hp,
		PLAYER_MAX_HP,
		100,
		100,
		"RIFLE" if current_weapon == Weapon.RIFLE else "PEIXEIRA",
		rifle_ammo,
		RIFLE_STARTING_AMMO,
		rifle_reserve_ammo,
		GameState.lapada_charges,
		GameState.has_lapada_ready(),
		stun_remaining > 0.0,
		is_reloading,
		reload_remaining,
		RIFLE_RELOAD_DURATION
	)


func _update_lapada_pips() -> void:
	if lapada_pip1 == null or lapada_pip2 == null or lapada_pip3 == null:
		return
	var charges: int = GameState.lapada_charges
	var charged_color := Color("44d6b3")
	var uncharged_color := Color("281d14")
	lapada_pip1.color = charged_color if charges >= 1 else uncharged_color
	lapada_pip2.color = charged_color if charges >= 2 else uncharged_color
	lapada_pip3.color = charged_color if charges >= 3 else uncharged_color


func _attempt_lapada_seca() -> bool:
	if not capanga_active or stun_remaining > 0.0 or scene_transitioning:
		return false
	if is_reloading:
		_update_status("Recarga ativa — Lapada bloqueada.")
		return false
	if current_weapon != Weapon.RIFLE:
		_update_status("Equipe o Rifle [Q] para usar a Lapada Seca.")
		return false
	if rifle_ammo <= 0:
		_update_status("Sem munição para a Lapada Seca.")
		return false
	if not GameState.has_lapada_ready():
		_update_status("Lapada Seca exige 3 críticos acumulados (%d/3)." % GameState.lapada_charges)
		return false
	if _tile_distance_between_positions(player_anchor.position, capanga_anchor.position) > RIFLE_RANGE:
		_update_status("Capanga fora do alcance da Lapada (máx. 5 tiles).")
		return false

	if not GameState.consume_lapada_charges():
		return false
	rifle_ammo -= 1
	_emit_rifle_muzzle_flash()
	_play_audio("lapada_seca")
	_trigger_screenshake(0.85)
	_spawn_popup("LAPADA SECA!", capanga_anchor.position, COLOR_MAGIC, 22, true, 1.2)
	_damage_capanga(ceili(capanga_hp), true, false)
	_update_status("LAPADA SECA — o Capanga foi eliminado.")
	_update_hud()
	return true


func _update_damage_border() -> void:
	if damage_border == null:
		return
	var alpha := 0.0
	if damage_border_remaining > 0.0:
		alpha = clampf(damage_border_remaining / DAMAGE_BORDER_DURATION, 0.0, 1.0)
	damage_border.modulate.a = alpha


func _draw() -> void:
	var bounds := _map_bounds().grow(256.0)
	draw_rect(bounds, COLOR_VOID, true)
	_draw_tiles()
	_draw_route_preview()
	_draw_destination()
	_draw_depth_sorted_world()
	_draw_combat_popups()


func _draw_tiles() -> void:
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)
			var is_road_cell := _is_road(cell)
			var fallback_color := COLOR_PATH_A if is_road_cell else COLOR_GROUND_A
			if (x + y) % 2 != 0:
				fallback_color = COLOR_PATH_B if is_road_cell else COLOR_GROUND_B
			var texture := PATH_TILESET if is_road_cell else GROUND_TILESET
			var variant := _terrain_variant_for_cell(cell)
			if cell == DUNGEON_ENTRY_CELL:
				texture = DUNGEON_TILESET
				variant = 3 if _is_dungeon_door_unlocked() else 0
			_draw_terrain_tile(center, texture, variant, fallback_color)


func _terrain_variant_for_cell(cell: Vector2i) -> int:
	if cell == PLAYER_START:
		return 3
	if cell in CAPANGA_PATROL_CELLS:
		return 2
	return posmod(cell.x * 3 + cell.y * 5, 4)


func _draw_terrain_tile(
	center: Vector2,
	texture: Texture2D,
	variant: int,
	fallback_color: Color
) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -HALF_TILE.y),
		center + Vector2(HALF_TILE.x, 0.0),
		center + Vector2(0.0, HALF_TILE.y),
		center + Vector2(-HALF_TILE.x, 0.0),
	])
	draw_colored_polygon(points, fallback_color)
	draw_texture_rect_region(
		texture,
		Rect2(center - HALF_TILE, TERRAIN_TILE_FRAME_SIZE),
		Rect2(
			Vector2(float(posmod(variant, 4)) * TERRAIN_TILE_FRAME_SIZE.x, 0.0),
			TERRAIN_TILE_FRAME_SIZE
		)
	)


func _draw_depth_sorted_world() -> void:
	var drawables: Array[Dictionary] = []
	for cell in ROAD_OBSTACLES:
		drawables.append({"kind": "road_prop", "cell": cell, "position": _cell_to_world(cell)})
	drawables.append({"kind": "door", "position": _cell_to_world(DUNGEON_DOOR_CELL)})
	if capanga_active:
		drawables.append({"kind": "capanga", "position": capanga_anchor.position})
	drawables.append({"kind": "player", "position": player_anchor.position})
	drawables.sort_custom(_sort_world_drawables_by_y)
	for drawable in drawables:
		match String(drawable["kind"]):
			"road_prop":
				_draw_road_obstacle(drawable["cell"])
			"door":
				_draw_dungeon_door()
			"capanga":
				_draw_capanga()
			"player":
				_draw_player()


func _sort_world_drawables_by_y(first: Dictionary, second: Dictionary) -> bool:
	var first_position: Vector2 = first["position"]
	var second_position: Vector2 = second["position"]
	if not is_equal_approx(first_position.y, second_position.y):
		return first_position.y < second_position.y
	return first_position.x < second_position.x


func _road_obstacle_variant(cell: Vector2i) -> int:
	if cell == START_LANDMARK_CELL:
		return 3
	if cell == COMBAT_LANDMARK_CELL:
		return 2
	if cell == Vector2i(5, 9):
		return 1
	return 0


func _draw_road_obstacle(cell: Vector2i) -> void:
	var center := _cell_to_world(cell)
	if cell == DUNGEON_LANDMARK_CELL:
		_draw_environment_prop(TAIPA_TILESET, center, 3, TAIPA_FOOT_ANCHOR)
		return
	_draw_environment_prop(VEGETATION_TILESET, center, _road_obstacle_variant(cell))


func _draw_environment_prop(
	texture: Texture2D,
	foot_position: Vector2,
	variant: int,
	foot_anchor: Vector2 = VEGETATION_FOOT_ANCHOR
) -> void:
	draw_texture_rect_region(
		texture,
		Rect2(foot_position - foot_anchor, ENVIRONMENT_PROP_FRAME_SIZE),
		Rect2(
			Vector2(float(posmod(variant, 4)) * ENVIRONMENT_PROP_FRAME_SIZE.x, 0.0),
			ENVIRONMENT_PROP_FRAME_SIZE
		)
	)


func _draw_dungeon_door() -> void:
	var position := _cell_to_world(DUNGEON_DOOR_CELL)
	var unlocked := _is_dungeon_door_unlocked()
	var door_color := COLOR_DOOR_OPEN if unlocked else COLOR_DOOR_LOCKED
	draw_rect(Rect2(position + Vector2(-19.0, -38.0), Vector2(38.0, 39.0)), COLOR_DOOR_FRAME, true)
	draw_rect(Rect2(position + Vector2(-14.0, -31.0), Vector2(28.0, 32.0)), door_color, true)
	draw_line(position + Vector2(-14.0, -31.0), position + Vector2(0.0, -42.0), COLOR_DOOR_FRAME, 5.0)
	draw_line(position + Vector2(0.0, -42.0), position + Vector2(14.0, -31.0), COLOR_DOOR_FRAME, 5.0)
	if unlocked:
		draw_circle(position + Vector2(8.0, -15.0), 2.0, COLOR_TEXT)
	else:
		draw_rect(Rect2(position + Vector2(-5.0, -18.0), Vector2(10.0, 9.0)), COLOR_LOCK, true)
		draw_arc(position + Vector2(0.0, -18.0), 5.0, PI, TAU, 12, COLOR_LOCK, 2.0)


func _draw_route_preview() -> void:
	if path_index >= movement_path.size():
		return
	var route_points := PackedVector2Array([player_anchor.position])
	for index in range(path_index, movement_path.size()):
		route_points.append(movement_path[index])
	if route_points.size() >= 2:
		draw_polyline(route_points, COLOR_ROUTE, 2.0, true)


func _draw_destination() -> void:
	if not has_destination:
		return
	draw_circle(destination_marker, 9.0, Color(0.27, 0.84, 0.70, 0.16))
	draw_arc(destination_marker, 9.0, 0.0, TAU, 24, COLOR_MAGIC, 2.0, true)


func _character_draw_rect(position: Vector2) -> Rect2:
	return Rect2(position - CHARACTER_FOOT_ANCHOR, CHARACTER_FRAME_SIZE)


func _character_sprite_region(row: int, animation_state: int, animation_frame: int) -> Rect2:
	var first_column := WALK_FIRST_COLUMN if animation_state == ANIMATION_WALK else IDLE_FIRST_COLUMN
	var frame_count := WALK_FRAME_COUNT if animation_state == ANIMATION_WALK else IDLE_FRAME_COUNT
	var normalized_frame := posmod(animation_frame, frame_count)
	return Rect2(
		float(first_column + normalized_frame) * CHARACTER_FRAME_SIZE.x,
		float(row) * CHARACTER_FRAME_SIZE.y,
		CHARACTER_FRAME_SIZE.x,
		CHARACTER_FRAME_SIZE.y
	)


func _draw_capanga() -> void:
	if not capanga_active:
		return
	var position := capanga_anchor.position
	draw_circle(position + Vector2(0.0, 7.0), 10.0, Color(0.08, 0.05, 0.03, 0.35))
	draw_texture_rect_region(
		CHARACTER_ATLAS,
		_character_draw_rect(position),
		_character_sprite_region(CAPANGA_ATLAS_ROW, capanga_animation_state, capanga_animation_frame),
		Color.WHITE
	)

	var health_rect := Rect2(position + Vector2(-18.0, -58.0), Vector2(36.0, 5.0))
	draw_rect(health_rect, COLOR_HEALTH_BACKGROUND, true)
	var health_width := health_rect.size.x * capanga_hp / CAPANGA_MAX_HP
	draw_rect(Rect2(health_rect.position, Vector2(health_width, health_rect.size.y)), COLOR_ENEMY_HEALTH, true)
	draw_rect(health_rect, COLOR_VOID, false, 1.0)


func _draw_player() -> void:
	var position := player_anchor.position
	draw_circle(position + Vector2(0.0, 7.0), 9.0, Color(0.08, 0.05, 0.03, 0.35))
	var player_row := PLAYER_KNIFE_ROW if current_weapon == Weapon.KNIFE else PLAYER_RIFLE_ROW
	draw_texture_rect_region(
		CHARACTER_ATLAS,
		_character_draw_rect(position),
		_character_sprite_region(player_row, player_animation_state, player_animation_frame),
		Color.WHITE
	)
	if heavy_warning_active:
		var font := ThemeDB.fallback_font
		draw_string(font, position + Vector2(-20.0, -58.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 40.0, 28, COLOR_ALERT)


func _draw_combat_popups() -> void:
	var font := ThemeDB.fallback_font
	for popup in combat_popups:
		var duration := float(popup["duration"])
		var progress := clampf(float(popup["elapsed"]) / duration, 0.0, 1.0)
		var popup_position: Vector2 = popup["position"] + Vector2(-40.0, -60.0 - progress * 24.0)
		var popup_color: Color = popup["color"]
		popup_color.a = 1.0 - progress
		var popup_text := str(popup["text"])
		var popup_size := int(popup["font_size"])
		if bool(popup["bold"]):
			for offset in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0)]:
				draw_string(font, popup_position + offset, popup_text, HORIZONTAL_ALIGNMENT_CENTER, 80.0, popup_size, popup_color)
		draw_string(font, popup_position, popup_text, HORIZONTAL_ALIGNMENT_CENTER, 80.0, popup_size, popup_color)
