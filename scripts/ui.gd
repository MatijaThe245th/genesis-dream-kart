extends CanvasLayer

# Nodes
@onready var TestCar: CharacterBody3D = $"../TestCar"
@onready var DebugLabel: Label = $HUD/DebugLabel

# Dynamic variables
var show_text: bool = true
var accelerate_toggle: bool = false
var brake_toggle: bool = false
var touch_controls: bool = false


func _ready():
	show_text = true
	accelerate_toggle = false
	brake_toggle = false
	touch_controls = false


func _process(_delta):
	if touch_controls:
		if accelerate_toggle == true:
			Input.action_press("Accelerate")
		else:
			Input.action_release("Accelerate")
		if brake_toggle == true:
			Input.action_press("Brake")
		else:
			Input.action_release("Brake")
	
	if Input.is_action_just_pressed("Debug Label"):
		show_text = not show_text
	
	# Show variables on screen
	if show_text == true:
		DebugLabel.text = "speed_force: " + str(accelerate_toggle) + "\n" + "turn_force: " + str(brake_toggle) + "\n" + "current_speed: " + str(TestCar.current_speed) + "\n" + "drift_boost_stage: " + str(TestCar.drift_boost_stage) + "\n" + "forward_direction: " + str(TestCar.forward_direction) + "\n" + "acceleration_input: " + str(TestCar.acceleration_input) + "\n" + "steering_input: " + str(TestCar.steering_input) + "\n" + "drift_direction: " + str(TestCar.drift_direction) + "\n" + "drift_amount: " + str(TestCar.drift_amount) + "\n" + "is_drifting: " + str(TestCar.is_drifting) + "\n" + "slope_angle: " + str(TestCar.slope_angle)
	else:
		DebugLabel.text = ""


func _input(event):
	if event is InputEventKey or event is InputEventJoypadButton:
		touch_controls = false
	else:
		touch_controls = true


func _on_accelerate_released():
	accelerate_toggle = not accelerate_toggle
	if brake_toggle == true:
		brake_toggle = false


func _on_brake_released():
	brake_toggle = not brake_toggle
	if accelerate_toggle == true:
		accelerate_toggle = false
