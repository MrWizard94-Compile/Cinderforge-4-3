extends Node2D
## CINDERFORGE — rhythm-core prototype ("does it feel good?" gate).
##
## Loads a track's stems, plays them in lockstep, and LAYERS them in by "Heat".
## Attack ON the beat -> Heat rises + the music fills out (drums -> bass ->
## guitar -> ... -> vocals). Miss -> Heat decays and the music strips back.
## Tap-tempo (T) sets BPM live, so you don't need to know it up front.
##
## This is the technical de-risk: if pounding SPACE on the beat feels good and
## the track audibly transforms, the concept is proven — hand to combat/art.

# Folder of the track's stems (Godot res:// path).
@export var stem_dir: String = "res://audio/weaponized_mind"

# Stems ordered LOW -> HIGH layer. Index 0 (drums) is always audible; each
# higher index unlocks at a higher Heat threshold. Match filenames on disk.
@export var stem_files: PackedStringArray = [
	"2 Drums.wav",
	"3 Bass.wav",
	"4 Guitar.wav",
	"6 Synth.wav",
	"5 Keyboard.wav",
	"1 Backing Vocals.wav",
	"0 Lead Vocals.wav",
]

@export var bpm: float = 120.0          ## tap T to the song to set this
@export var beat_window_ms: float = 110.0   ## timing tolerance for "on beat"
@export var heat_per_hit: float = 12.0
@export var heat_decay_per_sec: float = 9.0

var players: Array[AudioStreamPlayer] = []
var clock_player: AudioStreamPlayer = null
var heat: float = 0.0
var feedback: String = ""
var feedback_timer: float = 0.0
var taps: Array[float] = []

@onready var info: Label = $Info

func _ready() -> void:
	_load_stems()
	# Start every stem on the same frame -> synchronized playback.
	for p in players:
		p.play()
	if players.size() > 0:
		clock_player = players[0]

func _load_stems() -> void:
	for i in stem_files.size():
		var path := stem_dir + "/" + stem_files[i]
		var stream = load(path)
		if stream == null:
			push_warning("CINDERFORGE: missing stem " + path)
			continue
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = -80.0   # silent until Heat unlocks it
		add_child(p)
		players.append(p)
	if players.size() > 0:
		players[0].volume_db = 0.0   # drums always on

## Current song time, compensated for mix + output latency (Godot rhythm docs).
func song_position_sec() -> float:
	if clock_player == null or not clock_player.playing:
		return 0.0
	var t := clock_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	t -= AudioServer.get_output_latency()
	return maxf(t, 0.0)

## Milliseconds to the nearest beat (0 == perfectly on beat).
func nearest_beat_offset_ms() -> float:
	if bpm <= 0.0:
		return 9999.0
	var beat_len := 60.0 / bpm
	var phase := fmod(song_position_sec(), beat_len)
	return minf(phase, beat_len - phase) * 1000.0

func _process(delta: float) -> void:
	heat = clampf(heat - heat_decay_per_sec * delta, 0.0, 100.0)
	_apply_heat_layers()
	if feedback_timer > 0.0:
		feedback_timer -= delta
	else:
		feedback = ""
	_update_info()

## Fade stems in/out toward their Heat-gated target volume.
func _apply_heat_layers() -> void:
	var tiers := maxi(players.size(), 1)
	for i in players.size():
		if i == 0:
			continue
		var unlock_at := float(i) / float(tiers) * 100.0
		var target := 0.0 if heat >= unlock_at else -80.0
		players[i].volume_db = lerpf(players[i].volume_db, target, 0.15)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			_tap()
		elif event.keycode == KEY_SPACE:
			_attack()
	elif event is InputEventMouseButton and event.pressed:
		_attack()

func _attack() -> void:
	var off := nearest_beat_offset_ms()
	if off <= beat_window_ms:
		heat = clampf(heat + heat_per_hit, 0.0, 100.0)
		feedback = "ON BEAT  (+%d Heat)" % int(heat_per_hit)
	else:
		heat = clampf(heat - heat_per_hit * 0.5, 0.0, 100.0)
		feedback = "off  (%d ms)" % int(off)
	feedback_timer = 0.4

func _tap() -> void:
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

func _update_info() -> void:
	var filled := int(heat / 5.0)
	var bar := ""
	for i in 20:
		bar += "#" if i < filled else "."
	info.text = "CINDERFORGE  —  rhythm core prototype\n\n" \
		+ "BPM: %.1f     (tap T on the beat to set)\n" % bpm \
		+ "Heat: [%s] %d\n" % [bar, int(heat)] \
		+ "Nearest beat: %d ms\n\n" % int(nearest_beat_offset_ms()) \
		+ "ATTACK: Space / click  (land it on the beat -> +Heat -> music fills in)\n" \
		+ "\n%s" % feedback
