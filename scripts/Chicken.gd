extends CharacterBody2D

# Список путей — укажите в Инспекторе: Route1, Route2, …
@export var routes: Array[NodePath] = []
# Индекс текущего пути в массиве
var current_route: int = 0
# Ссылка на родительский PathFollow2D
var pf: PathFollow2D
@export var path_speed := 0.2   # скорость вдоль кривой [0..1]/сек

@export var eggs_per_point: int = 5
var eggs_laid: int = 0

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
	print(">>> routes[0] =", routes[0], "typeof =", typeof(routes[0]))
	# находим PathFollow2D — он родитель курицы
	pf = get_parent() as PathFollow2D
	if routes.size() > 0:
		pf.path = routes[0]
	
	
	egg_timer.connect("timeout", Callable(self, "_on_egg_timer_timeout"))
	egg_timer.wait_time = egg_interval
	egg_timer.one_shot = false
	egg_timer.start()
	
	#home_position = global_position
	#pick_new_target()
	#egg_timer.wait_time = egg_interval
	#egg_timer.start()

func _process(delta):
	pf.unit_offset = (pf.unit_offset + delta * path_speed) % 1.0

	#pf.unit_offset = (pf.unit_offset + delta * speed) % 1.0
	#var dir = (target_position - global_position).normalized()
	#velocity = dir * speed
	#var chicken_sprite = $Sprite2D
	#if velocity.x != 0:
		#chicken_sprite.scale.x = - sign(velocity.x) * abs(chicken_sprite.scale.x)
	#move_and_slide()
#
	#if global_position.distance_to(target_position) < 10:
		#pick_new_target()

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
	eggs_laid += 1
	print("Курица снесла яйцо. Сейчас яиц вокруг:", nearby_eggs + 1)
	if eggs_laid >= eggs_per_point:
		advance_route()

func advance_route():
	current_route = (current_route + 1) % routes.size()
	pf.path = routes[current_route]
	pf.unit_offset = 0    # или pf.offset = 0, чтобы начать сначала
	eggs_laid = 0
	print("🐤 switched to route #", current_route)
