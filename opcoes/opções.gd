extends Control

@onready var opcoes = $opcoes
@onready var video = $video
@onready var som = $som
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	opcoes.show()
	video.hide()
	som.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_and_hide(first, second):
	first.show()
	second.hide()

func _on_som_pressed():
	show_and_hide(som, opcoes)


	

func _on_video_pressed():
	show_and_hide(video, opcoes)


func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_principal.tscn")


func _on_tela_inteira_toggled(toogle_on: bool):
	if toogle_on:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
		
		



func _on_sem_borda_toggled(toogle_on: bool):
	if toogle_on:
		get_window().borderless = true
	else:
		get_window().borderless = false


func _on_vsync_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_voltar_para_op_pressed():
	show_and_hide(opcoes, video)
	
	


func _on_volume_geral_value_changed(value: float):
	volume(0, value)
	
func volume(bus_index, value):
	AudioServer.set_bus_volume_db(bus_index, value)
	
	


func _on_musica_value_changed(value: float):
	volume(1, value)
	
	

func _on_efeitos_value_changed(value: float):
	volume(2, value)
	
	


func _on_de_som_voltar_para_op_pressed():
	show_and_hide(opcoes, som)
	
