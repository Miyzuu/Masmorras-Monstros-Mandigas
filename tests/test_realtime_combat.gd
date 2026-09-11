extends SceneTree

const WEAPON_RIFLE := 0
const WEAPON_KNIFE := 1
const STATE_PATROL := 0
const STATE_CHASE := 1
const STATE_RETURN := 2
const SFX_RIFLE := "res://assets/art/audio/rifle_tiro.wav"
const SFX_RELOAD := "res://assets/art/audio/recarregar.wav"
const SFX_CRITICAL := "res://assets/art/audio/critical_hit.wav"
const SFX_PEIXEIRA_DRAW := "res://assets/art/audio/peixeira_draw.wav"
const SFX_PEIXEIRA_HIT := "res://assets/art/audio/peixeira_hit.wav"
const SFX_EQUIP_RIFLE := "res://assets/art/audio/equipando_rifle.wav"
const SFX_COIN := "res://assets/art/audio/moeda_popup.wav"

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
	_test_realtime_hud_contract(exploration)
	_test_reload_rules(exploration)
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
	_expect(int(exploration.get("rifle_reserve_ammo")) == 10, "A reserva deve começar com 10 balas.")
	_expect(int(exploration.get("current_weapon")) == WEAPON_RIFLE, "O Rifle deve ser a arma inicial.")

	_clear_sfx_players()
	_expect(bool(exploration.call("_toggle_weapon")), "Q deve trocar do Rifle para a Peixeira.")
	_expect(_count_sfx(SFX_PEIXEIRA_DRAW) == 1, "Trocar para Peixeira deve tocar o saque uma vez.")
	_expect(int(exploration.get("current_weapon")) == WEAPON_KNIFE, "A Peixeira deve ficar equipada.")
	_clear_sfx_players()
	_expect(not bool(exploration.call("_toggle_weapon")), "Q não deve trocar novamente durante o cooldown.")
	_expect(_count_sfx(SFX_PEIXEIRA_DRAW) == 0, "Troca bloqueada não deve repetir o saque da Peixeira.")
	_expect(_count_sfx(SFX_EQUIP_RIFLE) == 0, "Troca bloqueada não deve tocar o equipamento do Rifle.")
	exploration.call("_advance_timers", 0.49)
	_expect(not bool(exploration.call("_toggle_weapon")), "O cooldown de troca deve durar pelo menos 0,5 s.")
	exploration.call("_advance_timers", 0.02)
	_clear_sfx_players()
	_expect(bool(exploration.call("_toggle_weapon")), "Q deve voltar a funcionar após 0,5 s.")
	_expect(_count_sfx(SFX_PEIXEIRA_DRAW) == 0, "Trocar para Rifle não deve tocar o saque da Peixeira.")
	_expect(_count_sfx(SFX_EQUIP_RIFLE) == 1, "Trocar da Peixeira para Rifle deve tocar o equipamento uma vez.")
	_expect(int(exploration.get("current_weapon")) == WEAPON_RIFLE, "A segunda troca válida deve reequipar o Rifle.")


func _test_realtime_hud_contract(exploration: Node) -> void:
	var hud := exploration.get_node_or_null("Interface/RealtimeHUD") as Control
	_expect(hud != null, "A exploração deve manter o RealtimeHUD compartilhado.")
	if hud == null:
		return
	hud.size = Vector2(768.0, 512.0)
	_expect(hud.mouse_filter == Control.MOUSE_FILTER_IGNORE, "O HUD não deve capturar mouse.")
	_expect(hud.focus_mode == Control.FOCUS_NONE, "O HUD não deve receber foco.")
	_expect(hud.get_child_count() == 0, "O HUD v5 não deve criar filhos interativos.")
	var constants: Dictionary = hud.get_script().get_script_constant_map()
	_expect(constants.get("MEDALLION_PLACEHOLDER", "") == "—", "O medalhão deve permanecer sem nível numérico.")
	_expect(int(constants.get("PLACEHOLDER_SLOT_COUNT", 0)) == 6, "A grade visual deve conter seis slots vazios.")
	_expect(constants.get("MINIMAP_SIZE", Vector2.ZERO) == Vector2(128.0, 142.0), "O painel de minimapa estático deve ocupar 128x142 px.")
	var chrome_atlas := constants.get("HUD_CHROME_ATLAS") as Texture2D
	var content_atlas := constants.get("HUD_CONTENT_ATLAS") as Texture2D
	_expect(chrome_atlas != null and chrome_atlas.get_size() == Vector2(768.0, 256.0), "O atlas chrome modular deve carregar em 768x256 px.")
	_expect(content_atlas != null and content_atlas.get_size() == Vector2(768.0, 256.0), "O atlas de conteúdo modular deve carregar em 768x256 px.")
	_expect(hud.call("_main_panel_rect") == Rect2(220.0, 346.0, 280.0, 142.0), "O painel de combate deve respeitar 280x142 px no canvas 768x512.")
	_expect(hud.call("_next_weapon_name", "RIFLE") == "PEIXEIRA", "Q deve derivar Peixeira como a próxima arma do Rifle.")
	_expect(hud.call("_next_weapon_name", "PEIXEIRA") == "RIFLE", "Q deve derivar Rifle como a próxima arma da Peixeira.")
	hud.call("set_hud_state", 73, 110, 100, 100, "RIFLE", 2, 5, 8, 3, true, false, true, 0.5, 1.5)
	_expect(int(hud.get("player_hp")) == 73 and int(hud.get("player_max_hp")) == 110, "Vida do HUD deve preservar os dados recebidos.")
	_expect(int(hud.get("rifle_ammo")) == 2 and int(hud.get("rifle_reserve_ammo")) == 8, "Munição do HUD deve preservar pente e reserva.")
	_expect(int(hud.get("lapada_charges")) == 3 and bool(hud.get("lapada_ready")), "Lapada deve preservar cargas e estado pronto.")
	_expect(bool(hud.get("reloading")) and is_equal_approx(float(hud.get("reload_remaining")), 0.5), "Recarga deve preservar o tempo restante.")
	hud.call("set_hud_state", 73, 110, 100, 100, "PEIXEIRA", 2, 5, 8, 3, true, false, false, 0.0, 1.5)
	_expect(str(hud.get("weapon_name")) == "PEIXEIRA" and not bool(hud.get("reloading")), "Peixeira deve atualizar a apresentação sem estado de recarga.")


func _test_reload_rules(exploration: Node) -> void:
	_reset_state(exploration)
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D
	exploration.set("rifle_ammo", 2)
	exploration.set("rifle_reserve_ammo", 10)
	_clear_sfx_players()
	_expect(bool(exploration.call("_start_reload")), "R deve iniciar a recarga manual de um pente incompleto.")
	_expect(_count_sfx(SFX_RELOAD) == 1, "Iniciar a recarga deve tocar o WAV uma vez durante a barra.")
	_expect(bool(exploration.get("is_reloading")), "A recarga deve permanecer ativa por 1,5 s.")
	_expect(not bool(exploration.call("_toggle_weapon")), "Q deve ser bloqueado durante a recarga.")
	_expect(not bool(exploration.call("_attempt_lapada_seca")), "A Lapada deve ser bloqueada durante a recarga.")
	var position_before_move := player.position
	exploration.call("_move_player_with_input", 0.10, Vector2.RIGHT)
	_expect(player.position != position_before_move, "O Cangaceiro deve poder andar durante a recarga.")
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "Ataques devem ficar bloqueados durante a recarga.")
	exploration.call("_advance_timers", 0.50)
	exploration.call("_damage_player", 15)
	_expect(bool(exploration.get("is_reloading")), "Dano comum não deve interromper a recarga.")
	exploration.call("_advance_timers", 0.99)
	_expect(int(exploration.get("rifle_ammo")) == 2, "As balas só devem entrar no pente ao final dos 1,5 s.")
	_expect(_count_sfx(SFX_RELOAD) == 1, "A recarga em andamento não deve repetir o WAV.")
	exploration.call("_advance_timers", 0.02)
	_expect(_count_sfx(SFX_RELOAD) == 1, "Concluir a recarga não deve repetir o WAV iniciado com a barra.")
	_expect(not bool(exploration.get("is_reloading")), "A recarga deve terminar após 1,5 s.")
	_expect(int(exploration.get("rifle_ammo")) == 5, "A recarga deve completar o pente até 5 balas.")
	_expect(int(exploration.get("rifle_reserve_ammo")) == 7, "Somente 3 balas devem sair da reserva.")

	_reset_state(exploration)
	exploration.set("rifle_ammo", 0)
	exploration.set("rifle_reserve_ammo", 4)
	exploration.set("heavy_warning_active", true)
	_clear_sfx_players()
	_expect(bool(exploration.call("_start_reload")), "A recarga deve iniciar com pente vazio e reserva disponível.")
	exploration.call("_advance_timers", 0.70)
	_expect(bool(exploration.call("_attempt_parry")), "Espaço deve cancelar a recarga e executar um aparo válido.")
	_expect(not bool(exploration.get("is_reloading")), "O aparo deve cancelar o temporizador de recarga.")
	_expect(int(exploration.get("rifle_ammo")) == 0, "Cancelar antes do fim não deve inserir balas no pente.")
	_expect(int(exploration.get("rifle_reserve_ammo")) == 4, "Cancelar antes do fim não deve gastar a reserva.")
	_expect(_count_sfx(SFX_RELOAD) == 1, "Cancelar a recarga não deve iniciar uma segunda reprodução.")

	_reset_state(exploration)
	_clear_sfx_players()
	_expect(not bool(exploration.call("_start_reload")), "Pente cheio deve recusar a recarga.")
	_expect(_count_sfx(SFX_RELOAD) == 0, "Pente cheio deve permanecer silencioso.")
	exploration.set("rifle_ammo", 2)
	exploration.set("rifle_reserve_ammo", 0)
	_expect(not bool(exploration.call("_start_reload")), "Reserva vazia deve recusar a recarga.")
	_expect(_count_sfx(SFX_RELOAD) == 0, "Reserva vazia deve permanecer silenciosa.")
	exploration.set("rifle_reserve_ammo", 3)
	exploration.set("current_weapon", WEAPON_KNIFE)
	_expect(not bool(exploration.call("_start_reload")), "Peixeira equipada deve recusar a recarga.")
	_expect(_count_sfx(SFX_RELOAD) == 0, "Arma errada deve permanecer silenciosa.")
	exploration.set("current_weapon", WEAPON_RIFLE)
	exploration.set("stun_remaining", 0.7)
	_expect(not bool(exploration.call("_start_reload")), "Atordoamento deve recusar a recarga.")
	_expect(_count_sfx(SFX_RELOAD) == 0, "Estado bloqueado deve permanecer silencioso.")

	_reset_state(exploration)
	exploration.set("rifle_ammo", 0)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "Pente vazio não deve iniciar recarga automática.")
	_expect(not bool(exploration.get("is_reloading")), "A recarga deve depender exclusivamente do comando R.")


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
	_clear_sfx_players()
	_expect(bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle deve alcançar exatamente 5 tiles.")
	_expect(_count_sfx(SFX_RIFLE) == 1, "Um disparo efetuado deve tocar o WAV do Rifle uma vez.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 125.0), "Disparo normal deve causar 25 de dano.")
	exploration.call("_advance_timers", 1.19)
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle não deve atacar antes de 1,2 s.")
	exploration.call("_advance_timers", 0.02)
	_expect(bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle deve atacar após o intervalo de 1,2 s.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(7, 10))
	_clear_sfx_players()
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle não deve alcançar 6 tiles.")
	_expect(_count_sfx(SFX_RIFLE) == 0, "Ataque fora do alcance não deve tocar o Rifle.")
	_expect(int(exploration.get("rifle_ammo")) == 5, "Ataque fora do alcance não deve gastar munição.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	_clear_sfx_players()
	_expect(bool(exploration.call("_attempt_auto_attack", 0.10, 0.10)), "O Rifle deve aceitar um roll crítico determinístico.")
	_expect(_count_sfx(SFX_CRITICAL) == 1, "Crítico confirmado deve tocar o novo WAV uma vez.")
	_expect(_count_synth_sfx("hit") == 1, "Crítico de Rifle deve manter o impacto básico como camada.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 110.0), "Crítico de Rifle deve causar 40 de dano.")
	var critical_popup := _last_popup(exploration)
	_expect(bool(critical_popup.get("bold", false)), "O número crítico deve ser desenhado em negrito.")
	_expect(int(critical_popup.get("font_size", 0)) == 22, "O número crítico deve ser maior.")
	_expect(critical_popup.get("color", Color.TRANSPARENT) == Color("df3328"), "O número crítico deve ser vermelho.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	_clear_sfx_players()
	_expect(bool(exploration.call("_attempt_auto_attack", 0.95, 0.10)), "Um disparo dentro do alcance deve ser executado mesmo quando erra.")
	_expect(_count_sfx(SFX_CRITICAL) == 0, "Disparo errado não deve tocar o crítico.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 150.0), "Disparo errado não deve causar dano.")
	_expect(int(exploration.get("rifle_ammo")) == 4, "Disparo errado também deve consumir uma bala.")

	_reset_state(exploration)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(6, 10))
	for shot in range(5):
		exploration.set("player_attack_cooldown", 0.0)
		exploration.call("_attempt_auto_attack", 0.95, 0.50)
	_expect(int(exploration.get("rifle_ammo")) == 0, "Cinco disparos devem esgotar o Rifle.")
	_clear_sfx_players()
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.50)), "O Rifle não deve atacar sem munição.")
	_expect(_count_sfx(SFX_RIFLE) == 0, "Rifle sem munição não deve tocar o disparo.")


func _test_knife_rules(exploration: Node) -> void:
	var player := exploration.get_node("PlayerAnchor") as Node2D
	var capanga := exploration.get_node("CapangaAnchor") as Node2D

	_reset_state(exploration)
	exploration.set("current_weapon", WEAPON_KNIFE)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(2, 10))
	_clear_sfx_players()
	_expect(bool(exploration.call("_attempt_auto_attack", 0.95, 0.50)), "A Peixeira deve alcançar exatamente 1 tile.")
	_expect(_count_sfx(SFX_PEIXEIRA_HIT) == 1, "Contato da Peixeira deve tocar o golpe uma vez.")
	_expect(is_equal_approx(float(exploration.get("capanga_hp")), 130.0), "Peixeira normal deve causar 20 de dano e sempre acertar.")
	exploration.call("_advance_timers", 0.79)
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.95, 0.50)), "A Peixeira não deve atacar antes de 0,8 s.")
	exploration.call("_advance_timers", 0.02)
	_expect(bool(exploration.call("_attempt_auto_attack", 0.95, 0.50)), "A Peixeira deve atacar após 0,8 s.")

	_reset_state(exploration)
	exploration.set("current_weapon", WEAPON_KNIFE)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(3, 10))
	_clear_sfx_players()
	_expect(not bool(exploration.call("_attempt_auto_attack", 0.10, 0.10)), "A Peixeira não deve alcançar 2 tiles.")
	_expect(_count_sfx(SFX_PEIXEIRA_HIT) == 0, "Golpe no vazio não deve tocar o impacto da Peixeira.")

	_reset_state(exploration)
	exploration.set("current_weapon", WEAPON_KNIFE)
	player.position = exploration.call("_cell_to_world", Vector2i(1, 10))
	capanga.position = exploration.call("_cell_to_world", Vector2i(2, 10))
	_clear_sfx_players()
	exploration.call("_attempt_auto_attack", 0.95, 0.10)
	_expect(_count_sfx(SFX_PEIXEIRA_HIT) == 1, "Crítico da Peixeira deve manter o impacto básico.")
	_expect(_count_sfx(SFX_CRITICAL) == 1, "Crítico da Peixeira deve adicionar uma única camada crítica.")
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
	exploration.set("rifle_reserve_ammo", 8)
	exploration.set("capanga_hp", 35.0)
	exploration.set("capanga_state", STATE_CHASE)
	_expect(bool(exploration.call("_start_reload")), "A recarga deve iniciar antes do teste de derrota.")

	_expect(bool(exploration.call("_damage_player", 15)), "Dano letal deve acionar a derrota.")
	_expect(int(exploration.get("player_hp")) == 40, "O Cangaceiro deve reaparecer com 40 HP.")
	_expect(player.position == exploration.call("_cell_to_world", Vector2i(1, 10)), "O Cangaceiro deve reaparecer no PLAYER_START.")
	_expect(int(exploration.get("rifle_ammo")) == 2, "A derrota deve preservar a munição.")
	_expect(int(exploration.get("rifle_reserve_ammo")) == 8, "A derrota deve preservar a reserva.")
	_expect(not bool(exploration.get("is_reloading")), "O respawn deve cancelar a recarga sem transferir balas.")
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
	_clear_sfx_players()
	exploration.call("_attempt_auto_attack", 0.95, 0.50)

	_expect(not bool(exploration.get("capanga_active")), "O Capanga deve desaparecer ao chegar a 0 HP.")
	_expect(bool(game_state.call("is_encounter_defeated", "capanga_01")), "A morte do Capanga deve persistir na sessão.")
	exploration.call("_advance_capanga_ai", 5.0)
	exploration.call("_advance_capanga_attack", 5.0)
	_expect(int(exploration.get("player_hp")) == player_hp_before, "O Capanga morto não deve voltar a atacar.")
	_expect(is_zero_approx(float(exploration.get("capanga_hp"))), "O Capanga morto não deve regenerar.")
	_expect(_count_sfx(SFX_COIN) == 1, "Recompensa positiva exibida deve tocar a moeda uma vez.")


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
	exploration.set("rifle_reserve_ammo", 10)
	exploration.set("current_weapon", WEAPON_RIFLE)
	exploration.set("player_attack_cooldown", 0.0)
	exploration.set("weapon_switch_cooldown", 0.0)
	exploration.set("is_reloading", false)
	exploration.set("reload_remaining", 0.0)
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


func _clear_sfx_players() -> void:
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer and child.name.begins_with("SFXPlayer_"):
			child.stop()
			child.stream = null


func _count_sfx(resource_path: String) -> int:
	var count := 0
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer and child.stream != null and child.stream.resource_path == resource_path:
			count += 1
	return count


func _count_synth_sfx(sound_name: String) -> int:
	var audio_manager := root.get_node("AudioManager")
	var target_stream: AudioStream = (audio_manager.get("_synth_cache") as Dictionary).get(sound_name)
	var count := 0
	for child in audio_manager.get_children():
		if child is AudioStreamPlayer and child.stream == target_stream:
			count += 1
	return count


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
