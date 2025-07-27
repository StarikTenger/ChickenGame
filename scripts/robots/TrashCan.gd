extends Node

@onready var game_manager: Node = get_node("/root/Main")

var awaiting_egg: bool = false # If true, waiting for egg to arrive
var holding_egg: Node = null # Reference to the egg being delivered

var irritation: float = 0 # Irritation level, increases when slug is waiting for an egg
var irritation_threshold: float = 20.0 # Threshold for irritation, seconds
var irritation_increase_rate: float = 1.0 # Rate of irritation increase per second
var irritation_decrease: float = 10 # Irritation deacrease per egg

var eggs_consumed: int = 0 # Count of eggs consumed
var growth_levels: Array = [10, 20, 30, 40] # Levels of growth based on eggs consumed
var egg_saturation_levels: Array = [10, 5, 3, 1] # Saturation levels for growth stages
var level: int = 0 # Current growth level

signal game_over
signal level_complete

func _ready():
	randomize()
	add_to_group("trash_cans")  # Add trash_can to group for robot discovery
#	start_random_change_timer()

func consume(item: String, amount: int):
	var sprite = get_node("Sprite2D")


func receive_egg(egg: Node):
	holding_egg = egg
	awaiting_egg = false
	
	# Immediately consume the egg
	consume_egg(egg)
	print("Параша получила яйко: ", egg.item_name)

func consume_egg(egg: Node):
	consume(egg.item_name, 1)
	
	egg.state = egg.ItemState.CONSUMED
	
	egg.queue_free()
	holding_egg = null
	print("яйко выброшено")
