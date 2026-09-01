extends Node2D

const GridRulesScript = preload("res://scripts/grid_rules.gd")
const PauseMenuScript = preload("res://scripts/pause_menu.gd")

enum AttackType {
	NONE,
	RIFLE,
	KNIFE,
}

enum BossPhase {
	PLAYER_CHOICE,
	PLAYER_ACTION,
	ENEMY_TELEGRAPH,
	PARRY_WINDOW,
	IMPACT,
	CHECK_KO,
}

const VIEWPORT_SIZE := Vector2(768.0, 512.0)
const BOARD_SIZE := Vector2i(10, 10)
const TILE_SIZE := 32
const BOARD_ORIGIN := Vector2(32.0, 96.0)
const HERO_START := Vector2i(1, 8)
const CAPANGA_START := Vector2i(8, 1)
const HERO_MAX_HP := 100
const CAPANGA_MAX_HP := 60
const BOSS_MAX_HP := 250
const HERO_MOVEMENT := 4
const CAPANGA_MOVEMENT := 3
const RIFLE_DAMAGE := 25
const RIFLE_CRITICAL_DAMAGE := 40
const RIFLE_RANGE := 7
const RIFLE_HIT_CHANCE := 0.90
const RIFLE_CRITICAL_CHANCE := 0.25
const KNIFE_DAMAGE := 20
const KNIFE_RANGE := 1
const CAPANGA_DAMAGE := 15
const BOSS_BASIC_DAMAGE := 20
const BOSS_CHARGE_DAMAGE := 40
const BOSS_CHARGE_TURN_INTERVAL := 3
const BOSS_TELEGRAPH_DURATION := 0.35
const BOSS_CHARGE_PARRY_WINDOW := 0.7
const FAILED_PARRY_STUN := 0.7
const BOSS_POPUP_DURATION := 0.8
const BOSS_HIT_FLASH_DURATION := 0.12
const BOSS_DAMAGE_BORDER_DURATION := 0.15
const BOSS_IMPACT_DURATION := 0.22
const LAPADA_BOSS_DAMAGE := RIFLE_DAMAGE * 3
const FADE_DURATION := 0.5
const EXPLORATION_SCENE := "res://scenes/exploration.tscn"
const DUNGEON_SCENE := "res://scenes/dungeon.tscn"
const BOSS_ROOM_ID := "sala_04"

const RIFLE_RECT := Rect2(416.0, 282.0, 136.0, 42.0)
const KNIFE_RECT := Rect2(568.0, 282.0, 136.0, 42.0)
const END_TURN_RECT := Rect2(416.0, 332.0, 288.0, 40.0)
const RESET_RECT := Rect2(416.0, 380.0, 288.0, 40.0)
const LAPADA_RECT := Rect2(416.0, 380.0, 136.0, 40.0)
const RELOAD_RECT := Rect2(568.0, 380.0, 136.0, 40.0)
const HERO_STATUS_RECT := Rect2(32.0, 464.0, 704.0, 24.0)
const OVERLAY_RECT := Rect2(144.0, 112.0, 480.0, 288.0)
const OVERLAY_PRIMARY_RECT := Rect2(224.0, 320.0, 320.0, 44.0)
const OVERLAY_SECONDARY_RECT := Rect2(392.0, 320.0, 152.0, 44.0)
const OVERLAY_RESTART_RECT := Rect2(224.0, 320.0, 152.0, 44.0)
const BOSS_BATTLE_RECT := Rect2(32.0, 92.0, 704.0, 238.0)
const BOSS_MESSAGE_RECT := Rect2(32.0, 346.0, 384.0, 134.0)
const BOSS_RIFLE_RECT := Rect2(432.0, 346.0, 144.0, 60.0)
const BOSS_KNIFE_RECT := Rect2(592.0, 346.0, 144.0, 60.0)
const BOSS_LAPADA_RECT := Rect2(432.0, 420.0, 144.0, 60.0)
const BOSS_RELOAD_RECT := Rect2(592.0, 420.0, 144.0, 60.0)

const COLOR_BACKGROUND := Color("17120d")
const COLOR_PANEL := Color("281d14")
const COLOR_PANEL_BORDER := Color("705033")
const COLOR_TILE_LIGHT := Color("b48a56")
const COLOR_TILE_DARK := Color("9d7447")
const COLOR_GRID := Color("5a4029")
const COLOR_REACHABLE := Color("6f9b62")
const COLOR_PATH := Color("d7b54a")
const COLOR_ROCK := Color("5e594f")
const COLOR_ROCK_LIGHT := Color("858073")
const COLOR_WALL := Color("49382e")
const COLOR_WALL_LIGHT := Color("765b49")
const COLOR_HERO_COAT := Color("94452e")
const COLOR_HERO_HAT := Color("d1a15b")
const COLOR_ENEMY_COAT := Color("4f3327")
const COLOR_ENEMY_ARMOR := Color("6f6654")
const COLOR_ENEMY_HAT := Color("33231b")
const COLOR_TEXT := Color("f2dfbd")
const COLOR_TEXT_DIM := Color("c2a880")
const COLOR_BUTTON := Color("74482c")
const COLOR_BUTTON_HOVER := Color("99613b")
const COLOR_BUTTON_SELECTED := Color("b67639")
const COLOR_HEALTH_BACKGROUND := Color("3b211b")
const COLOR_HEALTH_FILL := Color("b94732")
const COLOR_ENEMY_HEALTH_FILL := Color("d15a3f")
const COLOR_BOSS_BODY := Color("7d4832")
const COLOR_BOSS_HORN := Color("d6c294")
const COLOR_MAGIC := Color("b95cff")
const COLOR_WARNING := Color("ed3128")
const COLOR_NORMAL_DAMAGE := Color("f2dfbd")
const COLOR_CRITICAL_DAMAGE := Color("ef3f35")
const COLOR_PLAYER_DAMAGE := Color("ff725c")
const COLOR_PARRY := Color("f7fbff")
const COLOR_TELEGRAPH := Color("e3a94f")
const COLOR_DISABLED_BUTTON := Color("3d3026")

var blocked: Dictionary = {
	Vector2i(3, 1): true,
	Vector2i(3, 2): true,
	Vector2i(3, 3): true,
	Vector2i(6, 2): true,
	Vector2i(7, 2): true,
	Vector2i(5, 5): true,
	Vector2i(5, 6): true,
	Vector2i(5, 7): true,
	Vector2i(2, 6): true,
	Vector2i(3, 6): true,
	Vector2i(7, 7): true,
	Vector2i(8, 7): true,
}
var walls: Dictionary = {
	Vector2i(3, 1): true,
	Vector2i(3, 2): true,
	Vector2i(3, 3): true,
}

var hero_cell := HERO_START
var capanga_cell := CAPANGA_START
var hero_hp := HERO_MAX_HP
var capanga_hp := CAPANGA_MAX_HP
var movement_left := HERO_MOVEMENT
var round_number := 1
var selected_attack := AttackType.NONE
var player_turn := true
var reachable: Dictionary = {}
var hovered_cell := Vector2i(-1, -1)
var preview_path: Array[Vector2i] = []
var notice := "Mova ou selecione um ataque."
var mouse_position := Vector2.ZERO
var game_version := "V.0.0.0"
var encounter_transitioning := false
var boss_mode := false
var boss_turns_since_charge := 0
var boss_charge_ready := false
var boss_charge_warning_active := false
var boss_charge_warning_remaining := 0.0
var boss_phase := BossPhase.PLAYER_CHOICE
var boss_enemy_action_token := 0
var boss_active_action_token := 0
var boss_resolved_action_token := -1
var boss_parry_attempted_token := -1
var boss_phase_deadline_usec := 0
var boss_parry_window_open_usec := 0
var boss_pending_charge := false
var pending_player_result := ""
var failed_parry_stun_remaining := 0.0
var failed_parry_turn_pending := false
var victory_visible := false
var boss_defeat_visible := false
var boss_exit_visible := false
var boss_combat_popups: Array[Dictionary] = []
var boss_player_hit_flash_remaining := 0.0
var boss_enemy_hit_flash_remaining := 0.0
var boss_damage_border_remaining := 0.0
var boss_impact_remaining := 0.0
var boss_impact_position := Vector2.ZERO
var boss_impact_color := Color.WHITE
var pause_menu

@onready var fade: ColorRect = $FadeLayer/Fade


func _ready() -> void:
	game_version = str(ProjectSettings.get_setting("application/config/version", "V.0.0.0"))
	boss_mode = (
		GameState.dungeon_active
		and GameState.get_current_dungeon_room_id() == BOSS_ROOM_ID
	)
	if boss_mode:
		hero_hp = GameState.player_hp
		capanga_hp = BOSS_MAX_HP
		boss_phase = BossPhase.PLAYER_CHOICE
		selected_attack = (
			AttackType.KNIFE
			if GameState.current_weapon == GameState.WEAPON_KNIFE
			else AttackType.RIFLE
		)
		notice = "Escolha uma ação. A Cabra-Cabriola aguarda."
	_setup_pause_menu()
	fade.modulate.a = 1.0
	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 0.0, FADE_DURATION)
	if not boss_mode:
		_rebuild_reachable()
	queue_redraw()


func _setup_pause_menu() -> void:
	var pause_layer := CanvasLayer.new()
	pause_layer.name = "PauseLayer"
	pause_layer.layer = 200
	add_child(pause_layer)
	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_layer.add_child(pause_menu)
	pause_menu.configure(boss_mode, Callable(self, "_can_open_pause_menu"))
	pause_menu.dungeon_exit_requested.connect(_request_boss_exit_from_pause)
	pause_menu.resumed.connect(_on_pause_menu_resumed)


func _can_open_pause_menu() -> bool:
	return (
		not encounter_transitioning
		and not victory_visible
		and not boss_defeat_visible
		and not boss_exit_visible
	)


func _request_boss_exit_from_pause() -> void:
	if not boss_mode or encounter_transitioning:
		return
	boss_exit_visible = true
	notice = "Sair apagará o progresso atual da masmorra."
	queue_redraw()


func _on_pause_menu_resumed(paused_duration_usec: int) -> void:
	if not boss_mode or paused_duration_usec <= 0:
		return
	if boss_phase == BossPhase.ENEMY_TELEGRAPH or boss_phase == BossPhase.PARRY_WINDOW:
		boss_phase_deadline_usec += paused_duration_usec
	if boss_phase == BossPhase.PARRY_WINDOW:
		boss_parry_window_open_usec += paused_duration_usec
	queue_redraw()


func _process(delta: float) -> void:
	if not boss_mode:
		return
	_advance_boss_visual_effects(delta)
	if encounter_transitioning:
		return
	var now_usec := Time.get_ticks_usec()
	if boss_phase == BossPhase.ENEMY_TELEGRAPH:
		queue_redraw()
	if boss_phase == BossPhase.ENEMY_TELEGRAPH and now_usec >= boss_phase_deadline_usec:
		if boss_pending_charge:
			_start_boss_charge()
		else:
			_resolve_boss_basic_attack(boss_active_action_token)
		queue_redraw()
		return
	if boss_phase == BossPhase.PARRY_WINDOW:
		boss_charge_warning_remaining = maxf(
			0.0,
			float(boss_phase_deadline_usec - now_usec) / 1000000.0
		)
		queue_redraw()
		if now_usec >= boss_phase_deadline_usec:
			_resolve_boss_charge(false, boss_active_action_token)
		queue_redraw()
		return
	if failed_parry_stun_remaining > 0.0:
		failed_parry_stun_remaining = maxf(0.0, failed_parry_stun_remaining - delta)
		if failed_parry_stun_remaining <= 0.0 and failed_parry_turn_pending and player_turn:
			failed_parry_turn_pending = false
			_end_player_turn("Aparo falhou — ação perdida.")
			queue_redraw()


func _advance_boss_visual_effects(delta: float) -> void:
	boss_player_hit_flash_remaining = maxf(0.0, boss_player_hit_flash_remaining - delta)
	boss_enemy_hit_flash_remaining = maxf(0.0, boss_enemy_hit_flash_remaining - delta)
	boss_damage_border_remaining = maxf(0.0, boss_damage_border_remaining - delta)
	boss_impact_remaining = maxf(0.0, boss_impact_remaining - delta)
	for index in range(boss_combat_popups.size() - 1, -1, -1):
		var popup := boss_combat_popups[index]
		popup["elapsed"] = float(popup["elapsed"]) + delta
		if float(popup["elapsed"]) >= float(popup["duration"]):
			boss_combat_popups.remove_at(index)
		else:
			boss_combat_popups[index] = popup
	if (
		boss_player_hit_flash_remaining > 0.0
		or boss_enemy_hit_flash_remaining > 0.0
		or boss_damage_border_remaining > 0.0
		or boss_impact_remaining > 0.0
		or not boss_combat_popups.is_empty()
	):
		queue_redraw()


func _spawn_boss_popup(
	popup_text: String,
	screen_position: Vector2,
	popup_color: Color,
	font_size: int,
	bold: bool,
	duration: float = BOSS_POPUP_DURATION
) -> void:
	boss_combat_popups.append({
		"text": popup_text,
		"position": screen_position,
		"color": popup_color,
		"font_size": font_size,
		"bold": bold,
		"duration": duration,
		"elapsed": 0.0,
	})
	queue_redraw()


func _show_boss_enemy_damage(amount: int, critical: bool = false, lapada: bool = false) -> void:
	boss_enemy_hit_flash_remaining = BOSS_HIT_FLASH_DURATION
	boss_impact_remaining = BOSS_IMPACT_DURATION
	boss_impact_position = Vector2(588.0, 240.0)
	var popup_text := "-%d" % amount
	var popup_color := COLOR_NORMAL_DAMAGE
	var popup_size := 20
	var popup_bold := false
	if lapada:
		popup_text = "LAPADA!  -%d" % amount
		popup_color = COLOR_MAGIC
		popup_size = 28
		popup_bold = true
		_play_boss_audio("lapada")
	elif critical:
		popup_text = "CRÍTICO!  -%d" % amount
		popup_color = COLOR_CRITICAL_DAMAGE
		popup_size = 26
		popup_bold = true
		_play_boss_audio("critical")
	else:
		_play_boss_audio("hit")
	boss_impact_color = popup_color
	_spawn_boss_popup(popup_text, Vector2(548.0, 190.0), popup_color, popup_size, popup_bold)


func _show_boss_player_damage(amount: int) -> void:
	boss_player_hit_flash_remaining = BOSS_HIT_FLASH_DURATION
	boss_damage_border_remaining = BOSS_DAMAGE_BORDER_DURATION
	boss_impact_remaining = BOSS_IMPACT_DURATION
	boss_impact_position = Vector2(176.0, 256.0)
	boss_impact_color = COLOR_PLAYER_DAMAGE
	_spawn_boss_popup("-%d" % amount, Vector2(136.0, 198.0), COLOR_PLAYER_DAMAGE, 24, true)
	_play_boss_audio("hit")


func _show_boss_parry_effect() -> void:
	boss_impact_remaining = BOSS_IMPACT_DURATION
	boss_impact_position = Vector2(250.0, 226.0)
	boss_impact_color = COLOR_PARRY
	_spawn_boss_popup("HÁ!", Vector2(210.0, 174.0), COLOR_PARRY, 30, true, 0.65)
	_play_boss_audio("parry")


func _play_boss_audio(sound_name: String) -> void:
	if not is_inside_tree() or not get_tree().root.has_node("AudioManager"):
		return
	var audio_manager := get_tree().root.get_node("AudioManager")
	match sound_name:
		"shoot": audio_manager.call("play_shoot")
		"knife": audio_manager.call("play_knife")
		"hit": audio_manager.call("play_hit")
		"critical": audio_manager.call("play_critical")
		"lapada": audio_manager.call("play_lapada_seca")
		"parry": audio_manager.call("play_parry")


func _unhandled_input(event: InputEvent) -> void:
	if encounter_transitioning:
		return
	if victory_visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if OVERLAY_PRIMARY_RECT.has_point(event.position):
				_exit_after_boss_victory()
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
				_exit_after_boss_victory()
		queue_redraw()
		return
	if boss_defeat_visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if OVERLAY_RESTART_RECT.has_point(event.position):
				_restart_dungeon_after_boss_defeat()
			elif OVERLAY_SECONDARY_RECT.has_point(event.position):
				_exit_after_boss_defeat()
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
				_restart_dungeon_after_boss_defeat()
			elif event.keycode == KEY_ESCAPE:
				_exit_after_boss_defeat()
		queue_redraw()
		return
	if boss_exit_visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if OVERLAY_RESTART_RECT.has_point(event.position):
				_exit_boss_without_victory()
			elif OVERLAY_SECONDARY_RECT.has_point(event.position):
				boss_exit_visible = false
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
				_exit_boss_without_victory()
			elif event.keycode == KEY_ESCAPE:
				boss_exit_visible = false
		queue_redraw()
		return
	if boss_mode:
		_handle_boss_input(event)
		return
	if boss_charge_warning_active:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
			_resolve_boss_charge(true)
		queue_redraw()
		return
	if failed_parry_stun_remaining > 0.0:
		return

	if event is InputEventMouseMotion:
		mouse_position = event.position
		_update_hover(event.position)
		queue_redraw()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			return

		mouse_position = event.position
		if RIFLE_RECT.has_point(event.position):
			_select_attack(AttackType.RIFLE)
		elif KNIFE_RECT.has_point(event.position):
			_select_attack(AttackType.KNIFE)
		elif END_TURN_RECT.has_point(event.position):
			_end_player_turn("Turno encerrado sem ataque.")
		elif boss_mode and LAPADA_RECT.has_point(event.position):
			_attempt_lapada_boss()
		elif boss_mode and RELOAD_RECT.has_point(event.position):
			_attempt_reload()
		elif not boss_mode and RESET_RECT.has_point(event.position):
			_reset_combat("Encontro reiniciado.")
		else:
			var target_cell := _screen_to_cell(event.position)
			if target_cell == capanga_cell and capanga_hp > 0:
				_attempt_attack(selected_attack)
			elif selected_attack != AttackType.NONE and not boss_mode:
				notice = "Clique no %s para usar o ataque selecionado." % _enemy_name()
			else:
				_try_move_to(target_cell)
		queue_redraw()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if boss_mode and event.keycode == KEY_Q:
			_toggle_selected_weapon()
		elif boss_mode and event.keycode == KEY_E:
			_attempt_lapada_boss()
		elif boss_mode and event.keycode == KEY_R:
			_attempt_reload()
		elif boss_mode and event.keycode == KEY_SPACE:
			_attempt_failed_parry()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_end_player_turn("Turno encerrado sem ataque.")
		elif not boss_mode and event.keycode == KEY_R:
			_reset_combat("Encontro reiniciado.")
		queue_redraw()


func _handle_boss_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position = event.position
		queue_redraw()
		return

	if boss_phase == BossPhase.ENEMY_TELEGRAPH:
		if (
			event is InputEventKey
			and event.pressed
			and not event.echo
			and event.keycode == KEY_SPACE
		):
			_attempt_early_boss_parry()
			queue_redraw()
		return

	if boss_phase == BossPhase.PARRY_WINDOW:
		if (
			event is InputEventKey
			and event.pressed
			and not event.echo
			and event.keycode == KEY_SPACE
		):
			if boss_parry_attempted_token != boss_active_action_token:
				boss_parry_attempted_token = boss_active_action_token
				_resolve_boss_charge(true, boss_active_action_token)
		queue_redraw()
		return

	if boss_phase != BossPhase.PLAYER_CHOICE or not player_turn:
		return
	if failed_parry_stun_remaining > 0.0:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			return
		mouse_position = event.position
		if BOSS_RIFLE_RECT.has_point(event.position):
			_attempt_boss_attack(AttackType.RIFLE)
		elif BOSS_KNIFE_RECT.has_point(event.position):
			_attempt_boss_attack(AttackType.KNIFE)
		elif BOSS_LAPADA_RECT.has_point(event.position):
			_attempt_lapada_boss()
		elif BOSS_RELOAD_RECT.has_point(event.position):
			_attempt_reload()
		queue_redraw()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_toggle_selected_weapon()
		elif event.keycode == KEY_E:
			_attempt_lapada_boss()
		elif event.keycode == KEY_R:
			_attempt_reload()
		elif event.keycode == KEY_SPACE:
			_attempt_failed_parry()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_attempt_boss_attack(selected_attack)
		queue_redraw()


func _select_attack(attack_type: int) -> void:
	if not player_turn:
		return

	selected_attack = attack_type
	if boss_mode:
		GameState.set_current_weapon(
			GameState.WEAPON_KNIFE
			if selected_attack == AttackType.KNIFE
			else GameState.WEAPON_RIFLE
		)
	if selected_attack == AttackType.RIFLE:
		notice = (
			"Rifle selecionado — Enter confirma ou clique em RIFLE."
			if boss_mode
			else "Disparo selecionado — clique no %s." % _enemy_name()
		)
	else:
		notice = (
			"Peixeira selecionada — Enter confirma ou clique em PEIXEIRA."
			if boss_mode
			else "Peixeira selecionada — clique no %s." % _enemy_name()
		)


func _toggle_selected_weapon() -> void:
	var next_attack := AttackType.KNIFE if selected_attack == AttackType.RIFLE else AttackType.RIFLE
	_select_attack(next_attack)


func _attempt_reload() -> bool:
	if (
		not boss_mode
		or not player_turn
		or boss_phase != BossPhase.PLAYER_CHOICE
	):
		return false
	if selected_attack != AttackType.RIFLE:
		notice = "Equipe o Rifle [Q] antes de recarregar."
		return false
	var transferred := GameState.reload_rifle_magazine()
	if transferred <= 0:
		notice = (
			"O pente já está cheio."
			if GameState.rifle_ammo >= GameState.RIFLE_MAGAZINE_CAPACITY
			else "A reserva está vazia."
		)
		return false
	boss_phase = BossPhase.PLAYER_ACTION
	_end_player_turn("Recarga: %d bala(s) transferida(s)." % transferred)
	return true


func _attempt_lapada_boss() -> bool:
	if (
		not boss_mode
		or not player_turn
		or boss_phase != BossPhase.PLAYER_CHOICE
		or capanga_hp <= 0
	):
		return false
	if selected_attack != AttackType.RIFLE:
		notice = "Equipe o Rifle [Q] para usar a Lapada Seca."
		return false
	if GameState.rifle_ammo <= 0:
		notice = "Sem bala no pente para usar a Lapada Seca."
		return false
	if not GameState.has_lapada_ready():
		notice = "Lapada Seca exige 3 críticos (%d/3)." % GameState.lapada_charges
		return false
	if not GameState.consume_lapada_charges():
		return false
	boss_phase = BossPhase.PLAYER_ACTION
	GameState.set_rifle_ammo(GameState.rifle_ammo - 1)
	capanga_hp = maxi(0, capanga_hp - LAPADA_BOSS_DAMAGE)
	_show_boss_enemy_damage(LAPADA_BOSS_DAMAGE, true, true)
	var result := "LAPADA SECA: %d de dano." % LAPADA_BOSS_DAMAGE
	if capanga_hp <= 0:
		_complete_encounter(result)
	else:
		_end_player_turn(result)
	queue_redraw()
	return true


func _attempt_failed_parry() -> bool:
	if (
		not boss_mode
		or not player_turn
		or boss_phase != BossPhase.PLAYER_CHOICE
	):
		return false
	failed_parry_stun_remaining = FAILED_PARRY_STUN
	failed_parry_turn_pending = true
	notice = "Aparo fora da janela — stun de 0,7 s e ação perdida."
	_spawn_boss_popup("FORA DA JANELA", Vector2(116.0, 194.0), COLOR_WARNING, 17, true, 0.7)
	return false


func _attempt_early_boss_parry() -> bool:
	if not boss_mode or boss_phase != BossPhase.ENEMY_TELEGRAPH:
		return false
	if boss_parry_attempted_token == boss_active_action_token:
		return false
	boss_parry_attempted_token = boss_active_action_token
	failed_parry_stun_remaining = FAILED_PARRY_STUN
	failed_parry_turn_pending = true
	notice = "Aparo antecipado — o golpe seguirá e a próxima ação será perdida."
	_spawn_boss_popup("CEDO!", Vector2(136.0, 194.0), COLOR_WARNING, 22, true, 0.7)
	return false


func _enemy_name() -> String:
	return "Cabra-Cabriola" if boss_mode else "Capanga"


func _enemy_max_hp() -> int:
	return BOSS_MAX_HP if boss_mode else CAPANGA_MAX_HP


func _attempt_boss_attack(
	attack_type: int,
	hit_roll: float = -1.0,
	critical_roll: float = -1.0
) -> bool:
	if (
		not boss_mode
		or not player_turn
		or boss_phase != BossPhase.PLAYER_CHOICE
		or capanga_hp <= 0
	):
		return false
	if attack_type != AttackType.RIFLE and attack_type != AttackType.KNIFE:
		notice = "Escolha Rifle, Peixeira, Lapada ou Recarga."
		return false
	if attack_type == AttackType.RIFLE and GameState.rifle_ammo <= 0:
		notice = "Pente vazio — recarregue ou use a Peixeira."
		return false

	selected_attack = attack_type
	GameState.set_current_weapon(
		GameState.WEAPON_KNIFE
		if attack_type == AttackType.KNIFE
		else GameState.WEAPON_RIFLE
	)
	boss_phase = BossPhase.PLAYER_ACTION

	var result_text := ""
	if attack_type == AttackType.RIFLE:
		_play_boss_audio("shoot")
		GameState.set_rifle_ammo(GameState.rifle_ammo - 1)
		var rifle_result := _resolve_rifle(hit_roll, critical_roll)
		var rifle_damage := int(rifle_result["damage"])
		capanga_hp = maxi(0, capanga_hp - rifle_damage)
		if not bool(rifle_result["hit"]):
			result_text = "Rifle: errou."
			_spawn_boss_popup("ERROU", Vector2(548.0, 190.0), COLOR_TEXT_DIM, 18, false)
		elif bool(rifle_result["critical"]):
			GameState.add_lapada_charge()
			result_text = "Rifle crítico: 40 de dano."
			_show_boss_enemy_damage(RIFLE_CRITICAL_DAMAGE, true)
		else:
			result_text = "Rifle: 25 de dano."
			_show_boss_enemy_damage(RIFLE_DAMAGE)
	else:
		_play_boss_audio("knife")
		capanga_hp = maxi(0, capanga_hp - KNIFE_DAMAGE)
		result_text = "Peixeira: 20 de dano."
		_show_boss_enemy_damage(KNIFE_DAMAGE)

	if capanga_hp <= 0:
		_complete_encounter(result_text)
	else:
		_end_player_turn(result_text)
	queue_redraw()
	return true


func _try_move_to(target: Vector2i) -> void:
	if not player_turn:
		return
	if not GridRulesScript.is_inside(target, BOARD_SIZE):
		return
	if target == hero_cell:
		notice = "O Cangaceiro já ocupa essa casa."
		return
	if target == capanga_cell and capanga_hp > 0:
		notice = "A casa do %s está ocupada." % _enemy_name()
		return
	if not reachable.has(target):
		notice = "Casa fora do alcance ou caminho bloqueado."
		return

	var distance := int(reachable[target])
	hero_cell = target
	movement_left -= distance
	if not boss_mode:
		selected_attack = AttackType.NONE
	notice = "Movimento realizado: %d casa(s)." % distance
	_rebuild_reachable()
	_update_hover(mouse_position)


func _attempt_attack(
	attack_type: int,
	hit_roll: float = -1.0,
	critical_roll: float = -1.0
) -> bool:
	if boss_mode:
		return _attempt_boss_attack(attack_type, hit_roll, critical_roll)
	if not player_turn or capanga_hp <= 0:
		return false
	if attack_type == AttackType.NONE:
		notice = "Selecione Disparo ou Peixeira primeiro."
		return false

	var distance := _orthogonal_distance(hero_cell, capanga_cell)
	if attack_type == AttackType.RIFLE:
		if distance > RIFLE_RANGE:
			notice = "%s fora do alcance de 7 casas." % _enemy_name()
			return false
		if _line_crosses_wall(hero_cell, capanga_cell):
			notice = "A parede bloqueia o Disparo."
			return false
		if boss_mode and GameState.rifle_ammo <= 0:
			notice = "Pente vazio — pressione R para recarregar ou Q para usar a Peixeira."
			return false
	elif attack_type == AttackType.KNIFE:
		if distance > KNIFE_RANGE:
			notice = "A Peixeira exige uma casa de distância."
			return false
	else:
		return false

	var result_text := ""
	if attack_type == AttackType.RIFLE:
		if boss_mode:
			GameState.set_rifle_ammo(GameState.rifle_ammo - 1)
		var rifle_result := _resolve_rifle(hit_roll, critical_roll)
		var rifle_damage := int(rifle_result["damage"])
		capanga_hp = maxi(0, capanga_hp - rifle_damage)
		if not bool(rifle_result["hit"]):
			result_text = "Errou."
		elif bool(rifle_result["critical"]):
			if boss_mode:
				GameState.add_lapada_charge()
			result_text = "Crítico: 40 de dano."
		else:
			result_text = "Dano: 25."
	else:
		capanga_hp = maxi(0, capanga_hp - KNIFE_DAMAGE)
		result_text = "Peixeira: 20 de dano."

	if not boss_mode:
		selected_attack = AttackType.NONE
	if capanga_hp <= 0:
		_complete_encounter(result_text)
	else:
		_end_player_turn(result_text)
	queue_redraw()
	return true


func _resolve_rifle(hit_roll: float = -1.0, critical_roll: float = -1.0) -> Dictionary:
	var resolved_hit_roll := randf() if hit_roll < 0.0 else hit_roll
	if resolved_hit_roll >= RIFLE_HIT_CHANCE:
		return {"hit": false, "critical": false, "damage": 0}

	var resolved_critical_roll := randf() if critical_roll < 0.0 else critical_roll
	if resolved_critical_roll < RIFLE_CRITICAL_CHANCE:
		return {"hit": true, "critical": true, "damage": RIFLE_CRITICAL_DAMAGE}
	return {"hit": true, "critical": false, "damage": RIFLE_DAMAGE}


func _end_player_turn(player_result: String) -> void:
	if not player_turn or encounter_transitioning:
		return

	player_turn = false
	if not boss_mode:
		selected_attack = AttackType.NONE
	pending_player_result = player_result
	var enemy_result := _run_capanga_action()
	if boss_mode:
		notice = "%s %s" % [player_result, enemy_result]
		queue_redraw()
		return
	if hero_hp <= 0:
		_reset_combat("Derrota — encontro reiniciado com vida cheia.")
		return
	_finish_round(player_result, enemy_result)


func _finish_round(player_result: String, enemy_result: String) -> void:
	if boss_mode:
		GameState.set_player_hp(hero_hp)
		boss_phase = BossPhase.CHECK_KO
		if hero_hp <= 0:
			_show_boss_defeat()
			return
		round_number += 1
		player_turn = true
		boss_phase = BossPhase.PLAYER_CHOICE
		notice = "%s %s" % [player_result, enemy_result]
		queue_redraw()
		return

	round_number += 1
	movement_left = HERO_MOVEMENT
	player_turn = true
	notice = "%s %s" % [player_result, enemy_result]
	_rebuild_reachable()
	_update_hover(mouse_position)


func _run_capanga_action() -> String:
	if boss_mode:
		return _run_boss_action()

	var distance := _orthogonal_distance(capanga_cell, hero_cell)
	var moved := 0

	if distance > 1:
		var path := GridRulesScript.shortest_path(
			capanga_cell,
			hero_cell,
			BOARD_SIZE.x * BOARD_SIZE.y,
			BOARD_SIZE,
			blocked
		)
		if not path.is_empty():
			var max_steps := maxi(0, path.size() - 2)
			moved = mini(CAPANGA_MOVEMENT, max_steps)
			if moved > 0:
				capanga_cell = path[moved]

	if _orthogonal_distance(capanga_cell, hero_cell) == 1:
		hero_hp = maxi(0, hero_hp - CAPANGA_DAMAGE)
		return "Capanga avançou %d e atacou: 15 de dano." % moved
	if moved > 0:
		return "Capanga avançou %d casa(s)." % moved
	return "Capanga não encontrou caminho."


func _run_boss_action() -> String:
	boss_turns_since_charge += 1
	boss_pending_charge = boss_turns_since_charge >= BOSS_CHARGE_TURN_INTERVAL
	boss_charge_ready = boss_pending_charge
	boss_enemy_action_token += 1
	boss_active_action_token = boss_enemy_action_token
	boss_parry_attempted_token = -1
	boss_phase = BossPhase.ENEMY_TELEGRAPH
	boss_phase_deadline_usec = (
		Time.get_ticks_usec()
		+ int(BOSS_TELEGRAPH_DURATION * 1000000.0)
	)
	if boss_pending_charge:
		return "Cabra-Cabriola prepara a INVESTIDA — espere o sinal de aparo."
	return "Cabra-Cabriola ergue as garras para atacar."


func _boss_can_start_charge() -> bool:
	return (
		boss_mode
		and boss_pending_charge
		and boss_phase == BossPhase.ENEMY_TELEGRAPH
	)


func _start_boss_charge() -> void:
	if not _boss_can_start_charge():
		return
	if boss_resolved_action_token == boss_active_action_token:
		return
	var now_usec := Time.get_ticks_usec()
	boss_phase = BossPhase.PARRY_WINDOW
	boss_charge_warning_active = true
	boss_charge_warning_remaining = BOSS_CHARGE_PARRY_WINDOW
	boss_parry_window_open_usec = now_usec
	boss_phase_deadline_usec = (
		now_usec
		+ int(BOSS_CHARGE_PARRY_WINDOW * 1000000.0)
	)
	notice = "%s INVESTIDA — pressione Espaço agora!" % pending_player_result


func _resolve_boss_basic_attack(action_token: int) -> void:
	if not boss_mode or boss_phase != BossPhase.ENEMY_TELEGRAPH:
		return
	if action_token != boss_active_action_token:
		return
	if boss_resolved_action_token == action_token:
		return
	boss_resolved_action_token = action_token
	boss_phase = BossPhase.IMPACT
	boss_pending_charge = false
	hero_hp = maxi(0, hero_hp - BOSS_BASIC_DAMAGE)
	GameState.set_player_hp(hero_hp)
	_show_boss_player_damage(BOSS_BASIC_DAMAGE)
	_finish_round(
		pending_player_result,
		"Ataque básico: %d de dano." % BOSS_BASIC_DAMAGE
	)


func _resolve_boss_charge(parried: bool, action_token: int = -1) -> void:
	var resolved_token := boss_active_action_token if action_token < 0 else action_token
	if not boss_mode or boss_phase != BossPhase.PARRY_WINDOW:
		return
	if not boss_charge_warning_active or resolved_token != boss_active_action_token:
		return
	if boss_resolved_action_token == resolved_token:
		return
	var now_usec := Time.get_ticks_usec()
	var parry_succeeded := (
		parried
		and now_usec >= boss_parry_window_open_usec
		and now_usec <= boss_phase_deadline_usec
	)
	boss_resolved_action_token = resolved_token
	boss_phase = BossPhase.IMPACT
	boss_charge_warning_active = false
	boss_charge_warning_remaining = 0.0
	boss_charge_ready = false
	boss_pending_charge = false
	boss_turns_since_charge = 0

	var charge_result := ""
	if parry_succeeded:
		charge_result = "HÁ — investida aparada; dano anulado."
		_show_boss_parry_effect()
	else:
		hero_hp = maxi(0, hero_hp - BOSS_CHARGE_DAMAGE)
		GameState.set_player_hp(hero_hp)
		charge_result = "Investida acertou: %d de dano." % BOSS_CHARGE_DAMAGE
		_show_boss_player_damage(BOSS_CHARGE_DAMAGE)
	_finish_round(pending_player_result, charge_result)


func _reset_combat(message: String) -> void:
	hero_cell = HERO_START
	capanga_cell = CAPANGA_START
	hero_hp = HERO_MAX_HP
	capanga_hp = CAPANGA_MAX_HP
	movement_left = HERO_MOVEMENT
	round_number = 1
	selected_attack = AttackType.NONE
	player_turn = true
	encounter_transitioning = false
	notice = message
	_rebuild_reachable()
	_update_hover(mouse_position)
	queue_redraw()


func _complete_encounter(attack_result: String) -> void:
	if boss_mode:
		_complete_boss_encounter(attack_result)
		return

	encounter_transitioning = true
	player_turn = false
	GameState.complete_active_encounter()
	notice = "%s Capanga derrotado — retornando à exploração." % attack_result

	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, FADE_DURATION)
	fade_tween.tween_callback(_return_to_exploration)


func _return_to_exploration() -> void:
	get_tree().change_scene_to_file(EXPLORATION_SCENE)


func _complete_boss_encounter(attack_result: String) -> void:
	capanga_hp = 0
	player_turn = false
	boss_phase = BossPhase.CHECK_KO
	boss_charge_warning_active = false
	failed_parry_stun_remaining = 0.0
	failed_parry_turn_pending = false
	GameState.set_player_hp(hero_hp)
	var reward_granted := GameState.complete_dungeon()
	victory_visible = true
	notice = (
		"%s Cabra-Cabriola derrotada — recompensa de %d ouros."
		% [attack_result, GameState.DUNGEON_BOSS_REWARD]
		if reward_granted
		else "%s Cabra-Cabriola derrotada novamente." % attack_result
	)
	queue_redraw()


func _show_boss_defeat() -> void:
	hero_hp = 0
	player_turn = false
	boss_phase = BossPhase.CHECK_KO
	boss_charge_warning_active = false
	failed_parry_stun_remaining = 0.0
	failed_parry_turn_pending = false
	GameState.set_player_hp(0)
	boss_defeat_visible = true
	notice = "Derrota — escolha reiniciar a masmorra ou sair."
	queue_redraw()


func _exit_after_boss_victory() -> void:
	if encounter_transitioning:
		return
	victory_visible = false
	GameState.leave_dungeon(hero_hp, GameState.rifle_ammo, GameState.current_weapon)
	_start_scene_transition(EXPLORATION_SCENE)


func _restart_dungeon_after_boss_defeat() -> void:
	if encounter_transitioning:
		return
	boss_defeat_visible = false
	GameState.respawn_player()
	GameState.reset_dungeon_progress()
	_start_scene_transition(DUNGEON_SCENE)


func _exit_after_boss_defeat() -> void:
	if encounter_transitioning:
		return
	boss_defeat_visible = false
	GameState.respawn_player()
	GameState.leave_dungeon(
		GameState.player_hp,
		GameState.rifle_ammo,
		GameState.current_weapon
	)
	_start_scene_transition(EXPLORATION_SCENE)


func _exit_boss_without_victory() -> void:
	if encounter_transitioning:
		return
	boss_exit_visible = false
	GameState.leave_dungeon(hero_hp, GameState.rifle_ammo, GameState.current_weapon)
	_start_scene_transition(EXPLORATION_SCENE)


func _start_scene_transition(scene_path: String) -> void:
	encounter_transitioning = true
	player_turn = false
	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, FADE_DURATION)
	fade_tween.tween_callback(_change_scene.bind(scene_path))


func _change_scene(scene_path: String) -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file(scene_path)


func _rebuild_reachable() -> void:
	var movement_blockers := blocked.duplicate()
	if capanga_hp > 0:
		movement_blockers[capanga_cell] = true
	reachable = GridRulesScript.reachable_distances(
		hero_cell,
		movement_left,
		BOARD_SIZE,
		movement_blockers
	)


func _update_hover(screen_position: Vector2) -> void:
	hovered_cell = _screen_to_cell(screen_position)
	preview_path.clear()

	if selected_attack != AttackType.NONE and not boss_mode:
		return
	if not reachable.has(hovered_cell) or hovered_cell == hero_cell:
		return

	var movement_blockers := blocked.duplicate()
	if capanga_hp > 0:
		movement_blockers[capanga_cell] = true
	preview_path = GridRulesScript.shortest_path(
		hero_cell,
		hovered_cell,
		movement_left,
		BOARD_SIZE,
		movement_blockers
	)


func _screen_to_cell(screen_position: Vector2) -> Vector2i:
	var local_position := screen_position - BOARD_ORIGIN
	return Vector2i(
		int(floor(local_position.x / TILE_SIZE)),
		int(floor(local_position.y / TILE_SIZE))
	)


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(
		BOARD_ORIGIN + Vector2(cell.x, cell.y) * TILE_SIZE,
		Vector2(TILE_SIZE, TILE_SIZE)
	)


func _orthogonal_distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
	return absi(to_cell.x - from_cell.x) + absi(to_cell.y - from_cell.y)


func _line_crosses_wall(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var current := from_cell
	var delta_x := absi(to_cell.x - from_cell.x)
	var step_x := 1 if from_cell.x < to_cell.x else -1
	var delta_y := -absi(to_cell.y - from_cell.y)
	var step_y := 1 if from_cell.y < to_cell.y else -1
	var error := delta_x + delta_y

	while true:
		if current != from_cell and current != to_cell and walls.has(current):
			return true
		if current == to_cell:
			break

		var doubled_error := 2 * error
		if doubled_error >= delta_y:
			error += delta_y
			current.x += step_x
		if doubled_error <= delta_x:
			error += delta_x
			current.y += step_y

	return false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), COLOR_BACKGROUND, true)
	if boss_mode:
		_draw_boss_header()
		_draw_boss_one_on_one()
		_draw_boss_telegraph()
		_draw_boss_charge_warning()
		_draw_boss_damage_border()
		_draw_boss_overlay()
		return
	_draw_header()
	_draw_board()
	_draw_side_panel()
	_draw_hero_status()


func _draw_boss_header() -> void:
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(32.0, 42.0),
		"3M: MONSTROS MASMORRAS & MANDINGAS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		24,
		COLOR_TEXT
	)
	draw_string(
		font,
		Vector2(32.0, 68.0),
		"Masmorra — Sala 4/4 • Batalha 1×1 por turnos • %s" % game_version,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		15,
		COLOR_TEXT_DIM
	)


func _draw_boss_one_on_one() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(BOSS_BATTLE_RECT, COLOR_PANEL, true)
	draw_rect(BOSS_BATTLE_RECT, COLOR_PANEL_BORDER, false, 2.0)
	draw_rect(Rect2(34.0, 218.0, 700.0, 110.0), Color("35271c"), true)
	draw_line(Vector2(34.0, 282.0), Vector2(734.0, 282.0), COLOR_PANEL_BORDER, 2.0)
	draw_string(
		font,
		Vector2(32.0, 114.0),
		"RODADA %d" % round_number,
		HORIZONTAL_ALIGNMENT_CENTER,
		704.0,
		16,
		COLOR_TEXT_DIM
	)

	_draw_battle_health_bar(
		Rect2(64.0, 126.0, 248.0, 22.0),
		hero_hp,
		HERO_MAX_HP,
		COLOR_HEALTH_FILL,
		"CANGACEIRO"
	)
	_draw_battle_health_bar(
		Rect2(456.0, 126.0, 248.0, 22.0),
		capanga_hp,
		BOSS_MAX_HP,
		COLOR_MAGIC,
		"CABRA-CABRIOLA"
	)

	_draw_boss_hero_portrait(Vector2(176.0, 256.0))
	_draw_boss_enemy_portrait(Vector2(588.0, 240.0))
	_draw_boss_impact_burst()
	_draw_boss_combat_popups()
	draw_string(
		font,
		Vector2(32.0, 316.0),
		_boss_phase_label(),
		HORIZONTAL_ALIGNMENT_CENTER,
		704.0,
		16,
		COLOR_WARNING if boss_phase == BossPhase.PARRY_WINDOW else COLOR_TEXT_DIM
	)

	draw_rect(BOSS_MESSAGE_RECT, COLOR_PANEL, true)
	draw_rect(BOSS_MESSAGE_RECT, COLOR_PANEL_BORDER, false, 2.0)
	draw_string(
		font,
		Vector2(48.0, 372.0),
		"RECURSOS DO CANGACEIRO",
		HORIZONTAL_ALIGNMENT_LEFT,
		352.0,
		14,
		COLOR_TEXT
	)
	draw_string(
		font,
		Vector2(48.0, 394.0),
		"PENTE %d/%d  •  RESERVA %d  •  LAPADA %d/3" % [
			GameState.rifle_ammo,
			GameState.RIFLE_MAGAZINE_CAPACITY,
			GameState.rifle_reserve_ammo,
			GameState.lapada_charges,
		],
		HORIZONTAL_ALIGNMENT_LEFT,
		352.0,
		12,
		COLOR_TEXT_DIM
	)
	var message_lines := _wrap_boss_message(notice, 47)
	for line_index in range(mini(3, message_lines.size())):
		draw_string(
			font,
			Vector2(48.0, 420.0 + float(line_index) * 20.0),
			message_lines[line_index],
			HORIZONTAL_ALIGNMENT_LEFT,
			352.0,
			13,
			COLOR_TEXT_DIM
		)

	var can_choose := (
		boss_phase == BossPhase.PLAYER_CHOICE
		and player_turn
		and failed_parry_stun_remaining <= 0.0
	)
	_draw_button(
		BOSS_RIFLE_RECT,
		"RIFLE %d/%d" % [GameState.rifle_ammo, GameState.RIFLE_MAGAZINE_CAPACITY],
		selected_attack == AttackType.RIFLE,
		can_choose and GameState.rifle_ammo > 0
	)
	_draw_button(
		BOSS_KNIFE_RECT,
		"PEIXEIRA",
		selected_attack == AttackType.KNIFE,
		can_choose
	)
	_draw_button(
		BOSS_LAPADA_RECT,
		"LAPADA [E] %d/3" % GameState.lapada_charges,
		false,
		can_choose
		and selected_attack == AttackType.RIFLE
		and GameState.rifle_ammo > 0
		and GameState.has_lapada_ready()
	)
	_draw_button(
		BOSS_RELOAD_RECT,
		"RECARGA [R] %d" % GameState.rifle_reserve_ammo,
		false,
		can_choose
		and selected_attack == AttackType.RIFLE
		and GameState.rifle_ammo < GameState.RIFLE_MAGAZINE_CAPACITY
		and GameState.rifle_reserve_ammo > 0
	)


func _draw_battle_health_bar(
	rect: Rect2,
	value: int,
	maximum: int,
	fill_color: Color,
	label: String
) -> void:
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		rect.position + Vector2(0.0, -8.0),
		"%s  %d/%d" % [label, value, maximum],
		HORIZONTAL_ALIGNMENT_LEFT,
		rect.size.x,
		14,
		COLOR_TEXT
	)
	draw_rect(rect, COLOR_HEALTH_BACKGROUND, true)
	var safe_ratio := clampf(float(value) / float(maxi(1, maximum)), 0.0, 1.0)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * safe_ratio, rect.size.y)), fill_color, true)
	draw_rect(rect, COLOR_PANEL_BORDER, false, 2.0)


func _draw_boss_hero_portrait(center: Vector2) -> void:
	draw_ellipse_shadow(center + Vector2(0.0, 40.0), 46.0)
	var coat_color := COLOR_HERO_COAT
	var hat_color := COLOR_HERO_HAT
	if boss_player_hit_flash_remaining > 0.0:
		var flash_ratio := clampf(
			boss_player_hit_flash_remaining / BOSS_HIT_FLASH_DURATION,
			0.0,
			1.0
		)
		coat_color = coat_color.lerp(Color.WHITE, flash_ratio * 0.82)
		hat_color = hat_color.lerp(Color.WHITE, flash_ratio * 0.70)
	var body_rect := Rect2(center + Vector2(-28.0, -4.0), Vector2(56.0, 74.0))
	draw_rect(body_rect, coat_color, true)
	draw_rect(body_rect, COLOR_BACKGROUND, false, 3.0)
	draw_circle(center + Vector2(0.0, -20.0), 22.0, coat_color)
	draw_rect(Rect2(center + Vector2(-38.0, -37.0), Vector2(76.0, 12.0)), hat_color, true)
	draw_rect(Rect2(center + Vector2(-24.0, -53.0), Vector2(48.0, 20.0)), hat_color, true)
	draw_line(center + Vector2(26.0, 16.0), center + Vector2(62.0, 2.0), hat_color, 7.0)


func _draw_boss_enemy_portrait(center: Vector2) -> void:
	draw_ellipse_shadow(center + Vector2(0.0, 50.0), 58.0)
	var body_color := COLOR_BOSS_BODY
	var horn_color := COLOR_BOSS_HORN
	if boss_enemy_hit_flash_remaining > 0.0:
		var flash_ratio := clampf(
			boss_enemy_hit_flash_remaining / BOSS_HIT_FLASH_DURATION,
			0.0,
			1.0
		)
		body_color = body_color.lerp(Color.WHITE, flash_ratio * 0.85)
		horn_color = horn_color.lerp(Color.WHITE, flash_ratio * 0.70)
	if boss_phase == BossPhase.ENEMY_TELEGRAPH:
		var pulse := 0.52 + 0.30 * sin(float(Time.get_ticks_msec()) * 0.018)
		var outline_color := COLOR_WARNING if boss_pending_charge else COLOR_TELEGRAPH
		outline_color.a = pulse
		draw_arc(center + Vector2(0.0, 2.0), 67.0, 0.0, TAU, 40, outline_color, 4.0)
	var body_rect := Rect2(center + Vector2(-38.0, -2.0), Vector2(76.0, 86.0))
	draw_rect(body_rect, body_color, true)
	draw_rect(body_rect, COLOR_BACKGROUND, false, 3.0)
	draw_circle(center + Vector2(0.0, -30.0), 31.0, body_color)
	draw_polyline(
		PackedVector2Array([
			center + Vector2(-20.0, -51.0),
			center + Vector2(-48.0, -76.0),
			center + Vector2(-51.0, -40.0),
		]),
		horn_color,
		7.0
	)
	draw_polyline(
		PackedVector2Array([
			center + Vector2(20.0, -51.0),
			center + Vector2(48.0, -76.0),
			center + Vector2(51.0, -40.0),
		]),
		horn_color,
		7.0
	)
	draw_circle(center + Vector2(-11.0, -31.0), 4.0, COLOR_MAGIC)
	draw_circle(center + Vector2(11.0, -31.0), 4.0, COLOR_MAGIC)


func _draw_boss_impact_burst() -> void:
	if boss_impact_remaining <= 0.0:
		return
	var progress := 1.0 - clampf(boss_impact_remaining / BOSS_IMPACT_DURATION, 0.0, 1.0)
	var burst_color := boss_impact_color
	burst_color.a = 1.0 - progress
	var inner_radius := 16.0 + progress * 18.0
	var outer_radius := 34.0 + progress * 34.0
	for ray_index in range(12):
		var angle := TAU * float(ray_index) / 12.0
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(
			boss_impact_position + direction * inner_radius,
			boss_impact_position + direction * outer_radius,
			burst_color,
			4.0
		)
	draw_arc(
		boss_impact_position,
		22.0 + progress * 28.0,
		0.0,
		TAU,
		36,
		burst_color,
		3.0
	)


func _draw_boss_combat_popups() -> void:
	var font := ThemeDB.fallback_font
	for popup in boss_combat_popups:
		var duration := float(popup["duration"])
		var progress := clampf(float(popup["elapsed"]) / duration, 0.0, 1.0)
		var popup_position: Vector2 = popup["position"] + Vector2(0.0, -progress * 34.0)
		var popup_color: Color = popup["color"]
		popup_color.a = 1.0 - progress
		var popup_text := str(popup["text"])
		var popup_size := int(popup["font_size"])
		var measured_width := font.get_string_size(
			popup_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			popup_size
		).x
		var popup_width := clampf(measured_width + 24.0, 96.0, 260.0)
		var popup_draw_position := popup_position + Vector2(40.0 - popup_width * 0.5, 0.0)
		popup_draw_position.x = clampf(
			popup_draw_position.x,
			12.0,
			VIEWPORT_SIZE.x - popup_width - 12.0
		)
		var shadow_color := Color(0.05, 0.03, 0.02, popup_color.a * 0.88)
		for shadow_offset in [Vector2(-2.0, 0.0), Vector2(2.0, 0.0), Vector2(0.0, 2.0)]:
			draw_string(
				font,
				popup_draw_position + shadow_offset,
				popup_text,
				HORIZONTAL_ALIGNMENT_CENTER,
				popup_width,
				popup_size,
				shadow_color
			)
		if bool(popup["bold"]):
			for bold_offset in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0)]:
				draw_string(
					font,
					popup_draw_position + bold_offset,
					popup_text,
					HORIZONTAL_ALIGNMENT_CENTER,
					popup_width,
					popup_size,
					popup_color
				)
		draw_string(
			font,
			popup_draw_position,
			popup_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			popup_width,
			popup_size,
			popup_color
		)


func draw_ellipse_shadow(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for point_index in range(24):
		var angle := TAU * float(point_index) / 24.0
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.28))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.34))


func _boss_phase_label() -> String:
	match boss_phase:
		BossPhase.PLAYER_CHOICE:
			if failed_parry_stun_remaining > 0.0:
				return "ATORDOADO — %.1f s" % failed_parry_stun_remaining
			return "SUA VEZ — clique em uma ação ou pressione Enter"
		BossPhase.PLAYER_ACTION:
			return "AÇÃO DO CANGACEIRO"
		BossPhase.ENEMY_TELEGRAPH:
			return "A CABRA-CABRIOLA SE PREPARA"
		BossPhase.PARRY_WINDOW:
			return "APARE AGORA — ESPAÇO"
		BossPhase.IMPACT:
			return "IMPACTO"
		BossPhase.CHECK_KO:
			return "RESULTADO"
	return "BATALHA"


func _wrap_boss_message(message: String, maximum_characters: int) -> Array[String]:
	var lines: Array[String] = []
	var current_line := ""
	for word in message.split(" ", false):
		var candidate := str(word) if current_line.is_empty() else "%s %s" % [current_line, word]
		if candidate.length() <= maximum_characters:
			current_line = candidate
		else:
			if not current_line.is_empty():
				lines.append(current_line)
			current_line = str(word)
	if not current_line.is_empty():
		lines.append(current_line)
	return lines


func _draw_header() -> void:
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(32.0, 42.0),
		"3M: MONSTROS MASMORRAS & MANDINGAS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		24,
		COLOR_TEXT
	)
	draw_string(
		font,
		Vector2(32.0, 68.0),
		(
			"Masmorra — Sala 4/4 • Chefe tático • %s" % game_version
			if boss_mode
			else "Protótipo 01 — combate básico • %s" % game_version
		),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		15,
		COLOR_TEXT_DIM
	)


func _draw_board() -> void:
	for y in range(BOARD_SIZE.y):
		for x in range(BOARD_SIZE.x):
			var cell := Vector2i(x, y)
			var cell_rect := _cell_rect(cell)
			var fill := COLOR_TILE_LIGHT if (x + y) % 2 == 0 else COLOR_TILE_DARK

			if reachable.has(cell) and cell != hero_cell and not blocked.has(cell):
				fill = fill.lerp(COLOR_REACHABLE, 0.58)
			if preview_path.has(cell) and cell != hero_cell:
				fill = fill.lerp(COLOR_PATH, 0.72)

			draw_rect(cell_rect, fill, true)
			draw_rect(cell_rect, COLOR_GRID, false, 1.0)

			if walls.has(cell):
				_draw_wall(cell_rect)
			elif blocked.has(cell):
				_draw_rock(cell_rect)

	_draw_hero(_cell_rect(hero_cell))
	if capanga_hp > 0:
		_draw_capanga(_cell_rect(capanga_cell))


func _draw_rock(cell_rect: Rect2) -> void:
	var rock_rect := cell_rect.grow(-5.0)
	draw_rect(rock_rect, COLOR_ROCK, true)
	draw_rect(Rect2(rock_rect.position, Vector2(rock_rect.size.x, 5.0)), COLOR_ROCK_LIGHT, true)
	draw_rect(rock_rect, COLOR_GRID, false, 1.0)


func _draw_wall(cell_rect: Rect2) -> void:
	var wall_rect := cell_rect.grow(-3.0)
	draw_rect(wall_rect, COLOR_WALL, true)
	draw_rect(Rect2(wall_rect.position, Vector2(wall_rect.size.x, 6.0)), COLOR_WALL_LIGHT, true)
	draw_line(
		wall_rect.position + Vector2(0.0, wall_rect.size.y * 0.55),
		wall_rect.end - Vector2(0.0, wall_rect.size.y * 0.45),
		COLOR_WALL_LIGHT,
		1.0
	)
	draw_rect(wall_rect, COLOR_GRID, false, 2.0)


func _draw_hero(cell_rect: Rect2) -> void:
	var body_rect := Rect2(cell_rect.position + Vector2(7.0, 9.0), Vector2(18.0, 18.0))
	draw_rect(body_rect, COLOR_HERO_COAT, true)
	draw_rect(body_rect, COLOR_BACKGROUND, false, 1.0)
	draw_rect(Rect2(cell_rect.position + Vector2(5.0, 7.0), Vector2(22.0, 5.0)), COLOR_HERO_HAT, true)
	draw_rect(Rect2(cell_rect.position + Vector2(9.0, 3.0), Vector2(14.0, 6.0)), COLOR_HERO_HAT, true)


func _draw_capanga(cell_rect: Rect2) -> void:
	if boss_mode:
		_draw_cabra_cabriola(cell_rect)
		return

	var body_rect := Rect2(cell_rect.position + Vector2(6.0, 8.0), Vector2(20.0, 19.0))
	draw_rect(body_rect, COLOR_ENEMY_COAT, true)
	draw_rect(Rect2(cell_rect.position + Vector2(4.0, 13.0), Vector2(24.0, 9.0)), COLOR_ENEMY_ARMOR, true)
	draw_rect(Rect2(cell_rect.position + Vector2(5.0, 6.0), Vector2(22.0, 5.0)), COLOR_ENEMY_HAT, true)
	draw_rect(Rect2(cell_rect.position + Vector2(9.0, 2.0), Vector2(14.0, 6.0)), COLOR_ENEMY_HAT, true)

	var health_rect := Rect2(cell_rect.position + Vector2(3.0, -5.0), Vector2(26.0, 5.0))
	draw_rect(health_rect, COLOR_HEALTH_BACKGROUND, true)
	var health_width := health_rect.size.x * float(capanga_hp) / float(_enemy_max_hp())
	draw_rect(Rect2(health_rect.position, Vector2(health_width, health_rect.size.y)), COLOR_ENEMY_HEALTH_FILL, true)
	draw_rect(health_rect, COLOR_BACKGROUND, false, 1.0)


func _draw_cabra_cabriola(cell_rect: Rect2) -> void:
	var center := cell_rect.get_center()
	var body_rect := Rect2(center + Vector2(-10.0, -7.0), Vector2(20.0, 22.0))
	draw_rect(body_rect, COLOR_BOSS_BODY, true)
	draw_rect(body_rect, COLOR_BACKGROUND, false, 1.0)
	draw_circle(center + Vector2(0.0, -9.0), 8.0, COLOR_BOSS_BODY)
	draw_polyline(
		PackedVector2Array([
			center + Vector2(-5.0, -14.0),
			center + Vector2(-11.0, -20.0),
			center + Vector2(-12.0, -12.0),
		]),
		COLOR_BOSS_HORN,
		3.0
	)
	draw_polyline(
		PackedVector2Array([
			center + Vector2(5.0, -14.0),
			center + Vector2(11.0, -20.0),
			center + Vector2(12.0, -12.0),
		]),
		COLOR_BOSS_HORN,
		3.0
	)
	draw_circle(center + Vector2(-3.0, -9.0), 1.5, COLOR_MAGIC)
	draw_circle(center + Vector2(3.0, -9.0), 1.5, COLOR_MAGIC)
	draw_line(center + Vector2(-7.0, 15.0), center + Vector2(-10.0, 20.0), COLOR_BOSS_HORN, 3.0)
	draw_line(center + Vector2(7.0, 15.0), center + Vector2(10.0, 20.0), COLOR_BOSS_HORN, 3.0)

	var health_rect := Rect2(cell_rect.position + Vector2(1.0, -6.0), Vector2(30.0, 5.0))
	draw_rect(health_rect, COLOR_HEALTH_BACKGROUND, true)
	var health_width := health_rect.size.x * float(capanga_hp) / float(BOSS_MAX_HP)
	draw_rect(Rect2(health_rect.position, Vector2(health_width, health_rect.size.y)), COLOR_MAGIC, true)
	draw_rect(health_rect, COLOR_BACKGROUND, false, 1.0)


func _draw_side_panel() -> void:
	var font := ThemeDB.fallback_font
	var panel_rect := Rect2(384.0, 96.0, 352.0, 340.0)
	draw_rect(panel_rect, COLOR_PANEL, true)
	draw_rect(panel_rect, COLOR_PANEL_BORDER, false, 2.0)

	draw_string(
		font,
		Vector2(416.0, 130.0),
		"CHEFE: CABRA-CABRIOLA" if boss_mode else "ENCONTRO: CAPANGA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		18,
		COLOR_TEXT
	)
	draw_string(font, Vector2(416.0, 158.0), "Rodada: %d" % round_number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, COLOR_TEXT)
	draw_string(
		font,
		Vector2(416.0, 184.0),
		"Movimento: %d / %d" % [movement_left, HERO_MOVEMENT],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		15,
		COLOR_TEXT
	)
	draw_string(
		font,
		Vector2(416.0, 210.0),
		"%s: %d / %d HP" % [_enemy_name(), capanga_hp, _enemy_max_hp()],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		15,
		COLOR_TEXT
	)
	var attack_name := "Nenhum"
	if selected_attack == AttackType.RIFLE:
		attack_name = "Disparo"
	elif selected_attack == AttackType.KNIFE:
		attack_name = "Peixeira"
	if boss_mode:
		draw_string(
			font,
			Vector2(416.0, 234.0),
			"%s • Pente %d/%d • Reserva %d" % [
				attack_name,
				GameState.rifle_ammo,
				GameState.RIFLE_MAGAZINE_CAPACITY,
				GameState.rifle_reserve_ammo,
			],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			12,
			COLOR_TEXT_DIM
		)
		var charge_text := "PRONTA" if boss_charge_ready else "%d/%d" % [
			boss_turns_since_charge,
			BOSS_CHARGE_TURN_INTERVAL,
		]
		draw_string(
			font,
			Vector2(416.0, 254.0),
			"Lapada %d/3 • Investida %s" % [GameState.lapada_charges, charge_text],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			12,
			COLOR_TEXT_DIM
		)
		draw_string(font, Vector2(416.0, 274.0), notice, HORIZONTAL_ALIGNMENT_LEFT, 288.0, 11, COLOR_TEXT_DIM)
	else:
		draw_string(font, Vector2(416.0, 236.0), "Ataque: %s" % attack_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, COLOR_TEXT_DIM)
		draw_string(font, Vector2(416.0, 264.0), notice, HORIZONTAL_ALIGNMENT_LEFT, 288.0, 12, COLOR_TEXT_DIM)

	_draw_button(RIFLE_RECT, "RIFLE  [Q]" if boss_mode else "DISPARO", selected_attack == AttackType.RIFLE)
	_draw_button(KNIFE_RECT, "PEIXEIRA  [Q]" if boss_mode else "PEIXEIRA", selected_attack == AttackType.KNIFE)
	_draw_button(END_TURN_RECT, "ENCERRAR TURNO  [ENTER]")
	if boss_mode:
		_draw_button(LAPADA_RECT, "LAPADA  [E]")
		_draw_button(RELOAD_RECT, "RECARREGAR  [R]")
	else:
		_draw_button(RESET_RECT, "REINICIAR  [R]")


func _draw_button(
	rect: Rect2,
	label: String,
	selected: bool = false,
	enabled: bool = true
) -> void:
	var font := ThemeDB.fallback_font
	var color := COLOR_BUTTON
	var text_color := COLOR_TEXT
	if not enabled:
		color = COLOR_DISABLED_BUTTON
		text_color = COLOR_TEXT_DIM.darkened(0.28)
	elif selected:
		color = COLOR_BUTTON_SELECTED
	elif rect.has_point(mouse_position):
		color = COLOR_BUTTON_HOVER
	draw_rect(rect, color, true)
	draw_rect(rect, COLOR_GRID if not enabled else COLOR_PANEL_BORDER, false, 2.0)
	draw_string(
		font,
		Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5 + 5.0),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		14,
		text_color
	)


func _draw_hero_status() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(HERO_STATUS_RECT, COLOR_HEALTH_BACKGROUND, true)
	var health_width := HERO_STATUS_RECT.size.x * float(hero_hp) / float(HERO_MAX_HP)
	draw_rect(
		Rect2(HERO_STATUS_RECT.position, Vector2(health_width, HERO_STATUS_RECT.size.y)),
		COLOR_HEALTH_FILL,
		true
	)
	draw_rect(HERO_STATUS_RECT, COLOR_PANEL_BORDER, false, 2.0)
	draw_string(
		font,
		Vector2(HERO_STATUS_RECT.position.x, HERO_STATUS_RECT.position.y + 18.0),
		"VIDA DO CANGACEIRO  %d / %d" % [hero_hp, HERO_MAX_HP],
		HORIZONTAL_ALIGNMENT_CENTER,
		HERO_STATUS_RECT.size.x,
		14,
		COLOR_TEXT
	)


func _draw_boss_telegraph() -> void:
	if boss_phase != BossPhase.ENEMY_TELEGRAPH:
		return
	var font := ThemeDB.fallback_font
	var telegraph_rect := Rect2(214.0, 166.0, 340.0, 78.0)
	var telegraph_color := COLOR_WARNING if boss_pending_charge else COLOR_TELEGRAPH
	var remaining := maxf(
		0.0,
		float(boss_phase_deadline_usec - Time.get_ticks_usec()) / 1000000.0
	)
	draw_rect(telegraph_rect, Color(0.10, 0.07, 0.04, 0.94), true)
	draw_rect(telegraph_rect, telegraph_color, false, 3.0)
	draw_string(
		font,
		Vector2(telegraph_rect.position.x, telegraph_rect.position.y + 30.0),
		"INVESTIDA SENDO PREPARADA" if boss_pending_charge else "ATAQUE INIMIGO",
		HORIZONTAL_ALIGNMENT_CENTER,
		telegraph_rect.size.x,
		20,
		telegraph_color
	)
	draw_string(
		font,
		Vector2(telegraph_rect.position.x, telegraph_rect.position.y + 54.0),
		"AGUARDE O SINAL PARA APARAR" if boss_pending_charge else "CABRA-CABRIOLA VAI ATACAR",
		HORIZONTAL_ALIGNMENT_CENTER,
		telegraph_rect.size.x,
		13,
		COLOR_TEXT
	)
	var progress_rect := Rect2(telegraph_rect.position + Vector2(12.0, 65.0), Vector2(316.0, 5.0))
	draw_rect(progress_rect, COLOR_HEALTH_BACKGROUND, true)
	draw_rect(
		Rect2(
			progress_rect.position,
			Vector2(progress_rect.size.x * clampf(remaining / BOSS_TELEGRAPH_DURATION, 0.0, 1.0), 5.0)
		),
		telegraph_color,
		true
	)


func _draw_boss_charge_warning() -> void:
	if not boss_charge_warning_active:
		return
	var font := ThemeDB.fallback_font
	var warning_rect := Rect2(184.0, 146.0, 400.0, 132.0)
	var pulse := 0.78 + 0.22 * sin(float(Time.get_ticks_msec()) * 0.025)
	var pulsing_warning := COLOR_WARNING
	pulsing_warning.a = pulse
	draw_rect(warning_rect, Color(0.17, 0.015, 0.01, 0.97), true)
	draw_rect(warning_rect, pulsing_warning, false, 5.0)
	draw_string(
		font,
		Vector2(warning_rect.position.x, warning_rect.position.y + 34.0),
		"!  INVESTIDA  !",
		HORIZONTAL_ALIGNMENT_CENTER,
		warning_rect.size.x,
		25,
		COLOR_WARNING
	)
	draw_string(
		font,
		Vector2(warning_rect.position.x, warning_rect.position.y + 65.0),
		"APERTE [ESPAÇO] PARA APARAR",
		HORIZONTAL_ALIGNMENT_CENTER,
		warning_rect.size.x,
		18,
		COLOR_TEXT
	)
	var key_rect := Rect2(warning_rect.position + Vector2(132.0, 76.0), Vector2(136.0, 32.0))
	draw_rect(key_rect, COLOR_PARRY, true)
	draw_rect(key_rect, COLOR_BACKGROUND, false, 3.0)
	draw_string(
		font,
		Vector2(key_rect.position.x, key_rect.position.y + 22.0),
		"ESPAÇO",
		HORIZONTAL_ALIGNMENT_CENTER,
		key_rect.size.x,
		15,
		COLOR_BACKGROUND
	)
	var time_bar := Rect2(warning_rect.position + Vector2(18.0, 116.0), Vector2(364.0, 8.0))
	draw_rect(time_bar, COLOR_HEALTH_BACKGROUND, true)
	draw_rect(
		Rect2(
			time_bar.position,
			Vector2(
				time_bar.size.x * clampf(
					boss_charge_warning_remaining / BOSS_CHARGE_PARRY_WINDOW,
					0.0,
					1.0
				),
				time_bar.size.y
			)
		),
		COLOR_PARRY,
		true
	)
	draw_string(
		font,
		Vector2(warning_rect.position.x + 310.0, warning_rect.position.y + 104.0),
		"%.1f s" % boss_charge_warning_remaining,
		HORIZONTAL_ALIGNMENT_CENTER,
		72.0,
		12,
		COLOR_TEXT_DIM
	)


func _draw_boss_damage_border() -> void:
	if boss_damage_border_remaining <= 0.0:
		return
	var alpha := 0.72 * clampf(
		boss_damage_border_remaining / BOSS_DAMAGE_BORDER_DURATION,
		0.0,
		1.0
	)
	draw_rect(Rect2(7.0, 7.0, 754.0, 498.0), Color(0.90, 0.06, 0.03, alpha), false, 10.0)


func _draw_boss_overlay() -> void:
	if not victory_visible and not boss_defeat_visible and not boss_exit_visible:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.0, 0.0, 0.0, 0.72), true)
	draw_rect(OVERLAY_RECT, COLOR_PANEL, true)
	draw_rect(OVERLAY_RECT, COLOR_PANEL_BORDER, false, 3.0)

	if victory_visible:
		draw_string(font, Vector2(144.0, 168.0), "VITÓRIA", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 30, COLOR_TEXT)
		draw_string(font, Vector2(144.0, 208.0), "A Cabra-Cabriola foi derrotada.", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 18, COLOR_TEXT_DIM)
		draw_string(font, Vector2(144.0, 242.0), "A vila está protegida.", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 18, COLOR_TEXT_DIM)
		draw_string(font, Vector2(144.0, 286.0), "OURO FINAL: %d" % GameState.gold_score, HORIZONTAL_ALIGNMENT_CENTER, 480.0, 22, COLOR_TEXT)
		_draw_button(OVERLAY_PRIMARY_RECT, "SAIR DA MASMORRA  [ENTER]")
		return

	if boss_defeat_visible:
		draw_string(font, Vector2(144.0, 168.0), "DERROTA NA MASMORRA", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 26, COLOR_WARNING)
		draw_string(font, Vector2(144.0, 214.0), "O retorno restaura 40% da vida.", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 17, COLOR_TEXT_DIM)
		draw_string(font, Vector2(144.0, 246.0), "A munição restante será preservada.", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 17, COLOR_TEXT_DIM)
		_draw_button(OVERLAY_RESTART_RECT, "REINICIAR  [ENTER]")
		_draw_button(OVERLAY_SECONDARY_RECT, "SAIR  [ESC]")
		return

	draw_string(font, Vector2(144.0, 168.0), "SAIR DA MASMORRA?", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 28, COLOR_TEXT)
	draw_string(font, Vector2(144.0, 214.0), "Todo o progresso interno será perdido.", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 17, COLOR_TEXT_DIM)
	draw_string(font, Vector2(144.0, 246.0), "Vida e munição atuais serão preservadas.", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 17, COLOR_TEXT_DIM)
	_draw_button(OVERLAY_RESTART_RECT, "SAIR  [ENTER]")
	_draw_button(OVERLAY_SECONDARY_RECT, "CONTINUAR  [ESC]")
