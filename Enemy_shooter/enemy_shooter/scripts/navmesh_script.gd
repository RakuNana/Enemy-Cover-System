extends NavigationRegion3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var test = get_navigation_map()
	test.is_valid()
	pass
