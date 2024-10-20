extends CharacterBody2D

@export var speed = 300
@export var gravity = 1150
@export var jump_force = 700
@export var dash_speed = 1000
@export var dash_duration = 0.3
@export var attack_damage = 20  # Obrażenia zadawane przeciwnikom
@export var can_double_jump = false  # Czy podwójny skok jest aktywny
@export var max_health = 100  # Maksymalne zdrowie bohatera
@export var health = 30 # Aktualne zdrowie bohatera
@onready var attack_area = get_node("AttackArea")

var has_double_jumped = false  # Czy podwójny skok już został wykonany
var is_dashing = false
var dash_time_left = 0
var dash_direction = 0
var is_attacking = false  # Flaga sprawdzająca, czy postać atakuje
var attack_duration = 0.5  # Czas trwania ataku
var facing_direction = "right"  # Kierunek, w którym patrzy postać
var is_dead = false  # Flaga sprawdzająca, czy bohater jest martwy

func _ready():
	# Debugging line in _ready
	# Znajdź węzeł paska zdrowia w UI
	# Podłączenie do obszaru ataku
	if not attack_area:
		print("Error: AttackArea node not found!")
	else:
		attack_area.connect("body_entered", Callable(self, "_on_AttackArea_body_entered"))

func _physics_process(delta):
	# Jeśli bohater jest martwy, zatrzymaj dalsze przetwarzanie
	if is_dead:
		return

	# Apply gravity unless the character is on the floor
	if !is_on_floor():
		velocity.y += gravity * delta
		if velocity.y > 1000:
			velocity.y = 1000

	# Handle dashing
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false
			velocity.x = 0  # Stop horizontal movement after dash ends
		else:
			if dash_time_left == dash_duration:
				# Play the dash animation once, when the dash starts
				if facing_direction == "left":
					$AnimatedSprite2D.play("dash_left", true)  # Loop the dash animation
				elif facing_direction == "right":
					$AnimatedSprite2D.play("dash_right", true)  # Loop the dash animation
	else:
		# Handle normal movement and attacking
		if is_attacking:
			var horizontal_direction = Input.get_axis("move_left", "move_right")
			velocity.x = speed * horizontal_direction  # Move along the X axis

			if horizontal_direction == 0:
				velocity.x = 0  # Stop if no direction is held

			attack_duration -= delta
			if attack_duration <= 0:
				is_attacking = false
				# Wyłącz kształty kolizji po zakończeniu ataku
				$AttackArea/CollisionShapeRight.disabled = true
				$AttackArea/CollisionShapeLeft.disabled = true
		else:
			# Normal gravity, jumping, and other movement logic
			if is_on_floor():
				has_double_jumped = false  # Reset double jump when on the floor

			# Handle jumping logic
			if Input.is_action_just_pressed("jump"):
				if is_on_floor():
					$"Retro-jump".play()
					velocity.y = -jump_force  # First jump
				elif can_double_jump and not has_double_jumped:
					$"Retro-jump".play()
					velocity.y = -jump_force  # Double jump
					has_double_jumped = true  # Mark that double jump has been used

			# Horizontal movement
			var horizontal_direction = Input.get_axis("move_left", "move_right")
			velocity.x = speed * horizontal_direction

			if horizontal_direction < 0 and !is_attacking:
				$AnimatedSprite2D.hide()
				$AnimatedSprite2D2.show()
				$AnimatedSprite2D2.play("run_left")
				facing_direction = "left"
			elif horizontal_direction > 0 and !is_attacking:
				$AnimatedSprite2D.hide()
				$AnimatedSprite2D2.show()
				$AnimatedSprite2D2.play("run_right")
				facing_direction = "right"
			elif horizontal_direction == 0 and is_on_floor() and !is_attacking:
				$AnimatedSprite2D2.hide()
				$AnimatedSprite2D.show()
				if facing_direction == "left":
					$AnimatedSprite2D.play("idle_left")
				else:
					$AnimatedSprite2D.play("idle_right")  # Play the idle animation

		# Handle initiating a dash based on current facing direction
		if Input.is_action_just_pressed("dash"):
			if facing_direction == "left":
				start_dash(-1)
			elif facing_direction == "right":
				start_dash(1)

		# Handle initiating an attack
		if Input.is_action_just_pressed("attack") && !is_attacking:
			start_attack()

	# Move character and apply velocity
	move_and_slide()

# Start dash function
func start_dash(direction):
	is_dashing = true
	dash_time_left = dash_duration
	dash_direction = direction
	velocity.x = dash_speed * dash_direction

	# Set the dash animation to play once when the dash starts
	if direction < 0:
		$AnimatedSprite2D2.hide()
		$AnimatedSprite2D.show()
		$AnimatedSprite2D.play("dash_left", true)
	else:
		$AnimatedSprite2D2.hide()
		$AnimatedSprite2D.show()
		$AnimatedSprite2D.play("dash_right", true)

# Funkcja rozpoczęcia ataku
func start_attack():
	$"Kick-hard".play()
	is_attacking = true
	attack_duration = 0.5  # Czas trwania ataku
	
	# Wybierz odpowiednią animację ataku zależnie od kierunku i aktywuj odpowiedni hitbox
	if facing_direction == "right":
		$AttackArea/CollisionShapeRight.disabled = false
		$AttackArea/CollisionShapeLeft.disabled = true
		$AnimatedSprite2D2.hide()
		$AnimatedSprite2D.show()
		$AnimatedSprite2D.play("attack_right")
	else:
		$AttackArea/CollisionShapeRight.disabled = true
		$AttackArea/CollisionShapeLeft.disabled = false
		$AnimatedSprite2D2.hide()
		$AnimatedSprite2D.show()
		$AnimatedSprite2D.play("attack_left")

# Funkcja wykrywania kolizji w AttackArea
func _on_AttackArea_body_entered(body):
	# Sprawdź, czy obiekt posiada metodę "take_damage" i wywołaj ją
	if body.has_method("take_damage") and is_attacking:
		body.take_damage(attack_damage)

# Funkcja do odbierania obrażeń przez bohatera
# Modify the take_damage_p function to include a color change effect
# Modify the take_damage_p function to include a color change effect using Tweener
# Modify the take_damage_p function to include a color change effect using Tweener
func take_damage_p(damage: int) -> void:
	health -= damage

	# Check if the character is dead
	if health <= 0:
		die()
		return
	# Start the color flash effect using Tweener
	var hit_color = Color(1, 0, 0)  # Red color to indicate hit
	var original_color = modulate  # Save the original color of the character
	# Create the Tweener instance and perform the transitions
	var tweener = create_tween()
	tweener.tween_property(self, "modulate", hit_color, 0.1)  # Tween to hit color over 0.1 seconds
	tweener.tween_property(self, "modulate", original_color, 0.1).set_delay(0.1)  # Tween back to original color with a delay of 0.1 seconds

	# Play a hit sound or other feedback
	$"Retro-hurt".play()
# Funkcja obsługująca śmierć bohatera
func die() -> void:
	$"Retro-hurt".play()
	is_dead = true
	print("Bohater umarł")
	set_physics_process(false)  # Wyłącz przetwarzanie fizyki

func _on_orb_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		can_double_jump = true

func _on_hitbox_2_body_entered(body: CharacterBody2D) -> void:  # This will help you identify the body causing the trigger
	if body.has_method("take_damage_p"):
		body.take_damage_p(attack_damage)
		print(health)

func _on_area_2d_body_entered(body: Node2D) -> void:
	die() # Replace with function body.
