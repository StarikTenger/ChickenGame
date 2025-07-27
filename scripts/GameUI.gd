extends Control


@onready var collector_button := $BuildBar/CollectorRobot/CollectorButton
@onready var collector_label := $BuildBar/CollectorRobot/CollectorLabel
@onready var long_thrower_button := $BuildBar/LongRangedRobot/LongRangedButton
@onready var long_thrower_label := $BuildBar/LongRangedRobot/LongRangedLabel
@onready var feedback_label := $FeedbackLabel
@onready var coins_label := $CoinsInfo/CoinsLabel
@onready var gm := get_node("/root/Main")
@onready var cam := get_node("/root/Main/MainCamera")

var ghost_target_position: Vector2
var ghost_lerp_speed := 20.0
var dragging := false
var ghost: Node = null
var current_build_scene: PackedScene = null
var collector_scene := preload("res://scenes/entities/Robot.tscn")
var long_thrower_scene = preload("res://scenes/entities/LongRangedRobot.tscn")

func _on_collector_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			current_build_scene = collector_scene
			start_drag(current_build_scene)
		else:
			try_place_bot(cam.absolute_mouse_position())

func _on_long_thrower_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			current_build_scene = long_thrower_scene
			start_drag(current_build_scene)
		else:
			try_place_bot(cam.absolute_mouse_position())

func start_drag(scene: PackedScene):
	if ghost:
		ghost.queue_free()
	ghost = scene.instantiate()
	ghost.is_ghost = true
	ghost.modulate = Color(1, 1, 1, 0.5)
	get_tree().root.get_node("Main").add_child(ghost)
	dragging = true

func _process(delta: float) -> void:
	if dragging and ghost:
		ghost.global_position = cam.absolute_mouse_position()
		print(delta)
		
func is_position_valid(pos: Vector2) -> bool:
	var nav_maps := NavigationServer2D.get_maps()
	if nav_maps.is_empty():
		print("Нет карт в NavigationServer2D")
		return false

	var map_id := nav_maps[0]
	var closest := NavigationServer2D.map_get_closest_point(map_id, pos)

	# Проверка расстояния — если далеко, значит вне зоны
	return closest.distance_to(pos) < 8.0


func try_place_bot(pos: Vector2):
	dragging = false
	if ghost:
		ghost.queue_free()
		ghost = null
	
	if not is_position_valid(pos):
		show_feedback("You can not spawn it here")
		return
	
	var price = gm.collector_bot_price
	if gm.coins < price:
		show_feedback("Not enough money")
		return
	
	var bot = current_build_scene.instantiate()
	bot.is_ghost = false
	gm.robot_container.add_child(bot)
	bot.global_position = pos
	
	if bot.has_signal("robot_selected"):
		bot.connect("robot_selected", Callable(gm, "_on_robot_selected"))
	
	gm.coins -= price
	if price == 0:
		gm.collector_bot_price = 10
		gm.collector_price_changed.emit(10)

	gm.coins_changed.emit()

func show_feedback(text: String):
	feedback_label.text = text
	feedback_label.visible = true
	await get_tree().create_timer(2.0).timeout
	feedback_label.visible = false

func _ready():
	print("GameUI got gm:", gm, "class=", gm.get_class())
	collector_button.gui_input.connect(_on_collector_input)
	feedback_label.visible = false
	gm.collector_price_changed.connect(update_collector_ui)
	long_thrower_button.gui_input.connect(_on_long_thrower_input)
	gm.coins_changed.connect(update_collector_ui)
	update_collector_ui()

func update_collector_ui():
	print("Обновление UI: монет =", gm.coins, ", цена =", gm.collector_bot_price)
	var price = gm.collector_bot_price
	var can_afford = gm.coins >= price
	coins_label.text = "Balance: " + str(gm.coins) + "$"

	collector_label.text = "Tossing Robot (" + str(price) + "$)"
	long_thrower_label.text = "Long-Ranged\nTossing Robot (" + str(price) + "$)"
	
	if can_afford:
		collector_button.modulate = Color.WHITE
		long_thrower_button.modulate = Color.WHITE
	else:
		collector_button.modulate = Color(1, 1, 1, 0.3)
		long_thrower_button.modulate - Color(1, 1, 1, 0.3)
