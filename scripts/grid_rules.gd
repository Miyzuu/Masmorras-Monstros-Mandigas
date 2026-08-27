class_name GridRules
extends RefCounted

const FOUR_DIRECTIONS = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]


static func is_inside(cell: Vector2i, board_size: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.y >= 0
		and cell.x < board_size.x
		and cell.y < board_size.y
	)


static func reachable_distances(
	start: Vector2i,
	max_distance: int,
	board_size: Vector2i,
	blocked: Dictionary
) -> Dictionary:
	var distances: Dictionary = {start: 0}
	var pending: Array[Vector2i] = [start]
	var cursor := 0

	while cursor < pending.size():
		var current := pending[cursor]
		cursor += 1
		var current_distance := int(distances[current])

		if current_distance >= max_distance:
			continue

		for direction in FOUR_DIRECTIONS:
			var next_cell: Vector2i = current + direction
			if not is_inside(next_cell, board_size):
				continue
			if blocked.has(next_cell) or distances.has(next_cell):
				continue

			distances[next_cell] = current_distance + 1
			pending.append(next_cell)

	return distances


static func shortest_path(
	start: Vector2i,
	target: Vector2i,
	max_distance: int,
	board_size: Vector2i,
	blocked: Dictionary
) -> Array[Vector2i]:
	if start == target:
		return [start]

	var distances: Dictionary = {start: 0}
	var came_from: Dictionary = {start: start}
	var pending: Array[Vector2i] = [start]
	var cursor := 0

	while cursor < pending.size():
		var current := pending[cursor]
		cursor += 1
		var current_distance := int(distances[current])

		if current_distance >= max_distance:
			continue

		for direction in FOUR_DIRECTIONS:
			var next_cell: Vector2i = current + direction
			if not is_inside(next_cell, board_size):
				continue
			if blocked.has(next_cell) or distances.has(next_cell):
				continue

			distances[next_cell] = current_distance + 1
			came_from[next_cell] = current
			pending.append(next_cell)

			if next_cell == target:
				return _reconstruct_path(start, target, came_from)

	return []


static func _reconstruct_path(
	start: Vector2i,
	target: Vector2i,
	came_from: Dictionary
) -> Array[Vector2i]:
	var path: Array[Vector2i] = [target]
	var current := target

	while current != start:
		current = came_from[current]
		path.push_front(current)

	return path
