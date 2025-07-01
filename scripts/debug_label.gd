extends Label

@onready var TestCar = $"../../../Car"


func _process(_delta):
	# Show variables on screen
	text = "speed_force: " + str(TestCar.speed_force) + "\n" + "turn_force: " + str(TestCar.turn_force) + "\n" + "ball_speed: " + str(TestCar.ball_speed) + "\n" + "drift_boost_stage: " + str(TestCar.drift_boost_stage) + "\n" + "forward_direction: " + str(TestCar.forward_direction) + "\n" + "acceleration_input: " + str(TestCar.acceleration_input) + "\n" + "steering_input: " + str(TestCar.steering_input)
