extends Node3D

#Make sure that your grid map is not inside of a mesh obj, otherwise the enemy will run into the wall!
@onready var get_cover_points = get_node("Cover_points")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var calling_all_enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy_enity in calling_all_enemies:
		##gridmap is a list/array. Needs a forloop to access each point!
		enemy_enity.receive_cover_points(get_cover_points)
