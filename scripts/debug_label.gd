extends Label

# Nodes
@onready var TestCar: CharacterBody3D = $"../../../TestCar"

# Dynamic variables
var show_text: bool = false


func _ready():
	show_text = false


func _process(_delta):
	if Input.is_action_just_pressed("Debug Label"):
		if show_text == false:
			show_text = true
		else:
			show_text = false
	
	# Show variables on screen
	if show_text == true:
		text = "speed_force: " + str(TestCar.speed_force) + "\n" + "turn_force: " + str(TestCar.turn_force) + "\n" + "current_speed: " + str(TestCar.current_speed) + "\n" + "drift_boost_stage: " + str(TestCar.drift_boost_stage) + "\n" + "forward_direction: " + str(TestCar.forward_direction) + "\n" + "acceleration_input: " + str(TestCar.acceleration_input) + "\n" + "steering_input: " + str(TestCar.steering_input)
	else:
		text = ""
