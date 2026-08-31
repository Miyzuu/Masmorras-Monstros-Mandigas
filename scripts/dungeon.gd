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
const PLAYER_COLLISION_STEP := 4.0
const PLAYER_MAX_HP := 100
const CLOSE_ZOOM := Vector2(1.45, 1.45)
const CAMERA_FOLLOW_SPEED := 8.0
const CAMERA_TRANSITION_TIME := 0.28
const FADE_DURATION := 0.5
const EXPLORATION_SCENE := "res://scenes/exploration.tscn"
const DUNGEON_SCENE := "res://scenes/dungeon.tscn"
const CHARACTER_ATLAS: Texture2D = preload("res://assets/art/characters/animations/personagens_completo_se_animacoes_640x256_16c.png")
const CHARACTER_FRAME_SIZE := Vector2(64.0, 64.0)
const CHARACTER_FOOT_ANCHOR := Vector2(32.0, 60.0)
const CHARACTER_ATLAS_COLUMNS := 10
const CHARACTER_ATLAS_ROWS := 4
const PLAYER_RIFLE_ROW := 0
const CAPANGA_ATLAS_ROW := 1
const PLAYER_KNIFE_ROW := 2
const ANIMATION_IDLE := 0
const ANIMATION_WALK := 1
const IDLE_FIRST_COLUMN := 0
const IDLE_FRAME_COUNT := 4
const IDLE_FPS := 4.0
const WALK_FIRST_COLUMN := 4
const WALK_FRAME_COUNT := 6
const WALK_FPS := 10.0
const STEP_DISTANCE := 42.0

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

const LOBO_MAX_HP := 70.0
const LOBO_CHASE_SPEED := 220.0
const LOBO_ATTACK_INTERVAL := 0.8
const LOBO_BASIC_DAMAGE := 10

const FAILED_PARRY_STUN := 0.7
const DAMAGE_NUMBER_DURATION := 0.8
const PARRY_TEXT_DURATION := 0.5
const DAMAGE_BORDER_DURATION := 0.15
const HIT_FLASH_DURATION := 0.12

const PLAYER_START := Vector2i(2, 10)
const EXIT_DOOR_CELL := Vector2i(0, 10)
const EXIT_INTERACTION_CELL := Vector2i(1, 10)
const BLOCKED_STAIRS_CELL := Vector2i(14, 1)
const CAPANGA_PATROL_CELLS := [
	Vector2i(7, 7),
	Vector2i(11, 4),
]
const LOBO_PATROL_CELLS := [
	Vector2i(7, 7),
	Vector2i(10, 4),
]
const ROOM_TWO_ROCK_CELLS := [
	Vector2i(5, 8),
	Vector2i(5, 9),
	Vector2i(6, 9),
	Vector2i(8, 5),
	Vector2i(8, 6),
	Vector2i(9, 6),
	Vector2i(11, 2),
	Vector2i(11, 3),
	Vector2i(12, 3),
]

const COLOR_VOID := Color("0d0e12")
const COLOR_FLOOR_A := Color("6f675f")
const COLOR_FLOOR_B := Color("625b55")
const COLOR_WALL_A := Color("39383b")
const COLOR_WALL_B := Color("302f33")
const COLOR_TILE_LINE := Color("24252a")
const COLOR_WALL_EDGE := Color("8d8174")
const COLOR_DOOR_FRAME := Color("211d1b")
const COLOR_DOOR := Color("684a36")
const COLOR_STAIRS := Color("292b31")
const COLOR_STAIRS_EDGE := Color("a18f7b")
const COLOR_SEAL := Color("ab3c77")
const COLOR_ROUTE := Color(0.27, 0.84, 0.70, 0.45)
const COLOR_MAGIC := Color("44d6b3")
const COLOR_NORMAL_DAMAGE := Color("f2dfbd")
const COLOR_CRITICAL_DAMAGE := Color("df3328")
const COLOR_PLAYER_DAMAGE := Color("ef6a52")
const COLOR_HEALTH_BACKGROUND := Color("3b211b")
const COLOR_ENEMY_HEALTH := Color("d15a3f")
const COLOR_ALERT := Color("ed3128")
const COLOR_ROCK_TOP := Color("514d4b")
const COLOR_ROCK_SIDE := Color("302e30")
const COLOR_LOBO_BODY := Color("a75f38")
const COLOR_LOBO_DARK := Color("3c2924")

@onready var player_anchor: Node2D = $PlayerAnchor
@onready var camera: Camera2D = $Camera2D
@onready var dust_particles: CPUParticles2D = $PlayerAnchor/DustParticles
@onready var title_label: Label = $Interface/TopPanel/Title
@onready var status_label: Label = $Interface/TopPanel/Status
@onready var version_label: Label = $Interface/Version
@onready var health_fill: ColorRect = $Interface/StatusHUD/HealthBack/HealthFill
@onready var health_label: Label = $Interface/StatusHUD/HealthBack/HealthLabel
@onready var weapon_label: Label = $Interface/StatusHUD/WeaponLabel
@onready var realtime_hud: RealtimeHUD = $Interface/RealtimeHUD
@onready var exit_prompt: Control = $DialogLayer/ExitPrompt
@onready var exit_prompt_title: Label = $DialogLayer/ExitPrompt/Dialog/Title
@onready var exit_prompt_message: Label = $DialogLayer/ExitPrompt/Dialog/Message
@onready var exit_yes_button: Button = $DialogLayer/ExitPrompt/Dialog/YesButton
@onready var exit_no_button: Button = $DialogLayer/ExitPrompt/Dialog/NoButton
@onready var fade: ColorRect = $FadeLayer/Fade

var astar := AStarGrid2D.new()
var movement_path := PackedVector2Array()
var path_index := 0
var destination_marker := Vector2.ZERO
var has_destination := false
var step_distance_accumulator := 0.0
var player_animation_state := ANIMATION_IDLE
var player_animation_frame := 0
var player_animation_elapsed := 0.0
var capanga_anchor: Node2D
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

var exit_prompt_visible := false
var defeat_prompt_visible := false
var exit_contact_latched := false
var stairs_contact_latched := false
var scene_transitioning := false
var exit_request_source := ""
var dungeon_room_id: String:
	get:
		return GameState.get_current_dungeon_room_id()


func _ready() -> void:
	_refresh_room_title()
	capanga_anchor = Node2D.new()
	capanga_anchor.name = "RoomMobAnchor"
	add_child(capanga_anchor)
	_reset_room_enemy()
	_setup_pathfinding()
	player_anchor.position = _cell_to_world(PLAYER_START)
	camera.position = player_anchor.position
	camera.zoom = CLOSE_ZOOM
	version_label.text = str(ProjectSettings.get_setting("application/config/version", "V.0.0.0"))
	exit_prompt.visible = false
	_restore_exit_prompt_text()
	exit_yes_button.pressed.connect(_confirm_dungeon_exit)
	exit_no_button.pressed.connect(_cancel_dungeon_exit)
	scene_transitioning = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	fade.modulate.a = 1.0
	fade_tween = create_tween()
	fade_tween.tween_property(fade, "modulate:a", 0.0, FADE_DURATION)
	fade_tween.finished.connect(_finish_entry_fade, CONNECT_ONE_SHOT)
	if capanga_active:
		_update_status("%s — derrote o %s." % [_room_label(), _enemy_name()])
	else:
		_update_status("%s concluída — a escada está liberada." % _room_label())
	_update_hud()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if exit_prompt_visible or scene_transitioning:
		return

	_advance_realtime(delta)

	if not overview_enabled and not camera_transitioning:
		var follow_weight := 1.0 - exp(-CAMERA_FOLLOW_SPEED * delta)
		camera.position = camera.position.lerp(player_anchor.position, follow_weight)
	queue_redraw()


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
	if _check_exit_door_contact():
		_update_hud()
		queue_redraw()
		return
	_check_stairs_contact()

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


func _reset_player_animation_to_idle() -> void:
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

	if exit_prompt_visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if _handle_exit_prompt_key(event.keycode):
				get_viewport().set_input_as_handled()
				return
		if event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_request_dungeon_exit("Esc")
			get_viewport().set_input_as_handled()
			return
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


func _handle_exit_prompt_key(keycode: int) -> bool:
	if keycode == KEY_ENTER or keycode == KEY_KP_ENTER or keycode == KEY_SPACE:
		_confirm_dungeon_exit()
		return true
	if keycode == KEY_ESCAPE:
		_cancel_dungeon_exit()
		return true
	return false


func _check_exit_door_contact() -> bool:
	if not _is_initial_dungeon_room():
		exit_contact_latched = false
		return false
	var touching_exit := _world_to_cell(player_anchor.position) == EXIT_INTERACTION_CELL
	if not touching_exit:
		exit_contact_latched = false
		return false
	if exit_contact_latched:
		return false

	exit_contact_latched = true
	_request_dungeon_exit("porta")
	return true


func _check_stairs_contact() -> bool:
	var touching_stairs := _world_to_cell(player_anchor.position) == BLOCKED_STAIRS_CELL
	if not touching_stairs:
		stairs_contact_latched = false
		return false
	if stairs_contact_latched:
		return false

	stairs_contact_latched = true
	if capanga_active:
		_update_status("O selo da escada só quebra após derrotar o %s." % _enemy_name())
		return false
	if GameState.has_next_dungeon_room():
		return _advance_to_next_room()
	_update_status("%s concluída — próxima etapa ainda não implementada." % _room_label())
	return true


func _advance_to_next_room() -> bool:
	if scene_transitioning or capanga_active:
		return false
	if not GameState.advance_dungeon_room():
		_update_status("A próxima sala ainda não está disponível.")
		return false

	scene_transitioning = true
	movement_path.clear()
	path_index = 0
	has_destination = false
	is_reloading = false
	reload_remaining = 0.0
	_reset_player_animation_to_idle()
	_play_audio("door")
	_update_status("Descendo para %s..." % _room_label())
	_start_scene_transition(DUNGEON_SCENE)
	return true


func _request_dungeon_exit(source: String) -> void:
	if exit_prompt_visible or scene_transitioning:
		return
	defeat_prompt_visible = false
	_restore_exit_prompt_text()
	exit_request_source = source
	exit_prompt_visible = true
	exit_prompt.visible = true
	movement_path.clear()
	path_index = 0
	has_destination = false
	_play_audio("ui_hover")
	_reset_player_animation_to_idle()
	_update_status("Sair apagará todo o progresso feito dentro da masmorra.")
	exit_yes_button.grab_focus()


func _cancel_dungeon_exit() -> void:
	if not exit_prompt_visible or scene_transitioning:
		return
	if defeat_prompt_visible:
		_leave_dungeon_after_defeat()
		return
	exit_prompt_visible = false
	exit_prompt.visible = false
	_play_audio("ui_click")
	_update_status("Saída cancelada — a exploração da sala continua.")


func _prepare_dungeon_exit() -> void:
	GameState.leave_dungeon(player_hp, rifle_ammo, current_weapon)


func _confirm_dungeon_exit() -> void:
	if not exit_prompt_visible or scene_transitioning:
		return
	if defeat_prompt_visible:
		_restart_dungeon_after_defeat()
		return
	exit_prompt_visible = false
	exit_prompt.visible = false
	scene_transitioning = true
	_play_audio("door")
	_prepare_dungeon_exit()
	_start_scene_transition(EXPLORATION_SCENE)


func _show_defeat_prompt() -> void:
	exit_prompt_visible = true
	defeat_prompt_visible = true
	exit_prompt.visible = true
	exit_prompt_title.text = "DERROTA NA MASMORRA"
	exit_prompt_message.text = "Voltar reinicia a masmorra e restaura seus mobs.\nSair retorna ao mapa externo."
	exit_yes_button.text = "VOLTAR  [ENTER/ESPAÇO]"
	exit_no_button.text = "SAIR  [ESC]"
	movement_path.clear()
	path_index = 0
	has_destination = false
	_reset_player_animation_to_idle()
	exit_yes_button.grab_focus()


func _restore_exit_prompt_text() -> void:
	exit_prompt_title.text = "SAIR E PERDER O PROGRESSO?"
	exit_prompt_message.text = "Salas e inimigos serão reiniciados.\nVida e munição atuais serão preservadas."
	exit_yes_button.text = "SIM  [ENTER/ESPAÇO]"
	exit_no_button.text = "NÃO  [ESC]"


func _restart_dungeon_after_defeat() -> void:
	GameState.respawn_player()
	GameState.reset_dungeon_progress()
	exit_prompt_visible = false
	defeat_prompt_visible = false
	exit_prompt.visible = false
	_restore_exit_prompt_text()
	player_anchor.position = _cell_to_world(PLAYER_START)
	_refresh_room_title()
	_reset_room_enemy()
	_setup_pathfinding()
	stun_remaining = 0.0
	skip_next_player_attack = false
	player_attack_cooldown = 0.0
	is_reloading = false
	reload_remaining = 0.0
	combat_popups.clear()
	stairs_contact_latched = false
	_reset_player_animation_to_idle()
	_play_audio("ui_click")
	_update_status("Retorno à %s com 40%% de vida — derrote o %s novamente." % [_room_label(), _enemy_name()])
	_update_hud()
	queue_redraw()


func _leave_dungeon_after_defeat() -> void:
	GameState.respawn_player()
	exit_prompt_visible = false
	defeat_prompt_visible = false
	exit_prompt.visible = false
	scene_transitioning = true
	_play_audio("door")
	_prepare_dungeon_exit()
	_start_scene_transition(EXPLORATION_SCENE)


func _play_audio(sound_name: String) -> void:
	if is_inside_tree() and get_tree().root.has_node("AudioManager"):
		var mgr := get_tree().root.get_node("AudioManager")
		match sound_name:
			"shoot": mgr.call("play_shoot")
			"knife": mgr.call("play_knife")
			"parry": mgr.call("play_parry")
			"hit": mgr.call("play_hit")
			"critical": mgr.call("play_critical")
			"lapada_seca": mgr.call("play_lapada_seca")
			"ui_click": mgr.call("play_ui_click")
			"ui_hover": mgr.call("play_ui_hover")
			"door": mgr.call("play_door_open")
			"step": mgr.call("play_step")
			_: mgr.call("play_sfx", sound_name)


func _trigger_screenshake(amount: float) -> void:
	if is_inside_tree():
		ScreenShake.shake_camera(get_tree(), amount)


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
	if scene_transitioning or exit_prompt_visible:
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
		capanga_attack_cooldown = _enemy_attack_interval()
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

	player_attack_cooldown = RIFLE_INTERVAL if current_weapon == Weapon.RIFLE else KNIFE_INTERVAL
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
	else:
		damage = KNIFE_CRITICAL_DAMAGE if critical else KNIFE_DAMAGE

	_damage_capanga(damage, critical)
	return true


func _damage_capanga(amount: int, critical: bool, play_impact_audio: bool = true) -> void:
	if not capanga_active:
		return
	capanga_hp = maxf(0.0, capanga_hp - float(amount))
	capanga_hit_flash_remaining = HIT_FLASH_DURATION
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
	heavy_warning_remaining = 0.0
	GameState.mark_dungeon_room_cleared(dungeon_room_id)
	astar.set_point_solid(BLOCKED_STAIRS_CELL, false)
	stairs_contact_latched = false
	_update_status("%s derrotado — o selo que bloqueava a escada foi quebrado." % _enemy_name())
	_update_hud()
	queue_redraw()


func _damage_player(amount: int) -> bool:
	player_hp = maxi(0, player_hp - amount)
	damage_border_remaining = DAMAGE_BORDER_DURATION
	player_hit_flash_remaining = HIT_FLASH_DURATION
	_play_audio("hit")
	_trigger_screenshake(0.35)
	_spawn_popup(str(amount), player_anchor.position, COLOR_PLAYER_DAMAGE, 16, true)
	if player_hp <= 0:
		_handle_player_defeat()
		return true
	return false


func _handle_player_defeat() -> void:
	movement_path.clear()
	path_index = 0
	has_destination = false
	is_reloading = false
	reload_remaining = 0.0
	heavy_warning_active = false
	heavy_warning_remaining = 0.0
	_update_status("Derrota — escolha sair ou voltar do início.")
	_update_hud()
	_show_defeat_prompt()


func _advance_capanga_ai(delta: float) -> void:
	if not capanga_active or heavy_warning_active:
		return

	var distance := _tile_distance_between_positions(capanga_anchor.position, player_anchor.position)
	match capanga_state:
		EnemyState.PATROL:
			var regen_per_second := _enemy_regen_per_second()
			if regen_per_second > 0.0:
				capanga_hp = minf(_enemy_max_hp(), capanga_hp + regen_per_second * delta)
			if distance <= CAPANGA_DETECTION_RANGE:
				_set_capanga_state(EnemyState.CHASE)
				return
			_advance_capanga_patrol(delta)
		EnemyState.CHASE:
			if distance > CAPANGA_DISENGAGE_RANGE:
				capanga_return_target_index = _nearest_capanga_patrol_index()
				_set_capanga_state(EnemyState.RETURN)
				return
			if distance > CAPANGA_ATTACK_RANGE:
				_move_capanga_toward(_world_to_cell(player_anchor.position), _enemy_chase_speed(), delta)
		EnemyState.RETURN:
			var return_cell := _enemy_patrol_cell(capanga_return_target_index)
			_move_capanga_toward(return_cell, CAPANGA_PATROL_SPEED, delta)
			if capanga_anchor.position.distance_to(_cell_to_world(return_cell)) <= 1.0:
				capanga_anchor.position = _cell_to_world(return_cell)
				capanga_patrol_target_index = 1 - capanga_return_target_index
				_set_capanga_state(EnemyState.PATROL)


func _advance_capanga_patrol(delta: float) -> void:
	if capanga_patrol_pause_remaining > 0.0:
		capanga_patrol_pause_remaining = maxf(0.0, capanga_patrol_pause_remaining - delta)
		return

	var target_cell := _enemy_patrol_cell(capanga_patrol_target_index)
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
		capanga_attack_cooldown = _enemy_attack_interval()


func _advance_capanga_attack(delta: float) -> void:
	if not capanga_active or exit_prompt_visible:
		return
	var attack_interval := _enemy_attack_interval()

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
			capanga_attack_cooldown = attack_interval
		return

	if capanga_state != EnemyState.CHASE or not _capanga_can_attack_player():
		capanga_attack_cooldown = attack_interval
		return

	capanga_attack_cooldown = maxf(0.0, capanga_attack_cooldown - delta)
	if capanga_attack_cooldown > 0.0:
		return

	if not _enemy_has_heavy_attack():
		var lobo_damage := _enemy_basic_damage()
		var defeated := _damage_player(lobo_damage)
		capanga_attack_cooldown = attack_interval
		if not defeated:
			_update_status("%s atacou: %d de dano." % [_enemy_name(), lobo_damage])
		return

	if capanga_basic_attack_count < 3:
		var basic_damage := _enemy_basic_damage()
		var defeated := _damage_player(basic_damage)
		if not defeated:
			capanga_basic_attack_count += 1
			capanga_attack_cooldown = attack_interval
			_update_status("%s atacou: %d de dano." % [_enemy_name(), basic_damage])
	else:
		heavy_warning_active = true
		heavy_warning_remaining = CAPANGA_HEAVY_WARNING
		_update_status("Ataque pesado chegando — pressione Espaço!")


func _capanga_can_attack_player() -> bool:
	return _tile_distance_between_positions(capanga_anchor.position, player_anchor.position) <= CAPANGA_ATTACK_RANGE


func _nearest_capanga_patrol_index() -> int:
	var distance_a := capanga_anchor.position.distance_to(_cell_to_world(_enemy_patrol_cell(0)))
	var distance_b := capanga_anchor.position.distance_to(_cell_to_world(_enemy_patrol_cell(1)))
	return 0 if distance_a <= distance_b else 1


func _setup_pathfinding() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, MAP_SIZE)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			if _is_wall(cell):
				astar.set_point_solid(cell)
	astar.set_point_solid(BLOCKED_STAIRS_CELL, capanga_active)


func _is_wall(cell: Vector2i) -> bool:
	var boundary_wall := (
		cell.x == 0
		or cell.y == 0
		or cell.x == MAP_SIZE.x - 1
		or cell.y == MAP_SIZE.y - 1
	)
	if boundary_wall:
		return true
	return _is_lobo_room() and cell in ROOM_TWO_ROCK_CELLS
func _set_destination(clicked_world_position: Vector2) -> void:
	var target_cell := _world_to_cell(clicked_world_position)
	if _is_initial_dungeon_room() and (target_cell == EXIT_DOOR_CELL or _is_exit_door_click(clicked_world_position)):
		target_cell = EXIT_INTERACTION_CELL
	if not astar.is_in_boundsv(target_cell):
		_update_status("Destino fora da sala.")
		return
	if target_cell == BLOCKED_STAIRS_CELL and capanga_active:
		_update_status("A escada está selada — derrote o %s." % _enemy_name())
		return
	if astar.is_point_solid(target_cell):
		_update_status("A parede bloqueia esse caminho.")
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


func _is_exit_door_click(world_position: Vector2) -> bool:
	if not _is_initial_dungeon_room():
		return false
	var door_position := _cell_to_world(EXIT_DOOR_CELL)
	return Rect2(door_position + Vector2(-24.0, -40.0), Vector2(48.0, 44.0)).has_point(world_position)


func _is_initial_dungeon_room() -> bool:
	return dungeon_room_id == String(GameState.DUNGEON_ROOM_IDS[0])


func _is_lobo_room() -> bool:
	return dungeon_room_id == String(GameState.DUNGEON_ROOM_IDS[1])


func _enemy_name() -> String:
	return "Lobo-guará corrompido" if _is_lobo_room() else "Capanga"


func _enemy_max_hp() -> float:
	return LOBO_MAX_HP if _is_lobo_room() else CAPANGA_MAX_HP


func _enemy_chase_speed() -> float:
	return LOBO_CHASE_SPEED if _is_lobo_room() else CAPANGA_CHASE_SPEED


func _enemy_attack_interval() -> float:
	return LOBO_ATTACK_INTERVAL if _is_lobo_room() else CAPANGA_ATTACK_INTERVAL


func _enemy_basic_damage() -> int:
	return LOBO_BASIC_DAMAGE if _is_lobo_room() else CAPANGA_BASIC_DAMAGE


func _enemy_has_heavy_attack() -> bool:
	return not _is_lobo_room()


func _enemy_regen_per_second() -> float:
	return 0.0 if _is_lobo_room() else CAPANGA_REGEN_PER_SECOND


func _enemy_patrol_cell(index: int) -> Vector2i:
	var patrol_cells := LOBO_PATROL_CELLS if _is_lobo_room() else CAPANGA_PATROL_CELLS
	return patrol_cells[clampi(index, 0, patrol_cells.size() - 1)]


func _reset_room_enemy() -> void:
	capanga_anchor.position = _cell_to_world(_enemy_patrol_cell(0))
	capanga_active = not GameState.is_dungeon_room_cleared(dungeon_room_id)
	capanga_hp = _enemy_max_hp()
	capanga_state = EnemyState.PATROL
	capanga_patrol_target_index = 1
	capanga_return_target_index = 0
	capanga_path.clear()
	capanga_path_index = 0
	capanga_repath_remaining = 0.0
	capanga_patrol_pause_remaining = 0.0
	capanga_attack_cooldown = _enemy_attack_interval()
	capanga_basic_attack_count = 0
	heavy_warning_active = false
	heavy_warning_remaining = 0.0
	capanga_animation_state = ANIMATION_IDLE
	capanga_animation_frame = 0
	capanga_animation_elapsed = 0.0


func _refresh_room_title() -> void:
	title_label.text = "MASMORRA — %s" % _room_label().to_upper()


func _room_label() -> String:
	return "Sala %d/%d" % [
		GameState.get_current_dungeon_room_number(),
		GameState.get_implemented_dungeon_room_count(),
	]


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
	if had_click_destination:
		_update_status("Rota cancelada — movimentação por WASD ativada.")

	var direction := raw_input.normalized()
	var remaining_distance := PLAYER_SPEED * delta
	var moved_distance := 0.0
	while remaining_distance > 0.0:
		var step_length := minf(PLAYER_COLLISION_STEP, remaining_distance)
		var accepted_motion := _resolve_player_motion(direction * step_length)
		if accepted_motion.is_zero_approx():
			break
		player_anchor.position += accepted_motion
		var accepted_distance := accepted_motion.length()
		moved_distance += accepted_distance
		remaining_distance -= step_length

	_emit_step_feedback(moved_distance)
	return moved_distance > 0.0


func _resolve_player_motion(motion: Vector2) -> Vector2:
	if _is_walkable_player_position(player_anchor.position + motion):
		return motion

	var horizontal_motion := Vector2(motion.x, 0.0)
	if not horizontal_motion.is_zero_approx() and _is_walkable_player_position(
		player_anchor.position + horizontal_motion
	):
		return horizontal_motion

	var vertical_motion := Vector2(0.0, motion.y)
	if not vertical_motion.is_zero_approx() and _is_walkable_player_position(
		player_anchor.position + vertical_motion
	):
		return vertical_motion
	return Vector2.ZERO


func _is_walkable_player_position(world_position: Vector2) -> bool:
	var origin_cell := _world_to_cell(player_anchor.position)
	var cell := _world_to_cell(world_position)
	if not _is_walkable_player_cell(cell):
		return false
	if cell.x != origin_cell.x and cell.y != origin_cell.y:
		if not _is_walkable_player_cell(Vector2i(cell.x, origin_cell.y)):
			return false
		if not _is_walkable_player_cell(Vector2i(origin_cell.x, cell.y)):
			return false
	return true


func _is_walkable_player_cell(cell: Vector2i) -> bool:
	if not astar.is_in_boundsv(cell) or astar.is_point_solid(cell):
		return false
	return not capanga_active or cell != _world_to_cell(capanga_anchor.position)


func _move_player_along_path(delta: float) -> void:
	if path_index >= movement_path.size():
		return

	var waypoint := movement_path[path_index]
	var previous_position := player_anchor.position
	player_anchor.position = player_anchor.position.move_toward(waypoint, PLAYER_SPEED * delta)
	_emit_step_feedback(previous_position.distance_to(player_anchor.position))
	if player_anchor.position.distance_to(waypoint) <= 0.5:
		player_anchor.position = waypoint
		path_index += 1
		if path_index >= movement_path.size():
			movement_path.clear()
			path_index = 0
			has_destination = false
			_update_status("Destino alcançado.")


func _emit_step_feedback(distance: float) -> void:
	if distance <= 0.0:
		return
	step_distance_accumulator += distance
	while step_distance_accumulator >= STEP_DISTANCE:
		step_distance_accumulator -= STEP_DISTANCE
		_restart_one_shot_particles(dust_particles)
		_play_audio("step")


func _restart_one_shot_particles(particles: CPUParticles2D) -> void:
	if particles == null:
		return
	particles.emitting = false
	particles.restart()
	particles.emitting = true


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


func _tile_distance_between_positions(first: Vector2, second: Vector2) -> int:
	var first_cell := _world_to_cell(first)
	var second_cell := _world_to_cell(second)
	return absi(first_cell.x - second_cell.x) + absi(first_cell.y - second_cell.y)


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
		_update_status("%s fora do alcance da Lapada (máx. 5 tiles)." % _enemy_name())
		return false

	if not GameState.consume_lapada_charges():
		return false
	rifle_ammo -= 1
	_play_audio("lapada_seca")
	_trigger_screenshake(0.85)
	_spawn_popup("LAPADA SECA!", capanga_anchor.position, COLOR_MAGIC, 22, true, 1.2)
	_damage_capanga(ceili(capanga_hp), true, false)
	_update_status("LAPADA SECA — %s eliminado." % _enemy_name())
	_update_hud()
	return true


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
	if capanga_active:
		weapon_label.text += "  •  ESCADA SELADA"
	else:
		weapon_label.text += "  •  SALA LIMPA"
	weapon_label.text += "  •  %s" % _room_label().to_upper()
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


func _draw() -> void:
	draw_rect(_map_bounds().grow(256.0), COLOR_VOID, true)
	_draw_tiles()
	_draw_room_rocks()
	if _is_initial_dungeon_room():
		_draw_exit_door()
	_draw_blocked_stairs()
	_draw_route_preview()
	_draw_destination()
	if capanga_active and capanga_anchor.position.y <= player_anchor.position.y:
		_draw_capanga()
	_draw_player()
	if capanga_active and capanga_anchor.position.y > player_anchor.position.y:
		_draw_capanga()
	_draw_combat_popups()
	_draw_damage_border()


func _draw_tiles() -> void:
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)
			var color: Color
			if _is_wall(cell):
				color = COLOR_WALL_A if (x + y) % 2 == 0 else COLOR_WALL_B
			else:
				color = COLOR_FLOOR_A if (x + y) % 2 == 0 else COLOR_FLOOR_B
			_draw_diamond(center, color)
			if _is_wall(cell):
				draw_line(center + Vector2(-18.0, 0.0), center + Vector2(0.0, 9.0), COLOR_WALL_EDGE, 2.0)


func _draw_diamond(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -HALF_TILE.y),
		center + Vector2(HALF_TILE.x, 0.0),
		center + Vector2(0.0, HALF_TILE.y),
		center + Vector2(-HALF_TILE.x, 0.0),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), COLOR_TILE_LINE, 1.0)


func _draw_room_rocks() -> void:
	if not _is_lobo_room():
		return
	for rock_cell in ROOM_TWO_ROCK_CELLS:
		var position := _cell_to_world(rock_cell)
		var top := PackedVector2Array([
			position + Vector2(-19.0, -7.0),
			position + Vector2(0.0, -17.0),
			position + Vector2(19.0, -7.0),
			position + Vector2(0.0, 3.0),
		])
		var left_side := PackedVector2Array([
			top[0],
			top[3],
			position + Vector2(0.0, 11.0),
			position + Vector2(-19.0, 1.0),
		])
		var right_side := PackedVector2Array([
			top[3],
			top[2],
			position + Vector2(19.0, 1.0),
			position + Vector2(0.0, 11.0),
		])
		draw_colored_polygon(left_side, COLOR_ROCK_SIDE.darkened(0.12))
		draw_colored_polygon(right_side, COLOR_ROCK_SIDE)
		draw_colored_polygon(top, COLOR_ROCK_TOP)
		draw_polyline(PackedVector2Array([top[0], top[1], top[2], top[3], top[0]]), COLOR_WALL_EDGE, 1.0)


func _draw_exit_door() -> void:
	var position := _cell_to_world(EXIT_DOOR_CELL)
	draw_rect(Rect2(position + Vector2(-18.0, -34.0), Vector2(36.0, 35.0)), COLOR_DOOR_FRAME, true)
	draw_rect(Rect2(position + Vector2(-13.0, -27.0), Vector2(26.0, 28.0)), COLOR_DOOR, true)
	draw_circle(position + Vector2(7.0, -13.0), 2.0, COLOR_STAIRS_EDGE)


func _draw_blocked_stairs() -> void:
	var position := _cell_to_world(BLOCKED_STAIRS_CELL)
	for step in range(4):
		var width := 30.0 - float(step) * 5.0
		var top := float(step) * 5.0 - 14.0
		draw_rect(Rect2(position + Vector2(-width * 0.5, top), Vector2(width, 4.0)), COLOR_STAIRS, true)
		draw_line(position + Vector2(-width * 0.5, top), position + Vector2(width * 0.5, top), COLOR_STAIRS_EDGE, 1.0)
	if capanga_active:
		draw_arc(position + Vector2(0.0, -3.0), 13.0, 0.0, TAU, 24, COLOR_SEAL, 2.0)
		draw_line(position + Vector2(-9.0, -12.0), position + Vector2(9.0, 6.0), COLOR_SEAL, 2.0)
	else:
		draw_arc(position + Vector2(0.0, -3.0), 13.0, 0.0, TAU, 24, COLOR_MAGIC, 2.0)


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


func _draw_player() -> void:
	var position := player_anchor.position
	draw_circle(position + Vector2(0.0, 7.0), 9.0, Color(0.08, 0.05, 0.03, 0.35))
	var player_row := PLAYER_KNIFE_ROW if current_weapon == Weapon.KNIFE else PLAYER_RIFLE_ROW
	draw_texture_rect_region(
		CHARACTER_ATLAS,
		_character_draw_rect(position),
		_character_sprite_region(player_row, player_animation_state, player_animation_frame),
		Color("ffd8d0") if player_hit_flash_remaining > 0.0 else Color.WHITE
	)
	if heavy_warning_active:
		var font := ThemeDB.fallback_font
		draw_string(font, position + Vector2(-20.0, -58.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 40.0, 28, COLOR_ALERT)


func _draw_capanga() -> void:
	if not capanga_active:
		return
	var position := capanga_anchor.position
	draw_circle(position + Vector2(0.0, 7.0), 10.0, Color(0.08, 0.05, 0.03, 0.35))
	if _is_lobo_room():
		_draw_lobo_placeholder(position)
	else:
		draw_texture_rect_region(
			CHARACTER_ATLAS,
			_character_draw_rect(position),
			_character_sprite_region(CAPANGA_ATLAS_ROW, capanga_animation_state, capanga_animation_frame),
			Color("ffd0c8") if capanga_hit_flash_remaining > 0.0 else Color.WHITE
		)

	var health_rect := Rect2(position + Vector2(-18.0, -58.0), Vector2(36.0, 5.0))
	draw_rect(health_rect, COLOR_HEALTH_BACKGROUND, true)
	var health_width := health_rect.size.x * clampf(capanga_hp / _enemy_max_hp(), 0.0, 1.0)
	draw_rect(Rect2(health_rect.position, Vector2(health_width, health_rect.size.y)), COLOR_ENEMY_HEALTH, true)
	draw_rect(health_rect, COLOR_VOID, false, 1.0)


func _draw_lobo_placeholder(position: Vector2) -> void:
	var body_color := Color("ffd0c8") if capanga_hit_flash_remaining > 0.0 else COLOR_LOBO_BODY
	var tail := PackedVector2Array([
		position + Vector2(-15.0, -24.0),
		position + Vector2(-29.0, -32.0),
		position + Vector2(-20.0, -17.0),
	])
	var body := PackedVector2Array([
		position + Vector2(-18.0, -27.0),
		position + Vector2(7.0, -30.0),
		position + Vector2(14.0, -17.0),
		position + Vector2(-13.0, -15.0),
	])
	draw_colored_polygon(tail, COLOR_LOBO_DARK)
	draw_colored_polygon(body, body_color)
	draw_circle(position + Vector2(15.0, -29.0), 9.0, body_color)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(10.0, -35.0),
		position + Vector2(11.0, -45.0),
		position + Vector2(17.0, -36.0),
	]), COLOR_LOBO_DARK)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(17.0, -36.0),
		position + Vector2(22.0, -44.0),
		position + Vector2(23.0, -33.0),
	]), COLOR_LOBO_DARK)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(20.0, -30.0),
		position + Vector2(30.0, -26.0),
		position + Vector2(21.0, -22.0),
	]), COLOR_LOBO_DARK)
	draw_line(position + Vector2(-10.0, -16.0), position + Vector2(-12.0, 0.0), COLOR_LOBO_DARK, 4.0)
	draw_line(position + Vector2(8.0, -17.0), position + Vector2(11.0, 0.0), COLOR_LOBO_DARK, 4.0)
	draw_circle(position + Vector2(19.0, -31.0), 2.0, COLOR_MAGIC)


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


func _draw_damage_border() -> void:
	if damage_border_remaining <= 0.0:
		return
	var viewport_size := get_viewport_rect().size
	var world_size := Vector2(
		viewport_size.x / maxf(camera.zoom.x, 0.01),
		viewport_size.y / maxf(camera.zoom.y, 0.01)
	)
	var border_rect := Rect2(camera.position - world_size * 0.5, world_size)
	var alpha := 0.65 * clampf(damage_border_remaining / DAMAGE_BORDER_DURATION, 0.0, 1.0)
	draw_rect(border_rect, Color(0.85, 0.08, 0.05, alpha), false, 8.0)
