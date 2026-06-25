extends Node3D

@onready var fill: MeshInstance3D = $Fill
var fill_material: StandardMaterial3D
var fill_max_width: float = 1.0

func _ready():
	fill_material = StandardMaterial3D.new()
	fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_material.albedo_color = Color.GREEN
	fill.set_surface_override_material(0, fill_material)

func update_health(current: float, max: float):
	var percent = clamp(current / max, 0.0, 1.0)
	
	fill.scale.x = percent
	fill.position.x = -(fill_max_width * (1.0 - percent)) / 2.0
	visible = current < max
	
	if percent > 0.5:
		fill_material.albedo_color = Color.GREEN.lerp(Color.YELLOW, (1.0 - percent) * 2)
	else:
		fill_material.albedo_color = Color.YELLOW.lerp(Color.RED, (0.5 - percent) * 2)
