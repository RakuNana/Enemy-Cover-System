extends CharacterBody3D

@onready var standing_col = get_node("standing_col")
@onready var crouching_col = get_node("crouching_col")
@onready var cam_pivot = get_node("cam_pivot")

@onready var top_head = get_node("all_raycast/top_head")
@onready var face_lvl = get_node("all_raycast/face")
@onready var new_pos = get_node("all_raycast/new_pos")

@onready var anim_tree = get_node("AnimationTree").get("parameters/playback")
@onready var get_bullets = preload("res://Scenes/bullet.tscn")
@onready var bullet_pos = get_node("cam_pivot/bullet_pos_node/bullet_pos")

var speed = 3
var jump_vel = 4.5
var mouse_sensitivity = 0.002

var can_mantle = true
var is_crouching = false

#Player needs to run for a set amouont of time before they can wall run
var can_wall_run_timer = 60
var can_wall_run = true

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	
	add_to_group("player")
	anim_tree.travel("standing_idle")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_node("AnimationTree").active = true
	
func _physics_process(delta):
	
	Global.player_current_pos = self.global_position
	
	if Input.is_action_just_pressed("fire"):
		
		fire_bullets()
	
	control_loop(delta)
	head_control()
	run_state()
	check_mantle()
	wall_run_timer()
	wall_run()
	move_and_slide()
	
func fire_bullets():
	
	var new_bullet = get_bullets.instantiate()
	get_parent().add_child(new_bullet)
	
	#set bullets position to gun pos
	new_bullet.global_position = bullet_pos.global_position
	#Bullet will copy the enemies rotation, allowing the bullet to travel in that direction
	#Thank the viewer!
	new_bullet.global_rotation = get_node("cam_pivot").global_rotation
		
func control_loop(delta):
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_vel

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		anim_tree.travel("standing_idle")
		
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
func head_control():
	
	#The cam_pivot expo. springarm for 3rd person
	if Input.is_action_just_pressed("ui_cancel"):
		#places mouse cursor to center of screen, then locks it to center
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE
	
func run_state():
	
	if Input.is_action_pressed("run"):
		
		speed = 6
		
		
	else:
		
		can_wall_run_timer = 60
		speed = 3
		
		
	#if Input.is_action_pressed("run") and velocity.z:
		#
		#can_wall_run_timer -= 1
	
func check_mantle():
	
	var has_ledge = (face_lvl.is_colliding() and not top_head.is_colliding())
	
	if can_mantle:
		
		#we are at a ledge
		if has_ledge:
			
			velocity.y = 0
			gravity = 0
			
			if has_ledge and Input.is_action_just_pressed("jump"):
				
				anim_tree.travel("mantle_up")
				var climb_tween = create_tween()
				climb_tween.tween_property(self,"position",  new_pos.global_position,0.50)
				#self.global_position = new_pos.global_position
				
		else:
			
			gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	
func _input(event):
	
	if event is InputEventMouseMotion:
		
		rotate_y(-event.relative.x * mouse_sensitivity)
		cam_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		#keeps camera from being able to 360, sprite should be parented to camera
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x,-PI/2, PI/2)
		
		
	if event.is_action_pressed("crouch"):
		
		check_crouch_state()
		crouch_stand_anim()
		is_crouching = not is_crouching
		
	if not is_crouching:
		
		if event.is_action_pressed("lean_left"):
			
			anim_tree.travel("lean_left")
			
		if event.is_action_released("lean_left"):
			
			anim_tree.travel("standing_idle")
			
			
		if event.is_action_pressed("lean_right"):
			
			anim_tree.travel("lean_right")
			
		if event.is_action_released("lean_right"):
			
			anim_tree.travel("standing_idle")
	
func crouch_stand_anim():
	
	if is_crouching:
		
		anim_tree.travel("standing_idle")
		
	if not is_crouching:
		
		anim_tree.travel("crouch_idle")
	
func check_crouch_state():
	
	standing_col.disabled = not is_crouching
	crouching_col.disabled = is_crouching
	
func wall_run_timer():
	
	if Input.is_action_pressed("run") and velocity.z:
		
		can_wall_run_timer -= 1
		
	if can_wall_run_timer <= 0:
		
		can_wall_run = true
		
	else:
		
		can_wall_run = false
	
func wall_run():
	
	if can_wall_run:
			
		if $all_raycast/check_L.is_colliding():
			
			gravity = gravity * 0.5
			
		if $all_raycast/check_R.is_colliding():
			
			gravity = gravity * 0.5
	
func _on_above_head_body_entered(_body):
	
	can_mantle = false
	
func _on_above_head_body_exited(_body):
	
	can_mantle = true
