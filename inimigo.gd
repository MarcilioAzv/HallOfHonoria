extends CharacterBody3D
@export var max_speed: float = 3.0
@export var acceleration: float = 20.0
@export var attack_range: float = 1.6
@export var chase_range: float = 10.0
@export var damage: float = 10.0
@export var max_health: float = 30.0
@export var target: CharacterBody3D
@onready var anim = %AnimationPlayer
@onready var health_bar = $HealthBar3D
@onready var hitbox = $Barbarian/Rig_Medium/GeneralSkeleton/BoneAttachment3D/mao_d/MeshInstance3D/sword_1handed/Area3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_attacking = false
var is_hit = false
var is_dead = false
var health: float
var hitbox_timer: float = 0.0
enum State { IDLE, CHASE, ATTACK, HIT }
var state = State.IDLE

func _ready():
	add_to_group("inimigos")
	anim.animation_finished.connect(_on_animation_finished)
	health = max_health
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	for anim_name in anim.get_animation_list():
		var a = anim.get_animation(anim_name)
	set_physics_process(false)
	visible = false
	$CollisionShape3D.disabled = true
	anim.play("Spawn_Air", 0.0)
	await get_tree().create_timer(0.05).timeout
	visible = true
	$CollisionShape3D.disabled = false
	health = max_health
	$Barbarian/Rig_Medium.rotation.y = deg_to_rad(0)
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)

	for anim_name in anim.get_animation_list():
		var a = anim.get_animation(anim_name)
		if a:
			for i in a.get_track_count():
				var path = str(a.track_get_path(i))
				if path == "Barbarian/Rig_Medium" and (a.track_get_type(i) == Animation.TYPE_ROTATION_3D or a.track_get_type(i) == Animation.TYPE_POSITION_3D):
					a.track_set_enabled(i, false)

	anim.animation_finished.connect(_on_animation_finished)

func _on_hitbox_body_entered(body):
	if body == self:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)

func _on_animation_finished(anim_name: String):
	if anim_name == "Spawn_Air":
		set_physics_process(true)
		state = State.IDLE
	$Barbarian/Rig_Medium.rotation.y = deg_to_rad(0)
	if anim_name == "ataque/mixamo_com":
		is_attacking = false
		hitbox.monitoring = false
		if state == State.ATTACK:
			_iniciar_ataque()
	if anim_name == "Hit_B":
		is_hit = false
		state = State.CHASE
	if anim_name == "Death_A":
		$CollisionShape3D.disabled = true
		await get_tree().create_timer(2.0).timeout
		queue_free()

func take_damage(amount: float):
	if is_dead or is_hit:
		return
	health -= amount
	health_bar.update_health(health, max_health)
	if health <= 0:
		die()
		return
	is_hit = true
	is_attacking = false
	hitbox.monitoring = false
	state = State.HIT
	anim.play("Hit_B")

func die():
	is_dead = true
	hitbox.monitoring = false
	anim.play("Death_A")
	set_physics_process(false)

func _iniciar_ataque():
	is_attacking = true
	hitbox.monitoring = true
	anim.play("ataque/mixamo_com", -1, 1.5)
	var duracao = anim.get_animation("ataque/mixamo_com").length / 1.5
	hitbox_timer = duracao * 0.5

func _physics_process(delta):
	if hitbox_timer > 0.0:
		hitbox_timer -= delta
		if hitbox_timer <= 0.0:
			hitbox.monitoring = false

	if not is_on_floor():
		velocity.y -= gravity * delta

	if not target:
		return

	var dist = global_position.distance_to(target.global_position)

	match state:
		State.IDLE:
			$Barbarian/Rig_Medium.rotation.y = deg_to_rad(0)
			if anim.current_animation != "Idle_A":
				anim.play("Idle_A")
			if dist < chase_range:
				state = State.CHASE

		State.CHASE:
			$Barbarian/Rig_Medium.rotation.y = deg_to_rad(0)
			var direction = (target.global_position - global_position)
			direction.y = 0
			direction = direction.normalized()

			velocity.x = direction.x * max_speed
			velocity.z = direction.z * max_speed

			if direction.length_squared() > 0.01:
				var look_pos = global_position - direction
				look_at(look_pos, Vector3.UP)

			if anim.current_animation != "Global1/Running_A":
				anim.play("Global1/Running_A")

			if dist < attack_range:
				state = State.ATTACK
			elif dist > chase_range + 2:
				state = State.IDLE

		State.ATTACK:
			$Barbarian/Rig_Medium.rotation.y = deg_to_rad(0)
			velocity = Vector3.ZERO

			var attack_dir = (target.global_position - global_position)
			attack_dir.y = 0
			attack_dir = attack_dir.normalized()
			if attack_dir.length_squared() > 0.01:
				var look_pos = global_position - attack_dir
				look_at(look_pos, Vector3.UP)

			if not is_attacking:
				_iniciar_ataque()

			if dist > attack_range + 0.5:
				is_attacking = false
				hitbox.monitoring = false
				anim.play("Idle_A")
				state = State.CHASE
		State.HIT:
			$Barbarian/Rig_Medium.rotation.y = deg_to_rad(0)
			velocity = Vector3.ZERO
	move_and_slide()
