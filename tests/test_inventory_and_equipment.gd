extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	_test_inventory_and_potion(game_state)
	_test_equipment_and_attributes(game_state)
	_test_loot(game_state)
	_test_save_compatibility(game_state)
	_finish(game_state)


func _test_inventory_and_potion(game_state: Node) -> void:
	game_state.call("reset_session")
	var added: Dictionary = game_state.call("add_inventory_item", "health_potion", 6)
	_expect(int(added.get("accepted", 0)) == 6, "Seis poções devem caber no inventário.")
	_expect(int(game_state.call("get_inventory_used_slots")) == 2, "Seis poções devem ocupar pilhas de 5 e 1.")
	_expect(int(game_state.call("get_item_count", "health_potion")) == 6, "A contagem deve somar todas as pilhas.")

	var refused: Dictionary = game_state.call("use_health_potion")
	_expect(not bool(refused.get("success", false)), "Vida cheia deve recusar a poção.")
	_expect(str(refused.get("reason", "")) == "full_health", "A recusa deve informar vida cheia.")
	_expect(int(game_state.call("get_item_count", "health_potion")) == 6, "Poção recusada não deve ser consumida.")

	game_state.call("set_player_hp", 40)
	var used: Dictionary = game_state.call("use_health_potion")
	_expect(bool(used.get("success", false)), "Poção deve ser usada com vida incompleta.")
	_expect(int(used.get("healed", 0)) == 30, "Poção deve curar 30% da vida máxima base.")
	_expect(int(game_state.get("player_hp")) == 70, "A cura deve atualizar a vida persistida.")
	_expect(int(game_state.call("get_item_count", "health_potion")) == 5, "Uma poção deve ser consumida.")

	game_state.call("reset_session")
	for _index in range(12):
		game_state.call("add_inventory_item", "armor_head", 1)
	var overflow: Dictionary = game_state.call("add_inventory_item", "armor_head", 1)
	_expect(int(game_state.call("get_inventory_used_slots")) == 12, "O inventário deve respeitar os 12 slots.")
	_expect(int(overflow.get("remaining", 0)) == 1, "Item excedente deve permanecer fora do inventário cheio.")


func _test_equipment_and_attributes(game_state: Node) -> void:
	game_state.call("reset_session")
	for item_id in ["armor_head", "armor_chest", "armor_legs", "armor_feet"]:
		var result: Dictionary = game_state.call("acquire_armor", item_id)
		_expect(bool(result.get("equipped", false)), "%s deve autoequipar em slot vazio." % item_id)

	_expect(int(game_state.call("get_defense_points")) == 8, "Quatro armaduras devem conceder 8 de Defesa.")
	_expect(int(game_state.call("get_player_max_hp")) == 110, "Vigor equipado deve conceder 10 de vida máxima.")
	_expect(int(game_state.call("get_rifle_damage", 25)) == 30, "Pontaria deve adicionar 5 ao Rifle.")
	_expect(int(game_state.call("get_knife_damage", 20)) == 25, "Força deve adicionar 5 à Peixeira.")
	_expect(is_equal_approx(float(game_state.call("get_player_critical_chance", 0.25)), 0.30), "Pontaria deve adicionar 5 pontos percentuais de crítico.")
	_expect(int(game_state.call("reduce_player_damage", 50)) == 42, "Oito de Defesa devem reduzir 16% de 50.")

	game_state.call("set_player_hp", 110)
	var unequipped: Dictionary = game_state.call("unequip_armor", "chest")
	_expect(bool(unequipped.get("success", false)), "A armadura de busto deve poder ser guardada.")
	_expect(int(game_state.call("get_player_max_hp")) == 100, "Remover Vigor deve restaurar a vida máxima base.")
	_expect(int(game_state.get("player_hp")) == 100, "Remover Vigor deve limitar a vida ao novo máximo.")
	var equipped_again: Dictionary = game_state.call("equip_inventory_item", 0)
	_expect(bool(equipped_again.get("success", false)), "A armadura guardada deve poder ser reequipada.")


func _test_loot(game_state: Node) -> void:
	game_state.call("reset_session")
	var guaranteed: Dictionary = game_state.call("generate_common_enemy_loot", "armor_head", 0.0, 0.0)
	var guaranteed_items: Array = guaranteed.get("items", [])
	_expect(int(guaranteed.get("gold", 0)) == 10, "Inimigo comum deve conceder 10 moedas.")
	_expect(guaranteed_items == ["health_potion", "armor_head"], "Rolagens baixas devem conceder poção e armadura.")

	var empty: Dictionary = game_state.call("generate_common_enemy_loot", "armor_head", 1.0, 1.0)
	_expect(Array(empty.get("items", [])).is_empty(), "Rolagens altas não devem conceder itens.")
	_expect(int(game_state.get("gold_score")) == 20, "Cada geração de espólio deve somar as moedas garantidas.")


func _test_save_compatibility(game_state: Node) -> void:
	game_state.call("reset_session")
	game_state.call("add_inventory_item", "health_potion", 6)
	game_state.call("acquire_armor", "armor_head")
	game_state.call("set_player_hp", 73)
	var saved: Dictionary = game_state.call("export_save_data")

	game_state.call("reset_session")
	game_state.call("import_save_data", saved)
	_expect(int(game_state.get("player_hp")) == 73, "O save deve restaurar a vida.")
	_expect(int(game_state.call("get_item_count", "health_potion")) == 6, "O save deve restaurar o inventário.")
	_expect(str(game_state.call("get_equipped_item", "head")) == "armor_head", "O save deve restaurar o equipamento.")

	game_state.call("import_save_data", {"player_hp": 75, "gold_score": 5})
	_expect(int(game_state.get("player_hp")) == 75, "Save antigo deve restaurar os campos existentes.")
	_expect(int(game_state.call("get_inventory_used_slots")) == 0, "Save antigo deve iniciar com inventário vazio.")
	_expect(str(game_state.call("get_equipped_item", "head")).is_empty(), "Save antigo deve iniciar sem equipamento.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(game_state: Node) -> void:
	game_state.call("reset_session")
	if failures.is_empty():
		print("TESTE_INVENTARIO_E_EQUIPAMENTO_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
