extends Node3D

# Nodes
@onready var Ball = $Ball
@onready var Car = $Car
@onready var LeftWheel = $"Car/Model/wheel-front-left"
@onready var RightWheel = $"Car/Model/wheel-front-right"
@onready var CarBody = $Car/Model/body
@onready var DriftTimer = $"DriftTimer"
@onready var BoostTimer = $"BoostTimer"
@onready var Camera = $Car/Camera
@onready var ParticleEmitter = $"Car/ParticleEmitter"
@onready var DebugLabel = $"../UI/HUD/DebugLabel"

# Customizable parameters
const ACCELERATION: float = 150.0
const STEERING_STRENGTH: float = 15.0
const TURN_SPEED: float = 5.0

const BODY_TILT_NORMAL: float = 60.0
const BODY_TILT_DRIFTING: float = 30.0
const PARTICLE_OFFSET: float = 1.5

const CAMERA_FOV_NORMAL: float = 80.0
const CAMERA_FOV_MAX: float = 105.0
const CAMERA_FOV_REVERSE: float = 60.0
const CAMERA_FOV_BOOST: float = 110.0

const DRIFT_STRENGTH: float = 0.5
const DRIFT_BOOST_SPEED: float = 200.0
const DRIFT_BOOST_DURATION: Dictionary = {
	1: 0.8,
	2: 1.1,
	3: 1.4,
}

# States
var is_drifting: bool = false
var is_boosting: bool = false

# Dynamic variables
var forward_direction: Vector3
var ball_speed: float = 0.0
var speed_force: float = 0.0
var turn_force: float = 0.0
var body_tilt: float = 0.0
var drift_direction: float = 0.0
var drift_boost_stage: int = 0


func _physics_process(_delta):
	# Attach car model to ball
	forward_direction = -Car.global_transform.basis.z.normalized()
	Car.transform.origin = Ball.transform.origin
	
	if not is_boosting:
		Ball.apply_central_force(forward_direction * speed_force)
	else:
		Ball.apply_central_force(forward_direction * DRIFT_BOOST_SPEED)


func _process(delta):
	ball_speed = Ball.linear_velocity.length()
	
	var acceleration_input = Input.get_action_strength("Accelerate") - Input.get_action_strength("Brake")
	var steering_input = Input.get_action_strength("Left") - Input.get_action_strength("Right")
	
	speed_force = acceleration_input * ACCELERATION
	turn_force = deg_to_rad(STEERING_STRENGTH) * steering_input
	
	# Wheel model rotation
	LeftWheel.rotation.y = lerp(LeftWheel.rotation.y, turn_force, 10 * delta)
	RightWheel.rotation.y = lerp(RightWheel.rotation.y, turn_force, 10 * delta)
	
	# Smoke particle position and gravity
	ParticleEmitter.rotation.y = lerp(ParticleEmitter.rotation.y, turn_force, delta)
	ParticleEmitter.process_material.gravity.z = ball_speed / 10.0
	
	# Handle drifting
	if Input.is_action_pressed("Drift") and not is_drifting and turn_force != 0 and speed_force > 0:
		start_drift()
	
	if is_drifting:
		var drift_amount = deg_to_rad(STEERING_STRENGTH * DRIFT_STRENGTH) * steering_input
		turn_force = drift_direction + drift_amount
		body_tilt = BODY_TILT_DRIFTING
	else:
		body_tilt = BODY_TILT_NORMAL
	
	if is_drifting and (Input.is_action_just_released("Drift") or speed_force < 1):
		stop_drift()
	
	if ball_speed > 0.75:
		turn(delta)
	
	drift_boost_stage = clamp(drift_boost_stage, 0, 3)
	
	# Handle camera FOV
	var speed_factor = clamp(ball_speed / 70.0, 0.0, 1.0)
	var target_fov = CAMERA_FOV_NORMAL
	
	if forward_direction.dot(Ball.linear_velocity.normalized()) < 0.0:
		target_fov = lerp(CAMERA_FOV_NORMAL, CAMERA_FOV_REVERSE, speed_factor)
	elif is_boosting:
		target_fov = CAMERA_FOV_BOOST
	else:
		target_fov = lerp(CAMERA_FOV_NORMAL, CAMERA_FOV_MAX, speed_factor)
	
	Camera.fov = lerp(Camera.fov, target_fov, 10 * delta)
	
	# Automatically accelerate on touch screen devices
	if DisplayServer.is_touchscreen_available():
		if not Input.is_action_pressed("Brake"):
			Input.action_press("Accelerate")
		else:
			Input.action_release("Accelerate")
	
	# Show variables on screen
	DebugLabel.text = "speed_force: " + str(speed_force) + "\n" + "ball_speed: " + str(ball_speed) + "\n" + "drift_boost_stage: " + str(drift_boost_stage)


func turn(delta):
	var new_basis = Car.global_transform.basis.rotated(Car.global_transform.basis.y, turn_force)
	Car.global_transform.basis = Car.global_transform.basis.slerp(new_basis, TURN_SPEED * delta)
	Car.global_transform = Car.global_transform.orthonormalized()
	
	CarBody.rotation.y = lerp(CarBody.rotation.y, turn_force * ball_speed / body_tilt, 10 * delta)
	ParticleEmitter.position.x = lerp(ParticleEmitter.position.x, (turn_force * ball_speed / body_tilt) * PARTICLE_OFFSET, 5 * delta)


func start_drift():
	is_drifting = true
	drift_boost_stage = 0
	drift_direction = turn_force
	DriftTimer.start(1.0)


func stop_drift():
	if drift_boost_stage > 0:
		is_boosting = true
		BoostTimer.start(DRIFT_BOOST_DURATION[drift_boost_stage])
	is_drifting = false
	drift_boost_stage = 0
	DriftTimer.stop()


func _on_drift_timer_timeout():
	if is_drifting:
		drift_boost_stage += 1


func _on_boost_timer_timeout():
	is_boosting = false
