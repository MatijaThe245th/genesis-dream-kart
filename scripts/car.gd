extends CharacterBody3D

# Nodes
@onready var DriftTimer: Timer = $"DriftTimer"
@onready var BoostTimer: Timer = $"BoostTimer"
@onready var RayCast: RayCast3D = $RayCast

# Customizable parameters
const TOP_SPEED: float = 60.0
const MIN_SPEED: float = -45.0
const ACCELERATION: float = 1.75
const STEERING_STRENGTH: float = 12.0
const TURN_SPEED: float = 7.5
const GRAVITY: float = 50.0

const DRIFT_FORCE_MIN: float = 0.125
const DRIFT_FORCE_MAX: float = 0.275

const DRIFT_STRENGTH: float = 0.5
const DRIFT_BOOST_SPEED: float = 75.0
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
var acceleration_input: float = 0.0
var steering_input: float = 0.0
var forward_direction: int = 0
var current_speed: float = 0.0
var speed_force: float = 0.0
var turn_force: float = 0.0
var drift_direction: float = 0.0
var drift_boost_stage: int = 0
var ground_normal: Vector3 = Vector3.UP
var new_transform: Transform3D
var horizontal_velocity: Vector3
var vertical_velocity: Vector3
var drift_amount: float
var slope_angle: float
var normal_interpolation_speed: float


func _physics_process(delta):
	current_speed = velocity.length()
	if current_speed > 1.0:
		forward_direction = speed_force / abs(speed_force)
	else:
		forward_direction = 0
	
	acceleration_input = Input.get_axis("Brake", "Accelerate")
	steering_input = Input.get_axis("Right", "Left") * forward_direction
	
	# Handle basic movement
	if is_boosting:
		speed_force = DRIFT_BOOST_SPEED
		speed_force = clamp(speed_force, MIN_SPEED, DRIFT_BOOST_SPEED)
	elif acceleration_input > 0.0:
		speed_force = lerp(speed_force, acceleration_input * TOP_SPEED, ACCELERATION * delta)
		speed_force = clamp(speed_force, MIN_SPEED, TOP_SPEED)
	else:
		speed_force = lerp(speed_force, acceleration_input * abs(MIN_SPEED), ACCELERATION * delta)
		speed_force = clamp(speed_force, MIN_SPEED, TOP_SPEED)
	
	turn_force = lerp(turn_force, deg_to_rad(STEERING_STRENGTH) * steering_input, TURN_SPEED * delta)
	turn_force = clamp(turn_force, -0.2, 0.2)
	
	horizontal_velocity = -global_transform.basis.z.normalized() * speed_force
	
	if is_on_floor():
		vertical_velocity.y = 0.0
	else:
		vertical_velocity.y -= GRAVITY * delta
	
	velocity = horizontal_velocity + vertical_velocity * up_direction
	
	# Handle drifting
	if Input.is_action_pressed("Drift") and not is_drifting and acceleration_input > 0.5 and abs(steering_input) > 0.5 and current_speed > 20.0:
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
	else:
		drift_boost_stage = 0
		drift_direction = 0.0
		drift_amount = 0.0
	
	if current_speed > 0.5:
		turn(delta)
	
	if current_speed < 10.0 and not is_on_wall():
		is_drifting = false
		is_boosting = false
	
	drift_boost_stage = clamp(drift_boost_stage, 0, 3)
	
	# Align car to slopes
	if RayCast.is_colliding():
		ground_normal = RayCast.get_collision_normal()
		normal_interpolation_speed = 10.0
	else:
		ground_normal = Vector3.UP
		normal_interpolation_speed = 1.5
		
	new_transform = align_with_y(global_transform, ground_normal)
	global_transform = global_transform.interpolate_with(new_transform, normal_interpolation_speed * delta)
	
	up_direction = ground_normal
	slope_angle = rad_to_deg(acos(ground_normal.dot(Vector3.UP)))
	
	move_and_slide()


func turn(delta):
	var new_basis = global_transform.basis.rotated(global_transform.basis.y, turn_force)
	global_transform.basis = global_transform.basis.slerp(new_basis, TURN_SPEED * delta)
	global_transform = global_transform.orthonormalized()


func start_drift():
	is_drifting = true
	drift_boost_stage = 0
	drift_direction = turn_force
	if DRIFT_STAGE_DELAY.has(drift_boost_stage):
		DriftTimer.start(DRIFT_STAGE_DELAY[drift_boost_stage])


func drift():
	drift_amount = deg_to_rad(STEERING_STRENGTH * DRIFT_STRENGTH) * steering_input
	turn_force = drift_direction + drift_amount
	if drift_direction > 0.0:
		turn_force = clamp(turn_force, DRIFT_FORCE_MIN, DRIFT_FORCE_MAX)
		drift_direction = clamp(drift_direction, 0.0, 100.0)
	else:
		turn_force = clamp(turn_force, -DRIFT_FORCE_MAX, -DRIFT_FORCE_MIN)
		drift_direction = clamp(drift_direction, -100.0, 0.0)


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
