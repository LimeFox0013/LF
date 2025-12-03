extends Node3D
class_name LFShaker
## LFShaker – Highly configurable camera/Node3D shaker for Godot 4.6 (camelCase)


@export var isEnabled: bool = true

@export_group("Shake Model")
@export var useTraumaModel: bool = true

@export_range(0.1, 10.0, 0.01)
var traumaDecayRate: float = 2.5

@export_range(0.5, 4.0, 0.01)
var traumaExponent: float = 2.0

@export_group("Translation")
@export var enableTranslation: bool = true
@export var translationStrength: Vector3 = Vector3(0.1, 0.1, 0.1)
@export_range(0.1, 60.0, 0.1)
var translationFrequency: float = 20.0

@export_group("Rotation")
@export var enableRotation: bool = true
@export var rotationStrengthDeg: Vector3 = Vector3(2.0, 2.0, 2.0)
@export_range(0.1, 60.0, 0.1)
var rotationFrequency: float = 25.0

@export_group("Noise")
@export var seedValue: int = 12345

@export_range(0.0, 1.0, 0.01)
var noiseRoughness: float = 0.5

@export_group("Behavior")
@export var autoResetOnIdle: bool = true
@export_range(0.0, 0.1, 0.001)
var idleTraumaThreshold: float = 0.001

@export var useOriginalTransformAsBase: bool = true

class Profile:
	var magnitude: float;
	var duration: float;
	var traumaDecayRate: float;
	var traumaExponent: float;
	var translationFrequency: float;
	var rotationFrequency: float;
	var noiseRoughness: float;
	
	func _init(
		magnitude := 0.5,
		duration := 0.2,
		traumaDecayRate := 2.5,
		traumaExponent := 1.0,
		translationFrequency := 20.0,
		rotationFrequency := 25.0,
		noiseRoughness := 0.5,
	):
		self.magnitude = magnitude;
		self.duration = duration;
		self.traumaDecayRate = traumaDecayRate;
		self.traumaExponent = traumaExponent;
		self.translationFrequency = translationFrequency;
		self.rotationFrequency = rotationFrequency;
		self.noiseRoughness = noiseRoughness;
		
		#static func fromShaker(shaker: LFShaker):
			#pass;

# ------------------------------------------------
# Internal state
# ------------------------------------------------
var noiseGen: FastNoiseLite
var timeCounter: float = 0.0
var traumaValue: float = 0.0
var timeLeft: float = 0.0

var originalTransform: Transform3D
var hasOriginal: bool = false


func _ready() -> void:
	originalTransform = transform
	hasOriginal = true

	setupNoise()


func _process(delta: float) -> void:
	if not isEnabled:
		return

	timeCounter += delta

	if useTraumaModel:
		if traumaValue <= 0.0:
			if autoResetOnIdle and hasOriginal:
				transform = originalTransform
			return
		traumaValue = max(traumaValue - traumaDecayRate * delta, 0.0)
	else:
		if timeLeft <= 0.0 or traumaValue <= 0.0:
			if autoResetOnIdle and hasOriginal:
				transform = originalTransform
			return
		timeLeft -= delta
		if timeLeft <= 0.0:
			traumaValue = 0.0
			if autoResetOnIdle and hasOriginal:
				transform = originalTransform
			return

	var intensity := pow(traumaValue, traumaExponent)
	if intensity < idleTraumaThreshold:
		if autoResetOnIdle and hasOriginal:
			transform = originalTransform
		return

	var translationOffset := Vector3.ZERO
	var rotationOffset := Vector3.ZERO

	if enableTranslation:
		translationOffset = computeTranslation(intensity)
	if enableRotation:
		rotationOffset = computeRotation(intensity)

	var base := transform
	if useOriginalTransformAsBase and hasOriginal:
		base = originalTransform

	var shaken := base
	shaken.origin += translationOffset

	if rotationOffset != Vector3.ZERO:
		var rotBasis := Basis.from_euler(rotationOffset)
		shaken.basis = rotBasis * base.basis

	transform = shaken


# ------------------------------------------------
# Public API
# ------------------------------------------------

func addTrauma(amount: float) -> void:
	traumaValue = clamp(traumaValue + amount, 0.0, 1.0)


func setTrauma(value: float) -> void:
	traumaValue = clamp(value, 0.0, 1.0)


func shake(magnitude: float = 0.5, duration: float = 0.2) -> void:
	magnitude = clamp(magnitude, 0.0, 1.0)
	if useTraumaModel:
		addTrauma(magnitude)
	else:
		traumaValue = magnitude
		timeLeft = max(duration, 0.0)


func applyShakeProfile(shakeProfile: Profile):
	self.traumaDecayRate = traumaDecayRate;
	self.traumaExponent = traumaExponent;
	self.translationFrequency = translationFrequency;
	self.rotationFrequency = rotationFrequency;
	self.noiseRoughness = noiseRoughness;
	shake(shakeProfile.magnitude, shakeProfile.duration);


func stopShake(resetTransform: bool = true) -> void:
	traumaValue = 0.0
	timeLeft = 0.0
	if resetTransform and hasOriginal:
		transform = originalTransform


func recaptureOriginalTransform() -> void:
	originalTransform = transform
	hasOriginal = true


# ------------------------------------------------
# Internal helpers
# ------------------------------------------------

func setupNoise() -> void:
	noiseGen = FastNoiseLite.new()
	noiseGen.seed = seedValue

	var freq: float = lerp(0.5, 4.0, noiseRoughness)
	noiseGen.frequency = freq
	noiseGen.fractal_octaves = int(round(lerp(1.0, 4.0, noiseRoughness)))
	noiseGen.fractal_lacunarity = lerp(1.5, 3.5, noiseRoughness)
	noiseGen.fractal_gain = lerp(0.4, 0.9, noiseRoughness)


func computeTranslation(intensity: float) -> Vector3:
	var t := timeCounter * translationFrequency

	var nx := noiseGen.get_noise_1d(t + 37.1)
	var ny := noiseGen.get_noise_1d(t + 91.7)
	var nz := noiseGen.get_noise_1d(t + 159.3)

	var n := Vector3(nx, ny, nz)
	return Vector3(
		n.x * translationStrength.x,
		n.y * translationStrength.y,
		n.z * translationStrength.z
	) * intensity


func computeRotation(intensity: float) -> Vector3:
	var t := timeCounter * rotationFrequency

	var nx := noiseGen.get_noise_1d(t + 11.1)
	var ny := noiseGen.get_noise_1d(t + 53.8)
	var nz := noiseGen.get_noise_1d(t + 204.6)

	var n := Vector3(nx, ny, nz)

	var rs := Vector3(
		deg_to_rad(rotationStrengthDeg.x),
		deg_to_rad(rotationStrengthDeg.y),
		deg_to_rad(rotationStrengthDeg.z)
	)

	return Vector3(
		n.x * rs.x,
		n.y * rs.y,
		n.z * rs.z
	) * intensity
