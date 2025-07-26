extends CharacterBody2D
class_name CollectorRobot

# Stats
@export var collect_radius: float = 64.0
@export var toss_radius: float = 256.0
@export var cooldown: float = 1 # time between catch and throw
@export var max_velocity: float = 1 # TODO: value
@export var tossing_speed: float = 100 # egg speed when tossing

var holding_egg: Node = null # Reference to the egg
var busy_waiting: bool = false # If true, waiting for egg to arrive, cannot accept egg proposals

@export var collect_delay: float = 1.0  # задержка в секундах
var collect_timer := 1.0

func try_collection(delta):
	collect_timer -= delta
	if collect_timer > 0:
		return 
	if holding_egg != null:
		return # Already holding an egg
	for item in get_tree().get_nodes_in_group("items"):
		if position.distance_to(item.position) <= collect_radius:
			
			holding_egg = item
			item.collect_from_ground(self)
			
			collect_timer = collect_delay  # сбрасываем таймер
			break

func _physics_process(delta):
	collect_timer -= delta
	try_collection(delta)
