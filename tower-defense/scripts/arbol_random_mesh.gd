extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

const arbol_1: Mesh = preload("res://assets/arboles/arbol1/Arbol1.obj")
const arbol_2: Mesh = preload("res://assets/arboles/arbol2/Arbol2.obj")
const arbol_3: Mesh = preload("res://assets/arboles/arbol3/Arbol3.obj")

var aleatorizador = RandomNumberGenerator.new()

func _ready() -> void:
	if mesh_instance == null:
		return
	aleatorizador.randomize()
	var opciones: Array[Mesh] = [arbol_1, arbol_2, arbol_3]
	mesh_instance.mesh = opciones[aleatorizador.randi_range(0, opciones.size() - 1)]
