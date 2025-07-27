extends CanvasLayer

@onready var restart_button := $CenterContainer/Panel/CenterContainer/VBoxContainer/Button
@onready var label := $CenterContainer/Panel/CenterContainer/VBoxContainer/Label

func _ready():
	restart_button.pressed.connect(on_restart_pressed)
	hide()  # Скрываем до проигрыша

func show_game_over():
	label.text = "Вы проиграли"
	visible = true
	Engine.time_scale = 0.0

func on_restart_pressed():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
