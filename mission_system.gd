extends Node3D

signal objective_completed(title: String, reward: int)

var player: Node3D
var mission_label: Label
var money_label: Label
var minimap: Control
var mission_index := 0
var money := 350
var objective_marker: Node3D
var marker_ring: MeshInstance3D
var objective_position := Vector3.ZERO
var _marker_clock := 0.0
var _objectives: Array[Dictionary] = [
    {"title": "PLAZA UMBRAL", "description": "Conoce el centro: llega a Plaza Umbral.", "position": Vector3(0, 0.15, -48), "reward": 250},
    {"title": "DISTRITO COMERCIAL", "description": "Dirígete al cruce del distrito comercial.", "position": Vector3(60, 0.15, 60), "reward": 400},
    {"title": "PARQUE DEL ESTE", "description": "Completa la entrega en el parque del distrito.", "position": Vector3(-30, 0.15, 30), "reward": 550}
]

func _ready() -> void:
    _load_progress()
    _create_objective_marker()

func configure(player_ref: Node3D, mission_label_ref: Label, money_label_ref: Label, minimap_ref: Control) -> void:
    player = player_ref
    mission_label = mission_label_ref
    money_label = money_label_ref
    minimap = minimap_ref
    _update_money_label()
    _set_current_objective()

func _process(delta: float) -> void:
    if objective_marker == null:
        return
    _marker_clock += delta
    var ring_scale := 1.0 + sin(_marker_clock * 2.4) * 0.055
    marker_ring.scale = Vector3.ONE * ring_scale
    var active_actor: Node3D = player
    if player != null:
        var vehicle_value = player.get("current_vehicle")
        if vehicle_value != null and is_instance_valid(vehicle_value):
            active_actor = vehicle_value as Node3D
    if active_actor != null and active_actor.global_position.distance_to(objective_position) < 4.8:
        _complete_objective()

func _create_objective_marker() -> void:
    objective_marker = Node3D.new()
    objective_marker.name = "MissionObjectiveMarker"
    add_child(objective_marker)

    var marker_material := StandardMaterial3D.new()
    marker_material.albedo_color = Color(0.16, 0.83, 0.78)
    marker_material.emission_enabled = true
    marker_material.emission = Color(0.08, 0.7, 0.68)
    marker_material.emission_energy_multiplier = 1.4
    marker_material.roughness = 0.35

    marker_ring = MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 1.7
    ring_mesh.outer_radius = 2.05
    ring_mesh.ring_segments = 12
    ring_mesh.rings = 40
    marker_ring.mesh = ring_mesh
    marker_ring.position.y = -0.07
    marker_ring.material_override = marker_material
    objective_marker.add_child(marker_ring)

    var beacon := MeshInstance3D.new()
    var beacon_mesh := CylinderMesh.new()
    beacon_mesh.top_radius = 0.08
    beacon_mesh.bottom_radius = 0.38
    beacon_mesh.height = 4.6
    beacon.mesh = beacon_mesh
    beacon.position.y = 2.45
    var beacon_material := StandardMaterial3D.new()
    beacon_material.albedo_color = Color(0.12, 0.8, 0.74, 0.16)
    beacon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    beacon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    beacon_material.emission_enabled = true
    beacon_material.emission = Color(0.08, 0.65, 0.62)
    beacon_material.emission_energy_multiplier = 0.8
    beacon.material_override = beacon_material
    objective_marker.add_child(beacon)

    var label := Label3D.new()
    label.text = "OBJETIVO"
    label.font_size = 42
    label.pixel_size = 0.008
    label.position.y = 5.0
    label.modulate = Color(0.83, 1.0, 0.96)
    label.outline_size = 7
    objective_marker.add_child(label)

func _set_current_objective() -> void:
    if mission_index >= _objectives.size():
        if mission_label != null:
            mission_label.text = "RUTA COMPLETADA · Explora la ciudad libremente."
        objective_marker.visible = false
        if minimap != null:
            minimap.set("target_position", Vector3.ZERO)
        return
    var objective: Dictionary = _objectives[mission_index]
    objective_position = objective["position"]
    objective_marker.global_position = objective_position
    objective_marker.visible = true
    if mission_label != null:
        mission_label.text = "OBJETIVO %d/3 · %s" % [mission_index + 1, objective["description"]]
    if minimap != null:
        minimap.set("target_position", objective_position)

func _complete_objective() -> void:
    if mission_index >= _objectives.size():
        return
    var objective: Dictionary = _objectives[mission_index]
    var title: String = objective["title"]
    var reward: int = objective["reward"]
    money += reward
    mission_index += 1
    _update_money_label()
    _save_progress()
    objective_completed.emit(title, reward)
    _set_current_objective()

func _update_money_label() -> void:
    if money_label != null:
        money_label.text = "$ %06d" % money

func _load_progress() -> void:
    var config := ConfigFile.new()
    var error := config.load("user://ciudad_umbral_save.cfg")
    if error != OK:
        return
    mission_index = clampi(int(config.get_value("profile", "mission_index", 0)), 0, _objectives.size())
    money = maxi(0, int(config.get_value("profile", "money", 350)))

func _save_progress() -> void:
    var config := ConfigFile.new()
    config.set_value("profile", "mission_index", mission_index)
    config.set_value("profile", "money", money)
    config.set_value("profile", "updated_at", Time.get_datetime_string_from_system())
    var error := config.save("user://ciudad_umbral_save.cfg")
    if error != OK:
        push_warning("No se pudo guardar el progreso: %s" % error_string(error))
