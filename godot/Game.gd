extends Node

const MAX_SCORE = 1100
const BGGREEN = "1a6d00"
const BGRED = "6c151c"
const BGBLUE = "1973ae"

var main

func remotePlay():
	await get_tree().create_timer(1).timeout
	var selectedCard = selectCard()
	if selectedCard:
		selectedCard.moveCard()
		await selectedCard.card_moved
		selectedCard.flip()
		main.verifyWinner()
		
func selectCard():
	var cardsPosition = main.enemyCardsLocation.get_children()
	var cards = []
	for sc in cardsPosition:
		if sc.get_children().size() > 0:
			cards.append(sc.get_child(0))
			
	if cards.is_empty(): return null
	
	randomize()
	
	var place1 = main.get_node("CardPlace/Collision/Place1")
	if place1.get_children().size() > 0:
		var player_card = place1.get_child(0)
		var possible_winners = []
		for c in cards:
			if c.cardValue > player_card.cardValue:
				possible_winners.append(c)
			elif c.cardValue == player_card.cardValue and main.typeAffinityMax(c.cardType, player_card.cardType):
				possible_winners.append(c)
				
		if possible_winners.size() > 0:
			var best_card = possible_winners[0]
			for c in possible_winners:
				if c.cardValue < best_card.cardValue:
					best_card = c
			return best_card
		else:
			var worst_card = cards[0]
			for c in cards:
				if c.cardValue < worst_card.cardValue:
					worst_card = c
			return worst_card
			
	return cards[randi() % cards.size()]
