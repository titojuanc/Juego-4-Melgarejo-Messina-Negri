extends Node

var jugador_vida: int = 100
var jugador_vida_max: int = 100
var jugador_llaves: int = 0
var jugador_tiene_cania: bool = false
var jugador_madera: int = 0
var jugador_piedra: int = 0
var jugador_metal: int = 0
var jugador_balas: int = 0

var tiene_datos_jugador: bool = false

func _ready() -> void:
	reset_jugador()

func reset_jugador() -> void:
	jugador_vida = 100
	jugador_vida_max = 100
	jugador_llaves = 0
	jugador_tiene_cania = false
	jugador_madera = 0
	jugador_piedra = 0
	jugador_metal = 0
	jugador_balas = 0
	tiene_datos_jugador = false

func guardar_desde_jugador(jugador: Node) -> void:
	if jugador == null:
		return
	jugador_vida = int(jugador.vida)
	jugador_vida_max = int(jugador.vida_max)
	jugador_llaves = int(jugador.llaves)
	jugador_tiene_cania = bool(jugador.tiene_caña)
	jugador_madera = int(jugador.madera)
	jugador_piedra = int(jugador.piedra)
	jugador_metal = int(jugador.metal)
	jugador_balas = int(jugador.balas)
	tiene_datos_jugador = true

func cargar_en_jugador(jugador: Node) -> void:
	if jugador == null or not tiene_datos_jugador:
		return
	jugador.vida_max = jugador_vida_max
	jugador.vida = min(jugador_vida, jugador.vida_max)
	jugador.llaves = jugador_llaves
	jugador.tiene_caña = jugador_tiene_cania
	jugador.madera = jugador_madera
	jugador.piedra = jugador_piedra
	jugador.metal = jugador_metal
	jugador.balas = jugador_balas
