extends CharacterBody3D

@onready var anim_sprite = $AnimatedSprite3D
@onready var anim_player = $AnimationPlayer
@onready var attack_area = $AttackArea
@onready var radar_area = $RadarArea

enum Estado {IDLE, CHASE, ATTACK, DEATH, STUN}

var jugador = null
var estado = Estado.IDLE
var persiguiendo = false
var en_rango_ataque = false

@export var speed: float = 3
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
	
	match estado:
		Estado.IDLE:
			anim_idle()
		Estado.CHASE:
			perseguir()
		Estado.ATTACK:
			print("Hola")
	
func _on_attack_area_body_entered(body: Node3D) -> void:
	estado = Estado.ATTACK
	
func _on_attack_area_body_exited(body: Node3D) -> void:
	estado = Estado.CHASE
	
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
	anim_caminar()
	move_and_slide()
