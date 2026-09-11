class_name RealtimeHUD
extends Control

const HUD_CHROME_ATLAS: Texture2D = preload("res://assets/art/ui/hud_v5/hud_v5_chrome_768.png")
const HUD_CONTENT_ATLAS: Texture2D = preload("res://assets/art/ui/hud_v5/hud_v5_content_768.png")

const DESIGN_CANVAS_SIZE := Vector2(768.0, 512.0)
const SCREEN_MARGIN := 8.0
const MAIN_PANEL_POSITION := Vector2(220.0, 346.0)
const MAIN_PANEL_SIZE := Vector2(280.0, 142.0)
const EQUIPMENT_PANEL_POSITION := Vector2(8.0, 346.0)
const PORTRAIT_PANEL_POSITION := Vector2(112.0, 346.0)
const GRID_PANEL_POSITION := Vector2(500.0, 346.0)
const MINIMAP_POSITION := Vector2(632.0, 346.0)
const POTION_POSITION := Vector2(72.0, 444.0)
const BAR_SIZE := Vector2(264.0, 20.0)
const Q_SLOT_SIZE := Vector2(88.0, 72.0)
const E_SLOT_SIZE := Vector2(80.0, 72.0)
const R_SLOT_SIZE := Vector2(88.0, 72.0)
const ARMOR_CELL_STEP := 36.0
const POTION_SLOT_SIZE := Vector2(40.0, 44.0)
const TOP_INFO_SIZE := Vector2(280.0, 72.0)
const PLACEHOLDER_SLOT_COUNT := 6
const MEDALLION_PLACEHOLDER := "—"
const MINIMAP_SIZE := Vector2(128.0, 142.0)
const COMBAT_NOTICE_SIZE := Vector2(330.0, 50.0)
const COMBAT_NOTICE_DURATION := 2.5
const NOTICE_LINE_LENGTH := 43

const CHROME_EQUIPMENT_PANEL := Rect2(2.0, 2.0, 58.0, 142.0)
const CHROME_PORTRAIT_LEVEL_PANEL := Rect2(64.0, 2.0, 108.0, 142.0)
const CHROME_COMBAT_PANEL := Rect2(176.0, 2.0, 280.0, 142.0)
const CHROME_GRID_GOLD_PANEL := Rect2(460.0, 2.0, 124.0, 142.0)
const CHROME_MINIMAP_PANEL := Rect2(588.0, 2.0, 128.0, 142.0)
const CHROME_WORLD_INFO := Rect2(2.0, 148.0, 280.0, 72.0)
const CHROME_POTION_PANEL := Rect2(286.0, 148.0, 40.0, 44.0)
const CHROME_NEXT_WEAPON_POPUP := Rect2(330.0, 148.0, 38.0, 17.0)

const CONTENT_SUN := Rect2(2.0, 2.0, 20.0, 20.0)
const CONTENT_CLOCK := Rect2(26.0, 2.0, 20.0, 20.0)
const CONTENT_REGION := Rect2(50.0, 2.0, 28.0, 28.0)
const CONTENT_HEART := Rect2(82.0, 2.0, 18.0, 18.0)
const CONTENT_MANA := Rect2(104.0, 2.0, 14.0, 18.0)
const CONTENT_COIN := Rect2(136.0, 2.0, 18.0, 18.0)
const CONTENT_RIFLE := Rect2(158.0, 2.0, 48.0, 22.0)
const CONTENT_PEIXEIRA := Rect2(210.0, 2.0, 48.0, 22.0)
const CONTENT_ARROWS := Rect2(262.0, 2.0, 12.0, 11.0)
const CONTENT_ARMOR := [
	Rect2(278.0, 2.0, 28.0, 28.0),
	Rect2(310.0, 2.0, 28.0, 28.0),
	Rect2(342.0, 2.0, 28.0, 28.0),
	Rect2(374.0, 2.0, 28.0, 28.0),
]
const CONTENT_POTION := Rect2(406.0, 2.0, 24.0, 30.0)
const CONTENT_PORTRAIT := Rect2(434.0, 2.0, 68.0, 68.0)
const CONTENT_MAP := Rect2(506.0, 2.0, 112.0, 112.0)
const CONTENT_RIFLE_MINI := Rect2(622.0, 2.0, 18.0, 11.0)
const CONTENT_PEIXEIRA_MINI := Rect2(644.0, 2.0, 18.0, 11.0)

const COLOR_PANEL := Color("130d09")
const COLOR_PANEL_INNER := Color("281d14")
const COLOR_BORDER_BRIGHT := Color("b07d47")
const COLOR_TEXT := Color("f2dfbd")
const COLOR_MUTED_TEXT := Color("9e8563")
const COLOR_HEALTH := Color("b94732")
const COLOR_MANA := Color("307ad1")
const COLOR_MAGIC := Color("44d6b3")
const COLOR_LOCKED := Color(0.12, 0.09, 0.07, 1.0)

var player_hp := 100
var player_max_hp := 100
var mana := 100
var mana_max := 100
var weapon_name := "RIFLE"
var rifle_ammo := 5
var rifle_ammo_max := 5
var rifle_reserve_ammo := 10
var lapada_charges := 0
var lapada_ready := false
var stunned := false
var reloading := false
var reload_remaining := 0.0
var reload_duration := 1.5
var combat_notice := ""
var combat_notice_remaining := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _process(delta: float) -> void:
	if combat_notice_remaining <= 0.0:
		return
	combat_notice_remaining = maxf(0.0, combat_notice_remaining - maxf(0.0, delta))
	if combat_notice_remaining <= 0.0:
		combat_notice = ""
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func set_hud_state(
	new_player_hp: int,
	new_player_max_hp: int,
	new_mana: int,
	new_mana_max: int,
	new_weapon_name: String,
	new_rifle_ammo: int,
	new_rifle_ammo_max: int,
	new_rifle_reserve_ammo: int,
	new_lapada_charges: int,
	new_lapada_ready: bool,
	new_stunned: bool,
	new_reloading: bool,
	new_reload_remaining: float,
	new_reload_duration: float
) -> void:
	player_hp = maxi(0, new_player_hp)
	player_max_hp = maxi(1, new_player_max_hp)
	mana = maxi(0, new_mana)
	mana_max = maxi(1, new_mana_max)
	weapon_name = new_weapon_name
	rifle_ammo = maxi(0, new_rifle_ammo)
	rifle_ammo_max = maxi(1, new_rifle_ammo_max)
	rifle_reserve_ammo = maxi(0, new_rifle_reserve_ammo)
	lapada_charges = clampi(new_lapada_charges, 0, 3)
	lapada_ready = new_lapada_ready
	stunned = new_stunned
	reloading = new_reloading
	reload_remaining = maxf(0.0, new_reload_remaining)
	reload_duration = maxf(0.01, new_reload_duration)
	queue_redraw()


func show_combat_notice(message: String, duration: float = COMBAT_NOTICE_DURATION) -> void:
	var cleaned_message := message.strip_edges()
	if cleaned_message.is_empty():
		return
	combat_notice = cleaned_message
	combat_notice_remaining = maxf(0.1, duration)
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	_draw_lower_chrome()
	_draw_resources()
	_draw_abilities()
	_draw_portrait_and_level()
	_draw_armor_stack()
	_draw_potion_slot()
	_draw_gold()
	_draw_static_minimap()
	_draw_top_info()
	_draw_combat_notice()


func _canvas_offset() -> Vector2:
	return Vector2(
		floor((size.x - DESIGN_CANVAS_SIZE.x) * 0.5),
		floor(size.y - DESIGN_CANVAS_SIZE.y)
	)


func _main_panel_rect() -> Rect2:
	return Rect2(_canvas_offset() + MAIN_PANEL_POSITION, MAIN_PANEL_SIZE)


func _draw_chrome(source_rect: Rect2, destination_rect: Rect2) -> void:
	draw_texture_rect_region(HUD_CHROME_ATLAS, destination_rect, source_rect)


func _draw_content(source_rect: Rect2, destination_rect: Rect2, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(HUD_CONTENT_ATLAS, destination_rect, source_rect, tint)


func _draw_panel_chrome(source_rect: Rect2, destination_rect: Rect2) -> void:
	draw_rect(destination_rect, COLOR_PANEL, true)
	_draw_chrome(source_rect, destination_rect)


func _draw_lower_chrome() -> void:
	var origin := _canvas_offset()
	_draw_panel_chrome(CHROME_EQUIPMENT_PANEL, Rect2(origin + EQUIPMENT_PANEL_POSITION, CHROME_EQUIPMENT_PANEL.size))
	_draw_panel_chrome(CHROME_POTION_PANEL, Rect2(origin + POTION_POSITION, CHROME_POTION_PANEL.size))
	_draw_panel_chrome(CHROME_PORTRAIT_LEVEL_PANEL, Rect2(origin + PORTRAIT_PANEL_POSITION, CHROME_PORTRAIT_LEVEL_PANEL.size))
	_draw_panel_chrome(CHROME_COMBAT_PANEL, _main_panel_rect())
	_draw_panel_chrome(CHROME_GRID_GOLD_PANEL, Rect2(origin + GRID_PANEL_POSITION, CHROME_GRID_GOLD_PANEL.size))
	_draw_panel_chrome(CHROME_MINIMAP_PANEL, Rect2(origin + MINIMAP_POSITION, CHROME_MINIMAP_PANEL.size))


func _draw_top_info() -> void:
	var origin := _canvas_offset()
	var panel_rect := Rect2(origin + Vector2(SCREEN_MARGIN, SCREEN_MARGIN), TOP_INFO_SIZE)
	_draw_panel_chrome(CHROME_WORLD_INFO, panel_rect)
	_draw_content(CONTENT_SUN, Rect2(origin + Vector2(36.0, 26.0), CONTENT_SUN.size))
	_draw_content(CONTENT_CLOCK, Rect2(origin + Vector2(36.0, 50.0), CONTENT_CLOCK.size))
	_draw_content(CONTENT_REGION, Rect2(origin + Vector2(168.0, 28.0), CONTENT_REGION.size))
	_draw_left_text(Rect2(origin + Vector2(64.0, 24.0), Vector2(84.0, 20.0)), "CLIMA SECO", 11, COLOR_TEXT)
	_draw_left_text(Rect2(origin + Vector2(64.0, 48.0), Vector2(84.0, 20.0)), "HORA 06:00", 11, COLOR_TEXT)
	_draw_left_text(Rect2(origin + Vector2(202.0, 23.0), Vector2(70.0, 18.0)), "REGIÃO", 9, COLOR_TEXT)
	_draw_left_text(Rect2(origin + Vector2(202.0, 45.0), Vector2(70.0, 18.0)), "SERTÃO", 9, COLOR_TEXT)


func _draw_combat_notice() -> void:
	if combat_notice.is_empty() or combat_notice_remaining <= 0.0:
		return
	var notice_width := minf(COMBAT_NOTICE_SIZE.x, size.x - SCREEN_MARGIN * 2.0)
	var notice_rect := Rect2(
		_canvas_offset() + Vector2(DESIGN_CANVAS_SIZE.x - notice_width - SCREEN_MARGIN, SCREEN_MARGIN),
		Vector2(notice_width, COMBAT_NOTICE_SIZE.y)
	)
	draw_rect(notice_rect, Color(COLOR_PANEL, 0.94), true)
	draw_rect(notice_rect, COLOR_BORDER_BRIGHT, false, 2.0)
	var lines := _wrap_notice(combat_notice)
	var font := ThemeDB.fallback_font
	var first_baseline := notice_rect.position.y + (18.0 if lines.size() > 1 else 30.0)
	for index in range(lines.size()):
		draw_string(
			font,
			Vector2(notice_rect.position.x + 10.0, first_baseline + float(index) * 17.0),
			lines[index],
			HORIZONTAL_ALIGNMENT_LEFT,
			notice_rect.size.x - 20.0,
			11,
			COLOR_TEXT
		)


func _wrap_notice(message: String) -> PackedStringArray:
	if message.length() <= NOTICE_LINE_LENGTH:
		return PackedStringArray([message])
	var split_at := message.rfind(" ", NOTICE_LINE_LENGTH)
	if split_at <= 0:
		split_at = NOTICE_LINE_LENGTH
	var first_line := message.left(split_at).strip_edges()
	var second_line := message.substr(split_at).strip_edges()
	if second_line.length() > NOTICE_LINE_LENGTH:
		second_line = second_line.left(NOTICE_LINE_LENGTH - 3).strip_edges() + "..."
	return PackedStringArray([first_line, second_line])


func _draw_portrait_and_level() -> void:
	var origin := _canvas_offset()
	_draw_left_text(Rect2(origin + Vector2(124.0, 360.0), Vector2(84.0, 16.0)), "NÍVEL %s" % MEDALLION_PLACEHOLDER, 11, COLOR_TEXT)
	_draw_content(CONTENT_PORTRAIT, Rect2(origin + Vector2(142.0, 394.0), CONTENT_PORTRAIT.size))


func _draw_resources() -> void:
	var origin := _canvas_offset()
	var health_rect := Rect2(origin + Vector2(228.0, 356.0), BAR_SIZE)
	var mana_rect := Rect2(origin + Vector2(228.0, 380.0), BAR_SIZE)
	_draw_fill(health_rect, float(player_hp) / float(player_max_hp), COLOR_HEALTH)
	_draw_fill(mana_rect, float(mana) / float(mana_max), COLOR_MANA)
	_draw_content(CONTENT_HEART, Rect2(origin + Vector2(232.0, 357.0), CONTENT_HEART.size))
	_draw_content(CONTENT_MANA, Rect2(origin + Vector2(234.0, 381.0), CONTENT_MANA.size))
	_draw_centered_text(health_rect, "VIDA  %d / %d" % [player_hp, player_max_hp], 12, COLOR_TEXT)
	_draw_centered_text(mana_rect, "MANA  %d / %d" % [mana, mana_max], 12, COLOR_TEXT)


func _draw_fill(rect: Rect2, ratio: float, fill_color: Color) -> void:
	var inner_rect := rect.grow(-3.0)
	draw_rect(inner_rect, COLOR_PANEL_INNER, true)
	var clamped_ratio := clampf(ratio, 0.0, 1.0)
	if clamped_ratio > 0.0:
		draw_rect(Rect2(inner_rect.position, Vector2(inner_rect.size.x * clamped_ratio, inner_rect.size.y)), fill_color, true)


func _draw_abilities() -> void:
	var origin := _canvas_offset()
	var q_rect := Rect2(origin + Vector2(228.0, 404.0), Q_SLOT_SIZE)
	var e_rect := Rect2(origin + Vector2(320.0, 404.0), E_SLOT_SIZE)
	var r_rect := Rect2(origin + Vector2(404.0, 404.0), R_SLOT_SIZE)

	_draw_weapon_slot(q_rect)
	_draw_ability_slot(e_rect, "E", "LAPADA", "", 11)
	_draw_lapada_pips(e_rect)
	_draw_centered_text(Rect2(e_rect.position + Vector2(6.0, 57.0), Vector2(e_rect.size.x - 12.0, 11.0)), "%d / 3" % lapada_charges, 9, COLOR_MAGIC if lapada_ready else COLOR_MUTED_TEXT)
	var reload_detail := "%.1f s" % reload_remaining if reloading else "RESERVA %d" % rifle_reserve_ammo
	_draw_ability_slot(r_rect, "R", "RECARREGAR", reload_detail, 9)
	_draw_reload_progress(r_rect)


func _next_weapon_name(current_weapon: String) -> String:
	return "PEIXEIRA" if current_weapon == "RIFLE" else "RIFLE"


func _draw_weapon_slot(rect: Rect2) -> void:
	var origin := _canvas_offset()
	var next_weapon := _next_weapon_name(weapon_name)
	var next_weapon_icon: Rect2 = CONTENT_PEIXEIRA_MINI if next_weapon == "PEIXEIRA" else CONTENT_RIFLE_MINI
	var content_tint := COLOR_MUTED_TEXT if stunned else Color.WHITE
	var text_color := COLOR_MUTED_TEXT if stunned else COLOR_TEXT
	_draw_centered_text(Rect2(rect.position + Vector2(4.0, 4.0), Vector2(16.0, 16.0)), "Q", 11, text_color)
	_draw_chrome(CHROME_NEXT_WEAPON_POPUP, Rect2(origin + Vector2(274.0, 408.0), CHROME_NEXT_WEAPON_POPUP.size))
	_draw_content(next_weapon_icon, Rect2(origin + Vector2(277.0, 411.0), next_weapon_icon.size), content_tint)
	_draw_content(CONTENT_ARROWS, Rect2(origin + Vector2(297.0, 411.0), CONTENT_ARROWS.size), content_tint)
	if weapon_name == "RIFLE":
		_draw_content(CONTENT_RIFLE, Rect2(origin + Vector2(240.0, 426.0), CONTENT_RIFLE.size), content_tint)
		_draw_centered_text(Rect2(origin + Vector2(236.0, 450.0), Vector2(72.0, 12.0)), "RIFLE", 9, text_color)
		_draw_centered_text(Rect2(origin + Vector2(236.0, 463.0), Vector2(72.0, 11.0)), "%d / %d" % [rifle_ammo, rifle_ammo_max], 9, text_color)
	else:
		_draw_content(CONTENT_PEIXEIRA, Rect2(origin + Vector2(240.0, 426.0), CONTENT_PEIXEIRA.size), content_tint)
		_draw_centered_text(Rect2(origin + Vector2(236.0, 450.0), Vector2(72.0, 12.0)), "PEIXEIRA", 9, text_color)


func _draw_ability_slot(
	rect: Rect2,
	key_text: String,
	ability_text: String,
	detail_text: String,
	ability_font_size: int
) -> void:
	var text_color := COLOR_MUTED_TEXT if stunned else COLOR_TEXT
	_draw_centered_text(Rect2(rect.position + Vector2(4.0, 4.0), Vector2(16.0, 16.0)), key_text, 11, text_color)
	_draw_centered_text(Rect2(rect.position + Vector2(6.0, 22.0), Vector2(rect.size.x - 12.0, 16.0)), ability_text, ability_font_size, text_color)
	if not detail_text.is_empty():
		_draw_centered_text(Rect2(rect.position + Vector2(6.0, 48.0), Vector2(rect.size.x - 12.0, 14.0)), detail_text, 9, COLOR_MUTED_TEXT)


func _draw_lapada_pips(slot_rect: Rect2) -> void:
	for index in range(3):
		if lapada_charges > index:
			draw_circle(slot_rect.position + Vector2(26.0 + float(index) * 14.0, 46.0), 3.0, COLOR_MAGIC)


func _draw_reload_progress(slot_rect: Rect2) -> void:
	if not reloading:
		return
	var progress := 1.0 - clampf(reload_remaining / reload_duration, 0.0, 1.0)
	var progress_back := Rect2(slot_rect.position + Vector2(6.0, slot_rect.size.y - 8.0), Vector2(slot_rect.size.x - 12.0, 3.0))
	draw_rect(progress_back, COLOR_LOCKED, true)
	draw_rect(
		Rect2(progress_back.position, Vector2(progress_back.size.x * progress, progress_back.size.y)),
		COLOR_MAGIC,
		true
	)


func _draw_armor_stack() -> void:
	var origin := _canvas_offset()
	for index in range(4):
		var armor_slot := str(GameState.ARMOR_SLOTS[index])
		if GameState.is_armor_slot_equipped(armor_slot):
			var armor_icon: Rect2 = CONTENT_ARMOR[index]
			var icon_rect := Rect2(origin + Vector2(23.0, 349.0 + float(index) * ARMOR_CELL_STEP), armor_icon.size)
			_draw_content(armor_icon, icon_rect)


func _draw_potion_slot() -> void:
	var potion_count := GameState.get_item_count(GameState.ITEM_HEALTH_POTION)
	var has_potion := potion_count > 0
	var slot_rect := Rect2(_canvas_offset() + POTION_POSITION, POTION_SLOT_SIZE)
	_draw_content(CONTENT_POTION, Rect2(slot_rect.position + Vector2(8.0, 5.0), CONTENT_POTION.size), Color.WHITE if has_potion else COLOR_MUTED_TEXT)
	var key_rect := Rect2(slot_rect.position + Vector2(2.0, 1.0), Vector2(14.0, 13.0))
	_draw_centered_text(key_rect, "F", 9, COLOR_TEXT if has_potion else COLOR_MUTED_TEXT)
	var count_rect := Rect2(slot_rect.position + Vector2(15.0, 28.0), Vector2(23.0, 13.0))
	_draw_centered_text(
		count_rect,
		"×%d" % potion_count,
		10,
		COLOR_TEXT if has_potion else COLOR_MUTED_TEXT
	)


func _draw_gold() -> void:
	var origin := _canvas_offset()
	_draw_content(CONTENT_COIN, Rect2(origin + Vector2(514.0, 451.0), CONTENT_COIN.size))
	_draw_centered_text(Rect2(origin + Vector2(538.0, 450.0), Vector2(72.0, 20.0)), "OURO %d" % GameState.gold_score, 11, COLOR_TEXT)


func _draw_static_minimap() -> void:
	_draw_content(CONTENT_MAP, Rect2(_canvas_offset() + Vector2(640.0, 356.0), CONTENT_MAP.size))


func _draw_left_text(rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var baseline := rect.position.y + (rect.size.y + float(font_size)) * 0.5 - 2.0
	draw_string(font, Vector2(rect.position.x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, color)


func _draw_centered_text(rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var baseline := rect.position.y + (rect.size.y + float(font_size)) * 0.5 - 2.0
	draw_string(
		font,
		Vector2(rect.position.x, baseline),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		font_size,
		color
	)
