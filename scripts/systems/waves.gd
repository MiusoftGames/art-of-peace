class_name WaveSpawner
extends Node

signal spawn_pair_requested
signal message_requested(text: String)

var settings: PeaceSettings
var wave := 1
var pairs_sent := 0
var rest_remaining := 0.0
var spawn_remaining := 5.0

func configure(tuning: PeaceSettings) -> void:
	settings = tuning
	wave = 1
	pairs_sent = 0
	rest_remaining = 0.0
	spawn_remaining = interval()

func interval() -> float:
	return maxf(settings.minimum_spawn_gap, settings.initial_spawn_gap - (wave - 1) * settings.gap_reduction_per_wave - pairs_sent * settings.gap_reduction_per_pair)

func advance(delta: float) -> void:
	if rest_remaining > 0.0:
		rest_remaining = maxf(0.0, rest_remaining - delta)
		if rest_remaining == 0.0:
			begin_next_wave()
		return
	spawn_remaining -= delta
	while spawn_remaining <= 0.0:
		spawn_pair_requested.emit()
		pairs_sent += 1
		if pairs_sent >= settings.pairs_per_wave:
			rest_remaining = settings.wave_rest_seconds
			message_requested.emit("Wave %d sent. %.0f seconds to reshape the forest." % [wave, rest_remaining])
			if rest_remaining == 0.0:
				begin_next_wave()
			break
		spawn_remaining += interval()

func begin_next_wave() -> void:
	wave += 1
	pairs_sent = 0
	spawn_remaining = interval()
	message_requested.emit("Wave %d begins. Keep the peaceful people alive!" % wave)
