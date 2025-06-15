@tool
extends SpecialMovementsPlatformer2D

class_name WallJump

## How long the player's movement input will be ignored after wall jumping.
@export_range(0, 0.5) var inputPauseAfterWallJump: float = 0.1
## How long after the player detached to the wall will the player still be able to jump.
@export_range(0, 0.5) var coyoteTime: float = 0.1
## The angle at which your player will jump away from the wall. 0 is straight away from the wall, 90 is straight up. Does not account for gravity
@export_range(0, 90) var wallKickAngle: float = 60.0
## The player's gravity will be divided by this number when touch a wall and descending. Set to 1 by default meaning no change will be made to the gravity and there is effectively no wall sliding. THIS IS OVERRIDDED BY WALL LATCH.
@export_range(1, 20) var wallSliding: float = 1.0
## Wall Latching Modes
enum WallLatchingModes {NONE, NORMAL, ON_KEY_PRESSED}
## If NORMAL, the player's gravity will be set to 0 when touching a wall and descending. THIS WILL OVERRIDE WALLSLIDING.
## If ON_KEY_PRESSED, the player must hold down the "latch" key to wall latch. The player's input will be ignored when latching.
@export var wallLatching: WallLatchingModes = WallLatchingModes.NONE:
	set(value):
		wallLatching = value
		_set_commands_and_animations()
		emit_changed()

## Flag for when the player is latched to the wall.
var latched: bool = false
## Flag for when the player was latched to the wall with coyote timing.
var wasLatched: bool = false
## Flag for when the player can get latched to the wall.
var canLatch: bool = true
## The player is against the wall.
var isOnWall: bool = false
## The player is sliding.
var sliding: bool = false

## Override commands and animations.
func _set_commands_and_animations() -> void:
	match wallLatching:
		WallLatchingModes.ON_KEY_PRESSED:
			requiredCommands = PackedStringArray(["latch"])
			requiredAnimations = PackedStringArray(["slide", "latch"])
		WallLatchingModes.NORMAL:
			requiredCommands = PackedStringArray([])
			requiredAnimations = PackedStringArray(["latch"])
		WallLatchingModes.NONE:
			requiredCommands = PackedStringArray([])
			requiredAnimations = PackedStringArray(["slide"])
	movementName = "WallJump"

## Checks for corresponding animations.
func _animation_check() -> void:
	if _latch_check():
		parent.play_animation("latch")
	elif isOnWall and parent.velocity.y > 0 and wallSliding > 1:
		parent.play_animation("slide")

## Checks for latch key pressing conditions
func _latch_check() -> bool:
	if isOnWall and canLatch:
		if wallLatching == WallLatchingModes.ON_KEY_PRESSED and parent.commandInputs.latch.hold:
			return true
		if wallLatching == WallLatchingModes.NORMAL:
			return true
	return false

## Checks for latch events.
func _is_latched() -> void:
	if isOnWall and _latch_check():
		latched = true
	else:
		latched = false
		_set_after_time("wasLatched", false, coyoteTime, true)

## Applies special wall slide gravity rules.
func _gravity() -> void:
	if parent.is_on_wall_only():
		var direction: Vector2 = Vector2.ZERO
		if parent.commandInputs.right.hold:
			direction = Vector2.LEFT
		if parent.commandInputs.left.hold:
			direction = Vector2.RIGHT
		if parent.get_wall_normal() == direction or (parent.commandInputs.left.hold and parent.commandInputs.right.hold):
			isOnWall = true
	elif isOnWall:
		_set_after_time("isOnWall", false, coyoteTime)
	if _get_special_flag("groundPounding"):
		sliding = false
		return
	if isOnWall:
		parent.appliedValues.terminalVelocity = parent.terminalVelocity / wallSliding
		if wallLatching and _latch_check():
			parent.appliedValues.gravity = 0
			if parent.velocity.y < 0:
				parent.velocity.y += 50
			if parent.velocity.y > 0:
				parent.velocity.y = 0
			if wallLatching == WallLatchingModes.ON_KEY_PRESSED and parent.commandInputs.latch.hold and parent.appliedValues.movementInputMonitoring == Vector2.ONE:
				parent.velocity.x = 0
		elif wallSliding != 1 and parent.velocity.y > 0:
			parent.appliedValues.gravity = parent.appliedValues.gravity / wallSliding
			sliding = true
	else:
		sliding = false

## Checks for wall jump.
func _jump_override() -> bool:
	if parent.commandInputs.jump.tap and isOnWall:
		_wall_jump()
		return true
	else:
		return false

## Wall jumps.
func _wall_jump() -> void:
	var horizontalWallKick = abs(parent.appliedValues.jumpMagnitude * cos(wallKickAngle * (PI / 180)))
	var verticalWallKick = abs(parent.appliedValues.jumpMagnitude * sin(wallKickAngle * (PI / 180)))
	_set_after_time("canLatch", true, inputPauseAfterWallJump, false)
	isOnWall = false
	parent.position.x -= 10 * 1 if parent.appliedValues.wasMovingR else 1
	_is_latched()
	parent.velocity.y = -verticalWallKick
	var right: float = -1 if parent.appliedValues.wasMovingR else 1
	var wall: float = 1 if parent.is_on_wall() else -1
	parent.velocity.x = horizontalWallKick * right * wall
	parent.play_animation("jump")
	if inputPauseAfterWallJump != 0:
		parent._set_after_time("appliedValues/movementInputMonitoring", Vector2.ONE, inputPauseAfterWallJump, Vector2.ZERO)
	await parent.get_tree().create_timer(0.01).timeout
	if parent.velocity.x == 0:
		parent.velocity.x = -horizontalWallKick * right * wall

## Checks for latch to do sprite flips
func _flip_check() -> bool:
	if wallLatching == WallLatchingModes.NONE:
		return sliding
	return _latch_check() or sliding

## Exports variables for debug testing live.
func _get_debug_variables() -> DebugMenuEditor.ParameterCategory:
	var category: DebugMenuEditor.ParameterCategory = DebugMenuEditor.ParameterCategory.new()
	category.category = movementName
	category.contents = [
		DebugMenuEditor.ParameterContents.new("inputPauseAfterWallJump", DebugParameterContainer.ParameterTypes.NUMERIC, inputPauseAfterWallJump, DebugParameterContainer.NumericData.new(0, 0.5)),
		DebugMenuEditor.ParameterContents.new("coyoteTime", DebugParameterContainer.ParameterTypes.NUMERIC, coyoteTime, DebugParameterContainer.NumericData.new(0, 0.5)),
		DebugMenuEditor.ParameterContents.new("wallKickAngle", DebugParameterContainer.ParameterTypes.NUMERIC, wallKickAngle, DebugParameterContainer.NumericData.new(0, 90, 1)),
		DebugMenuEditor.ParameterContents.new("wallSliding", DebugParameterContainer.ParameterTypes.NUMERIC, wallSliding, DebugParameterContainer.NumericData.new(1, 20)),
		DebugMenuEditor.ParameterContents.new("wallLatching", DebugParameterContainer.ParameterTypes.LIST, wallLatching, WallLatchingModes.keys())
	]
	return category
