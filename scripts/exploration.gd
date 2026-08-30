extends Node2D

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
const PLAYER_MAX_HP := 100
const PLAYER_RESPAWN_HP := 40
const CLOSE_ZOOM := Vector2(1.45, 1.45)
const CAMERA_FOLLOW_SPEED := 8.0
const CAMERA_TRANSITION_TIME := 0.28
const FADE_DURATION := 0.5
const DUNGEON_SCENE := "res://scenes/dungeon.tscn"
const CHARACTER_ATLAS: Texture2D = preload("res://assets/art/characters/animations/personagens_se_idle4_walk6_64px_16c.png")
const CHARACTER_FRAME_SIZE := Vector2(64.0, 64.0)
const CHARACTER_FOOT_ANCHOR := Vector2(32.0, 60.0)
const CHARACTER_ATLAS_COLUMNS := 10
const CHARACTER_ATLAS_ROWS := 2
const PLAYER_ATLAS_ROW := 0
const CAPANGA_ATLAS_ROW := 1
const ANIMATION_IDLE := 0
const ANIMATION_WALK := 1
const IDLE_FIRST_COLUMN := 0
const IDLE_FRAME_COUNT := 4
const IDLE_FPS := 4.0
const WALK_FIRST_COLUMN := 4
const WALK_FRAME_COUNT := 6
const WALK_FPS := 10.0

const RIFLE_STARTING_AMMO := 5
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

const COLOR_VOID := Color("17120d")
const COLOR_GROUND_A := Color("a97945")
const COLOR_GROUND_B := Color("9b693d")
const COLOR_PATH_A := Color("c49a61")
const COLOR_PATH_B := Color("b98d55")
const COLOR_TILE_LINE := Color("604027")
const COLOR_CLIFF := Color("563620")
const COLOR_ROCK := Color("5d5547")
const COLOR_ROCK_LIGHT := Color("837966")
const COLOR_CACTUS := Color("42643d")
const COLOR_CACTUS_LIGHT := Color("668656")
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
@onready var status_label: Label = $Interface/TopPanel/Status
@onready var version_label: Label = $Interface/Version
@onready var health_fill: ColorRect = $Interface/CombatHUD/HealthBack/HealthFill
@onready var health_label: Label = $Interface/CombatHUD/HealthBack/HealthLabel
@onready var weapon_label: Label = $Interface/CombatHUD/WeaponLabel
@onready var lapada_pip1: ColorRect = $Interface/CombatHUD/LapadaContainer/Pip1
@onready var lapada_pip2: ColorRect = $Interface/CombatHUD/LapadaContainer/Pip2
@onready var lapada_pip3: ColorRect = $Interface/CombatHUD/LapadaContainer/Pip3
@onready var lapada_label: Label = $Interface/CombatHUD/LapadaContainer/LapadaLabel
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

var player_hp := PLAYER_MAX_HP
var rifle_ammo := RIFLE_STARTING_AMMO
var current_weapon := Weapon.RIFLE
var player_attack_cooldown := 0.0
var weapon_switch_cooldown := 0.0
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
const AIM_DURATION := 1.0
var is_aiming_lapada := false
var aim_timer := 0.0
var combat_popups: Array[Dictionary] = []
var dungeon_prompt_visible := false
var door_contact_latched := false
var scene_transitioning := false


func _ready() -> void:
	_setup_pathfinding()
	var start_position := _cell_to_world(PLAYER_START)
	var returned_from_combat: bool = GameState.returning_from_combat
	var returned_from_dungeon: bool = GameState.returning_from_dungeon
	var returned_to_exploration := returned_from_combat or returned_from_dungeon
	player_hp = clampi(GameState.player_hp, 0, PLAYER_MAX_HP)
	rifle_ammo = maxi(0, GameState.rifle_ammo)
	current_weapon = Weapon.KNIFE if GameState.current_weapon == Weapon.KNIFE else Weapon.RIFLE
	player_anchor.position = GameState.consume_return_position(start_position)
	capanga_anchor.position = _cell_to_world(CAPANGA_PATROL_CELLS[0])
	capanga_active = not GameState.is_encounter_defeated(CAPANGA_ID)
	door_contact_latched = returned_from_dungeon
	camera.position = player_anchor.position
	camera.zoom = CLOSE_ZOOM
	version_label.text = str(ProjectSettings.get_setting("application/config/version", "V.0.0.0"))
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

	if capanga_active:
		_update_status("Clique para caminhar — o Capanga patrulha mais adiante.")
	else:
		_update_status("Capanga derrotado — a porta da masmorra está liberada.")
	_update_hud()
	_update_damage_border()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if dungeon_prompt_visible or scene_transitioning:
		return

	_advance_realtime(delta)

	if not overview_enabled and not camera_transitioning:
		var follow_weight := 1.0 - exp(-CAMERA_FOLLOW_SPEED * delta)
		camera.position = camera.position.lerp(player_anchor.position, follow_weight)


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
	queue_redraw()


func _advance_timers(delta: float) -> void:
	player_attack_cooldown = maxf(0.0, player_attack_cooldown - delta)
	weapon_switch_cooldown = maxf(0.0, weapon_switch_cooldown - delta)
	stun_remaining = maxf(0.0, stun_remaining - delta)
	damage_border_remaining = maxf(0.0, damage_border_remaining - delta)
	player_hit_flash_remaining = maxf(0.0, player_hit_flash_remaining - delta)
	capanga_hit_flash_remaining = maxf(0.0, capanga_hit_flash_remaining - delta)
	_update_damage_border()

	if is_aiming_lapada:
		aim_timer = maxf(0.0, aim_timer - delta)
		if aim_timer <= 0.0:
			_fire_lapada_seca()

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
			_start_aiming_lapada()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_SPACE:
			_attempt_parry()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_aiming_lapada:
				_cancel_aiming_lapada("Mira cancelada pelo clique.")
			elif stun_remaining > 0.0:
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


func _attempt_parry() -> bool:
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
	if not capanga_active or stun_remaining > 0.0 or player_attack_cooldown > 0.0 or is_aiming_lapada:
		return false

	var attack_range := RIFLE_RANGE if current_weapon == Weapon.RIFLE else KNIFE_RANGE
	if _tile_distance_between_positions(player_anchor.position, capanga_anchor.position) > attack_range:
		return false
	if current_weapon == Weapon.RIFLE and rifle_ammo <= 0:
		if status_label.text != "SEM MUNIÇÃO — pressione Q para usar a Peixeira.":
			_update_status("SEM MUNIÇÃO — pressione Q para usar a Peixeira.")
		return false

	var attack_interval := RIFLE_INTERVAL if current_weapon == Weapon.RIFLE else KNIFE_INTERVAL
	player_attack_cooldown = attack_interval
	if current_weapon == Weapon.RIFLE:
		rifle_ammo -= 1
		_play_audio("shoot")
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
			_update_lapada_pips()
	else:
		damage = KNIFE_CRITICAL_DAMAGE if critical else KNIFE_DAMAGE

	_damage_capanga(damage, critical)
	return true


func _damage_capanga(amount: int, critical: bool) -> void:
	capanga_hp = maxf(0.0, capanga_hp - float(amount))
	capanga_hit_flash_remaining = 0.12
	if critical:
		_play_audio("critical")
		_trigger_screenshake(0.5)
	else:
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
	if is_aiming_lapada:
		_cancel_aiming_lapada("Mira interrompida pelo dano recebido.")
	player_hp = maxi(0, player_hp - amount)
	damage_border_remaining = DAMAGE_BORDER_DURATION
	player_hit_flash_remaining = 0.12
	_play_audio("hit")
	_trigger_screenshake(0.35)
	_spawn_popup(str(amount), player_anchor.position, COLOR_PLAYER_DAMAGE, 16, true)
	_update_damage_border()
	if player_hp <= 0:
		_handle_player_defeat()
		return true
	return false


func _handle_player_defeat() -> void:
	player_hp = PLAYER_RESPAWN_HP
	player_anchor.position = _cell_to_world(PLAYER_START)
	movement_path.clear()
	path_index = 0
	has_destination = false
	is_aiming_lapada = false
	aim_timer = 0.0
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

	var start_cell := _nearest_walkable_cell(player_anchor.position)
	var capanga_cell := _world_to_cell(capanga_anchor.position)
	var block_capanga := capanga_active and astar.is_in_boundsv(capanga_cell)
	if block_capanga:
		astar.set_point_solid(capanga_cell, true)
	var id_path := astar.get_id_path(start_cell, target_cell)
	if block_capanga:
		astar.set_point_solid(capanga_cell, false)
	if id_path.is_empty():
		_update_status("Não há caminho até esse ponto.")
		return

	var new_path := PackedVector2Array()
	for index in range(1, id_path.size()):
		new_path.append(_cell_to_world(id_path[index]))

	var final_position := _position_inside_cell(clicked_world_position, target_cell)
	if new_path.is_empty():
		new_path.append(final_position)
	else:
		new_path[new_path.size() - 1] = final_position

	movement_path = new_path
	path_index = 0
	destination_marker = final_position
	has_destination = true
	_update_status("Caminhando — ataques automáticos não interrompem o movimento.")


func _is_dungeon_door_click(world_position: Vector2) -> bool:
	var door_position := _cell_to_world(DUNGEON_DOOR_CELL)
	return Rect2(door_position + Vector2(-24.0, -46.0), Vector2(48.0, 50.0)).has_point(world_position)


func _move_player(delta: float) -> void:
	if path_index >= movement_path.size():
		return

	var waypoint := movement_path[path_index]
	player_anchor.position = player_anchor.position.move_toward(waypoint, PLAYER_SPEED * delta)
	_emit_step_dust()
	if player_anchor.position.distance_to(waypoint) <= 0.5:
		player_anchor.position = waypoint
		path_index += 1
		if path_index >= movement_path.size():
			movement_path.clear()
			path_index = 0
			has_destination = false
			_update_status("Destino alcançado.")


func _emit_step_dust() -> void:
	if player_anchor != null:
		var dust := player_anchor.get_node_or_null("DustParticles") as CPUParticles2D
		if dust != null and not dust.emitting:
			dust.restart()


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
			"ui_click": mgr.call("play_ui_click")
			"ui_hover": mgr.call("play_ui_hover")
			"door": mgr.call("play_door_open")
			_: mgr.call("play_sfx", sound_name)


func _trigger_screenshake(amount: float) -> void:
	if is_inside_tree():
		ScreenShake.shake_camera(get_tree(), amount)


func _toggle_overview() -> void:
	overview_enabled = not overview_enabled
	camera_transitioning = true
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()

	var target_position := player_anchor.position
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
	if is_aiming_lapada:
		weapon_label.text = "MIRANDO LAPADA SECA... %.1f s  •  NÃO SE MOVA" % aim_timer
	elif current_weapon == Weapon.RIFLE:
		weapon_label.text = "RIFLE  •  BALAS %d / %d  •  Q PARA TROCAR" % [rifle_ammo, RIFLE_STARTING_AMMO]
		if GameState.has_lapada_ready():
			weapon_label.text += "  •  [E] LAPADA PRONTA"
	else:
		weapon_label.text = "PEIXEIRA  •  Q PARA TROCAR"
	if stun_remaining > 0.0:
		weapon_label.text += "  •  ATORDOADO"

	_update_lapada_pips()


func _update_lapada_pips() -> void:
	if lapada_pip1 == null or lapada_pip2 == null or lapada_pip3 == null:
		return
	var charges: int = GameState.lapada_charges
	var charged_color := Color(0.267, 0.839, 0.702, 1.0)
	var uncharged_color := Color(0.157, 0.114, 0.078, 1.0)
	lapada_pip1.color = charged_color if charges >= 1 else uncharged_color
	lapada_pip2.color = charged_color if charges >= 2 else uncharged_color
	lapada_pip3.color = charged_color if charges >= 3 else uncharged_color


func _start_aiming_lapada() -> bool:
	if not capanga_active or stun_remaining > 0.0 or scene_transitioning or is_aiming_lapada:
		return false
	if current_weapon != Weapon.RIFLE:
		_update_status("Equipe o Rifle [Q] para usar a Lapada Seca.")
		return false
	if rifle_ammo <= 0:
		_update_status("Sem munição para a Lapada Seca.")
		return false
	if not GameState.has_lapada_ready():
		_update_status("Lapada Seca exige 3 acertos críticos acumulados (%d/3)." % GameState.lapada_charges)
		return false
	var attack_range := RIFLE_RANGE
	if _tile_distance_between_positions(player_anchor.position, capanga_anchor.position) > attack_range:
		_update_status("Capanga fora do alcance (máx. 5 tiles) para mirar.")
		return false

	movement_path.clear()
	path_index = 0
	has_destination = false
	is_aiming_lapada = true
	aim_timer = AIM_DURATION
	_reset_character_animations_to_idle()
	_play_audio("ui_hover")
	_update_status("MIRANDO LAPADA SECA... NÃO SE MOVA!")
	_update_hud()
	return true


func _cancel_aiming_lapada(reason: String) -> void:
	if not is_aiming_lapada:
		return
	is_aiming_lapada = false
	aim_timer = 0.0
	_update_status(reason)
	_update_hud()


func _fire_lapada_seca() -> bool:
	is_aiming_lapada = false
	aim_timer = 0.0
	if not capanga_active or rifle_ammo <= 0 or not GameState.has_lapada_ready():
		return false

	rifle_ammo -= 1
	GameState.consume_lapada_charges()
	_play_audio("lapada_seca")
	_trigger_screenshake(0.85)

	_spawn_popup("LAPADA SECA!", capanga_anchor.position, Color("44d6b3"), 22, true, 1.2)
	_damage_capanga(int(capanga_hp) + 100, true)
	_update_status("LAPADA SECA DISPARADA! Dano fatal instantâneo.")
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
	_draw_dungeon_door()
	_draw_route_preview()
	_draw_destination()
	_draw_capanga()
	_draw_player()
	_draw_combat_popups()


func _draw_tiles() -> void:
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)
			var is_road_cell := _is_road(cell)
			var color: Color
			if is_road_cell:
				color = COLOR_PATH_A if (x + y) % 2 == 0 else COLOR_PATH_B
			else:
				color = COLOR_GROUND_A if (x + y) % 2 == 0 else COLOR_GROUND_B
			_draw_diamond(center, color)
			if not is_road_cell:
				_draw_cliff_mark(center)
			elif ROAD_OBSTACLES.has(cell):
				_draw_road_obstacle(center, (x + y) % 2 == 0)


func _draw_diamond(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -HALF_TILE.y),
		center + Vector2(HALF_TILE.x, 0.0),
		center + Vector2(0.0, HALF_TILE.y),
		center + Vector2(-HALF_TILE.x, 0.0),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), COLOR_TILE_LINE, 1.0)


func _draw_cliff_mark(center: Vector2) -> void:
	if int(center.x + center.y) % 3 != 0:
		return
	draw_line(center + Vector2(-9.0, 2.0), center + Vector2(-2.0, 6.0), COLOR_CLIFF, 2.0)
	draw_line(center + Vector2(2.0, 6.0), center + Vector2(9.0, 2.0), COLOR_CLIFF, 2.0)


func _draw_road_obstacle(center: Vector2, rock: bool) -> void:
	if rock:
		draw_rect(Rect2(center + Vector2(-9.0, -12.0), Vector2(18.0, 17.0)), COLOR_ROCK, true)
		draw_rect(Rect2(center + Vector2(-7.0, -10.0), Vector2(11.0, 4.0)), COLOR_ROCK_LIGHT, true)
	else:
		draw_rect(Rect2(center + Vector2(-3.0, -15.0), Vector2(6.0, 19.0)), COLOR_CACTUS, true)
		draw_rect(Rect2(center + Vector2(-8.0, -9.0), Vector2(6.0, 4.0)), COLOR_CACTUS, true)
		draw_rect(Rect2(center + Vector2(3.0, -5.0), Vector2(6.0, 4.0)), COLOR_CACTUS_LIGHT, true)


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
	var capanga_modulate := Color.WHITE
	if capanga_hit_flash_remaining > 0.0:
		var flash_ratio := clampf(capanga_hit_flash_remaining / 0.12, 0.0, 1.0)
		capanga_modulate = Color.WHITE.lerp(Color(5.0, 5.0, 5.0, 1.0), flash_ratio)
	draw_texture_rect_region(
		CHARACTER_ATLAS,
		_character_draw_rect(position),
		_character_sprite_region(CAPANGA_ATLAS_ROW, capanga_animation_state, capanga_animation_frame),
		capanga_modulate
	)

	var health_rect := Rect2(position + Vector2(-18.0, -58.0), Vector2(36.0, 5.0))
	draw_rect(health_rect, COLOR_HEALTH_BACKGROUND, true)
	var health_width := health_rect.size.x * capanga_hp / CAPANGA_MAX_HP
	draw_rect(Rect2(health_rect.position, Vector2(health_width, health_rect.size.y)), COLOR_ENEMY_HEALTH, true)
	draw_rect(health_rect, COLOR_VOID, false, 1.0)


func _draw_player() -> void:
	var position := player_anchor.position
	draw_circle(position + Vector2(0.0, 7.0), 9.0, Color(0.08, 0.05, 0.03, 0.35))
	var player_modulate := Color.WHITE
	if player_hit_flash_remaining > 0.0:
		var flash_ratio := clampf(player_hit_flash_remaining / 0.12, 0.0, 1.0)
		player_modulate = Color.WHITE.lerp(Color(5.0, 5.0, 5.0, 1.0), flash_ratio)
	draw_texture_rect_region(
		CHARACTER_ATLAS,
		_character_draw_rect(position),
		_character_sprite_region(PLAYER_ATLAS_ROW, player_animation_state, player_animation_frame),
		player_modulate
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
