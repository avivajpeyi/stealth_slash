@tool
extends SpecialMovementsPlatformer2D

##If the player's head is blocked by a jump but only by a little, the player will be nudged in the right direction and their jump will execute as intended. NEEDS RAYCASTS TO BE ATTACHED TO THE PLAYER NODE. AND ASSIGNED TO MOUNTING RAYCAST. DISTANCE OF MOUNTING DETERMINED BY PLACEMENT OF RAYCAST.
class_name CornerCutting

##How many pixels the player will be pushed (per frame) if corner cutting is needed to correct a jump.
@export_range(1, 5) var correctionAmount: float = 1.5
##Raycast used for corner cutting calculations. Place above and to the left of the players head point up. ALL ARE NEEDED FOR IT TO WORK.
@export_node_path("RayCast2D") var leftRaycast: NodePath
##Raycast used for corner cutting calculations. Place above of the players head point up. ALL ARE NEEDED FOR IT TO WORK.
@export_node_path("RayCast2D") var middleRaycast: NodePath
##Raycast used for corner cutting calculations. Place above and to the right of the players head point up. ALL ARE NEEDED FOR IT TO WORK.
@export_node_path("RayCast2D") var rightRaycast: NodePath

## Actual left ray.
var lRay: RayCast2D
## Actual middle ray.
var mRay: RayCast2D
## Actual right ray.
var rRay: RayCast2D

## Setup.
func _on_update() -> void:
	lRay = parent.get_node(leftRaycast)
	mRay = parent.get_node(middleRaycast)
	rRay = parent.get_node(rightRaycast)

## Check for corner cuts.
func _movement_check():
	if not mRay.is_colliding() and parent.velocity.y < 0:
		var leftRay: bool = lRay.is_colliding()
		var rightRay: bool = rRay.is_colliding()
		if leftRay and not rightRay:
			parent.position.x += correctionAmount
		if not leftRay and rightRay:
			parent.position.x -= correctionAmount
