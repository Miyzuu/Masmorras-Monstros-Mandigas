class_name PauseMenu
extends Control

signal dungeon_exit_requested
signal resumed(paused_duration_usec: int)

enum MenuScreen {
	MAIN,
	CONTROLS,
}

const PANEL_SIZE := Vector2(600.0, 424.0)
const BUTTON_SIZE := Vector2(320.0, 50.0)

const COLOR_OVERLAY := Color(0.015, 0.01, 0.008, 0.84)
const COLOR_PANEL := Color("281d14")
const COLOR_PANEL_INNER := Color("352419")
const COLOR_BORDER := Color("705033")
const COLOR_BORDER_BRIGHT := Color("b07d47")
const COLOR_TEXT := Color("f2dfbd")
const COLOR_TEXT_DIM := Color("c2a880")
const COLOR_BUTTON := Color("74482c")
const COLOR_BUTTON_HOVER := Color("99613b")
const COLOR_DANGER := Color("81352d")
const COLOR_DANGER_HOVER := Color("a54338")

const LEFT_CONTROLS := [
	["WASD", "mover o personagem"],
	["MOUSE DIR.", "definir o destino"],
	["M", "alternar visão do mapa"],
	["Q", "trocar Rifle/Peixeira"],
	["E", "usar Lapada Seca"],
]
const RIGHT_CONTROLS := [
	["R", "recarregar o Rifle"],
	["ESPAÇO", "aparar ou confirmar"],
	["ENTER", "confirmar ação/aviso"],
	["MOUSE ESQ.", "ações do chefe"],
	["ESC", "pausar ou voltar"],
]

var dungeon_exit_available := false
var menu_open := false
var current_screen := MenuScreen.MAIN
var mouse_position := Vector2(-1000.0, -1000.0)
var can_open_callback := Callable()
var tree_was_paused := false
var paused_at_usec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	position = Vector2.ZERO
	_sync_size()
	get_viewport().size_changed.connect(_sync_size)
	visible = false
	set_process_input(true)


func configure(new_dungeon_exit_available: bool, new_can_open_callback: Callable) -> void:
	dungeon_exit_available = new_dungeon_exit_available
	can_open_callback = new_can_open_callback
	queue_redraw()


func is_menu_open() -> bool:
	return menu_open


func open_menu() -> bool:
	if menu_open or not _can_open_menu():
		return false
	tree_was_paused = get_tree().paused
	paused_at_usec = Time.get_ticks_usec()
	current_screen = MenuScreen.MAIN
	menu_open = true
	visible = true
	get_tree().paused = true
	_play_ui_sound("hover")
	queue_redraw()
	return true


func close_menu() -> void:
	if not menu_open:
		return
	var paused_duration_usec := maxi(0, Time.get_ticks_usec() - paused_at_usec)
	menu_open = false
	current_screen = MenuScreen.MAIN
	visible = false
	get_tree().paused = tree_was_paused
	_play_ui_sound("click")
	resumed.emit(paused_duration_usec)


func _can_open_menu() -> bool:
	if not can_open_callback.is_valid():
		return true
	return bool(can_open_callback.call())


func _sync_size() -> void:
	size = get_viewport_rect().size
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if not menu_open:
			if not open_menu():
				return
		elif current_screen == MenuScreen.CONTROLS:
			current_screen = MenuScreen.MAIN
			_play_ui_sound("click")
			queue_redraw()
		else:
			close_menu()
		get_viewport().set_input_as_handled()
		return

	if not menu_open:
		return

	if event is InputEventMouseMotion:
		mouse_position = event.position
		queue_redraw()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if current_screen == MenuScreen.CONTROLS:
				current_screen = MenuScreen.MAIN
				_play_ui_sound("click")
				queue_redraw()
			else:
				close_menu()
		get_viewport().set_input_as_handled()


func _handle_click(click_position: Vector2) -> void:
	if current_screen == MenuScreen.CONTROLS:
		if _back_button_rect().has_point(click_position):
			current_screen = MenuScreen.MAIN
			_play_ui_sound("click")
			queue_redraw()
		return

	var button_rects := _main_button_rects()
	if button_rects["continue"].has_point(click_position):
		close_menu()
	elif button_rects["settings"].has_point(click_position):
		current_screen = MenuScreen.CONTROLS
		_play_ui_sound("click")
		queue_redraw()
	elif dungeon_exit_available and button_rects["exit"].has_point(click_position):
		close_menu()
		dungeon_exit_requested.emit()


func _draw() -> void:
	if not menu_open:
		return
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_OVERLAY, true)
	var panel_rect := _panel_rect()
	draw_rect(panel_rect, COLOR_PANEL, true)
	draw_rect(panel_rect, COLOR_BORDER, false, 3.0)
	if current_screen == MenuScreen.CONTROLS:
		_draw_controls_screen(panel_rect)
	else:
		_draw_main_screen(panel_rect)


func _draw_main_screen(panel_rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(panel_rect.position.x, panel_rect.position.y + 66.0),
		"JOGO PAUSADO",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		30,
		COLOR_TEXT
	)
	draw_string(
		font,
		Vector2(panel_rect.position.x, panel_rect.position.y + 94.0),
		"Monstros, Masmorras e Mandingas",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		14,
		COLOR_TEXT_DIM
	)

	var button_rects := _main_button_rects()
	_draw_button(button_rects["continue"], "CONTINUAR")
	_draw_button(button_rects["settings"], "CONFIGURAÇÕES")
	if dungeon_exit_available:
		_draw_button(button_rects["exit"], "SAIR DA MASMORRA", true)

	draw_string(
		font,
		Vector2(panel_rect.position.x, panel_rect.end.y - 28.0),
		"Esc ou Enter — continuar",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		13,
		COLOR_TEXT_DIM
	)


func _draw_controls_screen(panel_rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(panel_rect.position.x, panel_rect.position.y + 48.0),
		"CONFIGURAÇÕES",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		25,
		COLOR_TEXT
	)
	draw_string(
		font,
		Vector2(panel_rect.position.x, panel_rect.position.y + 78.0),
		"CONTROLES",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		16,
		COLOR_BORDER_BRIGHT
	)

	var controls_rect := Rect2(panel_rect.position + Vector2(26.0, 96.0), Vector2(548.0, 244.0))
	draw_rect(controls_rect, COLOR_PANEL_INNER, true)
	draw_rect(controls_rect, COLOR_BORDER, false, 2.0)
	_draw_control_column(LEFT_CONTROLS, controls_rect.position + Vector2(18.0, 36.0), 246.0)
	_draw_control_column(RIGHT_CONTROLS, controls_rect.position + Vector2(284.0, 36.0), 246.0)
	draw_line(
		controls_rect.position + Vector2(274.0, 16.0),
		controls_rect.position + Vector2(274.0, controls_rect.size.y - 16.0),
		COLOR_BORDER,
		1.0
	)
	_draw_button(_back_button_rect(), "VOLTAR")


func _draw_control_column(entries: Array, start_position: Vector2, column_width: float) -> void:
	var font := ThemeDB.fallback_font
	for index in range(entries.size()):
		var entry: Array = entries[index]
		var baseline := start_position.y + float(index) * 39.0
		draw_string(
			font,
			Vector2(start_position.x, baseline),
			"%s  —  %s" % [entry[0], entry[1]],
			HORIZONTAL_ALIGNMENT_LEFT,
			column_width,
			13,
			COLOR_TEXT if index % 2 == 0 else COLOR_TEXT_DIM
		)


func _draw_button(rect: Rect2, label: String, danger: bool = false) -> void:
	var hovered := rect.has_point(mouse_position)
	var fill_color := COLOR_DANGER if danger else COLOR_BUTTON
	if hovered:
		fill_color = COLOR_DANGER_HOVER if danger else COLOR_BUTTON_HOVER
	draw_rect(rect, fill_color, true)
	draw_rect(rect, COLOR_BORDER_BRIGHT if hovered else COLOR_BORDER, false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5 + 6.0),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		16,
		COLOR_TEXT
	)


func _panel_rect() -> Rect2:
	return Rect2((size - PANEL_SIZE) * 0.5, PANEL_SIZE)


func _main_button_rects() -> Dictionary:
	var button_x := (size.x - BUTTON_SIZE.x) * 0.5
	if dungeon_exit_available:
		return {
			"continue": Rect2(Vector2(button_x, 166.0), BUTTON_SIZE),
			"settings": Rect2(Vector2(button_x, 230.0), BUTTON_SIZE),
			"exit": Rect2(Vector2(button_x, 294.0), BUTTON_SIZE),
		}
	return {
		"continue": Rect2(Vector2(button_x, 198.0), BUTTON_SIZE),
		"settings": Rect2(Vector2(button_x, 262.0), BUTTON_SIZE),
		"exit": Rect2(),
	}


func _back_button_rect() -> Rect2:
	return Rect2(Vector2((size.x - 240.0) * 0.5, 414.0), Vector2(240.0, 42.0))


func _play_ui_sound(sound_name: String) -> void:
	if not is_inside_tree() or not get_tree().root.has_node("AudioManager"):
		return
	var audio_manager := get_tree().root.get_node("AudioManager")
	if sound_name == "hover":
		audio_manager.call("play_ui_hover")
	else:
		audio_manager.call("play_ui_click")
