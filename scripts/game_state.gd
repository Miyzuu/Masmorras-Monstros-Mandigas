extends Node

const PLAYER_MAX_HP := 100
const PLAYER_RESPAWN_RATIO := 0.40
const DEFAULT_PLAYER_HP := PLAYER_MAX_HP
const DEFAULT_RIFLE_AMMO := 5
const DEFAULT_WEAPON := 0
const DEFAULT_GOLD_SCORE := 0
const WEAPON_RIFLE := 0
const WEAPON_KNIFE := 1

var defeated_encounters: Dictionary = {}
var active_encounter_id := ""
var return_position := Vector2.ZERO
var return_position_pending := false
var returning_from_combat := false
var returning_from_dungeon := false

var player_hp := DEFAULT_PLAYER_HP
var rifle_ammo := DEFAULT_RIFLE_AMMO
var current_weapon := DEFAULT_WEAPON
var gold_score := DEFAULT_GOLD_SCORE

var dungeon_active := false
var dungeon_progress: Dictionary = {}


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
	rifle_ammo = maxi(0, new_rifle_ammo)


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


func reset_session() -> void:
	defeated_encounters.clear()
	active_encounter_id = ""
	return_position = Vector2.ZERO
	return_position_pending = false
	returning_from_combat = false
	returning_from_dungeon = false
	player_hp = DEFAULT_PLAYER_HP
	rifle_ammo = DEFAULT_RIFLE_AMMO
	current_weapon = DEFAULT_WEAPON
	gold_score = DEFAULT_GOLD_SCORE
	dungeon_active = false
	reset_dungeon_progress()
