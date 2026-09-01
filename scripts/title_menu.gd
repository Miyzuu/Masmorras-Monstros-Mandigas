extends Control

enum Screen {
	MAIN,
	SLOTS,
	SETTINGS,
	CONTROLS,
	AUDIO,
	VIDEO,
}

enum SlotMode {
	NEW_GAME,
	CONTINUE,
}

const COLOR_BACKGROUND := Color("120d09")
const COLOR_PANEL := Color("281d14")
const COLOR_PANEL_INNER := Color("352419")
const COLOR_BORDER := Color("705033")
const COLOR_BORDER_BRIGHT := Color("b07d47")
const COLOR_TEXT := Color("f2dfbd")
const COLOR_TEXT_DIM := Color("c2a880")
const COLOR_BUTTON := Color("74482c")
const COLOR_BUTTON_HOVER := Color("99613b")
const COLOR_DISABLED := Color("3a3028")
const COLOR_DANGER := Color("81352d")
const COLOR_DANGER_HOVER := Color("a54338")
const COLOR_ACCENT := Color("45d6b3")
const COLOR_OVERLAY := Color(0.01, 0.007, 0.005, 0.88)

const CONTROLS_LEFT := [
	["WASD", "mover o personagem"],
	["MOUSE DIR.", "definir o destino"],
	["M", "alternar visão do mapa"],
	["Q", "trocar Rifle/Peixeira"],
	["E", "usar Lapada Seca"],
]
const CONTROLS_RIGHT := [
	["R", "recarregar o Rifle"],
	["ESPAÇO", "aparar ou confirmar"],
	["ENTER", "confirmar ação/aviso"],
	["MOUSE ESQ.", "ações do chefe"],
	["ESC", "pausar ou voltar"],
]

var current_screen := Screen.MAIN
var slot_mode := SlotMode.NEW_GAME
var mouse_position := Vector2(-1000.0, -1000.0)
var confirmation_action := ""
var confirmation_slot := 0
var status_message := ""
var dragging_audio_setting := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	get_viewport().size_changed.connect(queue_redraw)
	set_process_input(true)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position = event.position
		if not dragging_audio_setting.is_empty():
			_set_audio_from_position(
				dragging_audio_setting,
				_audio_slider_rect(dragging_audio_setting),
				event.position.x
			)
		queue_redraw()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var input_viewport := get_viewport()
		if input_viewport != null:
			input_viewport.set_input_as_handled()
		if event.pressed:
			_handle_click(event.position)
		else:
			dragging_audio_setting = ""
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if not confirmation_action.is_empty():
			var confirmation_viewport := get_viewport()
			if confirmation_viewport != null:
				confirmation_viewport.set_input_as_handled()
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				_execute_confirmation()
			elif event.keycode == KEY_ESCAPE:
				_cancel_confirmation()
			return
		if event.keycode == KEY_ESCAPE:
			var escape_viewport := get_viewport()
			if escape_viewport != null:
				escape_viewport.set_input_as_handled()
			_go_back()


func _handle_click(click_position: Vector2) -> void:
	if not confirmation_action.is_empty():
		if _confirmation_yes_rect().has_point(click_position):
			_execute_confirmation()
		elif _confirmation_no_rect().has_point(click_position):
			_cancel_confirmation()
		return

	match current_screen:
		Screen.MAIN:
			_handle_main_click(click_position)
		Screen.SLOTS:
			_handle_slots_click(click_position)
		Screen.SETTINGS:
			_handle_settings_click(click_position)
		Screen.CONTROLS:
			if _back_button_rect().has_point(click_position):
				current_screen = Screen.SETTINGS
				_play_ui_click()
		Screen.AUDIO:
			_handle_audio_click(click_position)
		Screen.VIDEO:
			_handle_video_click(click_position)
	queue_redraw()


func _handle_main_click(click_position: Vector2) -> void:
	var buttons := _main_button_rects()
	if buttons["new_game"].has_point(click_position):
		slot_mode = SlotMode.NEW_GAME
		current_screen = Screen.SLOTS
		status_message = "Escolha um slot para iniciar."
		_play_ui_click()
	elif buttons["continue"].has_point(click_position) and SaveManager.has_any_save():
		slot_mode = SlotMode.CONTINUE
		current_screen = Screen.SLOTS
		status_message = "Escolha um save existente."
		_play_ui_click()
	elif buttons["settings"].has_point(click_position):
		current_screen = Screen.SETTINGS
		status_message = ""
		_play_ui_click()
	elif buttons["exit"].has_point(click_position):
		_play_ui_click()
		if OS.has_feature("web"):
			status_message = "Você pode fechar esta aba."
		else:
			get_tree().quit()


func _handle_slots_click(click_position: Vector2) -> void:
	if _back_button_rect().has_point(click_position):
		current_screen = Screen.MAIN
		status_message = ""
		_play_ui_click()
		return

	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		var summary := SaveManager.get_slot_summary(slot)
		if bool(summary.get("exists", false)) and _slot_delete_rect(slot).has_point(click_position):
			_request_confirmation("delete", slot)
			return
		if not _slot_rect(slot).has_point(click_position):
			continue
		if slot_mode == SlotMode.NEW_GAME:
			if bool(summary.get("exists", false)):
				_request_confirmation("overwrite", slot)
			else:
				_start_new_game(slot)
		elif bool(summary.get("exists", false)) and bool(summary.get("valid", false)):
			_continue_game(slot)
		return


func _handle_settings_click(click_position: Vector2) -> void:
	var buttons := _settings_button_rects()
	if buttons["controls"].has_point(click_position):
		current_screen = Screen.CONTROLS
		_play_ui_click()
	elif buttons["audio"].has_point(click_position):
		current_screen = Screen.AUDIO
		_play_ui_click()
	elif buttons["video"].has_point(click_position):
		current_screen = Screen.VIDEO
		_play_ui_click()
	elif _back_button_rect().has_point(click_position):
		current_screen = Screen.MAIN
		_play_ui_click()


func _handle_audio_click(click_position: Vector2) -> void:
	if _back_button_rect().has_point(click_position):
		current_screen = Screen.SETTINGS
		dragging_audio_setting = ""
		_play_ui_click()
		return
	for setting_name in ["master", "music", "effects"]:
		var slider_rect := _audio_slider_rect(setting_name)
		if slider_rect.grow(8.0).has_point(click_position):
			dragging_audio_setting = setting_name
			_set_audio_from_position(setting_name, slider_rect, click_position.x)
			_play_ui_click()
			return


func _handle_video_click(click_position: Vector2) -> void:
	if _back_button_rect().has_point(click_position):
		current_screen = Screen.SETTINGS
		_play_ui_click()
		return
	if OS.has_feature("web"):
		return
	var buttons := _video_button_rects()
	if buttons["fullscreen"].has_point(click_position):
		SaveManager.set_fullscreen_enabled(not SaveManager.fullscreen_enabled)
		_play_ui_click()
	elif buttons["vsync"].has_point(click_position):
		SaveManager.set_vsync_enabled(not SaveManager.vsync_enabled)
		_play_ui_click()


func _go_back() -> void:
	match current_screen:
		Screen.MAIN:
			return
		Screen.SLOTS, Screen.SETTINGS:
			current_screen = Screen.MAIN
		_:
			current_screen = Screen.SETTINGS
	status_message = ""
	dragging_audio_setting = ""
	_play_ui_click()
	queue_redraw()


func _request_confirmation(action: String, slot: int) -> void:
	confirmation_action = action
	confirmation_slot = slot
	_play_ui_click()
	queue_redraw()


func _cancel_confirmation() -> void:
	confirmation_action = ""
	confirmation_slot = 0
	_play_ui_click()
	queue_redraw()


func _execute_confirmation() -> void:
	var action := confirmation_action
	var slot := confirmation_slot
	confirmation_action = ""
	confirmation_slot = 0
	if action == "overwrite":
		_start_new_game(slot)
	elif action == "delete":
		if SaveManager.delete_slot(slot):
			status_message = "Slot %d apagado." % slot
		else:
			status_message = "Não foi possível apagar o slot %d." % slot
		_play_ui_click()
		queue_redraw()


func _start_new_game(slot: int) -> void:
	if not SaveManager.create_new_game(slot):
		status_message = "Não foi possível criar o save no slot %d." % slot
		queue_redraw()
		return
	_play_ui_click()
	get_tree().change_scene_to_file(SaveManager.EXPLORATION_SCENE)


func _continue_game(slot: int) -> void:
	var scene_path := SaveManager.load_slot(slot)
	if scene_path.is_empty():
		status_message = "Não foi possível carregar o slot %d." % slot
		queue_redraw()
		return
	_play_ui_click()
	get_tree().change_scene_to_file(scene_path)


func _set_audio_from_position(setting_name: String, slider_rect: Rect2, position_x: float) -> void:
	var value := clampf((position_x - slider_rect.position.x) / slider_rect.size.x, 0.0, 1.0)
	SaveManager.set_audio_setting(setting_name, value)
	queue_redraw()


func _play_ui_click() -> void:
	if is_inside_tree() and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").call("play_ui_click")


func _draw() -> void:
	_draw_background()
	_draw_panel()
	match current_screen:
		Screen.MAIN: _draw_main_screen()
		Screen.SLOTS: _draw_slots_screen()
		Screen.SETTINGS: _draw_settings_screen()
		Screen.CONTROLS: _draw_controls_screen()
		Screen.AUDIO: _draw_audio_screen()
		Screen.VIDEO: _draw_video_screen()
	_draw_status()
	_draw_version_watermark()
	if not confirmation_action.is_empty():
		_draw_confirmation()


func _draw_background() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), COLOR_BACKGROUND, true)
	for offset in range(-int(viewport_size.y), int(viewport_size.x), 48):
		draw_line(
			Vector2(float(offset), viewport_size.y),
			Vector2(float(offset) + viewport_size.y, 0.0),
			Color(0.44, 0.31, 0.20, 0.07),
			1.0
		)


func _draw_panel() -> void:
	var panel := _panel_rect()
	draw_rect(panel, COLOR_PANEL, true)
	draw_rect(panel, COLOR_BORDER, false, 3.0)
	draw_rect(panel.grow(-7.0), COLOR_BORDER, false, 1.0)


func _draw_main_screen() -> void:
	var panel := _panel_rect()
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(panel.position.x, panel.position.y + 66.0), "3M", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 44, COLOR_BORDER_BRIGHT)
	draw_string(
		font,
		Vector2(panel.position.x, panel.position.y + 99.0),
		"MONSTROS MASMORRAS & MANDINGAS",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel.size.x,
		20,
		COLOR_TEXT
	)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 126.0), "PINDORAMA FANTÁSTICA", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 13, COLOR_TEXT_DIM)
	var buttons := _main_button_rects()
	_draw_button(buttons["new_game"], "NOVO JOGO")
	_draw_button(buttons["continue"], "CONTINUAR", SaveManager.has_any_save())
	_draw_button(buttons["settings"], "CONFIGURAÇÕES")
	_draw_button(buttons["exit"], "SAIR")


func _draw_slots_screen() -> void:
	var panel := _panel_rect()
	var font := ThemeDB.fallback_font
	var heading := "NOVO JOGO — ESCOLHA O SLOT" if slot_mode == SlotMode.NEW_GAME else "CONTINUAR — ESCOLHA O SLOT"
	draw_string(font, Vector2(panel.position.x, panel.position.y + 48.0), heading, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 23, COLOR_TEXT)
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		_draw_slot(slot, SaveManager.get_slot_summary(slot))
	_draw_button(_back_button_rect(), "VOLTAR")


func _draw_slot(slot: int, summary: Dictionary) -> void:
	var rect := _slot_rect(slot)
	var exists := bool(summary.get("exists", false))
	var valid := bool(summary.get("valid", false))
	var selectable := slot_mode == SlotMode.NEW_GAME or (exists and valid)
	var hovered := rect.has_point(mouse_position) and selectable
	draw_rect(rect, COLOR_BUTTON_HOVER if hovered else (COLOR_PANEL_INNER if selectable else COLOR_DISABLED), true)
	draw_rect(rect, COLOR_BORDER_BRIGHT if hovered else COLOR_BORDER, false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, rect.position + Vector2(18.0, 25.0), "SLOT %d" % slot, HORIZONTAL_ALIGNMENT_LEFT, 112.0, 17, COLOR_TEXT)
	if not exists:
		draw_string(font, rect.position + Vector2(132.0, 32.0), "VAZIO", HORIZONTAL_ALIGNMENT_LEFT, 260.0, 17, COLOR_TEXT_DIM)
	else:
		draw_string(font, rect.position + Vector2(132.0, 24.0), str(summary.get("local", "")), HORIZONTAL_ALIGNMENT_LEFT, 270.0, 15, COLOR_TEXT if valid else COLOR_DANGER_HOVER)
		draw_string(font, rect.position + Vector2(132.0, 50.0), str(summary.get("saved_at", "")), HORIZONTAL_ALIGNMENT_LEFT, 270.0, 13, COLOR_TEXT_DIM)
		_draw_button(_slot_delete_rect(slot), "APAGAR", true, true)


func _draw_settings_screen() -> void:
	var panel := _panel_rect()
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(panel.position.x, panel.position.y + 58.0), "CONFIGURAÇÕES", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 27, COLOR_TEXT)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 86.0), "Alterações aplicadas e salvas imediatamente", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 13, COLOR_TEXT_DIM)
	var buttons := _settings_button_rects()
	_draw_button(buttons["controls"], "CONTROLES")
	_draw_button(buttons["audio"], "ÁUDIO")
	_draw_button(buttons["video"], "VÍDEO")
	_draw_button(_back_button_rect(), "VOLTAR")


func _draw_controls_screen() -> void:
	var panel := _panel_rect()
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(panel.position.x, panel.position.y + 48.0), "CONFIGURAÇÕES — CONTROLES", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 22, COLOR_TEXT)
	var controls_rect := Rect2(panel.position + Vector2(34.0, 76.0), Vector2(panel.size.x - 68.0, 278.0))
	draw_rect(controls_rect, COLOR_PANEL_INNER, true)
	draw_rect(controls_rect, COLOR_BORDER, false, 2.0)
	_draw_control_column(CONTROLS_LEFT, controls_rect.position + Vector2(18.0, 42.0), 270.0)
	_draw_control_column(CONTROLS_RIGHT, controls_rect.position + Vector2(308.0, 42.0), 270.0)
	draw_line(controls_rect.position + Vector2(298.0, 18.0), controls_rect.position + Vector2(298.0, 258.0), COLOR_BORDER, 1.0)
	_draw_button(_back_button_rect(), "VOLTAR")


func _draw_control_column(entries: Array, start: Vector2, width: float) -> void:
	var font := ThemeDB.fallback_font
	for index in range(entries.size()):
		var entry: Array = entries[index]
		draw_string(font, start + Vector2(0.0, float(index) * 45.0), "%s  —  %s" % [entry[0], entry[1]], HORIZONTAL_ALIGNMENT_LEFT, width, 13, COLOR_TEXT if index % 2 == 0 else COLOR_TEXT_DIM)


func _draw_audio_screen() -> void:
	var panel := _panel_rect()
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(panel.position.x, panel.position.y + 54.0), "CONFIGURAÇÕES — ÁUDIO", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 23, COLOR_TEXT)
	var values := {
		"master": SaveManager.master_volume,
		"music": SaveManager.music_volume,
		"effects": SaveManager.effects_volume,
	}
	var labels := {"master": "GERAL", "music": "MÚSICA", "effects": "EFEITOS"}
	for setting_name in ["master", "music", "effects"]:
		var rect := _audio_slider_rect(setting_name)
		var value := float(values[setting_name])
		draw_string(font, rect.position + Vector2(-142.0, 9.0), labels[setting_name], HORIZONTAL_ALIGNMENT_LEFT, 120.0, 16, COLOR_TEXT)
		draw_rect(rect, COLOR_DISABLED, true)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * value, rect.size.y)), COLOR_ACCENT, true)
		draw_rect(rect, COLOR_BORDER, false, 2.0)
		draw_circle(Vector2(rect.position.x + rect.size.x * value, rect.get_center().y), 8.0, COLOR_TEXT)
		draw_string(font, rect.position + Vector2(rect.size.x + 20.0, 9.0), "%d%%" % roundi(value * 100.0), HORIZONTAL_ALIGNMENT_LEFT, 60.0, 15, COLOR_TEXT_DIM)
	_draw_button(_back_button_rect(), "VOLTAR")


func _draw_video_screen() -> void:
	var panel := _panel_rect()
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(panel.position.x, panel.position.y + 54.0), "CONFIGURAÇÕES — VÍDEO", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 23, COLOR_TEXT)
	var web_build := OS.has_feature("web")
	var buttons := _video_button_rects()
	_draw_button(buttons["fullscreen"], "TELA CHEIA: %s" % ("NAVEGADOR" if web_build else ("SIM" if SaveManager.fullscreen_enabled else "NÃO")), not web_build)
	_draw_button(buttons["vsync"], "VSYNC: %s" % ("NAVEGADOR" if web_build else ("LIGADO" if SaveManager.vsync_enabled else "DESLIGADO")), not web_build)
	var info_rect := Rect2(panel.position + Vector2(90.0, 280.0), Vector2(panel.size.x - 180.0, 72.0))
	draw_rect(info_rect, COLOR_PANEL_INNER, true)
	draw_rect(info_rect, COLOR_BORDER, false, 2.0)
	draw_string(font, info_rect.position + Vector2(0.0, 28.0), "RESOLUÇÃO AUTOMÁTICA", HORIZONTAL_ALIGNMENT_CENTER, info_rect.size.x, 15, COLOR_TEXT)
	draw_string(font, info_rect.position + Vector2(0.0, 51.0), "A interface acompanha a janela ou a aba do navegador.", HORIZONTAL_ALIGNMENT_CENTER, info_rect.size.x, 13, COLOR_TEXT_DIM)
	_draw_button(_back_button_rect(), "VOLTAR")


func _draw_status() -> void:
	if status_message.is_empty():
		return
	var viewport_size := get_viewport_rect().size
	draw_string(ThemeDB.fallback_font, Vector2(0.0, viewport_size.y - 18.0), status_message, HORIZONTAL_ALIGNMENT_CENTER, viewport_size.x, 13, COLOR_TEXT_DIM)


func _draw_version_watermark() -> void:
	var viewport_size := get_viewport_rect().size
	var version := str(ProjectSettings.get_setting("application/config/version", "V.0.0.0"))
	draw_string(ThemeDB.fallback_font, Vector2(viewport_size.x - 118.0, viewport_size.y - 14.0), version, HORIZONTAL_ALIGNMENT_RIGHT, 104.0, 12, COLOR_TEXT_DIM)


func _draw_confirmation() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), COLOR_OVERLAY, true)
	var dialog := _confirmation_rect()
	draw_rect(dialog, COLOR_PANEL, true)
	draw_rect(dialog, COLOR_BORDER_BRIGHT, false, 3.0)
	var font := ThemeDB.fallback_font
	var title := "SOBRESCREVER SLOT %d?" % confirmation_slot if confirmation_action == "overwrite" else "APAGAR SLOT %d?" % confirmation_slot
	var message := "O progresso existente será substituído." if confirmation_action == "overwrite" else "Este save será apagado permanentemente."
	draw_string(font, dialog.position + Vector2(0.0, 50.0), title, HORIZONTAL_ALIGNMENT_CENTER, dialog.size.x, 22, COLOR_TEXT)
	draw_string(font, dialog.position + Vector2(0.0, 86.0), message, HORIZONTAL_ALIGNMENT_CENTER, dialog.size.x, 14, COLOR_TEXT_DIM)
	_draw_button(_confirmation_yes_rect(), "SIM  [ENTER]", true, true)
	_draw_button(_confirmation_no_rect(), "NÃO  [ESC]")


func _draw_button(rect: Rect2, label: String, enabled: bool = true, danger: bool = false) -> void:
	var hovered := enabled and rect.has_point(mouse_position)
	var fill := COLOR_DISABLED
	if enabled:
		fill = COLOR_DANGER if danger else COLOR_BUTTON
		if hovered:
			fill = COLOR_DANGER_HOVER if danger else COLOR_BUTTON_HOVER
	draw_rect(rect, fill, true)
	draw_rect(rect, COLOR_BORDER_BRIGHT if hovered else COLOR_BORDER, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5 + 6.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 15, COLOR_TEXT if enabled else COLOR_TEXT_DIM.darkened(0.35))


func _panel_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size
	var panel_size := Vector2(minf(680.0, viewport_size.x - 32.0), minf(438.0, viewport_size.y - 48.0))
	return Rect2((viewport_size - panel_size) * 0.5, panel_size)


func _main_button_rects() -> Dictionary:
	var panel := _panel_rect()
	var x := panel.get_center().x - 170.0
	return {
		"new_game": Rect2(Vector2(x, panel.position.y + 150.0), Vector2(340.0, 48.0)),
		"continue": Rect2(Vector2(x, panel.position.y + 208.0), Vector2(340.0, 48.0)),
		"settings": Rect2(Vector2(x, panel.position.y + 266.0), Vector2(340.0, 48.0)),
		"exit": Rect2(Vector2(x, panel.position.y + 324.0), Vector2(340.0, 48.0)),
	}


func _slot_rect(slot: int) -> Rect2:
	var panel := _panel_rect()
	return Rect2(panel.position + Vector2(48.0, 72.0 + float(slot - 1) * 94.0), Vector2(panel.size.x - 96.0, 76.0))


func _slot_delete_rect(slot: int) -> Rect2:
	var slot_rect := _slot_rect(slot)
	return Rect2(slot_rect.end - Vector2(108.0, 55.0), Vector2(92.0, 36.0))


func _settings_button_rects() -> Dictionary:
	var panel := _panel_rect()
	var x := panel.get_center().x - 170.0
	return {
		"controls": Rect2(Vector2(x, panel.position.y + 124.0), Vector2(340.0, 52.0)),
		"audio": Rect2(Vector2(x, panel.position.y + 190.0), Vector2(340.0, 52.0)),
		"video": Rect2(Vector2(x, panel.position.y + 256.0), Vector2(340.0, 52.0)),
	}


func _audio_slider_rect(setting_name: String) -> Rect2:
	var panel := _panel_rect()
	var index := ["master", "music", "effects"].find(setting_name)
	return Rect2(panel.position + Vector2(250.0, 132.0 + float(index) * 82.0), Vector2(270.0, 18.0))


func _video_button_rects() -> Dictionary:
	var panel := _panel_rect()
	var x := panel.get_center().x - 190.0
	return {
		"fullscreen": Rect2(Vector2(x, panel.position.y + 112.0), Vector2(380.0, 56.0)),
		"vsync": Rect2(Vector2(x, panel.position.y + 186.0), Vector2(380.0, 56.0)),
	}


func _back_button_rect() -> Rect2:
	var panel := _panel_rect()
	return Rect2(Vector2(panel.get_center().x - 120.0, panel.end.y - 54.0), Vector2(240.0, 40.0))


func _confirmation_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2((viewport_size - Vector2(470.0, 220.0)) * 0.5, Vector2(470.0, 220.0))


func _confirmation_yes_rect() -> Rect2:
	var dialog := _confirmation_rect()
	return Rect2(dialog.position + Vector2(38.0, 132.0), Vector2(184.0, 50.0))


func _confirmation_no_rect() -> Rect2:
	var dialog := _confirmation_rect()
	return Rect2(dialog.position + Vector2(248.0, 132.0), Vector2(184.0, 50.0))
