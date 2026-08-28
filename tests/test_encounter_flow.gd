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

	exploration.call("_damage_capanga", 150, false)
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
