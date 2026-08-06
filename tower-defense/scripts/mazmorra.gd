extends Node3D

signal jugador_cambio_tile(centro_mundo: Vector3)

@export var grilla: GridMap
@export var jugador: Node3D
@export var id_tile_piso: int = 0
@export var tamanio_grilla: int = 4

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
	for f in range(tamanio_grilla):
		for c in range(tamanio_grilla):
			if mapa[f][c]:
				grilla.set_cell_item(Vector3i(c, 0, f), id_tile_piso)
