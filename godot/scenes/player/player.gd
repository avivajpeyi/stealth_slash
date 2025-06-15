extends CharacterBody2D

class_name Player

@export var move_speed := 350.0
@export var jump_force := 500.0
@export var gravity := 1200.0
@export var grapple_speed := 2000.0 # Increased for snappier grapple
@export var attack_force := 500.0
@export var grapple_max_distance := 400.0
@export var grapple_stick_distance := 20.0 # Distance to "stick" to grapple point

var is_grappling := false
var grapple_target: Vector2 = Vector2.ZERO
var grapple_direction: Vector2 = Vector2.ZERO # Store grapple direction

# Define the Physics Layer for grappleable objects
@export var physics_grapple_layer_id := 3 # This is the Layer Number from Project Settings -> Physics -> 2D

@onready var grapple_ray := $GrappleRay
@onready var grapple_line := $GrappleLine
@onready var detection_area := $DetectionArea
@onready var sprite := $AnimatedSprite2D

func _ready() -> void:
	# Ensure the RayCast2D only looks for the 'grapple' physics layer
	grapple_ray.set_collision_mask_value(physics_grapple_layer_id, true)
	# Important: Uncheck all other layers in the RayCast2D's collision mask in the inspector,
	# or ensure you clear them here if you want only this layer.
	# grapple_ray.set_collision_mask(1 << (physics_grapple_layer_id - 1)) # This would clear all others

func _physics_process(delta: float) -> void:
	grapple_line.points[0] = global_position # Update line start position every frame

	if is_grappling:
		grapple_move(delta)
	else:
		handle_input()
		apply_gravity(delta)
		move_and_slide()

func handle_input() -> void:
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity.x = dir.x * move_speed

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = -jump_force

	if Input.is_action_just_pressed("Grapple"):
		try_grapple()

	if Input.is_action_just_pressed("Attack"):
		attack()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func attack() -> void:
	for body in detection_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			var direction = (body.global_position - global_position).normalized()
			body.take_damage(direction * attack_force)

func try_grapple() -> void:
	var mouse_pos = get_global_mouse_position()
	grapple_direction = (mouse_pos - global_position).normalized()
	grapple_ray.target_position = grapple_direction * grapple_max_distance
	grapple_ray.force_raycast_update()

	if grapple_ray.is_colliding():
		var collider = grapple_ray.get_collider()
		var hit_point = grapple_ray.get_collision_point()

		print("Grapple hit: ", collider.name)
		
		# Check if the collider is a TileMap node
		if collider is TileMap:
			var tilemap_node: TileMap = collider
			
			# Get the cell coordinates at the collision point
			var tile_coords = tilemap_node.local_to_map(tilemap_node.to_local(hit_point))
			
			# Get the TileData for that specific cell and TileMap layer
			var tile_data = tilemap_node.get_cell_tile_data(tilemap_grapple_layer_index, tile_coords)
			
			if tile_data:
				print("TILE DATA PRESENT for TileMap cell at ", tile_coords)
				# Check for the custom data property "grapple_point"
				if tile_data.has_custom_data("grapple_point") and tile_data.get_custom_data("grapple_point") == true:
					print("Tile is grappleable via custom data!")
					start_grapple(hit_point)
				else:
					print("Tile has data but no 'grapple_point' custom data or it's false.")
			else:
				print("No TileData found for cell at ", tile_coords, " on TileMap layer ", tilemap_grapple_layer_index)
		elif collider.get_collision_layer_value(physics_grapple_layer_id):
			# This handles any other Rigidbody/StaticBody that might be on the grapple layer
			print("Collider is a non-TileMap object on the grapple physics layer.")
			start_grapple(hit_point)
		else:
			print("Collider is not a TileMap and not on the grapple physics layer.")

func start_grapple(target: Vector2) -> void:
	is_grappling = true
	grapple_target = target
	grapple_line.visible = true
	# Set both points for the initial drawing
	grapple_line.points = [global_position, grapple_target]
	# Reset velocity to ensure snappiness
	velocity = Vector2.ZERO

func grapple_move(delta: float) -> void:
	var to_target = grapple_target - global_position
	var dist = to_target.length()

	# Move towards the target if grapple button held AND not yet "stuck"
	if Input.is_action_pressed("Grapple") and dist > grapple_stick_distance:
		var step_vector = to_target.normalized() * grapple_speed * delta
		# Limit the step to prevent overshooting or jittering if too close
		if step_vector.length() > dist:
			velocity = to_target
		else:
			velocity = step_vector
		move_and_slide()
	else:
		# "Stick" to the grapple point
		velocity = Vector2.ZERO # Stop all player controlled movement
		# Ensure we still call move_and_slide to resolve potential collisions
		# (e.g., if we were slightly inside a wall when sticking)
		move_and_slide()

		# Check if grapple should end (mouse released)
		if not Input.is_action_pressed("Grapple"):
			end_grapple()

	# Always update the line's end point to the fixed grapple target
	grapple_line.points[1] = grapple_target

func end_grapple() -> void:
	is_grappling = false
	grapple_line.visible = false
	# Optional: Apply a small jump or push off when ending grapple
	# velocity.y = -jump_force * 0.5 # Example: small hop off
	# velocity.x = 0 # Or maintain horizontal velocity if desired
	print("Grapple ended.")
