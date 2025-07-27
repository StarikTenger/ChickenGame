extends TextureRect

var water_textures = [
	load("res://sprites/water0000.png"),
	load("res://sprites/water0001.png"),
	load("res://sprites/water0002.png")
]

var frame = 0
var frame_delay = 40
var frame_counter = 0

func _process(delta):
	frame_counter += 1
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if frame_counter >= frame_delay:
		frame_counter = 0
		frame = (frame + 1) % water_textures.size()
		texture = water_textures[frame]
