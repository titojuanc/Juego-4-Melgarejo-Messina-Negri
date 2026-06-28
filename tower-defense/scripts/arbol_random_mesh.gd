extends Recurso
class_name Arbol

const arbol_1: Mesh = preload("res://assets/arboles/arbol1/Arbol1.obj")
const arbol_2: Mesh = preload("res://assets/arboles/arbol2/Arbol2.obj")
const arbol_3: Mesh = preload("res://assets/arboles/arbol3/Arbol3.obj")

func configurar_mesh() -> void:
	var opciones: Array[Mesh] = [arbol_1, arbol_2, arbol_3]
	mesh_instance.mesh = opciones[aleatorizador.randi_range(0, opciones.size() - 1)]
	
func dar_al_jugador(receptor: Node, cantidad: int) -> void:
	receptor.madera += cantidad
	
func dar_al_npc(receptor: Node, cantidad: int) -> void:
	receptor.inv_madera += cantidad
	
