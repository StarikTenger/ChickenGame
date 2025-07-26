extends Control

@onready var build_button := $VBoxContainer/Button
@onready var gm := get_node("/root/Main")

func _ready():
	build_button.pressed.connect(on_build_collector_pressed)
	gm.collector_price_changed.connect(update_price_text)
	update_price_text(gm.collector_bot_price)

func on_build_collector_pressed():
	if gm.coins >= 0:  # для бесплатного первого бота
		gm.spawn_collector_bot()

func update_price_text(price: int):
	build_button.text = "Построить сборщика (" + str(price) + "$)"
