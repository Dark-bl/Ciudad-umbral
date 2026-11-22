extends CharacterBody3D

const ENGINE_STREAM: AudioStreamWAV = preload("res://assets/audio/engine_loop.wav")

@export var max_forward_speed: float = 20.0
@export var max_reverse_speed: float = 7.0
@export var acceleration: float = 9.5
@export var braking: float = 22.0
@export var coasting_drag: float = 2.1
@export var steering_rate: float = 1.45
@export var paint_color: Color = Color(0.12, 0.34, 0.58)

@onready var vehicle_camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var wheels: Array[Node3D] = [$WheelFL, $WheelFR, $WheelRL, $WheelRR]

var driver: Node3D = null
var driver_input := Vector2.ZERO
var sprinting := false
var brake_input := false
var speed := 0.0
var ai_enabled := false
var ai_route: PackedVector3Array = PackedVector3Array()
var ai_target_index := 0
var ai_cruise_speed := 9.0
var camera_yaw := 0.0
var camera_pitch := deg_to_rad(-8.0)
var engine_audio: AudioStreamPlayer3D

func _ready() -> void:
    add_to_group("drivable_vehicle")
    var spring_arm := $CameraPivot/SpringArm3D as SpringArm3D
    spring_arm.add_excluded_object(get_rid())
    _apply_camera_rotation()
    engine_audio = AudioStreamPlayer3D.new()
    engine_audio.name = "EngineAudio"
    engine_audio.stream = _make_engine_loop()
    engine_audio.volume_db = -28.0
    engine_audio.max_distance = 72.0
    engine_audio.unit_size = 9.0
    add_child(engine_audio)
    if ai_enabled:
        engine_audio.play()
    _apply_vehicle_materials()

func _make_engine_loop() -> AudioStreamWAV:
    var stream := ENGINE_STREAM.duplicate() as AudioStreamWAV
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = int(stream.data.size() / 2)
    return stream

func enter_vehicle(player: Node3D) -> void:
    driver = player
    ai_enabled = false
    driver_input = Vector2.ZERO
    vehicle_camera.current = true

func exit_vehicle() -> void:
    driver = null
    driver_input = Vector2.ZERO
    sprinting = false
    brake_input = false
    vehicle_camera.current = false

func set_driver_input(value: Vector2, is_sprinting: bool) -> void:
    driver_input = value.limit_length(1.0)
    sprinting = is_sprinting

func set_brake_input(value: bool) -> void:
    brake_input = value

func rotate_camera(delta_pixels: Vector2) -> void:
    camera_yaw -= delta_pixels.x * 0.0042
    camera_pitch = clampf(camera_pitch - delta_pixels.y * 0.0042, deg_to_rad(-24.0), deg_to_rad(18.0))
    _apply_camera_rotation()

func _apply_camera_rotation() -> void:
    camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0.0)

func set_ai_route(route: PackedVector3Array, start_index: int = 0, cruise_speed: float = 9.0) -> void:
    ai_route = route
    ai_target_index = clampi(start_index, 0, max(0, route.size() - 1))
    ai_cruise_speed = cruise_speed
    ai_enabled = route.size() >= 2

func set_paint_color(value: Color) -> void:
    paint_color = value
    _apply_vehicle_materials()

func _physics_process(delta: float) -> void:
    if driver != null:
        _update_player_driving(delta)
    elif ai_enabled:
        _update_ai_driving(delta)
    else:
        speed = move_toward(speed, 0.0, coasting_drag * delta)

    var forward := -global_transform.basis.z
    velocity.x = forward.x * speed
    velocity.z = forward.z * speed
    velocity.y = -0.35
    move_and_slide()
    if is_on_wall():
        speed = move_toward(speed, 0.0, braking * delta)
    for wheel in wheels:
        wheel.rotate_y(-speed * delta / 0.39)
    _update_engine_audio()

func _update_engine_audio() -> void:
    if engine_audio == null:
        return
    var engine_active := driver != null or ai_enabled
    if engine_active and not engine_audio.playing:
        engine_audio.play()
    elif not engine_active and engine_audio.playing:
        engine_audio.stop()
    if engine_active:
        var speed_ratio := clampf(absf(speed) / max_forward_speed, 0.0, 1.0)
        engine_audio.pitch_scale = 0.76 + speed_ratio * 0.78
        engine_audio.volume_db = -19.0 if driver != null else -29.0

func _update_player_driving(delta: float) -> void:
    if brake_input:
        speed = move_toward(speed, 0.0, braking * delta)
    else:
        var throttle := driver_input.y
        if throttle > 0.08:
            speed = move_toward(speed, max_forward_speed, acceleration * throttle * delta)
        elif throttle < -0.08:
            if speed > 1.0:
                speed = move_toward(speed, 0.0, braking * absf(throttle) * delta)
            else:
                speed = move_toward(speed, -max_reverse_speed, acceleration * absf(throttle) * delta)
        else:
            speed = move_toward(speed, 0.0, coasting_drag * delta)

    if sprinting and speed > 0.0 and not brake_input:
        speed = minf(speed + 1.4 * delta, max_forward_speed + 2.0)
    var steering_factor := clampf(absf(speed) / 5.0, 0.18, 1.0)
    if absf(speed) > 0.15:
        rotation.y -= driver_input.x * steering_rate * steering_factor * signf(speed) * delta

func _update_ai_driving(delta: float) -> void:
    if ai_route.size() < 2:
        ai_enabled = false
        return
    var target := ai_route[ai_target_index]
    var to_target := target - global_position
    to_target.y = 0.0
    if to_target.length() < 4.2:
        ai_target_index = (ai_target_index + 1) % ai_route.size()
        target = ai_route[ai_target_index]
        to_target = target - global_position
        to_target.y = 0.0
    if to_target.length() > 0.1:
        var direction := to_target.normalized()
        var desired_angle := atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(rotation.y, desired_angle, delta * 2.2)
    speed = move_toward(speed, ai_cruise_speed, acceleration * 0.55 * delta)

func _apply_vehicle_materials() -> void:
    if not is_inside_tree() and not is_node_ready():
        return
    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = paint_color
    body_material.metallic = 0.48
    body_material.roughness = 0.27
    $Body.material_override = body_material
    $Hood.material_override = body_material
    var cabin_material := StandardMaterial3D.new()
    cabin_material.albedo_color = Color(0.035, 0.055, 0.07)
    cabin_material.metallic = 0.2
    cabin_material.roughness = 0.2
    $Cabin.material_override = cabin_material
    var glass_material := StandardMaterial3D.new()
    glass_material.albedo_color = Color(0.09, 0.16, 0.2)
    glass_material.metallic = 0.28
    glass_material.roughness = 0.16
    for glass_name in ["FrontGlass", "RearGlass", "LeftSideGlass", "RightSideGlass"]:
        var glass_node := get_node(glass_name) as MeshInstance3D
        glass_node.material_override = glass_material
    var tire_material := StandardMaterial3D.new()
    tire_material.albedo_color = Color(0.025, 0.03, 0.035)
    tire_material.roughness = 0.96
    for wheel in wheels:
        wheel.material_override = tire_material
    var bumper_material := StandardMaterial3D.new()
    bumper_material.albedo_color = Color(0.12, 0.13, 0.14)
    bumper_material.metallic = 0.55
    bumper_material.roughness = 0.42
    $FrontBumper.material_override = bumper_material
    $RearBumper.material_override = bumper_material
    $FrontGrille.material_override = bumper_material
    var headlight_material := StandardMaterial3D.new()
    headlight_material.albedo_color = Color(0.92, 0.83, 0.61)
    headlight_material.emission_enabled = true
    headlight_material.emission = Color(0.92, 0.77, 0.52)
    headlight_material.emission_energy_multiplier = 0.45
    $HeadlampL.material_override = headlight_material
    $HeadlampR.material_override = headlight_material
    var tail_material := StandardMaterial3D.new()
    tail_material.albedo_color = Color(0.62, 0.045, 0.035)
    tail_material.emission_enabled = true
    tail_material.emission = Color(0.5, 0.025, 0.015)
    tail_material.emission_energy_multiplier = 0.45
    $TailLampL.material_override = tail_material
    $TailLampR.material_override = tail_material
    $MirrorL.material_override = body_material
    $MirrorR.material_override = body_material
