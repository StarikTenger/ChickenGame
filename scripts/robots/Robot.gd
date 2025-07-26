extends CharacterBody2D
class_name CollectorRobot

# Stats
@export var collect_radius: float = 64.0
@export var toss_radius: float = 256.0
@export var collect_delay: float = 1.0  # Time between collections
@export var toss_delay: float = 1 # time between catch and throw
@export var max_velocity: float = 1 # TODO: value
@export var tossing_speed: float = 100 # egg speed when tossing

var holding_egg: Node = null # Reference to the egg
var awaiting_egg: bool = false # If true, waiting for egg to arrive, cannot accept egg proposals

var collect_timer := 1.0
var toss_timer := 1.0

func try_collection(delta):
	collect_timer -= delta
	if collect_timer > 0:
		return 
	if holding_egg != null:
		return # Already holding an egg
	for item in get_tree().get_nodes_in_group("items"):
		if position.distance_to(item.position) <= collect_radius:
			
			holding_egg = item
			item.collect_from_ground(self)
			
			collect_timer = collect_delay  # Reset collection timer
			toss_timer = toss_delay # Reset toss timer when picking up egg
			break

# Find a robot in tossing radius and toss the egg
func try_tossing(delta):
	toss_timer -= delta
	if toss_timer > 0:
		return
	if holding_egg == null:
		return # No egg to toss
	
	# Find a suitable robot to toss to
	for robot in get_tree().get_nodes_in_group("robots"):
		if robot == self:
			continue # Don't toss to self
		if position.distance_to(robot.position) <= toss_radius:
			if not robot.awaiting_egg and robot.holding_egg == null:
				# Found a valid target, start tossing
				toss_egg_to(robot)
				toss_timer = toss_delay # Reset toss timer
				break

func toss_egg_to(target_robot: Node):
	if holding_egg == null:
		return
	
	# Set target as awaiting egg
	target_robot.awaiting_egg = true
	
	# Set up egg for flight
	holding_egg.state = holding_egg.ItemState.IN_FLIGHT
	holding_egg.current_owner = target_robot
	holding_egg.source_pos = position
	holding_egg.destination_pos = target_robot.position
	holding_egg.flight_progress = 0.0
	
	# Calculate flight speed based on distance and tossing speed
	var distance = position.distance_to(target_robot.position)
	holding_egg.flight_progress_speed = tossing_speed / distance
	
	# Release the egg
	holding_egg = null
	
	print("Egg tossed to robot at ", target_robot.position)

func _ready():
	add_to_group("robots")

func _physics_process(delta):
	try_collection(delta)
	try_tossing(delta)

func receive_egg(egg: Node):
	holding_egg = egg
	awaiting_egg = false
	toss_timer = toss_delay # Reset toss timer when receiving egg
	print("Robot received egg")
