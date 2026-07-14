extends Node

var deck
signal cards_on_hand
var localTurn

var hpLocal = 20
var hpRemote = 20

var _cam: Camera2D

func _ready():
	_cam = Camera2D.new()
	_cam.position = Vector2(360, 640)
	add_child(_cam)
	_cam.make_current()
	randomize()
		
	Game.main = self
	deck = $CardDeckPosition
	initializeDeck()
	
	Game.enemyCardsLocation = $EnemyCardsLocation
	Game.myCardsLocation = $MyCardsLocation
	
	deckToLocation($EnemyCardsLocation)
	await self.cards_on_hand
	
	deckToLocation($MyCardsLocation)
	await self.cards_on_hand
		
	if randi()%2 == 1:
		setLocalTurn(true)
	else:
		setLocalTurn(false)
	
func isLocalTurn():
	return localTurn
		
func initializeDeck():
	# LOCAL PLAYER (Uses unlocked cards)
	var my_cards = SaveService.get_active_deck_cards()
	var local_tmp = []
	for c_data in my_cards:
		var c = preload("res://Card/Card.tscn").instantiate()
		c.cardValue = c_data["v"]
		c.cardType = c_data["t"]
		c.initialize()
		local_tmp.append(c)
		
	# ENEMY PLAYER (Random Deck based on level/difficulty, or same size)
	var enemy_tmp = []
	for i in range(my_cards.size()):
		var t = randi() % 5
		var v = (randi() % 9) + 2 if t < 4 else 10
		var c = preload("res://Card/Card.tscn").instantiate()
		c.cardValue = v
		c.cardType = t
		c.initialize()
		enemy_tmp.append(c)
		
	local_tmp.shuffle()
	enemy_tmp.shuffle()
	
	# Add Enemy cards first, then Player cards
	for c in enemy_tmp:
		deck.add_child(c)
	for c in local_tmp:
		deck.add_child(c)
			
func _on_Button_pressed():
	get_tree().change_scene_to_file('res://Main.tscn')

func deckToLocation(playerCardsLocation):
	if deck.get_children().size() > 0:
		var locations = playerCardsLocation.get_children()
		for l in locations:
			if l.get_children().size() == 0 and deck.get_children().size() > 0:
				var idx = 0 if playerCardsLocation.name == "EnemyCardsLocation" else (deck.get_children().size() - 1)
				var c = deck.get_child(idx)
				deck.remove_child(c)
				get_node("CardCount/Label").text = "%02d" % deck.get_children().size();
				var tex = c.get_node("Image").texture
				c.position = deck.position
				add_child(c)
				var tween = create_tween()
				tween.tween_property(c, "global_position", l.get_global_position(), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
				c.get_node("Image").texture = tex
				await tween.finished
				remove_child(c)
				c.position = Vector2.ZERO
				if playerCardsLocation.name == "MyCardsLocation":
					c.cardOwner = Card.Owner.ME
					c.flip()
				else:
					c.cardOwner = Card.Owner.OTHER
				
				#c.flip()
				l.add_child(c)
		emit_signal("cards_on_hand")

func _on_PopupEnd_visibility_changed():
	var end_label = $PopupEnd/ColorRect/Label
	var bg_rect = $PopupEnd/ColorRect
	
	# Create dynamic buttons
	var btn_again = Button.new()
	btn_again.text = "Jogar Novamente"
	btn_again.size = Vector2(200, 60)
	btn_again.position = Vector2(bg_rect.size.x / 2 - 100, bg_rect.size.y / 2 + 50)
	btn_again.pressed.connect(func(): get_tree().reload_current_scene())
	
	var btn_menu = Button.new()
	btn_menu.text = "Voltar ao Menu"
	btn_menu.size = Vector2(200, 60)
	btn_menu.position = Vector2(bg_rect.size.x / 2 - 100, bg_rect.size.y / 2 + 130)
	btn_menu.pressed.connect(func(): Navigator.change_scene(SceneRoutes.HOME))
	
	bg_rect.add_child(btn_again)
	bg_rect.add_child(btn_menu)
	
	if hpLocal <= 0 and hpRemote > 0:
		end_label.text = "DERROTA!"
		end_label.modulate = Color(1.0, 0.3, 0.3)
		AudioManager.play_defeat()
	else:
		end_label.text = "VITÓRIA! +50 Moedas"
		end_label.modulate = Color(0.3, 1.0, 0.3)
		AudioManager.play_victory()
		SaveService.add_coins(50)
		
	# Animation
	end_label.pivot_offset = end_label.size / 2.0
	end_label.scale = Vector2.ZERO
	var tween = create_tween().set_parallel(true)
	tween.tween_property(end_label, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(bg_rect, "color", Color(0, 0, 0, 0.8), 0.5)
	
	hpRemote = 0
	hpLocal = 0
	
func setLocalTurn(value):
	localTurn = value
	if localTurn == false:
		await get_tree().create_timer(0.5).timeout
		get_node("UI/Local").modulate = "50ffffff"
		get_node("UI/Remote").modulate = "ffffffff"
		Game.remotePlay()
	else:
		await get_tree().create_timer(0.5).timeout
		get_node("UI/Local").modulate = "ffffffff"
		get_node("UI/Remote").modulate = "50ffffff"

const MAX_VALID_PAIRS = [
	[Card.Type.F, Card.Type.E],
	[Card.Type.E, Card.Type.A],
	[Card.Type.A, Card.Type.W],
	[Card.Type.W, Card.Type.F]
]
const MIN_VALID_PAIRS = [
	[Card.Type.F, Card.Type.A],
	[Card.Type.E, Card.Type.W],
	[Card.Type.A, Card.Type.F],
	[Card.Type.W, Card.Type.E]
]

func typeAffinityMax(cardType1 , cardType2):
	return [cardType1, cardType2] in MAX_VALID_PAIRS

func typeAffinityMin(cardType1 , cardType2):
	return [cardType1, cardType2] in MIN_VALID_PAIRS


func verifyWinner():
	var card1:Card
	var card2:Card
	
	if get_node("CardPlace/Collision/Place1").get_children().size() == 1:
		card1 = get_node("CardPlace/Collision/Place1").get_child(0)	
	
	if get_node("CardPlace/Collision/Place2").get_children().size() == 1:
		card2 = get_node("CardPlace/Collision/Place2").get_child(0)
	
	if(card1 == null or card2 ==null):
		setLocalTurn(not isLocalTurn())
		return
		
	await get_tree().create_timer(1).timeout
	_play_battle_vfx()
	var cv1 = card1.cardValue
	var cv2 = card2.cardValue
	
	var cvex1 = 0
	var cvex2 = 0
	
	if card2.cardType != Card.Type.A:
		if cv1 == 5:
			if typeAffinityMax(card1.cardType, card2.cardType): cvex1 += 3
			elif typeAffinityMin(card1.cardType, card2.cardType): cvex1 += 2
		elif cv1 == 6:
			if typeAffinityMax(card1.cardType, card2.cardType): cvex1 += 2
			elif typeAffinityMin(card1.cardType, card2.cardType): cvex1 += 1
	
	if card1.cardType != Card.Type.A:
		if cv2 == 5:
			if typeAffinityMax(card2.cardType, card1.cardType): cvex2 += 3
			elif typeAffinityMin(card2.cardType, card1.cardType): cvex2 += 2
		elif cv2 == 6:
			if typeAffinityMax(card2.cardType, card1.cardType): cvex2 += 2
			elif typeAffinityMin(card2.cardType, card1.cardType): cvex2 += 1
	
	var cardToAnimate
	var winner
	var v = 0
	if (cv1 + cvex1) == (cv2 + cvex2):
		var e = typeAffinityMax(card1.cardType, card2.cardType) || typeAffinityMax(card2.cardType, card1.cardType)
		if e:
			cardToAnimate = card1
			winner = card1.cardOwner
		else:
			cardToAnimate = card2
			winner = card2.cardOwner
		v = 1
	elif (cv1 + cvex1) > (cv2 + cvex2):
		cardToAnimate = card1
		v = abs(cv1+cvex1)
		winner = card1.cardOwner
	else:
		cardToAnimate = card2
		v = abs(cv2+cvex2)
		winner = card2.cardOwner
	
	var winning_card = card1 if winner == card1.cardOwner else card2
	var losing_card = card2 if winner == card1.cardOwner else card1
	
	# Abilities
	# Fire (F) -> +1 Damage
	if winning_card.cardType == Card.Type.F:
		v += 1
	
	# Earth (E) -> Takes half damage
	if losing_card.cardType == Card.Type.E:
		v = max(1, v / 2)
		
	cardToAnimate.animateBattle(losing_card)
	await cardToAnimate.animation_battle_ended
	
	# Apply Damage
	if winner == Card.Owner.ME:  hpRemote -= v
	else:  hpLocal -= v
	
	# Water (W) -> Heals winner +2
	if winning_card.cardType == Card.Type.W:
		if winner == Card.Owner.ME: hpLocal = min(20, hpLocal + 2)
		else: hpRemote = min(20, hpRemote + 2)
	
	get_node("UI/Local/Score").text = "HP: %02d" %  hpLocal
	get_node("UI/Remote/Score").text = "HP: %02d" % hpRemote
	
	
	if !haveCards() || hpLocal <= 0 || hpRemote <= 0:
		get_node("PopupEnd").popup()
	else:
		if winner == Card.Owner.ME: setLocalTurn(true)
		else: setLocalTurn(false)
		cleanPlaces()
		
func cleanPlaces():
	var places = get_node("CardPlace/Collision").get_children()
	for p in places:
		p.get_child(0).queue_free()
	
	if await deckToLocation(Game.myCardsLocation if isLocalTurn() else Game.enemyCardsLocation):
		await self.cards_on_hand
	
	if await deckToLocation(Game.myCardsLocation if not isLocalTurn() else  Game.enemyCardsLocation):
		await self.cards_on_hand
		
func haveCards():
	var retEnemy = false
	var retLocal = false
	for c in $EnemyCardsLocation.get_children():
		if c.get_children().size() > 0:
			retEnemy = true
			break
	
	for c in $MyCardsLocation.get_children():
		if c.get_children().size() > 0:
			retLocal = true
			break

	return retEnemy && retLocal


func _on_BtnMenu_pressed():
	Navigator.change_scene(SceneRoutes.HOME)

func _play_battle_vfx():
	AudioManager.play_impact()
	var shake_tween = create_tween()
	for i in range(5):
		shake_tween.tween_property(_cam, "offset", Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.05)
	shake_tween.tween_property(_cam, "offset", Vector2.ZERO, 0.05)
	
	var p = CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.5
	p.direction = Vector2.UP
	p.spread = 180
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 100
	p.initial_velocity_max = 300
	p.scale_amount_min = 5.0
	p.scale_amount_max = 15.0
	p.color = Color(1.0, 0.8, 0.2)
	p.position = get_node("CardPlace").position
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)
