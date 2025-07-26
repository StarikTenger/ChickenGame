extends Node
class_name Item

@export var item_name: String = "egg"

@onready var sprite := $Sprite2D

enum ItemState {
	GROUND, # lying on the ground, initial state
	ROBOT, # being hold by a robot 
	IN_FLIGHT, # in the air
	CONSUMED # being consumed by the slug
}

var state: ItemState = ItemState.GROUND
var current_owner: Node = null # robot or slug holding or about to hold the egg

# Source and destination positions, need for throwing the egg
var source_pos: Vector2 = Vector2(0,0)
var destination_pos: Vector2 = Vector2(0,0)

var flight_progress = 0 # 0 - start of flight, 1 - landing
var flight_progress_speed = 0 # Calculated from distance when throwing

# TODO: egg flight animation, it should be not straight line

func collect_from_ground(owner: Node):
	current_owner = owner
	state = ItemState.ROBOT
	print("func called")
	

func _ready():
	add_to_group("items")
	match item_name:
		"egg":
			sprite.texture = load("res://sprites/items/egg.png")
		"egg2":
			sprite.texture = load("res://sprites/items/egg2.png")
		_:
			sprite.texture = load("res://sprites/items/default.png")
