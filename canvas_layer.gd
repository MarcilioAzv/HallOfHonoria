extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var player = $"../jogador"

func _ready():
	player.health_changed.connect(_on_health_changed)
	health_bar.max_value = player.max_health
	health_bar.value = player.health   # <-- sincroniza o valor inicial direto

func _on_health_changed(current: float, max: float):
	health_bar.max_value = max
	var tween = create_tween()
	tween.tween_property(health_bar, "value", current, 0.3).set_trans(Tween.TRANS_SINE)
	var percent = current / max
	var fill_style = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if percent > 0.5:
		fill_style.bg_color = Color.GREEN.lerp(Color.YELLOW, (1.0 - percent) * 2)
	else:
		fill_style.bg_color = Color.YELLOW.lerp(Color.RED, (0.5 - percent) * 2)
