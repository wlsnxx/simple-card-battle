import sys

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    start_str = 'func verifyWinner():'
    end_str = 'func cleanPlaces():'
    
    start_idx = content.find(start_str)
    end_idx = content.find(end_str)
    
    if start_idx == -1 or end_idx == -1:
        print(f"Could not find verifyWinner in {filepath}")
        return
        
    new_func = '''func verifyWinner():
\tvar card1:Card
\tvar card2:Card
\t
\tif get_node("CardPlace/Collision/Place1").get_children().size() == 1:
\t\tcard1 = get_node("CardPlace/Collision/Place1").get_child(0)	
\t
\tif get_node("CardPlace/Collision/Place2").get_children().size() == 1:
\t\tcard2 = get_node("CardPlace/Collision/Place2").get_child(0)
\t
\tif(card1 == null or card2 ==null):
\t\tsetLocalTurn(not isLocalTurn())
\t\treturn
\t\t
\tawait get_tree().create_timer(1).timeout
\t_play_battle_vfx()
\tvar cv1 = card1.cardValue
\tvar cv2 = card2.cardValue
\t
\tvar cvex1 = 0
\tvar cvex2 = 0
\t
\tif card2.cardType != Card.Type.A:
\t\tif cv1 == 5:
\t\t\tif typeAffinityMax(card1.cardType, card2.cardType): cvex1 += 3
\t\t\telif typeAffinityMin(card1.cardType, card2.cardType): cvex1 += 2
\t\telif cv1 == 6:
\t\t\tif typeAffinityMax(card1.cardType, card2.cardType): cvex1 += 2
\t\t\telif typeAffinityMin(card1.cardType, card2.cardType): cvex1 += 1
\t
\tif card1.cardType != Card.Type.A:
\t\tif cv2 == 5:
\t\t\tif typeAffinityMax(card2.cardType, card1.cardType): cvex2 += 3
\t\t\telif typeAffinityMin(card2.cardType, card1.cardType): cvex2 += 2
\t\telif cv2 == 6:
\t\t\tif typeAffinityMax(card2.cardType, card1.cardType): cvex2 += 2
\t\t\telif typeAffinityMin(card2.cardType, card1.cardType): cvex2 += 1
\t
\tvar cardToAnimate
\tvar winner
\tvar v = 0
\tif (cv1 + cvex1) == (cv2 + cvex2):
\t\tvar e = typeAffinityMax(card1.cardType, card2.cardType) || typeAffinityMax(card2.cardType, card1.cardType)
\t\tif e:
\t\t\tcardToAnimate = card1
\t\t\twinner = card1.cardOwner
\t\telse:
\t\t\tcardToAnimate = card2
\t\t\twinner = card2.cardOwner
\t\tv = 1
\telif (cv1 + cvex1) > (cv2 + cvex2):
\t\tcardToAnimate = card1
\t\tv = abs(cv1+cvex1)
\t\twinner = card1.cardOwner
\telse:
\t\tcardToAnimate = card2
\t\tv = abs(cv2+cvex2)
\t\twinner = card2.cardOwner
\t
\tvar winning_card = card1 if winner == card1.cardOwner else card2
\tvar losing_card = card2 if winner == card1.cardOwner else card1
\t
\t# Abilities
\t# Fire (F) -> +1 Damage
\tif winning_card.cardType == Card.Type.F:
\t\tv += 1
\t
\t# Earth (E) -> Takes half damage
\tif losing_card.cardType == Card.Type.E:
\t\tv = max(1, v / 2)
\t\t
\tcardToAnimate.animateBattle(losing_card)
\tawait cardToAnimate.animation_battle_ended
\t
\t# Apply Damage
\tif winner == Card.Owner.ME:  hpRemote -= v
\telse:  hpLocal -= v
\t
\t# Water (W) -> Heals winner +2
\tif winning_card.cardType == Card.Type.W:
\t\tif winner == Card.Owner.ME: hpLocal = min(20, hpLocal + 2)
\t\telse: hpRemote = min(20, hpRemote + 2)
\t
\tget_node("UI/Local/Score").text = "HP: %02d" %  hpLocal
\tget_node("UI/Remote/Score").text = "HP: %02d" % hpRemote
\t
\t
\tif !haveCards() || hpLocal <= 0 || hpRemote <= 0:
\t\tget_node("PopupEnd").popup()
\telse:
\t\tif winner == Card.Owner.ME: setLocalTurn(true)
\t\telse: setLocalTurn(false)
\t\tcleanPlaces()
\t\t
'''
    
    new_content = content[:start_idx] + new_func + content[end_idx:]
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Updated {filepath}")

process_file('Main1P.gd')
process_file('Main.gd')

