extends Node2D

enum Weapon {
	RIFLE,
	KNIFE,
}

const MAP_SIZE := Vector2i(16, 12)
const TILE_SIZE := Vector2(64.0, 32.0)
const HALF_TILE := TILE_SIZE * 0.5
const PLAYER_SPEED := 140.0
const PLAYER_MAX_HP := 100
const CLOSE_ZOOM := Vector2(1.45, 1.45)
const CAMERA_FOLLOW_SPEED := 8.0
const CAMERA_TRANSITION_TIME := 0.28
const FADE_DURATION := 0.5
const EXPLORATION_SCENE := "res://scenes/exploration.tscn"
const CHARACTER_ATLAS: Texture2D = preload("res://assets/art/characters/animations/personagens_se_idle4_walk6_64px_16c.png")
const CHARACTER_FRAME_SIZE := Vector2(64.0, 64.0)
const CHARACTER_FOOT_ANCHOR := Vector2(32.0, 60.0)
const CHARACTER_ATLAS_COLUMNS := 10
const CHARACTER_ATLAS_ROWS := 2
const PLAYER_ATLAS_ROW := 0
const ANIMATION_IDLE := 0
const ANIMATION_WALK := 1
const IDLE_FIRST_COLUMN := 0
const IDLE_FRAME_COUNT := 4
const IDLE_FPS := 4.0
const WALK_FIRST_COLUMN := 4
const WALK_FRAME_COUNT := 6
const WALK_FPS := 10.0

const PLAYER_START := Vector2i(2, 10)
const EXIT_DOOR_CELL := Vector2i(0, 10)
const EXIT_INTERACTION_CELL := Vector2i(1, 10)
const BLOCKED_STAIRS_CELL := Vector2i(14, 1)

const COLOR_VOID := Color("0d0e12")
const COLOR_FLOOR_A := Color("6f675f")
const COLOR_FLOOR_B := Color("625b55")
const COLOR_WALL_A := Color("39383b")
const COLOR_WALL_B := Color("302f33")
const COLOR_TILE_LINE := Color("24252a")
const COLOR_WALL_EDGE := Color("8d8174")
const COLOR_DOOR_FRAME := Color("211d1b")
const COLOR_DOOR := Color("684a36")
const COLOR_STAIRS := Color("292b31")
const COLOR_STAIRS_EDGE := Color("a18f7b")
const COLOR_SEAL := Color("ab3c77")
const COLOR_ROUTE := Color(0.27, 0.84, 0.70, 0.45)
const COLOR_MAGIC := Color("44d6b3")

@onready var player_anchor: Node2D = $PlayerAnchor
@onready var camera: Camera2D = $Camera2D
@onready var status_label: Label = $Interface/TopPanel/Status
@onready var version_label: Label = $Interface/Version
@onready var health_fill: ColorRect = $Interface/StatusHUD/HealthBack/HealthFill
@onready var health_label: Label = $Interface/StatusHUD/HealthBack/HealthLabel
@onready var weapon_label: Label = $Interface/StatusHUD/WeaponLabel
@onready var exit_prompt: Control = $DialogLayer/ExitPrompt
@onready var exit_yes_button: Button = $DialogLayer/ExitPrompt/Dialog/YesButton
@onready var exit_no_button: Button = $DialogLayer/ExitPrompt/Dialog/NoButton
@onready var fade: ColorRect = $FadeLayer/Fade

var astar := AStarGrid2D.new()
var movement_path := PackedVector2Array()
var path_index := 0
var destination_marker := Vector2.ZERO
var has_destination := false
var player_animation_state := ANIMATION_IDLE
var player_animation_frame := 0
var player_animation_elapsed := 0.0
var overview_enabled := false
var camera_transitioning := false
var camera_tween: Tween
var fade_tween: Tween

var player_hp: int:
	get:
		return GameState.player_hp
	set(value):
		GameState.set_player_hp(value)
var rifle_ammo: int:
	get:
		return GameState.rifle_ammo
	set(value):
		GameState.set_rifle_ammo(value)
var current_weapon: int:
	get:
		return GameState.current_weapon
	set(value):
		GameState.set_current_weapon(value)

var exit_prompt_visible := false
var exit_contact_latched := false
var scene_transitioning := false
var exit_request_source := ""


func _ready() -> void:
	_setup_pathfinding()
	player_anchor.position = _cell_to_world(PLAYER_START)
	camera.position = player_anchor.position
	camera.zoom = CLOSE_ZOOM
	version_label.text = str(ProjectSettings.get_setting("application/config/version", "V.0.0.0"))
	exit_prompt.visible = false
	exit_yes_button.pressed.connect(_confirm_dungeon_exit)
	exit_no_button.pressed.connect(_cancel_dungeon_exit)
	scene_transitioning = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	fade.modulate.a = 1.0
	fade_tween = create_tween()
	fade_tween.tween_property(fade, "modulate:a", 0.0, FADE_DURATION)
	fade_tween.finished.connect(_finish_entry_fade, CONNECT_ONE_SHOT)
	_update_status("Sala inicial vazia — a escada permanece bloqueada nesta versão.")
	_update_hud()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if exit_prompt_visible or scene_transitioning:
		return

	var player_previous_position := player_anchor.position
	_move_player(delta)
	_update_player_animation(delta, player_previous_position)
	if _check_exit_door_contact():
		queue_redraw()
		return

	if not overview_enabled and not camera_transitioning:
		var follow_weight := 1.0 - exp(-CAMERA_FOLLOW_SPEED * delta)
		camera.position = camera.position.lerp(player_anchor.position, follow_weight)
	queue_redraw()


func _update_player_animation(delta: float, previous_position: Vector2) -> void:
	var result := _next_character_animation(
		player_animation_state,
		player_animation_frame,
		player_animation_elapsed,
		not player_anchor.position.is_equal_approx(previous_position),
		delta
	)
	player_animation_state = int(result["state"])
	player_animation_frame = int(result["frame"])
	player_animation_elapsed = float(result["elapsed"])


func _next_character_animation(
	current_state: int,
	current_frame: int,
	current_elapsed: float,
	moved: bool,
	delta: float
) -> Dictionary:
	var target_state := ANIMATION_WALK if moved else ANIMATION_IDLE
	if current_state != target_state:
		return {
			"state": target_state,
			"frame": 0,
			"elapsed": 0.0,
		}

	var frame_count := WALK_FRAME_COUNT if target_state == ANIMATION_WALK else IDLE_FRAME_COUNT
	var frames_per_second := WALK_FPS if target_state == ANIMATION_WALK else IDLE_FPS
	var frame_duration := 1.0 / frames_per_second
	var next_elapsed := maxf(0.0, current_elapsed) + maxf(0.0, delta)
	var frames_advanced := floori(next_elapsed / frame_duration)
	if frames_advanced > 0:
		next_elapsed = fmod(next_elapsed, frame_duration)

	return {
		"state": target_state,
		"frame": (current_frame + frames_advanced) % frame_count,
		"elapsed": next_elapsed,
	}


func _reset_player_animation_to_idle() -> void:
	player_animation_state = ANIMATION_IDLE
	player_animation_frame = 0
	player_animation_elapsed = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if scene_transitioning:
		get_viewport().set_input_as_handled()
		return

	if exit_prompt_visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if _handle_exit_prompt_key(event.keycode):
				get_viewport().set_input_as_handled()
				return
		if event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_request_dungeon_exit("Esc")
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_M:
			_toggle_overview()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_set_destination(get_global_mouse_position())
			get_viewport().set_input_as_handled()


func _handle_exit_prompt_key(keycode: int) -> bool:
	if keycode == KEY_ENTER or keycode == KEY_KP_ENTER or keycode == KEY_SPACE:
		_confirm_dungeon_exit()
		return true
	if keycode == KEY_ESCAPE:
		_cancel_dungeon_exit()
		return true
	return false


func _check_exit_door_contact() -> bool:
	var touching_exit := _world_to_cell(player_anchor.position) == EXIT_INTERACTION_CELL
	if not touching_exit:
		exit_contact_latched = false
		return false
	if exit_contact_latched:
		return false

	exit_contact_latched = true
	_request_dungeon_exit("porta")
	return true


func _request_dungeon_exit(source: String) -> void:
	if exit_prompt_visible or scene_transitioning:
		return
	exit_request_source = source
	exit_prompt_visible = true
	exit_prompt.visible = true
	movement_path.clear()
	path_index = 0
	has_destination = false
	_play_audio("ui_hover")
	_reset_player_animation_to_idle()
	_update_status("Sair apagará todo o progresso feito dentro da masmorra.")
	exit_yes_button.grab_focus()


func _cancel_dungeon_exit() -> void:
	if not exit_prompt_visible or scene_transitioning:
		return
	exit_prompt_visible = false
	exit_prompt.visible = false
	_play_audio("ui_click")
	_update_status("Saída cancelada — a exploração da sala continua.")


func _prepare_dungeon_exit() -> void:
	GameState.leave_dungeon(player_hp, rifle_ammo, current_weapon)


func _confirm_dungeon_exit() -> void:
	if not exit_prompt_visible or scene_transitioning:
		return
	exit_prompt_visible = false
	exit_prompt.visible = false
	scene_transitioning = true
	_play_audio("door")
	_prepare_dungeon_exit()
	_start_scene_transition(EXPLORATION_SCENE)


func _play_audio(sound_name: String) -> void:
	if is_inside_tree() and get_tree().root.has_node("AudioManager"):
		var mgr := get_tree().root.get_node("AudioManager")
		match sound_name:
			"ui_click": mgr.call("play_ui_click")
			"ui_hover": mgr.call("play_ui_hover")
			"door": mgr.call("play_door_open")
			_: mgr.call("play_sfx", sound_name)


func _start_scene_transition(scene_path: String) -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_tween = create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, FADE_DURATION)
	fade_tween.finished.connect(_change_scene.bind(scene_path), CONNECT_ONE_SHOT)


func _finish_entry_fade() -> void:
	scene_transitioning = false
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _change_scene(scene_path: String) -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file(scene_path)


func _setup_pathfinding() -> void:
	astar.region = Rect2i(Vector2i.ZERO, MAP_SIZE)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			if _is_wall(cell):
				astar.set_point_solid(cell)
	astar.set_point_solid(BLOCKED_STAIRS_CELL)


func _is_wall(cell: Vector2i) -> bool:
	return cell.x == 0 or cell.y == 0 or cell.x == MAP_SIZE.x - 1 or cell.y == MAP_SIZE.y - 1


func _set_destination(clicked_world_position: Vector2) -> void:
	var target_cell := _world_to_cell(clicked_world_position)
	if target_cell == EXIT_DOOR_CELL or _is_exit_door_click(clicked_world_position):
		target_cell = EXIT_INTERACTION_CELL
	if not astar.is_in_boundsv(target_cell):
		_update_status("Destino fora da sala.")
		return
	if target_cell == BLOCKED_STAIRS_CELL:
		_update_status("A escada está bloqueada nesta versão.")
		return
	if astar.is_point_solid(target_cell):
		_update_status("A parede bloqueia esse caminho.")
		return

	var start_cell := _nearest_walkable_cell(player_anchor.position)
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
	_update_status("Caminhando pela sala inicial.")


func _is_exit_door_click(world_position: Vector2) -> bool:
	var door_position := _cell_to_world(EXIT_DOOR_CELL)
	return Rect2(door_position + Vector2(-24.0, -40.0), Vector2(48.0, 44.0)).has_point(world_position)


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


func _update_hud() -> void:
	var ratio := float(player_hp) / float(PLAYER_MAX_HP)
	health_fill.size.x = 240.0 * clampf(ratio, 0.0, 1.0)
	health_label.text = "VIDA  %d / %d" % [player_hp, PLAYER_MAX_HP]
	if current_weapon == Weapon.RIFLE:
		weapon_label.text = "RIFLE  •  BALAS %d  •  SEM INIMIGOS" % rifle_ammo
	else:
		weapon_label.text = "PEIXEIRA  •  SEM INIMIGOS"


func _draw() -> void:
	draw_rect(_map_bounds().grow(256.0), COLOR_VOID, true)
	_draw_tiles()
	_draw_exit_door()
	_draw_blocked_stairs()
	_draw_route_preview()
	_draw_destination()
	_draw_player()


func _draw_tiles() -> void:
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)
			var color: Color
			if _is_wall(cell):
				color = COLOR_WALL_A if (x + y) % 2 == 0 else COLOR_WALL_B
			else:
				color = COLOR_FLOOR_A if (x + y) % 2 == 0 else COLOR_FLOOR_B
			_draw_diamond(center, color)
			if _is_wall(cell):
				draw_line(center + Vector2(-18.0, 0.0), center + Vector2(0.0, 9.0), COLOR_WALL_EDGE, 2.0)


func _draw_diamond(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -HALF_TILE.y),
		center + Vector2(HALF_TILE.x, 0.0),
		center + Vector2(0.0, HALF_TILE.y),
		center + Vector2(-HALF_TILE.x, 0.0),
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), COLOR_TILE_LINE, 1.0)


func _draw_exit_door() -> void:
	var position := _cell_to_world(EXIT_DOOR_CELL)
	draw_rect(Rect2(position + Vector2(-18.0, -34.0), Vector2(36.0, 35.0)), COLOR_DOOR_FRAME, true)
	draw_rect(Rect2(position + Vector2(-13.0, -27.0), Vector2(26.0, 28.0)), COLOR_DOOR, true)
	draw_circle(position + Vector2(7.0, -13.0), 2.0, COLOR_STAIRS_EDGE)


func _draw_blocked_stairs() -> void:
	var position := _cell_to_world(BLOCKED_STAIRS_CELL)
	for step in range(4):
		var width := 30.0 - float(step) * 5.0
		var top := float(step) * 5.0 - 14.0
		draw_rect(Rect2(position + Vector2(-width * 0.5, top), Vector2(width, 4.0)), COLOR_STAIRS, true)
		draw_line(position + Vector2(-width * 0.5, top), position + Vector2(width * 0.5, top), COLOR_STAIRS_EDGE, 1.0)
	draw_arc(position + Vector2(0.0, -3.0), 13.0, 0.0, TAU, 24, COLOR_SEAL, 2.0)
	draw_line(position + Vector2(-9.0, -12.0), position + Vector2(9.0, 6.0), COLOR_SEAL, 2.0)


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


func _character_draw_rect(position: Vector2) -> Rect2:
	return Rect2(position - CHARACTER_FOOT_ANCHOR, CHARACTER_FRAME_SIZE)


func _character_sprite_region(row: int, animation_state: int, animation_frame: int) -> Rect2:
	var first_column := WALK_FIRST_COLUMN if animation_state == ANIMATION_WALK else IDLE_FIRST_COLUMN
	var frame_count := WALK_FRAME_COUNT if animation_state == ANIMATION_WALK else IDLE_FRAME_COUNT
	var normalized_frame := posmod(animation_frame, frame_count)
	return Rect2(
		float(first_column + normalized_frame) * CHARACTER_FRAME_SIZE.x,
		float(row) * CHARACTER_FRAME_SIZE.y,
		CHARACTER_FRAME_SIZE.x,
		CHARACTER_FRAME_SIZE.y
	)


func _draw_player() -> void:
	var position := player_anchor.position
	draw_circle(position + Vector2(0.0, 7.0), 9.0, Color(0.08, 0.05, 0.03, 0.35))
	draw_texture_rect_region(
		CHARACTER_ATLAS,
		_character_draw_rect(position),
		_character_sprite_region(PLAYER_ATLAS_ROW, player_animation_state, player_animation_frame)
	)
