extends Node2D

var game_manager: Node

var preferred_item: String = ""
var total_eaten: Dictionary = {}

var mood: int = 50  # начальное настроение
var awaiting_egg: bool = false # If true, waiting for egg to arrive
var holding_egg: Node = null # Reference to the egg being delivered

signal game_over
signal level_complete

func _ready():
	randomize()
	add_to_group("slugs")  # Add slug to group for robot discovery
	preferred_item = get_random_item_name()
	print("Пожиратель хочет: ", preferred_item)
#	start_random_change_timer()

func consume(item: String, amount: int):
	total_eaten[item] = total_eaten.get(item, 0) + amount
	
	if item == preferred_item:
		# Поднимаем настроение
		mood = min(mood + amount, 100)
		if game_manager:
			game_manager.add_coins(game_manager.egg_cost * amount)
	else:
		# Неправильная еда — падает настроение
		mood = max(mood - amount, 0)

	print("Съел: ", item, " | Настроение: ", mood, " | Любимая еда: ", preferred_item)
	
	# Проверка победы или поражения
	if mood == 0:
		print("Пожиратель в депрессии. Проигрыш")
		game_over.emit()
		return
	
	if mood == 100:
		print("Пожиратель наелся! Победа")
		level_complete.emit()
		return

func set_preferred_item(new_item: String):
	preferred_item = new_item
	print("Теперь Пожиратель хочет: ", preferred_item)
	
func get_random_item_name() -> String:
	var all = ["chicken_egg", "omlet", "fried_egg", "scrambled_egg"]
	return all[randi() % all.size()]
	
#func start_random_change_timer():
#	var timer := Timer.new()
#	timer.wait_time = 10.0
#	timer.one_shot = false
#	timer.autostart = true
#	timer.timeout.connect(change_preference_randomly)
#	add_child(timer)
	
func change_preference_randomly():
	var new_item = get_random_item_name()
	if new_item != preferred_item:
		set_preferred_item(new_item)

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
