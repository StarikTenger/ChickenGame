extends StaticBody2D

@onready var poly2d = $Polygon2D
@onready var collision = $CollisionPolygon2D

func _ready():
	poly2d.polygon = collision.polygon
	poly2d.position = collision.position
