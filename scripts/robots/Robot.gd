extends CharacterBody2D
class_name CollectorRobot

@export var collect_radius: float = 64.0
@export var toss_radius: float = 256.0
@export var collect_delay: float = 1.0
@export var toss_delay: float = 1.0
@export var max_velocity: float = 1.0 # TODO: уточни
@export var tossing_speed: float = 100.0

@export var is_ghost: bool = false

var target_position: Vector2
var is_moving: bool = false
var speed: float = 100.0

signal robot_selected(robot)

@onready var selection_frame = $SelectionFrame
@onready var nav_agent = $NavigationAgent2D  # Ссылка на NavigationAgent2D

var holding_egg: Node = null
var awaiting_egg: bool = false

var collect_timer := 1.0
var toss_timer := 1.0

func try_collection(delta):
	collect_timer -= delta
	if collect_timer > 0 or awaiting_egg:
		return
	if holding_egg != null:
		return
	for item in get_tree().get_nodes_in_group("items"):
		if position.distance_to(item.position) <= collect_radius and item.collect_from_ground(self):
			holding_egg = item
			collect_timer = collect_delay
			toss_timer = toss_delay
			break

func try_tossing(delta):
	toss_timer -= delta
	if toss_timer > 0:
		return
	if holding_egg == null:
		return
	if is_moving or is_ghost:
		return
	for slug in get_tree().get_nodes_in_group("slugs"):
		if position.distance_to(slug.position) <= toss_radius:
			# if not slug.awaiting_egg:
			# Found a valid slug target, start tossing
			toss_egg_to(slug)
			toss_timer = toss_delay # Reset toss timer
			return
	
	# Second priority: try to toss to other robots
	for robot in get_tree().get_nodes_in_group("robots"):
		if robot == self or robot.is_moving or robot.is_ghost:
			continue
		if position.distance_to(robot.position) <= toss_radius and not robot.awaiting_egg and robot.holding_egg == null:
			toss_egg_to(robot)
			toss_timer = toss_delay
			break

func toss_egg_to(target: Node):
	if holding_egg == null:
		return
	
	# Start animation
	var sprite = get_node("Sprite2D")
	if "robot_throw" in sprite.sprite_frames.get_animation_names():
		if sprite.is_playing() and sprite.animation == "robot_throw":
			print("RESET THROW ANIMATION")
			sprite.frame = 0  # resets to the first frame
		else:
			print("START THROW ANIMATION")
			holding_egg.visible = false  # Hide egg during animation
			sprite.play("robot_throw")
	
	# Wait for the animation before tossing
	if sprite.animation == "robot_throw":
		print("THROW ANIMATION...")
		await sprite.animation_finished
		#sprite.play("robot_idle")
	else:
		print("THROW ANIMATION WAS CANCELED???")
		print(sprite.animation)
	
	if holding_egg == null:
		return
	
	# Rotate the egg to match the end of the animation
	holding_egg.rotation = -0.7 #-120*180/3.14
	holding_egg.tossing_dir = randi() % 2 * 2 - 1
	holding_egg.visible = true  # Show egg after animation
			
	target.awaiting_egg = true
	holding_egg.state = holding_egg.ItemState.IN_FLIGHT
	holding_egg.current_owner = target
	holding_egg.source_pos = position
	holding_egg.destination_pos = target.position
	holding_egg.flight_progress = 0.0
	var distance = position.distance_to(target.position)
	holding_egg.flight_progress_speed = tossing_speed / distance
	holding_egg = null
	var estimated_flight_time = distance / tossing_speed
	var target_type = "slug" if target.is_in_group("slugs") else "robot"
	print("Egg tossed to ", target_type, " at ", target.position, " | Distance: ", distance, " | Flight time: ", "%.2f" % estimated_flight_time, "s")



func _ready():
	add_to_group("robots")
	selection_frame.visible = false
	# Обновляем цель агента, если уже есть target_position
	if target_position != null:
		nav_agent.target_position = target_position

func _physics_process(delta):
	if is_ghost:
		return
	try_collection(delta)
	try_tossing(delta)

func _process(delta):
	queue_redraw()
	if is_moving:
		# Animate moving if not already
		var sprite = get_node("Sprite2D")
		if sprite.animation != "robot_roll" or not sprite.is_playing():
			sprite.play("robot_roll")
		
		# Обновляем цель агента, если нужно (если target_position изменился)
		if nav_agent.target_position != target_position:
			nav_agent.target_position = target_position
		
		# Получаем следующую точку пути
		var next_point = nav_agent.get_next_path_position()
		var direction = (next_point - global_position).normalized()
		velocity = direction * speed
		
		# Если дошли до цели (учитываем расстояние)
		if nav_agent.is_navigation_finished():
			velocity = Vector2.ZERO
			is_moving = false
		
		move_and_slide()
	else:
		# Stop moving animation if not moving
		var sprite = get_node("Sprite2D")
		if (sprite.animation != "robot_idle" and sprite.animation != "robot_throw") or not sprite.is_playing():
			sprite.play("robot_idle")

func receive_egg(egg: Node):
	holding_egg = egg
	awaiting_egg = false
	toss_timer = toss_delay
	print("Robot received egg")

func _draw():
	if is_ghost:
		return
	
	# Draw collection radius (inner circle)
	if selection_frame.visible:
		draw_arc(Vector2.ZERO, collect_radius, 0, TAU, 64, Color.GREEN, 2.0)
	
	# Draw toss radius (outer circle) - only if different from collect radius
	if toss_radius != collect_radius and selection_frame.visible:
		draw_arc(Vector2.ZERO, toss_radius, 0, TAU, 64, Color.BLUE, 2.0)
	var coord_text = "(%d, %d)" % [int(position.x), int(position.y)]
	var font = ThemeDB.fallback_font
	var font_size = 12
	var text_size = font.get_string_size(coord_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos = Vector2(-text_size.x / 2, -collect_radius - 20)
	draw_string(font, text_pos, coord_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("robot_selected", self)

func set_selected(is_selected: bool):
	selection_frame.visible = is_selected
