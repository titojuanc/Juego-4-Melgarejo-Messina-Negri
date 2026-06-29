extends Node3D

@export var zombie_scenes: Array[PackedScene] = []
@export var max_zombies: int = 100
@export var tiempo_respawn: float = 10.0
@export var radio_mundo: float = 400.0
@export var distancia_minima_base: float = 50.0
@export var distancia_minima_jugador: float = 20.0
@export var offset_y_zombie: float = 10

var altura_suelo = 2
var aleatorizador = RandomNumberGenerator.new()
var timer_respawn: float = 0.0
var jugador: Node3D = null
var centro_base: Node3D = null

func _ready() -> void:
	aleatorizador.randomize()
	jugador = get_tree().get_first_node_in_group("Jugador")
	centro_base = get_tree().get_first_node_in_group("CentroBase")
	for i in range(max_zombies):
		spawnear_zombie()
	

func _process(delta: float) -> void:
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("Jugador")
	if centro_base == null:
		centro_base = get_tree().get_first_node_in_group("CentroBase")
	
	timer_respawn -= delta
	if timer_respawn <= 0:
		timer_respawn = tiempo_respawn
		var zombies_actuales = get_tree().get_nodes_in_group("Enemigo").size()
		if zombies_actuales < max_zombies:
			spawnear_zombie()

func spawnear_zombie() -> void:
	if zombie_scenes.is_empty():
		return
	var pos = buscar_posicion_valida()
	if pos == Vector3.INF:
		return
	var escena = zombie_scenes[aleatorizador.randi_range(0, zombie_scenes.size() - 1)]
	var zombie = escena.instantiate()
	get_tree().root.add_child(zombie)
	zombie.global_position = pos

func buscar_posicion_valida() -> Vector3:
	var intentos = 20
	for i in range(intentos):
		var pos = Vector3(
			aleatorizador.randf_range(-radio_mundo, radio_mundo),
			altura_suelo + offset_y_zombie,
			aleatorizador.randf_range(-radio_mundo, radio_mundo)
		)
		if centro_base != null:
			if centro_base.global_position.distance_to(pos) < distancia_minima_base:
				continue
		if jugador != null:
			if jugador.global_position.distance_to(pos) < distancia_minima_jugador:
				continue
		return pos
	return Vector3.INF
