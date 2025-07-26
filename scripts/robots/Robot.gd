extends CharacterBody2D
class_name CollectorRobot

@export var collect_radius: float = 64.0
@export var max_capacity: int = 10
var storage: Dictionary = {}
var stored_type: String = ""

#движение 
var target_position: Vector2
var is_moving: bool = false
var speed: float = 100.0

signal robot_selected(robot)

@onready var selection_frame = $SelectionFrame

@export var collect_delay: float = 1.0  # задержка в секундах
var collect_timer := 1.0



func _process(delta):
	if is_moving:
		var direction = (target_position - position).normalized()
		velocity = direction * speed

		# Если дошли почти до точки
		if position.distance_to(target_position) < 5:
			velocity = Vector2.ZERO
			is_moving = false
		
		move_and_slide()

func _physics_process(delta):
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
			


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("robot_selected", self)

func set_selected(is_selected: bool):
	selection_frame.visible = is_selected
