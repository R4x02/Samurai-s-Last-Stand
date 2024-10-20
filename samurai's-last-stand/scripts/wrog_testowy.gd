extends CharacterBody2D

@export var speed = 100
@export var health = 1  # Zdrowie przeciwnika
@export var damage = 10  # Obrażenia zadawane przez przeciwnika
var direction = -1
var is_dead = false  # Flaga sprawdzająca, czy przeciwnik jest martwy

func _ready():
	# Ustaw domyślną animację
	$AnimatedSprite2D.play("zombie_left")
	
	# Podłączenie sygnału kolizji z bohaterem do hitbox (Area2D)
	var hitbox = $hitbox2  # Odniesienie do Area2D o nazwie "hitbox2"
	if hitbox:
		# Użyj funkcji Callable do poprawnego połączenia sygnału
		hitbox.connect("body_entered", Callable(self, "_hitbox_body_entered"))
	else:
		print("Error: Node 'hitbox2' not found!")

func _physics_process(delta):
	# Jeśli przeciwnik jest martwy, nie wykonuj dalszej logiki
	if is_dead:
		return

	velocity.x = direction * speed
	move_and_slide()

	# Zmiana kierunku po dotarciu do ściany
	if is_on_wall():
		direction *= -1
		update_animation()

# Funkcja do aktualizacji animacji w zależności od kierunku
func update_animation():
	if direction == -1:
		$AnimatedSprite2D.play("zombie_left")
	else:
		$AnimatedSprite2D.play("zombie_right")

# Funkcja do odbierania obrażeń
func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		die()

# Funkcja do obsługi śmierci przeciwnika
func die() -> void:
	is_dead = true
	$AnimatedSprite2D.hide()
	$AnimatedSprite2D2.show()
	if direction == -1:
		$hitbox2.queue_free()
		$EnemyCollision.queue_free()
		$AnimatedSprite2D2.play("zombie_dead_left")
	else:
		$hitbox2.queue_free()
		$EnemyCollision.queue_free()
		$AnimatedSprite2D2.play("zombie_dead_right")

	$AnimatedSprite2D2.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

# Custom function to handle the end of the death animation
func _on_death_animation_finished():
	queue_free()
