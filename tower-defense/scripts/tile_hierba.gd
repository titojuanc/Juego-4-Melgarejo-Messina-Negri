extends MeshInstance3D

@export var arbol_scene: PackedScene
@export var min_arboles: int = 2
@export var max_arboles: int = 3
@export var separacion_minima: float = 8.0
@export var margen_borde: float = 3.0
@export var altura_spawn: float = 1.0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if arbol_scene == null:
		return
	_spawnear_arboles()

func _spawnear_arboles() -> void:
	_rng.randomize()
	var cantidad := _rng.randi_range(min_arboles, max_arboles)
	var posiciones: Array[Vector2] = []
	var contenedor := Node3D.new()
	contenedor.name = "RecursosSpawn"
	add_child(contenedor)

	var max_x := 16.0 - margen_borde
	var max_z := 16.0 - margen_borde

	for _i in range(cantidad):
		var offset := _buscar_offset_valido(posiciones, max_x, max_z)
		if offset == Vector2.INF:
			continue
		posiciones.append(offset)

		var arbol := arbol_scene.instantiate() as Node3D
		if arbol == null:
			continue

		arbol.position = Vector3(offset.x, altura_spawn, offset.y)
		arbol.rotation.y = _rng.randf_range(0.0, TAU)
		contenedor.add_child(arbol)

func _buscar_offset_valido(posiciones_existentes: Array[Vector2], max_x: float, max_z: float) -> Vector2:
	var intentos := 24
	for _i in range(intentos):
		var candidato := Vector2(
			_rng.randf_range(-max_x, max_x),
			_rng.randf_range(-max_z, max_z)
		)

		var valido := true
		for posicion in posiciones_existentes:
			if posicion.distance_to(candidato) < separacion_minima:
				valido = false
				break

		if valido:
			return candidato

	return Vector2.INF
