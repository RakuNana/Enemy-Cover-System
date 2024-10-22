extends Area3D

var speed = 1
#area3ds aren't a physics obj, so it needs a custom velocity var 
var velocity = Vector3.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	
	#opposite dir of where the enemies facing
	velocity.z = -1
	#move area 
	translate(velocity.normalized() * speed)

func _on_timer_timeout() -> void:
	#destroy after a few seconds
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	
	if body.is_in_group("enemy"):
		
		body.damaged()
	#if it collides with a body, destroy obj
	queue_free()
