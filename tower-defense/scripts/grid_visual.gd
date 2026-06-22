extends Node3D

@onready var grid_lines:MeshInstance3D=$GridLines
@onready var hover_cell:MeshInstance3D=$HoverCell
@onready var drag_overlay:MeshInstance3D=$DragOverlay

var _cell_size:float=1.0

func draw_grid(width:int,height:int,cell_size:float)->void:
	_cell_size=cell_size
	var mesh=ArrayMesh.new()
	var vertices=PackedVector3Array()

	for x in width+1:
		vertices.append(Vector3(x*cell_size,0,0))
		vertices.append(Vector3(x*cell_size,0,height*cell_size))

	for z in height+1:
		vertices.append(Vector3(0,0,z*cell_size))
		vertices.append(Vector3(width*cell_size,0,z*cell_size))

	var arrays=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES,arrays)
	grid_lines.mesh=mesh

	var hover_mesh=PlaneMesh.new()
	hover_mesh.size=Vector2(cell_size*0.95,cell_size*0.95)
	hover_cell.mesh=hover_mesh

func move_hover_cell(cell:Vector2i,cell_size:float)->void:
	var half=cell_size*0.5
	hover_cell.position=Vector3(cell.x*cell_size+half,0.01,cell.y*cell_size+half)

func set_hover_color(can_place:bool)->void:
	var mat=hover_cell.material_override as StandardMaterial3D
	if can_place:
		mat.albedo_color=Color(0,1,0,0.4)
	else:
		mat.albedo_color=Color(1,0,0,0.4)

func show_drag_area(from:Vector2i,to:Vector2i,color:Color)->void:
	drag_overlay.visible=true
	var min_x=mini(from.x,to.x)
	var max_x=maxi(from.x,to.x)
	var min_y=mini(from.y,to.y)
	var max_y=maxi(from.y,to.y)
	var w=(max_x-min_x+1)
	var h=(max_y-min_y+1)
	var margin=_cell_size*0.05
	var plane=PlaneMesh.new()
	plane.size=Vector2(w*_cell_size-margin,h*_cell_size-margin)
	drag_overlay.mesh=plane
	var cx=min_x*_cell_size+w*_cell_size*0.5
	var cz=min_y*_cell_size+h*_cell_size*0.5
	drag_overlay.position=Vector3(cx,0.02,cz)
	var mat=drag_overlay.material_override as StandardMaterial3D
	mat.albedo_color=color

func hide_drag_area()->void:
	drag_overlay.visible=false
