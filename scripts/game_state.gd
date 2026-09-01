extends Node

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
	player_hp = clampi(new_hp, 0, PLAYER_MAX_HP)


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
	set_player_hp(roundi(float(PLAYER_MAX_HP) * PLAYER_RESPAWN_RATIO))


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
	gold_score += DUNGEON_BOSS_REWARD
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
	dungeon_active = false
	dungeon_completed = false
	reset_dungeon_progress()
