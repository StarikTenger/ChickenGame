extends Node2D
class_name Item

@export var item_name: String = "egg"

@onready var sprite := $Sprite2D

enum ItemState {
	GROUND, # lying on the ground, initial state
	ROBOT, # being hold by a robot 
	IN_FLIGHT, # in the air
	CONSUMED # being consumed by the slug
}

enum EggFreshnessState {
	FRESH,
	STALE,
	ROTTEN
}

var freshness_state: EggFreshnessState = EggFreshnessState.FRESH

func get_freshless_state() -> EggFreshnessState:
	return freshness_state

@export var time_to_stale := 20.0 # через сколько секунд яйцо станет несвежим
@export var time_to_rotten := 30.0 # через сколько секунд оно станет гнилым
@export var time_to_despawn := 5 # Despawn afer rot

var freshness_timer := 0.0

var state: ItemState = ItemState.GROUND
var current_owner: Node = null # robot or slug holding or about to hold the egg

# Source and destination positions, need for throwing the egg
var source_pos: Vector2 = Vector2(0,0)
var destination_pos: Vector2 = Vector2(0,0)

var flight_progress = 0 # 0 - start of flight, 1 - landing
var flight_progress_speed = 0 # Calculated from distance when throwing

func update_egg_freshless(delta: float) -> void:
	freshness_timer += delta
	if freshness_state == EggFreshnessState.FRESH and freshness_timer >= time_to_stale:
		freshness_state = EggFreshnessState.STALE
		print("Яйцо начало тухнуть")
		sprite.modulate = Color(1, 0.9, 0.6)
	elif freshness_state == EggFreshnessState.STALE and freshness_timer >= time_to_rotten:
		freshness_state = EggFreshnessState.ROTTEN
		print("Яйцо стухло")
		sprite.modulate = Color(0, 0, 0)
	elif freshness_state == EggFreshnessState.ROTTEN and freshness_timer >= time_to_rotten + time_to_despawn:
		# Only despawn if egg is on the ground
		if state == ItemState.GROUND:
			print("Rotten egg despawning")
			queue_free()


func collect_from_ground(new_owner: Node) -> bool:
	if state != ItemState.GROUND:
		return false # Cannot collect if not on ground

	self.current_owner = new_owner
	state = ItemState.ROBOT
	
	# Move item to owner's position
	position = new_owner.position
	
	print("Egg collected at owner position: ", new_owner.position)
	return true
	

func toss_to(target_owner: Node, source_position: Vector2, target_position: Vector2, speed: float):
	current_owner = target_owner
	state = ItemState.IN_FLIGHT
	source_pos = source_position
	destination_pos = target_position
	flight_progress = 0.0
	flight_progress_speed = speed

func catch_by_receiver():
	state = ItemState.ROBOT
	var flight_time = flight_progress / flight_progress_speed if flight_progress_speed > 0 else 0

	# Check that the owner is in correct position
	if current_owner.position.distance_to(destination_pos) > 10:
		print("Egg missed the receiver! Current position: ", current_owner.position, " | Expected position: ", destination_pos)
		state = ItemState.GROUND
		# break egg animation
		print(sprite.sprite_frames.get_animation_names())
		if "egg_splat" in sprite.sprite_frames.get_animation_names():
			# Play the egg splat animation before despawning
			sprite.play("egg_splat")
			await sprite.animation_finished
		current_owner.awaiting_egg = false
		queue_free()
		return

	if current_owner.has_method("receive_egg"):
		current_owner.receive_egg(self)
	print("Egg caught by receiver | Flight time: ", "%.2f" % flight_time, "s")

func _ready():
	add_to_group("items")
	#match item_name:
		#"egg":
			#sprite.texture = load("res://sprites/egg.png")
		#"egg2":
			#sprite.texture = load("res://sprites/items/egg2.png")
		#_:
			#sprite.texture = load("res://sprites/items/default.png")

func _process(delta):
	update_egg_freshless(delta)
	if state == ItemState.IN_FLIGHT:
		flight_progress += flight_progress_speed * delta
		
		if flight_progress >= 1.0:
			# Egg has reached destination
			flight_progress = 1.0
			position = destination_pos
			catch_by_receiver()
		else:
			# Interpolate position during flight
			var h = 100 # height of the parabolic arc
			# Using a parabolic trajectory formula for a more natural flight path
			position = source_pos.lerp(destination_pos, flight_progress) + Vector2(0, h * (4 * (flight_progress - 0.5) * (flight_progress - 0.5) - 1))

	if state == ItemState.ROBOT and current_owner:
		# Update the position of the item to follow the owner if they are moving
		position = current_owner.position
