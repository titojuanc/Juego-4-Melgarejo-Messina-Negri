extends Node3D

@export_file("*.tscn") var escena_mazmorra := "res://scenes/mazmorra.tscn"
@onready var area_interaccion: Area3D = $Area3D

var jugador_en_rango := false
var cambiando_escena := false

func _ready() -> void:
	area_interaccion.body_entered.connect(_on_area_3d_body_entered)
	area_interaccion.body_exited.connect(_on_area_3d_body_exited)

func _process(_delta: float) -> void:
	if cambiando_escena:
		return
	if jugador_en_rango and Input.is_action_just_pressed("interactuar"):
		cambiando_escena = true
		var jugador_obj := get_tree().get_first_node_in_group("Jugador")
		if jugador_obj != null and Gamestate.has_method("guardar_desde_jugador"):
			Gamestate.guardar_desde_jugador(jugador_obj)
		var error := get_tree().change_scene_to_file(escena_mazmorra)
		if error != OK:
			cambiando_escena = false
			push_error("No se pudo cambiar a la escena: %s" % escena_mazmorra)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_en_rango = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugador_en_rango = false
