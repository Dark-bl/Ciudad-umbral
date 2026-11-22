# Informe de revisión técnica — Ciudad Umbral

## Revisión estática realizada

- Se verificó que los 22 recursos `res://` referenciados en escenas, scripts y configuración existen.
- Se verificó la consistencia de `load_steps` de `main.tscn`, `player.tscn` y `car.tscn`.
- Se verificaron las rutas `$NodePath` utilizadas por los controladores del jugador y del vehículo contra los nodos de sus escenas.
- Se comprobaron 18 texturas PNG y 3 efectos WAV.
- Se comprobó que el workflow de GitHub Actions es YAML válido.
- Se comprobó el nombre del preset Android, la ruta de salida del APK, la orientación horizontal y la propiedad ETC2/ASTC.

## Cambios de esta versión

- Ciudad 3D procedural con texturas PBR (albedo, normales y rugosidad), fachadas, ventanas, escaparates, azoteas, parque y mobiliario urbano.
- Ciclo de iluminación día/noche.
- Personaje humanoide con detalles de cara y ropa, cámara de tercera persona y controles táctiles.
- Vehículo conducible, tráfico de ruta y sonido de motor.
- Peatones con rutas y animación procedural.
- Tres objetivos con recompensas y guardado local.
- HUD, minimapa, menú, pausa y avisos de objetivos completados.
- Configuración y workflow Android para Godot 4.2.2.

## Pruebas que todavía faltan

Este entorno no dispone del ejecutable de Godot 4.2.2, por lo que no se ha realizado una importación real del motor, una ejecución de escena, una exportación del APK ni una prueba en dispositivo Android. La verificación estática no sustituye esas pruebas. El workflow de GitHub Actions incluye importación, ejecución headless y exportación para realizarlas en GitHub.

## Alcance visual

La dirección es 3D realista estilizada con materiales PBR y geometría procedural. No es un juego AAA fotorrealista: para alcanzar ese nivel harían falta modelos humanos y de vehículos de alta calidad, animaciones esqueléticas, interiores, materiales de autor, iluminación avanzada y pruebas de rendimiento en teléfonos reales.
