extends Node

const CITY_AMBIENCE: AudioStreamWAV = preload("res://assets/audio/city_ambience.wav")

var ambience_player: AudioStreamPlayer

func _ready() -> void:
    ambience_player = AudioStreamPlayer.new()
    ambience_player.name = "CityAmbience"
    ambience_player.stream = _make_loop(CITY_AMBIENCE)
    ambience_player.volume_db = -24.0
    ambience_player.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(ambience_player)
    ambience_player.play()

func _make_loop(source: AudioStreamWAV) -> AudioStreamWAV:
    var stream := source.duplicate() as AudioStreamWAV
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = int(stream.data.size() / 2)
    return stream
