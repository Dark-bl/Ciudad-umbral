extends Control

var player: Node3D
var target_position := Vector3.ZERO
var camera_yaw := 0.0
var map_radius := 115.0
var _redraw_clock := 0.0

func _process(delta: float) -> void:
    _redraw_clock += delta
    if _redraw_clock < 0.10:
        return
    _redraw_clock = 0.0
    if player != null:
        var active_actor: Node3D = player
        var vehicle_value = player.get("current_vehicle")
        if vehicle_value != null and is_instance_valid(vehicle_value):
            active_actor = vehicle_value as Node3D
        camera_yaw = active_actor.rotation.y
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    var radius := minf(size.x, size.y) * 0.47
    draw_circle(center + Vector2(0, 2), radius + 3.0, Color(0, 0, 0, 0.28))
    draw_circle(center, radius, Color(0.035, 0.065, 0.075, 0.88))
    draw_arc(center, radius, 0, TAU, 64, Color(0.65, 0.76, 0.76, 0.48), 2.0, true)
    for offset in [-0.55, 0.0, 0.55]:
        var horizontal_start := Vector2(-radius * 0.83, offset * radius).rotated(camera_yaw)
        var horizontal_end := Vector2(radius * 0.83, offset * radius).rotated(camera_yaw)
        var vertical_start := Vector2(offset * radius, -radius * 0.83).rotated(camera_yaw)
        var vertical_end := Vector2(offset * radius, radius * 0.83).rotated(camera_yaw)
        draw_line(center + horizontal_start, center + horizontal_end, Color(0.42, 0.52, 0.53, 0.4), 4.0)
        draw_line(center + vertical_start, center + vertical_end, Color(0.42, 0.52, 0.53, 0.4), 4.0)
    if player != null and target_position != Vector3.ZERO:
        var active_actor: Node3D = player
        var vehicle_value = player.get("current_vehicle")
        if vehicle_value != null and is_instance_valid(vehicle_value):
            active_actor = vehicle_value as Node3D
        var relative := target_position - active_actor.global_position
        var target := Vector2(relative.x, relative.z).rotated(camera_yaw) / map_radius * radius * 1.35
        if target.length() > radius - 12.0:
            target = target.normalized() * (radius - 12.0)
        draw_circle(center + target, 5.0, Color(0.12, 0.9, 0.78, 0.95))
        draw_arc(center + target, 8.0, 0, TAU, 24, Color(0.12, 0.9, 0.78, 0.75), 1.5, true)
    var player_triangle := PackedVector2Array([
        center + Vector2(0, -10),
        center + Vector2(-7, 8),
        center + Vector2(7, 8)
    ])
    draw_colored_polygon(player_triangle, Color(0.96, 0.88, 0.68, 1.0))
