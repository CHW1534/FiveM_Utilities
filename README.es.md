<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="banner_white.png">
  <source media="(prefers-color-scheme: light)" srcset="banner.png">
  <img alt="FiveM Utilities" src="banner.png" width="480">
</picture>

# FiveM Utilities Suite

![FiveM](https://img.shields.io/badge/FiveM-CFX-orange.svg?style=for-the-badge&logo=fivem)
![Lua](https://img.shields.io/badge/Lua-5.4-blue.svg?style=for-the-badge&logo=lua)
![Platform](https://img.shields.io/badge/Platform-Standalone%20%7C%20ESX-brightgreen.svg?style=for-the-badge)
![Author](https://img.shields.io/badge/Autor-CHW-red.svg?style=for-the-badge&logo=github)
![GitHub repo](https://img.shields.io/badge/Repositorio-FiveM__Utilities-informational.svg?style=for-the-badge&logo=github)

<br/>

[**🇺🇸 Read in English**](README.md) &nbsp;•&nbsp; [**🇪🇸 Versión en Español**](README.es.md)

---

</div>

Colección de utilidades ligeras, de alto rendimiento y listas para usar en servidores de **FiveM** (compatibles con Standalone, ESX y QBCore), desarrolladas y mantenidas por **[CHW](https://github.com/CHW1534)**.

---

## 📦 Recursos Incluidos

| Recurso | Versión | Tipo | Descripción |
| :--- | :---: | :---: | :--- |
| **[BodyGuard](#1-bodyguard)** | `2.0.0` | Standalone | Contratación de guardaespaldas con IA, escoltas armadas, vehículos y auto-limpieza anti-lag. |
| **[carplay](#2-carplay)** | `1.0.0` | Standalone | Sistema NUI estilo Apple CarPlay con YouTube sincronizado, audio 3D y sintonizador de radio. |
| **[esx_sticky_wheels](#3-esx_sticky_wheels)** | `6.0.0` | Standalone | Mantiene las ruedas giradas al estacionar y bajarse del vehículo con OneSync State Bags. |
| **[respawn_menu](#4-respawn_menu)** | `1.1.0` | Standalone / ESX | Menú de reaparición táctico con mapa satelital interactivo, zonas de exclusión, I-Frames y panel admin. |
| **[team_selector](#5-team_selector)** | `1.0.0` | Standalone / ESX | Selección de equipos con NPC interactivo en lobby, teletransporte, blacklist de ítems y equipamiento. |

---

## 1. 🛡️ BodyGuard (`v2.0.0`)
### Sistema Avanzado de Guardaespaldas con IA y Vehículos de Escolta

* **¿Para qué sirve?**  
  Permite a los jugadores contratar NPCs con IA táctica que los protegen en todo momento, siguiéndolos a pie o en vehículos y combatiendo contra cualquier atacante. También permite solicitar vehículos de escolta blindados y todoterreno con conductores armados.

* **Características Principales:**
  * **4 Tiers de Guardaespaldas Preconfigurados:**
    * **Novato (Tier 1):** Pistola, 400 HP, respuesta defensiva básica.
    * **Veterano (Tier 2):** Subfusil SMG + Chaleco (50 armor), 650 HP, combate táctico.
    * **Élite (Tier 3):** Rifle de Asalto Carabina + Chaleco Completo (100 armor), 1000 HP, gran puntería.
    * **Leyenda (Tier 4):** Ametralladora Pesada MG + Blindaje Pesado (200 armor), 2000 HP, resistencia extrema (tanque).
  * **Guardaespaldas Personalizados:** 3 slots preconfigurados listos para peds personalizados.
  * **Vehículos de Escolta Blindados:** Solicita vehículos de apoyo (Schafter, Dubsta, Baller, Insurgent, Can-Am Maverick X RS, Polaris RZR) conducidos por agentes armados.
  * **Sistema de Auto-Limpieza Anti-Lag:** Elimina vehículos fuera de uso (+1000m durante 5 minutos) y NPCs rezagados (+120m durante 5 minutos) para proteger el rendimiento del servidor y evitar saturación de entidades.
  * **Panel de Administrador (`/bgadmin`):** Concede o revoca permisos en vivo a través de licencias de FiveM, Discord ID o Steam.
  * **Eliminación de Nivel de Búsqueda:** Opción para retirar estrellas de policía.
  * **Blips en el Minimapa:** Marcadores en el radar con códigos de color para identificar guardaespaldas y vehículos de escolta.

<p align="center">
  <img src="assets/bodyguard_main.png" alt="Menú Principal de BodyGuard" width="31%" />
  <img src="assets/bodyguard_tiers.png" alt="Tiers y Guardaespaldas Custom" width="31%" />
  <img src="assets/bodyguard_escort.png" alt="Vehículos de Escolta Blindados" width="31%" />
</p>
<p align="center">
  <img src="assets/bodyguard_services.png" alt="Servicios Tácticos y Auto-Limpieza" width="46%" />
  <img src="assets/bodyguard_admin.png" alt="Panel de Administración en Vivo" width="46%" />
</p>

* **Controles y Comandos:**
  * `B` (tecla por defecto) o `/bodyguard` - Abrir el menú interactivo.
  * `/dismiss` - Despedir a todos los guardaespaldas y retirar vehículos de escolta.
  * `/bgadmin` - Abrir el panel de administración.

---

## 2. 🎵 carplay (`v1.0.0`)
### Pantalla NUI Estilo Apple CarPlay con YouTube Sincronizado

* **¿Para qué sirve?**  
  Agrega un sistema interactivo multimedia en los vehículos que permite escuchar música o videos de YouTube y sintonizar emisoras de radio de GTA V con sincronización espacial entre jugadores.

* **Características Principales:**
  * **Audio Espacial 3D:** El volumen disminuye de forma realista en función de la distancia al vehículo (curva logarítmica de hasta 45 metros).
  * **Sincronización Pasajeros / Conductor:** Todos los ocupantes del vehículo escuchan exactamente el mismo segundo de la canción gracias al cálculo del diferencial de reloj del servidor (`serverTimeDelta`).
  * **Conducción con Menú Abierto:** Permite acelerar, frenar, doblar y accionar el freno de mano mientras la interfaz está abierta, bloqueando la rueda de selección de armas y la rueda de radio para evitar cambios involuntarios con el ratón.
  * **Integración con la Radio de GTA V:** Muestra el nombre real de cada emisora nativa y silencia la radio del juego automáticamente al reproducir contenido de YouTube, y viceversa.

<p align="center">
  <img src="assets/carplay_player.png" alt="CarPlay Reproductor con Cola de YouTube" width="49%">
  <img src="assets/carplay_idle.png" alt="CarPlay Dashboard en Reposo" width="49%">
</p>
<p align="center">
  <img src="assets/carplay_widget.png" alt="Widget Mini HUD en Juego (Tecla F7)" width="340">
</p>

* **Controles y Comandos:**
  * `F7` o comando `/carplay` - Abrir o cerrar la pantalla CarPlay (requiere estar dentro de un vehículo).

---

## 3. 🚗 esx_sticky_wheels (`v6.0.0`)
### Ángulo de Ruedas Estacionadas Persistente (Sticky Wheels)

* **¿Para qué sirve?**  
  Soluciona el comportamiento por defecto de GTA V, en el cual las ruedas de los vehículos regresan al centro automáticamente en cuanto el conductor se baja del auto. Mantiene el ángulo de giro bloqueado al estacionar.

* **Características Principales:**
  * **Sincronización por OneSync State Bags (`ps_angle`):** No utiliza eventos de red repetitivos ni loops pesados en el servidor, garantizando máxima fluidez y cero consumo de recursos.
  * **Filtro Inteligente de Vehículos:** Excluye motos, bicicletas, botes, helicópteros, aviones y trenes.
  * **Totalmente Standalone:** A pesar de su prefijo tradicional `esx_`, no tiene dependencias y funciona en servidores Standalone, ESX, QBCore y vMenu.

---

## 4. 🗺️ respawn_menu (`v1.1.0`)
### Menú Táctico de Reaparición con Mapa Satelital y Protección de Spawn

* **¿Para qué sirve?**  
  Sustituye la pantalla de muerte común por un mapa satelital interactivo donde los jugadores caídos eligen su punto de despliegue táctico.

* **Características Principales:**
  * **Zona de Exclusión Dinámica (`MinRespawnDistance`):** Calcula en tiempo real las distancias y bloquea automáticamente los puntos de respawn cercanos al lugar de la muerte, previniendo el campeo y la venganza inmediata.
  * **Revivir en el Sitio ("Revive Here"):** Opción de revivir en el mismo lugar protegida por permisos ACE (`respawn.here`) o trabajos ESX (Policía, Médicos).
  * **I-Frames (Invulnerabilidad de Spawn):** Tiempo configurable de inmunidad contra disparos con advertencia holográfica previa para garantizar un despliegue justo.
  * **Transición Cinematográfica:** Animaciones de cámara aérea con fundidos suaves y desvanecimiento de sonido al reaparecer.
  * **Panel de Administración NUI:** Gestión visual integrada para configurar permisos de respawn sobre la marcha.

---

## 5. 👥 team_selector (`v1.0.0`)
### Lobby Táctico con Selección de Equipos por NPC

* **¿Para qué sirve?**  
  Proporciona una zona de lobby con un NPC interactivo donde los jugadores eligen su facción o equipo (Fuerzas Especiales, Bandas, Civiles, etc.), asignándoles automáticamente su equipamiento, chaleco y teletransporte a su base de operaciones.

* **Características Principales:**
  * **NPC en Lobby:** Ped con animación idle, marcador en el radar y verificación de rango de interacción.
  * **Limpieza de Inventario (Blacklist):** Retira automáticamente armas y consumibles de facciones contrarias al cambiar de equipo.
  * **Asignación Automática:** Entrega armas reglamentarias, munición, chalecos blindados y kits médicos al unirse a un bando.
  * **Teletransporte a Base:** Despliega instantáneamente al jugador en su cuartel general con coordenadas y orientación (heading) precisas.

---

## ⚙️ Instalación en tu Servidor

1. Clona este repositorio dentro de la carpeta `resources` de tu servidor:
   ```bash
   cd resources/[local]
   git clone https://github.com/CHW1534/FiveM_Utilities.git
   ```

2. Agrega los recursos en tu archivo `server.cfg`:
   ```cfg
   ensure BodyGuard
   ensure carplay
   ensure esx_sticky_wheels
   ensure respawn_menu
   ensure team_selector
   ```

3. Reinicia el servidor o ejecuta en la consola:
   ```
   refresh
   start BodyGuard
   start carplay
   start esx_sticky_wheels
   start respawn_menu
   start team_selector
   ```

---

## 👨‍💻 Autor y Repositorio
* **Autor:** [CHW](https://github.com/CHW1534)
* **GitHub Repository:** [https://github.com/CHW1534/FiveM_Utilities](https://github.com/CHW1534/FiveM_Utilities)
* **Licencia:** MIT - Libre para uso y adaptación en servidores de FiveM.
