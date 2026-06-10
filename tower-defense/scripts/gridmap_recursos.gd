extends GridMap

#configuración del spawneo
@export var arbol_scene: PackedScene
# Voy a ir agregando más por cada recurso. Creo igual que podría usar un resource para estos valores en vez de mil variables.
@export var min_arboles_por_tile: int = 2
@export var max_arboles_por_tile: int = 3
@export var separacion_minima: float = 8.0
@export var borde_tile: float = 3.0
@export var altura_spawn: float = 1.0
@export var variacion_escala_min: float = 0.9
@export var variacion_escala_max: float = 1.15
@export var regenerar_en_ready: bool = true

#número random
var aleatorizador = RandomNumberGenerator.new()

func _ready() -> void:
	if regenerar_en_ready:
		generar_recursos()

#valida los recursos y los spawnea uno a uno en la celda que pueda (las de hierba)
func generar_recursos() -> void:
	if mesh_library == null:
		#empecé a usar esto para darme cuenta más fácil cuando se me olvida algo por distraído
		push_warning("No hay MeshLibrary.")
		return
	var contenedor = _asegurar_contenedor_recursos()
	_limpiar_contenedor(contenedor)
	var item_hierba = _buscar_item_meshlib("TileHierba")
	if item_hierba == -1:
		push_warning("No se encontro el item 'TileHierba' en el MeshLibrary.")
		return
	var celdas_usadas: Array[Vector3i] = get_used_cells()
	for tile in celdas_usadas:
		if get_cell_item(tile) != item_hierba:
			continue
		_spawnear_arboles_en_celda(tile, contenedor)

func _buscar_item_meshlib(nombre_item: String) -> int:
	for id in mesh_library.get_item_list():
		if mesh_library.get_item_name(id) == nombre_item:
			return id
	return -1

func _asegurar_contenedor_recursos() -> Node3D:
	var contenedor = get_node_or_null("RecursosSpawn") as Node3D
	if contenedor == null:
		contenedor = Node3D.new()
		contenedor.name = "RecursosSpawn"
		add_child(contenedor)
	return contenedor

func _limpiar_contenedor(contenedor: Node3D) -> void:
	for hijo in contenedor.get_children():
		hijo.queue_free()

func _spawnear_arboles_en_celda(tile: Vector3i, contenedor: Node3D) -> void:
	var cantidad = aleatorizador.randi_range(min_arboles_por_tile, max_arboles_por_tile)
	var posiciones_locales: Array[Vector2] = [] #los árboles que ya puso
	var max_x = (cell_size.x * 0.5) - borde_tile
	var max_z = (cell_size.z * 0.5) - borde_tile
	var centro_celda = map_to_local(tile)
	for i in range(cantidad):
		var offset = _buscar_offset_valido(posiciones_locales, max_x, max_z)
		if offset == Vector2.INF:
			continue
		posiciones_locales.append(offset)
		var arbol = arbol_scene.instantiate() as Node3D
		if arbol == null:
			continue
		arbol.position = centro_celda + Vector3(offset.x, altura_spawn, offset.y)
		arbol.rotation.y = aleatorizador.randf_range(0.0, TAU)
		var escala = aleatorizador.randf_range(variacion_escala_min, variacion_escala_max)
		arbol.scale = Vector3.ONE * escala
		contenedor.add_child(arbol)

#busca una posición válida para el nuevo arbol
func _buscar_offset_valido(posiciones_existentes: Array[Vector2], max_x: float, max_z: float) -> Vector2:
	var intentos = 17 #podrían ser más, le puse mi número de la suerte
	for i in range(intentos):
		var candidato = Vector2(
			aleatorizador.randf_range(-max_x, max_x),
			aleatorizador.randf_range(-max_z, max_z)
		)
		var valido = true
		for posicion in posiciones_existentes:
			if posicion.distance_to(candidato) < separacion_minima:
				valido = false
				break
		if valido:
			return candidato
	return Vector2.INF
