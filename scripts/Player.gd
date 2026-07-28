extends CharacterBody2D
## Forged revenant — move, dash, attack into RhythmCore.

signal died

@export var move_speed: float = 260.0
@export var dash_speed: float = 620.0
@export var dash_time: float = 0.14
@export var attack_cooldown: float = 0.22
@export var base_damage: float = 12.0
@export var max_hp: float = 100.0

var hp: float = 100.0
var dash_timer: float = 0.0
var attack_cd: float = 0.0
var invuln: float = 0.0
var facing: Vector2 = Vector2.RIGHT
var rhythm: RhythmCore
var _attacking: bool = false

@onready var body: Polygon2D = $Body
@onready var sprite: Sprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox

const TEX_IDLE := preload("res://art/sprites/player/player_idle.png")
const TEX_ATTACK := preload("res://art/sprites/player/player_attack.png")
const TEX_DASH := preload("res://art/sprites/player/player_dash.png")
const TEX_HIT_SPARK := preload("res://art/sprites/vfx/hit_spark.png")
const TEX_BEAT_RING := preload("res://art/sprites/vfx/beat_ring.png")

func setup(r: RhythmCore) -> void:
	rhythm = r
	hp = max_hp

func _ready() -> void:
	hitbox.monitoring = false
	# Signals still useful for enemies that walk into an active swing mid-frame.
	hitbox.body_entered.connect(_on_hitbox_body)
	hitbox.area_entered.connect(_on_hitbox_area)
	if sprite:
		sprite.texture = TEX_IDLE

func _physics_process(delta: float) -> void:
	attack_cd = maxf(attack_cd - delta, 0.0)
	invuln = maxf(invuln - delta, 0.0)
	if dash_timer > 0.0:
		dash_timer -= delta
		move_and_slide()
		return

	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir.length() > 0.1:
		facing = dir.normalized()
		velocity = facing * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 4.0 * delta)
	move_and_slide()
	_update_facing_visual()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE):
		try_attack()
	elif event.is_action_pressed("dash") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SHIFT):
		try_dash()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_attack()

func try_dash() -> void:
	if dash_timer > 0.0:
		return
	var dir := facing
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input_dir.length() > 0.1:
		dir = input_dir.normalized()
		facing = dir
	dash_timer = dash_time
	velocity = dir * dash_speed
	invuln = dash_time
	if sprite:
		sprite.texture = TEX_DASH
	if rhythm and rhythm.is_on_beat():
		invuln += 0.05
		modulate = Color(1.0, 0.7, 0.3, 1.0)
	else:
		modulate = Color(0.7, 0.7, 0.8, 1.0)
	get_tree().create_timer(0.12).timeout.connect(func ():
		modulate = Color.WHITE
		if sprite and dash_timer <= 0.0 and not _attacking:
			sprite.texture = TEX_IDLE
	)

func try_attack() -> void:
	if attack_cd > 0.0 or _attacking:
		return
	_attacking = true
	attack_cd = attack_cooldown
	var mult := 1.0
	var on_beat := false
	if rhythm:
		var res: Dictionary = rhythm.resolve_attack()
		mult = float(res.get("mult", 1.0))
		on_beat = bool(res.get("on_beat", false))
	var dmg := base_damage * mult
	hitbox.position = facing * 36.0
	hitbox.set_meta("damage", dmg)
	hitbox.set_meta("on_beat", on_beat)
	hitbox.monitoring = true
	if sprite:
		sprite.texture = TEX_ATTACK
	if on_beat:
		_spawn_vfx(TEX_BEAT_RING, global_position + facing * 20.0, 0.25)
	modulate = Color(1.0, 0.85, 0.55, 1.0) if on_beat else Color(1, 1, 1, 1)

	# HIGH fix (Claude QA): body_entered does NOT fire for bodies already overlapping
	# when monitoring flips true. Query overlaps after a physics frame.
	await get_tree().physics_frame
	if not is_instance_valid(hitbox):
		_attacking = false
		return
	var hit_ids: Dictionary = {}
	for b in hitbox.get_overlapping_bodies():
		if _try_damage_target(b, hit_ids):
			_spawn_vfx(TEX_HIT_SPARK, b.global_position, 0.2)
	for a in hitbox.get_overlapping_areas():
		if _try_damage_target(a.get_parent(), hit_ids):
			_spawn_vfx(TEX_HIT_SPARK, a.global_position, 0.2)

	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(hitbox):
		hitbox.monitoring = false
	if is_instance_valid(sprite) and dash_timer <= 0.0:
		sprite.texture = TEX_IDLE
	modulate = Color.WHITE
	_attacking = false

func _on_hitbox_body(body_node: Node2D) -> void:
	if not hitbox.monitoring:
		return
	_try_damage_target(body_node, {})

func _on_hitbox_area(area: Area2D) -> void:
	if not hitbox.monitoring:
		return
	_try_damage_target(area.get_parent(), {})

func _try_damage_target(node: Node, hit_ids: Dictionary) -> bool:
	if node == null or not node.has_method("take_damage"):
		return false
	var id := node.get_instance_id()
	if hit_ids.has(id):
		return false
	hit_ids[id] = true
	var dmg: float = float(hitbox.get_meta("damage", base_damage))
	var on_beat: bool = bool(hitbox.get_meta("on_beat", false))
	node.take_damage(dmg, on_beat, global_position)
	return true

func _spawn_vfx(tex: Texture2D, pos: Vector2, life: float) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.z_index = 20
	get_parent().add_child(s)
	s.global_position = pos
	var tw := create_tween()
	tw.tween_property(s, "modulate:a", 0.0, life)
	tw.parallel().tween_property(s, "scale", Vector2(1.4, 1.4), life)
	tw.tween_callback(s.queue_free)

func take_damage(amount: float, _on_beat: bool = false, _from: Vector2 = Vector2.ZERO) -> void:
	if invuln > 0.0 or hp <= 0.0:
		return
	hp -= amount
	invuln = 0.35
	modulate = Color(1.0, 0.3, 0.3, 1.0)
	get_tree().create_timer(0.15).timeout.connect(func (): modulate = Color.WHITE)
	if hp <= 0.0:
		died.emit()

func _update_facing_visual() -> void:
	var sx := -1.0 if facing.x < 0.0 else 1.0
	if sprite:
		sprite.flip_h = facing.x < 0.0
	if body:
		body.scale.x = sx
