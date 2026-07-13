extends Area2D
class_name Card

enum Owner {ME, OTHER}
enum Type {A, E, F, W, X}

var COLOR_AIR = "#90caf9"
var COLOR_WATER = "#00b8d4"
var COLOR_FIRE = "#dd2c00"
var COLOR_EARTH = "#7cb342"

var followMouse = false
var originalPosition
var dropped = false
var cardTexture
var cardOwner

var cardType
var cardValue

signal card_moved
signal animation_battle_ended
signal animation_hide_ended

var hover_tween: Tween
var glow_light: PointLight2D
var battle_particles: GPUParticles2D

func _create_glow_texture() -> GradientTexture2D:
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1, 1, 1, 1))
	grad.add_point(1.0, Color(1, 1, 1, 0))
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1, 0.5)
	tex.width = 256
	tex.height = 256
	return tex

func _create_particles_material() -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(50, 80, 1)
	mat.gravity = Vector3(0, -200, 0)
	mat.initial_velocity_min = 50
	mat.initial_velocity_max = 100
	mat.scale_min = 2.0
	mat.scale_max = 4.0
	return mat

func _ready():
	# Inject PointLight2D
	glow_light = PointLight2D.new()
	glow_light.texture = _create_glow_texture()
	glow_light.energy = 0.0
	glow_light.color = Color(0.8, 0.9, 1.0)
	glow_light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(glow_light)
	
	# Inject GPUParticles2D
	battle_particles = GPUParticles2D.new()
	battle_particles.process_material = _create_particles_material()
	battle_particles.emitting = false
	battle_particles.one_shot = true
	battle_particles.explosiveness = 0.8
	battle_particles.amount = 30
	battle_particles.lifetime = 0.6
	add_child(battle_particles)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	AudioManager.play_hover()
	if get_parent() and get_parent().get_parent() and get_parent().get_parent().name == "MyCardsLocation":
		if hover_tween: hover_tween.kill()
		hover_tween = create_tween().set_parallel(true)
		hover_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
		hover_tween.tween_property(self, "rotation_degrees", randf_range(-5.0, 5.0), 0.1)
		hover_tween.tween_property(glow_light, "energy", 1.5, 0.2)

func _on_mouse_exited():
	if get_parent() and get_parent().get_parent() and get_parent().get_parent().name == "MyCardsLocation":
		if hover_tween: hover_tween.kill()
		hover_tween = create_tween().set_parallel(true)
		hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE)
		hover_tween.tween_property(self, "rotation_degrees", 0.0, 0.2)
		hover_tween.tween_property(glow_light, "energy", 0.0, 0.3)

func flip():
	$Anim.play("flip")
	await $Anim.animation_finished
	$Image.visible = false
	$Anim.play_backwards("flip")
	await $Anim.animation_finished

func _on_Card_input_event(viewport, ev, shape_idx):
	if (ev is InputEventMouseButton and ev.is_pressed()):
		if (Game.main.isLocalTurn()):
			var p =  get_parent().name
			if get_parent().get_parent().name ==  "MyCardsLocation":
				moveCard()
				await self.card_moved
				Game.main.verifyWinner()

func moveCard():
	print ("movecard")
	var area = Game.main.get_node("CardPlace/Collision")
	if area:		
		var place = area.get_node("Place1")
		if place.get_children().size() > 0:
			place = area.get_node("Place2")
		z_index = 999
		var t = create_tween()
		t.tween_property(self, "global_position", place.get_global_position(), 0.25).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		await t.finished
		z_index = 0
		get_parent().remove_child(self)	
		place.add_child(self)
		position = Vector2.ZERO
		emit_signal("card_moved")

	
func animateHide():
	$Anim.play("hide")
	await $Anim.animation_finished;

func animateBattle(otherCard:Card):
	z_index = 999
	var side = otherCard.global_position.x < global_position.x
	
	otherCard.animateHide()	
	setElementTexture()
	
	# Emit particles matching element color
	battle_particles.modulate = $top.self_modulate
	battle_particles.emitting = true
	
	if not side:
		$Anim.play("battle")
		await $Anim.animation_finished;
	else:
		$Anim.play("battle_left")	
		await $Anim.animation_finished;
	z_index = 0		
	emit_signal("animation_battle_ended")

func setElementTexture():
	$elementAnimation.texture = $element.texture

func initialize():
	match cardType:
		Type.A:
			$top.self_modulate = COLOR_AIR
			$element.texture = load("res://assets/Elements/air.png")
			$one.self_modulate = COLOR_FIRE
			$two.self_modulate = COLOR_WATER
		Type.W:
			$top.self_modulate = COLOR_WATER
			$element.texture = load("res://assets/Elements/water.png")
			$one.self_modulate = COLOR_EARTH
			$two.self_modulate = COLOR_FIRE
		Type.F:
			$top.self_modulate = COLOR_FIRE
			$element.texture = load("res://assets/Elements/fire.png")
			$one.self_modulate = COLOR_AIR
			$two.self_modulate = COLOR_EARTH
		Type.E:
			$top.self_modulate = COLOR_EARTH
			$element.texture = load("res://assets/Elements/earth.png")
			$one.self_modulate = COLOR_WATER
			$two.self_modulate = COLOR_AIR
		Type.X:
			$element.texture = load("res://assets/Elements/all.png")
			
	$top/Label.text = str(cardValue)
	
	if cardValue != 10:
		$one.visible = true
		$two.visible = true
		$one/Label.text = "+2" if cardValue == 5 else "+1"
		$two/Label.text = "+3" if cardValue == 5 else "+2"
		
