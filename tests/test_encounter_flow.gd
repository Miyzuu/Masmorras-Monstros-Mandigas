extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.call("reset_session")

	var packed_scene := load("res://scenes/exploration.tscn") as PackedScene
	_expect(packed_scene != null, "A cena de exploração deve carregar.")
	if packed_scene == null:
		_finish(game_state)
		return

	var exploration := packed_scene.instantiate()
	root.add_child(exploration)
	exploration.set_physics_process(false)
	await process_frame

	_expect(bool(exploration.get("capanga_active")), "O Capanga deve começar ativo.")
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(14, 6))
	capanga.position = exploration.call("_cell_to_world", Vector2i(8, 6))
	exploration.call("_advance_capanga_ai", 0.0)

	_expect(int(exploration.get("capanga_state")) == 1, "A aproximação deve iniciar a perseguição no mesmo mapa.")
	_expect(exploration.is_inside_tree(), "O combate em tempo real não deve trocar a cena de exploração.")
	_expect(str(game_state.get("active_encounter_id")).is_empty(), "O combate em tempo real não deve abrir um encontro separado.")

	_test_victory_autosave(exploration)
	_expect(not bool(exploration.get("capanga_active")), "O Capanga derrotado deve desaparecer imediatamente.")
	_expect(bool(game_state.call("is_encounter_defeated", "capanga_01")), "A vitória deve ser persistida no estado da sessão.")
	exploration.queue_free()
	await process_frame

	var returned_exploration := packed_scene.instantiate()
	root.add_child(returned_exploration)
	returned_exploration.set_physics_process(false)
	await process_frame

	_expect(not bool(returned_exploration.get("capanga_active")), "O Capanga vencido deve desaparecer.")
	_expect(str(game_state.get("active_encounter_id")).is_empty(), "Reabrir a exploração não deve criar uma arena separada.")

	returned_exploration.queue_free()
	_finish(game_state)


func _test_victory_autosave(exploration: Node) -> void:
	var save_manager := root.get_node("SaveManager")
	var previous_storage_root: String = save_manager.get("storage_root")
	var previous_slot: int = save_manager.get("active_slot")
	var test_storage := "res://.godot/encounter_autosave_test_%d" % Time.get_ticks_usec()
	save_manager.set("storage_root", test_storage)
	save_manager.set("active_slot", 1)
	exploration.call("_damage_capanga", 150, false)
	var saved: Dictionary = save_manager.call("_read_slot_data", 1)
	var saved_state: Dictionary = saved.get("game_state", {})
	var defeated: Dictionary = saved_state.get("defeated_encounters", {})
	_expect(bool(defeated.get("capanga_01", false)), "O autosave da vitória deve guardar a porta já desbloqueada.")
	save_manager.call("delete_slot", 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_storage))
	save_manager.set("storage_root", previous_storage_root)
	save_manager.set("active_slot", previous_slot)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(game_state: Node) -> void:
	game_state.call("reset_session")
	if failures.is_empty():
		print("TESTE_ENCONTRO_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
