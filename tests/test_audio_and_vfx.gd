extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_audio_manager()
	await _test_screenshake()
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
	var step_player = audio_mgr.call("play_sfx", "step")
	_expect(step_player != null, "play_sfx('step') deve retornar um player ativo.")

	var parry_player = audio_mgr.call("play_sfx", "parry")
	_expect(parry_player != null, "play_sfx('parry') deve retornar um player ativo.")

	var hit_player = audio_mgr.call("play_sfx", "hit")
	_expect(hit_player != null, "play_sfx('hit') deve retornar um player ativo.")

	var file_specs := [
		["play_shoot", [0.0], "res://assets/art/audio/rifle_tiro.wav", 0.0],
		["play_lapada_seca", [], "res://assets/art/audio/lapada_seca.wav", -2.0],
		["play_reload_complete", [], "res://assets/art/audio/recarregar.wav", -1.0],
		["play_enemy_death", [], "res://assets/art/audio/corpo_caindo_morte.wav", -3.0],
		["play_health_potion", [], "res://assets/art/audio/bebendo_pocao.wav", -2.0],
		["play_critical", [], "res://assets/art/audio/critical_hit.wav", -3.0],
		["play_peixeira_draw", [], "res://assets/art/audio/peixeira_draw.wav", -5.0],
		["play_peixeira_hit", [], "res://assets/art/audio/peixeira_hit.wav", -1.0],
		["play_equip_rifle", [], "res://assets/art/audio/equipando_rifle.wav", 0.0],
		["play_equip_armor", [], "res://assets/art/audio/equipando_armadura.wav", 0.0],
		["play_dungeon_open", [], "res://assets/art/audio/abrindo_masmorra.wav", 0.0],
		["play_shop_open", [], "res://assets/art/audio/abrir_loja.wav", 0.0],
		["play_dungeon_player_death", [], "res://assets/art/audio/morte_jogador_masmorra.wav", 0.0],
		["play_coin_popup", [], "res://assets/art/audio/moeda_popup.wav", 0.0],
		["play_dungeon_boss_victory", [], "res://assets/art/audio/vitoria_boss_masmorra.wav", 0.0],
	]
	for spec in file_specs:
		var file_player := audio_mgr.callv(str(spec[0]), spec[1]) as AudioStreamPlayer
		_expect(file_player != null, "%s deve retornar um player ativo." % spec[0])
		if file_player == null:
			continue
		_expect(file_player.stream.resource_path == spec[2], "%s deve usar o WAV integrado." % spec[0])
		_expect(is_equal_approx(file_player.volume_db, float(spec[3])), "%s deve usar o volume definido." % spec[0])
		if spec[0] == "play_reload_complete":
			_expect(absf(file_player.stream.get_length() - 1.326) < 0.002, "O SFX aprovado de recarga deve durar aproximadamente 1,326 s.")
			_expect(file_player.stream.get_length() <= 1.5, "O SFX de recarga deve permanecer dentro dos 1,5 s.")
		elif spec[0] == "play_peixeira_draw":
			_expect(absf(file_player.stream.get_length() - 0.632) < 0.002, "O saque revisado da Peixeira deve durar aproximadamente 0,632 s.")
		file_player.stop()
		file_player.stream = null
	_expect(audio_mgr.call("play_sfx", "shoot") == null, "O disparo antigo não deve voltar ao procedural.")
	_expect(audio_mgr.call("play_sfx", "knife") == null, "O golpe antigo da Peixeira não deve voltar ao procedural.")
	_expect(audio_mgr.call("play_sfx", "critical") == null, "O crítico antigo não deve voltar ao procedural.")
	_expect(audio_mgr.call("play_sfx", "sfx_inexistente") == null, "SFX ausente deve falhar sem interromper o jogo.")

	for player_value in [step_player, parry_player, hit_player]:
		var player := player_value as AudioStreamPlayer
		if player != null:
			player.stop()
			player.stream = null
	await process_frame
	await create_timer(0.75).timeout
	audio_mgr.queue_free()
	await process_frame
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
