extends Node3D
@export var inimigo_cena: PackedScene
@export var jogador: CharacterBody3D
@onready var spawn_points = $Spawn
var ronda: int = 0
var inimigos_vivos: int = 0
@onready var musica: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready():
	musica.play(4)
	comecar_ronda()

func comecar_ronda():
	ronda += 1
	inimigos_vivos = ronda

	var pontos = spawn_points.get_children().duplicate()
	pontos.shuffle()

	for i in ronda:
		var ponto = pontos[i % pontos.size()]
		spawnar_inimigo(ponto.global_position)

func spawnar_inimigo(pos: Vector3):
	# Cria uma variável para controlar se achamos um lugar
	var spawned = false
	var pontos = spawn_points.get_children().duplicate()
	pontos.shuffle() # Embaralhamos os pontos
	
	for ponto in pontos:
		# Verifica se a distância de outros inimigos até este ponto é maior que 2 metros
		if is_ponto_livre(ponto.global_position):
			var inimigo = inimigo_cena.instantiate()
			add_child(inimigo)
			inimigo.target = jogador
			inimigo.global_position = ponto.global_position
			inimigo.tree_exiting.connect(_on_inimigo_morreu)
			spawned = true
			break # Sai do loop assim que spawnar
	
	# Se todos os lugares estiverem ocupados, espera e tenta de novo (opcional)
	if not spawned:
		await get_tree().create_timer(1.0).timeout
		spawnar_inimigo(pos)

func is_ponto_livre(pos: Vector3) -> bool:
	# Busca todos os inimigos existentes na cena
	var inimigos = get_tree().get_nodes_in_group("inimigos") 
	for i in inimigos:
		if i.global_position.distance_to(pos) < 2.0: # Raio de 2 metros
			return false
	return true

func _on_inimigo_morreu():
	inimigos_vivos -= 1
	if inimigos_vivos <= 0:
		await get_tree().create_timer(2.0).timeout
		comecar_ronda()
