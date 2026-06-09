extends CharacterBody3D

@onready var anim_sprite = $AnimatedSprite3D
@onready var anim_player = $AnimationPlayer
@onready var attack_area = $AttackArea
@onready var radar_area = $RadarArea

enum Estado {IDLE, CHASE, ATTACK, DEATH}

var atacando = false
var jugador = null
var estado = Estado.IDLE
var persiguiendo = false
var en_rango_ataque = false

@export var speed: float = 3
@export var danio: int = 10
@export var vida: int = 50

const GRAVEDAD = 9.8

func _ready() -> void:
	pass

func anim_caminar():
	anim_sprite.play("Walk")
func anim_idle():
	anim_sprite.play("Idle")
func anim_atacar():
	anim_player.play("Attack")
func anim_hurt():
	anim_sprite.play("Hurt")
func anim_muerte():
	anim_sprite.play("Death")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVEDAD * delta
	else:
		velocity.y = 0
	
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("Jugador")
		if jugador == null:
			return
	
	if estado == Estado.DEATH:
		return 
	
	apuntar_attack_area()
	match estado:
		Estado.IDLE:
			anim_idle()
		Estado.CHASE:
			perseguir()
		Estado.ATTACK:
			if not atacando:
				iniciar_ataque()
	
func _on_attack_area_body_entered(body: Node3D) -> void:
	estado = Estado.ATTACK
	
func _on_attack_area_body_exited(body: Node3D) -> void:
	estado = Estado.CHASE
	atacando = false
	anim_player.stop()
	
func _on_radar_area_body_entered(body: Node3D) -> void:
	estado = Estado.CHASE
	
func _on_radar_area_body_exited(body: Node3D) -> void:
	estado = Estado.IDLE
	
func perseguir():
	var dir = (jugador.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if dir.x < 0:
		anim_sprite.flip_h = false  # derecha
	elif dir.x > 0:
		anim_sprite.flip_h = true   # izquierda
	anim_caminar()
	move_and_slide()

func iniciar_ataque():
	atacando = true
	anim_atacar()
	await anim_player.animation_finished
	atacando = false

func apuntar_attack_area():
	if jugador == null:
		return
	var dir = (jugador.global_position - global_position)
	dir.y = 0
	rotation.y = atan2(dir.x, dir.z) + PI / 2
	anim_sprite.global_rotation.y = 0

func pegar():
	if jugador != null:
		jugador.vida -= danio
		print(jugador.vida)
