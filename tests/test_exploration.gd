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
	var character_atlas := load("res://assets/art/characters/animations/personagens_se_idle4_walk6_64px_16c.png") as Texture2D
	_expect(character_atlas != null, "O atlas dos personagens deve carregar.")
	if character_atlas != null:
		_expect(character_atlas.get_size() == Vector2(640.0, 128.0), "O atlas deve conter 10 colunas e 2 linhas de 64x64.")
	var script_constants: Dictionary = exploration.get_script().get_script_constant_map()
	_expect(
		int(script_constants.get("CHARACTER_ATLAS_COLUMNS", 0)) == 10
		and int(script_constants.get("CHARACTER_ATLAS_ROWS", 0)) == 2,
		"O contrato do atlas deve permanecer em 10 colunas por 2 linhas."
	)
	_expect(
		int(script_constants.get("PLAYER_ATLAS_ROW", -1)) == 0,
		"O Cangaceiro deve usar a linha 0 do atlas."
	)
	_expect(
		int(script_constants.get("CAPANGA_ATLAS_ROW", -1)) == 1,
		"O Capanga deve usar a linha 1 do atlas."
	)
	_expect(
		int(script_constants.get("IDLE_FRAME_COUNT", 0)) == 4
		and is_equal_approx(float(script_constants.get("IDLE_FPS", 0.0)), 4.0),
		"Idle deve usar 4 quadros a 4 FPS."
	)
	_expect(
		int(script_constants.get("WALK_FRAME_COUNT", 0)) == 6
		and is_equal_approx(float(script_constants.get("WALK_FPS", 0.0)), 10.0),
		"Walk deve usar 6 quadros a 10 FPS."
	)
	_expect(
		exploration.call("_character_sprite_region", 0, 0, 3) == Rect2(192.0, 0.0, 64.0, 64.0),
		"O quarto quadro idle do Cangaceiro deve usar coluna 3, linha 0."
	)
	_expect(
		exploration.call("_character_sprite_region", 1, 1, 5) == Rect2(576.0, 64.0, 64.0, 64.0),
		"O sexto quadro walk do Capanga deve usar coluna 9, linha 1."
	)
	_expect(
		exploration.call("_character_draw_rect", Vector2.ZERO) == Rect2(-32.0, -60.0, 64.0, 64.0),
		"O ponto dos pés dos personagens deve coincidir com o anchor de movimento."
	)

	var idle_tick: Dictionary = exploration.call("_next_character_animation", 0, 0, 0.0, false, 0.25)
	_expect(int(idle_tick["state"]) == 0, "Sem deslocamento, o estado deve permanecer idle.")
	_expect(int(idle_tick["frame"]) == 1, "Idle deve avançar um quadro a cada 0,25 s.")
	var walk_reset: Dictionary = exploration.call("_next_character_animation", 0, 3, 0.20, true, 0.25)
	_expect(int(walk_reset["state"]) == 1, "Deslocamento real deve trocar imediatamente para walk.")
	_expect(int(walk_reset["frame"]) == 0, "Trocar para walk deve reiniciar o ciclo no quadro 0.")
	_expect(is_zero_approx(float(walk_reset["elapsed"])), "Trocar para walk deve zerar o relógio próprio.")
	var walk_tick: Dictionary = exploration.call("_next_character_animation", 1, 0, 0.0, true, 0.10)
	_expect(int(walk_tick["frame"]) == 1, "Walk deve avançar um quadro a cada 0,10 s.")
	var idle_reset: Dictionary = exploration.call("_next_character_animation", 1, 5, 0.09, false, 0.10)
	_expect(int(idle_reset["state"]) == 0, "Parar deve trocar imediatamente para idle.")
	_expect(int(idle_reset["frame"]) == 0, "Trocar para idle deve reiniciar o ciclo no quadro 0.")

	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	var player_start := player.position
	var capanga_start := capanga.position
	player.position += Vector2(1.0, 0.0)
	exploration.call("_update_player_animation", 0.01, player_start)
	exploration.call("_update_capanga_animation", 0.01, capanga_start)
	_expect(int(exploration.get("player_animation_state")) == 1, "O deslocamento do Cangaceiro deve ativar apenas seu walk.")
	_expect(int(exploration.get("capanga_animation_state")) == 0, "O Capanga parado deve preservar seu estado idle próprio.")
	player.position = player_start
	exploration.call("_reset_character_animations_to_idle")
	exploration.set("capanga_animation_frame", 2)
	exploration.call("_update_player_animation", 0.25, player.position)
	exploration.call("_update_capanga_animation", 0.25, capanga.position)
	_expect(int(exploration.get("player_animation_frame")) == 1, "O Cangaceiro deve avançar seu relógio idle próprio.")
	_expect(int(exploration.get("capanga_animation_frame")) == 3, "O Capanga deve avançar o mesmo timing sem copiar o quadro do Cangaceiro.")
	exploration.call("_reset_character_animations_to_idle")

	var target_cell := Vector2i(3, 10)
	var target_world: Vector2 = exploration.call("_cell_to_world", target_cell)
	exploration.call("_set_destination", target_world)

	var movement_path: PackedVector2Array = exploration.get("movement_path")
	_expect(not movement_path.is_empty(), "Um destino caminhável deve gerar rota.")

	for frame in range(600):
		exploration.call("_physics_process", 1.0 / 60.0)
		if not bool(exploration.get("has_destination")):
			break

	_expect(player.position.distance_to(target_world) <= 1.0, "O personagem deve alcançar o destino.")
	_expect(not bool(exploration.get("has_destination")), "A caminhada deve terminar ao chegar.")
	exploration.call("_physics_process", 1.0 / 60.0)
	_expect(int(exploration.get("player_animation_state")) == 0, "No primeiro tick sem deslocamento, o Cangaceiro deve voltar para idle.")
	_expect(int(exploration.get("player_animation_frame")) == 0, "Voltar para idle deve reiniciar no quadro 0.")

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
