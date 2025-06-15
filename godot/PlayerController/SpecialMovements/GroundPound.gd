@tool
extends SpecialMovementsPlatformer2D

class_name GroundPound

##The amount of time the player will hover in the air before completing a ground pound (in seconds).
@export_range(0.05, 0.75) var pause: float = 0.25
## Multiplies the falling max speed by this amount.
@export_range(1, 20, 0.1) var maxVelocityMultiplier: float = 10
## Multiplies the falling accelleration by this amount.
@export_range(1, 20, 0.1) var fallMultiplier: float = 2
## If enabled then an additional button will be required to be pressed while down is held.
@export var holdDown: bool = false
## If enabled, pressing up will end the ground pound early.
@export var upToCancel: bool = false
## If enabled, player cannot move left and right while ground pounding.
@export var freezeHorizontally: bool = false

## Override commands and animations.
func _set_commands_and_animations() -> void:
	requiredCommands = PackedStringArray(["groundPound"])
	requiredAnimations = PackedStringArray(["groundPound"])
	movementName = "GroundPound"

## Setup.
func _on_update() -> void:
	if freezeHorizontally:
		_set_special_flag("groundPounding", true, ["move", "moveAnimation", "jumpAnimation"])
	else:
		_set_special_flag("groundPounding", true, ["moveAnimation", "jumpAnimation"])

## Checks for ground pound events.
func _movement_check() -> void:
	if _input_check() and not parent.is_on_floor() and not parent.is_on_wall():
		_set_special_flag("groundPounding", true)
		parent.appliedValues.gravityActive = false
		parent.velocity.y = 0
		await parent.get_tree().create_timer(pause).timeout
		_ground_pound()
	if _get_special_flag("groundPounding"):
		if parent.is_on_floor() or (upToCancel and parent.commandInputs.up.tap):
			_end_ground_pound()

func _input_check() -> bool:
	if holdDown:
		return parent.commandInputs.down.hold and parent.commandInputs.groundPound.tap
	else:
		return parent.commandInputs.groundPound.tap

## Ground pounds.
func _ground_pound() -> void:
	parent.appliedValues.terminalVelocity = parent.terminalVelocity * maxVelocityMultiplier
	parent.velocity.y = parent.appliedValues.jumpMagnitude * fallMultiplier
	parent.play_animation("groundPound")

## Stops ground pound.
func _end_ground_pound() -> void:
	_set_special_flag("groundPounding", false)
	parent.appliedValues.terminalVelocity = parent.terminalVelocity
	parent.appliedValues.gravityActive = true

## Exports variables for debug testing live.
func _get_debug_variables() -> DebugMenuEditor.ParameterCategory:
	var category: DebugMenuEditor.ParameterCategory = DebugMenuEditor.ParameterCategory.new()
	category.category = movementName
	category.contents = [
		DebugMenuEditor.ParameterContents.new("pause", DebugParameterContainer.ParameterTypes.NUMERIC, pause, DebugParameterContainer.NumericData.new(0.5, 0.75, 0.01)),
		DebugMenuEditor.ParameterContents.new("maxVelocityMultiplier", DebugParameterContainer.ParameterTypes.NUMERIC, maxVelocityMultiplier, DebugParameterContainer.NumericData.new(1, 20, 0.1)),
		DebugMenuEditor.ParameterContents.new("fallMultiplier", DebugParameterContainer.ParameterTypes.NUMERIC, fallMultiplier, DebugParameterContainer.NumericData.new(1, 20, 0.1)),
		DebugMenuEditor.ParameterContents.new("holdDown", DebugParameterContainer.ParameterTypes.BOOL, holdDown),
		DebugMenuEditor.ParameterContents.new("upToCancel", DebugParameterContainer.ParameterTypes.BOOL, upToCancel),
		DebugMenuEditor.ParameterContents.new("freezeHorizontally", DebugParameterContainer.ParameterTypes.BOOL, freezeHorizontally)
		]
	return category

## What to do when the values are updated through debug.
func _on_debug_update() -> void:
	_on_update()
