extends Node3D

@export var mouse_sensibility: float = 0.005
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2
@export_range(0.0, 90.0, 0.1, "radians_as_degrees")var max_vertical_angle: float = PI/4
@export var min_spring_length: float = 2.0
@export var max_spring_length: float = 10.0
@onready var spring_arm := $SpringArm3D
@onready var menu_pausa = get_tree().root.get_node("Main/CanvasLayer/menuPause")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		rotation.y -= event.relative.x * mouse_sensibility
		rotation.y = wrapf(rotation.y, 0.0, TAU)
		
		rotation.x -= event.relative.y * mouse_sensibility
		rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)
	if event.is_action_pressed("scroll_up"):
		spring_arm.spring_length = max(min_spring_length, spring_arm.spring_length - 1)
	if event.is_action_pressed("scroll_down"):
		spring_arm.spring_length = min(max_spring_length, spring_arm.spring_length + 1)
	
	if event.is_action_pressed("esc"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
