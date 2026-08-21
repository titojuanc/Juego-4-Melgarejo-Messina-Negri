extends CharacterBody3D

var anim_player = null
var attack_area = null
var radar_area = null

enum Estado {IDLE, CHASE, ATTACK, DEATH}

var atacando = false
var jugador = null
var estado = Estado.IDLE

@export var speed: float = 3
@export var danio: int = 10
@export var vida: int = 50
@onready var attack_timer: Timer = $AttackTimer
var jugador_en_rango_ataque = false

const GRAVEDAD = 9.8
const _CANIA_DROP_SCENE = preload("res://scenes/CaniaDePescarDrop.tscn")

var _drop_spawneado := false

func _ready() -> void:
	anim_player = get_node_or_null("AnimationPlayer")
	if anim_player == null:
		anim_player = get_node_or_null("Iron Oath Executioner2/AnimationPlayer")
	attack_area = get_node_or_null("AttackArea")
	radar_area  = get_node_or_null("RadarArea")
	if attack_timer != null:
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	
func anim_caminar():
	if anim_player != null and anim_player.has_animation("Walk"):
		if anim_player.current_animation != "Walk":
			anim_player.play("Walk")
	
func anim_idle():
	if anim_player != null and anim_player.has_animation("Idle"):
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")
	
func anim_atacar():
	if anim_player != null and anim_player.has_animation("Attack"):
		anim_player.play("Attack")
	
func anim_hurt():
	if anim_player != null and anim_player.has_animation("Hurt"):
		anim_player.play("Hurt")
	
func anim_muerte():
	if anim_player != null and anim_player.has_animation("Death"):
		anim_player.play("Death")
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVEDAD * delta
	else:
		velocity.y = 0
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("Jugador")
		return
	if estado == Estado.DEATH:
		return
	apuntar_attack_area()
	match estado:
		Estado.IDLE:
			velocity.x = 0
			velocity.z = 0
			anim_idle()
		Estado.CHASE:
			perseguir()
		Estado.ATTACK:
			velocity.x = 0
			velocity.z = 0
	move_and_slide()
	
func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_en_rango_ataque = true
		estado = Estado.ATTACK
		if attack_timer != null and attack_timer.is_stopped():
			iniciar_ataque()
			attack_timer.start()
	
func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_en_rango_ataque = false
		estado = Estado.CHASE
		atacando = false
		if attack_timer != null:
			attack_timer.stop()
		if anim_player != null:
			anim_player.stop()
	
func _on_radar_area_body_entered(body: Node3D) -> void:
	print("RADAR DETECTÓ: ", body.name)
	if body.is_in_group("Jugador"):
		estado = Estado.CHASE
	
func _on_radar_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		estado = Estado.IDLE
	
func perseguir():
	var dir = (jugador.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	anim_caminar()
	
func iniciar_ataque():
	atacando = true
	anim_atacar()
	pegar()
	if anim_player != null and anim_player.has_animation("Attack"):
		await anim_player.animation_finished
	if estado == Estado.DEATH:
		return
	atacando = false

func _on_attack_timer_timeout() -> void:
	if estado == Estado.DEATH:
		if attack_timer != null:
			attack_timer.stop()
		return
	if not jugador_en_rango_ataque:
		if attack_timer != null:
			attack_timer.stop()
		return
	if not atacando:
		iniciar_ataque()
	
func apuntar_attack_area():
	if jugador == null:
		return
	var dir = (jugador.global_position - global_position)
	dir.y = 0
	rotation.y = atan2(dir.x, dir.z)
	
func pegar():
	if jugador != null:
		jugador.restar_vida(danio)
		print(jugador.vida)
	
func recibir_danio(cantidad: int) -> void:
	if estado == Estado.DEATH:
		return
	vida -= cantidad
	print("Zombie vida: ", vida)
	if vida <= 0:
		morir()
	else:
		anim_hurt()
	
func morir() -> void:
	estado = Estado.DEATH
	velocity = Vector3.ZERO
	if attack_timer != null:
		attack_timer.stop()
	_spawnear_drop_cania()
	var col = get_node_or_null("CollisionShape3D")
	if col != null:
		col.disabled = true
	if attack_area != null:
		attack_area.monitoring = false
	if radar_area != null:
		radar_area.monitoring = false
	if anim_player != null and anim_player.has_animation("Death"):
		anim_muerte()
	else:
		queue_free()

func _spawnear_drop_cania() -> void:
	if _drop_spawneado:
		return
	_drop_spawneado = true
	if _CANIA_DROP_SCENE == null:
		return
	var drop: Node3D = _CANIA_DROP_SCENE.instantiate()
	get_parent().add_child(drop)
	drop.global_position = global_position

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Death":
		queue_free()
