extends Node3D

@export var grid_width: int = 20
@export var grid_height: int = 20
@export var cell_size: float = 1.0

@onready var cell_data = $CellData
@onready var building_manager = $BuildingManager
@onready var input_handler = $InputHandler
@onready var grid_visual = $GridVisual

func _ready() -> void:
	cell_data.initialize(grid_width, grid_height)
	grid_visual.draw_grid(grid_width, grid_height, cell_size)
