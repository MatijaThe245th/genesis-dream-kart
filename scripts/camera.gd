extends Node3D

# Nodes
@onready var TestCar: CharacterBody3D = $".."
@onready var Camera: Camera3D = $Camera

# Customizable parameters
const FOV_NORMAL: float = 70.0
const FOV_MAX: float = 82.5
const FOV_MIN: float = 57.5
const FOV_BOOST: float = 95.0

const DISTANCE_NORMAL: float = 4.0
const DISTANCE_MAX: float = 3.8
const DISTANCE_MIN: float = 4.2
const DISTANCE_BOOST: float = 4.1

const OFFSET_NORMAL: float = 3.0
const OFFSET_DRIFT: float = 5.0

# Dynamic variables
var speed_factor: float
var target_fov: float
var target_camera_distance: float


func _ready():
	Camera.fov = FOV_NORMAL
	Camera.position.z = DISTANCE_NORMAL
	rotation.y = 0.0


func _process(delta):
	speed_factor = TestCar.current_speed / 70.0
	speed_factor = clamp(speed_factor, 0.0, 1.0)
	
	# Handle camera FOV and distance
	if TestCar.forward_direction == -1:
		target_fov = lerp(FOV_NORMAL, FOV_MIN, speed_factor)
		target_camera_distance = lerp(DISTANCE_NORMAL, DISTANCE_MIN, speed_factor)
	elif TestCar.is_boosting:
		target_fov = FOV_BOOST
		target_camera_distance = DISTANCE_BOOST
	else:
		target_fov = lerp(FOV_NORMAL, FOV_MAX, speed_factor)
		target_camera_distance = lerp(DISTANCE_NORMAL, DISTANCE_MAX, speed_factor)
	
	Camera.fov = lerp(Camera.fov, target_fov, 5.0 * delta)
	Camera.position.z = lerp(Camera.position.z, target_camera_distance, 5.0 * delta)
	
	# Handle camera horizontal offset
	if TestCar.is_drifting:
		Camera.h_offset = lerp(Camera.h_offset, OFFSET_DRIFT * -TestCar.drift_direction, 2.5 * delta)
	elif TestCar.turn_force != 0.0 and TestCar.current_speed > 0.75:
		Camera.h_offset = lerp(Camera.h_offset, OFFSET_NORMAL * -TestCar.turn_force * abs(TestCar.acceleration_input), 2.5 * delta)
	else:
		Camera.h_offset = lerp(Camera.h_offset, 0.0, 2.5 * delta)
	
	# Flip camera when reversing
	if TestCar.acceleration_input < 0.0 and TestCar.speed_force < 0.0:
		rotation.y = lerp(rotation.y, -PI, 4.0 * delta)
	else:
		rotation.y = lerp(rotation.y, 0.0, 4.0 * delta)
