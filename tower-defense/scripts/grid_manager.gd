extends Node3D

@export var grid_width:int=12
@export var grid_height:int=12
@export var cell_size:float=8.0
@export var grid_y_offset:float=2.0

@onready var cell_data=$CellData
@onready var building_manager=$BuildingManager
@onready var input_handler=$InputHandler
@onready var grid_visual=$GridVisual

func _ready()->void:
	global_position.y=grid_y_offset
	cell_data.initialize(grid_width,grid_height)
	grid_visual.draw_grid(grid_width,grid_height,cell_size)
