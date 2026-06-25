extends CharacterBody3D

# ---- Copie as mesmas variáveis do cavaleiro.gd ----
@export var max_speed: float = 5.0
@export var acceleration: float = 25.0
@export var jump_velocity: float = 6.0
const ATTACK_LUNGE = 3.5

@export var max_health: float = 100.0

@onready var health_bar = $CanvasLayer/HealthBar
@onready var anim = $Rig_Medium_MovementBasic/AnimationPlayer
@onready var hitbox: Area3D = $Knight/Rig_Medium/GeneralSkeleton/BoneAttachment3D/Node3D/sword_1handed/hitboxSword
@onready var hitbox_shield: Area3D = $Knight/Rig_Medium/GeneralSkeleton/BoneAttachment3D2/Node3D/shield_badge_color/hitboxShield

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_attacking = false
var is_blocking = false
var health: float = 0.0

# ---- Referência ao jogador ----
@export var jogador: CharacterBody3D

# ---- Personalidade do bot ----
@export var agressividade: float = 0.8   # 0.0 a 1.0
@export var chance_bloqueio: float = 0.3
@export var distancia_ataque: float = 1.8
@export var distancia_recuo: float = 4.0

# ---- Estado interno ----
enum Estado { IDLE, APROXIMAR, ATACAR, BLOQUEAR, RECUAR }
var estado_atual = Estado.IDLE
var timer_decisao: float = 0.0
var intervalo_decisao: float = 0.6

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	anim.animation_finished.connect(_on_animation_finished)
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)

func _physics_process(delta):
	# Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Decisão da IA
	timer_decisao -= delta
	if timer_decisao <= 0:
		_tomar_decisao()
		timer_decisao = intervalo_decisao

	# Executa o estado atual
	_executar_estado(delta)

	move_and_slide()

# -----------------------------------------------
# DECISÃO
# -----------------------------------------------
func _tomar_decisao():
	if jogador == null or not is_on_floor():
		return

	var distancia = global_position.distance_to(jogador.global_position)
	var chance = randf()

	if distancia > distancia_recuo:
		estado_atual = Estado.APROXIMAR

	elif distancia <= distancia_ataque:
		if is_attacking or is_blocking:
			return  # não interrompe ação em andamento
		if chance < agressividade:
			estado_atual = Estado.ATACAR
		elif chance < agressividade + chance_bloqueio:
			estado_atual = Estado.BLOQUEAR
		else:
			estado_atual = Estado.RECUAR
	else:
		if chance < agressividade:
			estado_atual = Estado.APROXIMAR
		else:
			estado_atual = Estado.IDLE

# -----------------------------------------------
# EXECUÇÃO DOS ESTADOS
# -----------------------------------------------
func _executar_estado(delta):
	match estado_atual:

		Estado.IDLE:
			_desacelerar(delta)
			if not is_attacking and not is_blocking:
				if anim.current_animation != "idle/mixamo_com":
					anim.play("idle/mixamo_com", 0.25)

		Estado.APROXIMAR:
			if not is_attacking and not is_blocking:
				_mover_para(jogador.global_position, delta)

		Estado.ATACAR:
			if not is_attacking and not is_blocking:
				_atacar()

		Estado.BLOQUEAR:
			if not is_attacking:
				_bloquear()

		Estado.RECUAR:
			if not is_attacking and not is_blocking:
				var direcao_fuga = global_position - jogador.global_position
				direcao_fuga.y = 0
				_mover_para(global_position + direcao_fuga.normalized() * 3.0, delta)
			# Para de bloquear se estava bloqueando
			is_blocking = false

func _mover_para(destino: Vector3, delta: float):
	var direcao = (destino - global_position)
	direcao.y = 0
	direcao = direcao.normalized()

	velocity.x = move_toward(velocity.x, direcao.x * max_speed, delta * acceleration)
	velocity.z = move_toward(velocity.z, direcao.z * max_speed, delta * acceleration)

	anim.play("Running_A", 0.25)

	# Vira o modelo na direção do jogador
	if jogador:
		$Knight.look_at(Vector3(jogador.global_position.x, global_position.y, jogador.global_position.z), Vector3.UP, true)

func _desacelerar(delta: float):
	velocity.x = move_toward(velocity.x, 0, delta * acceleration)
	velocity.z = move_toward(velocity.z, 0, delta * acceleration)

func _atacar():
	is_attacking = true
	anim.play("attack/mixamo_com", 0.15)
	anim.speed_scale = 1.5
	hitbox.monitoring = true
	var lunge_dir = transform.basis.z
	velocity.x = lunge_dir.x * ATTACK_LUNGE
	velocity.z = lunge_dir.z * ATTACK_LUNGE

func _bloquear():
	is_blocking = true
	anim.play("block/mixamo_com", 0.2)

# -----------------------------------------------
# DANO E MORTE (igual ao cavaleiro.gd)
# -----------------------------------------------
func take_damage(amount: float):
	if is_blocking:
		amount *= 0.2
	health -= amount
	health_bar.value = health
	if health <= 0:
		die()
	else:
		anim.play("reaction/mixamo_com", 0.1)

func die():
	health = 0
	anim.play("morreu/mixamo_com", 0.1)
	set_physics_process(false)

func _on_hitbox_body_entered(body):
	if body == self:
		return
	if body.has_method("take_damage"):
		body.take_damage(20.0)

func _on_hitbox_area_entered(area):
	var parent = area.get_parent()
	if parent == self:
		return
	if parent.has_method("take_damage"):
		parent.take_damage(20.0)

func _on_animation_finished(anim_name: String):
	if anim_name == "attack/mixamo_com":
		is_attacking = false
		anim.speed_scale = 1.0
		hitbox.monitoring = false
		estado_atual = Estado.IDLE
	elif anim_name == "reaction/mixamo_com":
		anim.play("idle/mixamo_com", 0.2)
	elif anim_name == "morreu/mixamo_com":
		queue_free()
	elif anim_name == "block/mixamo_com":
		is_blocking = false
		estado_atual = Estado.IDLE
