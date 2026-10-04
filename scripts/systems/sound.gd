extends Node
## A small voice pool and per-effect cooldown keep large battles quiet and readable.

const CLIPS := {
	"click": preload("res://assets/audio/click.ogg"),
	"collect": preload("res://assets/audio/collect.ogg"),
	"plant": preload("res://assets/audio/plant.ogg"),
	"chop": preload("res://assets/audio/chop.ogg"),
	"sword": preload("res://assets/audio/sword.ogg"),
	"peace": preload("res://assets/audio/peace.ogg"),
	"win": preload("res://assets/audio/win.ogg"),
	"lose": preload("res://assets/audio/lose.ogg"),
}
var muted := false
var voices: Array[AudioStreamPlayer] = []
var last_played: Dictionary = {}

func _ready() -> void:
	muted = bool(get_tree().get_meta("peace_sound_muted", false))
	for index in range(8):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func toggle() -> void:
	muted = not muted
	get_tree().set_meta("peace_sound_muted", muted)
	if muted:
		for voice in voices:
			voice.stop()
	else:
		play("click")

func play(cue: String) -> void:
	if muted or not CLIPS.has(cue) or not is_inside_tree():
		return
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(cue, -1000)) < (180 if cue == "sword" else 80):
		return
	last_played[cue] = now
	for voice in voices:
		if not voice.playing:
			voice.stream = CLIPS[cue]
			voice.volume_db = -14.0 if cue == "sword" else -10.0
			voice.pitch_scale = randf_range(0.94, 1.06) if cue in ["plant", "collect", "sword", "chop"] else 1.0
			voice.play()
			return
