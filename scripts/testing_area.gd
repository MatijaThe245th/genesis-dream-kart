extends Node3D

# Nodes
@onready var TestCar: CharacterBody3D = $TestCar


func _ready():
	reset_car(Vector3(-427.5, 137.5, -5.0))


func _process(_delta):
	# Teleport to test areas
	if Input.is_action_just_pressed("Test Area 1"):
		reset_car(Vector3(-427.5, 137.5, -5.0))
	if Input.is_action_just_pressed("Test Area 2"):
		reset_car(Vector3(-830.0, 0.7, 55.0))


func reset_car(car_position: Vector3):
	TestCar.position = car_position
	TestCar.rotation = Vector3(0.0, 0.0, 0.0)
	TestCar.velocity = Vector3(0.0, 0.0, 0.0)
	TestCar.speed_force = 0.0
