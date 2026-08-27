extends Node2D

const GridRulesScript = preload("res://scripts/grid_rules.gd")

const VIEWPORT_SIZE := Vector2(768.0, 512.0)
const BOARD_SIZE := Vector2i(10, 10)
const TILE_SIZE := 32
const BOARD_ORIGIN := Vector2(32.0, 96.0)
const HERO_START := Vector2i(1, 8)
const CAPANGA_CELL := Vector2i(8, 1)
const MOVEMENT_PER_TURN := 4
const FADE_DURATION := 0.5
const EXPLORATION_SCENE := "res://scenes/exploration.tscn"

const END_TURN_RECT := Rect2(416.0, 300.0, 288.0, 40.0)
const RESET_RECT := Rect2(416.0, 348.0, 288.0, 40.0)
const WIN_RECT := Rect2(416.0, 396.0, 288.0, 40.0)

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
const COLOR_HERO_COAT := Color("94452e")
const COLOR_HERO_HAT := Color("d1a15b")
const COLOR_ENEMY_COAT := Color("4f3327")
const COLOR_ENEMY_ARMOR := Color("6f6654")
const COLOR_ENEMY_HAT := Color("33231b")
const COLOR_TEXT := Color("f2dfbd")
const COLOR_TEXT_DIM := Color("c2a880")
const COLOR_BUTTON := Color("74482c")
const COLOR_BUTTON_HOVER := Color("99613b")

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

var hero_cell := HERO_START
var movement_left := MOVEMENT_PER_TURN
var round_number := 1
var reachable: Dictionary = {}
var hovered_cell := Vector2i(-1, -1)
var preview_path: Array[Vector2i] = []
var notice := "Clique em uma casa verde para mover."
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
		if END_TURN_RECT.has_point(event.position):
			_end_turn()
		elif RESET_RECT.has_point(event.position):
			_reset_prototype()
		elif WIN_RECT.has_point(event.position):
			_complete_debug_encounter()
		else:
			_try_move_to(_screen_to_cell(event.position))
		queue_redraw()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_end_turn()
		elif event.keycode == KEY_R:
			_reset_prototype()
		queue_redraw()


func _try_move_to(target: Vector2i) -> void:
	if not GridRulesScript.is_inside(target, BOARD_SIZE):
		return
	if target == hero_cell:
		notice = "O Cangaceiro já ocupa essa casa."
		return
	if not reachable.has(target):
		notice = "Casa fora do alcance ou caminho bloqueado."
		return

	var distance := int(reachable[target])
	hero_cell = target
	movement_left -= distance
	notice = "Movimento realizado: %d casa(s)." % distance
	_rebuild_reachable()
	_update_hover(mouse_position)


func _end_turn() -> void:
	round_number += 1
	movement_left = MOVEMENT_PER_TURN
	notice = "Nova rodada. Movimento restaurado para 4 casas."
	_rebuild_reachable()
	_update_hover(mouse_position)


func _reset_prototype() -> void:
	hero_cell = HERO_START
	movement_left = MOVEMENT_PER_TURN
	round_number = 1
	notice = "Protótipo reiniciado."
	_rebuild_reachable()
	_update_hover(mouse_position)


func _complete_debug_encounter() -> void:
	if GameState.active_encounter_id.is_empty():
		notice = "Entre nesta arena pelo contato com o Capanga."
		return

	encounter_transitioning = true
	GameState.complete_active_encounter()
	notice = "Vitória simulada — retornando à exploração."

	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, FADE_DURATION)
	fade_tween.tween_callback(_return_to_exploration)


func _return_to_exploration() -> void:
	get_tree().change_scene_to_file(EXPLORATION_SCENE)


func _rebuild_reachable() -> void:
	reachable = GridRulesScript.reachable_distances(
		hero_cell,
		movement_left,
		BOARD_SIZE,
		blocked
	)


func _update_hover(screen_position: Vector2) -> void:
	hovered_cell = _screen_to_cell(screen_position)
	preview_path.clear()

	if not reachable.has(hovered_cell) or hovered_cell == hero_cell:
		return

	preview_path = GridRulesScript.shortest_path(
		hero_cell,
		hovered_cell,
		movement_left,
		BOARD_SIZE,
		blocked
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


func _cell_center(cell: Vector2i) -> Vector2:
	return _cell_rect(cell).get_center()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), COLOR_BACKGROUND, true)
	_draw_header()
	_draw_board()
	_draw_side_panel()
	_draw_status()


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
		"Protótipo 01 — grade e movimentação • %s" % game_version,
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

			if blocked.has(cell):
				_draw_rock(cell_rect)

	_draw_hero(_cell_rect(hero_cell))
	_draw_capanga(_cell_rect(CAPANGA_CELL))


func _draw_rock(cell_rect: Rect2) -> void:
	var rock_rect := cell_rect.grow(-5.0)
	draw_rect(rock_rect, COLOR_ROCK, true)
	draw_rect(Rect2(rock_rect.position, Vector2(rock_rect.size.x, 5.0)), COLOR_ROCK_LIGHT, true)
	draw_rect(rock_rect, COLOR_GRID, false, 1.0)


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


func _draw_side_panel() -> void:
	var font := ThemeDB.fallback_font
	var panel_rect := Rect2(384.0, 96.0, 352.0, 352.0)
	draw_rect(panel_rect, COLOR_PANEL, true)
	draw_rect(panel_rect, COLOR_PANEL_BORDER, false, 2.0)

	draw_string(font, Vector2(416.0, 132.0), "ENCONTRO: CAPANGA", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, COLOR_TEXT)
	draw_string(font, Vector2(416.0, 168.0), "Rodada: %d" % round_number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, COLOR_TEXT)
	draw_string(
		font,
		Vector2(416.0, 198.0),
		"Movimento restante: %d / %d" % [movement_left, MOVEMENT_PER_TURN],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		16,
		COLOR_TEXT
	)
	draw_string(font, Vector2(416.0, 234.0), "• quatro direções, sem diagonais", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, COLOR_TEXT_DIM)
	draw_string(font, Vector2(416.0, 260.0), "• rochas bloqueiam o caminho", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, COLOR_TEXT_DIM)
	draw_string(font, Vector2(416.0, 286.0), "• caminho amarelo mostra a rota", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, COLOR_TEXT_DIM)

	_draw_button(END_TURN_RECT, "ENCERRAR TURNO  [ENTER]")
	_draw_button(RESET_RECT, "REINICIAR  [R]")
	_draw_button(WIN_RECT, "VENCER ENCONTRO  [TESTE]")


func _draw_button(rect: Rect2, label: String) -> void:
	var font := ThemeDB.fallback_font
	var color := COLOR_BUTTON_HOVER if rect.has_point(mouse_position) else COLOR_BUTTON
	draw_rect(rect, color, true)
	draw_rect(rect, COLOR_PANEL_BORDER, false, 2.0)
	draw_string(
		font,
		Vector2(rect.position.x, rect.position.y + 26.0),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		15,
		COLOR_TEXT
	)


func _draw_status() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(32.0, 462.0), notice, HORIZONTAL_ALIGNMENT_LEFT, 704.0, 15, COLOR_TEXT)
	draw_string(
		font,
		Vector2(32.0, 488.0),
		"Arte temporária • nenhuma estatística de combate foi inventada nesta etapa",
		HORIZONTAL_ALIGNMENT_LEFT,
		704.0,
		13,
		COLOR_TEXT_DIM
	)
