class_name InventoryUI
extends Control

signal inventory_changed(message: String)
signal health_potion_requested
signal resumed(paused_duration_usec: int)

const ItemVisualsScript = preload("res://scripts/item_visuals.gd")

const PANEL_SIZE := Vector2(620.0, 460.0)
const EQUIPMENT_SLOT_SIZE := Vector2(52.0, 52.0)
const INVENTORY_SLOT_SIZE := Vector2(52.0, 52.0)
const INVENTORY_COLUMNS := 4
const INVENTORY_ROWS := 3
const SLOT_GAP := 8.0
const TOAST_DURATION := 2.5

const COLOR_OVERLAY := Color(0.015, 0.01, 0.008, 0.82)
const COLOR_PANEL := Color("281d14")
const COLOR_PANEL_INNER := Color("352419")
const COLOR_SLOT := Color("201710")
const COLOR_SLOT_HOVER := Color("5b3a26")
const COLOR_BORDER := Color("705033")
const COLOR_BORDER_BRIGHT := Color("b07d47")
const COLOR_TEXT := Color("f2dfbd")
const COLOR_TEXT_DIM := Color("c2a880")
const COLOR_MAGIC := Color("44d6b3")
const COLOR_HEALTH := Color("d44838")
const COLOR_GOLD := Color("e6ad37")

const SLOT_LABELS := {
	"head": "CABEÇA",
	"chest": "BUSTO",
	"legs": "PERNAS",
	"feet": "PÉS",
}

var inventory_open := false
var mouse_position := Vector2(-1000.0, -1000.0)
var can_open_callback := Callable()
var delegate_health_potion_use := false
var tree_was_paused := false
var paused_at_usec := 0
var toasts: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL
	position = Vector2.ZERO
	_sync_size()
	get_viewport().size_changed.connect(_sync_size)
	GameState.inventory_changed.connect(_on_state_changed)
	GameState.equipment_changed.connect(_on_state_changed)
	set_process(true)
	set_process_input(true)
	queue_redraw()


func configure(
	new_can_open_callback: Callable,
	new_delegate_health_potion_use: bool = false
) -> void:
	can_open_callback = new_can_open_callback
	delegate_health_potion_use = new_delegate_health_potion_use


func is_inventory_open() -> bool:
	return inventory_open


func open_inventory() -> bool:
	if inventory_open or not _can_open_inventory():
		return false
	tree_was_paused = get_tree().paused
	paused_at_usec = Time.get_ticks_usec()
	inventory_open = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = true
	_play_ui_sound("hover")
	queue_redraw()
	return true


func close_inventory() -> void:
	if not inventory_open:
		return
	var paused_duration_usec := maxi(0, Time.get_ticks_usec() - paused_at_usec)
	inventory_open = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().paused = tree_was_paused
	_play_ui_sound("click")
	queue_redraw()
	resumed.emit(paused_duration_usec)


func show_notification(message: String, item_id: String = "") -> void:
	if message.is_empty():
		return
	toasts.append({
		"message": message,
		"item_id": item_id,
		"elapsed": 0.0,
		"duration": TOAST_DURATION,
	})
	while toasts.size() > 4:
		toasts.remove_at(0)
	queue_redraw()


func _can_open_inventory() -> bool:
	if not can_open_callback.is_valid():
		return true
	return bool(can_open_callback.call())


func _sync_size() -> void:
	size = get_viewport_rect().size
	queue_redraw()


func _on_state_changed() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	var changed := false
	for index in range(toasts.size() - 1, -1, -1):
		var toast := toasts[index]
		toast["elapsed"] = float(toast.get("elapsed", 0.0)) + maxf(0.0, delta)
		if float(toast["elapsed"]) >= float(toast.get("duration", TOAST_DURATION)):
			toasts.remove_at(index)
		else:
			toasts[index] = toast
		changed = true
	if changed:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			if inventory_open:
				close_inventory()
			else:
				open_inventory()
			_mark_input_handled()
			return
		if inventory_open and event.keycode == KEY_ESCAPE:
			close_inventory()
			_mark_input_handled()
			return
		if event.keycode == KEY_F and (inventory_open or _can_open_inventory()):
			_use_health_potion()
			_mark_input_handled()
			return

	if not inventory_open:
		return

	if event is InputEventMouseMotion:
		mouse_position = event.position
		queue_redraw()
		_mark_input_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mouse_position = event.position
			_handle_click(event.position)
		_mark_input_handled()
		return
	_mark_input_handled()


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _handle_click(click_position: Vector2) -> void:
	for index in range(GameState.INVENTORY_CAPACITY):
		if _inventory_slot_rect(index).has_point(click_position):
			_activate_inventory_slot(index)
			return
	for slot in GameState.ARMOR_SLOTS:
		if _equipment_slot_rect(str(slot)).has_point(click_position):
			_unequip_slot(str(slot))
			return


func _activate_inventory_slot(index: int) -> void:
	var entry := GameState.get_inventory_entry(index)
	if entry.is_empty():
		return
	var item_id := str(entry.get("item_id", ""))
	match GameState.get_item_kind(item_id):
		"consumable":
			_use_health_potion()
		"armor":
			var result := GameState.equip_inventory_item(index)
			if bool(result.get("success", false)):
				var message := "Equipado: %s" % GameState.get_item_name(item_id)
				show_notification(message, item_id)
				inventory_changed.emit(message)
			else:
				show_notification("Não foi possível equipar esta peça.", item_id)


func _unequip_slot(slot: String) -> void:
	var item_id := GameState.get_equipped_item(slot)
	if item_id.is_empty():
		return
	var result := GameState.unequip_armor(slot)
	if bool(result.get("success", false)):
		var message := "Guardado: %s" % GameState.get_item_name(item_id)
		show_notification(message, item_id)
		inventory_changed.emit(message)
	else:
		show_notification("Inventário cheio — libere um slot primeiro.", item_id)


func _use_health_potion() -> void:
	if delegate_health_potion_use:
		health_potion_requested.emit()
		return
	var result := GameState.use_health_potion()
	if bool(result.get("success", false)):
		var healed := int(result.get("healed", 0))
		var message := "Poção usada: +%d Vida" % healed
		show_notification(message, GameState.ITEM_HEALTH_POTION)
		inventory_changed.emit(message)
		_play_ui_sound("click")
		return
	match str(result.get("reason", "")):
		"full_health": show_notification("Vida já está cheia.", GameState.ITEM_HEALTH_POTION)
		_: show_notification("Nenhuma Poção de Vida no inventário.", GameState.ITEM_HEALTH_POTION)


func _draw() -> void:
	if inventory_open:
		_draw_inventory()
	_draw_toasts()


func _draw_inventory() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_OVERLAY, true)
	var panel_rect := _panel_rect()
	draw_rect(panel_rect, COLOR_PANEL, true)
	draw_rect(panel_rect, COLOR_BORDER, false, 3.0)
	draw_rect(Rect2(panel_rect.position + Vector2(12.0, 62.0), panel_rect.size - Vector2(24.0, 88.0)), COLOR_PANEL_INNER, true)
	draw_rect(Rect2(panel_rect.position + Vector2(12.0, 62.0), panel_rect.size - Vector2(24.0, 88.0)), COLOR_BORDER, false, 1.0)

	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(panel_rect.position.x, panel_rect.position.y + 42.0),
		"INVENTÁRIO",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		26,
		COLOR_TEXT
	)
	_draw_character_silhouette(panel_rect)
	_draw_equipment_slots()
	_draw_stats(panel_rect)
	_draw_inventory_grid(panel_rect)
	draw_string(
		font,
		Vector2(panel_rect.position.x, panel_rect.end.y - 12.0),
		"I ou Esc — fechar   •   F — usar poção   •   Clique — equipar/usar",
		HORIZONTAL_ALIGNMENT_CENTER,
		panel_rect.size.x,
		12,
		COLOR_TEXT_DIM
	)


func _draw_character_silhouette(panel_rect: Rect2) -> void:
	var center := panel_rect.position + Vector2(185.0, 210.0)
	var silhouette := Color("17120d")
	draw_circle(center + Vector2(0.0, -88.0), 18.0, silhouette)
	draw_rect(Rect2(center + Vector2(-20.0, -66.0), Vector2(40.0, 92.0)), silhouette, true)
	draw_line(center + Vector2(-16.0, -50.0), center + Vector2(-46.0, 26.0), silhouette, 14.0)
	draw_line(center + Vector2(16.0, -50.0), center + Vector2(46.0, 26.0), silhouette, 14.0)
	draw_line(center + Vector2(-10.0, 18.0), center + Vector2(-22.0, 104.0), silhouette, 16.0)
	draw_line(center + Vector2(10.0, 18.0), center + Vector2(22.0, 104.0), silhouette, 16.0)


func _draw_equipment_slots() -> void:
	var font := ThemeDB.fallback_font
	for slot in GameState.ARMOR_SLOTS:
		var slot_name := str(slot)
		var rect := _equipment_slot_rect(slot_name)
		var hovered := rect.has_point(mouse_position)
		draw_rect(rect, COLOR_SLOT_HOVER if hovered else COLOR_SLOT, true)
		draw_rect(rect, COLOR_BORDER_BRIGHT if hovered else COLOR_BORDER, false, 2.0)
		var item_id := GameState.get_equipped_item(slot_name)
		if not item_id.is_empty():
			ItemVisualsScript.draw_item(self, rect.grow(-7.0), item_id)
		draw_string(
			font,
			Vector2(rect.end.x + 8.0, rect.position.y + 31.0),
			str(SLOT_LABELS.get(slot_name, slot_name)).capitalize(),
			HORIZONTAL_ALIGNMENT_LEFT,
			72.0,
			11,
			COLOR_TEXT_DIM
		)


func _draw_stats(panel_rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var origin := panel_rect.position + Vector2(304.0, 88.0)
	var critical_percent := roundi(GameState.get_player_critical_chance() * 100.0)
	var stat_lines := [
		"OURO  %d" % GameState.gold_score,
		"VIDA MÁX.  %d" % GameState.get_player_max_hp(),
		"DEFESA  %d  (%d%%)" % [
			GameState.get_defense_points(),
			roundi(float(GameState.get_defense_points()) * GameState.DEFENSE_REDUCTION_PER_POINT * 100.0),
		],
		"PONTARIA  %d  •  CRÍT. %d%%" % [
			GameState.get_attribute_value(GameState.ATTRIBUTE_AIM),
			critical_percent,
		],
		"VIGOR  %d  •  FORÇA  %d" % [
			GameState.get_attribute_value(GameState.ATTRIBUTE_VIGOR),
			GameState.get_attribute_value(GameState.ATTRIBUTE_STRENGTH),
		],
		"VELOCIDADE  %d  •  POÇÕES  %d" % [
			GameState.get_attribute_value(GameState.ATTRIBUTE_SPEED),
			GameState.get_item_count(GameState.ITEM_HEALTH_POTION),
		],
	]
	for index in range(stat_lines.size()):
		draw_string(
			font,
			origin + Vector2(0.0, float(index) * 21.0),
			str(stat_lines[index]),
			HORIZONTAL_ALIGNMENT_LEFT,
			280.0,
			12,
			COLOR_GOLD if index == 0 else COLOR_TEXT
		)


func _draw_inventory_grid(panel_rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var title_position := panel_rect.position + Vector2(304.0, 225.0)
	draw_string(
		font,
		title_position,
		"ITENS  %d / %d" % [GameState.get_inventory_used_slots(), GameState.INVENTORY_CAPACITY],
		HORIZONTAL_ALIGNMENT_LEFT,
		270.0,
		13,
		COLOR_TEXT
	)
	for index in range(GameState.INVENTORY_CAPACITY):
		var rect := _inventory_slot_rect(index)
		var hovered := rect.has_point(mouse_position)
		draw_rect(rect, COLOR_SLOT_HOVER if hovered else COLOR_SLOT, true)
		draw_rect(rect, COLOR_BORDER_BRIGHT if hovered else COLOR_BORDER, false, 2.0)
		var entry := GameState.get_inventory_entry(index)
		if entry.is_empty():
			continue
		var item_id := str(entry.get("item_id", ""))
		ItemVisualsScript.draw_item(self, rect.grow(-7.0), item_id)
		var quantity := maxi(1, int(entry.get("quantity", 1)))
		if quantity > 1:
			draw_string(
				font,
				Vector2(rect.position.x + 4.0, rect.end.y - 4.0),
				str(quantity),
				HORIZONTAL_ALIGNMENT_RIGHT,
				rect.size.x - 8.0,
				12,
				COLOR_TEXT
			)

	var hovered_item := _hovered_item_id()
	if not hovered_item.is_empty():
		draw_string(
			font,
			panel_rect.position + Vector2(304.0, 423.0),
			GameState.get_item_name(hovered_item),
			HORIZONTAL_ALIGNMENT_LEFT,
			280.0,
			12,
			COLOR_MAGIC if hovered_item == GameState.ITEM_HEALTH_POTION else COLOR_TEXT_DIM
		)


func _draw_toasts() -> void:
	if toasts.is_empty():
		return
	var font := ThemeDB.fallback_font
	var toast_width := minf(330.0, size.x - 24.0)
	for index in range(toasts.size()):
		var toast := toasts[index]
		var elapsed := float(toast.get("elapsed", 0.0))
		var duration := maxf(0.01, float(toast.get("duration", TOAST_DURATION)))
		var alpha := clampf((duration - elapsed) / 0.35, 0.0, 1.0)
		var rect := Rect2(
			Vector2(size.x - toast_width - 12.0, 70.0 + float(index) * 54.0),
			Vector2(toast_width, 46.0)
		)
		draw_rect(rect, Color(COLOR_PANEL, alpha * 0.96), true)
		draw_rect(rect, Color(COLOR_BORDER_BRIGHT, alpha), false, 2.0)
		var item_id := str(toast.get("item_id", ""))
		if not item_id.is_empty():
			ItemVisualsScript.draw_item(self, Rect2(rect.position + Vector2(7.0, 6.0), Vector2(34.0, 34.0)), item_id)
		draw_string(
			font,
			Vector2(rect.position.x + 48.0, rect.position.y + 28.0),
			str(toast.get("message", "")),
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 56.0,
			12,
			Color(COLOR_TEXT, alpha)
		)


func _panel_rect() -> Rect2:
	return Rect2((size - PANEL_SIZE) * 0.5, PANEL_SIZE)


func _equipment_slot_rect(slot: String) -> Rect2:
	var index := GameState.ARMOR_SLOTS.find(slot)
	if index < 0:
		return Rect2()
	var panel_rect := _panel_rect()
	return Rect2(
		panel_rect.position + Vector2(28.0, 82.0 + float(index) * 68.0),
		EQUIPMENT_SLOT_SIZE
	)


func _inventory_slot_rect(index: int) -> Rect2:
	var safe_index := clampi(index, 0, GameState.INVENTORY_CAPACITY - 1)
	var column := safe_index % INVENTORY_COLUMNS
	var row := safe_index / INVENTORY_COLUMNS
	var panel_rect := _panel_rect()
	return Rect2(
		panel_rect.position + Vector2(
			304.0 + float(column) * (INVENTORY_SLOT_SIZE.x + SLOT_GAP),
			240.0 + float(row) * (INVENTORY_SLOT_SIZE.y + SLOT_GAP)
		),
		INVENTORY_SLOT_SIZE
	)


func _hovered_item_id() -> String:
	for index in range(GameState.INVENTORY_CAPACITY):
		if not _inventory_slot_rect(index).has_point(mouse_position):
			continue
		return str(GameState.get_inventory_entry(index).get("item_id", ""))
	for slot in GameState.ARMOR_SLOTS:
		if _equipment_slot_rect(str(slot)).has_point(mouse_position):
			return GameState.get_equipped_item(str(slot))
	return ""


func _play_ui_sound(sound_name: String) -> void:
	if not is_inside_tree() or not get_tree().root.has_node("AudioManager"):
		return
	var audio_manager := get_tree().root.get_node("AudioManager")
	if sound_name == "hover":
		audio_manager.call("play_ui_hover")
	else:
		audio_manager.call("play_ui_click")
