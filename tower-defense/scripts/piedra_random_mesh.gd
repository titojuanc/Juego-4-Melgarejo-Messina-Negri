extends Recurso
class_name Piedra

const piedra_1: Mesh = preload("res://assets/piedras/piedra1/Rock_Medium_1.obj")
const piedra_2: Mesh = preload("res://assets/piedras/piedra2/Rock_Medium_2.obj")
const piedra_3: Mesh = preload("res://assets/piedras/piedra3/Rock_Medium_3.obj")

func configurar_mesh() -> void:
	var opciones: Array[Mesh] = [piedra_1, piedra_2, piedra_3]
	mesh_instance.mesh = opciones[aleatorizador.randi_range(0, opciones.size() - 1)]

func dar_al_jugador(receptor: Node, cantidad: int) -> void:
	receptor.piedra += cantidad
	
func dar_al_npc(receptor: Node, cantidad: int) -> void:
	receptor.inv_piedra += cantidad
	
