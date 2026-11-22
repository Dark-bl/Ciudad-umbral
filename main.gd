extends Node3D

const WORLD_SCRIPT = preload("res://world_builder.gd")
const PLAYER_SCENE = preload("res://player.tscn")
const CAR_SCENE = preload("res://car.tscn")
const CONTROLS_SCRIPT = preload("res://mobile_controls.gd")
const MISSION_SCRIPT = preload("res://mission_system.gd")
const MINIMAP_SCRIPT = preload("res://minimap.gd")
const AUDIO_SCRIPT = preload("res://audio_manager.gd")

var player: CharacterBody3D
var controls: Control
var mission_label: Label
var money_label: Label
var hint_label: Label
var minimap: Control
var mission_system: Node3D
var pause_button: Button
var main_menu: Control
var pause_menu: Control
var toast_label: Label
var _hint_clock := 0.0
var _toast_clock := 0.0

func _ready() -> void:
    _build_world()
    _build_audio()
    _spawn_player_and_vehicle()
    _build_interface()
    _connect_gameplay()

func _build_world() -> void:
    var world := Node3D.new()
    world.name = "World"
    world.set_script(WORLD_SCRIPT)
    add_child(world)

func _build_audio() -> void:
    var audio_manager := Node.new()
    audio_manager.name = "AudioManager"
    audio_manager.set_script(AUDIO_SCRIPT)
    add_child(audio_manager)

func _spawn_player_and_vehicle() -> void:
    var car := CAR_SCENE.instantiate() as CharacterBody3D
    car.name = "PlayerVehicle"
    car.position = Vector3(3.4, 0.065, 13.0)
    car.set("paint_color", Color(0.08, 0.28, 0.42))
    add_child(car)

    player = PLAYER_SCENE.instantiate() as CharacterBody3D
    player.name = "Player"
    player.position = Vector3(0.0, 0.065, 13.0)
    add_child(player)

func _build_interface() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "GameInterface"
    canvas.layer = 5
    add_child(canvas)

    controls = Control.new()
    controls.name = "MobileControls"
    controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
    controls.set_script(CONTROLS_SCRIPT)
    canvas.add_child(controls)

    var mission_panel := PanelContainer.new()
    mission_panel.position = Vector2(22, 22)
    mission_panel.custom_minimum_size = Vector2(455, 118)
    mission_panel.size = Vector2(455, 118)
    mission_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.058, 0.88)))
    canvas.add_child(mission_panel)
    var mission_box := VBoxContainer.new()
    mission_box.add_theme_constant_override("separation", 5)
    mission_panel.add_child(mission_box)

    var title := Label.new()
    title.text = "CIUDAD UMBRAL  /  DISTRITO 01"
    title.add_theme_font_size_override("font_size", 17)
    title.add_theme_color_override("font_color", Color(0.72, 0.88, 0.84))
    mission_box.add_child(title)

    mission_label = Label.new()
    mission_label.text = "OBJETIVO · Llega a Plaza Umbral."
    mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    mission_label.custom_minimum_size = Vector2(410, 42)
    mission_label.add_theme_font_size_override("font_size", 16)
    mission_label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.88))
    mission_box.add_child(mission_label)

    var money_panel := PanelContainer.new()
    money_panel.anchor_left = 1.0
    money_panel.anchor_right = 1.0
    money_panel.offset_left = -220.0
    money_panel.offset_right = -22.0
    money_panel.offset_top = 22.0
    money_panel.offset_bottom = 82.0
    money_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.058, 0.88)))
    canvas.add_child(money_panel)
    money_label = Label.new()
    money_label.text = "$ 000350"
    money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    money_label.add_theme_font_size_override("font_size", 22)
    money_label.add_theme_color_override("font_color", Color(0.87, 0.78, 0.46))
    money_panel.add_child(money_label)

    hint_label = Label.new()
    hint_label.position = Vector2(24, 150)
    hint_label.size = Vector2(700, 30)
    hint_label.text = "WASD / JOYSTICK · E / ENTRAR · SHIFT / CORRER"
    hint_label.add_theme_font_size_override("font_size", 12)
    hint_label.add_theme_color_override("font_color", Color(0.83, 0.88, 0.88, 0.78))
    canvas.add_child(hint_label)

    toast_label = Label.new()
    toast_label.name = "ObjectiveToast"
    toast_label.anchor_left = 0.5
    toast_label.anchor_right = 0.5
    toast_label.offset_left = -270.0
    toast_label.offset_right = 270.0
    toast_label.offset_top = 116.0
    toast_label.offset_bottom = 154.0
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    toast_label.add_theme_font_size_override("font_size", 18)
    toast_label.add_theme_color_override("font_color", Color(0.94, 0.86, 0.59))
    toast_label.add_theme_shadow_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
    toast_label.add_theme_constant_override("shadow_offset_x", 2)
    toast_label.add_theme_constant_override("shadow_offset_y", 2)
    toast_label.visible = false
    canvas.add_child(toast_label)

    minimap = Control.new()
    minimap.name = "MiniMap"
    minimap.set_script(MINIMAP_SCRIPT)
    minimap.anchor_left = 1.0
    minimap.anchor_right = 1.0
    minimap.anchor_top = 1.0
    minimap.anchor_bottom = 1.0
    minimap.offset_left = -174.0
    minimap.offset_right = -16.0
    minimap.offset_top = -174.0
    minimap.offset_bottom = -16.0
    canvas.add_child(minimap)
    minimap.set("player", player)

    mission_system = Node3D.new()
    mission_system.name = "MissionSystem"
    mission_system.set_script(MISSION_SCRIPT)
    add_child(mission_system)
    _build_menus(canvas)

func _connect_gameplay() -> void:
    controls.connect("movement_changed", Callable(player, "set_mobile_movement"))
    controls.connect("sprint_changed", Callable(player, "set_mobile_sprint"))
    controls.connect("jump_pressed", Callable(player, "request_jump"))
    controls.connect("brake_changed", Callable(player, "set_mobile_brake"))
    controls.connect("camera_dragged", Callable(player, "rotate_camera"))
    controls.connect("interact_pressed", Callable(player, "request_interact"))
    player.connect("vehicle_state_changed", Callable(controls, "set_vehicle_mode"))
    mission_system.call("configure", player, mission_label, money_label, minimap)
    mission_system.connect("objective_completed", Callable(self, "_on_objective_completed"))
    get_tree().paused = true

func _build_menus(canvas: CanvasLayer) -> void:
    pause_button = Button.new()
    pause_button.name = "PauseButton"
    pause_button.text = "Ⅱ"
    pause_button.anchor_left = 1.0
    pause_button.anchor_right = 1.0
    pause_button.offset_left = -320.0
    pause_button.offset_right = -236.0
    pause_button.offset_top = 22.0
    pause_button.offset_bottom = 82.0
    pause_button.add_theme_font_size_override("font_size", 26)
    pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
    pause_button.pressed.connect(_pause_game)
    canvas.add_child(pause_button)

    main_menu = _create_menu_overlay(canvas, "MainMenu", "CIUDAD UMBRAL", "DISTRITO 01  ·  RECORRIDO LIBRE", [
        ["INICIAR RECORRIDO", Callable(self, "_start_game")],
        ["SALIR DEL JUEGO", Callable(self, "_quit_game")]
    ])

    pause_menu = _create_menu_overlay(canvas, "PauseMenu", "PAUSA", "TU RECORRIDO ESTÁ EN PAUSA", [
        ["CONTINUAR", Callable(self, "_resume_game")],
        ["REINICIAR RECORRIDO", Callable(self, "_restart_game")],
        ["SALIR DEL JUEGO", Callable(self, "_quit_game")]
    ])
    pause_menu.visible = false
    pause_button.visible = false

func _create_menu_overlay(canvas: CanvasLayer, node_name: String, heading: String, subtitle: String, actions: Array) -> Control:
    var overlay := Control.new()
    overlay.name = node_name
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    canvas.add_child(overlay)

    var shade := ColorRect.new()
    shade.color = Color(0.012, 0.025, 0.035, 0.88)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.add_child(shade)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(500, 390)
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.055, 0.068, 0.97)))
    center.add_child(panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 15)
    panel.add_child(content)

    var title := Label.new()
    title.text = heading
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color(0.82, 0.91, 0.86))
    content.add_child(title)

    var detail := Label.new()
    detail.text = subtitle
    detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    detail.add_theme_font_size_override("font_size", 13)
    detail.add_theme_color_override("font_color", Color(0.62, 0.75, 0.76))
    content.add_child(detail)

    var separator := HSeparator.new()
    content.add_child(separator)

    for action in actions:
        var button := Button.new()
        button.text = str(action[0])
        button.custom_minimum_size = Vector2(0, 58)
        button.add_theme_font_size_override("font_size", 18)
        var callback: Callable = action[1]
        button.pressed.connect(callback)
        content.add_child(button)

    var footer := Label.new()
    footer.text = "HECHO CON NIA  ·  CIUDAD UMBRAL  ·  GODOT 4.2.2"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 11)
    footer.add_theme_color_override("font_color", Color(0.54, 0.65, 0.67))
    content.add_child(footer)
    return overlay

func _start_game() -> void:
    main_menu.visible = false
    pause_button.visible = true
    get_tree().paused = false

func _pause_game() -> void:
    if pause_menu == null:
        return
    pause_menu.visible = true
    pause_button.visible = false
    get_tree().paused = true

func _resume_game() -> void:
    pause_menu.visible = false
    pause_button.visible = true
    get_tree().paused = false

func _restart_game() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()

func _quit_game() -> void:
    get_tree().paused = false
    get_tree().quit()

func _on_objective_completed(title: String, reward: int) -> void:
    if toast_label == null:
        return
    toast_label.text = "OBJETIVO COMPLETADO  ·  %s  ·  +$%d" % [title, reward]
    toast_label.visible = true
    _toast_clock = 4.0

func _panel_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = Color(0.45, 0.65, 0.64, 0.28)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.content_margin_left = 14.0
    style.content_margin_right = 14.0
    style.content_margin_top = 10.0
    style.content_margin_bottom = 10.0
    return style

func _process(delta: float) -> void:
    if _toast_clock > 0.0:
        _toast_clock = maxf(0.0, _toast_clock - delta)
        if _toast_clock == 0.0 and toast_label != null:
            toast_label.visible = false
    _hint_clock += delta
    if _hint_clock < 0.18 or player == null or hint_label == null:
        return
    _hint_clock = 0.0
    if player.get("current_vehicle") != null:
        hint_label.text = "CONDUCCIÓN · JOYSTICK PARA GIRAR Y ACELERAR · BOTÓN AZUL PARA FRENAR"
    else:
        hint_label.text = "EXPLORA LA CIUDAD · ACÉRCATE AL VEHÍCULO Y PULSA E PARA CONDUCIR"
