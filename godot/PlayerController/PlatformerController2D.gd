@tool
extends CharacterBody2D

class_name PlatformerController2D

## ALERT Essential child nodes.
@export_category("Necesary Child Nodes")
## The player sprite.
@export var playerSprite: AnimatedSprite2D
## The player collider.
@export var playerCollider: CollisionShape2D
## ALERT Only for debug.
@export var debugMenuEditor: DebugMenuEditor

## The input key values
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE) var inputKeys: Dictionary
## Animations for the chosen [AnimatedSprite2D].
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE) var animations: Dictionary

## INFO Horizontal Movement
@export_group("Horizontal Movement")
## Start the player looking left.
@export var startLookingLeft: bool = false
##The max speed your player will move
@export_range(50, 500) var maxSpeed: float = 200.0
##How fast your player will reach max speed from rest (in seconds)
@export_range(0, 4, 0.1) var timeToReachMaxSpeed: float = 0.2
##How fast your player will reach zero speed from max speed (in seconds)
@export_range(0, 4, 0.1) var timeToReachZeroSpeed: float = 0.2
##If true, player will instantly move and switch directions. Overrides the "timeToReach" variables, setting them to 0.
@export var directionalSnap: bool = false
##If higher than 1, running will be enabled. Player must hold a "run" button to accelerate to max speed times runningModifier. Assign [param inputKeys["inputRun"]] in the input settings.
@export_range(1, 50, 0.1) var runningModifier: float = 1

## INFO Jumping
@export_group("Jumping and Gravity")
##The peak height of your player's jump
@export_range(0, 200) var jumpHeight: float = 20.0
##How many jumps your character can do before needing to touch the ground again. Giving more than 1 jump disables jump buffering and coyote time.
@export_range(0, 4, 1) var jumps: int = 1
##The strength at which your character will be pulled to the ground.
@export_range(0, 100) var gravityScale: float = 20.0
##The fastest your player can fall
@export_range(0, 1000) var terminalVelocity: float = 500.0
##Your player will move this amount faster when falling providing a less floaty jump curve.
@export_range(0.5, 3, 0.1) var descendingGravityFactor: float = 1.3
##If this variable is under 1 and the player releases the jump key while still ascending, their vertical velocity will multiplied by this value, providing variable jump height.
@export_range(0, 1, 0.1) var shortHopMultiplier: float = 0.5
##How much extra time (in seconds) your player will be given to jump after falling off an edge. This is set to 0.2 seconds by default.
@export_range(0, 0.5, 0.1) var coyoteTime: float = 0.2
##The window of time (in seconds) that your player can press the jump button before hitting the ground and still have their input registered as a jump. This is set to 0.2 seconds by default.
@export_range(0, 0.5, 0.1) var jumpBuffering: float = 0.2

## INFO Special movement modes.
@export_group("Special Movements")
## Special movements array. Adding special movements here will have them be added to the player.
@export var specialMovements: Array[SpecialMovementsPlatformer2D]:
	set(value):
		specialMovements = value
		for movement in specialMovements:
			if movement:
				if not movement.changed.is_connected(notify_property_list_changed):
					movement.changed.connect(notify_property_list_changed)
		notify_property_list_changed()

## Applied Values.
var appliedValues: PlatformerController2DAppliedValues
## Special movements flags. Used for when a special movement needs to check for another special movement.
var specialMovementFlags: Dictionary = {}
## Special flags that block movement or animation if true.
var specialBlocks: Dictionary
## Command input Variables for the whole script.
var commandInputs: Dictionary = {}
## Flip [AnimatedSprite2D] for animations if this is false. Otherwise custom animations can be set.
var animationCustomFlip: bool = false:
	set(value):
		animationCustomFlip = value
		notify_property_list_changed()

## Custom getter for inputs and animations.
func _get(property: StringName) -> Variant:
	if Engine.is_editor_hint():
		if property.begins_with("input") and property != "input_pickable":
			var prop = property.get_slice("input", 1)
			if prop in inputKeys:
				return inputKeys[prop]
		if property.begins_with("animation") and property != "animationCustomFlip":
			var prop = property.get_slice("animation", 1)
			if prop in animations:
				return animations[prop]
	return null

## Custom setter for inputs and animations.
func _set(property: StringName, value: Variant) -> bool:
	if Engine.is_editor_hint():
		if property.begins_with("input") and property != "input_pickable":
			if not inputKeys:
				inputKeys = {}
			inputKeys[property.get_slice("input", 1)] = value
			return true
		if property.begins_with("animation") and property != "animationCustomFlip":
			if not animations:
				animations = {}
			animations[property.get_slice("animation", 1)] = value
			return true
	return false

## Makes inputs have revert.
func _property_can_revert(property: StringName):
	if (property.begins_with("input") and property != "input_pickable") or (property.begins_with("animation") and property != "animationCustomFlip"):
		return true

## Makes inputs revert default to no control.
func _property_get_revert(property: StringName):
	if (property.begins_with("input") and property != "input_pickable") or (property.begins_with("animation") and property != "animationCustomFlip"):
		return null

## Populates editor.
func _get_property_list() -> Array:
	var properties: Array = []
	properties.append({
		"name": "Input",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP,
		"hint_string": "input"
	})
	InputMap.load_from_project_settings()
	var commands: PackedStringArray = _get_commands()
	for command in commands:
		properties.append({
			"name": "input" + command,
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(InputMap.get_actions()),
		})
	properties.append({
		"name": "Animation",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP,
		"hint_string": "animation"
	})
	properties.append({
		"name": "animationCustomFlip",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	for animation in _get_animations():
		properties.append({
			"name": "animation" + animation,
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(playerSprite.sprite_frames.get_animation_names()),
		})
	return properties

## Gets command list to show in the editor.
func _get_commands() -> PackedStringArray:
	var commands: PackedStringArray = ["left", "right", "up", "down", "jump", "run"]
	for movement in specialMovements:
		if movement:
			commands.append_array(movement.requiredCommands)
	for key in inputKeys.keys():
		if key not in commands:
			inputKeys.erase(key)
	return commands

## Gets animation list to show in the editor.
func _get_animations() -> PackedStringArray:
	var animationList: PackedStringArray = ["idle", "walk", "jump", "run", "falling"]
	for movement in specialMovements:
		if movement:
			animationList.append_array(movement.requiredAnimations)
	if animationCustomFlip:
		var newAnimations: PackedStringArray = []
		for animation in animationList:
			newAnimations.append(animation + "_r")
			newAnimations.append(animation + "_l")
		animationList = newAnimations
	_correct_animations(animationList)
	return animationList

## Fixes animation list.
func _correct_animations(animationList: PackedStringArray):
	var newAnimationDictionary: Dictionary = {}
	for animation in animationList:
		if animation in animations.keys():
			newAnimationDictionary[animation] = animations[animation]
			continue
		if animation.ends_with("_r"):
			if animation.get_slice("_r", 0) in animations.keys():
				newAnimationDictionary[animation] = animations[animation.get_slice("_r", 0)]
				continue
		elif not animation.ends_with("_l"):
			if animation + "_r" in animations.keys():
				newAnimationDictionary[animation] = animations[animation + "_r"]
				continue
		newAnimationDictionary[animation] = null
	animations = newAnimationDictionary

## Runs when the scene is loaded.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_setup_keys()
	_updateData()
	if debugMenuEditor:
		_debug_variables()

## Fills the input dictionaries.
func _setup_keys() -> void:
	for key in _get_commands():
		if key not in inputKeys:
			inputKeys[key] = null
		commandInputs[key] = {}
		for kind in ["hold", "tap", "release"]:
			commandInputs[key][kind] = false

## Makes initial setup calls.
func _updateData() -> void:
	appliedValues = PlatformerController2DAppliedValues.new(self)
	for movement in specialMovements:
		if movement:
			movement._update(self)

## Called every frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# INFO animations
	animation_flip_check()
	# Run
	walk_run_animation()
	# Jump
	if appliedValues.gravityActive and not _check_block("jumpAnimation"):
		if velocity.y < 0:
			play_animation("jump")
		if velocity.y > 40:
			play_animation("falling")
	# Special Movements
	for movement in specialMovements:
		movement._do_animation_check()

## Called every physics frame.
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not appliedValues.dset:
		appliedValues.gdelta = delta
		appliedValues.dset = true
	
	#INFO Input Detection
	for key in inputKeys.keys():
		commandInputs[key].hold = Input.is_action_pressed(inputKeys[key]) if inputKeys[key] else false
		commandInputs[key].tap = Input.is_action_just_pressed(inputKeys[key]) if inputKeys[key] else false
		commandInputs[key].release = Input.is_action_just_released(inputKeys[key]) if inputKeys[key] else false
	
	#INFO Left and Right Movement
	_move_left_and_right(delta)
	
	#INFO Jump and Gravity
	_jump_and_gravity()
	
	#INFO Special Movements
	for movement in specialMovements:
		movement._do_movement_check()
	
	move_and_slide()

## Move left and right. Called in physics process. Moved outside to make reading easier.
func _move_left_and_right(delta: float) -> void:
	if _check_block("move"):
		velocity.x = 0
		return
	if commandInputs.right.hold and commandInputs.left.hold and appliedValues.movementInputMonitoring:
		if not appliedValues.instantStop:
			_decelerate(delta, false)
		else:
			velocity.x = -0.1
	elif commandInputs.right.hold and appliedValues.movementInputMonitoring.x:
		if velocity.x > maxSpeed or appliedValues.instantAccel:
			velocity.x = maxSpeed
		else:
			velocity.x += appliedValues.acceleration * delta
		if velocity.x < 0:
			if not appliedValues.instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = -0.1
	elif commandInputs.left.hold and appliedValues.movementInputMonitoring.y:
		if velocity.x < -maxSpeed or appliedValues.instantAccel:
			velocity.x = -maxSpeed
		else:
			velocity.x -= appliedValues.acceleration * delta
		if velocity.x > 0:
			if not appliedValues.instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = 0.1
	if velocity.x > 0:
		appliedValues.wasMovingR = true
	elif velocity.x < 0:
		appliedValues.wasMovingR = false
	if commandInputs.right.tap:
		appliedValues.wasPressingR = true
	if commandInputs.left.tap:
		appliedValues.wasPressingR = false
	if runningModifier > 1 and commandInputs.run.hold:
		maxSpeed = appliedValues.speed * runningModifier
	elif is_on_floor(): 
		maxSpeed = appliedValues.speed
	if not (commandInputs.left.hold or commandInputs.right.hold):
		if not appliedValues.instantStop:
			_decelerate(delta, false)
		else:
			velocity.x = 0

## Decelerates the player.
func _decelerate(delta: float, vertical: bool) -> void:
	if not vertical:
		if velocity.x > 0:
			velocity.x += appliedValues.deceleration * delta
		elif velocity.x < 0:
			velocity.x -= appliedValues.deceleration * delta
	elif vertical and velocity.y > 0:
		velocity.y += appliedValues.deceleration * delta

## Jump and gravity. Called in physics process. Moved outside to make reading easier.
func _jump_and_gravity() -> void:
	if velocity.y > 0:
		appliedValues.gravity = gravityScale * descendingGravityFactor
	else:
		appliedValues.gravity = gravityScale
	appliedValues.terminalVelocity = terminalVelocity
	for movement in specialMovements:
		movement._do_gravity()
	if appliedValues.gravityActive:
		if velocity.y < appliedValues.terminalVelocity:
			velocity.y += appliedValues.gravity
		elif velocity.y > appliedValues.terminalVelocity:
				velocity.y = appliedValues.terminalVelocity
	if shortHopMultiplier < 1 and commandInputs.jump.release and velocity.y < 0:
		velocity.y *= shortHopMultiplier
	for movement in specialMovements:
		if movement._do_jump_override():
			return
	if jumps == 1:
		if not is_on_floor() and not is_on_wall():
			if coyoteTime > 0:
				_coyote_time()
		if commandInputs.jump.tap and not is_on_wall():
			if appliedValues.coyoteActive:
				appliedValues.coyoteActive = false
				_jump()
			if jumpBuffering > 0:
				appliedValues.jumpWasPressed = true
				_set_after_time("appliedValues/jumpWasPressed", false, jumpBuffering)
			elif jumpBuffering == 0 and coyoteTime == 0 and is_on_floor():
				_jump()
		elif commandInputs.jump.tap and is_on_floor():
			_jump()
		if is_on_floor():
			appliedValues.jumpCount = jumps
			appliedValues.coyoteActive = true
			if appliedValues.jumpWasPressed:
				_jump()
	elif jumps > 1:
		if is_on_floor():
			appliedValues.jumpCount = jumps
		if commandInputs.jump.tap and appliedValues.jumpCount > 0 and not is_on_wall():
			velocity.y = -appliedValues.jumpMagnitude
			appliedValues.jumpCount -= 1
			appliedValues.terminalVelocity = terminalVelocity
			appliedValues.gravityActive = true

## The actual jump.
func _jump() -> void:
	if appliedValues.jumpCount > 0:
		velocity.y = -appliedValues.jumpMagnitude
		appliedValues.jumpCount += -1
		appliedValues.jumpWasPressed = false

## Applies coyote time to jumps.
func _coyote_time() -> void:
	appliedValues.coyoteActive = true
	await get_tree().create_timer(coyoteTime).timeout
	appliedValues.coyoteActive = false
	appliedValues.jumpCount += -1

## Special function to set a value after some time. Handy to save lines of code.
func _set_after_time(parameter: StringName, setValueAfter: Variant, time: float, setValueBefore: Variant = null) -> void:
	if setValueBefore != null:
		_special_set(parameter, setValueBefore)
	await get_tree().create_timer(time).timeout
	_special_set(parameter, setValueAfter)

## Used in case the value to set is in a dictionary or resource.
func _special_set(parameter: StringName, value: Variant) -> void:
	if parameter.contains("/"):
		var route: PackedStringArray = parameter.split("/")
		self[route[0]][route[1]] = value
	else:
		set(parameter, value)

## Checks whether to flip the player orientation in the animation.
func animation_flip_check() -> void:
	var flipCheck: bool = false
	for movement in specialMovements:
		if movement._do_flip_check():
			flipCheck = true
	if commandInputs.right.hold and not flipCheck:
		appliedValues.isFlipped = false
	if commandInputs.left.hold and not flipCheck:
		appliedValues.isFlipped = true
	if not animationCustomFlip:
		playerSprite.flip_h = not appliedValues.animFlip if appliedValues.isFlipped else appliedValues.animFlip

## Checks to play walk and run animations.
func walk_run_animation() -> void:
	if not _check_block("moveAnimation"):
		if abs(velocity.x) > 0.1 and is_on_floor() and not is_on_wall():
			if abs(velocity.x) < (appliedValues.speed):
				play_animation("walk", abs(velocity.x / appliedValues.speed))
			else:
				play_animation("run", abs(velocity.x / appliedValues.speed))
		elif abs(velocity.x) < 0.1 and is_on_floor():
			play_animation("idle")

## Restores speed scale and plays animation.
func play_animation(animationName: StringName, speed: float = 1) -> void:
	playerSprite.speed_scale = speed
	if animationCustomFlip:
		if appliedValues.isFlipped:
			animationName += "_l"
		else:
			animationName += "_r"
	if animationName in animations.keys():
		if playerSprite.animation != animations[animationName]:
			playerSprite.play(animations[animationName])

## Checks for special blockers from special movements.
func _check_block(blockType: String) -> bool:
	if blockType not in specialBlocks:
		return false
	for param in specialBlocks[blockType]:
		if specialMovementFlags[param]:
			return true
	return false


func _debug_variables() -> void:
	var categories: Array[DebugMenuEditor.ParameterCategory] = []
	var movementCategory: DebugMenuEditor.ParameterCategory = DebugMenuEditor.ParameterCategory.new()
	movementCategory.category = "Movement"
	movementCategory.contents = [
		DebugMenuEditor.ParameterContents.new("maxSpeed", DebugParameterContainer.ParameterTypes.NUMERIC, maxSpeed, DebugParameterContainer.NumericData.new(50, 500, 1)),
		DebugMenuEditor.ParameterContents.new("timeToReachMaxSpeed", DebugParameterContainer.ParameterTypes.NUMERIC, timeToReachMaxSpeed, DebugParameterContainer.NumericData.new(0, 4)),
		DebugMenuEditor.ParameterContents.new("timeToReachZeroSpeed", DebugParameterContainer.ParameterTypes.NUMERIC, timeToReachZeroSpeed, DebugParameterContainer.NumericData.new(0, 4)),
		DebugMenuEditor.ParameterContents.new("directionalSnap", DebugParameterContainer.ParameterTypes.BOOL, directionalSnap),
		DebugMenuEditor.ParameterContents.new("runningModifier", DebugParameterContainer.ParameterTypes.NUMERIC, runningModifier, DebugParameterContainer.NumericData.new(1, 50, 0.1))
	]
	categories.append(movementCategory)
	var jumpCategory: DebugMenuEditor.ParameterCategory = DebugMenuEditor.ParameterCategory.new()
	jumpCategory.category = "Jump"
	jumpCategory.contents = [
		DebugMenuEditor.ParameterContents.new("jumpHeight", DebugParameterContainer.ParameterTypes.NUMERIC, jumpHeight, DebugParameterContainer.NumericData.new(0, 200, 1)),
		DebugMenuEditor.ParameterContents.new("jumps", DebugParameterContainer.ParameterTypes.NUMERIC, jumps, DebugParameterContainer.NumericData.new(0, 4, 1)),
		DebugMenuEditor.ParameterContents.new("gravityScale", DebugParameterContainer.ParameterTypes.NUMERIC, gravityScale, DebugParameterContainer.NumericData.new(0, 100)),
		DebugMenuEditor.ParameterContents.new("terminalVelocity", DebugParameterContainer.ParameterTypes.NUMERIC, terminalVelocity, DebugParameterContainer.NumericData.new(0, 1000)),
		DebugMenuEditor.ParameterContents.new("descendingGravityFactor", DebugParameterContainer.ParameterTypes.NUMERIC, descendingGravityFactor, DebugParameterContainer.NumericData.new(0.5, 3)),
		DebugMenuEditor.ParameterContents.new("shortHopMultiplier", DebugParameterContainer.ParameterTypes.NUMERIC, shortHopMultiplier, DebugParameterContainer.NumericData.new(0, 1)),
		DebugMenuEditor.ParameterContents.new("coyoteTime", DebugParameterContainer.ParameterTypes.NUMERIC, coyoteTime, DebugParameterContainer.NumericData.new(0, 0.5)),
		DebugMenuEditor.ParameterContents.new("jumpBuffering", DebugParameterContainer.ParameterTypes.NUMERIC, jumpBuffering, DebugParameterContainer.NumericData.new(0, 0.5))
	]
	categories.append(jumpCategory)
	for movement in specialMovements:
		var category = movement._get_debug_variables()
		if category:
			categories.append(category)
	debugMenuEditor.value_updated.connect(_debug_update)
	debugMenuEditor.initialize(categories, 2)

func _debug_update(newValue: Variant, parameter: String, category: String):
	if category in ["Movement", "Jump"]:
		set(parameter, newValue)
		appliedValues._recalculate()
	else:
		for movement in specialMovements:
			if movement.movementName == category:
				movement.set(parameter, newValue)
				movement._on_debug_update()
