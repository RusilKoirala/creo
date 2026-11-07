extends CharacterBody2D

@export var speed := 40.0
@export var health := 3
@export var damage := 1

var direction := 1   

@onready var sprite = $AnimatedSprite2D
@onready var floor_ray = $FloorRay
@onready var hitbox = $Hitbox

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Turn around at walls or ledges
	if is_on_floor() and (is_on_wall() or not floor_ray.is_colliding()):
		direction *= -1

	velocity.x = direction * speed
	sprite.flip_h = direction < 0
	floor_ray.position.x = abs(floor_ray.position.x) * direction

	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	sprite.modulate = Color.RED        
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	if health <= 0:
		sprite.play("damage")
		queue_free()

func _on_hitbox_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
