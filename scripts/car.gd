extends Node3D

# Nodes
@onready var Ball = $Ball
@onready var Car = $Car
@onready var DriftTimer = $"DriftTimer"
@onready var BoostTimer = $"BoostTimer"
@onready var RayCast = $Car/RayCast

# Customizable parameters
const TOP_SPEED: float = 200.0
const MIN_SPEED: float = -150.0
const ACCELERATION: float = 5.0
const STEERING_STRENGTH: float = 12.5
const TURN_SPEED: float = 7.5

const DRIFT_FORCE_MIN: float = 0.1
const DRIFT_FORCE_MAX: float = 0.25

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
var drift_direction: float = 0.0
var drift_boost_stage: int = 0
var ground_normal: Vector3
var new_transform: Transform3D


func _physics_process(delta):
	# Attach car model to ball
	Car.transform.origin = Ball.transform.origin

	ball_speed = Ball.linear_velocity.length()
	forward_direction = round(-Car.global_transform.basis.z.normalized().dot(Ball.linear_velocity.normalized()))
	
	acceleration_input = Input.get_axis("Brake", "Accelerate")
	steering_input = Input.get_axis("Right", "Left")
	
	# Handle basic movement
	if acceleration_input > 0.0:
		speed_force = lerp(speed_force, acceleration_input * TOP_SPEED, ACCELERATION * delta)
	else:
		speed_force = lerp(speed_force, acceleration_input * abs(MIN_SPEED), ACCELERATION * delta)
	turn_force = lerp(turn_force, deg_to_rad(STEERING_STRENGTH) * steering_input, TURN_SPEED * delta)
	speed_force = clamp(speed_force, MIN_SPEED, TOP_SPEED)
	turn_force = clamp(turn_force, -0.2, 0.2)
	
	if not is_boosting:
		Ball.apply_central_force(-Car.global_transform.basis.z.normalized() * speed_force)
	else:
		Ball.apply_central_force(-Car.global_transform.basis.z.normalized() * DRIFT_BOOST_SPEED)
	
	# Handle drifting
	if Input.is_action_pressed("Drift") and not is_drifting and acceleration_input > 0.5 and abs(steering_input) > 0.5 and ball_speed > 20.0:
		var drift_force_average: float = (DRIFT_FORCE_MIN + DRIFT_FORCE_MAX) / 2.0
		if steering_input > 0.0:
			turn_force = drift_force_average
		else:
			turn_force = -drift_force_average
		start_drift()
	
	if is_drifting:
		drift()
		if Input.is_action_just_released("Drift") or speed_force < 1.0:
			stop_drift()
	
	if ball_speed > 0.75:
		turn(delta)
	
	if ball_speed < 20.0:
		is_drifting = false
		is_boosting = false
	
	drift_boost_stage = clamp(drift_boost_stage, 0, 3)
	
	# Align car to slopes
	if RayCast.is_colliding():
		ground_normal = RayCast.get_collision_normal()
		new_transform = align_with_y(Car.global_transform, ground_normal)
		Car.global_transform = Car.global_transform.interpolate_with(new_transform, 10.0 * delta)
	else:
		ground_normal = Vector3.UP
		new_transform = align_with_y(Car.global_transform, ground_normal)
		Car.global_transform = Car.global_transform.interpolate_with(new_transform, 5.0 * delta)
	
	# Automatically accelerate on touchscreen devices
	if DisplayServer.is_touchscreen_available():
		if not Input.is_action_pressed("Brake"):
			Input.action_press("Accelerate")
		else:
			Input.action_release("Accelerate")


func turn(delta):
	var new_basis = Car.global_transform.basis.rotated(Car.global_transform.basis.y, turn_force)
	Car.global_transform.basis = Car.global_transform.basis.slerp(new_basis, TURN_SPEED * delta)
	Car.global_transform = Car.global_transform.orthonormalized()


func start_drift():
	is_drifting = true
	drift_boost_stage = 0
	drift_direction = turn_force
	if DRIFT_STAGE_DELAY.has(drift_boost_stage):
		DriftTimer.start(DRIFT_STAGE_DELAY[drift_boost_stage])


func drift():
	var drift_amount: float = deg_to_rad(STEERING_STRENGTH * DRIFT_STRENGTH) * steering_input
	turn_force = drift_direction + drift_amount
	if drift_direction > 0.0:
		turn_force = clamp(turn_force, DRIFT_FORCE_MIN, DRIFT_FORCE_MAX)
	else:
		turn_force = clamp(turn_force, -DRIFT_FORCE_MAX, -DRIFT_FORCE_MIN)


func stop_drift():
	if drift_boost_stage > 0:
		is_boosting = true
		if DRIFT_BOOST_DURATION.has(drift_boost_stage):
			BoostTimer.start(DRIFT_BOOST_DURATION[drift_boost_stage])
	is_drifting = false
	drift_boost_stage = 0
	DriftTimer.stop()


func align_with_y(car_transform: Transform3D, new_y: Vector3):
	car_transform.basis.y = new_y
	car_transform.basis.x = -car_transform.basis.z.cross(new_y)
	return car_transform.orthonormalized()


func _on_drift_timer_timeout():
	if is_drifting:
		drift_boost_stage += 1
		if DRIFT_STAGE_DELAY.has(drift_boost_stage):
			DriftTimer.start(DRIFT_STAGE_DELAY[drift_boost_stage])


func _on_boost_timer_timeout():
	is_boosting = false
