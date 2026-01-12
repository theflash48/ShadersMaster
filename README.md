# Proyecto final — Recreación visual inspirada en *POOLS* (Unity URP)

Escena en **Unity 6.2 (6000.2.10f1)** con **URP**, centrada en reproducir parte del estilo visual de *POOLS*, especialmente el comportamiento del agua (refracción, reflejos y ondulación).

[GIF: recorrido corto / resultado final]

---

## Equipo
- Iker Torres
- María José López
- Pablo Rozalén — **Agua / Shader**

---

## Requisitos
- Unity **6000.2.10f1**
- **URP** (PC)

---

## Cómo ejecutar
1. Abrir el proyecto con Unity 6.2.
2. Abrir la escena principal:
   - `[PLACEHOLDER: ruta de la escena .unity]`
3. Asegurar en URP:
   - **Depth Texture: ON**
   - **Opaque Texture: ON**
4. Play.

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

<img width="347" height="672" alt="imagen" src="https://github.com/user-attachments/assets/56f0db1e-f629-4f97-87af-1dc3d8ac2a40" />

