extends Camera2D

var dragging := false
var drag_start_screen_pos := Vector2.ZERO
var drag_start_camera_pos := Vector2.ZERO
var target_position: Vector2

@export var zoom_step := 0.1
@export var zoom_min := 0.2
@export var zoom_max := 3.0
var smooth_speed := 10.0

func _ready():
	target_position = global_position

func _unhandled_input(event):
	# ПКМ: начать/остановить перетаскивание
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			dragging = true
			drag_start_screen_pos = get_viewport().get_mouse_position()
			print("M1 - ", drag_start_camera_pos)
			drag_start_camera_pos = target_position
		else:
			dragging = false

	# Колёсико мыши: зум
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			apply_zoom(zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			apply_zoom(-zoom_step)

func _process(delta):
	if dragging:
		var current_mouse_pos = get_viewport().get_mouse_position()
		print("M2 - ", current_mouse_pos)
		var delta_pixels = (drag_start_screen_pos - current_mouse_pos) / zoom / zoom
		target_position = drag_start_camera_pos + delta_pixels * zoom
	
	global_position = global_position.lerp(target_position, delta * smooth_speed)

func apply_zoom(amount: float):
	var new_zoom = zoom + Vector2(amount, amount)
	new_zoom.x = clamp(new_zoom.x, zoom_min, zoom_max)
	new_zoom.y = clamp(new_zoom.y, zoom_min, zoom_max)
	zoom = new_zoom
