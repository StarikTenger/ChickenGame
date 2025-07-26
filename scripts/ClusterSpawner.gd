extends Node2D

@export var item_name: String = "egg"
#@export var total_count: int = 20
@export var spawn_delay: float = 1.5  # сек между спавнами
@export var spawn_radius: float = 64.0
@export var max_nearby_items: int = 20  # максимум предметов рядом

# var spawned: int = 0
var item_scene := preload("res://scenes/items/Item.tscn")
@onready var timer := $Timer
@onready var items_container := get_node("/root/Main/Items")  # путь к Items

func _ready():
	timer.wait_time = spawn_delay
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	print("Spawner активен: ", item_name)

func _on_timer_timeout():
	# Считаем количество предметов нужного типа рядом
	var nearby_count = 0
	for item in get_tree().get_nodes_in_group("items"):
		if item.item_name == item_name and global_position.distance_to(item.global_position) <= spawn_radius:
			nearby_count += 1
	
	# print("Рядом ", item_name, ": ", nearby_count)
	
	if nearby_count >= max_nearby_items:
		return  # слишком много вокруг — не спавним

	# Спавним
	var item = item_scene.instantiate()
	item.item_name = item_name

	var offset = Vector2(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius))
	item.position = global_position + offset
	items_container.add_child(item)

	# print("Спавн ", item_name, " в ", item.position)
