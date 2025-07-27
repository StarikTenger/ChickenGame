extends "res://scripts/robots/Robot.gd"
class_name LongRangedRobot

func _ready():
	# Вызови оригинальный _ready()
	super._ready()

	# Измени параметры для "дальнего метателя"
	toss_radius = 400.0       # кидает дальше
	tossing_speed = 60.0      # медленнее летит
	collect_radius = 64.0     # можно оставить как у обычного
	collect_delay = 1.0       # скорость сбора
	toss_delay = 2.0          # дольше думает перед киданием

	# Добавим в другую группу, если нужно
	# add_to_group("long_throwers")
