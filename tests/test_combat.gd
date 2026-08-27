extends SceneTree

const ATTACK_RIFLE := 1
const ATTACK_KNIFE := 2

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.call("reset_session")
	game_state.call("begin_encounter", "capanga_01", Vector2.ZERO)

	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	_expect(packed_scene != null, "A cena de combate deve carregar.")
	if packed_scene == null:
		_finish(game_state)
		return

	var combat := packed_scene.instantiate()
	root.add_child(combat)
	await process_frame
	_expect(combat.get_script() != null, "O script da cena de combate deve compilar e ser carregado.")
	if combat.get_script() == null:
		combat.queue_free()
		await process_frame
		_finish(game_state)
		return

	_test_initial_state(combat)
	_test_capanga_blocks_movement(combat)
	_test_knife_range(combat)
	_test_rifle_resolution(combat)
	_test_rifle_range(combat)
	_test_shot_obstacles(combat)
	_test_capanga_action(combat)
	_test_defeat_reset(combat, game_state)
	_test_victory(combat, game_state)

	combat.queue_free()
	await process_frame
	_finish(game_state)


func _test_initial_state(combat: Node) -> void:
	_expect(int(combat.get("hero_hp")) == 100, "O Cangaceiro deve começar com 100 de vida.")
	_expect(int(combat.get("capanga_hp")) == 60, "O Capanga deve começar com 60 de vida.")
	_expect(int(combat.get("movement_left")) == 4, "O Cangaceiro deve começar com 4 movimentos.")
	_expect(int(combat.get("round_number")) == 1, "O combate deve começar na rodada 1.")
	_expect(bool(combat.get("player_turn")), "O Cangaceiro deve agir primeiro.")


func _test_capanga_blocks_movement(combat: Node) -> void:
	combat.call("_reset_combat", "Teste de ocupação.")
	combat.set("hero_cell", Vector2i(1, 8))
	combat.set("capanga_cell", Vector2i(2, 8))
	combat.call("_rebuild_reachable")

	var reachable: Dictionary = combat.get("reachable")
	_expect(not reachable.has(Vector2i(2, 8)), "A casa do Capanga vivo não deve ser alcançável.")
	combat.call("_try_move_to", Vector2i(2, 8))
	_expect(combat.get("hero_cell") == Vector2i(1, 8), "O Cangaceiro não deve ocupar a casa do Capanga.")


func _test_knife_range(combat: Node) -> void:
	combat.call("_reset_combat", "Teste da Peixeira fora do alcance.")
	combat.set("hero_cell", Vector2i(1, 8))
	combat.set("capanga_cell", Vector2i(3, 8))
	var outside_accepted := bool(combat.call("_attempt_attack", ATTACK_KNIFE))
	_expect(not outside_accepted, "A Peixeira não deve alcançar duas casas.")
	_expect(int(combat.get("capanga_hp")) == 60, "Ataque fora do alcance não deve causar dano.")
	_expect(int(combat.get("round_number")) == 1, "Ataque inválido não deve encerrar o turno.")

	combat.call("_reset_combat", "Teste da Peixeira dentro do alcance.")
	combat.set("hero_cell", Vector2i(1, 8))
	combat.set("capanga_cell", Vector2i(2, 8))
	var inside_accepted := bool(combat.call("_attempt_attack", ATTACK_KNIFE))
	_expect(inside_accepted, "A Peixeira deve atingir uma casa adjacente.")
	_expect(int(combat.get("capanga_hp")) == 40, "A Peixeira deve causar 20 de dano.")
	_expect(int(combat.get("hero_hp")) == 85, "O Capanga adjacente deve responder com 15 de dano.")
	_expect(int(combat.get("round_number")) == 2, "Ataque válido deve encerrar o turno.")


func _test_rifle_resolution(combat: Node) -> void:
	var normal: Dictionary = combat.call("_resolve_rifle", 0.10, 0.50)
	_expect(bool(normal["hit"]), "Roll de acerto válido deve acertar o Rifle.")
	_expect(not bool(normal["critical"]), "Roll crítico alto não deve gerar crítico.")
	_expect(int(normal["damage"]) == 25, "Disparo normal deve causar 25 de dano.")

	var critical: Dictionary = combat.call("_resolve_rifle", 0.10, 0.10)
	_expect(bool(critical["hit"]), "Disparo crítico também deve registrar acerto.")
	_expect(bool(critical["critical"]), "Roll crítico válido deve gerar crítico.")
	_expect(int(critical["damage"]) == 40, "Disparo crítico deve causar 40 de dano.")

	var miss: Dictionary = combat.call("_resolve_rifle", 0.95, 0.10)
	_expect(not bool(miss["hit"]), "Roll de acerto alto deve errar o Rifle.")
	_expect(not bool(miss["critical"]), "Um disparo errado não pode ser crítico.")
	_expect(int(miss["damage"]) == 0, "Um disparo errado não deve causar dano.")


func _test_rifle_range(combat: Node) -> void:
	combat.call("_reset_combat", "Teste do alcance 7.")
	combat.set("hero_cell", Vector2i(0, 9))
	combat.set("capanga_cell", Vector2i(7, 9))
	var range_seven_accepted := bool(combat.call(
		"_attempt_attack",
		ATTACK_RIFLE,
		0.10,
		0.50
	))
	_expect(range_seven_accepted, "O Rifle deve alcançar exatamente 7 casas ortogonais.")
	_expect(int(combat.get("capanga_hp")) == 35, "O Disparo no alcance 7 deve causar 25 de dano.")

	combat.call("_reset_combat", "Teste do alcance 8.")
	combat.set("hero_cell", Vector2i(0, 9))
	combat.set("capanga_cell", Vector2i(8, 9))
	var range_eight_accepted := bool(combat.call(
		"_attempt_attack",
		ATTACK_RIFLE,
		0.10,
		0.50
	))
	_expect(not range_eight_accepted, "O Rifle não deve alcançar 8 casas ortogonais.")
	_expect(int(combat.get("capanga_hp")) == 60, "Disparo além do alcance não deve causar dano.")
	_expect(int(combat.get("round_number")) == 1, "Disparo além do alcance não deve encerrar o turno.")


func _test_shot_obstacles(combat: Node) -> void:
	combat.call("_reset_combat", "Teste da parede.")
	combat.set("hero_cell", Vector2i(1, 1))
	combat.set("capanga_cell", Vector2i(5, 1))
	var wall_shot_accepted := bool(combat.call(
		"_attempt_attack",
		ATTACK_RIFLE,
		0.10,
		0.50
	))
	_expect(not wall_shot_accepted, "A parede deve bloquear o Disparo.")
	_expect(int(combat.get("capanga_hp")) == 60, "Disparo bloqueado pela parede não deve causar dano.")

	combat.call("_reset_combat", "Teste das rochas.")
	combat.set("hero_cell", Vector2i(5, 2))
	combat.set("capanga_cell", Vector2i(8, 2))
	var rock_shot_accepted := bool(combat.call(
		"_attempt_attack",
		ATTACK_RIFLE,
		0.10,
		0.50
	))
	_expect(rock_shot_accepted, "Rochas não devem bloquear o Disparo.")
	_expect(int(combat.get("capanga_hp")) == 35, "Disparo através de rochas deve causar 25 de dano.")


func _test_capanga_action(combat: Node) -> void:
	combat.call("_reset_combat", "Teste da IA do Capanga.")
	combat.set("hero_cell", Vector2i(1, 8))
	combat.set("capanga_cell", Vector2i(5, 8))
	combat.call("_run_capanga_action")
	_expect(combat.get("capanga_cell") == Vector2i(2, 8), "O Capanga deve avançar no máximo 3 casas.")
	_expect(int(combat.get("hero_hp")) == 85, "O Capanga deve atacar ao terminar adjacente.")


func _test_defeat_reset(combat: Node, game_state: Node) -> void:
	combat.call("_reset_combat", "Teste da derrota.")
	combat.set("hero_cell", Vector2i(1, 8))
	combat.set("capanga_cell", Vector2i(2, 8))
	combat.set("hero_hp", 15)
	combat.set("capanga_hp", 40)
	combat.call("_end_player_turn", "Teste.")

	_expect(int(combat.get("hero_hp")) == 100, "A derrota deve restaurar toda a vida do Cangaceiro.")
	_expect(int(combat.get("capanga_hp")) == 60, "A derrota deve restaurar toda a vida do Capanga.")
	_expect(combat.get("hero_cell") == Vector2i(1, 8), "A derrota deve restaurar a posição inicial do Cangaceiro.")
	_expect(combat.get("capanga_cell") == Vector2i(8, 1), "A derrota deve restaurar a posição inicial do Capanga.")
	_expect(int(combat.get("round_number")) == 1, "A derrota deve restaurar a rodada inicial.")
	_expect(bool(combat.get("player_turn")), "A derrota deve devolver o turno ao Cangaceiro.")
	_expect(str(game_state.get("active_encounter_id")) == "capanga_01", "A derrota deve manter o encontro ativo.")
	_expect(not bool(game_state.call("is_encounter_defeated", "capanga_01")), "A derrota não deve marcar o encontro como vencido.")


func _test_victory(combat: Node, game_state: Node) -> void:
	combat.call("_reset_combat", "Teste da vitória.")
	combat.set("hero_cell", Vector2i(1, 8))
	combat.set("capanga_cell", Vector2i(2, 8))
	combat.set("hero_hp", 100)
	combat.set("capanga_hp", 20)
	var attack_accepted := bool(combat.call("_attempt_attack", ATTACK_KNIFE))

	_expect(attack_accepted, "O golpe final válido deve ser aceito.")
	_expect(int(combat.get("capanga_hp")) == 0, "O golpe final deve reduzir a vida do Capanga a zero.")
	_expect(int(combat.get("hero_hp")) == 100, "O Capanga derrotado não deve contra-atacar.")
	_expect(bool(combat.get("encounter_transitioning")), "A vitória deve iniciar a transição de retorno.")
	_expect(bool(game_state.call("is_encounter_defeated", "capanga_01")), "A vitória deve marcar o encontro como vencido.")
	_expect(str(game_state.get("active_encounter_id")).is_empty(), "A vitória deve encerrar o encontro ativo.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(game_state: Node) -> void:
	game_state.call("reset_session")
	if failures.is_empty():
		print("TESTE_COMBATE_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
