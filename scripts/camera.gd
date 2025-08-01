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
const DISTANCE_MAX: float = 3.5
const DISTANCE_MIN: float = 2.0
const DISTANCE_BOOST: float = 4.5

const OFFSET_NORMAL: float = 3.0
const OFFSET_DRIFT: float = 5.0

# Dynamic variables
var speed_factor: float
var target_offset: float
var target_camera_distance: float
var distance_lerp_factor: float

var FOVTween: Tween
var DistanceTween: Tween
var last_fov: float
var last_distance: float


func _ready():
	Camera.fov = FOV_NORMAL
	Camera.position.z = DISTANCE_NORMAL
	rotation.y = 0.0


func _process(delta):
	speed_factor = TestCar.current_speed / 70.0
	speed_factor = clamp(speed_factor, 0.0, 1.0)
	
	# Handle camera FOV and distance
	if TestCar.forward_direction == -1 and TestCar.acceleration_input < 0.0:
		fov_tween(FOV_MIN, 0.6, Tween.EASE_IN, Tween.TRANS_LINEAR)
		distance_tween(DISTANCE_MIN, 0.6, Tween.EASE_IN, Tween.TRANS_LINEAR)
	elif TestCar.is_boosting:
		fov_tween(FOV_BOOST, 0.5, Tween.EASE_IN_OUT, Tween.TRANS_BACK)
		distance_tween(DISTANCE_BOOST, 0.5, Tween.EASE_IN_OUT, Tween.TRANS_BACK)
	elif TestCar.forward_direction == 1 and TestCar.acceleration_input > 0.0:
		fov_tween(FOV_MAX, 0.6, Tween.EASE_IN, Tween.TRANS_LINEAR)
		distance_tween(DISTANCE_MAX, 0.6, Tween.EASE_IN, Tween.TRANS_LINEAR)
	else:
		fov_tween(FOV_NORMAL, 0.6, Tween.EASE_IN, Tween.TRANS_LINEAR)
		distance_tween(DISTANCE_NORMAL, 0.6, Tween.EASE_IN, Tween.TRANS_LINEAR)
	
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


func fov_tween(target_fov: float, duration: float, ease_type: Tween.EaseType, transition_type: Tween.TransitionType):
	if target_fov != last_fov:
		if FOVTween:
			FOVTween.kill()
		
		FOVTween = create_tween()
		FOVTween.set_ease(ease_type)
		FOVTween.set_trans(transition_type)
		FOVTween.tween_property(Camera, "fov", target_fov, duration)
		
		last_fov = target_fov


func distance_tween(target_distance: float, duration: float, ease_type: Tween.EaseType, transition_type: Tween.TransitionType):
	if target_distance != last_distance:
		if DistanceTween:
			DistanceTween.kill()
		
		DistanceTween = create_tween()
		DistanceTween.set_ease(ease_type)
		DistanceTween.set_trans(transition_type)
		DistanceTween.tween_property(Camera, "position:z", target_distance, duration)
		
		last_distance = target_distance
