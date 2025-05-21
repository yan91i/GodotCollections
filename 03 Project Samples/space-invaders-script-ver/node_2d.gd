extends Node2D

# Game Variables
var screen_size
var player_speed = 300
var game_over = false
var game_started = false
var score = 0
var lives = 3
var level = 1
var enemy_shot_chance = 0.0005  # Reduced from 0.002 - chance per enemy per frame to shoot

# Mothership variables
var mothership = null
var mothership_active = false
var mothership_timer = 0
var mothership_interval = 15.0  # Seconds between mothership appearances
var mothership_speed = 100
var mothership_direction = 1

# Nodes
var player
var player_projectiles = []
var enemies = []
var enemy_projectiles = []
var bunkers = []
var score_label
var lives_label
var message_label
var commentary_label

# Constants
const PLAYER_SIZE = Vector2(40, 20)
const ENEMY_SIZE = Vector2(30, 30)
const MOTHERSHIP_SIZE = Vector2(60, 25)
const PROJECTILE_SIZE = Vector2(5, 15)
const BUNKER_BLOCK_SIZE = Vector2(10, 10)
const ENEMY_ROWS = 4
const ENEMY_COLS = 8
const ENEMY_SPACING = Vector2(50, 50)
const ENEMY_MOVE_SPEED = 20
const ENEMY_DROP_AMOUNT = 10
const MAX_PLAYER_PROJECTILES = 3
const PROJECTILE_SPEED = 400

# Enemy movement
var enemy_direction = 1  # 1 for right, -1 for left
var enemy_move_timer = 0
var enemy_move_interval = 0.5  # Time between enemy movements


func _ready():
	randomize()
	screen_size = get_viewport_rect().size
	
	# Create player
	player = ColorRect.new()
	player.color = Color.GREEN
	player.size = PLAYER_SIZE
	player.position = Vector2(screen_size.x / 2 - player.size.x / 2, screen_size.y - player.size.y - 20)
	add_child(player)
	
	# Create score and lives labels
	score_label = Label.new()
	score_label.position = Vector2(20, 20)
	score_label.text = "Score: 0"
	add_child(score_label)
	
	lives_label = Label.new()
	lives_label.position = Vector2(screen_size.x - 100, 20)
	lives_label.text = "Lives: 3"
	add_child(lives_label)
	
	# Create message label (center of screen)
	message_label = Label.new()
	message_label.position = Vector2(screen_size.x / 2 - 100, screen_size.y / 2 - 20)
	message_label.text = "Press SPACE to start"
	add_child(message_label)
	
	# Create commentary label (bottom of screen)
	commentary_label = Label.new()
	commentary_label.position = Vector2(screen_size.x / 2 - 150, screen_size.y - 40)
	commentary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	commentary_label.size = Vector2(300, 30)
	commentary_label.visible = false
	add_child(commentary_label)

func _process(delta):
	if game_over:
		if Input.is_action_just_pressed("ui_select"):  # Restart game
			reset_game()
		return
	
	if not game_started:
		if Input.is_action_just_pressed("ui_select"):
			game_started = true
			message_label.visible = false
			setup_level(level)
			show_commentary("Space battle begins! Blast 'em!")
		return
	
	# Player movement
	var player_movement = 0
	if Input.is_action_pressed("ui_left"):
		player_movement = -1
	if Input.is_action_pressed("ui_right"):
		player_movement = 1
	
	player.position.x += player_movement * player_speed * delta
	player.position.x = clamp(player.position.x, 0, screen_size.x - player.size.x)
	
	# Player shooting
	if Input.is_action_just_pressed("ui_select") and len(player_projectiles) < MAX_PLAYER_PROJECTILES:
		create_player_projectile()
	
	# Mothership handling
	process_mothership(delta)
	
	# Update player projectiles
	process_player_projectiles(delta)
	
	# Update enemy movement
	process_enemy_movement(delta)
	
	# Random enemy shooting
	for enemy in enemies:
		if randf() < enemy_shot_chance:
			create_enemy_projectile(enemy)
	
	# Update enemy projectiles
	process_enemy_projectiles(delta)

func process_mothership(delta):
	# Mothership timer and creation
	if not mothership_active:
		mothership_timer += delta
		if mothership_timer >= mothership_interval:
			mothership_timer = 0
			create_mothership()
	else:
		# Move mothership
		mothership.position.x += mothership_speed * mothership_direction * delta
		
		# Remove mothership if off screen
		if (mothership_direction > 0 and mothership.position.x > screen_size.x) or \
		   (mothership_direction < 0 and mothership.position.x < -MOTHERSHIP_SIZE.x):
			remove_child(mothership)
			mothership = null
			mothership_active = false

func process_player_projectiles(delta):
	for i in range(player_projectiles.size() - 1, -1, -1):
		var projectile = player_projectiles[i]
		projectile.position.y -= PROJECTILE_SPEED * delta
		
		# Remove projectile if it goes off screen
		if projectile.position.y < -PROJECTILE_SIZE.y:
			remove_child(projectile)
			player_projectiles.remove_at(i)
			continue
		
		# Check for collision with mothership
		if mothership_active and check_collision(projectile, mothership):
			# Mothership hit
			score += 100 * level  # More points for higher levels
			score_label.text = "Score: " + str(score)
			show_commentary("MOTHERSHIP DOWN! " + str(100 * level) + " POINTS!")
			
			# Remove mothership
			remove_child(mothership)
			mothership = null
			mothership_active = false
			
			# Remove projectile
			remove_child(projectile)
			player_projectiles.remove_at(i)
			continue
		
		# Check for collision with enemies
		var enemy_hit = false
		for j in range(enemies.size() - 1, -1, -1):
			var enemy = enemies[j]
			if check_collision(projectile, enemy):
				# Enemy hit
				score += 10
				score_label.text = "Score: " + str(score)
				
				# Show random hit commentary
				show_hit_commentary()
				
				# Remove enemy
				remove_child(enemy)
				enemies.remove_at(j)
				
				# Remove projectile
				remove_child(projectile)
				player_projectiles.remove_at(i)
				
				enemy_hit = true
				break
		
		if enemy_hit:
			continue
		
		# Check for collision with bunkers
		for j in range(bunkers.size() - 1, -1, -1):
			var bunker_block = bunkers[j]
			if check_collision(projectile, bunker_block):
				# Bunker block hit
				remove_child(bunker_block)
				bunkers.remove_at(j)
				
				# Remove projectile
				remove_child(projectile)
				player_projectiles.remove_at(i)
				break

func process_enemy_movement(delta):
	enemy_move_timer += delta
	if enemy_move_timer >= enemy_move_interval:
		enemy_move_timer = 0
		
		var should_change_direction = false
		var lowest_enemy_y = 0
		
		# Move all enemies
		for enemy in enemies:
			enemy.position.x += ENEMY_MOVE_SPEED * enemy_direction
			
			# Check if any enemy touches the sides
			if enemy.position.x <= 0 or enemy.position.x + enemy.size.x >= screen_size.x:
				should_change_direction = true
			
			# Track lowest enemy
			lowest_enemy_y = max(lowest_enemy_y, enemy.position.y + enemy.size.y)
		
		# Change direction and drop enemies if needed
		if should_change_direction:
			enemy_direction *= -1
			for enemy in enemies:
				enemy.position.y += ENEMY_DROP_AMOUNT
		
		# Check if enemies reached the player
		if lowest_enemy_y >= player.position.y:
			game_over = true
			message_label.text = "Game Over! Press SPACE to restart"
			message_label.visible = true
			show_commentary("They invaded your space! Game over!")
		
		# Check if all enemies are destroyed
		if enemies.size() == 0:
			level += 1
			setup_level(level)
			show_commentary("Level " + str(level) + "! Enemies incoming!")

func process_enemy_projectiles(delta):
	for i in range(enemy_projectiles.size() - 1, -1, -1):
		var projectile = enemy_projectiles[i]
		projectile.position.y += PROJECTILE_SPEED * delta
		
		# Remove projectile if it goes off screen
		if projectile.position.y > screen_size.y:
			remove_child(projectile)
			enemy_projectiles.remove_at(i)
			continue
		
		# Check for collision with player
		if check_collision(projectile, player):
			# Player hit
			lives -= 1
			lives_label.text = "Lives: " + str(lives)
			
			# Show hit commentary
			show_player_hit_commentary()
			
			# Remove projectile
			remove_child(projectile)
			enemy_projectiles.remove_at(i)
			
			if lives <= 0:
				game_over = true
				message_label.text = "Game Over! Press SPACE to restart"
				message_label.visible = true
				show_commentary("You're out of ships! Game over!")
			
			continue
		
		# Check for collision with bunkers
		for j in range(bunkers.size() - 1, -1, -1):
			var bunker_block = bunkers[j]
			if check_collision(projectile, bunker_block):
				# Bunker block hit
				remove_child(bunker_block)
				bunkers.remove_at(j)
				
				# Remove projectile
				remove_child(projectile)
				enemy_projectiles.remove_at(i)
				break

func create_mothership():
	mothership = ColorRect.new()
	mothership.color = Color.PURPLE
	mothership.size = MOTHERSHIP_SIZE
	
	# Randomize direction
	mothership_direction = 1 if randf() > 0.5 else -1
	
	if mothership_direction > 0:
		mothership.position = Vector2(-MOTHERSHIP_SIZE.x, 40)
	else:
		mothership.position = Vector2(screen_size.x, 40)
	
	add_child(mothership)
	mothership_active = true
	show_commentary("MOTHERSHIP INCOMING!")

func create_bunkers():
	# Clear any existing bunkers
	for bunker in bunkers:
		remove_child(bunker)
	bunkers.clear()
	
	# Create 4 bunkers evenly spaced
	var bunker_width = 5 * BUNKER_BLOCK_SIZE.x
	var bunker_height = 3 * BUNKER_BLOCK_SIZE.y
	var spacing = screen_size.x / 5
	
	for b in range(4):
		var bunker_x = spacing * (b + 1) - bunker_width / 2
		var bunker_y = screen_size.y - 150
		
		# Create bunker with a shape like:
		#  █████
		# ███████
		# ███ ███
		
		# Top row (5 blocks)
		for i in range(5):
			create_bunker_block(Vector2(bunker_x + i * BUNKER_BLOCK_SIZE.x, bunker_y))
		
		# Middle row (7 blocks)
		for i in range(7):
			var x = bunker_x + (i - 1) * BUNKER_BLOCK_SIZE.x
			create_bunker_block(Vector2(x, bunker_y + BUNKER_BLOCK_SIZE.y))
		
		# Bottom row (7 blocks with gap in middle)
		for i in range(7):
			if i != 3:  # Skip middle block to create doorway
				var x = bunker_x + (i - 1) * BUNKER_BLOCK_SIZE.x
				create_bunker_block(Vector2(x, bunker_y + 2 * BUNKER_BLOCK_SIZE.y))

func create_bunker_block(position):
	var block = ColorRect.new()
	block.color = Color(0, 0.5, 0)  # Dark green
	block.size = BUNKER_BLOCK_SIZE
	block.position = position
	add_child(block)
	bunkers.append(block)

func setup_level(level_num):
	# Clear any existing enemies and projectiles
	for enemy in enemies:
		remove_child(enemy)
	enemies.clear()
	
	for projectile in player_projectiles:
		remove_child(projectile)
	player_projectiles.clear()
	
	for projectile in enemy_projectiles:
		remove_child(projectile)
	enemy_projectiles.clear()
	
	if mothership_active and mothership != null:
		remove_child(mothership)
		mothership = null
		mothership_active = false
	
	# Create bunkers
	create_bunkers()
	
	# Adjust difficulty based on level
	enemy_move_interval = max(0.1, 0.5 - (level_num - 1) * 0.05)
	enemy_shot_chance = min(0.003, 0.0005 + (level_num - 1) * 0.0003)  # Still much lower than original
	
	# Create enemies
	var start_x = (screen_size.x - (ENEMY_COLS * (ENEMY_SIZE.x + ENEMY_SPACING.x))) / 2 + ENEMY_SIZE.x / 2
	var start_y = 70
	
	for row in range(ENEMY_ROWS):
		for col in range(ENEMY_COLS):
			var enemy = ColorRect.new()
			
			# Different colors based on row
			if row == 0:
				enemy.color = Color.RED
			elif row == 1:
				enemy.color = Color.ORANGE
			elif row == 2:
				enemy.color = Color.YELLOW
			else:
				enemy.color = Color(1, 0.5, 0)  # Orange-ish
			
			enemy.size = ENEMY_SIZE
			enemy.position = Vector2(
				start_x + col * (ENEMY_SIZE.x + ENEMY_SPACING.x),
				start_y + row * (ENEMY_SIZE.y + ENEMY_SPACING.y)
			)
			add_child(enemy)
			enemies.append(enemy)
	
	# Reset enemy movement
	enemy_direction = 1
	enemy_move_timer = 0
	
	# Reset mothership timer
	mothership_timer = 0

func create_player_projectile():
	var projectile = ColorRect.new()
	projectile.color = Color.GREEN
	projectile.size = PROJECTILE_SIZE
	projectile.position = Vector2(
		player.position.x + player.size.x / 2 - PROJECTILE_SIZE.x / 2,
		player.position.y - PROJECTILE_SIZE.y
	)
	add_child(projectile)
	player_projectiles.append(projectile)

func create_enemy_projectile(enemy):
	var projectile = ColorRect.new()
	projectile.color = Color.RED
	projectile.size = PROJECTILE_SIZE
	projectile.position = Vector2(
		enemy.position.x + enemy.size.x / 2 - PROJECTILE_SIZE.x / 2,
		enemy.position.y + enemy.size.y
	)
	add_child(projectile)
	enemy_projectiles.append(projectile)

func check_collision(rect1, rect2):
	return (
		rect1.position.x < rect2.position.x + rect2.size.x and
		rect1.position.x + rect1.size.x > rect2.position.x and
		rect1.position.y < rect2.position.y + rect2.size.y and
		rect1.position.y + rect1.size.y > rect2.position.y
	)

func reset_game():
	score = 0
	lives = 3
	level = 1
	score_label.text = "Score: 0"
	lives_label.text = "Lives: 3"
	game_over = false
	message_label.text = "Press SPACE to start"
	message_label.visible = true
	
	# Reset player position
	player.position = Vector2(screen_size.x / 2 - player.size.x / 2, screen_size.y - player.size.y - 20)
	
	# Clear any existing enemies and projectiles
	for enemy in enemies:
		remove_child(enemy)
	enemies.clear()
	
	for projectile in player_projectiles:
		remove_child(projectile)
	player_projectiles.clear()
	
	for projectile in enemy_projectiles:
		remove_child(projectile)
	enemy_projectiles.clear()
	
	if mothership_active and mothership != null:
		remove_child(mothership)
		mothership = null
		mothership_active = false
	
	for bunker in bunkers:
		remove_child(bunker)
	bunkers.clear()
	
	# Reset mothership timer
	mothership_timer = 0
	mothership_active = false

func show_commentary(text):
	commentary_label.text = text
	commentary_label.visible = true
	
	# Auto-hide commentary after a delay
	var timer = get_tree().create_timer(2.0)
	await timer.timeout
	if is_instance_valid(commentary_label):
		commentary_label.visible = false

func show_hit_commentary():
	var comments = [
		"Boom! Got one!",
		"Alien down!",
		"Nice shot!",
		"Target eliminated!",
		"That's a hit!",
		"Blasted!",
		"They're dropping like flies!",
		"One less invader!",
		"Direct hit!",
		"Alien go splat!"
	]
	
	# Add special comments for scoring milestones
	if score % 100 == 0:
		show_commentary("Score: " + str(score) + "! Keep it up!")
		return
	
	# Add special comments for few enemies left
	if enemies.size() <= 3 and enemies.size() > 0:
		comments.append("Almost got 'em all!")
		comments.append("Just " + str(enemies.size()) + " more to go!")
		comments.append("They're almost extinct!")
	
	show_commentary(comments[randi() % comments.size()])

func show_player_hit_commentary():
	var comments = [
		"Ouch! You've been hit!",
		"Shields damaged!",
		"They got you!",
		"Ship hit! " + str(lives) + " left!",
		"Watch out for those lasers!",
		"Hit detected! Keep fighting!",
		"That's gonna leave a mark!",
		"Your ship's on fire!",
		"Engines damaged!",
		"Critical hit!"
	]
	
	# Add special comments based on lives left
	if lives == 1:
		comments = [
			"Last life! Be careful!",
			"One more hit and you're done!",
			"Shields critical!",
			"Final ship remaining!",
			"Don't die now!"
		]
	
	show_commentary(comments[randi() % comments.size()])
