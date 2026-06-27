extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var hitbox_body: StaticBody3D = $StaticBody3D

@export var golpes_para_destruir: int = 7

const auto_hatchback: PackedScene = preload("res://assets/ciudad/kaykit/autos/car_hatchback.gltf")
const auto_police: PackedScene = preload("res://assets/ciudad/kaykit/autos/car_police.gltf")
const auto_sedan: PackedScene = preload("res://assets/ciudad/kaykit/autos/car_sedan.gltf")
const auto_stationwagon: PackedScene = preload("res://assets/ciudad/kaykit/autos/car_stationwagon.gltf")
const auto_taxi: PackedScene = preload("res://assets/ciudad/kaykit/autos/car_taxi.gltf")

var aleatorizador = RandomNumberGenerator.new()
var golpes_restantes: int = 0

func _ready() -> void:
	golpes_restantes = golpes_para_destruir
	if mesh_instance == null:
		return
	mesh_instance.mesh = null
	mesh_instance.scale = Vector3(5.0, 5.0, 5.0)
	aleatorizador.randomize()
	var opciones: Array[PackedScene] = [
		auto_hatchback,
		auto_police,
		auto_sedan,
		auto_stationwagon,
		auto_taxi
	]
	var modelo_elegido = opciones[aleatorizador.randi_range(0, opciones.size() - 1)]
	var instancia_modelo = modelo_elegido.instantiate()
	mesh_instance.add_child(instancia_modelo)
	if instancia_modelo is Node3D:
		instancia_modelo.position = Vector3.ZERO

	var rotacion_y = aleatorizador.randf_range(0.0, PI * 2)#un círculo entero
	mesh_instance.rotation.y = rotacion_y
	if hitbox_body:
		hitbox_body.rotation.y = rotacion_y

func recibir_golpe() -> void:
	if golpes_restantes <= 0:
		return
	golpes_restantes -= 1
	if golpes_restantes <= 0:
		var jugador = get_tree().get_first_node_in_group("Jugador")
		if jugador:
			jugador.metal += randi_range(8, 13)
		queue_free()
