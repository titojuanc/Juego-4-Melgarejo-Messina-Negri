extends CharacterBody3D

var anim_sprite = null
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

const GRAVEDAD = 9.8

func _ready() -> void:
	anim_sprite = get_node_or_null("AnimatedSprite3D")
	anim_player = get_node_or_null("AnimationPlayer")
	attack_area = get_node_or_null("AttackArea")
	radar_area  = get_node_or_null("RadarArea")
	
func anim_caminar():
	if anim_sprite == null:
		return
	if anim_sprite.sprite_frames.has_animation("Walk"):
		anim_sprite.play("Walk")
	
func anim_idle():
	if anim_sprite == null:
		return
	if anim_sprite.sprite_frames.has_animation("Idle"):
		anim_sprite.play("Idle")
	
func anim_atacar():
	if anim_player == null:
		return
	if anim_player.has_animation("Attack"):
		anim_player.play("Attack")
	
func anim_hurt():
	if anim_sprite == null:
		return
	if anim_sprite.sprite_frames.has_animation("Hurt"):
		anim_sprite.play("Hurt")
	
func anim_muerte():
	if anim_sprite == null:
		return
	if anim_sprite.sprite_frames.has_animation("Death"):
		anim_sprite.play("Death")
	
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
			if not atacando:
				iniciar_ataque()
	move_and_slide()
	
func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		estado = Estado.ATTACK
	
func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		estado = Estado.CHASE
		atacando = false
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
	if anim_sprite != null:
		if dir.x < 0:
			anim_sprite.flip_h = false
		elif dir.x > 0:
			anim_sprite.flip_h = true
	anim_caminar()
	
func iniciar_ataque():
	atacando = true
	anim_atacar()
	if anim_player != null and anim_player.has_animation("Attack"):
		await anim_player.animation_finished
	if estado == Estado.DEATH:
		return
	atacando = false
	
func apuntar_attack_area():
	if jugador == null:
		return
	var dir = (jugador.global_position - global_position)
	dir.y = 0
	rotation.y = atan2(dir.x, dir.z) + PI / 2
	if anim_sprite != null:
		anim_sprite.global_rotation.y = 0
	
func pegar():
	if jugador != null:
		jugador.vida -= danio
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
	var col = get_node_or_null("CollisionShape3D")
	if col != null:
		col.disabled = true
	if attack_area != null:
		attack_area.monitoring = false
	if radar_area != null:
		radar_area.monitoring = false
	if anim_player != null:
		anim_player.stop()
	anim_muerte()
	
func _on_animated_sprite_3d_animation_finished() -> void:
	if anim_sprite == null:
		return
	print("animation_finished: ", anim_sprite.animation)
	if estado == Estado.DEATH:
		queue_free()
