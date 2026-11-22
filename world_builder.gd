extends Node3D

const PEDESTRIAN_SCRIPT = preload("res://pedestrian_controller.gd")
const CAR_SCENE = preload("res://car.tscn")

var _rng := RandomNumberGenerator.new()
var _mat_asphalt: StandardMaterial3D
var _mat_concrete: StandardMaterial3D
var _mat_pavers: StandardMaterial3D
var _mat_grass: StandardMaterial3D
var _mat_stucco: StandardMaterial3D
var _mat_brick: StandardMaterial3D
var _mat_glass: StandardMaterial3D
var _mat_metal: StandardMaterial3D
var _mat_white_line: StandardMaterial3D
var _mat_yellow_line: StandardMaterial3D
var _mat_bark: StandardMaterial3D
var _mat_leaves: StandardMaterial3D
var _mat_sign: StandardMaterial3D
var _mat_warm_emission: StandardMaterial3D
var _mat_red_emission: StandardMaterial3D
var _mat_green_emission: StandardMaterial3D
var _environment: Environment
var _sky_material: ProceduralSkyMaterial
var _sun: DirectionalLight3D
var _day_clock := 0.66
var _day_update_clock := 0.0
@export var day_cycle_seconds: float = 720.0

const STREET_COORDS: Array[float] = [-120.0, -60.0, 0.0, 60.0, 120.0]
const CITY_EDGE := 132.0

func _ready() -> void:
    _rng.seed = 20261121
    _create_materials()
    _make_environment()
    _make_ground()
    _make_road_grid()
    _make_city_blocks()
    _make_park()
    _make_street_furniture()
    _spawn_pedestrians()
    _spawn_traffic()
    _update_day_cycle()

func _process(delta: float) -> void:
    _day_clock = fposmod(_day_clock + delta / maxf(day_cycle_seconds, 60.0), 1.0)
    _day_update_clock += delta
    if _day_update_clock >= 0.5:
        _day_update_clock = 0.0
        _update_day_cycle()

func _update_day_cycle() -> void:
    if _environment == null or _sky_material == null or _sun == null:
        return
    var phase := (_day_clock - 0.25) * TAU
    var daylight := clampf(sin(phase), 0.0, 1.0)
    var twilight := clampf(1.0 - absf(daylight - 0.45) / 0.55, 0.0, 1.0)
    _sun.rotation_degrees = Vector3(-18.0 - 48.0 * daylight, _day_clock * 360.0 - 35.0, 0.0)
    _sun.light_energy = 0.045 + daylight * 1.16
    _sun.light_color = Color(0.24, 0.31, 0.48).lerp(Color(1.0, 0.91, 0.79), daylight)
    _sun.shadow_enabled = daylight > 0.16
    _environment.ambient_light_energy = 0.17 + daylight * 0.48
    _environment.fog_light_color = Color(0.055, 0.075, 0.12).lerp(Color(0.62, 0.68, 0.70), daylight)
    _sky_material.sky_top_color = Color(0.018, 0.035, 0.075).lerp(Color(0.14, 0.28, 0.42), daylight)
    var twilight_horizon := Color(0.07, 0.09, 0.14).lerp(Color(0.86, 0.42, 0.24), twilight)
    _sky_material.sky_horizon_color = twilight_horizon.lerp(Color(0.68, 0.72, 0.74), daylight)
    _sky_material.ground_bottom_color = Color(0.025, 0.035, 0.055).lerp(Color(0.14, 0.17, 0.16), daylight)
    _sky_material.ground_horizon_color = Color(0.12, 0.10, 0.12).lerp(Color(0.48, 0.51, 0.49), daylight)

func _create_materials() -> void:
    _mat_asphalt = _textured_material("res://assets/textures/asphalt.png", Color(0.92, 0.94, 0.96), 0.96)
    _mat_concrete = _textured_material("res://assets/textures/concrete.png", Color(0.9, 0.9, 0.88), 0.94)
    _mat_pavers = _textured_material("res://assets/textures/pavers.png", Color(0.95, 0.95, 0.93), 0.9)
    _mat_grass = _textured_material("res://assets/textures/grass.png", Color(0.84, 0.9, 0.78), 0.98)
    _mat_stucco = _textured_material("res://assets/textures/stucco.png", Color(0.92, 0.9, 0.85), 0.9)
    _mat_brick = _textured_material("res://assets/textures/brick.png", Color(0.9, 0.88, 0.84), 0.93)
    _mat_asphalt.uv1_scale = Vector3(24.0, 24.0, 1.0)
    _mat_concrete.uv1_scale = Vector3(5.0, 5.0, 1.0)
    _mat_pavers.uv1_scale = Vector3(12.0, 12.0, 1.0)
    _mat_grass.uv1_scale = Vector3(35.0, 35.0, 1.0)
    _mat_stucco.uv1_scale = Vector3(4.0, 5.0, 1.0)
    _mat_brick.uv1_scale = Vector3(3.0, 5.0, 1.0)
    _mat_glass = _material(Color(0.075, 0.13, 0.17), 0.18, 0.28)
    _mat_metal = _material(Color(0.16, 0.18, 0.2), 0.42, 0.72)
    _mat_white_line = _material(Color(0.86, 0.85, 0.78), 0.88)
    _mat_yellow_line = _material(Color(0.9, 0.67, 0.19), 0.86)
    _mat_bark = _material(Color(0.22, 0.14, 0.09), 0.98)
    _mat_leaves = _material(Color(0.13, 0.27, 0.16), 0.98)
    _mat_sign = _material(Color(0.12, 0.2, 0.23), 0.76)
    _mat_warm_emission = _emissive_material(Color(1.0, 0.76, 0.42), 1.4)
    _mat_red_emission = _emissive_material(Color(0.92, 0.12, 0.08), 1.2)
    _mat_green_emission = _emissive_material(Color(0.16, 0.85, 0.32), 1.1)

func _textured_material(path: String, tint: Color, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.albedo_texture = load(path)
    material.roughness = roughness
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    var normal_path := path.get_basename() + "_normal.png"
    if ResourceLoader.exists(normal_path):
        material.normal_enabled = true
        material.normal_texture = load(normal_path)
        material.normal_scale = 0.28
    var roughness_path := path.get_basename() + "_roughness.png"
    if ResourceLoader.exists(roughness_path):
        material.roughness_texture = load(roughness_path)
    return material

func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    return material

func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
    var material := _material(color, 0.35, 0.0)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material

func _make_environment() -> void:
    var world_environment := WorldEnvironment.new()
    _environment = Environment.new()
    _environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    _sky_material = ProceduralSkyMaterial.new()
    _sky_material.sun_angle_max = 18.0
    sky.sky_material = _sky_material
    _environment.sky = sky
    _environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    _environment.ambient_light_energy = 0.62
    _environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    _environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    _environment.fog_enabled = true
    _environment.fog_light_color = Color(0.62, 0.68, 0.7)
    _environment.fog_density = 0.0012
    world_environment.environment = _environment
    add_child(world_environment)

    _sun = DirectionalLight3D.new()
    _sun.name = "DynamicSun"
    _sun.shadow_enabled = true
    _sun.directional_shadow_max_distance = 105.0
    _sun.light_angular_distance = 0.25
    add_child(_sun)

func _make_ground() -> void:
    _add_static_box(self, "CityGround", Vector3(0, -0.42, 0), Vector3(CITY_EDGE * 2.0, 0.7, CITY_EDGE * 2.0), _mat_grass)
    _add_static_box(self, "CentralPlazaBase", Vector3(0, -0.02, 0), Vector3(24.0, 0.08, 24.0), _mat_pavers)

func _make_road_grid() -> void:
    for coordinate in STREET_COORDS:
        _add_static_box(self, "Road_NS_%d" % int(coordinate), Vector3(coordinate, -0.025, 0), Vector3(14.0, 0.18, CITY_EDGE * 2.0), _mat_asphalt)
        _add_static_box(self, "Road_EW_%d" % int(coordinate), Vector3(0, -0.025, coordinate), Vector3(CITY_EDGE * 2.0, 0.18, 14.0), _mat_asphalt)
        for side in [-1.0, 1.0]:
            _add_static_box(self, "Sidewalk_NS", Vector3(coordinate + side * 9.0, 0.055, 0), Vector3(4.0, 0.22, CITY_EDGE * 2.0), _mat_pavers)
            _add_static_box(self, "Sidewalk_EW", Vector3(0, 0.055, coordinate + side * 9.0), Vector3(CITY_EDGE * 2.0, 0.22, 4.0), _mat_pavers)
            _add_visual_box(self, "Curb_NS", Vector3(coordinate + side * 7.15, 0.13, 0), Vector3(0.22, 0.3, CITY_EDGE * 2.0), _mat_concrete)
            _add_visual_box(self, "Curb_EW", Vector3(0, 0.13, coordinate + side * 7.15), Vector3(CITY_EDGE * 2.0, 0.3, 0.22), _mat_concrete)
        _add_road_markings(coordinate)
    _make_crosswalks()
    _make_manhole_covers()

func _add_road_markings(coordinate: float) -> void:
    for distance in range(-112, 113, 14):
        _add_visual_box(self, "CenterDash_NS", Vector3(coordinate, 0.072, float(distance)), Vector3(0.16, 0.025, 5.2), _mat_yellow_line)
        _add_visual_box(self, "CenterDash_EW", Vector3(float(distance), 0.072, coordinate), Vector3(5.2, 0.025, 0.16), _mat_yellow_line)
    for side in [-1.0, 1.0]:
        _add_visual_box(self, "RoadEdge_NS", Vector3(coordinate + side * 6.45, 0.068, 0), Vector3(0.12, 0.02, CITY_EDGE * 2.0 - 8.0), _mat_white_line)
        _add_visual_box(self, "RoadEdge_EW", Vector3(0, 0.068, coordinate + side * 6.45), Vector3(CITY_EDGE * 2.0 - 8.0, 0.02, 0.12), _mat_white_line)

func _make_crosswalks() -> void:
    for junction in [-60.0, 0.0, 60.0]:
        for side in [-1.0, 1.0]:
            for stripe in range(6):
                var offset := -5.0 + float(stripe) * 2.0
                _add_visual_box(self, "Crosswalk_NS", Vector3(junction + side * 9.5, 0.076, offset + junction), Vector3(1.0, 0.025, 0.72), _mat_white_line)
                _add_visual_box(self, "Crosswalk_EW", Vector3(offset + junction, 0.076, junction + side * 9.5), Vector3(0.72, 0.025, 1.0), _mat_white_line)

func _make_manhole_covers() -> void:
    for point in [Vector3(-4.3, 0.078, 17.0), Vector3(57.0, 0.078, 8.0), Vector3(-63.0, 0.078, -47.0)]:
        var cover := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.72
        mesh.bottom_radius = 0.72
        mesh.height = 0.035
        mesh.radial_segments = 24
        cover.mesh = mesh
        cover.position = point
        cover.material_override = _mat_metal
        add_child(cover)

func _make_city_blocks() -> void:
    var block_centers: Array[float] = [-90.0, -30.0, 30.0, 90.0]
    var shop_names: Array[String] = ["CAFÉ NORTE", "MERCADO 24", "TALLER UMBRAL", "FARMACIA", "PANADERÍA", "ESTUDIO 09"]
    var shop_index := 0
    for x in block_centers:
        for z in block_centers:
            if x == -30.0 and z == 30.0:
                continue
            for side in [-1.0, 1.0]:
                var height := _rng.randf_range(12.0, 31.0)
                if _rng.randf() < 0.22:
                    height = _rng.randf_range(34.0, 43.0)
                var footprint := Vector2(_rng.randf_range(16.0, 20.0), _rng.randf_range(23.0, 29.0))
                var position := Vector3(x + side * 11.5, 0.0, z)
                var wall_material := _mat_brick if _rng.randf() < 0.42 else _mat_stucco
                var shop := shop_names[shop_index % shop_names.size()] if height < 24.0 else ""
                shop_index += 1
                _create_building(position, footprint, height, wall_material, shop, PI * 0.5 if side > 0.0 else -PI * 0.5)

func _create_building(center: Vector3, footprint: Vector2, height: float, wall_material: Material, shop_name: String, facing: float) -> void:
    var building := Node3D.new()
    building.name = "Building_" + str(get_child_count())
    building.position = center
    building.rotation.y = facing
    add_child(building)

    var shell := StaticBody3D.new()
    shell.name = "BuildingCollision"
    building.add_child(shell)
    var wall := MeshInstance3D.new()
    var wall_mesh := BoxMesh.new()
    wall_mesh.size = Vector3(footprint.x, height, footprint.y)
    wall.mesh = wall_mesh
    wall.position.y = height * 0.5
    wall.material_override = wall_material
    shell.add_child(wall)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(footprint.x, height, footprint.y)
    collision.shape = shape
    collision.position.y = height * 0.5
    shell.add_child(collision)

    var front_z := -footprint.y * 0.5 - 0.075
    var floors := int(floor(height / 3.35))
    var window_positions: Array[Transform3D] = []
    var side_window_positions: Array[Transform3D] = []
    var columns := max(2, int(floor(footprint.x / 4.0)))
    var spacing := footprint.x / float(columns + 1)
    for floor_index in range(1, floors):
        var window_y := float(floor_index) * 3.35 + 1.75
        for column in range(columns):
            var window_x := -footprint.x * 0.5 + spacing * float(column + 1)
            window_positions.append(Transform3D(Basis.IDENTITY, Vector3(window_x, window_y, front_z)))
            var side_z := -footprint.y * 0.5 + (footprint.y / float(columns + 1)) * float(column + 1)
            side_window_positions.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(footprint.x * 0.5 + 0.075, window_y, side_z)))
    _add_window_batch(building, window_positions, Vector3(1.8, 1.25, 0.09))
    _add_window_batch(building, side_window_positions, Vector3(1.8, 1.25, 0.09))
    if floors >= 5 and _rng.randf() < 0.38:
        for balcony_floor in range(2, floors, 3):
            _create_balcony(building, front_z, float(balcony_floor) * 3.35 + 1.35)

    _add_visual_box(building, "FrontCornice", Vector3(0, height - 0.3, front_z - 0.08), Vector3(footprint.x + 0.35, 0.24, 0.28), _mat_concrete)
    _add_visual_box(building, "LeftFacadeTrim", Vector3(-footprint.x * 0.5 + 0.12, height * 0.5, front_z - 0.07), Vector3(0.22, height, 0.2), _mat_concrete)
    _add_visual_box(building, "RightFacadeTrim", Vector3(footprint.x * 0.5 - 0.12, height * 0.5, front_z - 0.07), Vector3(0.22, height, 0.2), _mat_concrete)
    _add_roof_details(building, footprint, height)
    if not shop_name.is_empty():
        _create_storefront(building, footprint, front_z, shop_name)

func _add_window_batch(parent: Node3D, transforms: Array[Transform3D], size: Vector3) -> void:
    if transforms.is_empty():
        return
    _add_multimesh_boxes(parent, "WindowGlass", size, transforms, _mat_glass)

    var horizontal_frames: Array[Transform3D] = []
    var vertical_frames: Array[Transform3D] = []
    for window_transform in transforms:
        var basis: Basis = window_transform.basis
        horizontal_frames.append(Transform3D(basis, window_transform.origin + basis * Vector3(0, size.y * 0.5 + 0.045, 0)))
        horizontal_frames.append(Transform3D(basis, window_transform.origin + basis * Vector3(0, -size.y * 0.5 - 0.045, 0)))
        vertical_frames.append(Transform3D(basis, window_transform.origin + basis * Vector3(size.x * 0.5 + 0.045, 0, 0)))
        vertical_frames.append(Transform3D(basis, window_transform.origin + basis * Vector3(-size.x * 0.5 - 0.045, 0, 0)))
        vertical_frames.append(Transform3D(basis, window_transform.origin + basis * Vector3(0, 0, 0)))
    _add_multimesh_boxes(parent, "WindowHorizontalFrames", Vector3(size.x + 0.16, 0.085, 0.16), horizontal_frames, _mat_metal)
    _add_multimesh_boxes(parent, "WindowVerticalFrames", Vector3(0.085, size.y, 0.16), vertical_frames, _mat_metal)

func _add_multimesh_boxes(parent: Node3D, node_name: String, mesh_size: Vector3, transforms: Array[Transform3D], material: Material) -> void:
    if transforms.is_empty():
        return
    var box_mesh := BoxMesh.new()
    box_mesh.size = mesh_size
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = box_mesh
    multi.instance_count = transforms.size()
    for index in range(transforms.size()):
        multi.set_instance_transform(index, transforms[index])
    var instance := MultiMeshInstance3D.new()
    instance.name = node_name
    instance.multimesh = multi
    instance.material_override = material
    parent.add_child(instance)

func _create_balcony(parent: Node3D, front_z: float, balcony_y: float) -> void:
    var balcony_z := front_z - 0.68
    _add_visual_box(parent, "BalconySlab", Vector3(0, balcony_y - 0.52, balcony_z), Vector3(3.2, 0.16, 1.25), _mat_concrete)
    _add_visual_box(parent, "BalconyRailTop", Vector3(0, balcony_y + 0.05, balcony_z - 0.57), Vector3(3.2, 0.09, 0.09), _mat_metal)
    _add_visual_box(parent, "BalconyRailBottom", Vector3(0, balcony_y - 0.42, balcony_z - 0.57), Vector3(3.2, 0.08, 0.08), _mat_metal)
    for post_index in range(9):
        var post_x := -1.48 + float(post_index) * 0.37
        _add_visual_box(parent, "BalconyRailPost", Vector3(post_x, balcony_y - 0.19, balcony_z - 0.57), Vector3(0.055, 0.46, 0.055), _mat_metal)

func _create_storefront(parent: Node3D, footprint: Vector2, front_z: float, shop_name: String) -> void:
    var glass_material := _material(Color(0.1, 0.19, 0.22), 0.2, 0.25)
    _add_visual_box(parent, "StoreGlassLeft", Vector3(-footprint.x * 0.22, 1.55, front_z - 0.06), Vector3(footprint.x * 0.42, 2.55, 0.1), glass_material)
    _add_visual_box(parent, "StoreGlassRight", Vector3(footprint.x * 0.22, 1.55, front_z - 0.06), Vector3(footprint.x * 0.42, 2.55, 0.1), glass_material)
    _add_visual_box(parent, "StoreDoor", Vector3(0, 1.18, front_z - 0.14), Vector3(0.95, 2.28, 0.14), _mat_metal)
    _add_visual_box(parent, "StoreSign", Vector3(0, 3.08, front_z - 0.1), Vector3(footprint.x * 0.78, 0.72, 0.22), _mat_sign)
    var label := Label3D.new()
    label.text = shop_name
    label.font_size = 38
    label.pixel_size = 0.008
    label.position = Vector3(0, 3.0, front_z - 0.24)
    label.modulate = Color(0.92, 0.88, 0.73)
    label.outline_size = 5
    parent.add_child(label)
    _add_visual_box(parent, "Awning", Vector3(0, 2.48, front_z - 0.4), Vector3(footprint.x * 0.82, 0.12, 0.85), _mat_sign)

func _add_roof_details(parent: Node3D, footprint: Vector2, height: float) -> void:
    var roof_y := height + 0.18
    _add_visual_box(parent, "RoofParapetFront", Vector3(0, roof_y, -footprint.y * 0.5), Vector3(footprint.x, 0.36, 0.35), _mat_concrete)
    _add_visual_box(parent, "RoofParapetRear", Vector3(0, roof_y, footprint.y * 0.5), Vector3(footprint.x, 0.36, 0.35), _mat_concrete)
    _add_visual_box(parent, "RoofParapetLeft", Vector3(-footprint.x * 0.5, roof_y, 0), Vector3(0.35, 0.36, footprint.y), _mat_concrete)
    _add_visual_box(parent, "RoofParapetRight", Vector3(footprint.x * 0.5, roof_y, 0), Vector3(0.35, 0.36, footprint.y), _mat_concrete)
    for unit in range(2):
        var x := -footprint.x * 0.22 + float(unit) * footprint.x * 0.42
        _add_visual_box(parent, "RoofHVAC", Vector3(x, height + 0.75, 0.25), Vector3(2.2, 1.05, 1.65), _mat_metal)
        _add_visual_box(parent, "HVACVent", Vector3(x, height + 1.3, 0.25), Vector3(1.45, 0.08, 1.15), _mat_concrete)

func _make_park() -> void:
    _add_static_box(self, "ParkGround", Vector3(-30, 0.015, 30), Vector3(40.0, 0.12, 40.0), _mat_grass)
    _add_static_box(self, "ParkPathNS", Vector3(-30, 0.09, 30), Vector3(3.2, 0.09, 40.0), _mat_pavers)
    _add_static_box(self, "ParkPathEW", Vector3(-30, 0.1, 30), Vector3(40.0, 0.09, 3.2), _mat_pavers)
    for point in [Vector3(-43, 0.1, 18), Vector3(-17, 0.1, 18), Vector3(-43, 0.1, 42), Vector3(-17, 0.1, 42), Vector3(-39, 0.1, 30), Vector3(-21, 0.1, 30)]:
        _make_tree(point, _rng.randf_range(0.9, 1.25))
    _make_bench(Vector3(-38, 0.2, 25), 0.0)
    _make_bench(Vector3(-22, 0.2, 35), PI)
    for point in [Vector3(-46, 0.15, 30), Vector3(-14, 0.15, 30), Vector3(-30, 0.15, 14), Vector3(-30, 0.15, 46)]:
        _add_visual_box(self, "ParkLampPost", point + Vector3(0, 2.2, 0), Vector3(0.13, 4.4, 0.13), _mat_metal)
        _add_visual_box(self, "ParkLampHead", point + Vector3(0, 4.45, 0), Vector3(0.6, 0.16, 0.35), _mat_warm_emission)

func _make_tree(position: Vector3, scale_factor: float = 1.0) -> void:
    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.22 * scale_factor
    trunk_mesh.bottom_radius = 0.34 * scale_factor
    trunk_mesh.height = 2.5 * scale_factor
    trunk.mesh = trunk_mesh
    trunk.position = position + Vector3(0, 1.25 * scale_factor, 0)
    trunk.material_override = _mat_bark
    add_child(trunk)
    for offset in [Vector3(0, 3.0, 0), Vector3(0.55, 2.85, 0.1), Vector3(-0.48, 2.72, -0.18)]:
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.15 * scale_factor
        crown_mesh.height = 2.0 * scale_factor
        crown.mesh = crown_mesh
        crown.position = position + offset * scale_factor
        crown.material_override = _mat_leaves
        add_child(crown)

func _make_bench(position: Vector3, yaw: float) -> void:
    var bench := Node3D.new()
    bench.position = position
    bench.rotation.y = yaw
    add_child(bench)
    _add_visual_box(bench, "BenchSeat", Vector3(0, 0.58, 0), Vector3(2.2, 0.16, 0.55), _mat_bark)
    _add_visual_box(bench, "BenchBack", Vector3(0, 1.02, 0.24), Vector3(2.2, 0.72, 0.14), _mat_bark)
    for x in [-0.82, 0.82]:
        _add_visual_box(bench, "BenchLeg", Vector3(x, 0.28, 0), Vector3(0.13, 0.56, 0.45), _mat_metal)

func _make_street_furniture() -> void:
    for road in [-60.0, 0.0, 60.0]:
        for distance in range(-105, 106, 35):
            for side in [-1.0, 1.0]:
                _make_street_lamp(Vector3(road + side * 10.1, 0.2, float(distance)))
    _make_traffic_signal(Vector3(8.3, 0.0, -8.3))
    _make_traffic_signal(Vector3(-8.3, 0.0, 8.3))
    _make_bus_stop(Vector3(12.5, 0.2, 23.0))
    _make_public_bin(Vector3(-11.0, 0.2, 12.0))
    _make_public_bin(Vector3(11.0, 0.2, -16.0))

func _make_street_lamp(position: Vector3) -> void:
    var lamp := Node3D.new()
    lamp.position = position
    add_child(lamp)
    var shaft := MeshInstance3D.new()
    var shaft_mesh := CylinderMesh.new()
    shaft_mesh.top_radius = 0.055
    shaft_mesh.bottom_radius = 0.09
    shaft_mesh.height = 5.9
    shaft.mesh = shaft_mesh
    shaft.position.y = 2.95
    shaft.material_override = _mat_metal
    lamp.add_child(shaft)
    _add_visual_box(lamp, "LampArm", Vector3(0.45, 5.65, 0), Vector3(0.95, 0.09, 0.09), _mat_metal)
    _add_visual_box(lamp, "LampHead", Vector3(0.9, 5.55, 0), Vector3(0.65, 0.16, 0.3), _mat_warm_emission)

func _make_traffic_signal(position: Vector3) -> void:
    var signal_root := Node3D.new()
    signal_root.position = position
    add_child(signal_root)
    _add_visual_box(signal_root, "SignalPole", Vector3(0, 2.4, 0), Vector3(0.13, 4.8, 0.13), _mat_metal)
    _add_visual_box(signal_root, "SignalHousing", Vector3(0, 4.35, -0.16), Vector3(0.48, 1.45, 0.42), _mat_metal)
    for index in range(3):
        var light := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.13
        mesh.height = 0.26
        light.mesh = mesh
        light.position = Vector3(0, 4.78 - float(index) * 0.42, -0.39)
        light.material_override = _mat_red_emission if index == 0 else (_mat_warm_emission if index == 1 else _mat_green_emission)
        signal_root.add_child(light)

func _make_bus_stop(position: Vector3) -> void:
    var stop := Node3D.new()
    stop.position = position
    add_child(stop)
    _add_visual_box(stop, "ShelterRoof", Vector3(0, 2.35, 0), Vector3(3.4, 0.16, 1.45), _mat_metal)
    _add_visual_box(stop, "ShelterGlass", Vector3(0, 1.2, 0.55), Vector3(3.25, 2.15, 0.08), _mat_glass)
    _add_visual_box(stop, "StopBench", Vector3(0, 0.62, -0.32), Vector3(2.25, 0.15, 0.45), _mat_bark)
    _add_visual_box(stop, "StopSign", Vector3(-1.72, 1.8, -0.52), Vector3(0.42, 0.78, 0.12), _mat_sign)

func _make_public_bin(position: Vector3) -> void:
    _add_static_box(self, "PublicBin", position + Vector3(0, 0.48, 0), Vector3(0.62, 0.95, 0.58), _mat_metal)
    _add_visual_box(self, "PublicBinLid", position + Vector3(0, 0.98, 0), Vector3(0.7, 0.1, 0.64), _mat_sign)

func _spawn_pedestrians() -> void:
    var routes: Array[PackedVector3Array] = [
        PackedVector3Array([Vector3(-9.4, 0.2, -43), Vector3(-9.4, 0.2, -18), Vector3(-9.4, 0.2, 5), Vector3(-9.4, 0.2, 30), Vector3(-9.4, 0.2, 55)]),
        PackedVector3Array([Vector3(9.4, 0.2, 55), Vector3(9.4, 0.2, 30), Vector3(9.4, 0.2, 5), Vector3(9.4, 0.2, -18), Vector3(9.4, 0.2, -43)]),
        PackedVector3Array([Vector3(-55, 0.2, 9.4), Vector3(-30, 0.2, 9.4), Vector3(-6, 0.2, 9.4), Vector3(18, 0.2, 9.4), Vector3(43, 0.2, 9.4)]),
        PackedVector3Array([Vector3(43, 0.2, -9.4), Vector3(18, 0.2, -9.4), Vector3(-6, 0.2, -9.4), Vector3(-30, 0.2, -9.4), Vector3(-55, 0.2, -9.4)]),
        PackedVector3Array([Vector3(-9.4, 0.2, 62), Vector3(-9.4, 0.2, 82), Vector3(-9.4, 0.2, 100), Vector3(-9.4, 0.2, 82), Vector3(-9.4, 0.2, 62)])
    ]
    var outfits: Array[Color] = [Color(0.25, 0.31, 0.38), Color(0.45, 0.24, 0.17), Color(0.19, 0.34, 0.28), Color(0.43, 0.42, 0.34), Color(0.3, 0.25, 0.42)]
    for index in range(routes.size()):
        var pedestrian := CharacterBody3D.new()
        pedestrian.set_script(PEDESTRIAN_SCRIPT)
        pedestrian.set("waypoints", routes[index])
        pedestrian.set("outfit_color", outfits[index])
        pedestrian.set("walk_speed", _rng.randf_range(1.0, 1.45))
        add_child(pedestrian)

func _spawn_traffic() -> void:
    var route := PackedVector3Array([
        Vector3(0, 0.1, -60), Vector3(0, 0.1, 60), Vector3(60, 0.1, 60),
        Vector3(60, 0.1, -60), Vector3(0, 0.1, -60)
    ])
    var starts: Array[Vector3] = [Vector3(0, 0.1, -43), Vector3(60, 0.1, 43), Vector3(60, 0.1, -35)]
    var colors: Array[Color] = [Color(0.55, 0.19, 0.13), Color(0.64, 0.66, 0.65), Color(0.12, 0.27, 0.43)]
    for index in range(starts.size()):
        var traffic_car := CAR_SCENE.instantiate() as CharacterBody3D
        traffic_car.name = "TrafficVehicle_%02d" % index
        traffic_car.position = starts[index]
        traffic_car.set("paint_color", colors[index])
        traffic_car.call("set_ai_route", route, (index + 1) % route.size(), 8.5 + float(index) * 1.2)
        add_child(traffic_car)

func _add_static_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = position
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = material
    body.add_child(visual)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    parent.add_child(body)
    return body

func _add_visual_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    visual.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.position = position
    visual.material_override = material
    parent.add_child(visual)
    return visual
