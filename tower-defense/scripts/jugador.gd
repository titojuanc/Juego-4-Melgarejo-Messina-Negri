extends CharacterBody3D

@onready var attack_area = $AttackArea
@onready var anim_player = $AnimationPlayer
@onready var anim_sprite = $AnimatedSprite3D
@onready var camara = get_viewport().get_camera_3d()

@export var speed = 10
@export var vida = 100
@export var danio = 30

const GRAVEDAD = 9.8

var atacando = false
var combo_step = 0
var camara_offset = Vector3(0, 4, 8)
var enemigos_en_rango = []

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
	anim_player.play("Sword-Combo")
func amim_sword_att1():
	anim_player.play("Sword-Att1")
func anim_sword_att2():
	anim_player.play("Sword-Att2")
func anim_sword_att3():
	anim_player.play("Sword-Att3")
func anim_sword_dash():
	anim_sprite.play("Sword-Dash")

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVEDAD * delta
	else:
		velocity.y = 0
	
	velocity.x = Input.get_axis("la_A", "la_D") * speed
	velocity.z = Input.get_axis("la_W", "la_S") * speed
	
	var moviendo = Vector3(velocity.x, 0, velocity.z) != Vector3.ZERO
	if !atacando:
		if moviendo:
			anim_normal_correr()
		else:
			anim_normal_idle()
	
	if Input.is_action_just_pressed("click_izq") and !atacando:
		atacar()
	
	move_and_slide()
	camara.global_position = global_position + camara_offset
	apuntar_con_mouse()
	
func atacar():
	atacando = true
	combo_step += 1
	if combo_step > 3:
		combo_step = 1
	match combo_step:
		1: anim_player.play("Sword-Att1")
		2: anim_player.play("Sword-Att2")
		3: anim_player.play("Sword-Att3")

func cancelar_atacar():
	atacando = false
	combo_step = 0
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name in ["Sword-Att1", "Sword-Att2", "Sword-Att3"]:
		if Input.is_action_pressed("click_izq"):
			atacar()
		else:
			cancelar_atacar()

func apuntar_con_mouse():
	var mouse_pos = get_viewport().get_mouse_position()
	var origen = camara.project_ray_origin(mouse_pos)
	var direccion = camara.project_ray_normal(mouse_pos)
	var plano = Plane(Vector3.UP, global_position.y)
	var punto = plano.intersects_ray(origen, direccion)
	
	if punto:
		var dir = (punto - global_position)
		dir.y = 0
		if dir.x > 0:
			anim_sprite.flip_h = false
		elif dir.x < 0:
			anim_sprite.flip_h = true
		rotation.y = atan2(dir.x, dir.z) - PI / 2
		anim_sprite.rotation.y = -rotation.y

func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemigo"):
		enemigos_en_rango.append(body)

func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Enemigo"):
		enemigos_en_rango.erase(body)

func pegar():
	for e in enemigos_en_rango:
		e.vida -= danio
		print("Pegué: " , danio, " a: ", e)
