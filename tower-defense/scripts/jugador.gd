extends CharacterBody3D

@onready var attack_area = $AttackArea
@onready var anim_player = $AnimationPlayer
@onready var anim_sprite = $AnimatedSprite3D

@export var speed = 10

const GRAVEDAD = 9.8

var atacando = false

#Animaciones del personaje normal
func anim_normal_idle():
	anim_sprite.play("Normal-Idle")
func anim_normal_correr():
	anim_sprite.play("Normal-Run")
func anim_normal_hit():
	anim_sprite.play("Normal-Hit")
func anim_normal_dash():
	anim_sprite.play("Normal-Dash")
func anim_normal_death():
	anim_sprite.play("Normal-Death")

#Animaciones del personaje con pistola
func anim_pistol_idle():
	anim_sprite.play("Pistol-Idle")
func anim_pistol_correr():
	anim_sprite.play("Pistol-Run")
func anim_pistol_shoot():
	anim_sprite.play("Pistol-Shoot")
func anim_pistol_hit():
	anim_sprite.play("Pistol-Hit")
func anim_pistol_dash():
	anim_sprite.play("Pistol-Dash")

#Animaciones del personaje con espada
func anim_sword_idle():
	anim_sprite.play("Sword-Idle")
func anim_sword_correr():
	anim_sprite.play("Sword-Run")
func anim_sword_hit():
	anim_sprite.play("Sword-Hit")
func anim_sword_combo():
	anim_sprite.play("Sword-Combo")
func anim_sword_dash():
	anim_sprite.play("Sword-Dash")

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	
	velocity.y -= GRAVEDAD * delta
	velocity.x = Input.get_axis("la_A", "la_D") * speed
	velocity.z = Input.get_axis("la_W", "la_S") * speed
	
	var moviendo = Vector3(velocity.x, 0, velocity.z) != Vector3.ZERO
	
	if moviendo:
		if atacando:
			anim_sword_correr()
		else:
			anim_normal_correr()
	else:
		anim_normal_idle()
	
	var dir = Vector3(velocity.x, 0, velocity.z)
	if dir != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 0.15)
		
	if Input.is_action_just_pressed("click_izq") and atacando:
		atacar()
	if Input.is_action_just_released("click_izq") and !atacando:
		cancelar_atacar()

func atacar():
	atacando = true
	anim_player.play("Sword-Combo")
func cancelar_atacar():
	atacando = false
	
