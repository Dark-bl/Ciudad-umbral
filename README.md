# Ciudad Umbral

**Ciudad Umbral 0.3.0** es un prototipo de aventura urbana 3D en tercera persona, diseñado para teléfonos Android y desarrollado con Godot 4.2.2 y GDScript.

La dirección visual es 3D realista estilizada. La portada incorpora el crédito “Hecho con Nia”: materiales PBR, superficies texturizadas, fachadas con ventanas, aceras, señalización, iluminación y mobiliario urbano. No utiliza pixel art ni estética de 8 bits. El proyecto es original y no reutiliza personajes, mapas ni recursos propietarios de otros videojuegos.

> Estado honesto: esta entrega amplía sustancialmente el prototipo, pero sigue siendo una versión de desarrollo. El ZIP aún debe validarse con Godot 4.2.2 y compilarse en GitHub Actions antes de poder afirmar que el APK funciona en un dispositivo real.

## Contenido de esta versión

- Ciudad procedural ampliada con cuadrícula de calles, avenidas, intersecciones, aceras y pasos peatonales.
- Texturas procedurales para asfalto, concreto, adoquín, césped, estuco y ladrillo, con mapas de normales y rugosidad.
- Edificios con fachadas orientadas hacia las calles, ventanas instanciadas con marcos, escaparates, letreros, balcones y equipos en azoteas.
- Parque con caminos, árboles, bancas y luminarias.
- Farolas, semáforos, parada de autobús y papeleras.
- Personaje humanoide compuesto por varias piezas 3D, rostro, detalles de vestuario y animación procedural de brazos y piernas.
- Cámara de tercera persona con giro táctil y colisión de brazo, también orientable durante la conducción.
- Automóvil detallado con parabrisas, ventanillas, luces, parrilla, defensas, manijas y rines metálicos.
- Conducción arcade con aceleración, frenado, reversa y dirección táctil.
- Vehículos de tráfico siguiendo rutas sencillas.
- Peatones con rutas predefinidas y animación de caminata.
- Tres objetivos iniciales con marcador tridimensional, recompensas y progreso guardado.
- Min mapa orientativo, HUD, menú principal y menú de pausa.
- Ciclo de día y noche con cambios de iluminación, color del cielo y niebla.
- Audio ambiental urbano, sonido de motor y pasos; los sonidos son originales y sintetizados para este prototipo.
- Perfil de renderizado GL Compatibility y resolución base de 1280 × 720 para ampliar la compatibilidad móvil.
- Workflow de GitHub Actions para instalar Godot 4.2.2, export templates, Java 17 y Android SDK.

## Requisitos de desarrollo

- Godot Engine **4.2.2 estable**.
- Plantillas de exportación de Godot **4.2.2**.
- Para Android: OpenJDK 17, Android SDK Platform 33, Build Tools 33.0.2, Platform Tools, Command-line Tools, CMake 3.10.2.4988404 y NDK 23.2.8568313.

## Ejecutar en Godot

1. Descomprime el proyecto completo.
2. Abre Godot 4.2.2.
3. Selecciona **Importar** y elige `project.godot`.
4. Espera a que Godot importe las texturas procedurales.
5. Ejecuta `main.tscn` con F6 o el proyecto con F5.

## Controles de escritorio

- `WASD` o flechas: caminar / controlar dirección y aceleración.
- `Shift`: correr / impulso del vehículo.
- `Espacio`: saltar.
- `E`: entrar o salir del automóvil.
- Botón derecho + ratón: capturar y girar la cámara.

## Controles táctiles

- Joystick izquierdo: desplazamiento y dirección / aceleración.
- Arrastrar en la zona derecha: orientar la cámara a pie.
- `SALTO`: saltar.
- `CORRER` o `IMPULSO`: correr a pie o dar impulso al vehículo.
- `ENTRAR` o `BAJAR`: entrar al automóvil cercano o salir de él.

## Exportación Android desde GitHub

El flujo se encuentra en `.github/workflows/build-android.yml`.

1. Sube el contenido del proyecto a la rama `main` o `master`.
2. Abre la pestaña **Actions**.
3. Ejecuta **Ciudad Umbral - APK Android (Godot 4.2.2)** o espera al push.
4. Revisa el resultado de los pasos de importación, prueba headless y exportación.
5. Si termina correctamente, descarga el artefacto `Ciudad-Umbral-Android-APK-Debug`.

El workflow crea un keystore de depuración temporal para cada ejecución. Esto es adecuado para probar el APK; no es una firma de publicación para Google Play. Para una versión de lanzamiento deberá configurarse un keystore privado persistente mediante GitHub Secrets.

## Estructura principal

```text
Ciudad-Umbral/
├── .github/workflows/build-android.yml
├── assets/audio/
├── assets/textures/
├── audio_manager.gd
├── car.tscn
├── export_presets.cfg
├── main.gd
├── main.tscn
├── minimap.gd
├── mobile_controls.gd
├── mission_system.gd
├── pedestrian_controller.gd
├── player.tscn
├── player_controller.gd
├── project.godot
├── vehicle_controller.gd
└── world_builder.gd
```

## Alcance y limitaciones actuales

- El escenario se construye mediante geometría procedural; no contiene edificios interiores explorables.
- Los peatones usan rutas básicas; todavía no tienen navegación dinámica avanzada ni evasión compleja.
- El tráfico sigue rutas predefinidas y no implementa semáforos con reglas completas ni evitación sofisticada.
- El vehículo utiliza conducción arcade basada en `CharacterBody3D`, no simulación completa de suspensión y ruedas físicas.
- El protagonista utiliza animación procedural sencilla; todavía no tiene esqueleto humano, captura de movimiento ni animaciones externas.
- Los objetivos iniciales son hitos de exploración, no una campaña narrativa completa.
- El rendimiento no está medido en teléfonos reales. La cantidad de elementos puede requerir ajustes según el dispositivo.
- No se incluyen APK ni capturas de ejecución en este paquete porque no se ha podido ejecutar Godot en el entorno de preparación.

## Validación pendiente

| Comprobación | Estado |
|---|---|
| Estructura del ZIP y recursos | Preparada |
| Orientación horizontal | Configurada |
| Compresión ETC2/ASTC | Configurada |
| Movimiento, cámara y detalles del personaje | Implementación actualizada; falta ejecutar |
| Entrada/salida del automóvil y cámara de conducción | Implementación actualizada; falta ejecutar |
| Acelerador hacia delante | Corregido en código; falta ejecutar |
| Importación en Godot 4.2.2 | Pendiente de GitHub Actions |
| Ejecución headless | Pendiente de GitHub Actions |
| Exportación APK Android | Pendiente de GitHub Actions |
| Prueba en teléfono físico | Pendiente |

## Recursos

Las texturas dentro de `assets/textures/` fueron generadas proceduralmente para este proyecto. No dependen de bancos comerciales ni de recursos extraídos de otros videojuegos.
