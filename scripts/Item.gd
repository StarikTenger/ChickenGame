extends Node
class_name Item

@export var item_name: String = "egg"

@onready var sprite := $Sprite2D

func _ready():
	add_to_group("items")
	match item_name:
		"egg":
			sprite.texture = load("res://sprites/items/egg.png")
		"egg2":
			sprite.texture = load("res://sprites/items/egg2.png")
		_:
			sprite.texture = load("res://sprites/items/default.png")
