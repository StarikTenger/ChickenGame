extends Node2D

var game_manager: Node

var awaiting_egg: bool = false # If true, waiting for egg to arrive
var holding_egg: Node = null # Reference to the egg being delivered

signal game_over
signal level_complete

func _ready():
	randomize()
	add_to_group("slugs")  # Add slug to group for robot discovery
#	start_random_change_timer()

func consume(item: String, amount: int):
	var sprite = get_node("Sprite2D")
	print(sprite.sprite_frames.get_animation_names())
	if "slug_eat" in sprite.sprite_frames.get_animation_names():
		if sprite.animation == "slug_eat" and sprite.is_playing():
			sprite.frame = 0  # resets to the first frame
		else:
			sprite.play("slug_eat")
	

func receive_egg(egg: Node):
	holding_egg = egg
	awaiting_egg = false
	
	# Immediately consume the egg
	consume_egg(egg)
	print("Slug received and consumed egg: ", egg.item_name)

func consume_egg(egg: Node):
	# Consume the egg based on its type
	consume(egg.item_name, 1)
	
	# Set egg state to consumed
	egg.state = egg.ItemState.CONSUMED
	
	# Remove the egg from the scene
	egg.queue_free()
	holding_egg = null

	# Add coins
	game_manager.add_coins(game_manager.egg_cost)
