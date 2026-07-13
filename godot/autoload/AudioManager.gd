extends Node

var sfx_hover: AudioStreamPlayer
var sfx_impact: AudioStreamPlayer
var sfx_victory: AudioStreamPlayer
var sfx_defeat: AudioStreamPlayer

func _ready():
	# Create synthetic sounds so we don't need asset files!
	sfx_hover = AudioStreamPlayer.new()
	sfx_hover.stream = _create_synthetic_sound(400.0, 0.05, 0.5) # Quick high blip
	add_child(sfx_hover)
	
	sfx_impact = AudioStreamPlayer.new()
	sfx_impact.stream = _create_synthetic_sound(150.0, 0.2, 2.0, true) # Low crunchy thud
	add_child(sfx_impact)
	
	sfx_victory = AudioStreamPlayer.new()
	sfx_victory.stream = _create_synthetic_sound(600.0, 0.5, 1.0) # Longer high beep
	add_child(sfx_victory)
	
	sfx_defeat = AudioStreamPlayer.new()
	sfx_defeat.stream = _create_synthetic_sound(200.0, 0.8, 0.5) # Sad low beep
	add_child(sfx_defeat)

func _create_synthetic_sound(freq: float, duration: float, volume: float, noise: bool = false) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var time = float(i) / sample_rate
		var wave = 0.0
		if noise:
			wave = randf_range(-1.0, 1.0) * exp(-time * 10.0) # Decay noise
		else:
			wave = sin(time * freq * 2.0 * PI) * exp(-time * 5.0) # Decay sine
		
		var val = int(wave * volume * 127.0) + 128
		val = clampi(val, 0, 255)
		data[i] = val
		
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	return stream

func play_hover():
	if not sfx_hover.playing:
		sfx_hover.play()

func play_impact():
	sfx_impact.play()

func play_victory():
	sfx_victory.play()

func play_defeat():
	sfx_defeat.play()
