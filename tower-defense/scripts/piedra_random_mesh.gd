extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

@export var golpes_para_destruir: int = 5

const piedra_1: Mesh = preload("res://assets/piedras/piedra1/Rock_Medium_1.obj")
const piedra_2: Mesh = preload("res://assets/piedras/piedra2/Rock_Medium_2.obj")
const piedra_3: Mesh = preload("res://assets/piedras/piedra3/Rock_Medium_3.obj")

var aleatorizador = RandomNumberGenerator.new()
var golpes_restantes: int = 0

func _ready() -> void:
	golpes_restantes = golpes_para_destruir
	if mesh_instance == null:
		return
	aleatorizador.randomize()
	var opciones: Array[Mesh] = [piedra_1, piedra_2, piedra_3]
	mesh_instance.mesh = opciones[aleatorizador.randi_range(0, opciones.size() - 1)]

func recibir_golpe() -> void:
	if golpes_restantes <= 0:
		return
	golpes_restantes -= 1
	if golpes_restantes <= 0:
		queue_free()
