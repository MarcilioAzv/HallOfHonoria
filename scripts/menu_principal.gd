extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_single_bt_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_mulyi_bt_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_op_bt_pressed() -> void:
	get_tree().change_scene_to_file("res://opções.tscn")


func _on_sair_bt_pressed() -> void:
	get_tree().quit()
