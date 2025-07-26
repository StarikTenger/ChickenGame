extends Node

@onready var grid = $Grid
@onready var robot_container: Node = null

@onready var items_container := get_node("Items")
var item_scene := preload("res://scenes/items/Item.tscn")
var collector_scene := preload("res://scenes/entities/Robot.tscn")
var spawner_scene := preload("res://scenes/ClusterSpawner.tscn")
var chicken_scene := preload("res://scenes/entities/Chicken.tscn")

var coins: int = 100
signal coins_changed()

var collector_bot_price: int = 0
signal collector_price_changed(price: int)

var egg_cost: int = 5  # Coins awarded when slug consumes an egg

func _ready():
	await get_tree().process_frame
	robot_container = get_node("Robots")
	spawn_mega_consumer()
	#spawn_cluster("egg", Vector2(300, 300))
	spawn_chickens(5)

func spawn_mega_consumer():
	if not is_instance_valid(robot_container):
		push_error("robot_container is null!")
		return

	var mega_scene = preload("res://scenes/entities/Slug.tscn")
	var mega = mega_scene.instantiate()
	robot_container.add_child(mega)
	mega.position = Vector2(640, 360)
	mega.game_manager = self

func spawn_resource_cluster(item_name: String, center: Vector2, count: int):
	print("Spawning ", count, item_name, " at ", center)
	for i in count:
		var item = item_scene.instantiate()
		item.item_name = item_name

		var offset = Vector2(randf_range(-64, 64), randf_range(-64, 64))
		item.position = center + offset

		items_container.add_child(item)

func add_coins(amount: int):
	coins += amount
	coins_changed.emit()
	print("Coins: ", coins)
	
func spawn_cluster(item_name: String, position: Vector2):
	var spawner = spawner_scene.instantiate()
	spawner.item_name = item_name
	spawner.global_position = position
	add_child(spawner)

func spawn_chickens(count: int):
	var center := Vector2(640, 360)   # центр карты
	var forbidden_radius := 200.0     # не ближе 200 пикселей к центру
	var chicken_min_dist := 100.0     # минимальное расстояние между курицами

	var placed_chickens: Array[Vector2] = []

	for i in count:
		var pos: Vector2
		var attempts := 0

		while true:
			pos = Vector2(randf_range(0, 1280), randf_range(0, 720))

			# Проверка расстояния от центра
			if pos.distance_to(center) < forbidden_radius:
				attempts += 1
				if attempts > 100: break
				continue

			# Проверка расстояния от других куриц
			var too_close := false
			for other_pos in placed_chickens:
				if pos.distance_to(other_pos) < chicken_min_dist:
					too_close = true
					break

			if too_close:
				attempts += 1
				if attempts > 100: break
				continue

			break  # Всё ок, выходим из цикла

		# Если нашли подходящую точку
		if attempts <= 100:
			var chicken = chicken_scene.instantiate()
			chicken.global_position = pos
			add_child(chicken)
			placed_chickens.append(pos)
		else:
			print("Не удалось разместить курицу ", i)
