extends CharacterBody2D

@export var path_speed := 0.002   # скорость вдоль кривой [0..1]/сек
@export var move_radius := 100.0       # Радиус гуляния
@export var speed := 40.0              # Скорость
@export var egg_interval := 5.0        # Раз в сколько секунд откладывает яйца
@export var max_eggs_nearby := 20
@export var egg_check_radius := 128.0
@export var item_scene := preload("res://scenes/items/Item.tscn")

var path_reference: PathFollow2D  # Reference to PathFollow2D for home position
var home_position: Vector2
var target_position: Vector2

@onready var egg_timer := $EggTimer

var travel_timeout := 0.0
var travel_time_passed := 0.0

func _ready():
	# Find PathFollow2D inside Route sibling node
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.name == "Route" or child.has_method("get_children"):
				# Look inside the Route node for PathFollow2D
				for grandchild in child.get_children():
					if grandchild is PathFollow2D:
						path_reference = grandchild
						break
				if path_reference:
					break
	
	if not path_reference:
		print("Warning: No PathFollow2D found inside Route sibling, chicken will stay at spawn position")
		home_position = global_position
	else:
		home_position = path_reference.global_position
		print("Found PathFollow2D inside Route:", path_reference.name)
	
	pick_new_target()
	egg_timer.wait_time = egg_interval
	egg_timer.start()

func _process(delta):
	# Update path reference position if available
	if path_reference:
		path_reference.progress_ratio = fmod(path_reference.progress_ratio + delta * path_speed, 1.0)
		# Update home position to follow the path reference
		home_position = path_reference.global_position
	
	# Move chicken independently towards target position
	var dir = (target_position - global_position).normalized()
	velocity = dir * speed
	var chicken_sprite = $Sprite2D
	if velocity.x != 0:
		chicken_sprite.scale.x = - sign(velocity.x) * abs(chicken_sprite.scale.x)
	move_and_slide()

	# Если достигли цели, выбираем новую 
	if global_position.distance_to(target_position) < 10:
		pick_new_target()
	
	# Где-то застряли -- тоже выбираем новую цель
	travel_time_passed += delta
	if travel_time_passed > travel_timeout:
		pick_new_target()

func pick_new_target():
	var angle = randf() * PI * 2
	var radius = randf_range(20, move_radius)
	var offset = Vector2(cos(angle), sin(angle)) * radius
	target_position = home_position + offset
	
	var distance = global_position.distance_to(target_position)
	travel_timeout = distance / speed
	travel_time_passed = 0.0

func _on_egg_timer_timeout() -> void:
	# Проверка яиц поблизости
	var nearby_eggs := 0
	var items_container = get_tree().root.get_node("Main/Items")
	for child in items_container.get_children():
		if child is Item and child.item_name == "egg":
			if child.global_position.distance_to(global_position) <= egg_check_radius:
				nearby_eggs += 1

	if nearby_eggs >= max_eggs_nearby:
		# слишком много яиц, ждем следующего раза
		print("Слишком много яиц рядом: ", nearby_eggs)
		return

	# спавним яйцо
	var egg = item_scene.instantiate()
	egg.item_name = "egg"
	egg.global_position = global_position
	items_container.add_child(egg)
	print("Курица снесла яйцо. Сейчас яиц вокруг:", nearby_eggs + 1)
