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

const _PARED_SCENE = preload("res://scenes/ParedMazmorra.tscn")
const _PUERTA_SCENE = preload("res://scenes/PuertaMazmorra.tscn")

const _ZOMBIE_SCENES: Array = [
	preload("res://scenes/ZombieNuevo1.tscn"),
	preload("res://scenes/ZombieNuevo2.tscn"),
	preload("res://scenes/ZombieNuevo3.tscn"),
	preload("res://scenes/ZombieNuevo4.tscn"),
	preload("res://scenes/ZombieNuevo5.tscn"),
	preload("res://scenes/ZombieNuevo6.tscn"),
]

@export var zombies_min_por_tile: int = 2
@export var zombies_max_por_tile: int = 5
@export var offset_y_zombie: float = 3.0

var _contenedor_paredes: Node3D = null
var _contenedor_zombies: Node3D = null

# Estructura por sala: clave = Vector2i(c, f)
# Valor: { "puertas": [{ "nodo": Node3D, "pos": Vector3, "rot_y": float }], "zombies": [Node3D] }
var _salas: Dictionary = {}
var _sala_activa: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	rng.randomize()
	_inicializar_mapa()
	_tallar_camino(Vector2i(0, 0), Vector2i(tamanio_grilla - 1, tamanio_grilla - 1))
	_pintar()
	_inicializar_salas()
	_generar_paredes()
	_spawnear_zombies()


func _inicializar_salas() -> void:
	_salas.clear()
	for f in range(tamanio_grilla):
		for c in range(tamanio_grilla):
			if mapa[f][c]:
				_salas[Vector2i(c, f)] = { "puertas": [], "zombies": [] }


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
		var coord := Vector2i(celda_actual.x, celda_actual.z)
		if _salas.has(coord):
			_on_jugador_entra_sala(coord)


func _pintar() -> void:
	grilla.clear()
	# Eliminar zombies previos
	for hijo in get_children():
		if hijo.is_in_group("zombies"):
			hijo.queue_free()

	for f in range(tamanio_grilla):
		for c in range(tamanio_grilla):
			if mapa[f][c]:
				grilla.set_cell_item(Vector3i(c, 0, f), id_tile_piso)


func _generar_paredes() -> void:
	# Limpiar paredes anteriores si se regenera
	if _contenedor_paredes != null:
		_contenedor_paredes.queue_free()
	_contenedor_paredes = Node3D.new()
	_contenedor_paredes.name = "Paredes"
	add_child(_contenedor_paredes)

	# Cuatro direcciones: Este (+X), Oeste (-X), Sur (+Z), Norte (-Z)
	var dirs := [
		Vector2i(1,  0),
		Vector2i(-1, 0),
		Vector2i(0,  1),
		Vector2i(0, -1),
	]

	var procesados: Dictionary = {}

	for f in range(tamanio_grilla):
		for c in range(tamanio_grilla):
			if not mapa[f][c]:
				continue

			var tile_pos: Vector3 = grilla.to_global(grilla.map_to_local(Vector3i(c, 0, f)))

			for d in dirs:
				var nc: int = c + d.x
				var nf: int = f + d.y

				# Clave única y simétrica para este borde
				var key: String
				if c < nc or (c == nc and f < nf):
					key = "%d,%d|%d,%d" % [c, f, nc, nf]
				else:
					key = "%d,%d|%d,%d" % [nc, nf, c, f]

				if procesados.has(key):
					continue
				procesados[key] = true

				var vecino_activo: bool = (
					nc >= 0 and nc < tamanio_grilla and
					nf >= 0 and nf < tamanio_grilla and
					mapa[nf][nc]
				)

				# Posición en el borde entre las dos celdas (o en el límite exterior)
				var world_pos: Vector3 = tile_pos + Vector3(d.x * 16.0, 0.0, d.y * 16.0)

				var instancia: Node3D
				if vecino_activo:
					instancia = _PUERTA_SCENE.instantiate()
				else:
					instancia = _PARED_SCENE.instantiate()

				_contenedor_paredes.add_child(instancia)
				instancia.global_position = world_pos

				# ParedMazmorra y PuertaMazmorra apuntan a lo largo de Z por defecto.
				# Si el borde es Norte/Sur (d.y != 0), el muro debe correr en X → rotar 90° en Y.
				# Si el borde es Este/Oeste (d.x != 0), el muro ya corre en Z → sin rotación extra.
				if d.y != 0:
					instancia.rotation_degrees.y = 90.0

				# Registrar puertas en las salas que conectan
				if vecino_activo:
					var dato_puerta := { "nodo": instancia, "pos": world_pos, "rot_y": instancia.rotation_degrees.y }
					var sala_a := Vector2i(c, f)
					var sala_b := Vector2i(nc, nf)
					if _salas.has(sala_a):
						_salas[sala_a]["puertas"].append(dato_puerta)
					if _salas.has(sala_b):
						_salas[sala_b]["puertas"].append(dato_puerta)


func _spawnear_zombies() -> void:
	if _contenedor_zombies != null:
		_contenedor_zombies.queue_free()
	_contenedor_zombies = Node3D.new()
	_contenedor_zombies.name = "Zombies"
	add_child(_contenedor_zombies)

	var celda_size := grilla.cell_size  # Vector3(32, 2, 32)
	var margen := 4.0  # margen interior para no spawnear pegado a la pared

	for f in range(tamanio_grilla):
		for c in range(tamanio_grilla):
			if not mapa[f][c]:
				continue

			var coord := Vector2i(c, f)
			var centro_tile: Vector3 = grilla.to_global(grilla.map_to_local(Vector3i(c, 0, f)))
			var cantidad: int = rng.randi_range(zombies_min_por_tile, zombies_max_por_tile)

			for _i in range(cantidad):
				var escena: PackedScene = _ZOMBIE_SCENES[rng.randi() % _ZOMBIE_SCENES.size()]
				var zombie: Node3D = escena.instantiate()
				_contenedor_zombies.add_child(zombie)

				var offset_x := rng.randf_range(-celda_size.x * 0.5 + margen, celda_size.x * 0.5 - margen)
				var offset_z := rng.randf_range(-celda_size.z * 0.5 + margen, celda_size.z * 0.5 - margen)
				zombie.global_position = centro_tile + Vector3(offset_x, offset_y_zombie, offset_z)

				# Registrar zombie en su sala y conectar señal de muerte
				if _salas.has(coord):
					_salas[coord]["zombies"].append(zombie)
					zombie.tree_exited.connect(_on_zombie_muerto.bind(coord, zombie))


func _on_jugador_entra_sala(coord: Vector2i) -> void:
	# Si ya estaba en esta sala, no hacer nada
	if coord == _sala_activa:
		return
	_sala_activa = coord
	var sala = _salas[coord]
	# Solo bloquear si hay zombies vivos en la sala
	if sala["zombies"].is_empty():
		return
	_bloquear_sala(sala)


func _bloquear_sala(sala: Dictionary) -> void:
	for dato in sala["puertas"]:
		var nodo: Node3D = dato["nodo"]
		if not is_instance_valid(nodo):
			continue
		# Reemplazar la PuertaMazmorra por una ParedMazmorra temporal
		var pared: Node3D = _PARED_SCENE.instantiate()
		_contenedor_paredes.add_child(pared)
		pared.global_position = dato["pos"]
		pared.rotation_degrees.y = dato["rot_y"]
		dato["pared_bloqueo"] = pared
		nodo.hide()

		# Animación: la pared "cae" desde escala 0 a 1 en Y
		pared.scale = Vector3(1.0, 0.0, 1.0)
		var tween := create_tween()
		tween.tween_property(pared, "scale:y", 1.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


func _desbloquear_sala(sala: Dictionary) -> void:
	for dato in sala["puertas"]:
		var nodo: Node3D = dato["nodo"]
		if dato.has("pared_bloqueo"):
			var pared: Node3D = dato["pared_bloqueo"]
			dato.erase("pared_bloqueo")
			if is_instance_valid(pared):
				# Animación: la pared se encoge antes de desaparecer
				var tween := create_tween()
				tween.tween_property(pared, "scale:y", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
				tween.tween_callback(pared.queue_free)
		# La puerta reaparece con un pequeño flash de escala
		if is_instance_valid(nodo):
			nodo.show()
			nodo.scale = Vector3(1.0, 0.0, 1.0)
			var tween_puerta := create_tween()
			tween_puerta.tween_property(nodo, "scale:y", 1.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func _on_zombie_muerto(coord: Vector2i, zombie: Node3D) -> void:
	if not _salas.has(coord):
		return
	var sala = _salas[coord]
	sala["zombies"].erase(zombie)
	# Desbloquear en cuanto no queden zombies, sin importar dónde esté el jugador
	if sala["zombies"].is_empty():
		_desbloquear_sala(sala)
