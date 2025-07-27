extends Control

@onready var play_button := $VBoxContainer/CenterContainer/Play

func _ready():
	play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
