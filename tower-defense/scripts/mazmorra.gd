extends Node3D

signal jugador_cambio_tile(centro_mundo: Vector3)

@export var grilla: GridMap
@export var jugador: Node3D
@export var id_tile_piso: int = 0
@export var tamanio_grilla: int = 4
@export var escena_zombie: PackedScene = preload("res://scenes/Zombie.tscn")
@export var zombies_por_tile: int = 1

var rng = RandomNumberGenerator.new()
var mapa: Array = []
var _celda_anterior: Vector3i = Vector3i(-9999, -9999, -9999)


func _ready() -> void:
	rng.randomize()
	_inicializar_mapa()
	_tallar_camino(Vector2i(0, 0), Vector2i(tamanio_grilla - 1, tamanio_grilla - 1))
	_pintar()


func _inicializar_mapa() -> void:
	mapa = []
	for f in range(tamanio_grilla):
		mapa.append([])
		for c in range(tamanio_grilla):
			mapa[f].append(false)


func _tallar_camino(desde: Vector2i, hasta: Vector2i) -> void:
	var actual = desde
	mapa[actual.y][actual.x] = true

	while actual != hasta:
		var opciones: Array[Vector2i] = []
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var siguiente = actual + d
			if siguiente.x >= 0 and siguiente.x < tamanio_grilla and siguiente.y >= 0 and siguiente.y < tamanio_grilla:
				opciones.append(siguiente)

		var preferidas: Array[Vector2i] = opciones.filter(func(v): return v.x <= hasta.x and v.y <= hasta.y)
		var candidatas = preferidas if not preferidas.is_empty() and rng.randf() < 0.75 else opciones

		actual = candidatas[rng.randi() % candidatas.size()]
		mapa[actual.y][actual.x] = true

	mapa[hasta.y][hasta.x] = true


func _process(_delta: float) -> void:
	if jugador == null:
		return
	var celda_actual = grilla.local_to_map(grilla.to_local(jugador.global_position))
	celda_actual.y = 0  # ignorar variación vertical
	if celda_actual != _celda_anterior:
		_celda_anterior = celda_actual
		var centro = grilla.to_global(grilla.map_to_local(celda_actual))
		emit_signal("jugador_cambio_tile", centro)


func _pintar() -> void:
	grilla.clear()
	# Eliminar zombies previos
	for hijo in get_children():
		if hijo.is_in_group("zombies"):
			hijo.queue_free()

	for f in range(tamanio_grilla):
		for c in range(tamanio_grilla):
			if mapa[f][c]:
				var celda = Vector3i(c, 0, f)
				grilla.set_cell_item(celda, id_tile_piso)
				_spawnear_zombies_en_celda(celda)


func _spawnear_zombies_en_celda(celda: Vector3i) -> void:
	if escena_zombie == null:
		return
	var centro_mundo = grilla.to_global(grilla.map_to_local(celda))
	# Superficie de la tile: centro Y + mitad del alto de celda
	var y_superficie = centro_mundo.y + grilla.cell_size.y / 2.0
	var mitad_tile_x = grilla.cell_size.x / 2.0 * 0.8
	var mitad_tile_z = grilla.cell_size.z / 2.0 * 0.8
	var cantidad = rng.randi_range(2, 5)
	for _i in range(cantidad):
		var zombie = escena_zombie.instantiate()
		add_child(zombie)
		zombie.add_to_group("zombies")
		var offset_x = rng.randf_range(-mitad_tile_x, mitad_tile_x)
		var offset_z = rng.randf_range(-mitad_tile_z, mitad_tile_z)
		zombie.global_position = Vector3(centro_mundo.x + offset_x, y_superficie, centro_mundo.z + offset_z)
