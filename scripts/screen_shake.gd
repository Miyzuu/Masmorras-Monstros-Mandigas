class_name ScreenShake
extends Node

## Componente modular de Screenshake baseado no modelo de Trauma.
## Pode ser adicionado diretamente como filho de uma Camera2D.
## Modifica exclusivamente Camera2D.offset para nao interferir no seguimento suave da camera.

@export var max_offset := Vector2(8.0, 6.0)
@export var max_roll := 0.015
@export var decay_rate := 2.5
@export var trauma_power := 2.0

var trauma := 0.0
var camera: Camera2D


func _ready() -> void:
	add_to_group("screenshake")
	if get_parent() is Camera2D:
		camera = get_parent() as Camera2D


func _process(delta: float) -> void:
	if trauma <= 0.0:
		if camera != null and camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO
			camera.rotation = 0.0
		return

	trauma = maxf(0.0, trauma - decay_rate * delta)
	_apply_shake()


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)
	_apply_shake()


func _apply_shake() -> void:
	if camera == null:
		return

	var shake := pow(trauma, trauma_power)
	var offset_x := randf_range(-1.0, 1.0) * max_offset.x * shake
	var offset_y := randf_range(-1.0, 1.0) * max_offset.y * shake
	camera.offset = Vector2(offset_x, offset_y)
	if max_roll > 0.0:
		camera.rotation = randf_range(-1.0, 1.0) * max_roll * shake


## Metodo estatico para acionar screenshake em qualquer arvore de cena
static func shake_camera(tree: SceneTree, amount: float) -> void:
	if tree == null:
		return
	var nodes := tree.get_nodes_in_group("screenshake")
	for node in nodes:
		if node is ScreenShake:
			(node as ScreenShake).add_trauma(amount)
