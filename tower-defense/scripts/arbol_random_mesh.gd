extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

@export var golpes_para_destruir: int = 3

const arbol_1: Mesh = preload("res://assets/arboles/arbol1/Arbol1.obj")
const arbol_2: Mesh = preload("res://assets/arboles/arbol2/Arbol2.obj")
const arbol_3: Mesh = preload("res://assets/arboles/arbol3/Arbol3.obj")

var aleatorizador = RandomNumberGenerator.new()
var golpes_restantes: int = 0

func _ready() -> void:
	golpes_restantes = golpes_para_destruir
	if mesh_instance == null:
		return
	aleatorizador.randomize()
	var opciones: Array[Mesh] = [arbol_1, arbol_2, arbol_3]
	mesh_instance.mesh = opciones[aleatorizador.randi_range(0, opciones.size() - 1)]

func recibir_golpe() -> void:
	if golpes_restantes <= 0:
		return
	golpes_restantes -= 1
	if golpes_restantes <= 0:
		var jugador = get_tree().get_first_node_in_group("Jugador")
		if jugador:
			jugador.madera += randi_range(8, 13)
		queue_free()
