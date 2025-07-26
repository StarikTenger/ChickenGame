extends Control

@onready var collector_button := $BuildBar/CollectorSlot/VBoxContainer/CollectorButton
@onready var collector_label := $BuildBar/CollectorSlot/VBoxContainer/CollectorLabel
@onready var feedback_label := $FeedbackLabel
@onready var coins_label := $CoinsLabel
@onready var gm := get_node("/root/Main")
@onready var cam := get_node("/root/Main/MainCamera")

var ghost_target_position: Vector2
var ghost_lerp_speed := 20.0
var dragging := false
var ghost: Node = null
var collector_scene := preload("res://scenes/entities/Robot.tscn")

func _on_collector_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag()
		else:
			try_place_bot(get_global_mouse_position())

func start_drag():
	if ghost:
		ghost.queue_free()
	ghost = collector_scene.instantiate()
	ghost.is_ghost = true
	ghost.modulate = Color(1, 1, 1, 0.5)
	get_tree().root.get_node("Main").add_child(ghost)
	dragging = true

func _process(delta: float) -> void:
	if dragging and ghost:
		ghost.global_position = get_viewport().get_mouse_position()
		print(delta)

func try_place_bot(pos: Vector2):
	dragging = false
	if ghost:
		ghost.queue_free()
		ghost = null
	
	var price = gm.collector_bot_price
	if gm.coins < price:
		show_feedback("Недостаточно монет!")
		return
	
	var bot = collector_scene.instantiate()
	bot.is_ghost = false
	gm.robot_container.add_child(bot)
	bot.global_position = pos
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
	collector_button.gui_input.connect(_on_collector_input)
	feedback_label.visible = false
	gm.collector_price_changed.connect(update_collector_ui)
	gm.coins_changed.connect(update_collector_ui)
	update_collector_ui()

func update_collector_ui():
	print("Обновление UI: монет =", gm.coins, ", цена =", gm.collector_bot_price)
	var price = gm.collector_bot_price
	var can_afford = gm.coins >= price
	coins_label.text = str(gm.coins) + "$"

	collector_label.text = "Сборщик (" + str(price) + "$)"
	if can_afford:
		collector_button.modulate = Color.WHITE
	else:
		collector_button.modulate = Color(1, 1, 1, 0.3)
