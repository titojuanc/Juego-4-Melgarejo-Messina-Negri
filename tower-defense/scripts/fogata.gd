extends StaticBody3D

@onready var area = $InteractionArea
@onready var anim = $AnimatedSprite3D
@export var madera_max := 100
var madera := 0
var encendida := false
var jugadores_en_rango = []
var apagado_id := 0

func _physics_process(_delta):
	if jugadores_en_rango.is_empty():
		return
	if Input.is_action_just_pressed("interactuar"):
		interactuar(jugadores_en_rango[0])

func interactuar(jugador):
	if !encendida:
		if jugador.gastar_madera(10):
			madera += 10
			encender()
		return
	if madera > madera_max - 10:
		return
	if jugador.gastar_madera(10):
		madera += 10

func encender():
	apagado_id += 1
	encendida = true
	anim.visible = true
	anim.offset.y = 0
	anim.play("idle")
	consumir_madera()
	curar()

func apagar():
	encendida = false
	anim.offset.y = 40
	anim.play("off-turn")
	apagado_id += 1
	var id_actual = apagado_id
	await get_tree().create_timer(10.0).timeout
	if id_actual == apagado_id:
		anim.visible = false

func consumir_madera():
	while encendida:
		await get_tree().create_timer(2.0).timeout
		if !encendida:
			return
		madera -= 1
		if madera <= 0:
			madera = 0
			apagar()
			break

func curar():
	while encendida:
		await get_tree().create_timer(1.5).timeout
		if !encendida:
			return
		for jugador in jugadores_en_rango:
			if jugador.vida < jugador.vida_max:
				jugador.vida = min(jugador.vida + 5, jugador.vida_max)
				
func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		if !jugadores_en_rango.has(body):
			jugadores_en_rango.append(body)

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		jugadores_en_rango.erase(body)
