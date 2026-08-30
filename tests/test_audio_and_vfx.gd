extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_audio_manager()
	_test_screenshake()
	_test_shaders_and_vfx()
	_test_woodcut_theme()
	_finish()


func _test_audio_manager() -> void:
	var audio_mgr_script := load("res://scripts/audio_manager.gd") as GDScript
	_expect(audio_mgr_script != null, "O script do AudioManager deve carregar.")
	if audio_mgr_script == null:
		return

	var audio_mgr: Node = audio_mgr_script.new()
	root.add_child(audio_mgr)
	await process_frame

	_expect(AudioServer.get_bus_index("Master") != -1, "O barramento Master deve existir.")
	_expect(AudioServer.get_bus_index("BGM") != -1, "O barramento BGM deve existir.")
	_expect(AudioServer.get_bus_index("SFX") != -1, "O barramento SFX deve existir.")

	audio_mgr.call("set_master_volume", 0.8)
	_expect(is_equal_approx(float(audio_mgr.call("get_master_volume")), 0.8), "O volume Master deve ser ajustável.")
	audio_mgr.call("set_sfx_volume", 0.65)
	_expect(is_equal_approx(float(audio_mgr.call("get_sfx_volume")), 0.65), "O volume SFX deve ser ajustável.")

	# Teste dos metodos semanticos de audio
	var shoot_player = audio_mgr.call("play_sfx", "shoot")
	_expect(shoot_player != null, "play_sfx('shoot') deve retornar um player ativo.")

	var knife_player = audio_mgr.call("play_sfx", "knife")
	_expect(knife_player != null, "play_sfx('knife') deve retornar um player ativo.")

	var step_player = audio_mgr.call("play_sfx", "step")
	_expect(step_player != null, "play_sfx('step') deve retornar um player ativo.")

	var parry_player = audio_mgr.call("play_sfx", "parry")
	_expect(parry_player != null, "play_sfx('parry') deve retornar um player ativo.")

	var hit_player = audio_mgr.call("play_sfx", "hit")
	_expect(hit_player != null, "play_sfx('hit') deve retornar um player ativo.")

	var crit_player = audio_mgr.call("play_sfx", "critical")
	_expect(crit_player != null, "play_sfx('critical') deve retornar um player ativo.")

	audio_mgr.queue_free()
	await process_frame


func _test_screenshake() -> void:
	var camera := Camera2D.new()
	root.add_child(camera)

	var screenshake_script := load("res://scripts/screen_shake.gd") as GDScript
	_expect(screenshake_script != null, "O script de ScreenShake deve carregar.")
	if screenshake_script == null:
		camera.queue_free()
		return

	var screenshake: Node = screenshake_script.new()
	camera.add_child(screenshake)
	await process_frame

	screenshake.call("add_trauma", 0.8)
	_expect(is_equal_approx(float(screenshake.get("trauma")), 0.8), "add_trauma deve acumular trauma no componente.")

	# Processa decaimento
	screenshake.call("_process", 0.2)
	_expect(float(screenshake.get("trauma")) < 0.8, "O trauma deve decair ao longo do tempo.")

	# Processa ate zerar
	screenshake.call("_process", 2.0)
	_expect(is_zero_approx(float(screenshake.get("trauma"))), "O trauma deve zerar apos o periodo de decaimento.")
	_expect(camera.offset == Vector2.ZERO, "A camera deve retornar ao offset (0, 0) com trauma zerado.")

	camera.queue_free()
	await process_frame


func _test_shaders_and_vfx() -> void:
	var shader := load("res://shaders/hit_flash.gdshader") as Shader
	_expect(shader != null, "O shader hit_flash.gdshader deve carregar com sucesso.")

	var dust_scene := load("res://scenes/vfx/dust_particles.tscn") as PackedScene
	_expect(dust_scene != null, "A cena de partículas de poeira deve carregar.")
	if dust_scene != null:
		var dust := dust_scene.instantiate()
		_expect(dust is CPUParticles2D, "DustParticles deve ser do tipo CPUParticles2D.")
		dust.queue_free()

	var muzzle_scene := load("res://scenes/vfx/rifle_muzzle_flash.tscn") as PackedScene
	_expect(muzzle_scene != null, "A cena de fumaça e faíscas do rifle deve carregar.")
	if muzzle_scene != null:
		var muzzle := muzzle_scene.instantiate()
		_expect(muzzle.has_node("Sparks"), "RifleMuzzleFlash deve conter o nó Sparks.")
		_expect(muzzle.has_node("Smoke"), "RifleMuzzleFlash deve conter o nó Smoke.")
		muzzle.queue_free()


func _test_woodcut_theme() -> void:
	var theme := load("res://assets/ui/woodcut_theme.tres") as Theme
	_expect(theme != null, "O tema de xilogravura deve carregar com sucesso.")
	if theme != null:
		var font_color: Color = theme.get_color("font_color", "Button")
		_expect(font_color == Color(0.949, 0.875, 0.741, 1), "A cor de fonte do tema deve ser creme de alto contraste.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("TESTE_AUDIO_E_VFX_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
