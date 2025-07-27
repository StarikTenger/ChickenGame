extends Node
class_name GameManager
@onready var grid = $Grid
@onready var robot_container: Node = $Robots
@onready var cam := get_node("/root/Main/MainCamera")

var selected_robot: CollectorRobot = null

@onready var items_container := get_node("Items")
var item_scene := preload("res://scenes/items/Item.tscn")
var collector_scene := preload("res://scenes/entities/Robot.tscn")
var chicken_scene := preload("res://scenes/entities/Chicken.tscn")

# Game settings, balance here
var coins: int = 20
var growth_levels: Array = [10, 20, 30, 40] # Levels of growth based on eggs consumed
var egg_saturation_levels: Array = [10, 5, 3, 1] # Saturation levels for growth stages
var rewards_per_level: Array = [10, 20, 30, 40] # Money rewards for each growth level
var collector_bot_price: int = 10

signal coins_changed()


signal collector_price_changed(price: int)

var egg_cost: int = 0  # Coins awarded when slug consumes an egg

func _ready():
	for robot in get_tree().get_nodes_in_group("robots"):
		if robot.has_signal("robot_selected"):
			robot.connect("robot_selected", Callable(self, "_on_robot_selected"))
			print("Подписал стартового робота:", robot.name)
	spawn_mega_consumer()
	
	# Подписываемся на сигнал выбора робота
	for robot in robot_container.get_children():
		if robot.has_signal("robot_selected"):
			robot.connect("robot_selected", Callable(self, "_on_robot_selected"))
	
	spawn_chickens(5)

func select_robot(robot: CollectorRobot):
	selected_robot = robot
	selected_robot.set_selected(true)

func unselect_robot():
	if selected_robot:
		selected_robot.set_selected(false)
		selected_robot = null

func _on_robot_selected(robot: CollectorRobot):
	if selected_robot:
		selected_robot.set_selected(false)

	select_robot(robot)
	print("Выбран робот: ", robot.name)

func _unhandled_input(event):
	if event is not InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if selected_robot == null:
		return
	var mouse_pos = cam.absolute_mouse_position()
	
	for robot in get_tree().get_nodes_in_group("robots"):
		var area = robot.get_node("Area2D") as Area2D
		var cs   = area.get_node("CollisionShape2D") as CollisionShape2D
		var shape = cs.shape
		if shape is CircleShape2D:
			if robot.global_position.distance_to(mouse_pos) <= shape.radius:
				return
		elif shape is RectangleShape2D:
			var local = robot.to_local(mouse_pos)
			if abs(local.x) <= shape.extents.x and abs(local.y) <= shape.extents.y:
				return
	selected_robot.target_position = mouse_pos
	selected_robot.is_moving = true
	unselect_robot()

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

func spawn_collector_bot():
	if coins < collector_bot_price:
		print("Недостаточно монет: нужно ", collector_bot_price, ", есть ", coins)
		return
	
	var bot = collector_scene.instantiate()
	robot_container.add_child(bot)
	bot.position = Vector2(300, 300)
	
	if bot.has_signal("robot_selected"):
		bot.connect("robot_selected", Callable(self, "_on_robot_selected"))
		print("Подписал нового робота:", bot.name)
	
	 # Подписываемся на сигнал выбора сразу после создания
	bot.connect("robot_selected", Callable(self, "_on_robot_selected"))

	coins -= collector_bot_price
	coins_changed.emit(coins)
	print("Построен сборщик. Монеты: ", coins)
	
	# Повышаем цену после первой покупки
	if collector_bot_price == 0:
		collector_bot_price = 10
		collector_price_changed.emit(collector_bot_price)

func add_coins(amount: int):
	coins += amount
	coins_changed.emit()

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
