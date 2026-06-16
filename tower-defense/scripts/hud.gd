extends CanvasLayer

@onready var barra_vida = $Panel/VBoxContainer/HBoxContainer/ProgressBar
@onready var label_vida = $Panel/VBoxContainer/HBoxContainer/Label
@onready var label_balas = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Label
@onready var label_madera = $Panel/VBoxContainer/HBoxContainer2/GridContainer/VBoxContainer/LabelMadera
@onready var label_piedra = $Panel/VBoxContainer/HBoxContainer2/GridContainer/VBoxContainer2/LabelPiedra
@onready var label_metal = $Panel/VBoxContainer/HBoxContainer2/GridContainer/VBoxContainer3/LabelMetal
@onready var stylebox_fill: StyleBoxFlat = barra_vida.get_theme_stylebox("fill")

var jugador

func _ready():
	jugador = get_tree().get_first_node_in_group("Jugador")
	barra_vida.max_value = jugador.vida_max
	
func _physics_process(delta: float) -> void:
	if jugador == null:
		return
	
	barra_vida.value = jugador.vida
	label_vida.text = str(jugador.vida) + "/" + str(jugador.vida_max)
	actualizar_color_vida()
	label_balas.text = str(jugador.balas) + "/" + str(jugador.balas_max)
	label_madera.text = "x " + str(jugador.madera)
	label_piedra.text = "x " + str(jugador.piedra)
	label_metal.text = "x " + str(jugador.metal)

func actualizar_color_vida():
	var porcentaje = float(jugador.vida) / float(jugador.vida_max)
	
	if porcentaje > 0.66:
		stylebox_fill.bg_color = Color.GREEN
	elif porcentaje > 0.33:
		stylebox_fill.bg_color = Color.YELLOW
	else:
		stylebox_fill.bg_color = Color.RED
	
