extends Node2D

const GridRulesScript = preload("res://scripts/grid_rules.gd")

enum AttackType {
	NONE,
	RIFLE,
	KNIFE,
}

const VIEWPORT_SIZE := Vector2(768.0, 512.0)
const BOARD_SIZE := Vector2i(10, 10)
const TILE_SIZE := 32
const BOARD_ORIGIN := Vector2(32.0, 96.0)
const HERO_START := Vector2i(1, 8)
const CAPANGA_START := Vector2i(8, 1)
const HERO_MAX_HP := 100
const CAPANGA_MAX_HP := 60
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
const FADE_DURATION := 0.5
const EXPLORATION_SCENE := "res://scenes/exploration.tscn"

const RIFLE_RECT := Rect2(416.0, 282.0, 136.0, 42.0)
const KNIFE_RECT := Rect2(568.0, 282.0, 136.0, 42.0)
const END_TURN_RECT := Rect2(416.0, 332.0, 288.0, 40.0)
const RESET_RECT := Rect2(416.0, 380.0, 288.0, 40.0)
const HERO_STATUS_RECT := Rect2(32.0, 464.0, 704.0, 24.0)

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

@onready var fade: ColorRect = $FadeLayer/Fade


func _ready() -> void:
	game_version = str(ProjectSettings.get_setting("application/config/version", "V.0.0.0"))
	fade.modulate.a = 1.0
	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 0.0, FADE_DURATION)
	_rebuild_reachable()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if encounter_transitioning:
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
		elif RESET_RECT.has_point(event.position):
			_reset_combat("Encontro reiniciado.")
		else:
			var target_cell := _screen_to_cell(event.position)
			if target_cell == capanga_cell and capanga_hp > 0:
				_attempt_attack(selected_attack)
			elif selected_attack != AttackType.NONE:
				notice = "Clique no Capanga para usar o ataque selecionado."
			else:
				_try_move_to(target_cell)
		queue_redraw()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_end_player_turn("Turno encerrado sem ataque.")
		elif event.keycode == KEY_R:
			_reset_combat("Encontro reiniciado.")
		queue_redraw()


func _select_attack(attack_type: int) -> void:
	if not player_turn:
		return

	selected_attack = attack_type
	if selected_attack == AttackType.RIFLE:
		notice = "Disparo selecionado — clique no Capanga."
	else:
		notice = "Peixeira selecionada — clique no Capanga."


func _try_move_to(target: Vector2i) -> void:
	if not player_turn:
		return
	if not GridRulesScript.is_inside(target, BOARD_SIZE):
		return
	if target == hero_cell:
		notice = "O Cangaceiro já ocupa essa casa."
		return
	if target == capanga_cell and capanga_hp > 0:
		notice = "A casa do Capanga está ocupada."
		return
	if not reachable.has(target):
		notice = "Casa fora do alcance ou caminho bloqueado."
		return

	var distance := int(reachable[target])
	hero_cell = target
	movement_left -= distance
	selected_attack = AttackType.NONE
	notice = "Movimento realizado: %d casa(s)." % distance
	_rebuild_reachable()
	_update_hover(mouse_position)


func _attempt_attack(
	attack_type: int,
	hit_roll: float = -1.0,
	critical_roll: float = -1.0
) -> bool:
	if not player_turn or capanga_hp <= 0:
		return false
	if attack_type == AttackType.NONE:
		notice = "Selecione Disparo ou Peixeira primeiro."
		return false

	var distance := _orthogonal_distance(hero_cell, capanga_cell)
	if attack_type == AttackType.RIFLE:
		if distance > RIFLE_RANGE:
			notice = "Capanga fora do alcance de 7 casas."
			return false
		if _line_crosses_wall(hero_cell, capanga_cell):
			notice = "A parede bloqueia o Disparo."
			return false
	elif attack_type == AttackType.KNIFE:
		if distance > KNIFE_RANGE:
			notice = "A Peixeira exige uma casa de distância."
			return false
	else:
		return false

	var result_text := ""
	if attack_type == AttackType.RIFLE:
		var rifle_result := _resolve_rifle(hit_roll, critical_roll)
		var rifle_damage := int(rifle_result["damage"])
		capanga_hp = maxi(0, capanga_hp - rifle_damage)
		if not bool(rifle_result["hit"]):
			result_text = "Errou."
		elif bool(rifle_result["critical"]):
			result_text = "Crítico: 40 de dano."
		else:
			result_text = "Dano: 25."
	else:
		capanga_hp = maxi(0, capanga_hp - KNIFE_DAMAGE)
		result_text = "Peixeira: 20 de dano."

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
	selected_attack = AttackType.NONE
	var enemy_result := _run_capanga_action()
	if hero_hp <= 0:
		_reset_combat("Derrota — encontro reiniciado com vida cheia.")
		return

	round_number += 1
	movement_left = HERO_MOVEMENT
	player_turn = true
	notice = "%s %s" % [player_result, enemy_result]
	_rebuild_reachable()
	_update_hover(mouse_position)


func _run_capanga_action() -> String:
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
	encounter_transitioning = true
	player_turn = false
	GameState.complete_active_encounter()
	notice = "%s Capanga derrotado — retornando à exploração." % attack_result

	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, FADE_DURATION)
	fade_tween.tween_callback(_return_to_exploration)


func _return_to_exploration() -> void:
	get_tree().change_scene_to_file(EXPLORATION_SCENE)


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

	if selected_attack != AttackType.NONE:
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
	_draw_header()
	_draw_board()
	_draw_side_panel()
	_draw_hero_status()


func _draw_header() -> void:
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(32.0, 42.0),
		"PINDORAMA FANTÁSTICA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		24,
		COLOR_TEXT
	)
	draw_string(
		font,
		Vector2(32.0, 68.0),
		"Protótipo 01 — combate básico • %s" % game_version,
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
	var body_rect := Rect2(cell_rect.position + Vector2(6.0, 8.0), Vector2(20.0, 19.0))
	draw_rect(body_rect, COLOR_ENEMY_COAT, true)
	draw_rect(Rect2(cell_rect.position + Vector2(4.0, 13.0), Vector2(24.0, 9.0)), COLOR_ENEMY_ARMOR, true)
	draw_rect(Rect2(cell_rect.position + Vector2(5.0, 6.0), Vector2(22.0, 5.0)), COLOR_ENEMY_HAT, true)
	draw_rect(Rect2(cell_rect.position + Vector2(9.0, 2.0), Vector2(14.0, 6.0)), COLOR_ENEMY_HAT, true)

	var health_rect := Rect2(cell_rect.position + Vector2(3.0, -5.0), Vector2(26.0, 5.0))
	draw_rect(health_rect, COLOR_HEALTH_BACKGROUND, true)
	var health_width := health_rect.size.x * float(capanga_hp) / float(CAPANGA_MAX_HP)
	draw_rect(Rect2(health_rect.position, Vector2(health_width, health_rect.size.y)), COLOR_ENEMY_HEALTH_FILL, true)
	draw_rect(health_rect, COLOR_BACKGROUND, false, 1.0)


func _draw_side_panel() -> void:
	var font := ThemeDB.fallback_font
	var panel_rect := Rect2(384.0, 96.0, 352.0, 340.0)
	draw_rect(panel_rect, COLOR_PANEL, true)
	draw_rect(panel_rect, COLOR_PANEL_BORDER, false, 2.0)

	draw_string(font, Vector2(416.0, 130.0), "ENCONTRO: CAPANGA", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, COLOR_TEXT)
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
		"Capanga: %d / %d HP" % [capanga_hp, CAPANGA_MAX_HP],
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
	draw_string(font, Vector2(416.0, 236.0), "Ataque: %s" % attack_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, COLOR_TEXT_DIM)
	draw_string(font, Vector2(416.0, 264.0), notice, HORIZONTAL_ALIGNMENT_LEFT, 288.0, 12, COLOR_TEXT_DIM)

	_draw_button(RIFLE_RECT, "DISPARO", selected_attack == AttackType.RIFLE)
	_draw_button(KNIFE_RECT, "PEIXEIRA", selected_attack == AttackType.KNIFE)
	_draw_button(END_TURN_RECT, "ENCERRAR TURNO  [ENTER]")
	_draw_button(RESET_RECT, "REINICIAR  [R]")


func _draw_button(rect: Rect2, label: String, selected: bool = false) -> void:
	var font := ThemeDB.fallback_font
	var color := COLOR_BUTTON
	if selected:
		color = COLOR_BUTTON_SELECTED
	elif rect.has_point(mouse_position):
		color = COLOR_BUTTON_HOVER
	draw_rect(rect, color, true)
	draw_rect(rect, COLOR_PANEL_BORDER, false, 2.0)
	draw_string(
		font,
		Vector2(rect.position.x, rect.position.y + 27.0),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		14,
		COLOR_TEXT
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
