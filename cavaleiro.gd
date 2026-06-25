extends CharacterBody3D

signal died
@export var max_speed: float = 5.0
@export var acceleration: float = 25.0
@export var jump_velocity: float = 6.0
const COYOTE_TIME = 0.12
signal health_changed(current: float, max: float)
@export var action_jump: String = "jump"
@export var action_attack: String = "attack"
@export var action_block: String = "block"
@export var action_move_left: String = "esquerda"
@export var action_move_right: String = "direita"
@export var action_move_forward: String = "frente"
@export var action_move_back: String = "tras"
@export var camera_pivot: Node3D
@export var attack_duration: float = 0.4
@export var max_health: float = 100.0
@onready var anim = %AnimationPlayer
@onready var hitbox = $Knight/Rig_Medium/Skeleton3D/BoneAttachment3D/mao_d/MeshInstance3D/sword_1handed/Area3D
@onready var shieldbox = $Knight/Rig_Medium/Skeleton3D/BoneAttachment3D2/mao_e/MeshInstance3D/shield_round_color2/Area3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_attacking = false
var is_blocking = false
var is_dead = false
var was_on_floor = true
var coyote_timer = 0.0
var attack_timer: float = 0.0
var hitbox_timer: float = 0.0
var health: float = max_health

func _ready():
	floor_snap_length = 0.0
	floor_max_angle = deg_to_rad(60)
	health = max_health
	hitbox.monitoring = false
	shieldbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	shieldbox.body_entered.connect(_on_shieldbox_body_entered)
	health_changed.emit(health, max_health)

func take_damage(amount: float):
	if is_blocking or is_dead:
		return
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		die()
	else:
		anim.play("movimentos/SofrerDano")

func die():
	if is_dead:
		return
	is_dead = true
	health = 0
	anim.play("movimentos/Morte")
	set_physics_process(false)
	hitbox.monitoring = false
	shieldbox.monitoring = false
	await get_tree().create_timer(4).timeout
	get_tree().change_scene_to_file("res://game_over.tscn")
	died.emit()

func _on_hitbox_body_entered(body):
	if body == self:
		return
	if body.has_method("take_damage"):
		body.take_damage(10)
	elif body is RigidBody3D:
		var direction = (body.global_position - hitbox.global_position).normalized()
		direction.y = 0.5
		body.apply_impulse(direction * 10.0)

func _on_shieldbox_body_entered(body):
	if body == self:
		return
	if body is RigidBody3D:
		var direction = (body.global_position - shieldbox.global_position).normalized()
		direction.y = 0.5
		body.apply_impulse(direction * 10.0)

func _physics_process(delta):
	var on_floor = is_on_floor()

	if not was_on_floor and on_floor:
		anim.play("movimentos/Repouso", 0.1)
	was_on_floor = on_floor

	if on_floor:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if not on_floor:
		velocity.y -= gravity * delta

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			is_attacking = false
			hitbox.monitoring = false

	if hitbox_timer > 0.0:
		hitbox_timer -= delta
		if hitbox_timer <= 0.0:
			hitbox.monitoring = false

	if Input.is_action_just_pressed(action_jump) and coyote_timer > 0.0 and not is_attacking and not is_blocking:
		velocity.y = jump_velocity
		coyote_timer = 0.0
		anim.play("movimentos/Pulo", 0.1)

	if not on_floor:
		is_attacking = false
		hitbox.monitoring = false
		anim.speed_scale = 1.0
		if velocity.y > 0:
			anim.play("movimentos/Pulo")
		else:
			anim.play("movimentos/Queda")

	if Input.is_action_just_pressed(action_attack) and on_floor and not is_blocking:
		is_attacking = true
		hitbox.monitoring = true
		attack_timer = attack_duration
		hitbox_timer = attack_duration * 0.5
		anim.play("movimentos/Ataque_Espada")
	elif Input.is_action_pressed(action_block) and on_floor and not is_attacking:
		if not is_blocking:
			is_blocking = true
			shieldbox.monitoring = true
			anim.play("movimentos/Bloqueio")
	elif Input.is_action_just_released(action_block):
		is_blocking = false
		shieldbox.monitoring = false

	var input_dir = Input.get_vector(action_move_left, action_move_right, action_move_forward, action_move_back)
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if camera_pivot:
		var yaw = camera_pivot.global_rotation.y
		var cam_forward = Vector3(-sin(yaw), 0, -cos(yaw))
		var cam_right = Vector3(cos(yaw), 0, -sin(yaw))
		direction = (cam_forward * -input_dir.y + cam_right * input_dir.x).normalized()

	if direction and not is_attacking and not is_blocking:
		velocity.x = move_toward(velocity.x, direction.x * max_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * max_speed, acceleration * delta)
		if velocity.length_squared() > 0.1:
			var target_angle = atan2(direction.x, direction.z)
			$Knight.rotation.y = lerp_angle($Knight.rotation.y, target_angle, 10.0 * delta)
		if on_floor:
			anim.play("movimentos/Corrida", 0.25)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
		if on_floor and not is_attacking and not is_blocking:
			anim.play("movimentos/Repouso", 0.25)

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() is RigidBody3D:
			var push_dir = collision.get_normal() * -1
			collision.get_collider().apply_central_impulse(push_dir * max_speed)

	move_and_slide()
