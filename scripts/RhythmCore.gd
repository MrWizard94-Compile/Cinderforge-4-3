extends Node
## Beat clock, Heat, stem layering. Autoload-friendly; used by Arena.
class_name RhythmCore

signal heat_changed(value: float)
signal attack_resolved(on_beat: bool, offset_ms: float, damage_mult: float)

@export var stem_dir: String = "res://audio/weaponized_mind"
@export var stem_files: PackedStringArray = [
	"2 Drums.wav",
	"3 Bass.wav",
	"4 Guitar.wav",
	"6 Synth.wav",
	"5 Keyboard.wav",
	"1 Backing Vocals.wav",
	"0 Lead Vocals.wav",
]
@export var bpm: float = 120.0
@export var beat_window_ms: float = 90.0
@export var heat_per_hit: float = 12.0
@export var heat_decay_per_sec: float = 8.0
@export var on_beat_damage_mult: float = 1.6
@export var off_beat_damage_mult: float = 1.0

var players: Array[AudioStreamPlayer] = []
var clock_player: AudioStreamPlayer = null
var heat: float = 0.0
var taps: Array[float] = []
var started: bool = false

func start_music() -> void:
	if started:
		return
	_load_stems()
	for p in players:
		p.play()
	if players.size() > 0:
		clock_player = players[0]
	started = true

func _load_stems() -> void:
	for i in stem_files.size():
		var path := stem_dir + "/" + stem_files[i]
		var stream = load(path)
		if stream == null:
			push_warning("CINDERFORGE: missing stem " + path)
			continue
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.bus = "Master"
		p.volume_db = -80.0
		add_child(p)
		players.append(p)
	if players.size() > 0:
		players[0].volume_db = 0.0

func song_position_sec() -> float:
	if clock_player == null or not clock_player.playing:
		return 0.0
	var t := clock_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	t -= AudioServer.get_output_latency()
	return maxf(t, 0.0)

func nearest_beat_offset_ms() -> float:
	if bpm <= 0.0:
		return 9999.0
	var beat_len := 60.0 / bpm
	var phase := fmod(song_position_sec(), beat_len)
	return minf(phase, beat_len - phase) * 1000.0

func beat_index() -> int:
	if bpm <= 0.0:
		return 0
	var beat_len := 60.0 / bpm
	return int(floor(song_position_sec() / beat_len))

func is_on_beat() -> bool:
	return nearest_beat_offset_ms() <= beat_window_ms

func _process(delta: float) -> void:
	if not started:
		return
	var prev := heat
	heat = clampf(heat - heat_decay_per_sec * delta, 0.0, 100.0)
	if heat != prev:
		heat_changed.emit(heat)
	_apply_heat_layers()

func _apply_heat_layers() -> void:
	var tiers := maxi(players.size(), 1)
	for i in players.size():
		if i == 0:
			continue
		var unlock_at := float(i) / float(tiers) * 100.0
		var target := 0.0 if heat >= unlock_at else -80.0
		players[i].volume_db = lerpf(players[i].volume_db, target, 0.12)

## Call from player attack. Returns damage multiplier.
func resolve_attack() -> Dictionary:
	var off := nearest_beat_offset_ms()
	var on := off <= beat_window_ms
	var mult := on_beat_damage_mult if on else off_beat_damage_mult
	if on:
		heat = clampf(heat + heat_per_hit, 0.0, 100.0)
	else:
		heat = clampf(heat - heat_per_hit * 0.35, 0.0, 100.0)
	heat_changed.emit(heat)
	attack_resolved.emit(on, off, mult)
	return {"on_beat": on, "offset_ms": off, "mult": mult, "heat": heat}

func tap_tempo() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	taps.append(now)
	while taps.size() > 8:
		taps.pop_front()
	if taps.size() >= 2:
		var total := 0.0
		for i in range(1, taps.size()):
			total += taps[i] - taps[i - 1]
		var avg := total / float(taps.size() - 1)
		if avg > 0.0:
			bpm = clampf(60.0 / avg, 40.0, 300.0)

## Clean exit — stop, release the stream ref, and free each stem player
## synchronously so a headless quit (or scene teardown) leaks no audio.
## Deferred queue_free() is intentionally NOT used: at --quit-after the engine
## exits before the deferred queue is flushed, leaving the AudioStreamWAV +
## AudioStreamPlaybackWAV "still in use". stop() ends the playback, stream = null
## drops the player's ref to the WAV, and free() removes the node immediately.
func shutdown() -> void:
	print("CF_DIAG shutdown fired players=", players.size())
	for p in players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
			p.free()
	players.clear()
	clock_player = null
	started = false

func _exit_tree() -> void:
	print("CF_DIAG _exit_tree fired")
	shutdown()
