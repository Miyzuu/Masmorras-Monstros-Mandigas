extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := root.get_node("GameState")
	state.call("reset_session")
	_test_transient_state(state)
	_test_panel(state)
	await _test_scene_freeze()
	state.call("reset_session")
	if failures.is_empty():
		print("TESTE_GOD_MODE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_transient_state(state: Node) -> void:
	state.call("set_rifle_ammo", 0)
	_expect(not bool(state.call("can_fire_rifle")), "Rifle vazio deve permanecer bloqueado sem GOD Mode.")
	_expect(not bool(state.call("consume_rifle_round")), "Rifle vazio não deve consumir um disparo normal.")
	_expect(int(state.call("reduce_player_damage", 15)) > 0, "Dano normal deve continuar reduzido apenas pela Defesa.")

	state.call("set_god_mode_infinite_ammo", true)
	_expect(bool(state.call("can_fire_rifle")), "Munição infinita deve liberar Rifle com pente vazio.")
	_expect(bool(state.call("consume_rifle_round")), "Munição infinita deve aceitar o disparo.")
	_expect(int(state.get("rifle_ammo")) == 0, "Munição infinita não deve alterar o pente salvo.")

	state.call("set_god_mode_no_damage", true)
	_expect(int(state.call("reduce_player_damage", 40)) == 0, "Sem dano deve cobrir o ponto compartilhado de dano.")
	_expect(bool(state.get("god_mode_infinite_ammo")), "As opções de GOD Mode devem ser independentes.")

	var save_data: Dictionary = state.call("export_save_data")
	_expect(not save_data.has("god_mode_no_damage"), "Save não deve registrar Sem dano.")
	_expect(not save_data.has("god_mode_infinite_ammo"), "Save não deve registrar Munição infinita.")

	state.call("import_save_data", {"player_hp": 73, "rifle_ammo": 0})
	_expect(not bool(state.get("god_mode_no_damage")), "Carregar save deve desligar Sem dano.")
	_expect(not bool(state.get("god_mode_infinite_ammo")), "Carregar save deve desligar Munição infinita.")
	_expect(not bool(state.call("can_fire_rifle")), "Após desligar, pente vazio deve voltar a bloquear o Rifle.")
	_expect(int(state.call("reduce_player_damage", 40)) > 0, "Após desligar, dano normal deve retornar.")


func _test_panel(state: Node) -> void:
	var panel: CanvasLayer = load("res://scripts/god_mode_panel.gd").new()
	root.add_child(panel)
	_expect(not bool(panel.call("is_panel_open")), "Painel deve iniciar fechado.")

	var shortcut := InputEventKey.new()
	shortcut.keycode = KEY_C
	shortcut.pressed = true
	shortcut.ctrl_pressed = true
	shortcut.shift_pressed = true
	panel.call("_input", shortcut)
	_expect(bool(panel.call("is_panel_open")), "Ctrl+Shift+C deve abrir o painel.")

	panel.call("_on_no_damage_toggled", true)
	_expect(bool(state.get("god_mode_no_damage")), "Caixa Sem dano deve ativar sua opção.")
	_expect(not bool(state.get("god_mode_infinite_ammo")), "Caixa Sem dano não deve ativar Munição infinita.")
	panel.call("_on_infinite_ammo_toggled", true)
	_expect(bool(state.get("god_mode_infinite_ammo")), "Caixa Munição infinita deve ativar sua opção.")

	panel.call("_input", shortcut)
	_expect(not bool(panel.call("is_panel_open")), "Ctrl+Shift+C deve fechar sem alterar as opções.")
	_expect(bool(state.get("god_mode_no_damage")), "Fechar o painel deve preservar Sem dano ativo.")
	_expect(bool(state.get("god_mode_infinite_ammo")), "Fechar o painel deve preservar Munição infinita ativa.")
	panel.queue_free()


func _test_scene_freeze() -> void:
	var exploration_scene := load("res://scenes/exploration.tscn") as PackedScene
	var dungeon_scene := load("res://scenes/dungeon.tscn") as PackedScene
	var boss_scene := load("res://scenes/main.tscn") as PackedScene
	_expect(exploration_scene != null and dungeon_scene != null and boss_scene != null, "As três cenas devem carregar para validar o congelamento.")
	if exploration_scene == null or dungeon_scene == null or boss_scene == null:
		return

	var exploration := exploration_scene.instantiate()
	root.add_child(exploration)
	exploration.set_physics_process(false)
	await process_frame
	var exploration_player := exploration.get_node("PlayerAnchor") as Node2D
	var exploration_panel: CanvasLayer = exploration.get("god_mode_panel")
	exploration.call("_set_destination", exploration.call("_cell_to_world", Vector2i(3, 10)))
	var exploration_start := exploration_player.position
	_toggle_panel(exploration_panel)
	exploration.call("_physics_process", 1.0)
	_expect(exploration_player.position == exploration_start, "Painel aberto deve congelar a exploração.")
	_toggle_panel(exploration_panel)
	exploration.call("_physics_process", 1.0 / 60.0)
	_expect(exploration_player.position != exploration_start, "Fechar o painel deve retomar a exploração.")
	exploration.queue_free()
	await process_frame

	var dungeon := dungeon_scene.instantiate()
	root.add_child(dungeon)
	dungeon.set_physics_process(false)
	await process_frame
	dungeon.set("scene_transitioning", false)
	var dungeon_player := dungeon.get_node("PlayerAnchor") as Node2D
	var dungeon_panel: CanvasLayer = dungeon.get("god_mode_panel")
	dungeon.call("_set_destination", dungeon.call("_cell_to_world", Vector2i(3, 10)))
	var dungeon_start := dungeon_player.position
	_toggle_panel(dungeon_panel)
	dungeon.call("_physics_process", 1.0)
	_expect(dungeon_player.position == dungeon_start, "Painel aberto deve congelar a masmorra.")
	_toggle_panel(dungeon_panel)
	dungeon.call("_physics_process", 1.0 / 60.0)
	_expect(dungeon_player.position != dungeon_start, "Fechar o painel deve retomar a masmorra.")
	dungeon.queue_free()
	await process_frame

	var boss := boss_scene.instantiate()
	root.add_child(boss)
	await process_frame
	boss.set("boss_mode", true)
	boss.set("boss_phase", 2)
	boss.set("boss_phase_deadline_usec", Time.get_ticks_usec() + 2000000)
	var boss_panel: CanvasLayer = boss.get("god_mode_panel")
	var boss_deadline := int(boss.get("boss_phase_deadline_usec"))
	_toggle_panel(boss_panel)
	boss.call("_process", 1.0)
	_expect(int(boss.get("boss_phase_deadline_usec")) == boss_deadline + 1000000, "Painel aberto deve congelar o prazo do chefe.")
	boss.queue_free()
	await process_frame


func _toggle_panel(panel: CanvasLayer) -> void:
	var shortcut := InputEventKey.new()
	shortcut.keycode = KEY_C
	shortcut.pressed = true
	shortcut.ctrl_pressed = true
	shortcut.shift_pressed = true
	panel.call("_input", shortcut)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
