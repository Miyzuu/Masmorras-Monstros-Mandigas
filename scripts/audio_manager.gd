extends Node

## Autoload de Gerenciamento de Audio com barramentos Master, BGM e SFX.
## Inclui sintese de som procedural (AudioStreamWAV) para funcionamento imediato
## e suporte transparente a arquivos de audio em assets/art/audio/.

const BUS_MASTER := "Master"
const BUS_BGM := "BGM"
const BUS_SFX := "SFX"
const SFX_POOL_SIZE := 10
const SAMPLE_RATE := 22050
const LAPADA_SECA_VOLUME_DB := -2.0
const RIFLE_SHOT_VOLUME_DB := 0.0
const RELOAD_VOLUME_DB := -1.0
const ENEMY_DEATH_VOLUME_DB := -3.0
const HEALTH_POTION_VOLUME_DB := -2.0
const CRITICAL_HIT_VOLUME_DB := -3.0
const PEIXEIRA_DRAW_VOLUME_DB := -5.0
const PEIXEIRA_HIT_VOLUME_DB := -1.0
const FILE_SFX_PATHS := {
	"lapada_seca": "res://assets/art/audio/lapada_seca.wav",
	"rifle_tiro": "res://assets/art/audio/rifle_tiro.wav",
	"recarregar": "res://assets/art/audio/recarregar.wav",
	"corpo_caindo_morte": "res://assets/art/audio/corpo_caindo_morte.wav",
	"bebendo_pocao": "res://assets/art/audio/bebendo_pocao.wav",
	"critical_hit": "res://assets/art/audio/critical_hit.wav",
	"peixeira_draw": "res://assets/art/audio/peixeira_draw.wav",
	"peixeira_hit": "res://assets/art/audio/peixeira_hit.wav",
	"equipando_rifle": "res://assets/art/audio/equipando_rifle.wav",
	"equipando_armadura": "res://assets/art/audio/equipando_armadura.wav",
	"abrindo_masmorra": "res://assets/art/audio/abrindo_masmorra.wav",
	"abrir_loja": "res://assets/art/audio/abrir_loja.wav",
	"morte_jogador_masmorra": "res://assets/art/audio/morte_jogador_masmorra.wav",
	"moeda_popup": "res://assets/art/audio/moeda_popup.wav",
	"vitoria_boss_masmorra": "res://assets/art/audio/vitoria_boss_masmorra.wav",
}

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _bgm_player: AudioStreamPlayer
var _synth_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_setup_audio_players()
	_pregenerate_procedural_sfx()


func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index(BUS_BGM) == -1:
		var bgm_idx := AudioServer.bus_count
		AudioServer.add_bus(bgm_idx)
		AudioServer.set_bus_name(bgm_idx, BUS_BGM)
		AudioServer.set_bus_send(bgm_idx, BUS_MASTER)

	if AudioServer.get_bus_index(BUS_SFX) == -1:
		var sfx_idx := AudioServer.bus_count
		AudioServer.add_bus(sfx_idx)
		AudioServer.set_bus_name(sfx_idx, BUS_SFX)
		AudioServer.set_bus_send(sfx_idx, BUS_MASTER)


func _setup_audio_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = BUS_BGM
	add_child(_bgm_player)

	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)


func _pregenerate_procedural_sfx() -> void:
	_synth_cache["step"] = _generate_step_sfx()
	_synth_cache["parry"] = _generate_parry_sfx()
	_synth_cache["hit"] = _generate_hit_sfx()
	_synth_cache["ui_click"] = _generate_ui_click_sfx()
	_synth_cache["ui_hover"] = _generate_ui_hover_sfx()
	_synth_cache["door"] = _generate_door_sfx()


## Toca efeito sonoro por nome ou recurso de AudioStream
func play_sfx(sound: Variant, pitch_scale: float = 1.0, volume_db: float = 0.0) -> AudioStreamPlayer:
	var stream: AudioStream = null
	var resolved_volume_db := volume_db

	if sound is AudioStream:
		stream = sound as AudioStream
	elif sound is String:
		var sound_name := (sound as String).to_lower()
		if sound_name == "lapada_seca" and is_zero_approx(volume_db):
			resolved_volume_db = LAPADA_SECA_VOLUME_DB
		stream = _resolve_named_sfx(sound_name)

	if stream == null:
		return null

	var player := _get_available_sfx_player()
	player.stream = stream
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.volume_db = resolved_volume_db
	player.play()
	return player


func _resolve_named_sfx(sound_name: String) -> AudioStream:
	if FILE_SFX_PATHS.has(sound_name):
		var asset_path := str(FILE_SFX_PATHS[sound_name])
		if ResourceLoader.exists(asset_path):
			var asset_stream := load(asset_path) as AudioStream
			if asset_stream != null:
				return asset_stream
	if _synth_cache.has(sound_name):
		return _synth_cache[sound_name] as AudioStream
	var legacy_path := "res://assets/audio/%s.wav" % sound_name
	if ResourceLoader.exists(legacy_path):
		return load(legacy_path) as AudioStream
	return null


## Metodos semanticos para os sons principais do jogo

func play_shoot(pitch_random: float = 0.06) -> AudioStreamPlayer:
	var pitch := randf_range(1.0 - pitch_random, 1.0 + pitch_random)
	return play_sfx("rifle_tiro", pitch, RIFLE_SHOT_VOLUME_DB)


func play_peixeira_draw() -> AudioStreamPlayer:
	return play_sfx("peixeira_draw", 1.0, PEIXEIRA_DRAW_VOLUME_DB)


func play_peixeira_hit() -> AudioStreamPlayer:
	return play_sfx("peixeira_hit", 1.0, PEIXEIRA_HIT_VOLUME_DB)


func play_step(pitch_random: float = 0.12) -> void:
	var pitch := randf_range(1.0 - pitch_random, 1.0 + pitch_random)
	play_sfx("step", pitch, -8.0)


func play_parry() -> void:
	play_sfx("parry", 1.0, 2.0)


func play_hit(pitch_random: float = 0.08) -> void:
	var pitch := randf_range(1.0 - pitch_random, 1.0 + pitch_random)
	play_sfx("hit", pitch, 0.0)


func play_critical() -> AudioStreamPlayer:
	return play_sfx("critical_hit", 1.0, CRITICAL_HIT_VOLUME_DB)


func play_lapada_seca() -> AudioStreamPlayer:
	return play_sfx("lapada_seca", 1.0, LAPADA_SECA_VOLUME_DB)


func play_reload_complete() -> AudioStreamPlayer:
	return play_sfx("recarregar", 1.0, RELOAD_VOLUME_DB)


func play_enemy_death() -> AudioStreamPlayer:
	return play_sfx("corpo_caindo_morte", 1.0, ENEMY_DEATH_VOLUME_DB)


func play_health_potion() -> AudioStreamPlayer:
	return play_sfx("bebendo_pocao", 1.0, HEALTH_POTION_VOLUME_DB)


func play_equip_rifle() -> AudioStreamPlayer:
	return play_sfx("equipando_rifle")


func play_equip_armor() -> AudioStreamPlayer:
	return play_sfx("equipando_armadura")


func play_dungeon_open() -> AudioStreamPlayer:
	return play_sfx("abrindo_masmorra")


func play_shop_open() -> AudioStreamPlayer:
	return play_sfx("abrir_loja")


func play_dungeon_player_death() -> AudioStreamPlayer:
	return play_sfx("morte_jogador_masmorra")


func play_coin_popup() -> AudioStreamPlayer:
	return play_sfx("moeda_popup")


func play_dungeon_boss_victory() -> AudioStreamPlayer:
	return play_sfx("vitoria_boss_masmorra")


func play_ui_click() -> void:
	play_sfx("ui_click", 1.0, -2.0)


func play_ui_hover() -> void:
	play_sfx("ui_hover", 1.0, -8.0)


func play_door_open() -> void:
	play_sfx("door", 1.0, 0.0)


## Controle de volume

func set_master_volume(linear: float) -> void:
	_set_bus_volume_linear(BUS_MASTER, linear)


func set_bgm_volume(linear: float) -> void:
	_set_bus_volume_linear(BUS_BGM, linear)


func set_sfx_volume(linear: float) -> void:
	_set_bus_volume_linear(BUS_SFX, linear)


func get_master_volume() -> float:
	return _get_bus_volume_linear(BUS_MASTER)


func get_bgm_volume() -> float:
	return _get_bus_volume_linear(BUS_BGM)


func get_sfx_volume() -> float:
	return _get_bus_volume_linear(BUS_SFX)


func _set_bus_volume_linear(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))


func _get_bus_volume_linear(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(idx))
	return 1.0


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player

	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	return player


# ------------------------------------------------------------------------------
# Sintese procedural de audio (PCM 16-bit)
# ------------------------------------------------------------------------------

func _create_pcm_stream(samples: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream


func _generate_step_sfx() -> AudioStreamWAV:
	var duration := 0.08
	var total_samples := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := exp(-progress * 22.0)
		var thump := sin(2.0 * PI * 90.0 * (1.0 - progress * 0.7) * t)
		var grit := randf_range(-0.3, 0.3)
		var sample_val := (thump * 0.8 + grit * 0.2) * env
		var sample_16 := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_16)

	return _create_pcm_stream(bytes)
func _generate_parry_sfx() -> AudioStreamWAV:
	var duration := 0.42
	var total_samples := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := exp(-progress * 7.0)
		var chime1 := sin(2.0 * PI * 1760.0 * t)
		var chime2 := sin(2.0 * PI * 2640.0 * t)
		var chime3 := sin(2.0 * PI * 3520.0 * t)
		var sample_val := (chime1 * 0.5 + chime2 * 0.3 + chime3 * 0.2) * env
		var sample_16 := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_16)

	return _create_pcm_stream(bytes)


func _generate_hit_sfx() -> AudioStreamWAV:
	var duration := 0.14
	var total_samples := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := exp(-progress * 16.0)
		var punch := sin(2.0 * PI * 110.0 * (1.0 - progress * 0.8) * t)
		var crunch := randf_range(-0.4, 0.4)
		var sample_val := (punch * 0.7 + crunch * 0.3) * env
		var sample_16 := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_16)

	return _create_pcm_stream(bytes)


func _generate_ui_click_sfx() -> AudioStreamWAV:
	var duration := 0.05
	var total_samples := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := exp(-progress * 30.0)
		var click := sin(2.0 * PI * 600.0 * (1.0 - progress) * t)
		var sample_val := click * env
		var sample_16 := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_16)

	return _create_pcm_stream(bytes)


func _generate_ui_hover_sfx() -> AudioStreamWAV:
	var duration := 0.03
	var total_samples := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := exp(-progress * 40.0)
		var tap := sin(2.0 * PI * 950.0 * t)
		var sample_val := tap * env * 0.5
		var sample_16 := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_16)

	return _create_pcm_stream(bytes)


func _generate_door_sfx() -> AudioStreamWAV:
	var duration := 0.35
	var total_samples := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := exp(-progress * 8.0)
		var creak := sin(2.0 * PI * (180.0 + sin(t * 40.0) * 50.0) * t)
		var sample_val := creak * env * 0.6
		var sample_16 := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_16)

	return _create_pcm_stream(bytes)
