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
var target_offset: float
var target_camera_distance: float
var fov_lerp_factor: float
var distance_lerp_factor: float


func _ready():
	Camera.fov = FOV_NORMAL
	Camera.position.z = DISTANCE_NORMAL
	rotation.y = 0.0


func _process(delta):
	speed_factor = TestCar.current_speed / 70.0
	speed_factor = clamp(speed_factor, 0.0, 1.0)
	
	# Handle camera FOV and distance
	if TestCar.forward_direction == -1 and TestCar.acceleration_input < 0.0:
		target_fov = FOV_MIN
		target_camera_distance = DISTANCE_MIN
		fov_lerp_factor = 5.0 * speed_factor
		distance_lerp_factor = 5.0 * speed_factor
	elif TestCar.is_boosting:
		target_fov = FOV_BOOST
		target_camera_distance = DISTANCE_BOOST
		fov_lerp_factor = 10.0
		distance_lerp_factor = 10.0
	elif TestCar.forward_direction == 1 and TestCar.acceleration_input > 0.0:
		target_fov = FOV_MAX
		target_camera_distance = DISTANCE_MAX
		fov_lerp_factor = 5.0 * speed_factor
		distance_lerp_factor = 5.0 * speed_factor
	else:
		target_fov = FOV_NORMAL
		target_camera_distance = DISTANCE_NORMAL
		fov_lerp_factor = 1.5
		distance_lerp_factor = 1.5
	
	Camera.fov = lerp(Camera.fov, target_fov, fov_lerp_factor * delta)
	Camera.position.z = lerp(Camera.position.z, target_camera_distance, distance_lerp_factor * delta)
	
	# Handle camera horizontal offset
	if TestCar.is_drifting:
		target_offset = OFFSET_DRIFT * -TestCar.drift_direction
	elif TestCar.turn_force != 0.0 and TestCar.current_speed > 0.75:
		target_offset = OFFSET_NORMAL * -TestCar.turn_force * abs(TestCar.acceleration_input)
	else:
		target_offset = 0.0
	
	Camera.h_offset = lerp(Camera.h_offset, target_offset, 2.5 * delta)
	
	# Flip camera when reversing
	if TestCar.acceleration_input < 0.0 and TestCar.speed_force < 0.0:
		rotation.y = lerp(rotation.y, -PI, 4.0 * delta)
	else:
		rotation.y = lerp(rotation.y, 0.0, 4.0 * delta)
