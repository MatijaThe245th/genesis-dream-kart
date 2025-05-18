extends Node3D

@onready var Ball = $Ball
@onready var Car = $Car
@onready var RightWheel = $"Car/Model/wheel-front-right"
@onready var LeftWheel = $"Car/Model/wheel-front-left"
@onready var CarBody = $Car/Model/body
@onready var DriftTimer = $"Drift Timer"
@onready var BoostTimer = $"Boost Timer"
@onready var Camera = $Car/Camera
@onready var particle_emitter = $Car/GPUParticles3D

var acceleration: float = 150.0
var steering: float = 15.0
var turn_speed: float = 5.0
var body_tilt: float = 0.0

var speed_input: float = 0.0
var rotate_input: float = 0.0

var is_drifting: bool = false
var drift_direction: float = 0.0
var minimum_drift: bool = false
var boost_speed: float = 1.0
var drift_boost_speed: float = 200.0
var drift_boost_time_factor: int = 0
var drift_strength: float = 0.5


func _physics_process(_delta):
	Car.transform.origin = Ball.transform.origin
	if boost_speed == 1.0:
		Ball.apply_central_force(-Car.global_transform.basis.z * speed_input)
	else:
		Ball.apply_central_force(-Car.global_transform.basis.z * boost_speed)


func _process(delta):
	var car_speed = Ball.linear_velocity.length()
	var max_car_speed: float = 70.0
	
	speed_input = (Input.get_action_strength("Accelerate") - Input.get_action_strength("Brake")) * acceleration
	rotate_input = deg_to_rad(steering) * (Input.get_action_strength("Left") - Input.get_action_strength("Right"))
	LeftWheel.rotation.y = lerp(LeftWheel.rotation.y, rotate_input, 10 * delta)
	RightWheel.rotation.y = lerp(RightWheel.rotation.y, rotate_input, 10 * delta)
	particle_emitter.rotation.y = lerp(particle_emitter.rotation.y, rotate_input, delta)
	particle_emitter.process_material.gravity.z = car_speed / 10
	
	if Input.is_action_pressed("Drift") and not is_drifting and rotate_input != 0 and speed_input > 0:
		StartDrift()
	
	if is_drifting:
		var drift_amount: float = 0.0
		drift_amount += Input.get_action_strength("Left") - Input.get_action_strength("Right")
		drift_amount *= deg_to_rad(steering * drift_strength)
		rotate_input = drift_direction + drift_amount
		
		body_tilt = 20.0
	else:
		body_tilt = 60.0
	
	if is_drifting and (Input.is_action_just_released("Drift") or speed_input < 1):
		StopDrift()
	
	if car_speed > 0.75:
		RotateCar(delta)
	
	var speed_factor = clamp(car_speed / max_car_speed, 0.0, 1.0)
	var forward_direction = -Car.global_transform.basis.z
	
	var target_fov = 80.0
	
	if forward_direction.dot(Ball.linear_velocity) < 0.0:
		target_fov = lerp(80.0, 60.0, speed_factor)
	elif boost_speed != 1.0:
		target_fov = 110.0
	else:
		target_fov = lerp(80.0, 110.0, speed_factor)
	
	Camera.fov = lerp(Camera.fov, target_fov, 10 * delta)
	
	drift_boost_time_factor = clamp(drift_boost_time_factor, 0, 3)


func RotateCar(delta):
	var new_basis = Car.global_transform.basis.rotated(Car.global_transform.basis.y, rotate_input)
	Car.global_transform.basis = Car.global_transform.basis.slerp(new_basis, turn_speed * delta)
	Car.global_transform = Car.global_transform.orthonormalized()
	
	var t = rotate_input * Ball.linear_velocity.length() / body_tilt
	CarBody.rotation.y = lerp(CarBody.rotation.y, t, 10 * delta)
	particle_emitter.position.x = lerp(particle_emitter.position.x, t * 1.5, 0.005)


func StartDrift():
	is_drifting = true
	minimum_drift = false
	drift_direction = rotate_input
	DriftTimer.start(1.0)


func StopDrift():
	if minimum_drift:
		boost_speed = drift_boost_speed
		if drift_boost_time_factor == 1:
			BoostTimer.start(0.8)
		elif drift_boost_time_factor == 2:
			BoostTimer.start(1.1)
		elif drift_boost_time_factor == 3:
			BoostTimer.start(1.4)
	is_drifting = false
	minimum_drift = false
	drift_boost_time_factor = 0
	DriftTimer.stop()


func _on_drift_timer_timeout():
	if is_drifting:
		minimum_drift = true
	drift_boost_time_factor += 1


func _on_boost_timer_timeout():
	boost_speed = 1.0
