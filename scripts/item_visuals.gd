class_name ItemVisuals
extends RefCounted

const COLOR_OUTLINE := Color("24170f")
const COLOR_METAL_DARK := Color("6a5542")
const COLOR_METAL := Color("b18a5f")
const COLOR_METAL_LIGHT := Color("e0bd80")
const COLOR_GOLD_DARK := Color("a86520")
const COLOR_GOLD := Color("e6ad37")
const COLOR_GOLD_LIGHT := Color("ffe08a")
const COLOR_GLASS := Color("d7e4dc")
const COLOR_POTION_DARK := Color("7f251f")
const COLOR_POTION := Color("d44838")
const COLOR_POTION_LIGHT := Color("ff7660")


static func draw_item(target: CanvasItem, rect: Rect2, item_id: String) -> void:
	match item_id:
		"coin": _draw_coin(target, rect)
		"health_potion": _draw_potion(target, rect)
		"armor_head": _draw_head(target, rect)
		"armor_chest": _draw_chest(target, rect)
		"armor_legs": _draw_legs(target, rect)
		"armor_feet": _draw_feet(target, rect)
		_: _draw_unknown(target, rect)


static func _pixel_rect(rect: Rect2, x: float, y: float, width: float, height: float) -> Rect2:
	return Rect2(
		rect.position + Vector2(rect.size.x * x, rect.size.y * y),
		Vector2(rect.size.x * width, rect.size.y * height)
	)


static func _draw_coin(target: CanvasItem, rect: Rect2) -> void:
	target.draw_rect(_pixel_rect(rect, 0.24, 0.18, 0.52, 0.64), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.18, 0.28, 0.64, 0.44), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.28, 0.22, 0.44, 0.56), COLOR_GOLD, true)
	target.draw_rect(_pixel_rect(rect, 0.22, 0.32, 0.56, 0.36), COLOR_GOLD, true)
	target.draw_rect(_pixel_rect(rect, 0.34, 0.27, 0.12, 0.12), COLOR_GOLD_LIGHT, true)
	target.draw_rect(_pixel_rect(rect, 0.54, 0.42, 0.10, 0.28), COLOR_GOLD_DARK, true)


static func _draw_potion(target: CanvasItem, rect: Rect2) -> void:
	target.draw_rect(_pixel_rect(rect, 0.38, 0.10, 0.24, 0.17), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.42, 0.08, 0.16, 0.15), COLOR_METAL_LIGHT, true)
	target.draw_rect(_pixel_rect(rect, 0.28, 0.24, 0.44, 0.62), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.22, 0.35, 0.56, 0.40), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.32, 0.29, 0.36, 0.51), COLOR_GLASS, true)
	target.draw_rect(_pixel_rect(rect, 0.27, 0.40, 0.46, 0.30), COLOR_POTION, true)
	target.draw_rect(_pixel_rect(rect, 0.34, 0.43, 0.12, 0.12), COLOR_POTION_LIGHT, true)
	target.draw_rect(_pixel_rect(rect, 0.58, 0.48, 0.10, 0.20), COLOR_POTION_DARK, true)


static func _draw_head(target: CanvasItem, rect: Rect2) -> void:
	target.draw_rect(_pixel_rect(rect, 0.18, 0.24, 0.64, 0.18), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.26, 0.14, 0.48, 0.54), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.32, 0.20, 0.36, 0.42), COLOR_METAL, true)
	target.draw_rect(_pixel_rect(rect, 0.20, 0.30, 0.60, 0.10), COLOR_METAL_LIGHT, true)
	target.draw_rect(_pixel_rect(rect, 0.32, 0.57, 0.12, 0.20), COLOR_METAL_DARK, true)
	target.draw_rect(_pixel_rect(rect, 0.56, 0.57, 0.12, 0.20), COLOR_METAL_DARK, true)


static func _draw_chest(target: CanvasItem, rect: Rect2) -> void:
	target.draw_rect(_pixel_rect(rect, 0.18, 0.20, 0.24, 0.22), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.58, 0.20, 0.24, 0.22), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.26, 0.24, 0.48, 0.60), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.30, 0.28, 0.40, 0.50), COLOR_METAL, true)
	target.draw_rect(_pixel_rect(rect, 0.22, 0.24, 0.18, 0.14), COLOR_METAL_LIGHT, true)
	target.draw_rect(_pixel_rect(rect, 0.60, 0.24, 0.18, 0.14), COLOR_METAL_LIGHT, true)
	target.draw_rect(_pixel_rect(rect, 0.46, 0.31, 0.08, 0.42), COLOR_METAL_DARK, true)


static func _draw_legs(target: CanvasItem, rect: Rect2) -> void:
	target.draw_rect(_pixel_rect(rect, 0.20, 0.14, 0.60, 0.20), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.22, 0.30, 0.26, 0.56), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.52, 0.30, 0.26, 0.56), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.25, 0.19, 0.50, 0.11), COLOR_METAL_LIGHT, true)
	target.draw_rect(_pixel_rect(rect, 0.27, 0.34, 0.16, 0.46), COLOR_METAL, true)
	target.draw_rect(_pixel_rect(rect, 0.57, 0.34, 0.16, 0.46), COLOR_METAL, true)


static func _draw_feet(target: CanvasItem, rect: Rect2) -> void:
	target.draw_rect(_pixel_rect(rect, 0.16, 0.40, 0.32, 0.42), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.52, 0.40, 0.32, 0.42), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.21, 0.44, 0.22, 0.30), COLOR_METAL, true)
	target.draw_rect(_pixel_rect(rect, 0.57, 0.44, 0.22, 0.30), COLOR_METAL, true)
	target.draw_rect(_pixel_rect(rect, 0.13, 0.70, 0.34, 0.12), COLOR_METAL_LIGHT, true)
	target.draw_rect(_pixel_rect(rect, 0.53, 0.70, 0.34, 0.12), COLOR_METAL_LIGHT, true)


static func _draw_unknown(target: CanvasItem, rect: Rect2) -> void:
	target.draw_rect(_pixel_rect(rect, 0.22, 0.22, 0.56, 0.56), COLOR_OUTLINE, true)
	target.draw_rect(_pixel_rect(rect, 0.29, 0.29, 0.42, 0.42), COLOR_METAL_DARK, true)

