extends Node

#Audio
const MAX_SAMPLES = 20

const THRESHOLD_DEFAULT: float = 0.5
const INPUT_GAIN_DEFAULT: float = 0.0

const AUDIO_REST_TIMEOUT = 60

#Audio Vars
var bus_index
var analyzer: AudioEffectSpectrumAnalyzerInstance
var samples: Array[float] = []
var amplifier_effect = AudioEffectAmplify
var threshold = 0.5
var input_gain: float
var input_device: String
var mag_throbber_value:= 0.0
var _microphone_reset_timer := Timer.new()

var _current_microphone_device: AudioStreamPlayer = null

func _ready() -> void:
    bus_index = AudioServer.get_bus_index("Record")
    amplifier_effect = AudioServer.get_bus_effect(bus_index, 1)

    create_microphone_device()

    _microphone_reset_timer.wait_time=AUDIO_REST_TIMEOUT
    _microphone_reset_timer.timeout.connect(self.audio_reset)
    _microphone_reset_timer.autostart=true
    add_child(_microphone_reset_timer)

func create_microphone_device():
    var audio_player = AudioStreamPlayer.new()
    var microphone = AudioStreamMicrophone.new()
    audio_player.stream = microphone 
    audio_player.autoplay = true
    add_child(audio_player)
    audio_player.stream_paused=true # if you don't set this to true you can monitor your self. 
    _current_microphone_device = audio_player

func get_audio_devices() -> PackedStringArray: 
    return  AudioServer.get_input_device_list()

func _get_average() -> float:
    var mag_sum: float = 0.0
    var mag_avg: float = 0.0
    for i in samples:
        mag_sum += i
    mag_avg = mag_sum / float(samples.size())
    return mag_avg

func _process(_delta: float) -> void:
    # Audio Processing
    var current_db = AudioServer.get_bus_peak_volume_left_db(bus_index, 0)
    var magnitude = db_to_linear(current_db)

    if samples.size() >= MAX_SAMPLES:
        samples.pop_front()
    samples.append(magnitude)
    
    var magnitude_avg = _get_average() 
    mag_throbber_value = magnitude_avg

func set_input_source(new_input_device) -> void:
    AudioServer.set_input_device(new_input_device)
    input_device = new_input_device

func get_audio_config() -> Array:
    return [input_device, threshold, input_gain]

func set_audio_config(set_input_device, set_threshold, set_input_gain_value) -> void:
    threshold = set_threshold
    set_input_gain(set_input_gain_value)
    set_input_source(set_input_device)
    

func set_input_gain(new_input_gain: float) -> void:
    _update_amplifier(new_input_gain)
    input_gain = new_input_gain

func _update_amplifier(new_input_gain: float):
    if new_input_gain <= -10.0 || new_input_gain >= 24.1:
        return
    if amplifier_effect.volume_db != new_input_gain:
        amplifier_effect.volume_db = new_input_gain

func audio_reset() -> void:
    print_debug("Resetting audio device")
    # based on this from a bug report 
    # https://github.com/godotengine/godot/issues/80173#issuecomment-2119148302
    _current_microphone_device.playing=false
    await get_tree().create_timer(0.25).timeout
    _current_microphone_device.playing=true
    _current_microphone_device.stream_paused=true # if you don't set this to true you can monitor your self. 
