extends Camera3D

# Nodes
@onready var TestCar = $"../.."

# Customizable parameters
const FOV_NORMAL: float = 70.0
const FOV_MAX: float = 87.5
const FOV_MIN: float = 55.0
const FOV_BOOST: float = 95.0

const DISTANCE_NORMAL: float = 4.0
const DISTANCE_MAX: float = 3.75
const DISTANCE_MIN: float = 4.0
const DISTANCE_BOOST: float = 4.25

const OFFSET_NORMAL: float = 3.0
const OFFSET_DRIFT: float = 5.0


func _ready():
	fov = FOV_NORMAL
	position.z = DISTANCE_NORMAL


func _process(delta):
	var speed_factor: float = clamp(TestCar.ball_speed / 70.0, 0.0, 1.0)
	var target_fov: float = FOV_NORMAL
	var target_camera_distance: float = DISTANCE_NORMAL
	
	# Handle camera FOV and distance
	if TestCar.forward_direction < 0:
		target_fov = lerp(FOV_NORMAL, FOV_MIN, speed_factor)
		target_camera_distance = lerp(DISTANCE_NORMAL, DISTANCE_MIN, speed_factor)
	elif TestCar.is_boosting:
		target_fov = FOV_BOOST
		target_camera_distance = DISTANCE_BOOST
	else:
		target_fov = lerp(FOV_NORMAL, FOV_MAX, speed_factor)
		target_camera_distance = lerp(DISTANCE_NORMAL, DISTANCE_MAX, speed_factor)
	
	fov = lerp(fov, target_fov, 5 * delta)
	position.z = lerp(position.z, target_camera_distance, 5 * delta)
	
	# Handle camera horizontal offset
	if TestCar.is_drifting:
		h_offset = lerp(h_offset, OFFSET_DRIFT * -TestCar.drift_direction, 2.5 * delta)
	elif TestCar.turn_force != 0.0 and TestCar.ball_speed > 0.75:
		h_offset = lerp(h_offset, OFFSET_NORMAL * -TestCar.turn_force * abs(TestCar.acceleration_input), 2.5 * delta)
	else:
		h_offset = lerp(h_offset, 0.0, 2.5 * delta)
