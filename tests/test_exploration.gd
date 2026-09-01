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
	var character_atlas := load("res://assets/art/characters/animations/personagens_completo_se_animacoes_640x256_16c.png") as Texture2D
	_expect(character_atlas != null, "O atlas dos personagens deve carregar.")
	if character_atlas != null:
		_expect(character_atlas.get_size() == Vector2(640.0, 256.0), "O atlas deve conter 10 colunas e 4 linhas de 64x64.")
	_test_environment_assets()
	var script_constants: Dictionary = exploration.get_script().get_script_constant_map()
	_expect(
		int(script_constants.get("CHARACTER_ATLAS_COLUMNS", 0)) == 10
		and int(script_constants.get("CHARACTER_ATLAS_ROWS", 0)) == 4,
		"O contrato do atlas deve permanecer em 10 colunas por 4 linhas."
	)
	_expect(
		int(script_constants.get("PLAYER_RIFLE_ROW", -1)) == 0,
		"O Cangaceiro (Rifle) deve usar a linha 0 do atlas."
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
	_expect(
		script_constants.get("PLAYER_FOOTPRINT_RADIUS", Vector2.ZERO) == Vector2(7.0, 3.0),
		"O contato do Cangaceiro deve usar uma área curta ancorada nos pés."
	)
	_test_environment_landmarks(exploration, script_constants)

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
	# Um tick de 1/60 s não deve criar um replanejamento falso por resíduo
	# numérico no orçamento de movimento.
	var short_tick_start: Vector2 = exploration.call("_cell_to_world", Vector2i(1, 10))
	player.position = short_tick_start
	exploration.set("capanga_active", false)
	exploration.call("_set_destination", exploration.call("_cell_to_world", Vector2i(2, 9)))
	var path_before_tick: PackedVector2Array = exploration.get("movement_path")
	exploration.call("_move_player_along_path", 1.0 / 60.0)
	_expect(player.position.distance_to(short_tick_start) > 0.0, "Um tick curto deve aceitar deslocamento real.")
	_expect(
		float(exploration.get("player_repath_remaining")) == 0.0,
		"Um tick curto não deve entrar em espera falsa."
	)
	_expect(
		(exploration.get("movement_path") as PackedVector2Array).size() == path_before_tick.size(),
		"Um tick curto deve preservar a rota ativa."
	)
	_test_wasd_movement(exploration)
	_test_dynamic_click_path(exploration)
	_test_camera_bounds(exploration)

	exploration.call("_toggle_overview")
	_expect(bool(exploration.get("overview_enabled")), "A visão geral deve ser ativada.")
	exploration.call("_toggle_overview")
	_expect(not bool(exploration.get("overview_enabled")), "A segunda alternância deve restaurar a câmera.")

	exploration.queue_free()
	_finish()


func _test_environment_assets() -> void:
	var assets := {
		"res://assets/art/tilesets/tileset_caatinga_terra_rachada.png": Vector2(256.0, 32.0),
		"res://assets/art/tilesets/tileset_caminho_batido.png": Vector2(256.0, 32.0),
		"res://assets/art/tilesets/tileset_masmorra_pedra.png": Vector2(256.0, 32.0),
		"res://assets/art/tilesets/tileset_vegetacao_caatinga.png": Vector2(256.0, 64.0),
		"res://assets/art/tilesets/tileset_paredes_taipa.png": Vector2(256.0, 64.0),
	}
	for asset_path in assets:
		var texture := load(asset_path) as Texture2D
		_expect(texture != null, "O recurso visual externo deve carregar: %s" % asset_path)
		if texture != null:
			_expect(texture.get_size() == assets[asset_path], "O recurso deve preservar seu atlas: %s" % asset_path)


func _test_environment_landmarks(exploration: Node, script_constants: Dictionary) -> void:
	var start_cell: Vector2i = script_constants.get("START_LANDMARK_CELL", Vector2i(-1, -1))
	var combat_cell: Vector2i = script_constants.get("COMBAT_LANDMARK_CELL", Vector2i(-1, -1))
	var dungeon_cell: Vector2i = script_constants.get("DUNGEON_LANDMARK_CELL", Vector2i(-1, -1))
	var obstacles: Array = script_constants.get("ROAD_OBSTACLES", [])
	_expect(start_cell != combat_cell and combat_cell != dungeon_cell and start_cell != dungeon_cell, "Os três marcos externos devem ocupar posições únicas.")
	_expect(obstacles.has(start_cell), "O marco inicial deve reutilizar um obstáculo existente.")
	_expect(obstacles.has(combat_cell), "O marco do encontro deve reutilizar um obstáculo existente.")
	_expect(obstacles.has(dungeon_cell), "O marco da masmorra deve reutilizar um obstáculo existente.")
	_expect(int(exploration.call("_road_obstacle_variant", start_cell)) == 3, "O início deve usar o cacto florido.")
	_expect(int(exploration.call("_road_obstacle_variant", combat_cell)) == 2, "A arena deve usar o arbusto seco.")
	_expect(
		script_constants.get("TAIPA_FOOT_ANCHOR", Vector2.ZERO) == Vector2(32.0, 48.0),
		"A taipa deve manter a base visual validada em y=48."
	)


func _test_wasd_movement(exploration: Node) -> void:
	var player := exploration.get_node("PlayerAnchor") as Node2D
	exploration.set("capanga_active", false)
	exploration.set("movement_path", PackedVector2Array())
	exploration.set("path_index", 0)
	exploration.set("has_destination", false)

	# Direção da tela e velocidade de 140 px/s.
	player.position = exploration.call("_cell_to_world", Vector2i(9, 6))
	var start := player.position
	_expect(bool(exploration.call("_move_player_with_input", 0.10, Vector2.RIGHT)), "D deve mover em uma área livre.")
	_expect(is_equal_approx(player.position.distance_to(start), 14.0), "WASD deve manter 140 px/s.")
	_expect(is_equal_approx(player.position.y, start.y), "D deve mover somente para a direita da tela.")

	# Diagonal normalizada não pode aumentar a velocidade.
	player.position = exploration.call("_cell_to_world", Vector2i(9, 6))
	start = player.position
	exploration.call("_move_player_with_input", 0.10, Vector2(1.0, 1.0))
	_expect(is_equal_approx(player.position.distance_to(start), 14.0), "Diagonal WASD deve continuar em 140 px/s.")

	# Obstáculos e limites não podem ser atravessados, mesmo com delta alto.
	var obstacle_cell := Vector2i(5, 9)
	player.position = exploration.call("_cell_to_world", Vector2i(4, 9))
	var obstacle_direction: Vector2 = (
		exploration.call("_cell_to_world", obstacle_cell) - player.position
	).normalized()
	exploration.call("_move_player_with_input", 1.0, obstacle_direction)
	var occupied_cell: Vector2i = exploration.call("_world_to_cell", player.position)
	_expect(occupied_cell != obstacle_cell, "WASD não deve atravessar uma rocha.")
	_expect(bool(exploration.call("_is_walkable_player_cell", occupied_cell)), "A posição final deve continuar caminhável.")

	player.position = exploration.call("_cell_to_world", Vector2i(0, 10))
	var outside_direction: Vector2 = (
		exploration.call("_cell_to_world", Vector2i(-1, 10)) - player.position
	).normalized()
	exploration.call("_move_player_with_input", 1.0, outside_direction)
	occupied_cell = exploration.call("_world_to_cell", player.position)
	_expect(bool(exploration.call("_is_walkable_player_cell", occupied_cell)), "WASD deve respeitar o limite do mapa.")

	# Uma diagonal não pode cortar a quina entre duas células bloqueadas.
	var astar := exploration.get("astar") as AStarGrid2D
	var corner_origin := Vector2i(7, 6)
	var corner_target := Vector2i(8, 5)
	var corner_side_a := Vector2i(8, 6)
	var corner_side_b := Vector2i(7, 5)
	astar.set_point_solid(corner_side_a, true)
	astar.set_point_solid(corner_side_b, true)
	player.position = exploration.call("_cell_to_world", corner_origin)
	_expect(
		not bool(exploration.call("_is_walkable_player_position", exploration.call("_cell_to_world", corner_target))),
		"WASD diagonal não deve cortar uma quina bloqueada."
	)
	astar.set_point_solid(corner_side_a, false)
	astar.set_point_solid(corner_side_b, false)

	# WASD cancela a rota atual; um clique posterior continua funcionando.
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	var click_target: Vector2 = exploration.call("_cell_to_world", Vector2i(3, 10))
	exploration.call("_set_destination", click_target)
	_expect(bool(exploration.get("has_destination")), "O clique deve criar uma rota antes do WASD.")
	exploration.call("_move_player_with_input", 0.10, Vector2.RIGHT)
	_expect(not bool(exploration.get("has_destination")), "WASD deve cancelar o destino do clique.")
	_expect((exploration.get("movement_path") as PackedVector2Array).is_empty(), "WASD deve limpar a rota anterior.")
	_expect(int(exploration.get("path_index")) == 0, "WASD deve zerar o índice da rota.")

	click_target = exploration.call("_cell_to_world", Vector2i(2, 10))
	exploration.call("_set_destination", click_target)
	_expect(bool(exploration.get("has_destination")), "Um novo clique deve voltar a criar uma rota.")
	var position_before_zero_input := player.position
	_expect(
		not bool(exploration.call("_move_player_with_input", 0.10, Vector2.ZERO)),
		"Entrada WASD neutra não deve deslocar diretamente."
	)
	_expect(bool(exploration.get("has_destination")), "Entrada WASD neutra deve preservar a rota do clique.")
	_expect(player.position == position_before_zero_input, "Entrada WASD neutra não deve alterar a posição.")

	# O footprint deve barrar o pé antes que o centro entre no obstáculo.
	var footprint_origin := Vector2i(9, 6)
	var footprint_blocker := Vector2i(10, 5)
	var blocker_was_solid: bool = astar.is_point_solid(footprint_blocker)
	astar.set_point_solid(footprint_blocker, true)
	player.position = exploration.call("_cell_to_world", footprint_origin)
	var footprint_probe := player.position + Vector2(26.0, 0.0)
	_expect(
		exploration.call("_world_to_cell", footprint_probe) == footprint_origin,
		"A prova do footprint deve manter o centro na célula livre."
	)
	_expect(
		not bool(exploration.call("_is_walkable_player_footprint", footprint_probe)),
		"A borda dos pés deve impedir aproximação que invada a célula bloqueada."
	)
	astar.set_point_solid(footprint_blocker, blocker_was_solid)

	# Os cantos do footprint também devem barrar um corte diagonal no obstáculo.
	var diagonal_footprint_origin := Vector2i(4, 9)
	var diagonal_footprint_blocker := Vector2i(5, 9)
	var diagonal_blocker_was_solid: bool = astar.is_point_solid(diagonal_footprint_blocker)
	astar.set_point_solid(diagonal_footprint_blocker, true)
	var diagonal_footprint_probe: Vector2 = (
		exploration.call("_cell_to_world", diagonal_footprint_origin) + Vector2(11.2, 5.6)
	)
	_expect(
		exploration.call("_world_to_cell", diagonal_footprint_probe) == diagonal_footprint_origin,
		"A prova diagonal deve manter o centro do pé na célula livre."
	)
	_expect(
		exploration.call("_world_to_cell", diagonal_footprint_probe + Vector2(7.0, 3.0)) == diagonal_footprint_blocker,
		"A prova diagonal deve colocar somente o canto do pé no obstáculo."
	)
	_expect(
		not bool(exploration.call("_is_walkable_player_footprint", diagonal_footprint_probe)),
		"O canto do footprint deve impedir o corte diagonal do obstáculo."
	)
	astar.set_point_solid(diagonal_footprint_blocker, diagonal_blocker_was_solid)

	# Em um empate diagonal, os dois eixos livres devem alternar em vez de favorecer X.
	# Esta posição encosta num canto estático: o passo diagonal é bloqueado, mas
	# seus componentes horizontal e vertical ainda são válidos separadamente.
	player.position = exploration.call("_cell_to_world", Vector2i(4, 8)) + Vector2(-17.0, 12.0)
	var first_slide: Vector2 = exploration.call("_resolve_player_motion", Vector2(4.0, 4.0))
	var second_slide: Vector2 = exploration.call("_resolve_player_motion", Vector2(4.0, 4.0))
	_expect(
		(first_slide == Vector2(4.0, 0.0) and second_slide == Vector2(0.0, 4.0))
		or (first_slide == Vector2(0.0, 4.0) and second_slide == Vector2(4.0, 0.0)),
		"O deslizamento diagonal deve alternar os eixos livres."
	)
	# Neste trecho, a diagonal encontra o limite, mas um eixo permanece livre por
	# todo o orçamento de 0,10 s.
	player.position = exploration.call("_cell_to_world", Vector2i(11, 2)) + Vector2(-10.0, 12.0)
	exploration.set("step_distance_accumulator", 0.0)
	exploration.call("_move_player_with_input", 0.10, Vector2(1.0, 1.0))
	var slide_distance := float(exploration.get("step_distance_accumulator"))
	_expect(
		absf(slide_distance - 14.0) <= 0.002,
		"O deslizamento deve manter o orçamento real de 140 px/s; medido %.3f." % slide_distance
	)


func _test_dynamic_click_path(exploration: Node) -> void:
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(8, 6))
	exploration.set("capanga_active", true)
	exploration.set("movement_path", PackedVector2Array())
	exploration.set("path_index", 0)
	exploration.set("has_destination", false)

	var target := exploration.call("_cell_to_world", Vector2i(4, 10)) as Vector2
	exploration.call("_set_destination", target)
	var original_path: PackedVector2Array = exploration.get("movement_path")
	_expect(not original_path.is_empty(), "A rota dinâmica deve começar com um caminho válido.")
	if original_path.is_empty():
		exploration.set("capanga_active", false)
		return

	var occupied_cell: Vector2i = exploration.call("_world_to_cell", original_path[0])
	capanga.position = exploration.call("_cell_to_world", occupied_cell)
	var position_before_replan := player.position
	exploration.call("_move_player_along_path", 0.10)
	var rerouted_path: PackedVector2Array = exploration.get("movement_path")
	_expect(bool(exploration.get("has_destination")), "Replanejar deve preservar o destino ativo.")
	_expect(exploration.get("destination_marker") == target, "Replanejar deve preservar o marcador final.")
	_expect(exploration.call("_world_to_cell", player.position) != occupied_cell, "O jogador não pode entrar na célula móvel ocupada.")
	_expect(player.position != position_before_replan, "Uma alternativa livre deve continuar a caminhada no mesmo comando.")
	for waypoint in rerouted_path:
		_expect(exploration.call("_world_to_cell", waypoint) != occupied_cell, "A nova rota não pode conter a célula do Capanga.")

	for frame in range(600):
		exploration.call("_advance_timers", 1.0 / 60.0)
		exploration.call("_move_player_along_path", 1.0 / 60.0)
		if not bool(exploration.get("has_destination")):
			break
	_expect(player.position.distance_to(target) <= 1.0, "A rota ajustada deve alcançar o destino sem um novo clique.")
	_expect(not bool(exploration.get("has_destination")), "A rota ajustada deve encerrar o destino ao chegar.")

	# Uma rota longa deve continuar estável enquanto o Capanga muda de célula.
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(8, 6))
	exploration.set("capanga_active", true)
	target = exploration.call("_cell_to_world", Vector2i(13, 3))
	exploration.call("_set_destination", target)
	var moving_cells: Array[Vector2i] = [
		Vector2i(8, 6),
		Vector2i(9, 6),
		Vector2i(10, 6),
		Vector2i(11, 5),
		Vector2i(11, 4),
	]
	var moving_route_overlap := false
	for frame in range(1200):
		if frame % 48 == 0:
			var moving_index := int(frame / 48) % moving_cells.size()
			capanga.position = exploration.call("_cell_to_world", moving_cells[moving_index])
		exploration.call("_advance_timers", 1.0 / 60.0)
		exploration.call("_move_player_along_path", 1.0 / 60.0)
		if exploration.call("_world_to_cell", player.position) == exploration.call("_world_to_cell", capanga.position):
			moving_route_overlap = true
		if not bool(exploration.get("has_destination")):
			break
	_expect(not moving_route_overlap, "A rota móvel não deve sobrepor o jogador ao Capanga.")
	_expect(not bool(exploration.get("has_destination")), "A rota móvel deve concluir sem ficar em espera permanente.")
	_expect(player.position.distance_to(target) <= 1.0, "A rota móvel deve alcançar o destino final.")

	# O clique mantém a mesma velocidade de 140 px/s em uma rota livre.
	exploration.set("capanga_active", false)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	target = exploration.call("_cell_to_world", Vector2i(4, 10))
	exploration.call("_set_destination", target)
	var route_start := player.position
	exploration.call("_move_player_along_path", 0.10)
	_expect(is_equal_approx(player.position.distance_to(route_start), 14.0), "O clique deve manter 140 px/s.")


func _test_camera_bounds(exploration: Node) -> void:
	var bounds: Rect2 = exploration.call("_map_bounds")
	var zoom := Vector2(1.45, 1.45)
	var half_view: Vector2 = exploration.get_viewport_rect().size * 0.5 / zoom
	for target in [
		bounds.position - Vector2(1000.0, 1000.0),
		bounds.end + Vector2(1000.0, 1000.0),
	]:
		var clamped: Vector2 = exploration.call("_clamp_camera_position", target, zoom)
		_expect(clamped.x - half_view.x >= bounds.position.x - 0.01, "A câmera não deve revelar vazio à esquerda.")
		_expect(clamped.y - half_view.y >= bounds.position.y - 0.01, "A câmera não deve revelar vazio acima.")
		_expect(clamped.x + half_view.x <= bounds.end.x + 0.01, "A câmera não deve revelar vazio à direita.")
		_expect(clamped.y + half_view.y <= bounds.end.y + 0.01, "A câmera não deve revelar vazio abaixo.")


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
