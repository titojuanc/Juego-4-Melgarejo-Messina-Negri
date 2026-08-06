extends Area3D

@export var tiempo_activacion: float  = 2.0
@export var barra_offset_x: float = -3.0

@onready var barra = $BarraProgreso

var progreso = 0.0
var jugador_dentro = false
var barra_ancho_original: float
var barra_pos_izquierda: float

signal boton_activado

func _ready() -> void:
	barra_ancho_original = (barra.mesh as BoxMesh).size.x
	barra.scale.x = 0

func _physics_process(delta: float) -> void:
	if jugador_dentro:
		progreso += delta
		actualizar_barra()
		if progreso >= tiempo_activacion:
			progreso = 0.0
			barra.scale.x = 0
			boton_activado.emit()
	else:
		progreso = max(progreso - delta, 0.0)
		actualizar_barra()
	
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_dentro = true
	
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_dentro = false
	
func actualizar_barra() -> void:
	var t = progreso / tiempo_activacion
	barra.scale.x = t
	barra.position.x = barra_offset_x + (barra_ancho_original * t / 2)
