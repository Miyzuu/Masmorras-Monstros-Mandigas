extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/exploration.tscn") as PackedScene
	_expect(packed_scene != null, "A cena de exploração deve carregar.")
	if packed_scene == null:
		_finish()
		return

	var exploration := packed_scene.instantiate()
	root.add_child(exploration)
	await process_frame
	var character_atlas := load("res://assets/art/characters/prototypes/personagens_se_48px_16c.png") as Texture2D
	_expect(character_atlas != null, "O atlas dos personagens deve carregar.")
	if character_atlas != null:
		_expect(character_atlas.get_size() == Vector2(128.0, 64.0), "O atlas deve conter duas células 64x64.")
	var script_constants: Dictionary = exploration.get_script().get_script_constant_map()
	_expect(
		script_constants.get("PLAYER_SPRITE_REGION") == Rect2(0.0, 0.0, 64.0, 64.0),
		"O Cangaceiro deve usar a célula esquerda do atlas."
	)
	_expect(
		script_constants.get("CAPANGA_SPRITE_REGION") == Rect2(64.0, 0.0, 64.0, 64.0),
		"O Capanga deve usar a célula direita do atlas."
	)
	_expect(
		exploration.call("_character_draw_rect", Vector2.ZERO) == Rect2(-32.0, -60.0, 64.0, 64.0),
		"O ponto dos pés dos personagens deve coincidir com o anchor de movimento."
	)

	var target_cell := Vector2i(3, 10)
	var target_world: Vector2 = exploration.call("_cell_to_world", target_cell)
	exploration.call("_set_destination", target_world)

	var movement_path: PackedVector2Array = exploration.get("movement_path")
	_expect(not movement_path.is_empty(), "Um destino caminhável deve gerar rota.")

	for frame in range(600):
		exploration.call("_physics_process", 1.0 / 60.0)
		if not bool(exploration.get("has_destination")):
			break

	var player := exploration.get_node("PlayerAnchor") as Node2D
	_expect(player.position.distance_to(target_world) <= 1.0, "O personagem deve alcançar o destino.")
	_expect(not bool(exploration.get("has_destination")), "A caminhada deve terminar ao chegar.")

	exploration.call("_toggle_overview")
	_expect(bool(exploration.get("overview_enabled")), "A visão geral deve ser ativada.")
	exploration.call("_toggle_overview")
	_expect(not bool(exploration.get("overview_enabled")), "A segunda alternância deve restaurar a câmera.")

	exploration.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("TESTE_EXPLORACAO_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
