extends CharacterBody3D

#Mision
var mision_madera = 20
var mision_piedra = 20
var esperando_respuesta_mision = false
#

@onready var deteccion_enemigos = $DeteccionEnemigos
@onready var interaccion_area = $InteractionArea

var menu_scene = preload("res://scenes/HUD_npc.tscn")
var bala_scene = preload("res://scenes/Bala.tscn")
var menu_instancia: CanvasLayer = null

#Ataque
var enemigo_objetivo: Node3D = null
var enemigos_cercanos = []
var cooldown_ataque = 0.0
var tiempo_entre_ataques = 1.5
@export var danio_npc = 10
#

@export var nombre_npc = "Sofia"

enum Estado {
	DESCONOCIDO,
	MISION_ACTIVA,
	RECLUTABLE,
	ACOMPAÑANDO,
	EN_BASE_IDLE,
	RECOLECTANDO,
	DEFENDIENDO,
	EN_TORRE
}
var estado = Estado.DESCONOCIDO
var menu_abierto = false
var opciones = []
var opcion_seleccionada = 0
var jugador_cerca = false
var jugador: Node3D = null
var velocidad = 4.0
var en_dialogo = false

#Recoleccion
var inv_madera: int = 0
var inv_piedra: int = 0
var inv_metal: int = 0
var recurso_objetivo: Node3D = null
var cooldown_recoleccion = 0.0
var tiempo_entre_golpes = 1.0
@export var radio_recoleccion: float = 20.0
var centro_base: Node3D = null
var _radio_deteccion_original: float = -1.0
#

func _ready() -> void:
	jugador = get_tree().get_first_node_in_group("Jugador")
	centro_base = get_tree().get_first_node_in_group("CentroBase")

func _physics_process(delta: float) -> void:
	if centro_base == null:
		centro_base = get_tree().get_first_node_in_group("CentroBase")
		if centro_base != null:
			print("CentroBase encontrado: ", centro_base.name)
	if menu_abierto and menu_instancia:
		actualizar_posicion_menu()
	cooldown_ataque -= delta
	if menu_abierto:
		return
	match estado:
		Estado.ACOMPAÑANDO:
			if enemigos_cercanos.size() > 0:
				enemigo_objetivo = enemigos_cercanos[0]
				atacar_enemigo(delta)
			else:
				enemigo_objetivo = null
				seguir_jugador()
		Estado.RECOLECTANDO:
			cooldown_recoleccion -= delta
			recolectar()
		Estado.EN_TORRE:
			if enemigos_cercanos.size() > 0:
				enemigo_objetivo = enemigos_cercanos[0]
				atacar_desde_torre(delta)
			else:
				enemigo_objetivo = null
	
func actualizar_posicion_menu() -> void:
	var camara = get_viewport().get_camera_3d()
	if camara:
		var pos_mundo = global_position + Vector3(0, 2, 0)
		var pos_pantalla = camara.unproject_position(pos_mundo)
		menu_instancia.actualizar_posicion(pos_pantalla)
	
func _input(event: InputEvent) -> void:
	if !jugador_cerca:
		return
	if event.is_action_pressed("interactuar"):
		if !menu_abierto:
			abrir_menu()
		elif en_dialogo:
			pass
		else:
			confirmar_opcion()
	if menu_abierto and !en_dialogo:
		if event.is_action_pressed("la_S"):
			opcion_seleccionada = (opcion_seleccionada + 1) % opciones.size()
			actualizar_opciones_label()
		if event.is_action_pressed("la_W"):
			opcion_seleccionada = (opcion_seleccionada - 1 + opciones.size()) % opciones.size()
			actualizar_opciones_label()
		if event.is_action_pressed("ui_cancel"):
			cerrar_menu()
	
func abrir_menu() -> void:
	menu_abierto = true
	menu_instancia = menu_scene.instantiate()
	get_tree().root.add_child(menu_instancia)
	menu_instancia.dialogo_label.visible = false
	menu_instancia.set_titulo(nombre_npc)
	opciones = get_opciones_segun_estado()
	opcion_seleccionada = 0
	actualizar_opciones_label()
	
	if jugador:
		jugador.movimiento_bloqueado = true
	
func cerrar_menu() -> void:
	menu_abierto = false
	if menu_instancia:
		menu_instancia.queue_free()
		menu_instancia = null
		
	if jugador:
		jugador.movimiento_bloqueado = false
	
func actualizar_opciones_label() -> void:
	var texto = ""
	for i in opciones.size():
		if i == opcion_seleccionada:
			texto += "> " + opciones[i] + "\n"
		else:
			texto += "  " + opciones[i] + "\n"
	menu_instancia.set_opciones_texto(texto)
	
func confirmar_opcion() -> void:
	var opcion = opciones[opcion_seleccionada]
	print("Opción elegida: ", opcion, " (índice ", opcion_seleccionada, ")")
	match opcion:
		"Hablar":
			hablar()
		"Ver misión":
			ver_mision()
		"Reclutar":
			if hay_base():
				cambiar_estado(Estado.ACOMPAÑANDO)
				cerrar_menu()
			else:
				en_dialogo = true
				menu_instancia.mostrar_dialogo("Necesitás construir una base primero.")
				if !menu_instancia.dialogo_terminado.is_connected(_on_dialogo_terminado):
					menu_instancia.dialogo_terminado.connect(_on_dialogo_terminado)
		"Acompañarme":
			cambiar_estado(Estado.ACOMPAÑANDO)
			cerrar_menu()
		"Cancelar":
			cambiar_estado(Estado.EN_BASE_IDLE)
			cerrar_menu()
		"Ir a la base":
			cambiar_estado(Estado.EN_BASE_IDLE)
			cerrar_menu()
		"Recolectar recursos":
			cambiar_estado(Estado.RECOLECTANDO)
			cerrar_menu()
		"Defender base":
			cambiar_estado(Estado.DEFENDIENDO)
			cerrar_menu()
		"Asignar a torre":
			cambiar_estado(Estado.EN_TORRE)
			cerrar_menu()
		"Cancelar orden":
			cambiar_estado(Estado.EN_BASE_IDLE)
			cerrar_menu()
		"Aceptar":
			esperando_respuesta_mision = false
			cambiar_estado(Estado.MISION_ACTIVA)
			cerrar_menu()
		"Rechazar":
			esperando_respuesta_mision = false
			cerrar_menu()
		"Ver inventario":
			ver_inventario()
		_:
			print("Opción no manejada: ", opcion)
			cerrar_menu()
	
func get_opciones_segun_estado() -> Array:
	match estado:
		Estado.DESCONOCIDO:
			return ["Hablar"]
		Estado.MISION_ACTIVA:
			return ["Hablar", "Ver misión"]
		Estado.RECLUTABLE:
			return ["Reclutar"]
		Estado.ACOMPAÑANDO:
			return ["Ir a la base", "Cancelar", "Ver inventario"]
		Estado.EN_BASE_IDLE:
			return ["Acompañarme", "Recolectar recursos", "Defender base", "Asignar a torre", "Ver inventario"]
		Estado.RECOLECTANDO, Estado.DEFENDIENDO, Estado.EN_TORRE:
			return ["Ver inventario", "Cancelar orden"]
	return []
	
func cambiar_estado(nuevo_estado: Estado) -> void:
	estado = nuevo_estado
	var es_aliado=estado in [Estado.ACOMPAÑANDO,Estado.EN_BASE_IDLE,Estado.RECOLECTANDO,Estado.DEFENDIENDO,Estado.EN_TORRE]
	if es_aliado:
		if not is_in_group("Aliado"):
			add_to_group("Aliado")
	else:
		if is_in_group("Aliado"):
			remove_from_group("Aliado")

func asignar_a_torre(torre:Node)->void:
	cambiar_estado(Estado.EN_TORRE)
	global_position=torre.get_spawn_position()
	var col=deteccion_enemigos.get_node("CollisionShape3D")
	var shape=col.shape.duplicate() as SphereShape3D
	_radio_deteccion_original=shape.radius
	shape.radius=30.0
	col.shape=shape

func desasignar_torre()->void:
	if _radio_deteccion_original>0.0:
		var col=deteccion_enemigos.get_node("CollisionShape3D")
		var shape=col.shape.duplicate() as SphereShape3D
		shape.radius=_radio_deteccion_original
		col.shape=shape
		_radio_deteccion_original=-1.0
	cambiar_estado(Estado.EN_BASE_IDLE)
	
func hablar() -> void:
	en_dialogo = true
	var texto = ""
	match estado:
		Estado.DESCONOCIDO:
			texto = "Hola, soy Sofia. Llevo días atrapada aquí...\n¿Podrías traerme %d de madera y %d de piedra?" % [mision_madera, mision_piedra]
			esperando_respuesta_mision = true
		Estado.MISION_ACTIVA:
			var falta_madera = max(0, mision_madera - jugador.madera)
			var falta_piedra = max(0, mision_piedra - jugador.piedra)
			if falta_madera == 0 and falta_piedra == 0:
				texto = "¡Lo lograste! Gracias por traerme los recursos."
				cambiar_estado(Estado.RECLUTABLE)
			else:
				texto = "Aún te faltan %d de madera y %d de piedra." % [falta_madera, falta_piedra]
		Estado.RECLUTABLE:
			texto = "¡Gracias! Ya puedes reclutarme."
		
	menu_instancia.mostrar_dialogo(texto)
	if !menu_instancia.dialogo_terminado.is_connected(_on_dialogo_terminado):
		menu_instancia.dialogo_terminado.connect(_on_dialogo_terminado)
	
func ver_mision() -> void:
	hablar()
	
func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_cerca = true
	
func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_cerca = false
		cerrar_menu()
	
func asignar_edificio(edificio: Node) -> void:
	cambiar_estado(Estado.EN_BASE_IDLE)
	global_position = edificio.get_spawn_position()
	
func desasignar_edificio() -> void:
	cambiar_estado(Estado.ACOMPAÑANDO)

func _on_dialogo_terminado() -> void:
	en_dialogo = false
	if esperando_respuesta_mision:
		opciones = ["Aceptar", "Rechazar"]
	elif estado == Estado.RECOLECTANDO:
		opciones = ["Recoger recursos", "Cancelar orden"]
	else:
		opciones = get_opciones_segun_estado()
	opcion_seleccionada = 0
	actualizar_opciones_label()
	
func get_texto_opciones() -> String:
	var texto = ""
	for i in opciones.size():
		if i == opcion_seleccionada:
			texto += "> " + opciones[i] + "\n"
		else:
			texto += "  " + opciones[i] + "\n"
	return texto
	
func seguir_jugador() -> void:
	if jugador:
		var dir = (jugador.global_position - global_position)
		dir.y = 0
		if dir.length() > 1.5:
			velocity = dir.normalized() * velocidad
		else:
			velocity = Vector3.ZERO
		move_and_slide()
	
func atacar_enemigo(delta: float) -> void:
	if enemigo_objetivo == null:
		return
	var dir = (enemigo_objetivo.global_position - global_position)
	dir.y = 0
	var distancia = dir.length()
	if distancia > 1.5:
		velocity = dir.normalized() * velocidad
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		if enemigo_objetivo.is_in_group("Enemigo") and cooldown_ataque <= 0:
			if is_instance_valid(enemigo_objetivo):
				cooldown_ataque = tiempo_entre_ataques
				# anim_player.play("Attack")
				enemigo_objetivo.recibir_danio(danio_npc) #Esto en el animation player va donde tenga q ir
				# await anim_player.animation_finished
			else:
				enemigos_cercanos.erase(enemigo_objetivo)
				enemigo_objetivo = null
	
func atacar_desde_torre(delta: float) -> void:
	if enemigo_objetivo == null:
		return
	if not is_instance_valid(enemigo_objetivo):
		enemigos_cercanos.erase(enemigo_objetivo)
		enemigo_objetivo = null
		return
	velocity = Vector3.ZERO
	move_and_slide()
	if enemigo_objetivo.is_in_group("Enemigo") and cooldown_ataque <= 0:
		cooldown_ataque = tiempo_entre_ataques
		var bala = bala_scene.instantiate()
		get_tree().root.add_child(bala)
		var origen = global_position + Vector3(0, 0.5, 0)
		bala.global_position = origen
		bala.danio = 17
		var distancia = origen.distance_to(enemigo_objetivo.global_position)
		var velocidad_bala: float = bala.speed
		var tiempo_estimado = distancia / velocidad_bala
		var pos_predicha = enemigo_objetivo.global_position + Vector3(enemigo_objetivo.velocity.x, 0, enemigo_objetivo.velocity.z) * tiempo_estimado
		var dir = (pos_predicha - origen)
		bala.direccion = dir.normalized()

func recolectar() -> void:
	if recurso_objetivo == null or !is_instance_valid(recurso_objetivo):
		buscar_recurso()
		return
		
	# Verificar que sea un Recurso y no un StaticBody3D
	if not recurso_objetivo is Recurso:
		print("recurso_objetivo no es Recurso, es: ", recurso_objetivo.get_class())
		recurso_objetivo = null
		return
		
	var dir = (recurso_objetivo.global_position - global_position)
	dir.y = 0
	var distancia = dir.length()
	if distancia > 1.5:
		velocity = dir.normalized() * velocidad
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		if cooldown_recoleccion <= 0:
			cooldown_recoleccion = tiempo_entre_golpes
			#anim_player.play("Recolectar")
			recurso_objetivo.recibir_golpe(self) #esto iria el en animplayer
			#await anim_player.animation_finished
	
func buscar_recurso() -> void:
	var recursos = get_tree().get_nodes_in_group("RecursoDestruible")
	if recursos.size() == 0:
		return
	var mas_cercano = null
	var distancia_min = INF
	for r in recursos:
		if not r is Recurso:
			continue
		if centro_base != null:
			var dist_base = centro_base.global_position.distance_to(r.global_position)
			if dist_base > radio_recoleccion:
				continue
		var d = global_position.distance_to(r.global_position)
		if d < distancia_min:
			distancia_min = d
			mas_cercano = r
	recurso_objetivo = mas_cercano
	
func _on_deteccion_enemigos_body_entered(body: Node3D) -> void:
	print("DeteccionEnemigos detectó: ", body.name)
	if body.is_in_group("Enemigo"):
		enemigos_cercanos.append(body)
		print("Enemigo agregado, total: ", enemigos_cercanos.size())
	
func _on_deteccion_enemigos_body_exited(body: Node3D) -> void:
	if body.is_in_group("Enemigo"):
		enemigos_cercanos.erase(body)
	
func ver_inventario() -> void:
	en_dialogo = true
	var texto = "Inventario de %s:\nMadera: %d\nPiedra: %d\nMetal: %d" % [nombre_npc, inv_madera, inv_piedra, inv_metal]
	menu_instancia.mostrar_dialogo(texto)
	if !menu_instancia.dialogo_terminado.is_connected(_on_dialogo_terminado):
		menu_instancia.dialogo_terminado.connect(_on_dialogo_terminado)
	
func hay_base() -> bool:
	return get_tree().get_first_node_in_group("Base") != null
