extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.call("reset_session")

	var exploration_scene := load("res://scenes/exploration.tscn") as PackedScene
	var dungeon_scene := load("res://scenes/dungeon.tscn") as PackedScene
	_expect(exploration_scene != null, "A exploração deve carregar.")
	_expect(dungeon_scene != null, "A masmorra deve carregar.")
	if exploration_scene == null or dungeon_scene == null:
		_finish(game_state)
		return

	var exploration := exploration_scene.instantiate()
	root.add_child(exploration)
	exploration.set_physics_process(false)
	await process_frame
	_expect(exploration.get_script() != null, "O script da exploração deve estar válido.")
	if exploration.get_script() == null:
		exploration.queue_free()
		_finish(game_state)
		return

	var exterior_player := exploration.get_node("PlayerAnchor") as Node2D
	var exterior_entry: Vector2 = exploration.call("_cell_to_world", Vector2i(14, 3))
	var exterior_door_top: Vector2 = exploration.call("_cell_to_world", Vector2i(15, 3)) + Vector2(0.0, -30.0)
	exploration.call("_set_destination", exterior_door_top)
	_expect(
		exploration.get("destination_marker") == exterior_entry,
		"Clicar na parte alta da porta externa deve levar o herói até a entrada."
	)
	exterior_player.position = exterior_entry
	exploration.set("door_contact_latched", false)
	_expect(
		not bool(exploration.call("_check_dungeon_door_contact")),
		"A porta deve permanecer bloqueada enquanto o Capanga estiver vivo."
	)
	_expect(
		not bool(exploration.get("dungeon_prompt_visible")),
		"A porta bloqueada não deve abrir o modal."
	)

	exploration.call("_damage_capanga", 150, false)
	_expect(
		bool(exploration.call("_is_dungeon_door_unlocked")),
		"Derrotar o Capanga deve liberar a porta imediatamente."
	)
	exploration.set("door_contact_latched", false)
	_expect(
		bool(exploration.call("_check_dungeon_door_contact")),
		"O contato com a porta liberada deve abrir a confirmação."
	)
	_expect(bool(exploration.get("dungeon_prompt_visible")), "O modal de entrada deve ficar visível.")
	_expect(
		bool(exploration.call("_handle_dungeon_prompt_key", KEY_ESCAPE)),
		"Esc deve ser reconhecido pelo modal de entrada."
	)
	_expect(not bool(exploration.get("dungeon_prompt_visible")), "Esc deve cancelar a entrada.")

	exploration.set("door_contact_latched", false)
	exploration.call("_check_dungeon_door_contact")
	exploration.set("player_hp", 73)
	exploration.set("rifle_ammo", 2)
	exploration.set("current_weapon", 1)
	exploration.set("stun_remaining", 0.0)
	_expect(
		bool(exploration.call("_handle_dungeon_prompt_key", KEY_SPACE)),
		"Espaço deve confirmar o modal de entrada."
	)
	_expect(is_zero_approx(float(exploration.get("stun_remaining"))), "Espaço no modal não deve causar aparo falho.")
	_expect(bool(game_state.get("dungeon_active")), "Confirmar a entrada deve iniciar a sessão da masmorra.")
	_expect(int(game_state.get("player_hp")) == 73, "A entrada deve preservar 73 HP.")
	_expect(int(game_state.get("rifle_ammo")) == 2, "A entrada deve preservar 2 balas.")
	_expect(game_state.get("return_position") == exterior_entry, "O retorno deve ser guardado diante da porta.")
	_expect(bool(exploration.get("scene_transitioning")), "Confirmar com Espaço deve iniciar o fade.")

	exploration.queue_free()
	await process_frame

	var enter_exploration := exploration_scene.instantiate()
	root.add_child(enter_exploration)
	enter_exploration.set_physics_process(false)
	await process_frame
	var enter_player := enter_exploration.get_node("PlayerAnchor") as Node2D
	enter_player.position = exterior_entry
	enter_exploration.set("door_contact_latched", false)
	enter_exploration.call("_check_dungeon_door_contact")
	enter_exploration.set("player_hp", 73)
	enter_exploration.set("rifle_ammo", 2)
	enter_exploration.set("current_weapon", 1)
	_expect(bool(enter_exploration.get("dungeon_prompt_visible")), "A confirmação deve reabrir para testar Enter.")
	_expect(
		bool(enter_exploration.call("_handle_dungeon_prompt_key", KEY_ENTER)),
		"Enter deve confirmar uma caixa realmente aberta."
	)
	_expect(bool(enter_exploration.get("scene_transitioning")), "Confirmar com Enter deve iniciar o fade.")
	enter_exploration.queue_free()
	await process_frame

	var dungeon := dungeon_scene.instantiate()
	root.add_child(dungeon)
	dungeon.set_physics_process(false)
	await process_frame
	_expect(dungeon.get_script() != null, "O script da masmorra deve estar válido.")
	if dungeon.get_script() == null:
		dungeon.queue_free()
		_finish(game_state)
		return
	var dungeon_script_constants: Dictionary = dungeon.get_script().get_script_constant_map()
	_expect(
		dungeon_script_constants.get("PLAYER_SPRITE_REGION") == Rect2(0.0, 0.0, 64.0, 64.0),
		"A masmorra deve usar a célula esquerda do atlas para o Cangaceiro."
	)
	_expect(
		dungeon.call("_character_draw_rect", Vector2.ZERO) == Rect2(-32.0, -60.0, 64.0, 64.0),
		"O Cangaceiro deve manter o mesmo alinhamento visual dentro da masmorra."
	)
	_expect(bool(dungeon.get("scene_transitioning")), "O fade de entrada deve bloquear comandos.")
	await create_timer(0.55).timeout
	_expect(not bool(dungeon.get("scene_transitioning")), "O fade deve liberar comandos após 0,5 s.")

	var dungeon_astar: AStarGrid2D = dungeon.get("astar")
	var dungeon_player := dungeon.get_node("PlayerAnchor") as Node2D
	_expect(dungeon_astar.region.size == Vector2i(16, 12), "A masmorra deve ter grade 16x12.")
	_expect(dungeon.find_child("CapangaAnchor", true, false) == null, "A sala inicial não deve conter inimigos.")
	_expect(int(dungeon.get("player_hp")) == 73, "A masmorra deve receber os 73 HP atuais.")
	_expect(int(dungeon.get("rifle_ammo")) == 2, "A masmorra deve receber as 2 balas atuais.")
	_expect(int(dungeon.get("current_weapon")) == 1, "A arma equipada também deve ser preservada.")
	_expect(dungeon_astar.is_point_solid(Vector2i(14, 1)), "A escada ao fundo deve estar bloqueada.")

	var exit_front: Vector2 = dungeon.call("_cell_to_world", Vector2i(1, 10))
	var exit_door_top: Vector2 = dungeon.call("_cell_to_world", Vector2i(0, 10)) + Vector2(0.0, -25.0)
	dungeon.call("_set_destination", exit_door_top)
	_expect(not (dungeon.get("movement_path") as PackedVector2Array).is_empty(), "A porta de saída deve ser alcançável.")
	_expect(dungeon.get("destination_marker") == exit_front, "A imagem inteira da porta deve responder ao clique.")
	dungeon_player.position = exit_front
	dungeon.set("exit_contact_latched", false)
	_expect(bool(dungeon.call("_check_exit_door_contact")), "Tocar a porta interna deve pedir confirmação.")
	_expect(str(dungeon.get("exit_request_source")) == "porta", "A saída deve registrar o contato com a porta.")
	_expect(
		bool(dungeon.call("_handle_exit_prompt_key", KEY_ESCAPE)),
		"Esc no aviso deve cancelar a saída."
	)
	_expect(not bool(dungeon.get("exit_prompt_visible")), "Cancelar deve manter o jogador na masmorra.")

	dungeon.call("_request_dungeon_exit", "Esc")
	_expect(bool(dungeon.get("exit_prompt_visible")), "Esc dentro da sala deve abrir o aviso de saída.")
	_expect(str(dungeon.get("exit_request_source")) == "Esc", "O aviso deve registrar a solicitação por Esc.")
	dungeon.call("_cancel_dungeon_exit")
	dungeon.set("exit_contact_latched", false)
	dungeon.call("_check_exit_door_contact")
	_expect(str(dungeon.get("exit_request_source")) == "porta", "A confirmação final deve vir da porta interna.")
	dungeon.set("player_hp", 41)
	dungeon.set("rifle_ammo", 1)
	dungeon.set("current_weapon", 0)
	var progress: Dictionary = game_state.get("dungeon_progress")
	progress["sala_visitada"] = true
	_expect(
		bool(dungeon.call("_handle_exit_prompt_key", KEY_ENTER)),
		"Enter deve confirmar a saída iniciada pela porta."
	)
	_expect(bool(dungeon.get("scene_transitioning")), "Confirmar a saída deve iniciar o fade.")
	_expect(not bool(game_state.get("dungeon_active")), "Sair deve encerrar a sessão da masmorra.")
	_expect((game_state.get("dungeon_progress") as Dictionary).is_empty(), "Sair deve apagar o progresso interno.")
	_expect(int(game_state.get("player_hp")) == 41, "A saída não deve curar os 41 HP atuais.")
	_expect(int(game_state.get("rifle_ammo")) == 1, "A saída não deve recarregar a munição.")
	_expect(
		bool(game_state.call("is_encounter_defeated", "capanga_01")),
		"Limpar a masmorra não deve ressuscitar o Capanga."
	)

	dungeon.queue_free()
	await process_frame

	var returned_exploration := exploration_scene.instantiate()
	root.add_child(returned_exploration)
	returned_exploration.set_physics_process(false)
	await process_frame

	var returned_player := returned_exploration.get_node("PlayerAnchor") as Node2D
	_expect(bool(returned_exploration.get("scene_transitioning")), "O fade de retorno deve bloquear comandos.")
	await create_timer(0.55).timeout
	_expect(not bool(returned_exploration.get("scene_transitioning")), "O fade de retorno deve liberar comandos após 0,5 s.")
	_expect(returned_player.position == exterior_entry, "A saída deve devolver o herói diante da porta externa.")
	_expect(int(returned_exploration.get("player_hp")) == 41, "O mapa externo deve manter os 41 HP.")
	_expect(int(returned_exploration.get("rifle_ammo")) == 1, "O mapa externo deve manter 1 bala.")
	_expect(not bool(returned_exploration.get("capanga_active")), "O Capanga derrotado deve continuar removido.")
	_expect(bool(returned_exploration.get("door_contact_latched")), "O retorno deve bloquear a reabertura imediata da porta.")
	returned_exploration.call("_check_dungeon_door_contact")
	_expect(
		not bool(returned_exploration.get("dungeon_prompt_visible")),
		"O modal não deve reabrir automaticamente no retorno."
	)

	returned_exploration.queue_free()
	await process_frame

	game_state.call("begin_dungeon", exterior_entry, 41, 1, 0)
	var reentered_dungeon := dungeon_scene.instantiate()
	root.add_child(reentered_dungeon)
	reentered_dungeon.set_physics_process(false)
	await process_frame
	var reentered_player := reentered_dungeon.get_node("PlayerAnchor") as Node2D
	var dungeon_start: Vector2 = reentered_dungeon.call("_cell_to_world", Vector2i(2, 10))
	_expect(reentered_player.position == dungeon_start, "Reentrar deve começar no início da masmorra.")
	_expect(int(reentered_dungeon.get("player_hp")) == 41, "Reentrar deve preservar a vida atual.")
	_expect(int(reentered_dungeon.get("rifle_ammo")) == 1, "Reentrar deve preservar a munição atual.")
	_expect((game_state.get("dungeon_progress") as Dictionary).is_empty(), "Reentrar deve começar sem progresso interno.")
	reentered_dungeon.queue_free()
	_finish(game_state)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(game_state: Node) -> void:
	game_state.call("reset_session")
	if failures.is_empty():
		print("TESTE_MASMORRA_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
