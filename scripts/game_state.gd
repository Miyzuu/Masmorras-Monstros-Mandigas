extends Node

signal inventory_changed
signal equipment_changed

const PLAYER_MAX_HP := 100
const PLAYER_RESPAWN_RATIO := 0.40
const DEFAULT_PLAYER_HP := PLAYER_MAX_HP
const RIFLE_MAGAZINE_CAPACITY := 5
const DEFAULT_RIFLE_AMMO := RIFLE_MAGAZINE_CAPACITY
const DEFAULT_RIFLE_RESERVE_AMMO := 10
const DEFAULT_WEAPON := 0
const DEFAULT_GOLD_SCORE := 0
const WEAPON_RIFLE := 0
const WEAPON_KNIFE := 1
const MAX_LAPADA_CHARGES := 3
const DUNGEON_BOSS_REWARD := 250
const DUNGEON_ROOM_IDS := ["sala_01", "sala_02", "sala_03", "sala_04"]
const INVENTORY_CAPACITY := 12
const POTION_STACK_LIMIT := 5
const HEALTH_POTION_HEAL_RATIO := 0.30
const GROUND_DROP_LIFETIME := 120.0
const COMMON_ENEMY_GOLD := 10
const COMMON_POTION_DROP_CHANCE := 0.30
const COMMON_ARMOR_DROP_CHANCE := 0.20
const ARMOR_DEFENSE_POINTS := 2
const DEFENSE_REDUCTION_PER_POINT := 0.02
const ATTRIBUTE_DAMAGE_BONUS := 5
const VIGOR_HP_BONUS := 10
const CRITICAL_CHANCE_BONUS := 0.05
const MAX_CRITICAL_CHANCE := 0.50

const ATTRIBUTE_VIGOR := "vigor"
const ATTRIBUTE_AIM := "pontaria"
const ATTRIBUTE_STRENGTH := "forca"
const ATTRIBUTE_SPEED := "velocidade"

const ARMOR_SLOT_HEAD := "head"
const ARMOR_SLOT_CHEST := "chest"
const ARMOR_SLOT_LEGS := "legs"
const ARMOR_SLOT_FEET := "feet"
const ARMOR_SLOTS := [
	ARMOR_SLOT_HEAD,
	ARMOR_SLOT_CHEST,
	ARMOR_SLOT_LEGS,
	ARMOR_SLOT_FEET,
]

const ITEM_COIN := "coin"
const ITEM_HEALTH_POTION := "health_potion"
const ITEM_ARMOR_HEAD := "armor_head"
const ITEM_ARMOR_CHEST := "armor_chest"
const ITEM_ARMOR_LEGS := "armor_legs"
const ITEM_ARMOR_FEET := "armor_feet"
const ITEM_DEFINITIONS := {
	ITEM_COIN: {
		"name": "Moedas",
		"kind": "currency",
		"stack_limit": 999,
	},
	ITEM_HEALTH_POTION: {
		"name": "Poção de Vida",
		"kind": "consumable",
		"stack_limit": POTION_STACK_LIMIT,
	},
	ITEM_ARMOR_HEAD: {
		"name": "Armadura de Cabeça",
		"kind": "armor",
		"slot": ARMOR_SLOT_HEAD,
		"defense": ARMOR_DEFENSE_POINTS,
		"attribute": ATTRIBUTE_AIM,
		"attribute_bonus": 1,
		"stack_limit": 1,
	},
	ITEM_ARMOR_CHEST: {
		"name": "Armadura de Busto",
		"kind": "armor",
		"slot": ARMOR_SLOT_CHEST,
		"defense": ARMOR_DEFENSE_POINTS,
		"attribute": ATTRIBUTE_VIGOR,
		"attribute_bonus": 1,
		"stack_limit": 1,
	},
	ITEM_ARMOR_LEGS: {
		"name": "Armadura de Pernas",
		"kind": "armor",
		"slot": ARMOR_SLOT_LEGS,
		"defense": ARMOR_DEFENSE_POINTS,
		"attribute": ATTRIBUTE_STRENGTH,
		"attribute_bonus": 1,
		"stack_limit": 1,
	},
	ITEM_ARMOR_FEET: {
		"name": "Armadura de Pés",
		"kind": "armor",
		"slot": ARMOR_SLOT_FEET,
		"defense": ARMOR_DEFENSE_POINTS,
		"attribute": ATTRIBUTE_SPEED,
		"attribute_bonus": 1,
		"stack_limit": 1,
	},
}

var defeated_encounters: Dictionary = {}
var active_encounter_id := ""
var return_position := Vector2.ZERO
var return_position_pending := false
var returning_from_combat := false
var returning_from_dungeon := false

var player_hp := DEFAULT_PLAYER_HP
var rifle_ammo := DEFAULT_RIFLE_AMMO
var rifle_reserve_ammo := DEFAULT_RIFLE_RESERVE_AMMO
var current_weapon := DEFAULT_WEAPON
var gold_score := DEFAULT_GOLD_SCORE
var lapada_charges := 0
var inventory: Array[Dictionary] = []
var equipped_armor: Dictionary = {
	ARMOR_SLOT_HEAD: "",
	ARMOR_SLOT_CHEST: "",
	ARMOR_SLOT_LEGS: "",
	ARMOR_SLOT_FEET: "",
}

var dungeon_active := false
var dungeon_progress: Dictionary = {}
var dungeon_room_index := 0
var dungeon_completed := false


func begin_encounter(encounter_id: String, player_position: Vector2) -> void:
	active_encounter_id = encounter_id
	return_position = player_position
	return_position_pending = true
	returning_from_combat = false
	returning_from_dungeon = false


func complete_active_encounter() -> void:
	if active_encounter_id.is_empty():
		return

	defeated_encounters[active_encounter_id] = true
	active_encounter_id = ""
	returning_from_combat = true


func mark_encounter_defeated(encounter_id: String) -> void:
	if encounter_id.is_empty():
		return

	defeated_encounters[encounter_id] = true


func save_player_state(new_hp: int, new_rifle_ammo: int, new_weapon: int) -> void:
	set_player_hp(new_hp)
	set_rifle_ammo(new_rifle_ammo)
	set_current_weapon(new_weapon)


func set_player_hp(new_hp: int) -> void:
	player_hp = clampi(new_hp, 0, get_player_max_hp())


func set_rifle_ammo(new_rifle_ammo: int) -> void:
	rifle_ammo = clampi(new_rifle_ammo, 0, RIFLE_MAGAZINE_CAPACITY)


func set_rifle_reserve_ammo(new_rifle_reserve_ammo: int) -> void:
	rifle_reserve_ammo = maxi(0, new_rifle_reserve_ammo)


func reload_rifle_magazine() -> int:
	var missing_ammo := RIFLE_MAGAZINE_CAPACITY - rifle_ammo
	var transferred_ammo := mini(missing_ammo, rifle_reserve_ammo)
	set_rifle_ammo(rifle_ammo + transferred_ammo)
	set_rifle_reserve_ammo(rifle_reserve_ammo - transferred_ammo)
	return transferred_ammo


func set_current_weapon(new_weapon: int) -> void:
	current_weapon = WEAPON_KNIFE if new_weapon == WEAPON_KNIFE else WEAPON_RIFLE


func respawn_player() -> void:
	set_player_hp(roundi(float(get_player_max_hp()) * PLAYER_RESPAWN_RATIO))


func add_gold(amount: int) -> int:
	var accepted := maxi(0, amount)
	gold_score += accepted
	return accepted


func get_item_definition(item_id: String) -> Dictionary:
	if not ITEM_DEFINITIONS.has(item_id):
		return {}
	return Dictionary(ITEM_DEFINITIONS[item_id]).duplicate(true)


func get_item_name(item_id: String) -> String:
	return str(get_item_definition(item_id).get("name", "Item desconhecido"))


func get_item_kind(item_id: String) -> String:
	return str(get_item_definition(item_id).get("kind", ""))


func get_item_armor_slot(item_id: String) -> String:
	return str(get_item_definition(item_id).get("slot", ""))


func get_inventory_snapshot() -> Array[Dictionary]:
	return inventory.duplicate(true)


func get_inventory_entry(index: int) -> Dictionary:
	if index < 0 or index >= inventory.size():
		return {}
	return inventory[index].duplicate(true)


func get_inventory_used_slots() -> int:
	return inventory.size()


func get_item_count(item_id: String) -> int:
	var total := 0
	for entry in inventory:
		if str(entry.get("item_id", "")) == item_id:
			total += maxi(0, int(entry.get("quantity", 0)))
	return total


func can_store_item(item_id: String) -> bool:
	var definition := get_item_definition(item_id)
	if definition.is_empty() or item_id == ITEM_COIN:
		return false
	var stack_limit := maxi(1, int(definition.get("stack_limit", 1)))
	for entry in inventory:
		if (
			str(entry.get("item_id", "")) == item_id
			and int(entry.get("quantity", 0)) < stack_limit
		):
			return true
	return inventory.size() < INVENTORY_CAPACITY


func add_inventory_item(item_id: String, quantity: int = 1) -> Dictionary:
	var definition := get_item_definition(item_id)
	var requested := maxi(0, quantity)
	if definition.is_empty() or item_id == ITEM_COIN or requested <= 0:
		return {"accepted": 0, "remaining": requested}

	var remaining := requested
	var stack_limit := maxi(1, int(definition.get("stack_limit", 1)))
	for index in range(inventory.size()):
		if remaining <= 0:
			break
		var entry := inventory[index]
		if str(entry.get("item_id", "")) != item_id:
			continue
		var current_quantity := maxi(0, int(entry.get("quantity", 0)))
		var added := mini(remaining, stack_limit - current_quantity)
		if added <= 0:
			continue
		entry["quantity"] = current_quantity + added
		inventory[index] = entry
		remaining -= added

	while remaining > 0 and inventory.size() < INVENTORY_CAPACITY:
		var stack_quantity := mini(remaining, stack_limit)
		inventory.append({"item_id": item_id, "quantity": stack_quantity})
		remaining -= stack_quantity

	var accepted := requested - remaining
	if accepted > 0:
		inventory_changed.emit()
	return {"accepted": accepted, "remaining": remaining}


func remove_inventory_item(index: int, quantity: int = 1) -> bool:
	if index < 0 or index >= inventory.size() or quantity <= 0:
		return false
	var entry := inventory[index]
	var current_quantity := maxi(0, int(entry.get("quantity", 0)))
	if current_quantity <= 0:
		return false
	var remaining_quantity := current_quantity - quantity
	if remaining_quantity > 0:
		entry["quantity"] = remaining_quantity
		inventory[index] = entry
	else:
		inventory.remove_at(index)
	inventory_changed.emit()
	return true


func acquire_armor(item_id: String) -> Dictionary:
	var definition := get_item_definition(item_id)
	if str(definition.get("kind", "")) != "armor":
		return {"accepted": false, "reason": "invalid"}
	var slot := str(definition.get("slot", ""))
	if not equipped_armor.has(slot):
		return {"accepted": false, "reason": "invalid"}

	var current_item := str(equipped_armor.get(slot, ""))
	if current_item.is_empty():
		equipped_armor[slot] = item_id
		_finish_equipment_change()
		return {"accepted": true, "equipped": true, "replaced": ""}

	var current_defense := int(get_item_definition(current_item).get("defense", 0))
	var new_defense := int(definition.get("defense", 0))
	if new_defense > current_defense:
		if not can_store_item(current_item):
			return {"accepted": false, "reason": "inventory_full"}
		var store_result := add_inventory_item(current_item, 1)
		if int(store_result.get("accepted", 0)) != 1:
			return {"accepted": false, "reason": "inventory_full"}
		equipped_armor[slot] = item_id
		_finish_equipment_change()
		return {"accepted": true, "equipped": true, "replaced": current_item}

	var inventory_result := add_inventory_item(item_id, 1)
	if int(inventory_result.get("accepted", 0)) != 1:
		return {"accepted": false, "reason": "inventory_full"}
	return {"accepted": true, "equipped": false, "replaced": ""}


func equip_inventory_item(index: int) -> Dictionary:
	var entry := get_inventory_entry(index)
	if entry.is_empty():
		return {"success": false, "reason": "invalid"}
	var item_id := str(entry.get("item_id", ""))
	var definition := get_item_definition(item_id)
	if str(definition.get("kind", "")) != "armor":
		return {"success": false, "reason": "not_armor"}
	var slot := str(definition.get("slot", ""))
	var current_item := str(equipped_armor.get(slot, ""))
	if current_item == item_id:
		return {"success": false, "reason": "duplicate"}

	if current_item.is_empty():
		inventory.remove_at(index)
	else:
		inventory[index] = {"item_id": current_item, "quantity": 1}
	equipped_armor[slot] = item_id
	_finish_equipment_change()
	return {"success": true, "equipped": item_id, "replaced": current_item}


func unequip_armor(slot: String) -> Dictionary:
	if not equipped_armor.has(slot):
		return {"success": false, "reason": "invalid"}
	var current_item := str(equipped_armor.get(slot, ""))
	if current_item.is_empty():
		return {"success": false, "reason": "empty"}
	if not can_store_item(current_item):
		return {"success": false, "reason": "inventory_full"}
	var result := add_inventory_item(current_item, 1)
	if int(result.get("accepted", 0)) != 1:
		return {"success": false, "reason": "inventory_full"}
	equipped_armor[slot] = ""
	_finish_equipment_change()
	return {"success": true, "item_id": current_item}


func get_equipped_item(slot: String) -> String:
	return str(equipped_armor.get(slot, ""))


func is_armor_slot_equipped(slot: String) -> bool:
	return not get_equipped_item(slot).is_empty()


func get_equipped_armor_snapshot() -> Dictionary:
	return equipped_armor.duplicate(true)


func get_attribute_value(attribute: String) -> int:
	var value := 1
	for slot in ARMOR_SLOTS:
		var item_id := get_equipped_item(slot)
		if item_id.is_empty():
			continue
		var definition := get_item_definition(item_id)
		if str(definition.get("attribute", "")) == attribute:
			value += maxi(0, int(definition.get("attribute_bonus", 0)))
	return value


func get_defense_points() -> int:
	var total := 0
	for slot in ARMOR_SLOTS:
		var item_id := get_equipped_item(slot)
		if item_id.is_empty():
			continue
		total += maxi(0, int(get_item_definition(item_id).get("defense", 0)))
	return total


func get_player_max_hp() -> int:
	return PLAYER_MAX_HP + maxi(0, get_attribute_value(ATTRIBUTE_VIGOR) - 1) * VIGOR_HP_BONUS


func get_rifle_damage(base_damage: int) -> int:
	return maxi(0, base_damage) + maxi(0, get_attribute_value(ATTRIBUTE_AIM) - 1) * ATTRIBUTE_DAMAGE_BONUS


func get_knife_damage(base_damage: int) -> int:
	return maxi(0, base_damage) + maxi(0, get_attribute_value(ATTRIBUTE_STRENGTH) - 1) * ATTRIBUTE_DAMAGE_BONUS


func get_player_critical_chance(base_chance: float = 0.25) -> float:
	var bonus_points := maxi(0, get_attribute_value(ATTRIBUTE_AIM) - 1)
	return minf(MAX_CRITICAL_CHANCE, maxf(0.0, base_chance) + float(bonus_points) * CRITICAL_CHANCE_BONUS)


func reduce_player_damage(raw_damage: int) -> int:
	if raw_damage <= 0:
		return 0
	var reduction := clampf(float(get_defense_points()) * DEFENSE_REDUCTION_PER_POINT, 0.0, 0.99)
	return maxi(1, roundi(float(raw_damage) * (1.0 - reduction)))


func use_health_potion() -> Dictionary:
	var potion_index := -1
	for index in range(inventory.size()):
		if str(inventory[index].get("item_id", "")) == ITEM_HEALTH_POTION:
			potion_index = index
			break
	if potion_index < 0:
		return {"success": false, "reason": "empty", "healed": 0}
	var maximum_hp := get_player_max_hp()
	if player_hp >= maximum_hp:
		return {"success": false, "reason": "full_health", "healed": 0}
	var previous_hp := player_hp
	var healing := maxi(1, roundi(float(maximum_hp) * HEALTH_POTION_HEAL_RATIO))
	set_player_hp(player_hp + healing)
	remove_inventory_item(potion_index, 1)
	return {"success": true, "reason": "", "healed": player_hp - previous_hp}


func generate_common_enemy_loot(
	armor_item_id: String,
	potion_roll: float = -1.0,
	armor_roll: float = -1.0
) -> Dictionary:
	add_gold(COMMON_ENEMY_GOLD)
	var items: Array[String] = []
	var resolved_potion_roll := randf() if potion_roll < 0.0 else potion_roll
	var resolved_armor_roll := randf() if armor_roll < 0.0 else armor_roll
	if resolved_potion_roll < COMMON_POTION_DROP_CHANCE:
		items.append(ITEM_HEALTH_POTION)
	if (
		get_item_kind(armor_item_id) == "armor"
		and resolved_armor_roll < COMMON_ARMOR_DROP_CHANCE
	):
		items.append(armor_item_id)
	return {"gold": COMMON_ENEMY_GOLD, "items": items}


func get_boss_loot_items() -> Array[String]:
	return [ITEM_HEALTH_POTION, ITEM_ARMOR_LEGS]


func _finish_equipment_change() -> void:
	set_player_hp(player_hp)
	equipment_changed.emit()
	inventory_changed.emit()


func begin_dungeon(
	exterior_return_position: Vector2,
	new_hp: int,
	new_rifle_ammo: int,
	new_weapon: int
) -> void:
	save_player_state(new_hp, new_rifle_ammo, new_weapon)
	return_position = exterior_return_position
	return_position_pending = true
	returning_from_combat = false
	returning_from_dungeon = false
	dungeon_active = true
	reset_dungeon_progress()


func leave_dungeon(new_hp: int, new_rifle_ammo: int, new_weapon: int) -> void:
	save_player_state(new_hp, new_rifle_ammo, new_weapon)
	reset_dungeon_progress()
	dungeon_active = false
	returning_from_combat = false
	returning_from_dungeon = true


func reset_dungeon_progress() -> void:
	dungeon_progress.clear()
	dungeon_room_index = 0


func get_current_dungeon_room_id() -> String:
	var safe_index := clampi(dungeon_room_index, 0, DUNGEON_ROOM_IDS.size() - 1)
	return String(DUNGEON_ROOM_IDS[safe_index])


func get_current_dungeon_room_number() -> int:
	return clampi(dungeon_room_index, 0, DUNGEON_ROOM_IDS.size() - 1) + 1


func get_implemented_dungeon_room_count() -> int:
	return DUNGEON_ROOM_IDS.size()


func has_next_dungeon_room() -> bool:
	return dungeon_active and dungeon_room_index + 1 < DUNGEON_ROOM_IDS.size()


func advance_dungeon_room() -> bool:
	if not has_next_dungeon_room():
		return false
	if not is_dungeon_room_cleared(get_current_dungeon_room_id()):
		return false

	dungeon_room_index += 1
	return true


func mark_dungeon_room_cleared(room_id: String) -> void:
	if room_id.is_empty():
		return

	dungeon_progress[room_id] = true


func is_dungeon_room_cleared(room_id: String) -> bool:
	if room_id.is_empty():
		return false

	return bool(dungeon_progress.get(room_id, false))


func complete_dungeon() -> bool:
	mark_dungeon_room_cleared(get_current_dungeon_room_id())
	if dungeon_completed:
		return false
	dungeon_completed = true
	add_gold(DUNGEON_BOSS_REWARD)
	return true


func is_encounter_defeated(encounter_id: String) -> bool:
	return bool(defeated_encounters.get(encounter_id, false))


func has_return_position() -> bool:
	return return_position_pending


func consume_return_position(fallback: Vector2) -> Vector2:
	if not return_position_pending:
		return fallback

	return_position_pending = false
	return return_position


func acknowledge_return() -> void:
	returning_from_combat = false
	returning_from_dungeon = false


func add_lapada_charge() -> bool:
	if lapada_charges < MAX_LAPADA_CHARGES:
		lapada_charges += 1
		return lapada_charges == MAX_LAPADA_CHARGES
	return false


func consume_lapada_charges() -> bool:
	if lapada_charges >= MAX_LAPADA_CHARGES:
		lapada_charges = 0
		return true
	return false


func has_lapada_ready() -> bool:
	return lapada_charges >= MAX_LAPADA_CHARGES


func export_save_data() -> Dictionary:
	return {
		"player_hp": player_hp,
		"rifle_ammo": rifle_ammo,
		"rifle_reserve_ammo": rifle_reserve_ammo,
		"current_weapon": current_weapon,
		"gold_score": gold_score,
		"lapada_charges": lapada_charges,
		"inventory": inventory.duplicate(true),
		"equipped_armor": equipped_armor.duplicate(true),
		"defeated_encounters": defeated_encounters.duplicate(true),
		"dungeon_active": dungeon_active,
		"dungeon_progress": dungeon_progress.duplicate(true),
		"dungeon_room_index": dungeon_room_index,
		"dungeon_completed": dungeon_completed,
	}


func import_save_data(data: Dictionary) -> void:
	inventory = _sanitize_inventory(data.get("inventory", []))
	equipped_armor = _sanitize_equipped_armor(data.get("equipped_armor", {}))
	set_player_hp(int(data.get("player_hp", DEFAULT_PLAYER_HP)))
	set_rifle_ammo(int(data.get("rifle_ammo", DEFAULT_RIFLE_AMMO)))
	set_rifle_reserve_ammo(int(data.get("rifle_reserve_ammo", DEFAULT_RIFLE_RESERVE_AMMO)))
	set_current_weapon(int(data.get("current_weapon", DEFAULT_WEAPON)))
	gold_score = maxi(0, int(data.get("gold_score", DEFAULT_GOLD_SCORE)))
	lapada_charges = clampi(int(data.get("lapada_charges", 0)), 0, MAX_LAPADA_CHARGES)
	defeated_encounters = _sanitize_boolean_dictionary(data.get("defeated_encounters", {}))
	dungeon_active = bool(data.get("dungeon_active", false))
	dungeon_progress = _sanitize_boolean_dictionary(data.get("dungeon_progress", {}))
	dungeon_room_index = clampi(
		int(data.get("dungeon_room_index", 0)),
		0,
		DUNGEON_ROOM_IDS.size() - 1
	)
	dungeon_completed = bool(data.get("dungeon_completed", false))

	active_encounter_id = ""
	return_position = Vector2.ZERO
	return_position_pending = false
	returning_from_combat = false
	returning_from_dungeon = false


func _sanitize_boolean_dictionary(value: Variant) -> Dictionary:
	var sanitized: Dictionary = {}
	if not value is Dictionary:
		return sanitized
	for key in value:
		if bool(value[key]):
			sanitized[str(key)] = true
	return sanitized


func _sanitize_inventory(value: Variant) -> Array[Dictionary]:
	var sanitized: Array[Dictionary] = []
	if not value is Array:
		return sanitized
	for raw_entry in value:
		if sanitized.size() >= INVENTORY_CAPACITY:
			break
		if not raw_entry is Dictionary:
			continue
		var item_id := str(raw_entry.get("item_id", ""))
		var definition := get_item_definition(item_id)
		if definition.is_empty() or item_id == ITEM_COIN:
			continue
		var stack_limit := maxi(1, int(definition.get("stack_limit", 1)))
		var raw_quantity := int(raw_entry.get("quantity", 0))
		if raw_quantity <= 0:
			continue
		var quantity := mini(raw_quantity, stack_limit)
		sanitized.append({"item_id": item_id, "quantity": quantity})
	return sanitized


func _sanitize_equipped_armor(value: Variant) -> Dictionary:
	var sanitized := {
		ARMOR_SLOT_HEAD: "",
		ARMOR_SLOT_CHEST: "",
		ARMOR_SLOT_LEGS: "",
		ARMOR_SLOT_FEET: "",
	}
	if not value is Dictionary:
		return sanitized
	for slot in ARMOR_SLOTS:
		var item_id := str(value.get(slot, ""))
		var definition := get_item_definition(item_id)
		if (
			str(definition.get("kind", "")) == "armor"
			and str(definition.get("slot", "")) == slot
		):
			sanitized[slot] = item_id
	return sanitized


func reset_session() -> void:
	defeated_encounters.clear()
	active_encounter_id = ""
	return_position = Vector2.ZERO
	return_position_pending = false
	returning_from_combat = false
	returning_from_dungeon = false
	player_hp = DEFAULT_PLAYER_HP
	rifle_ammo = DEFAULT_RIFLE_AMMO
	rifle_reserve_ammo = DEFAULT_RIFLE_RESERVE_AMMO
	current_weapon = DEFAULT_WEAPON
	gold_score = DEFAULT_GOLD_SCORE
	lapada_charges = 0
	inventory.clear()
	equipped_armor = {
		ARMOR_SLOT_HEAD: "",
		ARMOR_SLOT_CHEST: "",
		ARMOR_SLOT_LEGS: "",
		ARMOR_SLOT_FEET: "",
	}
	dungeon_active = false
	dungeon_completed = false
	reset_dungeon_progress()
