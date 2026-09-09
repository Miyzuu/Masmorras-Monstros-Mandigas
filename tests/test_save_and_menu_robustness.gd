extends SceneTree

var failures: Array[String] = []
var test_root := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var saves := root.get_node("SaveManager")
	var state := root.get_node("GameState")
	test_root = "res://.godot/qa_save_%d" % OS.get_process_id()
	saves.call("set_storage_root_for_tests", test_root)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))
	_test_invalid_saves(saves, state)
	_test_safe_replacement(saves, state)
	_test_import_types(state)
	_test_checkpoint_roundtrip(saves, state)
	_test_pause_layout()
	_test_controls_consistency()
	_cleanup()
	state.call("reset_session")
	saves.set("active_slot", 0)
	if failures.is_empty():
		print("TESTE_SAVES_E_MENUS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_invalid_saves(saves: Node, state: Node) -> void:
	state.call("reset_session")
	state.call("set_player_hp", 73)
	saves.set("active_slot", 2)
	for payload in [
		{"schema_version": 1},
		{"schema_version": 1, "game_state": null},
		{"schema_version": [], "game_state": {}},
		{"schema_version": 1.5, "game_state": {}},
		{"schema_version": 1, "game_state": {}, "checkpoint": "unknown"},
	]:
		state.call("set_player_hp", 73)
		saves.set("active_slot", 2)
		_write_slot(payload)
		var summary: Dictionary = saves.call("get_slot_summary", 1)
		_expect(not bool(summary.get("valid", true)), "Save estruturalmente inválido deve ser recusado: %s" % payload)
		_expect(str(saves.call("load_slot", 1)).is_empty(), "Save inválido não deve iniciar uma cena.")
		_expect(int(saves.get("active_slot")) == 2, "Save inválido não deve trocar o slot ativo.")
		_expect(int(state.get("player_hp")) == 73, "Save inválido não deve alterar a sessão.")


func _test_safe_replacement(saves: Node, state: Node) -> void:
	_expect(bool(saves.call("create_new_game", 1)), "Novo jogo deve criar um save válido.")
	var path := test_root.path_join("save_slot_1.json")
	var original := FileAccess.get_file_as_string(path)
	# Impede apenas a gravação temporária para reproduzir uma falha de escrita.
	var blocked_temporary := ProjectSettings.globalize_path(path + ".tmp")
	DirAccess.make_dir_absolute(blocked_temporary)
	state.call("set_player_hp", 44)
	_expect(not bool(saves.call("save_active_slot")), "Falha ao gravar temporário deve ser informada.")
	_expect(FileAccess.get_file_as_string(path) == original, "Falha de gravação deve preservar o save anterior byte a byte.")
	DirAccess.remove_absolute(blocked_temporary)
	_expect(bool(saves.call("save_active_slot")), "Gravação seguinte deve substituir o save após recuperar a escrita.")
	state.call("reset_session")
	_expect(str(saves.call("load_slot", 1)).ends_with("exploration.tscn"), "Save substituído deve continuar carregável.")
	_expect(int(state.get("player_hp")) == 44, "Save substituído deve conter o estado novo.")


func _test_import_types(state: Node) -> void:
	state.call("reset_session")
	state.call("import_save_data", {
		"player_hp": [], "rifle_ammo": {}, "rifle_reserve_ammo": null,
		"current_weapon": [], "gold_score": {}, "lapada_charges": [],
		"dungeon_room_index": {}, "dungeon_active": "false", "dungeon_completed": "false",
		"defeated_encounters": {"invalid": "false", "valid": true},
		"inventory": [{"item_id": "health_potion", "quantity": []}],
	})
	_expect(int(state.get("player_hp")) == 100, "HP com tipo inválido deve usar o padrão.")
	_expect(int(state.get("rifle_ammo")) == 5, "Munição com tipo inválido deve usar o padrão.")
	_expect(int(state.get("rifle_reserve_ammo")) == 10, "Reserva com tipo inválido deve usar o padrão.")
	_expect(not bool(state.get("dungeon_active")), "Texto false não deve ativar masmorra.")
	_expect(not bool(state.get("dungeon_completed")), "Texto false não deve completar masmorra.")
	_expect(not bool(state.call("is_encounter_defeated", "invalid")), "Flag inválida não deve derrotar encontro.")
	_expect(bool(state.call("is_encounter_defeated", "valid")), "Flag booleana válida deve ser preservada.")
	_expect(int(state.call("get_inventory_used_slots")) == 0, "Item com quantidade inválida deve ser descartado.")
	state.call("import_save_data", {"player_hp": 75, "gold_score": 5})
	_expect(int(state.get("player_hp")) == 75, "Save antigo sem inventário deve continuar compatível.")


func _test_checkpoint_roundtrip(saves: Node, state: Node) -> void:
	_expect(bool(saves.call("create_new_game", 1)), "Roundtrip deve criar slot.")
	state.call("acquire_armor", "armor_chest")
	state.call("set_player_hp", 108)
	state.call("add_inventory_item", "health_potion", 6)
	state.set("dungeon_active", true)
	state.set("dungeon_room_index", 3)
	_expect(bool(saves.call("save_active_slot")), "Checkpoint do chefe deve ser gravado.")
	state.call("reset_session")
	_expect(str(saves.call("load_slot", 1)).ends_with("main.tscn"), "Quarta sala deve carregar o chefe.")
	_expect(int(state.get("player_hp")) == 108, "HP do equipamento deve sobreviver ao JSON.")
	_expect(int(state.call("get_item_count", "health_potion")) == 6, "Pilhas devem sobreviver ao JSON.")
	state.set("dungeon_completed", true)
	_expect(bool(saves.call("save_active_slot", "completed")), "Checkpoint completo deve ser gravado.")
	_expect(str(saves.call("load_slot", 1)).ends_with("exploration.tscn"), "Conclusão deve retornar à exploração.")
	_expect(not bool(state.get("dungeon_active")), "Conclusão deve desativar a masmorra.")


func _test_pause_layout() -> void:
	var menu := load("res://scripts/pause_menu.gd").new() as Control
	for viewport_size in [Vector2(768, 512), Vector2(768, 900)]:
		menu.size = viewport_size
		var panel: Rect2 = menu.call("_panel_rect")
		for dungeon_available in [false, true]:
			menu.set("dungeon_exit_available", dungeon_available)
			var buttons: Dictionary = menu.call("_main_button_rects")
			for key in buttons:
				var button: Rect2 = buttons[key]
				if button.has_area():
					_expect(panel.encloses(button), "Botão %s deve acompanhar o painel ao redimensionar." % key)
		var confirmations: Dictionary = menu.call("_confirmation_button_rects")
		for button in confirmations.values():
			_expect(panel.encloses(button), "Confirmação deve acompanhar o painel ao redimensionar.")
		_expect(panel.encloses(menu.call("_back_button_rect")), "Voltar deve acompanhar o painel ao redimensionar.")
	menu.free()


func _test_controls_consistency() -> void:
	var title_constants: Dictionary = load("res://scripts/title_menu.gd").get_script_constant_map()
	var pause_constants: Dictionary = load("res://scripts/pause_menu.gd").get_script_constant_map()
	_expect(title_constants["CONTROLS_LEFT"] == pause_constants["LEFT_CONTROLS"], "Menu inicial e pausa devem listar os mesmos controles da coluna esquerda.")
	_expect(title_constants["CONTROLS_RIGHT"] == pause_constants["RIGHT_CONTROLS"], "Menu inicial e pausa devem listar os mesmos controles da coluna direita.")


func _write_slot(data: Dictionary) -> void:
	var file := FileAccess.open(test_root.path_join("save_slot_1.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _cleanup() -> void:
	for file_name in ["save_slot_1.json", "save_slot_1.json.tmp"]:
		var path := ProjectSettings.globalize_path(test_root.path_join(file_name))
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
