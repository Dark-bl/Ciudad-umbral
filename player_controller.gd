extends CharacterBody3D

const FOOTSTEP_STREAM: AudioStreamWAV = preload("res://assets/audio/footstep_concrete.wav")

signal vehicle_state_changed(in_vehicle: bool)

@export var walk_speed: float = 4.5
@export var run_speed: float = 7.0
@export var ground_acceleration: float = 24.0
@export var ground_deceleration: float = 30.0
@export var jump_velocity: float = 6.7
@export var gravity: float = 18.0
@export var touch_sensitivity: float = 0.0042
@export var mouse_sensitivity: float = 0.0035

@onready var camera_pivot: Node3D = $CameraPivot
@onready var player_camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visual_root: Node3D = $VisualRoot
@onready var left_leg: Node3D = $VisualRoot/LeftLegPivot
@onready var right_leg: Node3D = $VisualRoot/RightLegPivot
@onready var left_arm: Node3D = $VisualRoot/LeftArmPivot
@onready var right_arm: Node3D = $VisualRoot/RightArmPivot

var mobile_movement := Vector2.ZERO
var mobile_sprint := false
var mobile_brake := false
var jump_requested := false
var interact_requested := false
var camera_yaw := 0.0
var camera_pitch := deg_to_rad(-11.0)
var current_vehicle: CharacterBody3D = null
var collision_layer_before_vehicle := 1
var collision_mask_before_vehicle := 1
var _animation_clock := 0.0
var _is_moving := false
var _step_clock := 0.0
var _footstep_player: AudioStreamPlayer3D

func _ready() -> void:
    var spring_arm := $CameraPivot/SpringArm3D as SpringArm3D
    spring_arm.add_excluded_object(get_rid())
    _footstep_player = AudioStreamPlayer3D.new()
    _footstep_player.name = "FootstepAudio"
    _footstep_player.stream = FOOTSTEP_STREAM
    _footstep_player.volume_db = -9.0
    _footstep_player.max_distance = 22.0
    _footstep_player.unit_size = 6.0
    add_child(_footstep_player)
    _build_character_details()
    _apply_camera_rotation()

func _build_character_details() -> void:
    var eye_white := _detail_material(Color(0.88, 0.84, 0.76), 0.42)
    var pupil := _detail_material(Color(0.035, 0.027, 0.022), 0.22)
    var skin := _detail_material(Color(0.62, 0.43, 0.32), 0.84)
    var dark_trim := _detail_material(Color(0.045, 0.065, 0.075), 0.72)
    var metal_trim := _detail_material(Color(0.42, 0.48, 0.47), 0.35, 0.68)
    for side in [-1.0, 1.0]:
        _add_detail_sphere("Ear", Vector3(side * 0.215, 1.94, 0.0), Vector3(0.045, 0.07, 0.045), skin)
        _add_detail_sphere("Eye", Vector3(side * 0.075, 1.985, -0.202), Vector3(0.031, 0.024, 0.018), eye_white)
        _add_detail_sphere("Pupil", Vector3(side * 0.075, 1.984, -0.219), Vector3(0.013, 0.017, 0.009), pupil)
        _add_detail_box("Eyebrow", Vector3(side * 0.075, 2.035, -0.203), Vector3(0.075, 0.018, 0.018), dark_trim)
        _add_detail_box("JacketPocket", Vector3(side * 0.19, 1.22, -0.306), Vector3(0.19, 0.17, 0.025), dark_trim)
    _add_detail_sphere("Nose", Vector3(0, 1.925, -0.222), Vector3(0.035, 0.043, 0.04), skin)
    _add_detail_box("Mouth", Vector3(0, 1.865, -0.207), Vector3(0.075, 0.012, 0.014), dark_trim)
    _add_detail_box("JacketZipper", Vector3(0, 1.27, -0.309), Vector3(0.018, 0.48, 0.018), metal_trim)
    _add_detail_box("Backpack", Vector3(0, 1.24, 0.27), Vector3(0.47, 0.63, 0.22), dark_trim)

func _detail_material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    return material

func _add_detail_sphere(node_name: String, position: Vector3, scale_value: Vector3, material: Material) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = node_name
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.scale = scale_value
    mesh_instance.material_override = material
    visual_root.add_child(mesh_instance)

func _add_detail_box(node_name: String, position: Vector3, box_size: Vector3, material: Material) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = box_size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = material
    visual_root.add_child(mesh_instance)

func set_mobile_movement(value: Vector2) -> void:
    mobile_movement = value.limit_length(1.0)

func set_mobile_sprint(value: bool) -> void:
    mobile_sprint = value

func set_mobile_brake(value: bool) -> void:
    mobile_brake = value

func request_jump() -> void:
    jump_requested = true

func request_interact() -> void:
    interact_requested = true

func rotate_camera(delta_pixels: Vector2) -> void:
    if current_vehicle != null and is_instance_valid(current_vehicle):
        if current_vehicle.has_method("rotate_camera"):
            current_vehicle.call("rotate_camera", delta_pixels)
        return
    camera_yaw -= delta_pixels.x * touch_sensitivity
    camera_pitch = clampf(camera_pitch - delta_pixels.y * touch_sensitivity, deg_to_rad(-52.0), deg_to_rad(28.0))
    _apply_camera_rotation()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        if current_vehicle != null and is_instance_valid(current_vehicle):
            if current_vehicle.has_method("rotate_camera"):
                current_vehicle.call("rotate_camera", event.relative * (mouse_sensitivity / touch_sensitivity))
        else:
            camera_yaw -= event.relative.x * mouse_sensitivity
            camera_pitch = clampf(camera_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-52.0), deg_to_rad(28.0))
            _apply_camera_rotation()

func _physics_process(delta: float) -> void:
    var input_vector := _get_move_input()
    var wants_interact := interact_requested or Input.is_action_just_pressed("interact")
    if current_vehicle != null:
        if is_instance_valid(current_vehicle):
            current_vehicle.call("set_driver_input", input_vector, mobile_sprint or Input.is_action_pressed("sprint"))
            current_vehicle.call("set_brake_input", mobile_brake)
            if wants_interact:
                _exit_vehicle()
        else:
            current_vehicle = null
            collision_layer = collision_layer_before_vehicle
            collision_mask = collision_mask_before_vehicle
            show()
            player_camera.current = true
            vehicle_state_changed.emit(false)
        interact_requested = false
        jump_requested = false
        return

    if wants_interact:
        _try_enter_vehicle()
    interact_requested = false

    var camera_basis := camera_pivot.global_transform.basis
    var forward := -camera_basis.z
    var right := camera_basis.x
    forward.y = 0.0
    right.y = 0.0
    forward = forward.normalized()
    right = right.normalized()
    var direction := (right * input_vector.x + forward * input_vector.y).limit_length(1.0)
    var is_sprinting := mobile_sprint or Input.is_action_pressed("sprint")
    var target_speed := run_speed if is_sprinting else walk_speed
    var acceleration := ground_acceleration if direction.length() > 0.05 else ground_deceleration
    var target_velocity := direction * target_speed
    velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump") or jump_requested:
        velocity.y = jump_velocity
    else:
        velocity.y = -0.15

    _is_moving = direction.length() > 0.08
    if _is_moving:
        var target_angle := atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(rotation.y, target_angle, minf(1.0, delta * 11.0))
    _animate_character(delta, is_sprinting)
    jump_requested = false
    move_and_slide()

    if global_position.y < -18.0:
        global_position = Vector3(0.0, 0.065, 13.0)
        velocity = Vector3.ZERO

func _get_move_input() -> Vector2:
    var keyboard := Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
    )
    if mobile_movement.length() > 0.05:
        return mobile_movement.limit_length(1.0)
    return keyboard.limit_length(1.0)

func _animate_character(delta: float, is_sprinting: bool) -> void:
    var target_blend := 1.0 if _is_moving else 0.0
    if _is_moving and is_on_floor():
        _step_clock += delta
        var step_interval := 0.36 if is_sprinting else 0.52
        if _step_clock >= step_interval and _footstep_player != null:
            _step_clock = 0.0
            _footstep_player.play()
    else:
        _step_clock = 0.0
    _animation_clock += delta * (12.5 if is_sprinting else 8.8)
    var gait := sin(_animation_clock) * target_blend
    left_leg.rotation.x = lerpf(left_leg.rotation.x, gait * 0.56, delta * 12.0)
    right_leg.rotation.x = lerpf(right_leg.rotation.x, -gait * 0.56, delta * 12.0)
    left_arm.rotation.x = lerpf(left_arm.rotation.x, -gait * 0.42, delta * 12.0)
    right_arm.rotation.x = lerpf(right_arm.rotation.x, gait * 0.42, delta * 12.0)
    visual_root.position.y = lerpf(visual_root.position.y, absf(gait) * 0.025, delta * 9.0)

func _try_enter_vehicle() -> void:
    var nearest: CharacterBody3D = null
    var nearest_distance := 4.2
    for candidate in get_tree().get_nodes_in_group("drivable_vehicle"):
        if not is_instance_valid(candidate) or candidate == current_vehicle:
            continue
        if candidate.get("driver") != null:
            continue
        var distance := global_position.distance_to(candidate.global_position)
        if distance < nearest_distance:
            nearest = candidate as CharacterBody3D
            nearest_distance = distance
    if nearest == null:
        return
    current_vehicle = nearest
    collision_layer_before_vehicle = collision_layer
    collision_mask_before_vehicle = collision_mask
    collision_layer = 0
    collision_mask = 0
    velocity = Vector3.ZERO
    hide()
    player_camera.current = false
    current_vehicle.call("enter_vehicle", self)
    vehicle_state_changed.emit(true)

func _exit_vehicle() -> void:
    if current_vehicle == null or not is_instance_valid(current_vehicle):
        current_vehicle = null
        mobile_brake = false
        collision_layer = collision_layer_before_vehicle
        collision_mask = collision_mask_before_vehicle
        show()
        player_camera.current = true
        vehicle_state_changed.emit(false)
        return
    var vehicle := current_vehicle
    current_vehicle = null
    mobile_brake = false
    vehicle.call("exit_vehicle")
    var exit_offset := vehicle.global_transform.basis.x * 1.85
    global_position = vehicle.global_position + exit_offset
    velocity = Vector3.ZERO
    collision_layer = collision_layer_before_vehicle
    collision_mask = collision_mask_before_vehicle
    show()
    player_camera.current = true
    vehicle_state_changed.emit(false)

func _apply_camera_rotation() -> void:
    camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0.0)
