extends Control

func _ready():
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		resume()
	else:
		pause()

func pause():
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume():
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_vt_menu_inicial_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu_principal.tscn")


func _on_vt_ao_jogo_pressed() -> void:
	resume()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
