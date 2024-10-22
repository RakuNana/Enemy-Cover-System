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

@export var speed = 300.0
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

var can_see_player = false

#used for testing
var array1 = [10,5,33,9]
var array2 = ["p1","p2","p3","p4"]

var test = 0

func _ready():
	
	add_to_group("enemy")
	
func gpt():
	
	#asked chat for the godot equivalent to python zip(sort)
	#tested, and worked. Used in func get_cover
	var combined = []
	for i in range(array1.size()):
		
		combined.append({"order" : array1[i], "item" : array2[i]})
		
	combined.sort_custom(sort_pos_by_distance)
	
	print(combined)
	
func get_cover():
	#cover_order not being appeded to list!
	calc_cover()
	for i in range(cover_points_order.size()):
		
		combined_points.append({"order": cover_points_order[i], "all_cover_points": cover_points[i]}) 
	
	#creates a dictionary from player distance to cover and pos of cover points
	combined_points.sort_custom(sort_pos_by_distance)
	#sorts the dictionary from farthest to closest distance
	combined_points.sort()
	combined_points.sort()#needs to sort twice, Not sure why?
	
	#get that first element from list(Should be the farthest cover point from player
	#Then give to enemy navagent to move to
	
	var farthest_point = combined_points.size() - 1
	next_cover_point = combined_points[farthest_point]["all_cover_points"]
	
	#clear out list after calcs are done, to optimize performance
	cover_points_order.clear()
	combined_points.clear()
	
func sort_pos_by_distance(a,b):
	
	return a["order"] < b["order"]
	
func _physics_process(delta):
	
	#have enemy always face player, can have a bool here to control if the enemy
	#should look at the players direction or not
	#look_at(Global.player_current_pos)
	
	#for testing only
	if Input.is_action_just_pressed("enemy_fire"):
		
		fire_weapon()
	
	#for testing only
	if Input.is_action_just_pressed("ui_down"):
			
			#print(cover_points_order)
			print(cover_points.size())
			#current_state = all_states[STATES.ACTIVE]
			
	run_for_cover(delta)
	get_cover()
	
	move_and_slide()
	
func calc_cover():
	
	for x in cover_points.size():
		#append ,sort distance from small to big, use to sort order of cover points? 
		#if Global.player_current_pos.distance_to(cover_points[x]) > 3:
		#use a list to sort the list, can be done in python
		#append distance to a list. In order of point placement
		var get_distance = Global.player_current_pos.distance_to(cover_points[x]) 
		cover_points_order.append(get_distance)
	
func receive_cover_points(all_cover_points):
	
	#passes the gridmap "cover_points" to a var in the script. We now have access to it
	#I created a list to store the gridmap points.
	#Make sure that the cover object has all its angles with a cover point, gives wierd results otherwise
	for cover in all_cover_points.get_used_cells():
		#appends points in order of placement.
		cover.y = 1 # add 1 to all y axis. Navagent origin point is in capsule center not bottom
		cover_points.append(cover)
	
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
	
func run_for_cover(delta):
	
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
		
		
	if current_state == all_states[STATES.ACTIVE]:
		
		velocity = Vector3.ZERO
		look_at(Global.player_current_pos)
		
func get_new_pos(next_pos):
	
	nav_agent.set_target_position(next_pos)
	
func example():
	
	fire_weapon()
	
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
			
			#current_state = all_states[STATES.SHOOT_PLAYER]
			fire_weapon()
			
func _on_enemy_fov_body_entered(body):
	
	if body.is_in_group("player"):
		
		can_see_player = true
	
func _on_enemy_fov_body_exited(body):
	
	if body.is_in_group("player"):
		
		can_see_player = false
	
func _on_navigation_agent_3d_target_reached() -> void:
	
	#Change state when position reached
	current_state = all_states[STATES.ACTIVE]
	
	get_node("shoot_at_player_example").start(1)
	
	#print("When I have reached cover. I can be coded to do something else")
	pass # Replace with function body.
	

func _on_shoot_at_player_example_timeout():
	
	example()
