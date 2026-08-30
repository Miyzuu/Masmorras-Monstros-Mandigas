extends SceneTree

const WEAPON_RIFLE := 0
const WEAPON_KNIFE := 1
const CAPANGA_ID := "capanga_01"

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
	_test_instant_requirements_and_failures(exploration, game_state)
	_test_instant_firing_and_fatal_damage(exploration, game_state)
	await _test_persistence_across_scenes(exploration, game_state, packed_scene)

	_finish(game_state)


func _test_charge_accumulation(exploration: Node, game_state: Node) -> void:
	_reset_state(exploration, game_state)
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D

	_expect(int(game_state.get("lapada_charges")) == 0, "As cargas iniciais devem ser 0.")
	_expect(not bool(game_state.call("has_lapada_ready")), "A Lapada não deve começar pronta.")

	exploration.set("current_weapon", WEAPON_KNIFE)
	capanga.position = exploration.call("_cell_to_world", Vector2i(2, 10))
	exploration.call("_attempt_auto_attack", 0.10, 0.10)
	_expect(int(game_state.get("lapada_charges")) == 0, "Crítico de Peixeira não deve gerar carga.")

	exploration.set("current_weapon", WEAPON_RIFLE)
	exploration.set("capanga_hp", 150.0)
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	exploration.set("player_attack_cooldown", 0.0)
	exploration.call("_attempt_auto_attack", 0.95, 0.10)
	_expect(int(game_state.get("lapada_charges")) == 0, "Disparo errado não deve gerar carga.")
	exploration.set("player_attack_cooldown", 0.0)
	exploration.call("_attempt_auto_attack", 0.10, 0.50)
	_expect(int(game_state.get("lapada_charges")) == 0, "Disparo normal não deve gerar carga.")

	for expected_charge in range(1, 4):
		exploration.set("player_attack_cooldown", 0.0)
		exploration.call("_attempt_auto_attack", 0.10, 0.10)
		_expect(
			int(game_state.get("lapada_charges")) == expected_charge,
			"Crítico de Rifle deve acumular a carga %d." % expected_charge
		)
	_expect(bool(game_state.call("has_lapada_ready")), "A Lapada deve ficar pronta com 3 cargas.")
	_expect(not bool(game_state.call("add_lapada_charge")), "Uma quarta carga deve ser recusada.")
	_expect(int(game_state.get("lapada_charges")) == 3, "As cargas devem respeitar o limite de 3.")
	_expect(player.position == exploration.call("_cell_to_world", Vector2i(1, 10)), "O teste não deve mover o herói.")


func _test_instant_requirements_and_failures(exploration: Node, game_state: Node) -> void:
	_reset_state(exploration, game_state)
	var capanga := exploration.get_node("CapangaAnchor") as Node2D

	game_state.set("lapada_charges", 2)
	_expect(not bool(exploration.call("_attempt_lapada_seca")), "Menos de 3 cargas não deve disparar a Lapada.")

	game_state.set("lapada_charges", 3)
	exploration.set("current_weapon", WEAPON_KNIFE)
	_expect(not bool(exploration.call("_attempt_lapada_seca")), "A Peixeira não deve disparar a Lapada.")

	exploration.set("current_weapon", WEAPON_RIFLE)
	exploration.set("rifle_ammo", 0)
	_expect(not bool(exploration.call("_attempt_lapada_seca")), "Rifle sem munição não deve disparar a Lapada.")

	exploration.set("rifle_ammo", 5)
	capanga.position = exploration.call("_cell_to_world", Vector2i(7, 10))
	_expect(not bool(exploration.call("_attempt_lapada_seca")), "Alvo fora do alcance não deve receber a Lapada.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 150.0), "Alvo fora do alcance não deve sofrer dano.")

	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	exploration.set("is_reloading", true)
	_expect(not bool(exploration.call("_attempt_lapada_seca")), "A recarga deve bloquear a Lapada.")
	exploration.set("is_reloading", false)
	exploration.set("stun_remaining", 0.7)
	_expect(not bool(exploration.call("_attempt_lapada_seca")), "O stun deve bloquear a Lapada.")
	_expect(int(exploration.get("rifle_ammo")) == 5, "Falhas de condição não devem consumir munição.")
	_expect(int(game_state.get("lapada_charges")) == 3, "Falhas de condição não devem consumir cargas.")


func _test_instant_firing_and_fatal_damage(exploration: Node, game_state: Node) -> void:
	_reset_state(exploration, game_state)
	game_state.set("lapada_charges", 3)
	var destination: Vector2 = exploration.call("_cell_to_world", Vector2i(3, 10))
	exploration.set("movement_path", PackedVector2Array([destination]))
	exploration.set("path_index", 0)
	exploration.set("has_destination", true)

	_expect(bool(exploration.call("_attempt_lapada_seca")), "E deve disparar a Lapada imediatamente.")
	_expect(is_zero_approx(float(exploration.get("capanga_hp"))), "A Lapada deve eliminar o Capanga no mesmo instante.")
	_expect(not bool(exploration.get("capanga_active")), "O Capanga eliminado deve ficar inativo.")
	_expect(int(exploration.get("rifle_ammo")) == 4, "A Lapada deve consumir 1 bala.")
	_expect(int(game_state.get("lapada_charges")) == 0, "A Lapada deve zerar as 3 cargas.")
	_expect(bool(game_state.call("is_encounter_defeated", CAPANGA_ID)), "A derrota deve persistir no GameState.")
	_expect(bool(exploration.get("has_destination")), "A Lapada instantânea não deve interromper o movimento.")


func _test_persistence_across_scenes(
	exploration: Node,
	game_state: Node,
	packed_scene: PackedScene
) -> void:
	_reset_state(exploration, game_state)
	game_state.set("lapada_charges", 2)
	exploration.queue_free()
	await process_frame

	var new_exploration := packed_scene.instantiate()
	root.add_child(new_exploration)
	new_exploration.set_physics_process(false)
	await process_frame

	_expect(int(game_state.get("lapada_charges")) == 2, "As cargas devem persistir entre cenas.")
	new_exploration.queue_free()
	await process_frame


func _reset_state(exploration: Node, game_state: Node) -> void:
	game_state.call("reset_session")
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	exploration.set("movement_path", PackedVector2Array())
	exploration.set("path_index", 0)
	exploration.set("has_destination", false)
	exploration.set("player_hp", 100)
	exploration.set("rifle_ammo", 5)
	exploration.set("rifle_reserve_ammo", 10)
	exploration.set("current_weapon", WEAPON_RIFLE)
	exploration.set("player_attack_cooldown", 0.0)
	exploration.set("weapon_switch_cooldown", 0.0)
	exploration.set("stun_remaining", 0.0)
	exploration.set("skip_next_player_attack", false)
	exploration.set("capanga_active", true)
	exploration.set("capanga_hp", 150.0)
	exploration.set("heavy_warning_active", false)
	exploration.set("is_reloading", false)
	exploration.set("reload_remaining", 0.0)
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
