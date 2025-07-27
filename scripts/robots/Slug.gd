extends Node2D

var game_manager: Node

var awaiting_egg: bool = false # If true, waiting for egg to arrive
var holding_egg: Node = null # Reference to the egg being delivered

var irritation: float = 0 # Irritation level, increases when slug is waiting for an egg
var irritation_threshold: float = 20.0 # Threshold for irritation, seconds
var irritation_increase_rate: float = 1.0 # Rate of irritation increase per second
var irritation_decrease: float = 10 # Irritation deacrease per egg

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
	
	# Decrease irritation when egg is consumed
	irritation = max(0, irritation - irritation_decrease)
	print("Slug consumed egg! Irritation decreased to: ", "%.2f" % irritation)

func _process(delta):
	# Increase irritation over time
	irritation += irritation_increase_rate * delta
	queue_redraw()  # Update the visual bar
	
	# Check if irritation threshold is reached
	if irritation >= irritation_threshold:
		game_over.emit()
		print("Slug irritation reached threshold! Game Over!")

func _draw():
	# Draw irritation bar above the slug
	var bar_width = 100.0
	var bar_height = 8.0
	var bar_pos = Vector2(-bar_width / 2, -60)  # Position above the slug
	
	# Background bar (gray)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.GRAY)
	
	# Fill bar based on irritation level
	var fill_ratio = irritation / irritation_threshold
	fill_ratio = clamp(fill_ratio, 0.0, 1.0)
	var fill_width = bar_width * fill_ratio
	
	# Color changes from green to red based on irritation level
	var bar_color = Color.RED.lerp(Color.RED, fill_ratio)
	draw_rect(Rect2(bar_pos, Vector2(fill_width, bar_height)), bar_color)
	
	# Border around the bar
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.WHITE, false, 1.0)
	
	# Text showing irritation value
	var irritation_text = "%.1f/%.1f" % [irritation, irritation_threshold]
	var font = ThemeDB.fallback_font
	var font_size = 10
	var text_size = font.get_string_size(irritation_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos = Vector2(-text_size.x / 2, bar_pos.y - 5)
	draw_string(font, text_pos, irritation_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
