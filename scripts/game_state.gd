extends Node

var defeated_encounters: Dictionary = {}
var active_encounter_id := ""
var return_position := Vector2.ZERO
var return_position_pending := false
var returning_from_combat := false


func begin_encounter(encounter_id: String, player_position: Vector2) -> void:
	active_encounter_id = encounter_id
	return_position = player_position
	return_position_pending = true
	returning_from_combat = false


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


func reset_session() -> void:
	defeated_encounters.clear()
	active_encounter_id = ""
	return_position = Vector2.ZERO
	return_position_pending = false
	returning_from_combat = false
