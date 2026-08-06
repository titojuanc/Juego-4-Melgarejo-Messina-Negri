extends Node3D
class_name Recurso

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@export var golpes_para_destruir: int = 3
var golpes_restantes: int = 0
var aleatorizador = RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("RecursoDestruible")
	for hijo in get_children():
		if hijo is StaticBody3D:
			hijo.add_to_group("RecursoColision")
	golpes_restantes = golpes_para_destruir
	aleatorizador.randomize()
	configurar_mesh()
	
func configurar_mesh() -> void:
	pass
	
func recibir_golpe(quien = null) -> void:
	if golpes_restantes <= 0:
		return
	golpes_restantes -= 1
	if golpes_restantes <= 0:
		var receptor = quien if quien != null else get_tree().get_first_node_in_group("Jugador")
		dar_recursos(receptor)
		queue_free()
	
func dar_recursos(receptor: Node) -> void:
	if receptor == null:
		return
	var cantidad = randi_range(8, 13)
	if receptor.is_in_group("Jugador"):
		dar_al_jugador(receptor, cantidad)
	else:
		dar_al_npc(receptor, cantidad)
	
func dar_al_jugador(receptor: Node, cantidad: int) -> void:
	pass
	
func dar_al_npc(receptor: Node, cantidad: int) -> void:
	pass
	
