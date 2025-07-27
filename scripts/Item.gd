extends Node2D
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

func collect_from_ground(new_owner: Node) -> bool:
	if state != ItemState.GROUND:
		return false # Cannot collect if not on ground

	self.current_owner = new_owner
	state = ItemState.ROBOT
	
	# Move item to owner's position
	position = new_owner.position
	
	print("Egg collected at owner position: ", new_owner.position)
	return true
	

func toss_to(target_owner: Node, source_position: Vector2, target_position: Vector2, speed: float):
	current_owner = target_owner
	state = ItemState.IN_FLIGHT
	source_pos = source_position
	destination_pos = target_position
	flight_progress = 0.0
	flight_progress_speed = speed

func catch_by_receiver():
	state = ItemState.ROBOT
	position = current_owner.position
	var flight_time = flight_progress / flight_progress_speed if flight_progress_speed > 0 else 0
	if current_owner.has_method("receive_egg"):
		current_owner.receive_egg(self)
	print("Egg caught by receiver | Flight time: ", "%.2f" % flight_time, "s")

func _ready():
	add_to_group("items")
	match item_name:
		"egg":
			sprite.texture = load("res://sprites/egg.png")
		"egg2":
			sprite.texture = load("res://sprites/items/egg2.png")
		_:
			sprite.texture = load("res://sprites/items/default.png")

func _process(delta):
	if state == ItemState.IN_FLIGHT:
		flight_progress += flight_progress_speed * delta
		
		if flight_progress >= 1.0:
			# Egg has reached destination
			flight_progress = 1.0
			position = destination_pos
			catch_by_receiver()
		else:
			# Interpolate position during flight
			var h = 100 # height of the parabolic arc
			# Using a parabolic trajectory formula for a more natural flight path
			position = source_pos.lerp(destination_pos, flight_progress) + Vector2(0, h * (4 * (flight_progress - 0.5) * (flight_progress - 0.5) - 1))
