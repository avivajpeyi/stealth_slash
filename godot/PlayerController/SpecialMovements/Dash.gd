@tool
extends SpecialMovementsPlatformer2D

class_name Dash

## The type of dashes available
enum DashTypes {HORIZONTAL, VERTICAL, FOURWAY, EIGHTWAY}
## The type of dashes the player can do.
@export var dashType: DashTypes
## Can dash mid air.
@export var airDash: bool = false
## How many dashes your player can do before needing to hit the ground.
@export_range(0, 10) var dashes: int = 1
## Dash cancel modes.
enum DashCancelModes {NONE, STRICT, AND_DASH_RELEASE}
## If enabled, pressing the opposite direction of a dash, during a dash, will zero the player's velocity.
@export var dashCancel: DashCancelModes = DashCancelModes.NONE
## How far the player will dash. One of the dashing toggles must be on for this to be used.
@export_range(1.1, 20) var speedMultiplier: float = 2.5
## Dash time multiplier.
@export_range(0.01, 5) var duration: float = 0.2
## Dash on no direction.
@export var noDirectionDash: bool = false
## Allow player to jump during dash.
@export var allowJump: bool = false:
	set(value):
		allowJump = value
		if not allowJump:
			consecutiveJumps = 0
		notify_property_list_changed()
## Consecutive dash jumps After jumping how many times can you chain jumps.
var consecutiveJumps: int = 0:
	set(value):
		consecutiveJumps = value
		if consecutiveJumps == 0:
			consecutiveJumpsTimer = 0.2
		notify_property_list_changed()
## Consecutive dash jumps timer. If higher than 0 then it will give you some time before stopping the dash so you can chain jumps
var consecutiveJumpsTimer: float = 0.2

## The actual dash speed.
var dashMagnitude: float
## The current number of dashes available.
var dashCount: int = dashes
## Last dash direction. Used for dash cancels.
var lastDashDirection: Vector2
## Current consecutive jumps.
var jumpCount: int = consecutiveJumps + 1

func _get_property_list() -> Array:
	var properties: Array = []
	if allowJump:
		properties.append({
			"name": "consecutiveJumps",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,20"
		})
	if consecutiveJumps > 0:
		properties.append({
			"name": "consecutiveJumpsTimer",
			"type": TYPE_FLOAT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.01,5"
		})
	return properties

## Override commands and animations.
func _set_commands_and_animations() -> void:
	requiredCommands = PackedStringArray(["dash"])
	requiredAnimations = PackedStringArray(["dash"])
	movementName = "Dash"

## Setup.
func _on_update() -> void:
	dashMagnitude = parent.maxSpeed * speedMultiplier
	_set_special_flag("dashing", false, ["moveAnimation", "jumpAnimation"])
	if allowJump:
		_set_special_flag("dashboosting", false)

## Checks for dash events.
func _movement_check() -> void:
	if parent.is_on_floor() and not _get_special_flag("dashboosting"):
		dashCount = dashes
	var inputDirection: Vector2 = Input.get_vector(parent.inputKeys.left, parent.inputKeys.right, parent.inputKeys.up, parent.inputKeys.down)
	if inputDirection.length() < 0.2:
		inputDirection = Vector2.ZERO
	inputDirection = inputDirection.normalized()
	if inputDirection == Vector2.ZERO and noDirectionDash:
		if not parent.appliedValues.isFlipped:
			inputDirection = Vector2.RIGHT
		else:
			inputDirection = Vector2.LEFT
	if parent.commandInputs.dash.tap and not _get_special_flag("rolling") and (parent.is_on_floor() or airDash):
		if dashCount > 0 and inputDirection != Vector2.ZERO:
			match dashType:
				DashTypes.EIGHTWAY:
					_do_dash(inputDirection.normalized(), duration)
				DashTypes.FOURWAY:
					if abs(inputDirection.x) == 1 or abs(inputDirection.y) == 1:
						_do_dash(inputDirection.normalized(), duration)
				DashTypes.VERTICAL:
					if abs(inputDirection.y) > 0:
						_do_dash(Vector2.UP if inputDirection.y < 0 else Vector2.DOWN, duration)
				DashTypes.HORIZONTAL:
					if abs(inputDirection.x) > 0:
						_do_dash(Vector2.LEFT if inputDirection.x < 0 else Vector2.RIGHT, duration)
	if _get_special_flag("dashing") and dashCancel != DashCancelModes.NONE:
		_dash_cancel(inputDirection)
	if _get_special_flag("dashing"):
			#if you want your player to become immune or do something else while dashing, add that here.
			pass

## Dashes.
func _do_dash(dashDirection: Vector2, time: float) -> void:
	jumpCount = consecutiveJumps + 1
	lastDashDirection = dashDirection
	_special_set_after_time("dashing", false, time, true)
	_special_set_after_time("appliedValues/gravityActive", true, time, false)
	parent.velocity = dashDirection * dashMagnitude
	dashCount += -1
	_special_set_after_time("appliedValues/movementInputMonitoring", Vector2.ONE, time, Vector2.ZERO)

## Cancels dash.
func _dash_cancel(inputDirection: Vector2) -> void:
	if (parent.velocity.x == 0 and abs(lastDashDirection.x) > 0) or (lastDashDirection + inputDirection == Vector2.ZERO and (dashCancel == DashCancelModes.STRICT or not parent.commandInputs.dash.hold)):
		parent.velocity = Vector2.ZERO
		_set_special_flag("dashing", false)
		if allowJump:
			_set_special_flag("dashboosting", false)

## Animate dashes.
func _animation_check() -> void:
	if _get_special_flag("rolling"):
		_set_special_flag("dashing", false)
	if _get_special_flag("dashing"):
		parent.play_animation("dash")

## Checks for wall jump.
func _jump_override() -> bool:
	if not allowJump or not _get_special_flag("dashing") or not parent.is_on_floor():
		return false
	if parent.commandInputs.jump.tap and jumpCount > 0:
		jumpCount -= 1
		_set_special_flag("dashboosting", true)
		parent._special_set("appliedValues/gravityActive", true)
	elif _get_special_flag("dashboosting"):
		_set_special_flag_after_time("dashboosting", false, parent.coyoteTime)
	return false

func _special_set_after_time(property: StringName, valueAfterTime: Variant, time: float, valueBeforeTime: Variant) -> void:
	if property.contains("/"):
		parent._special_set(property, valueBeforeTime)
	else:
		_set_special_flag(property, valueBeforeTime)
	await parent.get_tree().create_timer(time).timeout
	if allowJump:
		while _get_special_flag("dashboosting"):
			await special_property_change
			if not _get_special_flag("dashboosting"):
				await parent.get_tree().create_timer(consecutiveJumpsTimer).timeout
	if property.contains("/"):
		parent._special_set(property, valueAfterTime)
	else:
		_set_special_flag(property, valueAfterTime)

## Exports variables for debug testing live.
func _get_debug_variables() -> DebugMenuEditor.ParameterCategory:
	var category: DebugMenuEditor.ParameterCategory = DebugMenuEditor.ParameterCategory.new()
	category.category = movementName
	category.contents = [
		DebugMenuEditor.ParameterContents.new("dashType", DebugParameterContainer.ParameterTypes.LIST, dashType, DashTypes.keys()),
		DebugMenuEditor.ParameterContents.new("airDash", DebugParameterContainer.ParameterTypes.BOOL, airDash),
		DebugMenuEditor.ParameterContents.new("dashes", DebugParameterContainer.ParameterTypes.NUMERIC, dashes, DebugParameterContainer.NumericData.new(0, 4, 1)),
		DebugMenuEditor.ParameterContents.new("dashCancel", DebugParameterContainer.ParameterTypes.LIST, dashCancel, DashCancelModes.keys()),
		DebugMenuEditor.ParameterContents.new("speedMultiplier", DebugParameterContainer.ParameterTypes.NUMERIC, speedMultiplier, DebugParameterContainer.NumericData.new(1.1, 20)),
		DebugMenuEditor.ParameterContents.new("duration", DebugParameterContainer.ParameterTypes.NUMERIC, duration, DebugParameterContainer.NumericData.new(0.01, 5, 0.01)),
		DebugMenuEditor.ParameterContents.new("noDirectionDash", DebugParameterContainer.ParameterTypes.BOOL, noDirectionDash),
		DebugMenuEditor.ParameterContents.new("allowJump", DebugParameterContainer.ParameterTypes.BOOL, allowJump),
		DebugMenuEditor.ParameterContents.new("consecutiveJumps", DebugParameterContainer.ParameterTypes.NUMERIC, consecutiveJumps, DebugParameterContainer.NumericData.new(0, 20, 1)),
		DebugMenuEditor.ParameterContents.new("consecutiveJumpsTimer", DebugParameterContainer.ParameterTypes.NUMERIC, consecutiveJumpsTimer, DebugParameterContainer.NumericData.new(0.01, 5, 0.01))
	]
	return category

## What to do when the values are updated through debug.
func _on_debug_update() -> void:
	dashMagnitude = parent.maxSpeed * speedMultiplier
