# Proyecto final — Recreación visual inspirada en *POOLS* (Unity URP)

Escena en **Unity 6.2 (6000.2.10f1)** con **URP**, centrada en reproducir el estilo visual de *POOLS* (poolrooms/liminal), con énfasis en materiales procedurales y shaders en HLSL (sin Shader Graph): agua, barrera glitch, entidad tipo “void” y superficies tipo azulejo.


---

## Equipo
- **Iker Torres Arenas** — Modelado del mapa + Shader tiles (paredes) + Shader entidad (void)
- **María José López Arroyo** — Shader glitch door + Shader metal del marco de la puerta
- **Pablo Rozalén** — **Agua / Shader**

---

## Requisitos
- Unity **6000.2.10f1**
- **URP** (PC)

---

## Cómo ejecutar
1. Abrir el proyecto con Unity 6.2.
2. Abrir la escena principal:
3. Asegurar en URP:
   - **Depth Texture: ON**
   - **Opaque Texture: ON**
4. Play.

---

## Aportación individual — Iker Torres Arenas (Tiles + Modelado + Entidad Void)
### 1) Modelado del mapa (Blender)
Creación del escenario base inspirado en *POOLS*:
- Sala principal + transición/escalón
- Marco de la puerta y plano interior para la “barrera”
- Distribución simple para reforzar composición tipo liminal (líneas limpias y lectura clara)

### 2) Shader de paredes tipo azulejo (Tiles) — HLSL (URP Unlit)
Shader procedural sin texturas para simular **azulejo blanco repetitivo**:
- Rejilla/junta (grout) configurable por ancho
- Repetición por UV con control de densidad
- Variación sutil por tile para evitar efecto “plano”/clonado

### 3) Shader de la entidad “void” (abujero negro) — HLSL (URP Unlit + Dissolve)
Entidad tipo “agujero negro” pensada para generar tensión:
- **Dissolve** procedural animado en world-space (sin depender de UV ni texturas)
- Borde doble (rim sharp + rim soft) para controlar el contorno
- **Fresnel** para dar sensación de “vacío” y profundidad visual
- Emisión controlada por parámetros (no depende de Bloom global)

---

## Aportación individual — María José López Arroyo (Glitch Door + Metal del marco)
### 1) Shader de “Glitch Door” (barrera holográfica) — HLSL (URP Unlit Transparent)
Plano en el interior del marco simulando una barrera irreal:
- Scanlines animadas (UV.y + tiempo)
- Ruido animado + distorsión horizontal (glitch UV)
- Fresnel para reforzar bordes y lectura de “pantalla/barrera”

### 2) Shader metal del marco de la puerta — HLSL (URP Lit)
Material metálico simple y legible en escena:
- Specular fuerte con control de smoothness
- Variación “brushed” ligera en UV para evitar metal plano
- Fresnel suave para mejorar lectura en bordes

---

## Aportación individual — Pablo Rozalén (Agua / Shader)
Implementación de un **URP Unlit Shader en HLSL (sin Shader Graph)** para agua estilo *POOLS* con:

- **Oleaje real** por *vertex displacement* (olas).
- **Wave normals** para que la ondulación se aprecie desde ángulos “normales”, no solo rasantes.
- **Reflejos** (Skybox/Reflection Probe) con **Fresnel**.
- **Refracción** usando `_CameraOpaqueTexture`.
- **Profundidad/absorción** usando `_CameraDepthTexture` (shallow/deep).
- **2 capas de normal maps** (macro + detalle) animadas.
- Ajustes de borde (edge fade + edge waviness).

https://github.com/user-attachments/assets/50266f55-94bc-4f57-9339-f913c7823989

---

## Notas de configuración (para que se vea bien)
- El suelo bajo el agua debe ser **opaco** y el agua debe ir ligeramente por encima (ej. +0.2 en Y).
- Recomendado:
  - **Reflection Probe** (Baked o Realtime según necesidad).
  - **Skybox** configurado.
  - **Emissive** en luces de techo + **Bloom** en el Volume para highlights tipo fluorescente.

## Dificultades que tuvimos:
- En el caso del agua, nos costo lograr que las olas tuvieran ondulación y se apreciaran
- En el caso del agua, el brillo del agua aveces dificultaba el montaje
- En el caso de la entidad, nos parece que podría haber quedado mejor con otro modelo para mostrar mejor el shader
- En el caso de la puerta, podríamos haber juntado los marcos en lugar de que fueran tres piezas distintas.

<img width="347" height="672" alt="imagen" src="https://github.com/user-attachments/assets/56f0db1e-f629-4f97-87af-1dc3d8ac2a40" />
