extends Node2D

const MAP_SIZE := Vector2i(16, 12)
const TILE_SIZE := Vector2(64.0, 32.0)
const HALF_TILE := TILE_SIZE * 0.5
const PLAYER_SPEED := 140.0
const CLOSE_ZOOM := Vector2(1.45, 1.45)
const CAMERA_FOLLOW_SPEED := 8.0
const CAMERA_TRANSITION_TIME := 0.28
const FADE_DURATION := 0.5
const CONTACT_DISTANCE := 23.0
const COMBAT_SCENE := "res://scenes/main.tscn"

const COLOR_VOID := Color("17120d")
const COLOR_GROUND_A := Color("a97945")
const COLOR_GROUND_B := Color("9b693d")
const COLOR_PATH_A := Color("c49a61")
const COLOR_PATH_B := Color("b98d55")
const COLOR_TILE_LINE := Color("604027")
const COLOR_CLIFF := Color("563620")
const COLOR_ROCK := Color("5d5547")
const COLOR_ROCK_LIGHT := Color("837966")
const COLOR_CACTUS := Color("42643d")
const COLOR_CACTUS_LIGHT := Color("668656")
const COLOR_PLAYER_COAT := Color("94452e")
const COLOR_PLAYER_HAT := Color("d1a15b")
const COLOR_ENEMY_COAT := Color("4f3327")
const COLOR_ENEMY_ARMOR := Color("6f6654")
const COLOR_ENEMY_HAT := Color("33231b")
const COLOR_MAGIC := Color("44d6b3")
const COLOR_ROUTE := Color(0.27, 0.84, 0.70, 0.45)

const PLAYER_START := Vector2i(1, 10)
const CAPANGA_ID := "capanga_01"
const CAPANGA_CELL := Vector2i(5, 10)
const ROAD_OBSTACLES = [
	Vector2i(5, 9),
	Vector2i(5, 11),
	Vector2i(6, 8),
	Vector2i(9, 5),
	Vector2i(12, 3),
]

@onready var player_anchor: Node2D = $PlayerAnchor
@onready var camera: Camera2D = $Camera2D
@onready var status_label: Label = $Interface/TopPanel/Status
@onready var version_label: Label = $Interface/Version
@onready var fade: ColorRect = $FadeLayer/Fade

var astar := AStarGrid2D.new()
var movement_path := PackedVector2Array()
var path_index := 0
var destination_marker := Vector2.ZERO
var has_destination := false
var overview_enabled := false
var camera_transitioning := false
var camera_tween: Tween
var capanga_active := true
var encounter_transitioning := false


func _ready() -> void:
	_setup_pathfinding()
	var start_position := _cell_to_world(PLAYER_START)
	var returned_from_combat: bool = GameState.returning_from_combat
	player_anchor.position = GameState.consume_return_position(start_position)
	capanga_active = not GameState.is_encounter_defeated(CAPANGA_ID)
	camera.position = player_anchor.position
	camera.zoom = CLOSE_ZOOM
	version_label.text = str(ProjectSettings.get_setting("application/config/version", "V.0.0.0"))

	if returned_from_combat:
		fade.modulate.a = 1.0
		var return_tween := create_tween()
		return_tween.tween_property(fade, "modulate:a", 0.0, FADE_DURATION)
		_update_status("Capanga vencido — caminho liberado.")
		GameState.acknowledge_return()
	else:
		fade.modulate.a = 0.0
		_update_status("Clique no caminho para caminhar.")

	queue_redraw()


func _physics_process(delta: float) -> void:
	_move_player(delta)
	_check_enemy_contact()

	if not overview_enabled and not camera_transitioning:
		var follow_weight := 1.0 - exp(-CAMERA_FOLLOW_SPEED * delta)
		camera.position = camera.position.lerp(player_anchor.position, follow_weight)


func _unhandled_input(event: InputEvent) -> void:
	if encounter_transitioning:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_toggle_overview()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_set_destination(get_global_mouse_position())
			get_viewport().set_input_as_handled()


func _setup_pathfinding() -> void:
	astar.region = Rect2i(Vector2i.ZERO, MAP_SIZE)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			if not _is_road(cell):
				astar.set_point_solid(cell)

	for obstacle in ROAD_OBSTACLES:
		astar.set_point_solid(obstacle)


func _is_road(cell: Vector2i) -> bool:
	var lower_path := cell.x <= 6 and cell.y >= 9
	var first_turn := cell.x >= 4 and cell.x <= 7 and cell.y >= 6 and cell.y <= 10
	var middle_path := cell.x >= 6 and cell.x <= 12 and cell.y >= 4 and cell.y <= 7
	var upper_path := cell.x >= 10 and cell.y >= 1 and cell.y <= 5
	return lower_path or first_turn or middle_path or upper_path


func _set_destination(clicked_world_position: Vector2) -> void:
	var target_cell := _world_to_cell(clicked_world_position)
	if not astar.is_in_boundsv(target_cell):
		_update_status("Destino fora do mapa.")
		return
	if astar.is_point_solid(target_cell):
		_update_status("Esse terreno está bloqueado.")
		return

	var start_cell := _world_to_cell(player_anchor.position)
	if not astar.is_in_boundsv(start_cell) or astar.is_point_solid(start_cell):
		start_cell = _nearest_walkable_cell(player_anchor.position)

	var id_path := astar.get_id_path(start_cell, target_cell)
	if id_path.is_empty():
		_update_status("Não há caminho até esse ponto.")
		return

	var new_path := PackedVector2Array()
	for index in range(1, id_path.size()):
		new_path.append(_cell_to_world(id_path[index]))

	var final_position := _position_inside_cell(clicked_world_position, target_cell)
	if new_path.is_empty():
		new_path.append(final_position)
	else:
		new_path[new_path.size() - 1] = final_position

	movement_path = new_path
	path_index = 0
	destination_marker = final_position
	has_destination = true
	_update_status("Caminhando a 140 px/s — novo clique troca o destino.")
	queue_redraw()


func _move_player(delta: float) -> void:
	if path_index >= movement_path.size():
		return

	var waypoint := movement_path[path_index]
	player_anchor.position = player_anchor.position.move_toward(waypoint, PLAYER_SPEED * delta)

	if player_anchor.position.distance_to(waypoint) <= 0.5:
		player_anchor.position = waypoint
		path_index += 1

		if path_index >= movement_path.size():
			movement_path.clear()
			path_index = 0
			has_destination = false
			_update_status("Destino alcançado.")

	queue_redraw()


func _check_enemy_contact() -> void:
	if not capanga_active or encounter_transitioning:
		return

	var capanga_position := _cell_to_world(CAPANGA_CELL)
	if player_anchor.position.distance_to(capanga_position) <= CONTACT_DISTANCE:
		_begin_encounter()


func _begin_encounter() -> void:
	encounter_transitioning = true
	movement_path.clear()
	path_index = 0
	has_destination = false
	GameState.begin_encounter(CAPANGA_ID, player_anchor.position)
	_update_status("Contato com o Capanga — iniciando combate...")

	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, FADE_DURATION)
	fade_tween.tween_callback(_open_combat_scene)
	queue_redraw()


func _open_combat_scene() -> void:
	get_tree().change_scene_to_file(COMBAT_SCENE)


func _toggle_overview() -> void:
	overview_enabled = not overview_enabled
	camera_transitioning = true

	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()

	var target_position := player_anchor.position
	var target_zoom := CLOSE_ZOOM
	if overview_enabled:
		target_position = _map_bounds().get_center()
		var viewport_size := get_viewport_rect().size
		var bounds_size := _map_bounds().size + TILE_SIZE * 2.0
		var fit_zoom: float = minf(viewport_size.x / bounds_size.x, viewport_size.y / bounds_size.y)
		target_zoom = Vector2.ONE * minf(fit_zoom, 0.9)

	camera_tween = create_tween().set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "position", target_position, CAMERA_TRANSITION_TIME)
	camera_tween.tween_property(camera, "zoom", target_zoom, CAMERA_TRANSITION_TIME)
	camera_tween.finished.connect(_on_camera_transition_finished)

	_update_status("Visão geral ativada." if overview_enabled else "Câmera acompanhando o Cangaceiro.")


func _on_camera_transition_finished() -> void:
	camera_transitioning = false


func _nearest_walkable_cell(world_position: Vector2) -> Vector2i:
	var origin := _world_to_cell(world_position)
	if astar.is_in_boundsv(origin) and not astar.is_point_solid(origin):
		return origin

	for radius in range(1, maxi(MAP_SIZE.x, MAP_SIZE.y)):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var candidate := Vector2i(x, y)
				if astar.is_in_boundsv(candidate) and not astar.is_point_solid(candidate):
					return candidate

	return PLAYER_START


func _position_inside_cell(clicked_position: Vector2, cell: Vector2i) -> Vector2:
	var center := _cell_to_world(cell)
	var offset := clicked_position - center
	var diamond_distance: float = absf(offset.x) / HALF_TILE.x + absf(offset.y) / HALF_TILE.y
	if diamond_distance <= 0.78:
		return clicked_position
	return center


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		(cell.x - cell.y) * HALF_TILE.x,
		(cell.x + cell.y) * HALF_TILE.y
	)


func _world_to_cell(world_position: Vector2) -> Vector2i:
	var grid_x := world_position.x / TILE_SIZE.x + world_position.y / TILE_SIZE.y
	var grid_y := world_position.y / TILE_SIZE.y - world_position.x / TILE_SIZE.x
	return Vector2i(roundi(grid_x), roundi(grid_y))


func _map_bounds() -> Rect2:
	var corners: Array[Vector2] = [
		_cell_to_world(Vector2i(0, 0)),
		_cell_to_world(Vector2i(MAP_SIZE.x - 1, 0)),
		_cell_to_world(Vector2i(0, MAP_SIZE.y - 1)),
		_cell_to_world(MAP_SIZE - Vector2i.ONE),
	]
	var minimum: Vector2 = corners[0]
	var maximum: Vector2 = corners[0]

	for corner in corners:
		minimum.x = minf(minimum.x, corner.x)
		minimum.y = minf(minimum.y, corner.y)
		maximum.x = maxf(maximum.x, corner.x)
		maximum.y = maxf(maximum.y, corner.y)

	minimum -= HALF_TILE
	maximum += HALF_TILE
	return Rect2(minimum, maximum - minimum)


func _update_status(message: String) -> void:
	status_label.text = message


func _draw() -> void:
	var bounds := _map_bounds().grow(256.0)
	draw_rect(bounds, COLOR_VOID, true)
	_draw_tiles()
	_draw_route_preview()
	_draw_destination()
	_draw_capanga()
	_draw_player()


func _draw_tiles() -> void:
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)
			var is_road_cell := _is_road(cell)
			var color: Color

			if is_road_cell:
				color = COLOR_PATH_A if (x + y) % 2 == 0 else COLOR_PATH_B
			else:
				color = COLOR_GROUND_A if (x + y) % 2 == 0 else COLOR_GROUND_B

			_draw_diamond(center, color)

			if not is_road_cell:
				_draw_cliff_mark(center)
			elif ROAD_OBSTACLES.has(cell):
				_draw_road_obstacle(center, (x + y) % 2 == 0)


func _draw_diamond(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -HALF_TILE.y),
		center + Vector2(HALF_TILE.x, 0.0),
		center + Vector2(0.0, HALF_TILE.y),
		center + Vector2(-HALF_TILE.x, 0.0),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), COLOR_TILE_LINE, 1.0)


func _draw_cliff_mark(center: Vector2) -> void:
	if int(center.x + center.y) % 3 != 0:
		return
	draw_line(center + Vector2(-9.0, 2.0), center + Vector2(-2.0, 6.0), COLOR_CLIFF, 2.0)
	draw_line(center + Vector2(2.0, 6.0), center + Vector2(9.0, 2.0), COLOR_CLIFF, 2.0)


func _draw_road_obstacle(center: Vector2, rock: bool) -> void:
	if rock:
		draw_rect(Rect2(center + Vector2(-9.0, -12.0), Vector2(18.0, 17.0)), COLOR_ROCK, true)
		draw_rect(Rect2(center + Vector2(-7.0, -10.0), Vector2(11.0, 4.0)), COLOR_ROCK_LIGHT, true)
	else:
		draw_rect(Rect2(center + Vector2(-3.0, -15.0), Vector2(6.0, 19.0)), COLOR_CACTUS, true)
		draw_rect(Rect2(center + Vector2(-8.0, -9.0), Vector2(6.0, 4.0)), COLOR_CACTUS, true)
		draw_rect(Rect2(center + Vector2(3.0, -5.0), Vector2(6.0, 4.0)), COLOR_CACTUS_LIGHT, true)


func _draw_route_preview() -> void:
	if path_index >= movement_path.size():
		return

	var route_points := PackedVector2Array([player_anchor.position])
	for index in range(path_index, movement_path.size()):
		route_points.append(movement_path[index])

	if route_points.size() >= 2:
		draw_polyline(route_points, COLOR_ROUTE, 2.0, true)


func _draw_destination() -> void:
	if not has_destination:
		return
	draw_circle(destination_marker, 9.0, Color(0.27, 0.84, 0.70, 0.16))
	draw_arc(destination_marker, 9.0, 0.0, TAU, 24, COLOR_MAGIC, 2.0, true)


func _draw_capanga() -> void:
	if not capanga_active:
		return

	var position := _cell_to_world(CAPANGA_CELL)
	draw_circle(position + Vector2(0.0, 7.0), 10.0, Color(0.08, 0.05, 0.03, 0.35))
	draw_rect(Rect2(position + Vector2(-8.0, -18.0), Vector2(16.0, 19.0)), COLOR_ENEMY_COAT, true)
	draw_rect(Rect2(position + Vector2(-10.0, -14.0), Vector2(20.0, 9.0)), COLOR_ENEMY_ARMOR, true)
	draw_rect(Rect2(position + Vector2(-11.0, -21.0), Vector2(22.0, 5.0)), COLOR_ENEMY_HAT, true)
	draw_rect(Rect2(position + Vector2(-7.0, -26.0), Vector2(14.0, 6.0)), COLOR_ENEMY_HAT, true)


func _draw_player() -> void:
	var position := player_anchor.position
	draw_circle(position + Vector2(0.0, 7.0), 9.0, Color(0.08, 0.05, 0.03, 0.35))
	draw_rect(Rect2(position + Vector2(-7.0, -17.0), Vector2(14.0, 18.0)), COLOR_PLAYER_COAT, true)
	draw_rect(Rect2(position + Vector2(-11.0, -20.0), Vector2(22.0, 5.0)), COLOR_PLAYER_HAT, true)
	draw_rect(Rect2(position + Vector2(-7.0, -25.0), Vector2(14.0, 6.0)), COLOR_PLAYER_HAT, true)
