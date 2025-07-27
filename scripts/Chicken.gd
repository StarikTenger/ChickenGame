extends CharacterBody2D

@export var move_radius := 100.0       # Радиус гуляния внутри каждого сегмента
@export var speed := 100.0             # Скорость
@export var egg_interval := 5.0        # Интервал между яйцами
@export var max_eggs_nearby := 20      # Макс яиц в зоне до паузы
@export var egg_check_radius := 128.0  # Радиус поиска яиц
@export var item_scene := preload("res://scenes/items/Item.tscn")

# --- Добавленные для маршрута ---
@export var waypoints: Array[Vector2] = []  # Точки маршрута
@export var eggs_per_point: int = 5        # Яиц до перехода к следующей точке

var home_position: Vector2
var target_position: Vector2

var current_wp: int = 0      # Индекс текущей точки пути
var eggs_laid: int = 0       # Сколько яиц уже снесли на этой точке

@onready var egg_timer := $EggTimer
@onready var items_container := get_tree().get_current_scene().get_node("Items")

func _ready():
	home_position = global_position
	pick_new_target()
	
		# 1) Подключаем сигнал _до_ старта таймера
	egg_timer.connect("timeout", Callable(self, "_on_egg_timer_timeout"))
	# 2) Настраиваем и запускаем таймер
	egg_timer.wait_time = egg_interval
	egg_timer.one_shot = false
	egg_timer.start()      # вот здесь точно стартуем уже с подключённым обратным вызовом



func _process(delta):
	# Движение к случайной цели внутри круга вокруг home_position
	var dir = (target_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	# Когда дошли до target_position, выбираем новую
	if global_position.distance_to(target_position) < 10:
		pick_new_target()

func pick_new_target():
	# Рандомим следующую точку внутри круга move_radius от home_position
	var angle = randf() * TAU
	var radius = randf_range(0, move_radius)
	var offset = Vector2(cos(angle), sin(angle)) * radius
	target_position = home_position + offset

func _on_egg_timer_timeout() -> void:
	print("🐣 <timeout> on ", name, "@", global_position)
	if global_position.distance_to(home_position) > 20:
		print("    → ещё в пути, до дома:", global_position.distance_to(home_position))
		return

	# Считаем яйца поблизости
	var nearby := 0
	var items_container = get_tree().root.get_node("Main/Items")
	for child in items_container.get_children():
		if child is Item and child.item_name == "egg":
			if child.global_position.distance_to(global_position) <= egg_check_radius:
				nearby += 1

	if nearby >= max_eggs_nearby:
		# Слишком много яиц — ждем следующего таймаута
		return

	# Спавним яйцо
	var egg = item_scene.instantiate()
	egg.item_name = "egg"
	egg.global_position = global_position
	items_container.add_child(egg)

	eggs_laid += 1
	print("Курица #", name, "снесла яйцо:", eggs_laid, "/", eggs_per_point)

	# Достигли нормы — переходим к следующей точке маршрута
	if eggs_laid >= eggs_per_point:
		advance_waypoint()

func advance_waypoint() -> void:
	eggs_laid = 0
	if waypoints.size() == 0:
		return

	# Хитрость: идем по кругу
	current_wp = (current_wp + 1) % waypoints.size()
	home_position = waypoints[current_wp]
	pick_new_target()
	print("Курица #", name, "→ новая точка #", current_wp, ":", home_position)
