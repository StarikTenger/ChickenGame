extends StaticBody2D

@onready var poly2d = $Polygon2D
@onready var collision = $CollisionPolygon2D

func _ready():
	poly2d.polygon = collision.polygon
	poly2d.position = collision.position
	poly2d.texture_scale = Vector2(1.0, 1.0) * 4.0
	poly2d.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

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
	if frame_counter >= frame_delay:
		frame_counter = 0
		frame = (frame + 1) % water_textures.size()
		poly2d.texture = water_textures[frame]
