extends CharacterBody3D

#Created a collider checker. placed obj in a list. Enemy randomly
#picks from list, max of 10. More is expensive

#when cover is decided, enemy chooses the one that is farther from the place
#if you can't find cover, no cover is found catch all
#clears list after each check - list was not used
#if player is to close, changes cover spot
#Enemy needs to check if cover is tall enough, raycast?

@onready var nav_agent  = get_node("NavigationAgent3D")
#field of vision
@onready var FOV_caster = get_node("FOV_cast")
@onready var load_bullets = preload("res://Scenes/bullet.tscn")
@onready var bullet_pos = get_node("bullet_pos_node/bullet_pos")

@export var speed = 100.0
#get objects instead of vectors

#this will store the gridmap coords
var cover_points = []
#this will store the distance of the player from the cover object
var cover_points_order = []

var combined_points = []
var next_cover_point 

enum STATES {ACTIVE,SHOOT_PLAYER,BEING_HIT,LOOK_FOR_COVER}
var all_states = [STATES.ACTIVE,STATES.SHOOT_PLAYER,STATES.BEING_HIT,STATES.LOOK_FOR_COVER]

var current_state = all_states[STATES.ACTIVE]

var found_cover = false
var can_see_player = false

var array1 = [10,5,33,9]
var array2 = ["p1","p2","p3","p4"]

func _ready():
	
	add_to_group("enemy")
	gpt()
	
	
func gpt():
	
	var combined = []
	for i in range(array1.size()):
		
		combined.append({"value" : array1[i], " item": array2[i]})
		
	combined.sort_custom(gpt_sorter)
	
	print(combined)
	
	
func gpt_sorter(a,b):
	
	return a["value"] < b["value"]
	
	
func _physics_process(delta):
	
	#have enemy always face player, can have a bool here to control if the enemy
	#should look at the players direction or not
	#look_at(Global.player_current_pos)
	
	
	if Input.is_action_just_pressed("enemy_fire"):
		
		fire_weapon()
	
	if Input.is_action_just_pressed("ui_down"):
			
			current_state = all_states[STATES.ACTIVE]
			
	#covering(delta)
	look_for_cover(delta)
	#calc_cover()
	#get_cover_obj()
	#pick_cover_point()
		
	move_and_slide()
	
	
func sort_cover_distance(dl,cl):
	#distance_list, cover_list
	
	return dl["value"] < cl["value"]
	
func calc_cover():
	
	if not cover_points.is_empty():
		
		for x in cover_points.size():
			#append ,sort distance from small to big, use to sort order of cover points? 
			#if Global.player_current_pos.distance_to(cover_points[x]) > 3:
			#use a list to sort the list, can be done in python
			
			#append distance to a list. In order of point placement
			var get_distance = Global.player_current_pos.distance_to(cover_points[x])
			cover_points_order.append(get_distance)
			
		for i in cover_points_order.size():
			
			combined_points.append({"value" : cover_points_order, "item" : cover_points})
			#combined_points.sort_custom(sort_cover_distance)
			
		for entry in combined_points:
			cover_points.append(entry["item"])
		
		print(combined_points)
		cover_points.clear()
		cover_points_order.clear()
		combined_points.clear()
			
		
	
func receive_cover_points(all_cover_points):
	
	#passes the gridmap "cover_points" to a var in the script. We now have access to it
	#passed_cover_points = all_cover_points
	for x in all_cover_points.get_used_cells():
		#appends points in order of placement.
		cover_points.append(x)
	
func pick_cover_point():
	pass
	
	#if in forloop it calcs players pos x times before giving a new pos
	#need to do this outside of loop then, append to list? 
	
	#Put on a timer?
	#cp = cover_point
	#use passed cover points instead?
	#for cp in passed_cover_points.get_used_cells():
		 #
		##gridmap gives Vector3i, we need a Vector3. Convert
		#
		#var convert_v3i = Vector3(cp)
		#
		##calc the distance from the cover point pos and the players pos
		##var calc_distance_from_player = Global.player_current_pos.distance_to(convert_v3i)#abs(convert_v3i - Global.player_current_pos)
		#var calc_distance_from_player = Global.player_current_pos - convert_v3i
		#var calc_distance_from_cover = global_position - convert_v3i
		#
		#if calc_distance_from_player > calc_distance_from_cover:
			#
			#cover_points.append(convert_v3i)
			#var farthest_point = cover_points.size() - 1
			#cover_points.sort()
			#next_cover_point = cover_points[farthest_point]
			
			#var farthest_point = convert_v3i
			#
			#next_cover_point = farthest_point
		
			#place all the distance calcs abs in a list
			#cover_points.append(convert_v3i)
				
			#find the farthest point in the list, which will be last element after list.sort()
			#var farthest_point = cover_points.size() - 1 #Size starts at 1 but list start at 0
			#sort list from smallest/closet point to biggest/farthest point
			#cover_points.sort()
			#give final result to var that enemies nav agent uses for target selection
			#next_cover_point = cover_points[farthest_point]#needs to grab from gridmap
		
func covering(_delta : float) -> void:
	
	var cover_areas = get_tree().get_nodes_in_group("cover")
	
	for cover in cover_areas:
		
		var cover_pos = cover.global_transform.origin
		
		if position.direction_to(cover_pos) > cover_pos.direction_to(Global.player_current_pos): 
			
			next_cover_point = cover.global_position
			
func fire_weapon():
	
	var new_bullet = load_bullets.instantiate()
	get_parent().add_child(new_bullet)
	
	#set bullets position to gun pos
	new_bullet.global_position = bullet_pos.global_position
	#Bullet will copy the enemies rotation, allowing the bullet to travel in that direction
	#Thank the viewer on the metriod video!
	new_bullet.global_rotation = self.global_rotation
	
func damaged():
	
	current_state = all_states[STATES.BEING_HIT]
	
func look_for_cover(delta):
	
	if current_state == all_states[STATES.BEING_HIT]:
		
		await get_tree().process_frame
		
		var dir
		
		#needs to be able to check players pos, and find cover farthest away
		nav_agent.target_position = next_cover_point
		dir = nav_agent.get_next_path_position() - self.global_position
		dir = dir.normalized()
		velocity = velocity.lerp(dir * speed * delta ,1.0)
		
		#stops enemy from rolling over
		dir.y = 0
		
		#stops error, if look_at point is equal to zero
		if self.global_transform.origin.is_equal_approx(self.global_transform.origin + dir):
			
			return
		#as long as enemy is seeking cover, he won't face player
		look_at(self.global_transform.origin + dir)
		
func get_cover_obj():
	
	#if found_cover:
		
	var space_state = get_world_3d().direct_space_state

	var find_openings = get_node("Cover_seeker_inarea").get_overlapping_bodies()

	for cover_obj in find_openings:
		
		#finds object in area3d
		if cover_obj.is_in_group("cover"):
			
			var query = PhysicsRayQueryParameters3D.create(self.global_position, cover_obj.global_position)                                            
		
			var result = space_state.intersect_ray(query)
			
			#finds obj the intersect_ray is colliding with
			if result["collider"].is_in_group("cover"):
				
				pick_cover_point()
				cover_points.clear()
	
func get_new_pos(next_pos):
	
	nav_agent.set_target_position(next_pos)
	
func _on_timer_timeout():
	
	check_sight()
	
func check_sight():
	
	#if the FOV raycast is colliding with the player, and nothing else
	#Enemy can see player and begin to chase
	
	#Note: is_colliding uses the raycast vector length, if something
	#collides with it, the first object is used instead of it's max
	
	#When seen_player is true, The raycast will lock on to player pos
	if can_see_player:
		
		look_at(Global.player_current_pos)
		FOV_caster.look_at(Global.player_current_pos,Vector3(0,1,0))
	
	if FOV_caster.is_colliding():
				
		var collider = FOV_caster.get_collider()
		
		if collider.is_in_group("player"):
			
			current_state = all_states[STATES.SHOOT_PLAYER]
			fire_weapon()
			
func _on_enemy_fov_body_entered(body):
	
	if body.is_in_group("player"):
		
		can_see_player = true
	
func _on_enemy_fov_body_exited(body):
	
	if body.is_in_group("player"):
		
		can_see_player = false
	
func _on_cover_seeker_inarea_body_entered(body: Node3D) -> void:
	
	if body.is_in_group("cover"):
		#this should add cover to the list
		found_cover = true
		
func _on_cover_seeker_inarea_body_exited(body: Node3D) -> void:
	
	if body.is_in_group("cover"):
		#this should add cover to the list
		found_cover = false
	
func _on_navigation_agent_3d_target_reached() -> void:
	#print("done")
	pass # Replace with function body.
	
