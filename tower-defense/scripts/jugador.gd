extends CharacterBody3D

@onready var attack_area = $AttackArea
@onready var anim_player = $AnimationPlayer
@onready var anim_sprite = $AnimatedSprite3D
@onready var camara = get_viewport().get_camera_3d()
@onready var linea_area = $LineaApuntado
@onready var linea_mesh = $LineaApuntado/MeshInstance3D
@export var bala_scene: PackedScene
@export var controla_camara:bool = true

@export var speed: float = 100
@export var vida_max: int = 100
var vida: int
@export var danio: int = 30
var balas: int
@export var balas_max: int = 100

enum Modo {ESPADA, PISTOLA}
const GRAVEDAD = 9.8

var atacando = false
var combo_step = 0
var camara_offset = Vector3(0, 18, 10)
var enemigos_en_rango = []
var recursos_en_rango = []
var modo
var mat_linea: StandardMaterial3D
var enemigo_en_linea = false
var cooldown_disparo = false
var madera: int = 0
var piedra: int = 0
var metal: int = 0
# Inventario de items especiales
var llaves: int = 0
var movimiento_bloqueado = false
var muerto = false

@export var gridmap:GridMap
const PESCA_TILE_ID:=8
var pesca_pool:Array[String]=["llave","pez","pez","pez","pez"]
var _pesca_instancia:CanvasLayer=null
var _pesca_escena:=preload("res://scenes/Pesca.tscn")
var tiene_caña:bool=false

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
	anim_player.play("Pistol-Shoot")
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
	mat_linea = linea_mesh.get_surface_override_material(0)
	vida = vida_max
	balas = balas_max
	if gridmap == null:
		var gridmap_grupo = get_tree().get_first_node_in_group("GridMap")
		if gridmap_grupo is GridMap:
			gridmap = gridmap_grupo
		else:
			var gridmap_nodo = get_parent().get_node_or_null("GridMap")
			if gridmap_nodo is GridMap:
				gridmap = gridmap_nodo
	if Gamestate.has_method("cargar_en_jugador"):
		Gamestate.cargar_en_jugador(self)
	print("material: ", mat_linea)
	
func _physics_process(delta: float) -> void:
	if muerto:
		return
	if Input.is_action_just_pressed("interactuar") and not movimiento_bloqueado and _pesca_instancia==null and _puede_pescar():
		_abrir_pesca()
		return
	if movimiento_bloqueado:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y -= GRAVEDAD * delta
	else:
		velocity.y = 0
	
	velocity.x = Input.get_axis("la_A", "la_D") * speed
	velocity.z = Input.get_axis("la_W", "la_S") * speed
	
	if modo == Modo.ESPADA:
		if Input.is_action_just_pressed("click_izq") and !atacando:
			atacar()
	elif modo == Modo.PISTOLA:
		if Input.is_action_just_pressed("click_izq"):
			disparar()
	
	if Input.is_action_pressed("click_der") and !atacando:
		modo = Modo.PISTOLA
		linea_area.monitoring = true
	else:
		modo = Modo.ESPADA
		linea_area.monitoring = false
	
	var moviendo = Vector3(velocity.x, 0, velocity.z) != Vector3.ZERO
	if !atacando:
		if modo == Modo.PISTOLA:
			if moviendo:
				anim_pistol_correr()
			else:
				anim_pistol_idle()
		else:
			if moviendo:
				anim_normal_correr()
			else:
				anim_normal_idle()
				
	
	move_and_slide()
	if controla_camara:
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
	elif anim_name == "Pistol-Shoot":
		cooldown_disparo = false

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
		
		if modo == Modo.PISTOLA:
			linea_area.visible = true
			var dir_xz = Vector3(dir.x, 0, dir.z)
			var dir_norm = dir_xz.normalized()
			linea_area.global_rotation = Vector3(0, atan2(dir.x, dir.z), 0)
			linea_area.global_position = global_position + dir_norm / 2
			if enemigo_en_linea:
				mat_linea.albedo_color = Color(1, 0, 0, 0.3)
			else:
				mat_linea.albedo_color = Color(1, 1, 1, 0.3)
		else:
			linea_area.visible = false

func _on_attack_area_body_entered(body: Node3D) -> void:
	print("AttackArea detectó: ", body.name, " grupos: ", body.get_groups())
	if body.is_in_group("Enemigo"):
		enemigos_en_rango.append(body)
	if body.is_in_group("RecursoColision"):
		print("Recurso en rango agregado: ", body.get_parent().name)
		recursos_en_rango.append(body.get_parent())

func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Enemigo"):
		enemigos_en_rango.erase(body)
	if body.is_in_group("RecursoColision"):
		recursos_en_rango.erase(body.get_parent())

func pegar():
	print("pegar llamado, recursos en rango: ", recursos_en_rango.size())
	for e in enemigos_en_rango:
		e.recibir_danio(danio)
	for r in recursos_en_rango:
		print("golpeando recurso: ", r.name)
		r.recibir_golpe()

func disparar():
	if cooldown_disparo:
		return
	cooldown_disparo = true
	anim_player.play("Pistol-Shoot")
	print("disparar hacia: ", get_punto_apuntado())

func spawnear_bala():
	var punto = get_punto_apuntado()
	if punto == null:
		return
	var bala = bala_scene.instantiate()
	get_tree().root.add_child(bala)
	bala.global_position = linea_area.global_position
	var dir = (punto - global_position)
	dir.y = 0
	bala.direccion = dir.normalized()

func get_punto_apuntado():
	var mouse_pos = get_viewport().get_mouse_position()
	var origen = camara.project_ray_origin(mouse_pos)
	var direccion = camara.project_ray_normal(mouse_pos)
	var plano = Plane(Vector3.UP, global_position.y)
	return plano.intersects_ray(origen, direccion)

func _on_linea_apuntado_body_entered(body: Node3D) -> void:
	print("linea detectó: ", body.name)
	if body.is_in_group("Enemigo"):
		enemigo_en_linea = true

func _on_linea_apuntado_body_exited(body: Node3D) -> void:
	print("linea detectó: ", body.name)
	if body.is_in_group("Enemigo"):
		enemigo_en_linea = false
	
func restar_vida(danio):
	vida -= danio
	verificar_muerte()
	
func verificar_muerte():
	if vida <= 0:
		morir()
		
func morir():
	muerto = true
	anim_normal_death()
	
func _on_animated_sprite_3d_animation_finished() -> void:
	if anim_sprite.animation == "Normal-Death":
		queue_free()
		
func gastar_madera(cantidad: int) -> bool:
	if madera < cantidad:
		return false
	madera -= cantidad
	return true

# --- Inventario de items ---

# Llamar este método para darle una llave al jugador
# (desde la escena Llave, desde la lógica de pesca, o desde un NPC)
func agregar_llave() -> void:
	llaves += 1

func agregar_cania() -> void:
	tiene_caña = true
	if Gamestate.has_method("guardar_desde_jugador"):
		Gamestate.guardar_desde_jugador(self)

# Llamar este método cuando un NPC pida la llave para completar su misión
# Devuelve true si tenía al menos una y la consume, false si no tenía
func gastar_llave() -> bool:
	if llaves <= 0:
		return false
	llaves -= 1
	return true

func _puede_pescar()->bool:
	if gridmap==null or pesca_pool.is_empty() or not tiene_caña:
		return false
	var pos_local:=gridmap.to_local(global_position)
	var celda:=gridmap.local_to_map(pos_local)
	for dy_off in [0,-1]:
		for offset in [Vector3i(1,0,0),Vector3i(-1,0,0),Vector3i(0,0,1),Vector3i(0,0,-1)]:
			if gridmap.get_cell_item(Vector3i(celda.x+offset.x,celda.y+dy_off,celda.z+offset.z))==PESCA_TILE_ID:
				return true
	return false

func _abrir_pesca()->void:
	_pesca_instancia=_pesca_escena.instantiate()
	_pesca_instancia.test_mode=false
	get_tree().root.add_child(_pesca_instancia)
	_pesca_instancia.pesca_cerrada.connect(_on_pesca_cerrada)
	_pesca_instancia.abrir(pesca_pool.duplicate())

func _on_pesca_cerrada(_item:String)->void:
	if is_instance_valid(_pesca_instancia):
		pesca_pool=_pesca_instancia.pool_restante.duplicate()
		_pesca_instancia.queue_free()
	_pesca_instancia=null
