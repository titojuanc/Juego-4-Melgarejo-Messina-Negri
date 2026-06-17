extends CharacterBody3D

@onready var interaccion_area = $InteractionArea
var menu_scene = preload("res://scenes/HUD_npc.tscn")
var menu_instancia: CanvasLayer = null

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

func _physics_process(delta: float) -> void:
	if menu_abierto and menu_instancia:
		actualizar_posicion_menu()
	
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
		else:
			confirmar_opcion()
	if menu_abierto:
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
	
	menu_instancia.set_titulo(nombre_npc)
	opciones = get_opciones_segun_estado()
	opcion_seleccionada = 0
	actualizar_opciones_label()
	
	var jugador = get_tree().get_first_node_in_group("Jugador")
	if jugador:
		jugador.movimiento_bloqueado = true
	
func cerrar_menu() -> void:
	menu_abierto = false
	if menu_instancia:
		menu_instancia.queue_free()
		menu_instancia = null
		
	var jugador = get_tree().get_first_node_in_group("Jugador")
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
			cambiar_estado(Estado.ACOMPAÑANDO)
			cerrar_menu()
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
			return ["Ir a la base", "Cancelar"]
		Estado.EN_BASE_IDLE:
			return ["Acompañarme", "Recolectar recursos", "Defender base", "Asignar a torre"]
		Estado.RECOLECTANDO, Estado.DEFENDIENDO, Estado.EN_TORRE:
			return ["Cancelar orden"]
	return []
	
func cambiar_estado(nuevo_estado: Estado) -> void:
	estado = nuevo_estado
	
func hablar() -> void:
	pass
	
func ver_mision():
	pass
	
func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_cerca = true
	
func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_cerca = false
		cerrar_menu()
