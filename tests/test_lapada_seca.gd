extends SceneTree

const WEAPON_RIFLE := 0
const WEAPON_KNIFE := 1

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

	_test_charge_accumulation(exploration, game_state)
	_test_aiming_requirements_and_cancellation(exploration, game_state)
	_test_firing_and_fatal_damage(exploration, game_state)
	_test_persistence_across_scenes(exploration, game_state, packed_scene)

	exploration.queue_free()
	await process_frame
	_finish(game_state)


func _test_charge_accumulation(exploration: Node, game_state: Node) -> void:
	_reset_state(exploration, game_state)
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))

	_expect(int(game_state.get("lapada_charges")) == 0, "Cargas iniciais devem ser 0.")
	_expect(not bool(game_state.call("has_lapada_ready")), "Lapada Seca não deve estar pronta com 0 cargas.")

	# Disparo normal (sem crítico) não deve aumentar carga
	exploration.set("player_attack_cooldown", 0.0)
	exploration.call("_attempt_auto_attack", 0.10, 0.50)
	_expect(int(game_state.get("lapada_charges")) == 0, "Disparo normal de rifle não deve acumular carga.")

	# 1º Crítico de Rifle
	exploration.set("player_attack_cooldown", 0.0)
	exploration.call("_attempt_auto_attack", 0.10, 0.10)
	_expect(int(game_state.get("lapada_charges")) == 1, "1º crítico de rifle deve somar 1 carga.")

	# 2º Crítico de Rifle
	exploration.set("player_attack_cooldown", 0.0)
	exploration.call("_attempt_auto_attack", 0.10, 0.10)
	_expect(int(game_state.get("lapada_charges")) == 2, "2º crítico de rifle deve somar a 2 cargas.")

	# 3º Crítico de Rifle
	exploration.set("player_attack_cooldown", 0.0)
	exploration.call("_attempt_auto_attack", 0.10, 0.10)
	_expect(int(game_state.get("lapada_charges")) == 3, "3º crítico de rifle deve atingir 3 cargas.")
	_expect(bool(game_state.call("has_lapada_ready")), "Lapada Seca deve ficar pronta com 3 cargas.")

	# 4º Crítico não deve ultrapassar 3
	exploration.set("player_attack_cooldown", 0.0)
	exploration.call("_attempt_auto_attack", 0.10, 0.10)
	_expect(int(game_state.get("lapada_charges")) == 3, "Cargas devem ter limite máximo de 3.")


func _test_aiming_requirements_and_cancellation(exploration: Node, game_state: Node) -> void:
	_reset_state(exploration, game_state)
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))

	# Sem 3 cargas, não pode mirar
	game_state.set("lapada_charges", 2)
	_expect(not bool(exploration.call("_start_aiming_lapada")), "Não deve permitir mirar com menos de 3 cargas.")

	# Com 3 cargas mas Peixeira equipada, não pode mirar
	game_state.set("lapada_charges", 3)
	exploration.set("current_weapon", WEAPON_KNIFE)
	_expect(not bool(exploration.call("_start_aiming_lapada")), "Não deve permitir mirar com a Peixeira equipada.")

	# Com 3 cargas e Rifle sem munição, não pode mirar
	exploration.set("current_weapon", WEAPON_RIFLE)
	exploration.set("rifle_ammo", 0)
	_expect(not bool(exploration.call("_start_aiming_lapada")), "Não deve permitir mirar sem munição no Rifle.")

	# Com 3 cargas, Rifle e munição válida, mira com sucesso
	exploration.set("rifle_ammo", 5)
	_expect(bool(exploration.call("_start_aiming_lapada")), "Deve iniciar a mira com todos os requisitos atendidos.")
	_expect(bool(exploration.get("is_aiming_lapada")), "Estado de mira deve ficar ativo.")
	_expect(is_equal_approx(float(exploration.get("aim_timer")), 1.0), "O tempo de mira deve ser 1,0 s.")

	# Cancelamento de mira por dano recebido
	exploration.call("_damage_player", 15)
	_expect(not bool(exploration.get("is_aiming_lapada")), "Receber dano deve cancelar a mira imediatamente.")
	_expect(int(game_state.get("lapada_charges")) == 3, "Cancelar a mira não deve consumir as cargas acumuladas.")


func _test_firing_and_fatal_damage(exploration: Node, game_state: Node) -> void:
	_reset_state(exploration, game_state)
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	game_state.set("lapada_charges", 3)
	exploration.set("rifle_ammo", 5)
	exploration.set("capanga_hp", 150.0)

	exploration.call("_start_aiming_lapada")
	_expect(bool(exploration.get("is_aiming_lapada")), "Mira iniciada para teste de disparo.")

	# Avança 0.95 s — ainda mirando, capanga vivo
	exploration.call("_advance_timers", 0.95)
	_expect(bool(exploration.get("is_aiming_lapada")), "Ainda deve estar mirando antes de 1,0 s.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 150.0), "Capanga não deve sofrer dano antes do fim da mira.")

	# Avança o restante 0.06 s — completa mira e dispara
	exploration.call("_advance_timers", 0.06)
	_expect(not bool(exploration.get("is_aiming_lapada")), "A mira deve finalizar ao disparar.")
	_expect(is_zero_approx(float(exploration.get("capanga_hp"))), "Lapada Seca deve causar dano letal instantâneo ao Capanga.")
	_expect(not bool(exploration.get("capanga_active")), "O Capanga deve ser eliminado.")
	_expect(int(exploration.get("rifle_ammo")) == 4, "Disparar Lapada Seca deve consumir 1 bala.")
	_expect(int(game_state.get("lapada_charges")) == 0, "Disparar Lapada Seca deve zerar as 3 cargas.")
	_expect(bool(game_state.call("is_encounter_defeated", "capanga_01")), "Derrota do Capanga deve persistir no GameState.")


func _test_persistence_across_scenes(exploration: Node, game_state: Node, packed_scene: PackedScene) -> void:
	_reset_state(exploration, game_state)
	game_state.set("lapada_charges", 2)

	# Simula troca de cena
	exploration.queue_free()
	await process_frame

	var new_exploration := packed_scene.instantiate()
	root.add_child(new_exploration)
	new_exploration.set_physics_process(false)
	await process_frame

	_expect(int(game_state.get("lapada_charges")) == 2, "As cargas da Lapada Seca devem persistir entre cenas no GameState.")
	new_exploration.queue_free()
	await process_frame


func _reset_state(exploration: Node, game_state: Node) -> void:
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(8, 6))
	exploration.set("movement_path", PackedVector2Array())
	exploration.set("path_index", 0)
	exploration.set("has_destination", false)
	exploration.set("player_hp", 100)
	exploration.set("rifle_ammo", 5)
	exploration.set("current_weapon", WEAPON_RIFLE)
	exploration.set("player_attack_cooldown", 0.0)
	exploration.set("weapon_switch_cooldown", 0.0)
	exploration.set("stun_remaining", 0.0)
	exploration.set("skip_next_player_attack", false)
	exploration.set("capanga_active", true)
	exploration.set("capanga_hp", 150.0)
	exploration.set("is_aiming_lapada", false)
	exploration.set("aim_timer", 0.0)
	game_state.set("lapada_charges", 0)
	var popups: Array = exploration.get("combat_popups")
	popups.clear()
	exploration.call("_update_hud")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(game_state: Node) -> void:
	game_state.call("reset_session")
	if failures.is_empty():
		print("TESTE_LAPADA_SECA_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
