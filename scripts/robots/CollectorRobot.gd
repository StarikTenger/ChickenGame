extends CharacterBody2D
class_name CollectorRobot

@export var is_ghost: bool = false

@export var collect_radius: float = 64.0
@export var max_capacity: int = 10
var storage: Dictionary = {}
var stored_type: String = ""

@export var collect_delay: float = 1.0  # задержка в секундах
var collect_timer := 1.0

func _physics_process(delta):
	if is_ghost:
		return
	
	collect_timer -= delta
	if collect_timer > 0:
		return
	print("Stored: ", storage)
	for item in get_tree().get_nodes_in_group("items"):
		if position.distance_to(item.position) <= collect_radius:
			if stored_type == "":
				stored_type = item.item_name
			if item.item_name != stored_type:
				continue
			# Собираем

			var current_amount = storage.get(stored_type, 0)
			if current_amount >= max_capacity:
				return  # перегруз — ничего не собираем

			storage[stored_type] = storage.get(stored_type, 0) + 1
			item.queue_free()
			collect_timer = collect_delay  # сбрасываем таймер
			print("Собрал: ", stored_type, ", всего: ", storage[stored_type])
			break
