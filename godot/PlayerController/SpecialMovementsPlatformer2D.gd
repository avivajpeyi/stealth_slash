@tool
extends Resource

## Special Movements for 2D Platformer Player.
class_name SpecialMovementsPlatformer2D

## The movement type. For debug purposes.
var movementName: String = "Placeholder"

## Reference to the parent node.
var parent: PlatformerController2D
## Required commands. Override on resources that extend this one and require special buttons.
var requiredCommands: PackedStringArray
## Required animations. Override on resources that extend this one and require special animations.
var requiredAnimations: PackedStringArray

## Special signal for changing of special properties
signal special_property_change(property: StringName, value: Variant)

## Init function. To override commands and animations.
func _init() -> void:
	_set_commands_and_animations()

## Init function to use on resources that extend this one. To override commands and animations.
func _set_commands_and_animations() -> void:
	pass

## Setup. Sets parent Also creates special flags on parent.
func _update(newParent: PlatformerController2D) -> void:
	parent = newParent
	_on_update()

## Sets special flags on parent. specialBlocks will apply blocks to special moments in the player code. Right now "move", "moveAnimation", and "jumpAnimation" are implemented.
func _set_special_flag(flag: StringName, value: bool, specialBlocks: PackedStringArray = []) -> void:
	parent.specialMovementFlags[flag] = value
	for block in specialBlocks:
		if not block in parent.specialBlocks:
			parent.specialBlocks[block] = [flag]
		else:
			parent.specialBlocks[block].append(flag)
	if specialBlocks:
		for block in parent.specialBlocks:
			if block not in specialBlocks:
				parent.specialBlocks[block].erase(flag)
	special_property_change.emit(flag, value)

## Gets special flags on parent.
func _get_special_flag(flag: StringName) -> bool:
	if flag not in parent.specialMovementFlags.keys():
		return false
	return parent.specialMovementFlags[flag]

## Special function to set special flags on parent after some time. Handy to save lines of code.
func _set_special_flag_after_time(parameter: StringName, setValueAfter: bool, time: float, setValueBefore: Variant = null) -> void:
	if setValueBefore is bool:
		_set_special_flag(parameter, setValueBefore)
	await parent.get_tree().create_timer(time).timeout
	_set_special_flag(parameter, setValueAfter)

## Special function to set a value after some time. Handy to save lines of code.
func _set_after_time(parameter: StringName, setValueAfter: Variant, time: float, setValueBefore: Variant = null) -> void:
	if setValueBefore != null:
		set(parameter, setValueBefore)
	await parent.get_tree().create_timer(time).timeout
	set(parameter, setValueAfter)

## Expanded setup function to use on resources that extend this one.
func _on_update() -> void:
	pass

## Base animation check function.
func _do_animation_check() -> void:
	if parent:
		_animation_check()

## Animation check function to use on resources that extend this one.
func _animation_check() -> void:
	pass

## Base special gravity function.
func _do_gravity() -> void:
	if parent:
		_gravity()

## Special gravity function to use on resources that extend this one.
func _gravity() -> void:
	pass

## Base movement check function.
func _do_movement_check() -> void:
	if parent:
		_movement_check()

## Movement check function to use on resources that extend this one.
func _movement_check() -> void:
	pass

## Base jump override function.
func _do_jump_override() -> bool:
	if parent:
		return _jump_override()
	else:
		return false

## Jump override function to use on resources that extend this one.
func _jump_override() -> bool:
	return false

## Base sprite flip check function.
func _do_flip_check() -> bool:
	if parent:
		return _flip_check()
	else:
		return false

## Sprite flip check function to use on resources that extend this one.
func _flip_check() -> bool:
	return false

## Exports variables for debug testing live.
func _get_debug_variables() -> DebugMenuEditor.ParameterCategory:
	return null

## What to do when the values are updated through debug.
func _on_debug_update() -> void:
	pass
