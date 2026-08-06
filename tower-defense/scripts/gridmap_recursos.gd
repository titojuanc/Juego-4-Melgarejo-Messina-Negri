extends GridMap

#escenas de recursos
const escena_arbol: PackedScene = preload("res://scenes/Arbol.tscn")
const escena_piedra: PackedScene = preload("res://scenes/Piedra.tscn")

#configuración general
@export var borde_tile: float = 3.0
@export var altura_spawn: float = 1.0
@export var regenerar_en_ready: bool = true

#número random
var aleatorizador = RandomNumberGenerator.new()

#configuraciones fijas de cada recurso
var recursos: Array[RecursoSpawnConfig] = []

func _init() -> void:
	var config_arbol = RecursoSpawnConfig.new()
	config_arbol.escena = escena_arbol
	config_arbol.nombre_tile = "TileHierba"
	config_arbol.min_por_tile = 6
	config_arbol.max_por_tile = 10
	config_arbol.separacion_minima = 8.0
	config_arbol.variacion_escala_min = 0.9
	config_arbol.variacion_escala_max = 1.15

	var config_piedra = RecursoSpawnConfig.new()
	config_piedra.escena = escena_piedra
	config_piedra.nombre_tile = "TilePiedra"
	config_piedra.min_por_tile = 7
	config_piedra.max_por_tile = 14
	config_piedra.separacion_minima = 5.0
	config_piedra.variacion_escala_min = 0.85
	config_piedra.variacion_escala_max = 1.2

	recursos = [config_arbol, config_piedra]

func _ready() -> void:
	if regenerar_en_ready:
		generar_recursos()

#valida los recursos y los spawnea uno a uno en la celda que corresponda
func generar_recursos() -> void:
	if mesh_library == null:
		push_warning("No hay MeshLibrary.")
		return
	var contenedor = _asegurar_contenedor_recursos()
	_limpiar_contenedor(contenedor)
	var celdas_usadas: Array[Vector3i] = get_used_cells()
	for config in recursos:
		if config == null or config.escena == null:
			push_warning("Un RecursoSpawnConfig está vacío o sin escena.")
			continue
		var item_id = _buscar_item_meshlib(config.nombre_tile)
		if item_id == -1:
			push_warning("No se encontró el item '%s' en el MeshLibrary." % config.nombre_tile)
			continue
		for tile in celdas_usadas:
			if get_cell_item(tile) != item_id:
				continue
			_spawnear_recurso_en_celda(tile, contenedor, config)

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

func _spawnear_recurso_en_celda(tile: Vector3i, contenedor: Node3D, config: RecursoSpawnConfig) -> void:
	var cantidad = aleatorizador.randi_range(config.min_por_tile, config.max_por_tile)
	var posiciones_locales: Array[Vector2] = []
	var max_x = (cell_size.x * 0.5) - borde_tile
	var max_z = (cell_size.z * 0.5) - borde_tile
	var centro_celda = map_to_local(tile)
	for i in range(cantidad):
		var offset = _buscar_offset_valido(posiciones_locales, max_x, max_z, config.separacion_minima)
		if offset == Vector2.INF:
			continue
		posiciones_locales.append(offset)
		var instancia = config.escena.instantiate() as Node3D
		if instancia == null:
			continue
		instancia.position = centro_celda + Vector3(offset.x, altura_spawn, offset.y)
		instancia.rotation.y = aleatorizador.randf_range(0.0, TAU)
		var escala = aleatorizador.randf_range(config.variacion_escala_min, config.variacion_escala_max)
		instancia.scale = Vector3.ONE * escala
		contenedor.add_child(instancia)

#busca una posición válida para el nuevo recurso
func _buscar_offset_valido(posiciones_existentes: Array[Vector2], max_x: float, max_z: float, separacion: float) -> Vector2:
	var intentos = 17 #podrían ser más, le puse mi número de la suerte
	for i in range(intentos):
		var candidato = Vector2(
			aleatorizador.randf_range(-max_x, max_x),
			aleatorizador.randf_range(-max_z, max_z)
		)
		var valido = true
		for posicion in posiciones_existentes:
			if posicion.distance_to(candidato) < separacion:
				valido = false
				break
		if valido:
			return candidato
	return Vector2.INF
