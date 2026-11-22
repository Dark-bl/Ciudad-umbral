extends CharacterBody3D

@export var waypoints: PackedVector3Array = PackedVector3Array()
@export var walk_speed: float = 1.25
@export var outfit_color: Color = Color(0.24, 0.31, 0.38)

var _target_index := 1
var _phase := 0.0
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D

func _ready() -> void:
    name = "Pedestrian"
    collision_layer = 1
    collision_mask = 1
    if waypoints.size() > 0:
        global_position = waypoints[0]
    if waypoints.size() < 2:
        set_physics_process(false)
        return
    _build_appearance()

func _build_appearance() -> void:
    var jacket := StandardMaterial3D.new()
    jacket.albedo_color = outfit_color
    jacket.roughness = 0.88
    var trousers := StandardMaterial3D.new()
    trousers.albedo_color = Color(0.13, 0.15, 0.17)
    trousers.roughness = 0.92
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.58, 0.4, 0.29)
    skin.roughness = 0.9
    var shape := CapsuleShape3D.new()
    shape.radius = 0.23
    shape.height = 1.65
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 0.84
    add_child(collision)

    _add_capsule("Body", Vector3(0, 1.12, 0), 0.25, 0.72, jacket)
    _add_sphere("Head", Vector3(0, 1.78, 0), 0.17, skin)
    var hair := StandardMaterial3D.new()
    hair.albedo_color = Color(0.065, 0.045, 0.032)
    hair.roughness = 0.96
    var eye_white := StandardMaterial3D.new()
    eye_white.albedo_color = Color(0.88, 0.84, 0.76)
    var pupil := StandardMaterial3D.new()
    pupil.albedo_color = Color(0.025, 0.02, 0.018)
    var hair_cap := _add_sphere("Hair", Vector3(0, 1.88, 0.01), 0.17, hair)
    hair_cap.scale = Vector3(1.02, 0.48, 1.02)
    for side in [-1.0, 1.0]:
        _add_sphere("EyeWhite", Vector3(side * 0.055, 1.8, -0.151), 0.025, eye_white)
        _add_sphere("EyePupil", Vector3(side * 0.055, 1.8, -0.17), 0.012, pupil)
    _left_leg = _add_pivot("LeftLeg", Vector3(-0.13, 0.78, 0))
    _right_leg = _add_pivot("RightLeg", Vector3(0.13, 0.78, 0))
    _add_capsule_to(_left_leg, "Leg", Vector3(0, -0.28, 0), 0.105, 0.58, trousers)
    _add_capsule_to(_right_leg, "Leg", Vector3(0, -0.28, 0), 0.105, 0.58, trousers)
    _left_arm = _add_pivot("LeftArm", Vector3(-0.31, 1.48, 0))
    _right_arm = _add_pivot("RightArm", Vector3(0.31, 1.48, 0))
    _add_capsule_to(_left_arm, "Arm", Vector3(0, -0.25, 0), 0.085, 0.5, jacket)
    _add_capsule_to(_right_arm, "Arm", Vector3(0, -0.25, 0), 0.085, 0.5, jacket)

func _physics_process(delta: float) -> void:
    _phase += delta * 7.0
    var target := waypoints[_target_index]
    var to_target := target - global_position
    to_target.y = 0.0
    if to_target.length() < 0.9:
        _target_index = (_target_index + 1) % waypoints.size()
        target = waypoints[_target_index]
        to_target = target - global_position
        to_target.y = 0.0
    var direction := to_target.normalized()
    velocity.x = direction.x * walk_speed
    velocity.z = direction.z * walk_speed
    velocity.y -= 18.0 * delta
    if direction.length() > 0.05:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 4.5)
    move_and_slide()
    var swing := sin(_phase) * 0.32
    if _left_leg != null:
        _left_leg.rotation.x = swing
        _right_leg.rotation.x = -swing
        _left_arm.rotation.x = -swing * 0.75
        _right_arm.rotation.x = swing * 0.75

func _add_pivot(node_name: String, position: Vector3) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = node_name
    pivot.position = position
    add_child(pivot)
    return pivot

func _add_capsule(node_name: String, position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
    return _add_capsule_to(self, node_name, position, radius, height, material)

func _add_capsule_to(parent: Node3D, node_name: String, position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    visual.name = node_name
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    visual.mesh = mesh
    visual.position = position
    visual.material_override = material
    parent.add_child(visual)
    return visual

func _add_sphere(node_name: String, position: Vector3, radius: float, material: Material) -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    visual.name = node_name
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    visual.mesh = mesh
    visual.position = position
    visual.material_override = material
    add_child(visual)
    return visual
