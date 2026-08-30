class_name RealtimeHUD
extends Control

const MAIN_PANEL_SIZE := Vector2(500.0, 108.0)
const SCREEN_MARGIN := 8.0
const BAR_SIZE := Vector2(150.0, 22.0)
const ABILITY_SLOT_SIZE := Vector2(54.0, 54.0)
const ABILITY_SLOT_GAP := 8.0
const ARMOR_SLOT_SIZE := Vector2(40.0, 40.0)
const ARMOR_SLOT_GAP := 4.0

const COLOR_PANEL := Color(0.075, 0.052, 0.034, 0.97)
const COLOR_PANEL_INNER := Color(0.157, 0.114, 0.078, 1.0)
const COLOR_BORDER := Color(0.439, 0.314, 0.2, 1.0)
const COLOR_BORDER_BRIGHT := Color(0.69, 0.49, 0.28, 1.0)
const COLOR_TEXT := Color(0.949, 0.875, 0.741, 1.0)
const COLOR_MUTED_TEXT := Color(0.62, 0.52, 0.39, 1.0)
const COLOR_HEALTH := Color(0.725, 0.278, 0.196, 1.0)
const COLOR_MANA := Color(0.19, 0.48, 0.82, 1.0)
const COLOR_MAGIC := Color(0.27, 0.84, 0.70, 1.0)
const COLOR_ALERT := Color(0.88, 0.17, 0.12, 1.0)
const COLOR_LOCKED := Color(0.12, 0.09, 0.07, 1.0)
const COLOR_ARMOR_ICON := Color(0.61, 0.47, 0.31, 0.9)

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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var panel_rect := Rect2(
		Vector2((size.x - MAIN_PANEL_SIZE.x) * 0.5, size.y - MAIN_PANEL_SIZE.y - SCREEN_MARGIN),
		MAIN_PANEL_SIZE
	)
	_draw_panel(panel_rect)
	_draw_resources(panel_rect)
	_draw_abilities(panel_rect)
	_draw_armor_stack()


func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, COLOR_PANEL, true)
	draw_rect(rect, COLOR_BORDER, false, 2.0)
	draw_line(
		rect.position + Vector2(8.0, 36.0),
		Vector2(rect.end.x - 8.0, rect.position.y + 36.0),
		COLOR_BORDER,
		1.0
	)


func _draw_resources(panel_rect: Rect2) -> void:
	var health_rect := Rect2(panel_rect.position + Vector2(12.0, 9.0), BAR_SIZE)
	var mana_rect := Rect2(
		Vector2(panel_rect.end.x - BAR_SIZE.x - 12.0, panel_rect.position.y + 9.0),
		BAR_SIZE
	)
	_draw_fill_bar(
		health_rect,
		"VIDA  %d / %d" % [player_hp, player_max_hp],
		float(player_hp) / float(player_max_hp),
		COLOR_HEALTH
	)
	_draw_fill_bar(
		mana_rect,
		"MANA  %d / %d" % [mana, mana_max],
		float(mana) / float(mana_max),
		COLOR_MANA
	)

	var weapon_rect := Rect2(
		panel_rect.position + Vector2(170.0, 7.0),
		Vector2(160.0, 26.0)
	)
	var weapon_text := weapon_name
	var weapon_font_size := 12
	if weapon_name == "RIFLE":
		weapon_text = "PENTE %d/%d  •  RESERVA %d" % [rifle_ammo, rifle_ammo_max, rifle_reserve_ammo]
		weapon_font_size = 10
	elif weapon_name == "PEIXEIRA":
		weapon_text = "PEIXEIRA"
	if stunned:
		weapon_text = "ATORDOADO"
	_draw_centered_text(weapon_rect, weapon_text, weapon_font_size, COLOR_ALERT if stunned else COLOR_TEXT)


func _draw_fill_bar(rect: Rect2, label: String, ratio: float, fill_color: Color) -> void:
	draw_rect(rect, COLOR_PANEL_INNER, true)
	var clamped_ratio := clampf(ratio, 0.0, 1.0)
	if clamped_ratio > 0.0:
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * clamped_ratio, rect.size.y)), fill_color, true)
	draw_rect(rect, COLOR_BORDER_BRIGHT, false, 1.0)
	_draw_centered_text(rect, label, 12, COLOR_TEXT)


func _draw_abilities(panel_rect: Rect2) -> void:
	var total_width := ABILITY_SLOT_SIZE.x * 3.0 + ABILITY_SLOT_GAP * 2.0
	var first_position := Vector2(
		panel_rect.get_center().x - total_width * 0.5,
		panel_rect.position.y + 44.0
	)
	var q_rect := Rect2(first_position, ABILITY_SLOT_SIZE)
	var e_rect := Rect2(first_position + Vector2(ABILITY_SLOT_SIZE.x + ABILITY_SLOT_GAP, 0.0), ABILITY_SLOT_SIZE)
	var r_rect := Rect2(first_position + Vector2((ABILITY_SLOT_SIZE.x + ABILITY_SLOT_GAP) * 2.0, 0.0), ABILITY_SLOT_SIZE)

	_draw_ability_slot(q_rect, "Q", "RIFLE" if weapon_name == "RIFLE" else "PEIX.", COLOR_BORDER_BRIGHT, false)
	var e_border := COLOR_MAGIC if lapada_ready else COLOR_BORDER
	_draw_ability_slot(e_rect, "E", "LAPADA", e_border, false)
	_draw_lapada_pips(e_rect)
	var reload_label := "%.1fs" % reload_remaining if reloading else "RECARR."
	_draw_ability_slot(r_rect, "R", reload_label, COLOR_MAGIC if reloading else COLOR_BORDER_BRIGHT, false)
	_draw_reload_progress(r_rect)


func _draw_ability_slot(
	rect: Rect2,
	key_text: String,
	ability_text: String,
	border_color: Color,
	locked: bool
) -> void:
	draw_rect(rect, COLOR_LOCKED if locked else COLOR_PANEL_INNER, true)
	draw_rect(rect, border_color, false, 2.0)
	var key_rect := Rect2(rect.position + Vector2(4.0, 2.0), Vector2(16.0, 15.0))
	_draw_centered_text(key_rect, key_text, 11, COLOR_MUTED_TEXT if locked else COLOR_TEXT)
	var ability_rect := Rect2(rect.position + Vector2(3.0, 18.0), Vector2(rect.size.x - 6.0, 24.0))
	_draw_centered_text(ability_rect, ability_text, 9, COLOR_MUTED_TEXT if locked else COLOR_TEXT)


func _draw_lapada_pips(slot_rect: Rect2) -> void:
	const PIP_SIZE := Vector2(10.0, 5.0)
	const PIP_GAP := 3.0
	var total_width := PIP_SIZE.x * 3.0 + PIP_GAP * 2.0
	var first_position := Vector2(
		slot_rect.get_center().x - total_width * 0.5,
		slot_rect.end.y - PIP_SIZE.y - 5.0
	)
	for index in range(3):
		var pip_rect := Rect2(first_position + Vector2(float(index) * (PIP_SIZE.x + PIP_GAP), 0.0), PIP_SIZE)
		draw_rect(pip_rect, COLOR_MAGIC if lapada_charges > index else COLOR_LOCKED, true)
		draw_rect(pip_rect, COLOR_BORDER, false, 1.0)


func _draw_reload_progress(slot_rect: Rect2) -> void:
	if not reloading:
		return
	var progress := 1.0 - clampf(reload_remaining / reload_duration, 0.0, 1.0)
	var progress_back := Rect2(slot_rect.position + Vector2(4.0, slot_rect.size.y - 8.0), Vector2(slot_rect.size.x - 8.0, 4.0))
	draw_rect(progress_back, COLOR_LOCKED, true)
	draw_rect(
		Rect2(progress_back.position, Vector2(progress_back.size.x * progress, progress_back.size.y)),
		COLOR_MAGIC,
		true
	)


func _draw_armor_stack() -> void:
	var total_height := ARMOR_SLOT_SIZE.y * 4.0 + ARMOR_SLOT_GAP * 3.0
	var first_position := Vector2(SCREEN_MARGIN + 4.0, size.y - total_height - SCREEN_MARGIN)
	for index in range(4):
		var slot_rect := Rect2(
			first_position + Vector2(0.0, float(index) * (ARMOR_SLOT_SIZE.y + ARMOR_SLOT_GAP)),
			ARMOR_SLOT_SIZE
		)
		draw_rect(slot_rect, COLOR_PANEL, true)
		draw_rect(slot_rect, COLOR_BORDER, false, 2.0)
		_draw_armor_silhouette(slot_rect, index)


func _draw_armor_silhouette(slot_rect: Rect2, armor_part: int) -> void:
	var origin := slot_rect.position
	match armor_part:
		0:
			draw_rect(Rect2(origin + Vector2(11.0, 9.0), Vector2(18.0, 5.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(8.0, 14.0), Vector2(24.0, 7.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(11.0, 21.0), Vector2(5.0, 7.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(24.0, 21.0), Vector2(5.0, 7.0)), COLOR_ARMOR_ICON, true)
		1:
			draw_rect(Rect2(origin + Vector2(8.0, 10.0), Vector2(7.0, 7.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(25.0, 10.0), Vector2(7.0, 7.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(12.0, 12.0), Vector2(16.0, 18.0)), COLOR_ARMOR_ICON, true)
		2:
			draw_rect(Rect2(origin + Vector2(10.0, 9.0), Vector2(20.0, 6.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(10.0, 15.0), Vector2(8.0, 17.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(22.0, 15.0), Vector2(8.0, 17.0)), COLOR_ARMOR_ICON, true)
		3:
			draw_rect(Rect2(origin + Vector2(8.0, 17.0), Vector2(10.0, 12.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(22.0, 17.0), Vector2(10.0, 12.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(6.0, 27.0), Vector2(12.0, 5.0)), COLOR_ARMOR_ICON, true)
			draw_rect(Rect2(origin + Vector2(22.0, 27.0), Vector2(12.0, 5.0)), COLOR_ARMOR_ICON, true)


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
