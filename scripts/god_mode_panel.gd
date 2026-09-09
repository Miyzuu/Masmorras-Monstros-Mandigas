extends CanvasLayer

var panel: PanelContainer
var no_damage_toggle: CheckButton
var infinite_ammo_toggle: CheckButton
var active_indicator: Label


func _ready() -> void:
	layer = 220
	_build_interface()
	_sync_from_state()


func _input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.ctrl_pressed
		and event.shift_pressed
		and event.keycode == KEY_C
	):
		panel.visible = not panel.visible
		_sync_from_state()
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()


func is_panel_open() -> bool:
	return panel != null and panel.visible


func _build_interface() -> void:
	panel = PanelContainer.new()
	panel.name = "GodModePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -156.0
	panel.offset_top = 18.0
	panel.offset_right = 156.0
	panel.offset_bottom = 144.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var content := VBoxContainer.new()
	content.name = "Options"
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title := Label.new()
	title.text = "GOD MODE  •  Ctrl+Shift+C fecha"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	no_damage_toggle = CheckButton.new()
	no_damage_toggle.name = "NoDamageToggle"
	no_damage_toggle.text = "Não receber dano"
	no_damage_toggle.toggled.connect(_on_no_damage_toggled)
	content.add_child(no_damage_toggle)

	infinite_ammo_toggle = CheckButton.new()
	infinite_ammo_toggle.name = "InfiniteAmmoToggle"
	infinite_ammo_toggle.text = "Munição infinita"
	infinite_ammo_toggle.toggled.connect(_on_infinite_ammo_toggled)
	content.add_child(infinite_ammo_toggle)

	active_indicator = Label.new()
	active_indicator.name = "GodModeIndicator"
	active_indicator.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	active_indicator.offset_left = -280.0
	active_indicator.offset_top = 16.0
	active_indicator.offset_right = -16.0
	active_indicator.offset_bottom = 40.0
	active_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	active_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_indicator.add_theme_color_override("font_color", Color("ffd166"))
	add_child(active_indicator)

	panel.visible = false


func _sync_from_state() -> void:
	if no_damage_toggle == null or infinite_ammo_toggle == null:
		return
	no_damage_toggle.button_pressed = GameState.god_mode_no_damage
	infinite_ammo_toggle.button_pressed = GameState.god_mode_infinite_ammo
	_refresh_indicator()


func _refresh_indicator() -> void:
	if active_indicator == null:
		return
	var active_options: Array[String] = []
	if GameState.god_mode_no_damage:
		active_options.append("SEM DANO")
	if GameState.god_mode_infinite_ammo:
		active_options.append("MUNIÇÃO ∞")
	active_indicator.visible = not active_options.is_empty()
	active_indicator.text = "GOD MODE: %s" % " • ".join(active_options)


func _on_no_damage_toggled(enabled: bool) -> void:
	GameState.set_god_mode_no_damage(enabled)
	_refresh_indicator()


func _on_infinite_ammo_toggled(enabled: bool) -> void:
	GameState.set_god_mode_infinite_ammo(enabled)
	_refresh_indicator()
