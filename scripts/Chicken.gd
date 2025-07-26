extends CharacterBody2D

@export var move_radius := 100.0       # Радиус гуляния
@export var speed := 40.0              # Скорость
@export var egg_interval := 5.0        # Раз в сколько секунд откладывает яйца
@export var max_eggs_nearby := 20
@export var egg_check_radius := 128.0
@export var item_scene := preload("res://scenes/items/Item.tscn")

var home_position: Vector2
var target_position: Vector2

@onready var egg_timer := $EggTimer

func _ready():
	home_position = global_position
	pick_new_target()
	egg_timer.wait_time = egg_interval
	egg_timer.start()

func _process(delta):
	var dir = (target_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	if global_position.distance_to(target_position) < 10:
		pick_new_target()

func pick_new_target():
	var angle = randf() * PI * 2
	var radius = randf_range(20, move_radius)
	var offset = Vector2(cos(angle), sin(angle)) * radius
	target_position = home_position + offset

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
