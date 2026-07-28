extends CharacterBody2D
## Base enemy — three types via @export kind.
class_name CFEnemy

enum Kind { WRETCH, ARCHER, GUARD, BOSS }

signal died(kind: Kind)

@export var kind: Kind = Kind.WRETCH
@export var max_hp: float = 30.0
@export var move_speed: float = 90.0
@export var contact_damage: float = 8.0
@export var attack_damage: float = 12.0

var hp: float = 30.0
var player: Node2D = null
var rhythm: RhythmCore = null
var attack_cd: float = 0.0
var stun: float = 0.0
var telegraph: float = 0.0
var guard_open: bool = false
var last_beat: int = -1

@onready var body: Polygon2D = $Body
@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label
@onready var hurt: Area2D = $Hurtbox

const TEX_WRETCH := preload("res://art/sprites/enemies/wretch.png")
const TEX_ARCHER := preload("res://art/sprites/enemies/archer.png")
const TEX_GUARD := preload("res://art/sprites/enemies/guard.png")
const TEX_BOSS := preload("res://art/sprites/enemies/boss_first_hammer.png")
const TEX_DEATH := preload("res://art/sprites/vfx/death_sparks.png")

func setup(p: Node2D, r: RhythmCore) -> void:
	player = p
	rhythm = r
	_apply_kind_stats()
	hp = max_hp
	_style_body()

func _apply_kind_stats() -> void:
	match kind:
		Kind.WRETCH:
			max_hp = 24.0
			move_speed = 110.0
			attack_damage = 10.0
			label.text = "Wretch"
		Kind.ARCHER:
			max_hp = 28.0
			move_speed = 70.0
			attack_damage = 14.0
			label.text = "Archer"
		Kind.GUARD:
			max_hp = 55.0
			move_speed = 55.0
			attack_damage = 16.0
			label.text = "Guard"
		Kind.BOSS:
			max_hp = 220.0
			move_speed = 65.0
			attack_damage = 22.0
			label.text = "FIRST HAMMER"
			scale = Vector2(1.25, 1.25)

func _style_body() -> void:
	if sprite == null:
		return
	match kind:
		Kind.WRETCH:
			sprite.texture = TEX_WRETCH
		Kind.ARCHER:
			sprite.texture = TEX_ARCHER
		Kind.GUARD:
			sprite.texture = TEX_GUARD
		Kind.BOSS:
			sprite.texture = TEX_BOSS
	body.visible = false

func _physics_process(delta: float) -> void:
	if player == null or hp <= 0.0:
		return
	stun = maxf(stun - delta, 0.0)
	attack_cd = maxf(attack_cd - delta, 0.0)
	if stun > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		move_and_slide()
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 1.0 else Vector2.ZERO

	match kind:
		Kind.WRETCH:
			_ai_wretch(delta, dir, dist)
		Kind.ARCHER:
			_ai_archer(delta, dir, dist)
		Kind.GUARD:
			_ai_guard(delta, dir, dist)
		Kind.BOSS:
			_ai_boss(delta, dir, dist)

	move_and_slide()
	# Contact damage
	if dist < 28.0 and player != null and player.get("invuln") != null and float(player.invuln) <= 0.0:
		if player.has_method("take_damage"):
			player.take_damage(contact_damage * 8.0 * delta)

func _ai_wretch(_delta: float, dir: Vector2, dist: float) -> void:
	velocity = dir * move_speed
	if dist < 40.0 and attack_cd <= 0.0:
		_telegraph_attack(0.25)
		attack_cd = 1.1

func _ai_archer(_delta: float, dir: Vector2, dist: float) -> void:
	if dist < 160.0:
		velocity = -dir * move_speed
	elif dist > 220.0:
		velocity = dir * move_speed * 0.8
	else:
		velocity = Vector2.ZERO
	if attack_cd <= 0.0 and dist < 280.0:
		_fire_bolt(dir)
		attack_cd = 1.6

func _ai_guard(_delta: float, dir: Vector2, dist: float) -> void:
	velocity = dir * move_speed * 0.7
	# Open guard every 4 beats for 1 beat window
	if rhythm:
		var b := rhythm.beat_index()
		guard_open = (b % 4) == 0
		body.modulate = Color(1.0, 0.85, 0.4, 1.0) if guard_open else Color(0.6, 0.6, 0.65, 1.0)
	if dist < 50.0 and attack_cd <= 0.0:
		attack_cd = 1.8
		_telegraph_attack(0.35)

func _ai_boss(delta: float, dir: Vector2, dist: float) -> void:
	velocity = dir * move_speed
	if attack_cd <= 0.0 and dist < 90.0:
		_telegraph_attack(0.55)
		attack_cd = 2.2 if hp > max_hp * 0.5 else 1.4
	# Phase 2 tint
	if hp <= max_hp * 0.5:
		body.modulate = Color(1.0, 0.45, 0.2, 1.0)

func _telegraph_attack(windup: float) -> void:
	telegraph = windup
	body.modulate = Color(1.0, 0.3, 0.1, 1.0)
	get_tree().create_timer(windup).timeout.connect(func ():
		if hp <= 0.0:
			return
		body.modulate = Color.WHITE
		if player and global_position.distance_to(player.global_position) < (100.0 if kind == Kind.BOSS else 48.0):
			if player.has_method("take_damage") and float(player.get("invuln")) <= 0.0:
				player.take_damage(attack_damage)
	)

func _fire_bolt(dir: Vector2) -> void:
	var bolt := Area2D.new()
	var poly := Polygon2D.new()
	poly.color = Color(1.0, 0.45, 0.1, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(8, 0), Vector2(-4, 4)])
	bolt.add_child(poly)
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	cs.shape = shape
	bolt.add_child(cs)
	bolt.collision_layer = 0
	bolt.collision_mask = 1
	bolt.monitoring = true
	get_parent().add_child(bolt)
	bolt.global_position = global_position + dir * 20.0
	var vel := dir * 280.0
	bolt.body_entered.connect(func (b):
		if b == player and player.has_method("take_damage"):
			if float(player.get("invuln")) <= 0.0:
				player.take_damage(attack_damage * 0.9)
			bolt.queue_free()
	)
	var life := 2.2
	var end_pos := bolt.global_position + vel * life
	var tw := get_tree().create_tween()
	tw.tween_property(bolt, "global_position", end_pos, life)
	tw.tween_callback(func ():
		if is_instance_valid(bolt):
			bolt.queue_free()
	)

func take_damage(amount: float, on_beat: bool = false, from: Vector2 = Vector2.ZERO) -> void:
	if hp <= 0.0:
		return
	# Guard reduces damage unless open or on-beat heavy-ish
	if kind == Kind.GUARD and not guard_open and not on_beat:
		amount *= 0.25
		body.modulate = Color(0.5, 0.5, 0.6, 1.0)
	elif kind == Kind.GUARD and guard_open and on_beat:
		amount *= 1.8
		stun = 0.6
	if on_beat:
		amount *= 1.0  # mult already in amount from player
		stun = maxf(stun, 0.08)
	hp -= amount
	# knockback
	if from != Vector2.ZERO:
		var kb := (global_position - from).normalized() * (140.0 if on_beat else 80.0)
		velocity = kb
	body.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var flash := Color(1.0, 0.6, 0.2, 1.0) if on_beat else Color(1.0, 0.4, 0.4, 1.0)
	modulate = flash
	get_tree().create_timer(0.08).timeout.connect(func (): modulate = Color.WHITE)
	if hp <= 0.0:
		_die()

func _die() -> void:
	died.emit(kind)
	# death sparks
	var s := Sprite2D.new()
	s.texture = TEX_DEATH
	s.z_index = 30
	get_parent().add_child(s)
	s.global_position = global_position
	var tws := create_tween()
	tws.tween_property(s, "modulate:a", 0.0, 0.35)
	tws.tween_callback(s.queue_free)
	modulate = Color(1.0, 0.5, 0.1, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tw.tween_callback(queue_free)
