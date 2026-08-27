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
	await process_frame

	_expect(bool(exploration.get("capanga_active")), "O Capanga deve começar ativo.")
	var capanga_world: Vector2 = exploration.call("_cell_to_world", Vector2i(5, 10))
	var player := exploration.get_node("PlayerAnchor") as Node2D
	player.position = capanga_world
	exploration.call("_check_enemy_contact")

	_expect(str(game_state.get("active_encounter_id")) == "capanga_01", "O contato deve iniciar o encontro.")
	_expect(bool(exploration.get("encounter_transitioning")), "O fade de entrada deve ser iniciado.")
	game_state.call("complete_active_encounter")
	exploration.queue_free()
	await process_frame

	var returned_exploration := packed_scene.instantiate()
	root.add_child(returned_exploration)
	await process_frame

	var returned_player := returned_exploration.get_node("PlayerAnchor") as Node2D
	_expect(not bool(returned_exploration.get("capanga_active")), "O Capanga vencido deve desaparecer.")
	_expect(returned_player.position.distance_to(capanga_world) <= 1.0, "O jogador deve retornar ao mesmo ponto.")

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
