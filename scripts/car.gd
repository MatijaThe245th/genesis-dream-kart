extends Node3D

# Nodes
@onready var Ball = $Ball
@onready var Car = $Car
@onready var BackLeftWheel = $"Car/Model/BackLeftWheel"
@onready var BackRightWheel = $"Car/Model/BackRightWheel"
@onready var FrontLeftWheel = $"Car/Model/FrontLeftWheel"
@onready var FrontRightWheel = $"Car/Model/FrontRightWheel"
@onready var WheelSpinReference = $Car/WheelSpinReference
@onready var CarModel = $Car/Model
@onready var DriftTimer = $"DriftTimer"
@onready var BoostTimer = $"BoostTimer"
@onready var Camera = $Car/Camera
@onready var ParticleEmitter = $"Car/ParticleEmitter"
@onready var DebugLabel = $"../UI/HUD/DebugLabel"

# Customizable parameters
const TOP_SPEED: float = 200.0
const STEERING_STRENGTH: float = 12.5
const TURN_SPEED: float = 7.5

const DRIFT_FORCE_MIN: float = 0.08
const DRIFT_FORCE_MAX: float = 0.225

const BODY_TILT_NORMAL: float = 1.0
const BODY_TILT_DRIFT: float = 0.2
const PARTICLE_OFFSET: float = 1.5

const CAMERA_FOV_NORMAL: float = 70.0
const CAMERA_FOV_MAX: float = 87.5
const CAMERA_FOV_MIN: float = 55.0
const CAMERA_FOV_BOOST: float = 95.0

const CAMERA_DISTANCE_NORMAL: float = 4.0
const CAMERA_DISTANCE_MAX: float = 3.75
const CAMERA_DISTANCE_MIN: float = 4.0
const CAMERA_DISTANCE_BOOST: float = 4.25

const CAMERA_OFFSET_NORMAL: float = 3.0
const CAMERA_OFFSET_DRIFT: float = 5.0

const DRIFT_STRENGTH: float = 0.5
const DRIFT_BOOST_SPEED: float = 250.0
const DRIFT_BOOST_DURATION: Dictionary = {
	1: 0.8,
	2: 1.3,
	3: 1.7,
}
const DRIFT_STAGE_DELAY: Dictionary = {
	0: 1.0,
	1: 1.5,
	2: 2.3,
}

# States
var is_drifting: bool = false
var is_boosting: bool = false

# Dynamic variables
var acceleration_input: float
var steering_input: float
var forward_direction: int = 0
var ball_speed: float = 0.0
var speed_force: float = 0.0
var turn_force: float = 0.0
var body_tilt: float = 0.0
var drift_direction: float = 0.0
var drift_boost_stage: int = 0


func _ready():
	CarModel.rotation_degrees.y = 180
	Camera.fov = CAMERA_FOV_NORMAL
	Camera.position.z = CAMERA_DISTANCE_NORMAL
	Camera.rotation.z = 0.0
	WheelSpinReference.rotation.x = 0.0


func _physics_process(_delta):
	# Attach car model to ball
	Car.transform.origin = Ball.transform.origin
	
	if not is_boosting:
		Ball.apply_central_force(-Car.global_transform.basis.z.normalized() * speed_force)
	else:
		Ball.apply_central_force(-Car.global_transform.basis.z.normalized() * DRIFT_BOOST_SPEED)


func _process(delta):
	ball_speed = Ball.linear_velocity.length()
	forward_direction = round(-Car.global_transform.basis.z.normalized().dot(Ball.linear_velocity.normalized()))
	
	# Handle basic movement
	acceleration_input = Input.get_action_strength("Accelerate") - Input.get_action_strength("Brake")
	steering_input = Input.get_action_strength("Left") - Input.get_action_strength("Right")
	
	speed_force = acceleration_input * TOP_SPEED
	turn_force = lerp(turn_force, deg_to_rad(STEERING_STRENGTH) * steering_input, 10 * delta)
	speed_force = clamp(speed_force, -150.0, 200.0)
	turn_force = clamp(turn_force, -0.2, 0.2)
	
	# Wheel spin
	WheelSpinReference.rotate_x(ball_speed * forward_direction * delta)
	BackLeftWheel.rotation.x = WheelSpinReference.rotation.x
	BackRightWheel.rotation.x = BackLeftWheel.rotation.x
	FrontLeftWheel.rotation.x = BackLeftWheel.rotation.x
	FrontRightWheel.rotation.x = BackLeftWheel.rotation.x
	
	# Front wheel rotation
	FrontLeftWheel.rotation.y = lerp(FrontLeftWheel.rotation.y, steering_input / 2, 10 * delta)
	FrontRightWheel.rotation.y = FrontLeftWheel.rotation.y
	
	# Smoke particle position and gravity
	ParticleEmitter.rotation.y = lerp(ParticleEmitter.rotation.y, turn_force, delta)
	ParticleEmitter.process_material.gravity.z = ball_speed / 10.0
	
	# Handle drifting
	if Input.is_action_pressed("Drift") and not is_drifting and acceleration_input > 0.5 and abs(steering_input) > 0.5 and ball_speed > 20.0:
		var drift_force_average: float = (DRIFT_FORCE_MIN + DRIFT_FORCE_MAX) / 2
		if steering_input > 0.0:
			turn_force = drift_force_average
		else:
			turn_force = -drift_force_average
		start_drift()
	
	if is_drifting:
		var drift_amount: float = deg_to_rad(STEERING_STRENGTH * DRIFT_STRENGTH) * steering_input
		turn_force = drift_direction + drift_amount
		if drift_direction > 0.0:
			turn_force = clamp(turn_force, DRIFT_FORCE_MIN, DRIFT_FORCE_MAX)
		else:
			turn_force = clamp(turn_force, -DRIFT_FORCE_MAX, -DRIFT_FORCE_MIN)
		body_tilt = BODY_TILT_DRIFT
	else:
		body_tilt = BODY_TILT_NORMAL
	
	if is_drifting and (Input.is_action_just_released("Drift") or speed_force < 1):
		stop_drift()
	
	if ball_speed > 0.75:
		turn(delta)
	
	if ball_speed < 20.0:
		is_drifting = false
	
	drift_boost_stage = clamp(drift_boost_stage, 0, 3)
	
	# Handle camera FOV and distance
	var speed_factor: float = clamp(ball_speed / 70.0, 0.0, 1.0)
	var target_fov: float = CAMERA_FOV_NORMAL
	var target_camera_distance: float = CAMERA_DISTANCE_NORMAL
	
	if forward_direction < 0:
		target_fov = lerp(CAMERA_FOV_NORMAL, CAMERA_FOV_MIN, speed_factor)
		target_camera_distance = lerp(CAMERA_DISTANCE_NORMAL, CAMERA_DISTANCE_MIN, speed_factor)
	elif is_boosting:
		target_fov = CAMERA_FOV_BOOST
		target_camera_distance = CAMERA_DISTANCE_BOOST
	else:
		target_fov = lerp(CAMERA_FOV_NORMAL, CAMERA_FOV_MAX, speed_factor)
		target_camera_distance = lerp(CAMERA_DISTANCE_NORMAL, CAMERA_DISTANCE_MAX, speed_factor)
	
	Camera.fov = lerp(Camera.fov, target_fov, 5 * delta)
	Camera.position.z = lerp(Camera.position.z, target_camera_distance, 5 * delta)
	
	if is_drifting:
		Camera.h_offset = lerp(Camera.h_offset, CAMERA_OFFSET_DRIFT * -drift_direction, 2.5 * delta)
	elif turn_force != 0.0 and ball_speed > 0.75:
		Camera.h_offset = lerp(Camera.h_offset, CAMERA_OFFSET_NORMAL * -turn_force * abs(acceleration_input), 2.5 * delta)
	else:
		Camera.h_offset = lerp(Camera.h_offset, 0.0, 2.5 * delta)
	
	# Automatically accelerate on touch screen devices
	if DisplayServer.is_touchscreen_available():
		if not Input.is_action_pressed("Brake"):
			Input.action_press("Accelerate")
		else:
			Input.action_release("Accelerate")
	
	# Show variables on screen
	DebugLabel.text = "speed_force: " + str(speed_force) + "\n" + "turn_force: " + str(turn_force) + "\n" + "ball_speed: " + str(ball_speed) + "\n" + "drift_boost_stage: " + str(drift_boost_stage) + "\n" + "forward_direction: " + str(forward_direction) + "\n" + "acceleration_input: " + str(acceleration_input) + "\n" + "steering_input: " + str(steering_input)


func turn(delta):
	var new_basis = Car.global_transform.basis.rotated(Car.global_transform.basis.y, turn_force)
	Car.global_transform.basis = Car.global_transform.basis.slerp(new_basis, TURN_SPEED * delta)
	Car.global_transform = Car.global_transform.orthonormalized()
	
	# Rotate car when turning
	CarModel.rotation.y = lerp(CarModel.rotation.y, PI + (turn_force / body_tilt), 10 * delta)
	CarModel.rotation.y = clamp(CarModel.rotation.y, PI + -2, PI + 2)
	
	# Fix particle emitter position
	ParticleEmitter.position.x = lerp(ParticleEmitter.position.x, (turn_force / body_tilt) * PARTICLE_OFFSET, 5 * delta)


func start_drift():
	is_drifting = true
	drift_boost_stage = 0
	drift_direction = turn_force
	if DRIFT_STAGE_DELAY.has(drift_boost_stage):
		DriftTimer.start(DRIFT_STAGE_DELAY[drift_boost_stage])


func stop_drift():
	if drift_boost_stage > 0:
		is_boosting = true
		if DRIFT_BOOST_DURATION.has(drift_boost_stage):
			BoostTimer.start(DRIFT_BOOST_DURATION[drift_boost_stage])
	is_drifting = false
	drift_boost_stage = 0
	DriftTimer.stop()


func _on_drift_timer_timeout():
	if is_drifting:
		drift_boost_stage += 1
		if DRIFT_STAGE_DELAY.has(drift_boost_stage):
			DriftTimer.start(DRIFT_STAGE_DELAY[drift_boost_stage])


func _on_boost_timer_timeout():
	is_boosting = false
