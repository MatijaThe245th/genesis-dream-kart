extends Node3D

# Nodes
@onready var TestCar: CharacterBody3D = $"../.."
@onready var ParticleEmitter: GPUParticles3D = $"../ParticleEmitter"
@onready var WheelSpinReference: Node3D = $"../WheelSpinReference"
@onready var BackLeftWheel: MeshInstance3D = $BackLeftWheel
@onready var BackRightWheel: MeshInstance3D = $BackRightWheel
@onready var FrontLeftWheel: MeshInstance3D = $FrontLeftWheel
@onready var FrontRightWheel: MeshInstance3D = $FrontRightWheel
@onready var AnimPlayer: AnimationPlayer = $"../../AnimPlayer"

# Customizable parameters
const BODY_TILT_NORMAL: float = 0.9
const BODY_TILT_DRIFT: float = 0.225
const PARTICLE_OFFSET: float = 1.5

# Dynamic variables
var body_tilt: float


func _ready():
	rotation_degrees.y = 180.0
	WheelSpinReference.rotation.x = 0.0


func _process(delta):
	if TestCar.is_drifting:
		body_tilt = BODY_TILT_DRIFT
	else:
		body_tilt = BODY_TILT_NORMAL
	
	# Rotate car when turning
	if TestCar.current_speed > 0.75:
		rotation.y = lerp(rotation.y, PI + (TestCar.turn_force / body_tilt), 10.0 * delta)
		rotation.y = clamp(rotation.y, PI - 2.0, PI + 2.0)
		ParticleEmitter.position.x = lerp(ParticleEmitter.position.x, (TestCar.turn_force / body_tilt) * PARTICLE_OFFSET, 5 * delta)
	else:
		rotation.y = lerp(rotation.y, PI, 10.0 * delta)
		ParticleEmitter.position.x = lerp(ParticleEmitter.position.x, 0.0, 5 * delta)
	
	# Wheel spin
	WheelSpinReference.rotate_x(TestCar.current_speed * TestCar.forward_direction * delta)
	BackLeftWheel.rotation.x = WheelSpinReference.rotation.x
	BackRightWheel.rotation.x = WheelSpinReference.rotation.x
	FrontLeftWheel.rotation.x = WheelSpinReference.rotation.x
	FrontRightWheel.rotation.x = WheelSpinReference.rotation.x
	
	# Front wheel rotation
	FrontLeftWheel.rotation.y = lerp(FrontLeftWheel.rotation.y, TestCar.steering_input / 2.0, 10.0 * delta)
	FrontRightWheel.rotation.y = FrontLeftWheel.rotation.y
	
	# Smoke particle position and gravity
	ParticleEmitter.rotation.y = lerp(ParticleEmitter.rotation.y, TestCar.turn_force, delta)
	ParticleEmitter.process_material.gravity.z = TestCar.current_speed / 10.0
	
	# Wheel glow based on drift stage
	AnimPlayer.play("Drift Boost Stage " + str(TestCar.drift_boost_stage))
