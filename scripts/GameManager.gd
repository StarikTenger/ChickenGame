extends Node

@onready var grid = $Grid
@onready var robot_container = $Robots

@onready var items_container := get_node("Items")
var item_scene := preload("res://scenes/items/Item.tscn")
var collector_scene := preload("res://scenes/robots/CollectorRobot.tscn")
var spawner_scene := preload("res://scenes/ClusterSpawner.tscn")

var coins: int = 0
signal coins_changed(value: int)

var collector_bot_price: int = 0
signal collector_price_changed(price: int)

func _ready():
	spawn_mega_consumer()
	spawn_cluster("egg", Vector2(300, 300))
	#spawn_resource_cluster("egg", Vector2(200, 300), 10)

func spawn_mega_consumer():
	var mega_scene = preload("res://scenes/robots/MegaConsumer.tscn")
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

	coins -= collector_bot_price
	print("Построен сборщик. Монеты: ", coins)
	
	# Повышаем цену после первой покупки
	if collector_bot_price == 0:
		collector_bot_price = 10
		collector_price_changed.emit(collector_bot_price)

func add_coins(amount: int):
	coins += amount
	coins_changed.emit(coins)
	print("Coins: ", coins)
	
func spawn_cluster(item_name: String, position: Vector2):
	var spawner = spawner_scene.instantiate()
	spawner.item_name = item_name
	spawner.global_position = position
	add_child(spawner)
