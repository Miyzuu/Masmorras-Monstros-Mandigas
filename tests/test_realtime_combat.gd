extends SceneTree

const WEAPON_RIFLE := 0
const WEAPON_KNIFE := 1
const STATE_PATROL := 0
const STATE_CHASE := 1
const STATE_RETURN := 2

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

	_expect(exploration.get_script() != null, "O combate em tempo real deve compilar.")
	if exploration.get_script() == null:
		exploration.queue_free()
		await process_frame
		_finish(game_state)
		return

	_test_initial_state_and_weapon_switch(exploration)
	_test_auto_attack_while_moving(exploration)
	_test_rifle_rules(exploration)
	_test_knife_rules(exploration)
	_test_capanga_states_and_speeds(exploration)
	_test_capanga_attack_sequence(exploration)
	_test_successful_parry(exploration)
	_test_failed_parry(exploration)
	_test_feedback_durations(exploration)
	_test_player_defeat_and_regeneration(exploration)
	_test_capanga_defeat(exploration, game_state)

	exploration.queue_free()
	await process_frame
	_finish(game_state)


func _test_initial_state_and_weapon_switch(exploration: Node) -> void:
	_reset_state(exploration)
	_expect(int(exploration.get("player_hp")) == 100, "O Cangaceiro deve começar com 100 HP.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 150.0), "O Capanga deve começar com 150 HP.")
	_expect(int(exploration.get("rifle_ammo")) == 5, "O Rifle deve começar com 5 balas.")
	_expect(int(exploration.get("current_weapon")) == WEAPON_RIFLE, "O Rifle deve ser a arma inicial.")

	_expect(bool(exploration.call("_toggle_weapon")), "Q deve trocar do Rifle para a Peixeira.")
	_expect(int(exploration.get("current_weapon")) == WEAPON_KNIFE, "A Peixeira deve ficar equipada.")
	_expect(not bool(exploration.call("_toggle_weapon")), "Q não deve trocar novamente durante o cooldown.")
	exploration.call("_advance_timers", 0.49)
	_expect(not bool(exploration.call("_toggle_weapon")), "O cooldown de troca deve durar pelo menos 0,5 s.")
	exploration.call("_advance_timers", 0.02)
	_expect(bool(exploration.call("_toggle_weapon")), "Q deve voltar a funcionar após 0,5 s.")
	_expect(int(exploration.get("current_weapon")) == WEAPON_RIFLE, "A segunda troca válida deve reequipar o Rifle.")


func _test_auto_attack_while_moving(exploration: Node) -> void:
	_reset_state(exploration)
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	var destination: Vector2 = exploration.call("_cell_to_world", Vector2i(3, 10))
	exploration.set("movement_path", PackedVector2Array([destination]))
	exploration.set("path_index", 0)
	exploration.set("has_destination", true)
	var start_position := player.position

	exploration.call("_advance_realtime", 0.10, 0.10, 0.50)
	_expect(player.position.distance_to(start_position) > 0.0, "O Cangaceiro deve continuar andando durante o autoataque.")
	_expect(bool(exploration.get("has_destination")), "Atacar não deve cancelar o destino atual.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 125.0), "O autoataque de Rifle deve causar 25 de dano.")
	_expect(int(exploration.get("rifle_ammo")) == 4, "O autoataque deve consumir uma bala.")


func _test_rifle_rules(exploration: Node) -> void:
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	_expect(bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle deve alcançar exatamente 5 tiles.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 125.0), "Disparo normal deve causar 25 de dano.")
	exploration.call("_advance_timers", 1.19)
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle não deve atacar antes de 1,2 s.")
	exploration.call("_advance_timers", 0.02)
	_expect(bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle deve atacar após o intervalo de 1,2 s.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(7, 10))
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle não deve alcançar 6 tiles.")
	_expect(int(exploration.get("rifle_ammo")) == 5, "Ataque fora do alcance não deve gastar munição.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	_expect(bool(exploration.call("_attempt_auto_attack", 0.10, 0.10)), "O Rifle deve aceitar um roll crítico determinístico.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 110.0), "Crítico de Rifle deve causar 40 de dano.")
	var critical_popup := _last_popup(exploration)
	_expect(bool(critical_popup.get("bold", false)), "O número crítico deve ser desenhado em negrito.")
	_expect(int(critical_popup.get("font_size", 0)) == 22, "O número crítico deve ser maior.")
	_expect(critical_popup.get("color", Color.TRANSPARENT) == Color("df3328"), "O número crítico deve ser vermelho.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	_expect(bool(exploration.call("_attempt_auto_attack", 0.95, 0.10)), "Um disparo dentro do alcance deve ser executado mesmo quando erra.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 150.0), "Disparo errado não deve causar dano.")
	_expect(int(exploration.get("rifle_ammo")) == 4, "Disparo errado também deve consumir uma bala.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	for shot in range(5):
		exploration.set("player_attack_cooldown", 0.0)
		exploration.call("_attempt_auto_attack", 0.95, 0.50)
	_expect(int(exploration.get("rifle_ammo")) == 0, "Cinco disparos devem esgotar o Rifle.")
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle não deve atacar sem munição.")


func _test_knife_rules(exploration: Node) -> void:
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D

	_reset_state(exploration)
	exploration.set("current_weapon", WEAPON_KNIFE)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(2, 10))
	_expect(bool(exploration.call("_attempt_auto_attack", 0.95, 0.50)), "A Peixeira deve alcançar exatamente 1 tile.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 130.0), "Peixeira normal deve causar 20 de dano e sempre acertar.")
	exploration.call("_advance_timers", 0.79)
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.95, 0.50)), "A Peixeira não deve atacar antes de 0,8 s.")
	exploration.call("_advance_timers", 0.02)
	_expect(bool(exploration.call("_attempt_auto_attack", 0.95, 0.50)), "A Peixeira deve atacar após 0,8 s.")

	_reset_state(exploration)
	exploration.set("current_weapon", WEAPON_KNIFE)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(3, 10))
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.10)), "A Peixeira não deve alcançar 2 tiles.")

	_reset_state(exploration)
	exploration.set("current_weapon", WEAPON_KNIFE)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(2, 10))
	exploration.call("_attempt_auto_attack", 0.95, 0.10)
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 120.0), "Crítico de Peixeira deve causar 30 de dano.")


func _test_capanga_states_and_speeds(exploration: Node) -> void:
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(14, 6))
	capanga.position = exploration.call("_cell_to_world", Vector2i(8, 6))
	exploration.call("_advance_capanga_ai", 0.0)
	_expect(int(exploration.get("capanga_state")) == STATE_CHASE, "O Capanga deve detectar o herói a 6 tiles.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(0, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(8, 6))
	exploration.set("capanga_state", STATE_CHASE)
	exploration.call("_advance_capanga_ai", 0.0)
	_expect(int(exploration.get("capanga_state")) == STATE_RETURN, "O Capanga deve desistir acima de 10 tiles.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(0, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(8, 6))
	exploration.call("_damage_capanga", 1, false)
	_expect(int(exploration.get("capanga_state")) == STATE_CHASE, "Sofrer dano deve iniciar perseguição.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(0, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(8, 6))
	var patrol_start := capanga.position
	exploration.call("_move_capanga_toward", Vector2i(11, 4), 70.0, 0.10)
	_expect(is_equal_approx(capanga.position.distance_to(patrol_start), 7.0), "A patrulha deve avançar a 70 px/s.")

	capanga.position = exploration.call("_cell_to_world", Vector2i(8, 6))
	exploration.set("capanga_path", PackedVector2Array())
	exploration.set("capanga_path_index", 0)
	exploration.set("capanga_repath_remaining", 0.0)
	var chase_start := capanga.position
	exploration.call("_move_capanga_toward", Vector2i(7, 7), 150.0, 0.10)
	_expect(is_equal_approx(capanga.position.distance_to(chase_start), 15.0), "A perseguição deve avançar a 150 px/s.")


func _test_capanga_attack_sequence(exploration: Node) -> void:
	_reset_state(exploration)
	_set_adjacent_positions(exploration)
	exploration.set("capanga_state", STATE_CHASE)

	exploration.call("_advance_capanga_attack", 1.49)
	_expect(int(exploration.get("player_hp")) == 100, "O Capanga não deve atacar antes de 1,5 s.")
	exploration.call("_advance_capanga_attack", 0.02)
	_expect(int(exploration.get("player_hp")) == 85, "O primeiro ataque deve causar 15 de dano.")
	exploration.call("_advance_capanga_attack", 1.5)
	exploration.call("_advance_capanga_attack", 1.5)
	_expect(int(exploration.get("player_hp")) == 55, "Três ataques básicos devem causar 45 de dano.")
	exploration.call("_advance_capanga_attack", 1.5)
	_expect(bool(exploration.get("heavy_warning_active")), "O quarto ataque deve iniciar o alerta pesado.")
	_expect(int(exploration.get("player_hp")) == 55, "O alerta pesado não deve causar dano imediato.")

	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	var warning_position := capanga.position
	exploration.call("_advance_capanga_ai", 0.30)
	_expect(capanga.position == warning_position, "O Capanga deve ficar parado durante o alerta pesado.")
	exploration.call("_advance_capanga_attack", 0.69)
	_expect(int(exploration.get("player_hp")) == 55, "O pesado não deve acertar antes de 0,7 s.")
	exploration.call("_advance_capanga_attack", 0.02)
	_expect(int(exploration.get("player_hp")) == 25, "O ataque pesado deve causar 30 de dano após o alerta.")


func _test_successful_parry(exploration: Node) -> void:
	_reset_state(exploration)
	_set_adjacent_positions(exploration)
	exploration.set("capanga_state", STATE_CHASE)
	exploration.set("capanga_basic_attack_count", 3)
	exploration.set("heavy_warning_active", true)
	exploration.set("heavy_warning_remaining", 0.7)

	_expect(bool(exploration.call("_attempt_parry")), "Space durante o alerta deve aparar o pesado.")
	_expect(not bool(exploration.get("heavy_warning_active")), "O aparo deve cancelar o ataque pesado.")
	_expect(int(exploration.get("player_hp")) == 100, "O aparo deve anular todo o dano pesado.")
	var popup := _last_popup(exploration)
	_expect(str(popup.get("text", "")) == "HÁ", "O aparo deve mostrar HÁ.")
	_expect(popup.get("color", Color.TRANSPARENT) == Color.WHITE, "O texto HÁ deve ser branco.")


func _test_failed_parry(exploration: Node) -> void:
	_reset_state(exploration)
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	var destination: Vector2 = exploration.call("_cell_to_world", Vector2i(3, 10))
	exploration.set("movement_path", PackedVector2Array([destination]))
	exploration.set("path_index", 0)
	exploration.set("has_destination", true)
	var start_position := player.position

	_expect(not bool(exploration.call("_attempt_parry")), "Space fora do alerta deve falhar.")
	_expect(is_equal_approx(float(exploration.get("stun_remaining")), 0.7), "A falha deve aplicar stun de 0,7 s.")
	exploration.call("_advance_realtime", 0.69, 0.10, 0.50)
	_expect(player.position == start_position, "O stun deve bloquear movimento.")
	_expect(not bool(exploration.call("_toggle_weapon")), "O stun deve bloquear Q.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 150.0), "O stun deve bloquear ataques.")

	exploration.call("_advance_timers", 0.02)
	_expect(bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "Após o stun, o autoataque cancelado deve ser processado.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 150.0), "O primeiro autoataque após a falha deve ser perdido.")
	_expect(not bool(exploration.get("skip_next_player_attack")), "O cancelamento deve afetar somente um autoataque.")


func _test_feedback_durations(exploration: Node) -> void:
	_reset_state(exploration)
	exploration.call("_spawn_popup", "25", Vector2.ZERO, Color.WHITE, 15, false)
	exploration.call("_advance_timers", 0.79)
	_expect((exploration.get("combat_popups") as Array).size() == 1, "O número de dano deve durar 0,8 s.")
	exploration.call("_advance_timers", 0.02)
	_expect((exploration.get("combat_popups") as Array).is_empty(), "O número de dano deve desaparecer após 0,8 s.")

	exploration.call("_damage_player", 15)
	_expect(float(exploration.get("damage_border_remaining")) > 0.0, "Receber dano deve ativar a borda vermelha.")
	exploration.call("_advance_timers", 0.14)
	_expect(float(exploration.get("damage_border_remaining")) > 0.0, "A borda deve permanecer antes de 0,15 s.")
	exploration.call("_advance_timers", 0.02)
	_expect(is_zero_approx(float(exploration.get("damage_border_remaining"))), "A borda deve terminar após 0,15 s.")


func _test_player_defeat_and_regeneration(exploration: Node) -> void:
	_reset_state(exploration)
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(2, 10))
	exploration.set("player_hp", 15)
	exploration.set("rifle_ammo", 2)
	exploration.set("capanga_hp", 35.0)
	exploration.set("capanga_state", STATE_CHASE)

	_expect(bool(exploration.call("_damage_player", 15)), "Dano letal deve acionar a derrota.")
	_expect(int(exploration.get("player_hp")) == 40, "O Cangaceiro deve reaparecer com 40 HP.")
	_expect(player.position == exploration.call("_cell_to_world", Vector2i(1, 10)), "O Cangaceiro deve reaparecer no PLAYER_START.")
	_expect(int(exploration.get("rifle_ammo")) == 2, "A derrota deve preservar a munição.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 35.0), "A derrota deve preservar a vida atual do Capanga.")
	_expect(int(exploration.get("capanga_state")) == STATE_RETURN, "Após a derrota, o Capanga deve retornar à patrulha.")

	for step in range(400):
		exploration.call("_advance_capanga_ai", 0.10)
		if int(exploration.get("capanga_state")) == STATE_PATROL:
			break
	_expect(
		int(exploration.get("capanga_state")) == STATE_PATROL,
		"O Capanga deve alcançar novamente a rota de patrulha; estado=%d, posição=%s." % [
			int(exploration.get("capanga_state")),
			str(capanga.position),
		]
	)
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 35.0), "O Capanga não deve regenerar enquanto retorna.")
	exploration.call("_advance_capanga_ai", 1.0)
	_expect(
		is_equal_approx(float(exploration.get("capanga_hp")), 40.0),
		"Patrulhando, o Capanga deve regenerar 5 HP por segundo; vida=%.2f." % float(exploration.get("capanga_hp"))
	)

	exploration.set("capanga_hp", 40.0)
	exploration.set("capanga_state", STATE_CHASE)
	exploration.call("_advance_capanga_ai", 1.0)
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 40.0), "O Capanga não deve regenerar durante a perseguição.")


func _test_capanga_defeat(exploration: Node, game_state: Node) -> void:
	_reset_state(exploration)
	_set_adjacent_positions(exploration)
	exploration.set("current_weapon", WEAPON_KNIFE)
	exploration.set("capanga_hp", 20.0)
	var player_hp_before := int(exploration.get("player_hp"))
	exploration.call("_attempt_auto_attack", 0.95, 0.50)

	_expect(not bool(exploration.get("capanga_active")), "O Capanga deve desaparecer ao chegar a 0 HP.")
	_expect(bool(game_state.call("is_encounter_defeated", "capanga_01")), "A morte do Capanga deve persistir na sessão.")
	exploration.call("_advance_capanga_ai", 5.0)
	exploration.call("_advance_capanga_attack", 5.0)
	_expect(int(exploration.get("player_hp")) == player_hp_before, "O Capanga morto não deve voltar a atacar.")
	_expect(is_zero_approx(float(exploration.get("capanga_hp"))), "O Capanga morto não deve regenerar.")


func _reset_state(exploration: Node) -> void:
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
	exploration.set("capanga_state", STATE_PATROL)
	exploration.set("capanga_patrol_target_index", 1)
	exploration.set("capanga_return_target_index", 0)
	exploration.set("capanga_path", PackedVector2Array())
	exploration.set("capanga_path_index", 0)
	exploration.set("capanga_repath_remaining", 0.0)
	exploration.set("capanga_patrol_pause_remaining", 0.0)
	exploration.set("capanga_attack_cooldown", 1.5)
	exploration.set("capanga_basic_attack_count", 0)
	exploration.set("heavy_warning_active", false)
	exploration.set("heavy_warning_remaining", 0.0)
	exploration.set("damage_border_remaining", 0.0)
	var popups: Array = exploration.get("combat_popups")
	popups.clear()
	exploration.call("_update_hud")
	exploration.call("_update_damage_border")


func _set_adjacent_positions(exploration: Node) -> void:
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(2, 10))


func _last_popup(exploration: Node) -> Dictionary:
	var popups: Array = exploration.get("combat_popups")
	if popups.is_empty():
		return {}
	return popups[popups.size() - 1]


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(game_state: Node) -> void:
	game_state.call("reset_session")
	if failures.is_empty():
		print("TESTE_COMBATE_TEMPO_REAL_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
