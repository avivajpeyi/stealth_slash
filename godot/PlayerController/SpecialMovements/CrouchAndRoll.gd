@tool
extends SpecialMovementsPlatformer2D

class_name CrouchAndRoll

## Multiply the max speed by this value while crouched.
@export_range(0, 2) var crouchSpeedMultiplier = 0.5
## Multiply the collider size by this value while crouched.
@export_range(0, 2) var crouchSizeMultiplier = 0.5
## Holding down and pressing the input for "roll" will execute a roll if the player is grounded.
@export var canRoll: bool:
	set(value):
		canRoll = value
		_set_commands_and_animations()
		emit_changed()
## The amount of time the roll lasts.
@export_range(0.1, 2) var rollTime: float = 0.25
## The speed multiplier for the roll.
@export_range(0.1, 10, 0.1) var rollSpeedMultiplier = 1.5

## Actual roll speed.
var rollSpeed: float
## Player Collider height. Used for transformations.
var colliderHeight: float
## Used for keeping track of roll direction
var lastRollDirection: Vector2

## Override commands and animations.
func _set_commands_and_animations() -> void:
	if canRoll:
		requiredCommands = PackedStringArray(["crouch", "roll"])
		requiredAnimations = PackedStringArray(["crouch_idle", "crouch_walk", "roll"])
	else:
		requiredCommands = PackedStringArray(["crouch"])
		requiredAnimations = PackedStringArray(["crouch_idle", "crouch_walk"])
	movementName = "CrouchAndRoll"

## Setup.
func _on_update() -> void:
	rollSpeed = parent.maxSpeed * rollSpeedMultiplier
	_set_special_flag("crouching", false, ["moveAnimation", "jumpAnimation"])
	_set_special_flag("rolling", false, ["moveAnimation", "jumpAnimation"])
	_get_collider_height()

## Gets player collider height.
func _get_collider_height() -> void:
	if parent.playerCollider.shape is CircleShape2D:
		colliderHeight = parent.playerCollider.shape.radius * 2
	elif parent.playerCollider.shape is CapsuleShape2D:
		colliderHeight = parent.playerCollider.shape.height
	elif parent.playerCollider.shape is RectangleShape2D:
		colliderHeight = parent.playerCollider.shape.size.y

## Check for crouch or roll events.
func _movement_check() -> void:
	# Crouching
	if not _get_special_flag("rolling"):
		if parent.commandInputs.down.hold and parent.is_on_floor():
			_set_special_flag("crouching", true)
			parent.playerCollider.scale.y = parent.appliedValues.colliderScaleLockY * crouchSizeMultiplier
			parent.playerCollider.position.y = parent.appliedValues.colliderPosLockY + crouchSizeMultiplier * colliderHeight / 2
		elif not parent.commandInputs.down.hold or ((parent.commandInputs.run.hold and parent.runningModifier > 1) or parent.runningModifier == 1) and not _get_special_flag("rolling"):
			_set_special_flag("crouching", false)
		if not parent.is_on_floor():
			_set_special_flag("crouching", false)
		if _get_special_flag("crouching"):
			parent.maxSpeed = parent.appliedValues.speed * crouchSpeedMultiplier
		else:
			parent.playerCollider.scale.y = parent.appliedValues.colliderScaleLockY
			parent.playerCollider.position.y = parent.appliedValues.colliderPosLockY
	# Rolling
	if canRoll:
		if parent.commandInputs.roll.tap and _get_special_flag("crouching") and (parent.commandInputs.left.hold or parent.commandInputs.right.hold) and not parent.commandInputs.up.hold:
			_do_roll()
		if _get_special_flag("rolling"):
			#if you want your player to become immune or do something else while rolling, add that here.
			pass

func _do_roll() -> void:
	if not _get_special_flag("rolling"):
		lastRollDirection = Vector2.RIGHT if parent.appliedValues.wasPressingR else Vector2.LEFT
	_set_special_flag_after_time("rolling", false, rollTime, true)
	parent.velocity = rollSpeed * lastRollDirection
	parent._set_after_time("appliedValues/gravityActive", true, rollTime, false)
	parent._set_after_time("appliedValues/movementInputMonitoring", Vector2.ONE, rollTime, Vector2.ZERO)

## Checks for corresponding animations.
func _animation_check() -> void:
	if _get_special_flag("crouching") and not _get_special_flag("rolling"):
		if abs(parent.velocity.x) > 0:
			parent.play_animation("crouch_walk", abs(parent.velocity.x / (parent.appliedValues.speed * crouchSpeedMultiplier)))
		elif parent.animations.crouch_idle:
			parent.play_animation("crouch_idle")
	elif _get_special_flag("rolling"):
		parent.play_animation("roll")

## Exports variables for debug testing live.
func _get_debug_variables() -> DebugMenuEditor.ParameterCategory:
	var category: DebugMenuEditor.ParameterCategory = DebugMenuEditor.ParameterCategory.new()
	category.category = movementName
	category.contents = [
		DebugMenuEditor.ParameterContents.new("crouchSpeedMultiplier", DebugParameterContainer.ParameterTypes.NUMERIC, crouchSpeedMultiplier, DebugParameterContainer.NumericData.new(0, 2)),
		DebugMenuEditor.ParameterContents.new("crouchSizeMultiplier", DebugParameterContainer.ParameterTypes.NUMERIC, crouchSizeMultiplier, DebugParameterContainer.NumericData.new(0, 2)),
		DebugMenuEditor.ParameterContents.new("canRoll", DebugParameterContainer.ParameterTypes.BOOL, canRoll),
		DebugMenuEditor.ParameterContents.new("rollTime", DebugParameterContainer.ParameterTypes.NUMERIC, rollTime, DebugParameterContainer.NumericData.new(0.1, 2)),
		DebugMenuEditor.ParameterContents.new("rollSpeedMultiplier", DebugParameterContainer.ParameterTypes.NUMERIC, rollSpeedMultiplier, DebugParameterContainer.NumericData.new(0.1, 10))
	]
	return category

## What to do when the values are updated through debug.
func _on_debug_update() -> void:
	rollSpeed = parent.maxSpeed * rollSpeedMultiplier
