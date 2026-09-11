extends SceneTree

const ATTACK_RIFLE := 1
const ATTACK_KNIFE := 2
const BOSS_PHASE_PLAYER_CHOICE := 0
const SFX_RIFLE := "res://assets/art/audio/rifle_tiro.wav"
const SFX_RELOAD := "res://assets/art/audio/recarregar.wav"
const SFX_CRITICAL := "res://assets/art/audio/critical_hit.wav"
const SFX_PEIXEIRA_DRAW := "res://assets/art/audio/peixeira_draw.wav"
const SFX_PEIXEIRA_HIT := "res://assets/art/audio/peixeira_hit.wav"
const SFX_EQUIP_RIFLE := "res://assets/art/audio/equipando_rifle.wav"
const SFX_DUNGEON_DEATH := "res://assets/art/audio/morte_jogador_masmorra.wav"
const SFX_COIN := "res://assets/art/audio/moeda_popup.wav"
const SFX_BOSS_VICTORY := "res://assets/art/audio/vitoria_boss_masmorra.wav"

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
	_test_legacy_nonboss_sfx(combat)
	_test_boss_sfx(combat, game_state)
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


func _test_legacy_nonboss_sfx(combat: Node) -> void:
	combat.call("_reset_combat", "Teste de áudio legado do Rifle normal.")
	combat.set("hero_cell", Vector2i(0, 9))
	combat.set("capanga_cell", Vector2i(7, 9))
	_clear_sfx_players()
	_expect(bool(combat.call("_attempt_attack", ATTACK_RIFLE, 0.10, 0.50)), "O encontro legado deve aceitar o Rifle normal.")
	_expect(_count_sfx(SFX_RIFLE) == 1, "Rifle normal legado deve tocar um único disparo.")
	_expect(_count_synth_sfx("hit") == 1, "Rifle normal legado deve tocar um único impacto básico.")
	_expect(_count_sfx(SFX_CRITICAL) == 0, "Rifle normal legado não deve tocar crítico.")

	combat.call("_reset_combat", "Teste de áudio legado do Rifle crítico.")
	combat.set("hero_cell", Vector2i(0, 9))
	combat.set("capanga_cell", Vector2i(7, 9))
	_clear_sfx_players()
	_expect(bool(combat.call("_attempt_attack", ATTACK_RIFLE, 0.10, 0.10)), "O encontro legado deve aceitar o Rifle crítico.")
	_expect(_count_sfx(SFX_RIFLE) == 1, "Rifle crítico legado deve tocar um único disparo.")
	_expect(_count_synth_sfx("hit") == 1, "Rifle crítico legado deve manter um único impacto básico.")
	_expect(_count_sfx(SFX_CRITICAL) == 1, "Rifle crítico legado deve tocar uma única camada crítica.")

	combat.call("_reset_combat", "Teste de erro legado do Rifle.")
	combat.set("hero_cell", Vector2i(0, 9))
	combat.set("capanga_cell", Vector2i(7, 9))
	_clear_sfx_players()
	_expect(bool(combat.call("_attempt_attack", ATTACK_RIFLE, 0.95, 0.10)), "O disparo legado perdido ainda deve ser efetuado.")
	_expect(_count_sfx(SFX_RIFLE) == 1, "Rifle legado perdido deve tocar somente o disparo.")
	_expect(_count_synth_sfx("hit") == 0, "Rifle legado perdido não deve tocar impacto.")
	_expect(_count_sfx(SFX_CRITICAL) == 0, "Rifle legado perdido não deve tocar crítico.")

	combat.call("_reset_combat", "Teste de áudio legado da Peixeira.")
	combat.set("hero_cell", Vector2i(1, 8))
	combat.set("capanga_cell", Vector2i(2, 8))
	_clear_sfx_players()
	_expect(bool(combat.call("_attempt_attack", ATTACK_KNIFE)), "O contato legado da Peixeira deve ser aceito.")
	_expect(_count_sfx(SFX_PEIXEIRA_HIT) == 1, "Contato legado da Peixeira deve tocar um único impacto.")

	combat.call("_reset_combat", "Teste inválido legado da Peixeira.")
	combat.set("hero_cell", Vector2i(1, 8))
	combat.set("capanga_cell", Vector2i(3, 8))
	_clear_sfx_players()
	_expect(not bool(combat.call("_attempt_attack", ATTACK_KNIFE)), "Peixeira legado fora do alcance deve ser rejeitada.")
	_expect(_count_sfx(SFX_PEIXEIRA_HIT) == 0, "Peixeira legado sem contato deve permanecer silenciosa.")


func _test_boss_sfx(combat: Node, game_state: Node) -> void:
	_prepare_boss_choice(combat)
	_clear_sfx_players()
	combat.call("_select_attack", ATTACK_KNIFE)
	combat.call("_select_attack", ATTACK_KNIFE)
	_expect(_count_sfx(SFX_PEIXEIRA_DRAW) == 1, "Selecionar Peixeira repetidamente deve tocar um único saque.")
	_clear_sfx_players()
	combat.call("_select_attack", ATTACK_RIFLE)
	combat.call("_select_attack", ATTACK_RIFLE)
	_expect(_count_sfx(SFX_EQUIP_RIFLE) == 1, "Voltar da Peixeira ao Rifle deve tocar um único equipamento.")

	_prepare_boss_choice(combat)
	_clear_sfx_players()
	_expect(bool(combat.call("_attempt_boss_attack", ATTACK_KNIFE)), "O golpe adjacente da Peixeira no chefe deve ser aceito.")
	_expect(_count_sfx(SFX_PEIXEIRA_DRAW) == 1, "Atacar ao trocar para Peixeira deve tocar um único saque.")
	_expect(_count_sfx(SFX_PEIXEIRA_HIT) == 1, "Dano confirmado da Peixeira deve tocar um único impacto.")

	_prepare_boss_choice(combat)
	combat.set("selected_attack", ATTACK_KNIFE)
	game_state.call("set_rifle_ammo", 5)
	_clear_sfx_players()
	_expect(bool(combat.call("_attempt_boss_attack", ATTACK_RIFLE, 0.10, 0.10)), "O chefe deve aceitar um disparo crítico determinístico.")
	_expect(_count_sfx(SFX_EQUIP_RIFLE) == 1, "Ataque direto ao trocar para Rifle deve tocar um único equipamento.")
	_expect(_count_sfx(SFX_RIFLE) == 1, "Disparo confirmado contra o chefe deve tocar o Rifle uma vez.")
	_expect(_count_sfx(SFX_CRITICAL) == 1, "Crítico confirmado contra o chefe deve tocar uma única camada crítica.")
	_expect(_count_synth_sfx("hit") == 1, "Crítico contra o chefe deve manter o impacto básico.")

	_prepare_boss_choice(combat)
	game_state.call("set_rifle_ammo", 2)
	game_state.call("set_rifle_reserve_ammo", 3)
	_clear_sfx_players()
	_expect(bool(combat.call("_attempt_reload")), "A recarga válida do chefe deve transferir munição.")
	_expect(_count_sfx(SFX_RELOAD) == 1, "Recarga válida do chefe deve tocar a conclusão uma vez.")

	_prepare_boss_choice(combat)
	game_state.call("set_rifle_ammo", 5)
	_clear_sfx_players()
	_expect(not bool(combat.call("_attempt_reload")), "Pente cheio deve bloquear a recarga do chefe.")
	_expect(_count_sfx(SFX_RELOAD) == 0, "Recarga bloqueada do chefe deve permanecer silenciosa.")

	_prepare_boss_choice(combat)
	_clear_sfx_players()
	combat.call("_show_boss_defeat")
	combat.call("_show_boss_defeat")
	_expect(_count_sfx(SFX_DUNGEON_DEATH) == 1, "Derrota do chefe deve tocar a morte do jogador uma única vez.")

	game_state.call("reset_session")
	game_state.call("begin_dungeon", Vector2.ZERO, 100, 5, 0)
	_prepare_boss_choice(combat)
	_clear_sfx_players()
	combat.call("_complete_boss_encounter", "Teste.")
	_expect(_count_sfx(SFX_BOSS_VICTORY) == 1, "Primeira conclusão do chefe deve tocar a vitória uma vez.")
	_expect(_count_sfx(SFX_COIN) == 0, "Recompensa do chefe não deve sobrepor o popup de moeda à vitória.")
	combat.call("_complete_boss_encounter", "Teste repetido.")
	_expect(_count_sfx(SFX_BOSS_VICTORY) == 1, "Conclusão repetida não deve repetir o som de vitória.")
	combat.set("boss_mode", false)
	game_state.call("reset_session")
	game_state.call("begin_encounter", "capanga_01", Vector2.ZERO)
	combat.call("_reset_combat", "Retorno aos testes do Capanga.")


func _prepare_boss_choice(combat: Node) -> void:
	combat.call("_reset_combat", "Teste de áudio do chefe.")
	combat.set("boss_mode", true)
	combat.set("boss_phase", BOSS_PHASE_PLAYER_CHOICE)
	combat.set("player_turn", true)
	combat.set("capanga_hp", 250)
	combat.set("selected_attack", ATTACK_RIFLE)


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
