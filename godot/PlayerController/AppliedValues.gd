extends Resource

class_name PlatformerController2DAppliedValues

## Reference to parent node.
var parent: PlatformerController2D
## Gravity mode.
var gravityActive: bool = true
## Current gravity.
var gravity: float
## Used to check for x or y inputs.
var movementInputMonitoring: Vector2 = Vector2.ONE
## Acceleration.
var acceleration: float
## Deceleration
var deceleration: float
## Final jump after applying gravity.
var jumpMagnitude: float
## Current amount of jumps.
var jumpCount: int
## Current speed.
var speed: float
## Current max vertical velocity.
var terminalVelocity: float
## Acceleration mode.
var instantAccel: bool = false
## Deceleration mode.
var instantStop: bool = false
## Jump buffer bool.
var jumpWasPressed: bool = false
## Coyote time bool.
var coyoteActive: bool = false
## Moving right bool.
var wasMovingR: bool = true
## Pressing right bool.
var wasPressingR: bool = false
## To apply time sensitive transformations.
var gdelta: float = 1
## If gdelta has been set.
var dset: bool = false
## Store Collider Scale Y.
var colliderScaleLockY: float
## Store Collider Position Y.
var colliderPosLockY: float
## Store player flip.
var animFlip: bool
## Plater is flipped. Used for animations.
var isFlipped: bool = false

## Setup.
func _init(newParent: PlatformerController2D):
	parent = newParent
	_recalculate()
	colliderScaleLockY = parent.playerCollider.scale.y
	colliderPosLockY = parent.playerCollider.position.y
	animFlip = parent.playerSprite.flip_h
	isFlipped = parent.startLookingLeft
	wasMovingR = isFlipped

func _recalculate():
	acceleration = parent.maxSpeed / parent.timeToReachMaxSpeed
	deceleration = -parent.maxSpeed / parent.timeToReachZeroSpeed
	jumpMagnitude = parent.jumpHeight * parent.gravityScale
	jumpCount = parent.jumps
	speed = parent.maxSpeed
	if parent.timeToReachMaxSpeed == 0:
		instantAccel = true
		parent.timeToReachMaxSpeed = 1
	else:
		instantAccel = false
	if parent.timeToReachZeroSpeed == 0:
		instantStop = true
		parent.timeToReachZeroSpeed = 1
	else:
		instantStop = false
	if parent.jumps > 1:
		parent.jumpBuffering = 0
		parent.coyoteTime = 0
	if parent.directionalSnap:
		instantAccel = true
		instantStop = true
