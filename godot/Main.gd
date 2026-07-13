extends Node
class_name Main

signal cards_on_hand
signal cards_on_place

var localTurn

var localScore = 0
var remoteScore = 0

@onready var enemyCardsLocation = $EnemyCardsLocation
@onready var myCardsLocation = $MyCardsLocation
@onready var deck = $CardDeckPosition
	
var _cam: Camera2D

func _ready():
	_cam = Camera2D.new()
	_cam.position = Vector2(360, 640)
	add_child(_cam)
	_cam.make_current()
	randomize()		
	Game.main = self
	
	initializeDeck()
	
	placeCards()	
	await self.cards_on_place
	
	var v = randi()%2 == 1
	setLocalTurn(v)


func isLocalTurn():
	return localTurn
	
func placeCards():
		
	deckToLocation(enemyCardsLocation)
	await self.cards_on_hand
	
	deckToLocation(myCardsLocation)
	await self.cards_on_hand
	
	emit_signal("cards_on_place")
		
func initializeDeck():	
	if Network.networkId <= 1:
		var tmp = []
		for e in ["a","e","f","w"]:
			for i in range(2, 10):
				var c = preload("res://Card/Card.tscn").instantiate()
				c.cardValue = i
				c.cardType = Card.Type.A if e == "a" else Card.Type.E if e == "e" else Card.Type.F if e == "f" else Card.Type.W	
				c.initialize()
				tmp.append(c)
		
		var cx = preload("res://Card/Card.tscn").instantiate()
		cx.cardValue = 10
		cx.cardType = Card.Type.X
		cx.initialize()
		tmp.append(cx)
		
		cx = preload("res://Card/Card.tscn").instantiate()
		cx.cardValue = 10
		cx.cardType = Card.Type.X
		cx.initialize()
		tmp.append(cx)
			
		tmp.shuffle()
		
		for i in tmp:
			deck.add_child(i)
			if Network.otherId > 0:
				rpc_id(Network.otherId, "addChildDeck", i.cardValue, i.cardType)

@rpc("any_peer") func addChildDeck(i, e):
	var c = preload("res://Card/Card.tscn").instantiate()
	c.cardValue = i
	c.cardType = e	
	c.initialize()
	deck.add_child(c)

func _on_Button_pressed():
	Network.close_connection()
	get_tree().change_scene_to_file('res://Main.tscn')

func deckToLocation(playerCardsLocation):
	print("deckToLocation")
	if deck.get_children().size() > 0:
		var locations = playerCardsLocation.get_children()
		for l in locations:
			if l.get_children().size() == 0:
				var c = deck.get_child(deck.get_children().size() - 1)
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
	if remoteScore > localScore:
		$PopupEnd/ColorRect/Label.text = "Você Perdeu!"
	
	remoteScore = 0
	localScore = 0
	
@rpc func setLocalTurn(value):
	if Network.networkId <= 1:
		localTurn = value
	else:
		localTurn = !value
	
	if localTurn == false:
		await get_tree().create_timer(0.5).timeout
		get_node("UI/Local").modulate = "50ffffff"
		get_node("UI/Remote").modulate = "ffffffff"
		
		if Network.networkId == -1:
			Game.remotePlay()
	else:
		await get_tree().create_timer(0.5).timeout
		get_node("UI/Local").modulate = "ffffffff"
		get_node("UI/Remote").modulate = "50ffffff"

func typeAffinityMax(cardType1 , cardType2):
	return (cardType1 == Card.Type.F && cardType2 == Card.Type.E or
		cardType1 == Card.Type.E && cardType2 == Card.Type.A or
		cardType1 == Card.Type.A && cardType2 == Card.Type.W or
		cardType1 == Card.Type.W && cardType2 == Card.Type.F)

func typeAffinityMin(cardType1 , cardType2):
	return (cardType1 == Card.Type.F && cardType2 == Card.Type.A or
		cardType1 == Card.Type.E && cardType2 == Card.Type.W or
		cardType1 == Card.Type.A && cardType2 == Card.Type.F or
		cardType1 == Card.Type.W && cardType2 == Card.Type.E)


func verifyWinner():
	var card1:Card
	var card2:Card
	
	if get_node("CardPlace/Collision/Place1").get_children().size() == 1:
		card1 = get_node("CardPlace/Collision/Place1").get_child(0)	
	
	if get_node("CardPlace/Collision/Place2").get_children().size() == 1:
		card2 = get_node("CardPlace/Collision/Place2").get_child(0)
	
	if(card1 == null or card2 ==null):
		rpc("setLocalTurn", not isLocalTurn())
		setLocalTurn(not isLocalTurn())
		return
		
	await get_tree().create_timer(1).timeout
	_play_battle_vfx()
	var cv1 = card1.cardValue
	var cv2 = card2.cardValue
	
	var cvex1 = 0
	var cvex2 = 0
	
	if cv1 == 5:
		if typeAffinityMax(card1.cardType, card2.cardType):
			cvex1 += 3
		elif typeAffinityMin(card1.cardType, card2.cardType):
			cvex1 += 2
	else:
		if typeAffinityMax(card1.cardType, card2.cardType):
			cvex1 += 2
		elif typeAffinityMin(card1.cardType, card2.cardType):
			cvex1 += 1

	if cv2 == 5:
		if typeAffinityMax(card2.cardType, card1.cardType):
			cvex2 += 3
		elif typeAffinityMin(card2.cardType, card1.cardType):
			cvex2 += 2
	else:
		if typeAffinityMax(card2.cardType, card1.cardType):
			cvex2 += 2
		elif typeAffinityMin(card2.cardType, card1.cardType):
			cvex2 += 1
	
	
	print("=================")
	print(str(cv1) +"+"+ str(cvex1))
	print(str(cv2) +"+"+ str(cvex2))
	
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
		v = abs(cv1+cvex1) - abs(cv2+cvex2)
		winner = card1.cardOwner
	else:
		cardToAnimate = card2
		v = abs(cv2+cvex2) - abs(cv1+cvex1)
		winner = card2.cardOwner
	
	cardToAnimate.animateBattle(card2 if card1 == cardToAnimate else card1)
	await cardToAnimate.animation_battle_ended

	if winner == Card.Owner.ME:  localScore += v
	else:  remoteScore += v
	
	get_node("UI/Local/Score").text = "%02d" %  localScore
	get_node("UI/Remote/Score").text = "%02d" % remoteScore
	
	
	if !haveCards() || localScore >= Game.MAX_SCORE || remoteScore >=  Game.MAX_SCORE:
		get_node("PopupEnd").popup()
	else:
		if winner == Card.Owner.ME: 
			rpc("setLocalTurn", true)
			setLocalTurn(true)
		else: 
			rpc("setLocalTurn", false)
			setLocalTurn(false)
		cleanPlaces()
		
func cleanPlaces():
	var places = get_node("CardPlace/Collision").get_children()
	for p in places:
		p.get_child(0).queue_free()
	
	if await deckToLocation(myCardsLocation if isLocalTurn() else enemyCardsLocation):
		await self.cards_on_hand
	
	if await deckToLocation(myCardsLocation if not isLocalTurn() else  enemyCardsLocation):
		await self.cards_on_hand
		
func haveCards():
	var retEnemy = false
	var retLocal = false
	for c in enemyCardsLocation.get_children():
		if c.get_children().size() > 0:
			retEnemy = true
			break
	
	for c in myCardsLocation.get_children():
		if c.get_children().size() > 0:
			retLocal = true
			break

	return retEnemy && retLocal


func _on_BtnMenu_pressed():
	
	Network.close_connection()
	Navigator.change_scene(SceneRoutes.HOME)

func _play_battle_vfx():
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
