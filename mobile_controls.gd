extends Control

signal movement_changed(value: Vector2)
signal sprint_changed(value: bool)
signal jump_pressed
signal brake_changed(value: bool)
signal interact_pressed
signal camera_dragged(delta_pixels: Vector2)

const JOY_RADIUS := 76.0
const BUTTON_RADIUS := 41.0

var joystick_vector := Vector2.ZERO
var joystick_touch := -1
var camera_touch := -1
var sprint_touch := -1
var brake_touch := -1
var jump_flash := 0.0
var vehicle_mode := false

func _ready() -> void:
    set_process(true)
    set_process_input(true)

func set_vehicle_mode(value: bool) -> void:
    vehicle_mode = value
    queue_redraw()

func _process(delta: float) -> void:
    if jump_flash > 0.0:
        jump_flash = maxf(0.0, jump_flash - delta)
        queue_redraw()

func _draw() -> void:
    var viewport_size := get_viewport_rect().size
    var joystick_center := Vector2(120, viewport_size.y - 126)
    var jump_center := Vector2(viewport_size.x - 91, viewport_size.y - 112)
    var sprint_center := Vector2(viewport_size.x - 194, viewport_size.y - 76)
    var interact_center := Vector2(viewport_size.x - 91, viewport_size.y - 211)

    draw_circle(joystick_center, JOY_RADIUS + 8.0, Color(0.015, 0.025, 0.04, 0.22))
    draw_circle(joystick_center, JOY_RADIUS, Color(0.035, 0.055, 0.075, 0.46))
    draw_arc(joystick_center, JOY_RADIUS, 0.0, TAU, 56, Color(0.82, 0.88, 0.92, 0.58), 2.2, true)
    draw_circle(joystick_center + joystick_vector * 46.0, 29.0, Color(0.78, 0.85, 0.9, 0.76))
    draw_arc(joystick_center + joystick_vector * 46.0, 29.0, 0.0, TAU, 40, Color(1, 1, 1, 0.65), 1.5, true)

    _draw_button(jump_center, "FRENO" if vehicle_mode else "SALTO", Color(0.12, 0.38, 0.54, 0.76 if jump_flash <= 0.0 else 0.98))
    _draw_button(sprint_center, "IMPULSO" if vehicle_mode else "CORRER", Color(0.48, 0.28, 0.12, 0.75 if sprint_touch == -1 else 0.98))
    _draw_button(interact_center, "BAJAR" if vehicle_mode else "ENTRAR", Color(0.12, 0.38, 0.27, 0.78))
    draw_string(ThemeDB.fallback_font, Vector2(viewport_size.x * 0.5 - 84, viewport_size.y - 24), "DESLIZA PARA MIRAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.54))

func _draw_button(center: Vector2, label: String, color: Color) -> void:
    draw_circle(center + Vector2(0, 3), BUTTON_RADIUS + 4.0, Color(0, 0, 0, 0.24))
    draw_circle(center, BUTTON_RADIUS, color)
    draw_arc(center, BUTTON_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.74), 2.0, true)
    var width := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
    draw_string(ThemeDB.fallback_font, center + Vector2(-width * 0.5, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

func _input(event: InputEvent) -> void:
    var viewport_size := get_viewport_rect().size
    var joystick_center := Vector2(120, viewport_size.y - 126)
    var jump_center := Vector2(viewport_size.x - 91, viewport_size.y - 112)
    var sprint_center := Vector2(viewport_size.x - 194, viewport_size.y - 76)
    var interact_center := Vector2(viewport_size.x - 91, viewport_size.y - 211)

    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.distance_to(joystick_center) < JOY_RADIUS * 1.8 and joystick_touch == -1:
                joystick_touch = event.index
                _update_joystick(event.position, joystick_center)
            elif event.position.distance_to(jump_center) < BUTTON_RADIUS * 1.45:
                jump_flash = 0.18
                queue_redraw()
                if vehicle_mode:
                    brake_touch = event.index
                    brake_changed.emit(true)
                else:
                    jump_pressed.emit()
            elif event.position.distance_to(sprint_center) < BUTTON_RADIUS * 1.45:
                sprint_touch = event.index
                sprint_changed.emit(true)
            elif event.position.distance_to(interact_center) < BUTTON_RADIUS * 1.45:
                interact_pressed.emit()
            elif event.position.x > viewport_size.x * 0.42:
                var touching_top_right_hud := event.position.y < 104.0 and event.position.x > viewport_size.x - 350.0
                if not touching_top_right_hud:
                    camera_touch = event.index
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                joystick_vector = Vector2.ZERO
                movement_changed.emit(Vector2.ZERO)
                queue_redraw()
            if event.index == sprint_touch:
                sprint_touch = -1
                sprint_changed.emit(false)
                queue_redraw()
            if event.index == brake_touch:
                brake_touch = -1
                brake_changed.emit(false)
                queue_redraw()
            if event.index == camera_touch:
                camera_touch = -1
    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            _update_joystick(event.position, joystick_center)
        elif event.index == camera_touch:
            camera_dragged.emit(event.relative)

func _update_joystick(position: Vector2, center: Vector2) -> void:
    joystick_vector = ((position - center) / JOY_RADIUS).limit_length(1.0)
    movement_changed.emit(Vector2(joystick_vector.x, -joystick_vector.y))
    queue_redraw()
