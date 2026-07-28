extends Node2D
## Main combat arena — owns RhythmCore, Player, enemies, rooms, juice.

enum Room { INTRO, A, REWARD, B, BOSS, WIN, DEAD }

var rhythm: RhythmCore
var player: CharacterBody2D
var room: Room = Room.INTRO
var shake: float = 0.0
var feedback: String = ""
var feedback_timer: float = 0.0
var enemies_alive: int = 0
var run_seed: int = 0

@onready var world: Node2D = $World
@onready var enemy_root: Node2D = $World/Enemies
@onready var spawn_points: Node2D = $World/Spawns
@onready var ui: CanvasLayer = $UI
@onready var info: Label = $UI/Info
@onready var heat_bar: ColorRect = $UI/HeatFill
@onready var heat_bg: ColorRect = $UI/HeatBg
@onready var beat_pip: ColorRect = $UI/BeatPip
@onready var camera: Camera2D = $Camera2D
@onready var floor_poly: Polygon2D = $World/Floor
@onready var floor_tiles: Node2D = $World/FloorTiles

const TEX_FLOOR := preload("res://art/sprites/env/tile_floor.png")
const TEX_FLOOR_B := preload("res://art/sprites/env/tile_floor_b.png")
const TEX_LAVA := preload("res://art/sprites/env/tile_lava.png")
const TEX_ANVIL := preload("res://art/sprites/env/prop_anvil.png")
const TEX_HEAT_BG := preload("res://art/sprites/ui/heat_bg.png")
const TEX_HEAT_FILL := preload("res://art/sprites/ui/heat_fill.png")
const TEX_BEAT_PIP := preload("res://art/sprites/ui/beat_pip.png")

func _ready() -> void:
	_setup_input()
	_build_floor()
	_style_ui()
	rhythm = RhythmCore.new()
	add_child(rhythm)
	rhythm.heat_changed.connect(_on_heat)
	rhythm.attack_resolved.connect(_on_attack_resolved)
	rhythm.start_music()

	player = preload("res://scenes/Player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector2(640, 400)
	player.setup(rhythm)
	player.died.connect(_on_player_died)

	# Clean exit on tree quit
	get_tree().root.close_requested.connect(_clean_exit)
	tree_exiting.connect(_clean_exit)

	_enter_room(Room.INTRO)

func _clean_exit() -> void:
	if rhythm:
		rhythm.shutdown()

func _build_floor() -> void:
	if floor_tiles == null:
		return
	for c in floor_tiles.get_children():
		c.queue_free()
	# Tile the arena rectangle
	var origin := Vector2(200, 120)
	var cols := 14
	var rows := 8
	for y in rows:
		for x in cols:
			var s := Sprite2D.new()
			var edge := x == 0 or y == 0 or x == cols - 1 or y == rows - 1
			s.texture = TEX_LAVA if edge and ((x + y) % 3 == 0) else (TEX_FLOOR if ((x + y) % 2 == 0) else TEX_FLOOR_B)
			s.position = origin + Vector2(x * 64 + 32, y * 64 + 32)
			s.z_index = -2
			floor_tiles.add_child(s)
	# Props
	var anvil := Sprite2D.new()
	anvil.texture = TEX_ANVIL
	anvil.position = Vector2(320, 520)
	anvil.z_index = -1
	floor_tiles.add_child(anvil)
	if floor_poly:
		floor_poly.visible = false

func _style_ui() -> void:
	# Replace ColorRect heat bar with sprites if present
	if heat_bg:
		heat_bg.color = Color(0, 0, 0, 0)
	if heat_bar:
		pass
	# Beat pip as texture via modulate on ColorRect is fine; add sprite overlay
	var pip := Sprite2D.new()
	pip.texture = TEX_BEAT_PIP
	pip.position = Vector2(632, 24)
	pip.name = "BeatPipSprite"
	ui.add_child(pip)
	# keep reference for pulse via beat_pip node if ColorRect

func _setup_input() -> void:
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("move_up", KEY_W)
	_add_key("move_down", KEY_S)
	_add_key("attack", KEY_SPACE)
	_add_key("dash", KEY_SHIFT)

func _add_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

func _process(delta: float) -> void:
	# Juice: camera shake
	if shake > 0.0:
		shake = maxf(shake - delta * 8.0, 0.0)
		camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) * 6.0
	else:
		camera.offset = Vector2.ZERO

	# Beat pip pulse
	var off := rhythm.nearest_beat_offset_ms()
	var pulse := clampf(1.0 - off / maxf(rhythm.beat_window_ms, 1.0), 0.0, 1.0)
	if beat_pip:
		beat_pip.modulate.a = 0.15 + pulse * 0.5
		beat_pip.scale = Vector2.ONE * (0.8 + pulse * 0.4)
	var pip_sprite := ui.get_node_or_null("BeatPipSprite") as Sprite2D
	if pip_sprite:
		pip_sprite.modulate.a = 0.35 + pulse * 0.65
		pip_sprite.scale = Vector2.ONE * (0.85 + pulse * 0.45)

	if feedback_timer > 0.0:
		feedback_timer -= delta
	else:
		feedback = ""

	_update_hud()

	# Room clear
	if room in [Room.INTRO, Room.A, Room.B, Room.BOSS]:
		enemies_alive = enemy_root.get_child_count()
		if enemies_alive == 0 and room != Room.WIN and room != Room.DEAD:
			_on_room_cleared()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			rhythm.tap_tempo()
		elif event.keycode == KEY_R and room == Room.DEAD:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_N and room == Room.REWARD:
			_enter_room(Room.B)
		elif event.keycode == KEY_N and room == Room.WIN:
			get_tree().reload_current_scene()

func _on_heat(value: float) -> void:
	var t := value / 100.0
	heat_bar.scale.x = maxf(t, 0.02)
	heat_bar.color = Color(1.0, 0.45 + t * 0.2, 0.1, 1.0)

func _on_attack_resolved(on_beat: bool, offset_ms: float, _mult: float) -> void:
	if on_beat:
		feedback = "ON BEAT"
		shake = maxf(shake, 0.35)
	else:
		feedback = "off  %dms" % int(offset_ms)
	feedback_timer = 0.35

func _on_player_died() -> void:
	room = Room.DEAD
	feedback = "FORGED OUT — press R to retry"
	feedback_timer = 99.0

func _on_room_cleared() -> void:
	match room:
		Room.INTRO:
			_enter_room(Room.A)
		Room.A:
			_enter_room(Room.REWARD)
		Room.B:
			_enter_room(Room.BOSS)
		Room.BOSS:
			room = Room.WIN
			feedback = "FIRST HAMMER BROKEN — N to restart"
			feedback_timer = 99.0
			rhythm.heat = 100.0

func _enter_room(r: Room) -> void:
	room = r
	for c in enemy_root.get_children():
		c.queue_free()
	# clear leftover bolts
	for c in world.get_children():
		if c is Area2D and c != player:
			c.queue_free()

	match r:
		Room.INTRO:
			floor_poly.color = Color(0.06, 0.04, 0.03, 1.0)
			player.global_position = Vector2(640, 400)
			_spawn(CFEnemy.Kind.WRETCH, Vector2(820, 360))
			feedback = "TUTORIAL — strike the Wretch ON the beat (Space)"
			feedback_timer = 4.0
		Room.A:
			floor_poly.color = Color(0.07, 0.04, 0.03, 1.0)
			_spawn(CFEnemy.Kind.WRETCH, Vector2(900, 300))
			_spawn(CFEnemy.Kind.WRETCH, Vector2(950, 420))
			_spawn(CFEnemy.Kind.ARCHER, Vector2(1000, 360))
			feedback = "ARENA A"
			feedback_timer = 2.0
		Room.REWARD:
			floor_poly.color = Color(0.08, 0.05, 0.02, 1.0)
			feedback = "REWARD — N continue | Heat is your music"
			feedback_timer = 8.0
			# small heal
			player.hp = minf(player.hp + 25.0, player.max_hp)
		Room.B:
			floor_poly.color = Color(0.07, 0.035, 0.03, 1.0)
			_spawn(CFEnemy.Kind.ARCHER, Vector2(880, 280))
			_spawn(CFEnemy.Kind.ARCHER, Vector2(1000, 450))
			_spawn(CFEnemy.Kind.GUARD, Vector2(920, 360))
			feedback = "ARENA B — open the Guard on the bright beat"
			feedback_timer = 3.0
		Room.BOSS:
			floor_poly.color = Color(0.1, 0.03, 0.02, 1.0)
			_spawn(CFEnemy.Kind.BOSS, Vector2(960, 360))
			_spawn(CFEnemy.Kind.WRETCH, Vector2(800, 280))
			feedback = "THE FIRST HAMMER"
			feedback_timer = 3.0
			shake = 0.8

func _spawn(kind: CFEnemy.Kind, pos: Vector2) -> void:
	var e: CFEnemy = preload("res://scenes/Enemy.tscn").instantiate()
	e.kind = kind
	enemy_root.add_child(e)
	e.global_position = pos
	e.setup(player, rhythm)
	e.died.connect(_on_enemy_died)

func _on_enemy_died(kind: CFEnemy.Kind) -> void:
	if kind == CFEnemy.Kind.BOSS:
		shake = 1.2
	else:
		shake = maxf(shake, 0.4)
	# Heat snack on kill
	if rhythm:
		rhythm.heat = clampf(rhythm.heat + 6.0, 0.0, 100.0)

func _update_hud() -> void:
	var filled := int(rhythm.heat / 5.0)
	var bar := ""
	for i in 20:
		bar += "#" if i < filled else "."
	var room_name: String = str(Room.keys()[room])
	info.text = "CINDERFORGE  |  %s\n" % room_name \
		+ "BPM %.0f  (T = tap tempo)   Heat [%s] %d\n" % [rhythm.bpm, bar, int(rhythm.heat)] \
		+ "HP %d/%d    Enemies %d\n" % [int(player.hp), int(player.max_hp), enemy_root.get_child_count()] \
		+ "WASD move | Space attack | Shift dash | R retry\n" \
		+ "Nearest beat: %d ms\n" % int(rhythm.nearest_beat_offset_ms()) \
		+ feedback
