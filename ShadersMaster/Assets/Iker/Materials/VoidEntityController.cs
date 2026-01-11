using System.Collections;
using UnityEngine;

public class VoidEntityController : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private Renderer entityRenderer;     // Renderer del cilindro/entidad
    [SerializeField] private Camera playerCamera;         // Cámara del player

    [Header("Spawns (exactamente 2)")]
    [SerializeField] private Transform spawnA;
    [SerializeField] private Transform spawnB;

    [Header("Dissolve")]
    [SerializeField] private string dissolveProperty = "_Dissolve";
    [SerializeField] private float dissolveDuration = 1.0f;   // segundos
    [SerializeField] private float respawnDelay = 5.0f;        // segundos entre spawn y spawn
    [SerializeField] private float seenGraceTime = 0.15f;      // evita falsos positivos por 1 frame

    [Header("Vision Check")]
    [SerializeField] private LayerMask occlusionMask = ~0;     // todo por defecto
    [SerializeField] private Transform visibilityPoint;        // opcional: punto de mira (si no, usa transform)
    [SerializeField] private float maxViewDistance = 50f;

    [Header("Aura (optional)")]
    [SerializeField] private Transform aura;                   // arrastra un objeto hijo (sphere/quad)
    [SerializeField] private float auraPulseSpeed = 1.2f;
    [SerializeField] private float auraPulseScale = 0.08f;

    private MaterialPropertyBlock mpb;
    private Coroutine routine;
    private float seenTimer;

    private enum SpawnSlot { A, B }
    private SpawnSlot currentSlot = SpawnSlot.A;
    private bool active = true;       // entidad "viva" en escena (render ON)
    private bool dissolving = false;

    void Awake()
    {
        if (!entityRenderer) entityRenderer = GetComponentInChildren<Renderer>();
        if (!playerCamera) playerCamera = Camera.main;

        mpb = new MaterialPropertyBlock();
        if (!visibilityPoint) visibilityPoint = transform;

        // Arranca en un spawn
        TeleportToSpawn(currentSlot);
        SetDissolve(0f); // visible al inicio (ajusta si lo quieres al revés)
        SetVisible(true);
    }

    void Update()
    {
        if (!active || dissolving || !playerCamera) return;

        // Aura pulsing (opcional)
        if (aura)
        {
            float s = 1f + Mathf.Sin(Time.time * auraPulseSpeed) * auraPulseScale;
            aura.localScale = Vector3.one * s;
        }

        // Check si lo está viendo
        if (IsSeenByPlayer())
        {
            seenTimer += Time.deltaTime;
            if (seenTimer >= seenGraceTime)
            {
                StartDissolveAndRespawn();
            }
        }
        else
        {
            seenTimer = 0f;
        }
    }

    private bool IsSeenByPlayer()
    {
        Vector3 target = visibilityPoint.position;
        Vector3 camPos = playerCamera.transform.position;

        // Distancia
        float dist = Vector3.Distance(camPos, target);
        if (dist > maxViewDistance) return false;

        // Dentro del frustum (pantalla)
        Vector3 vp = playerCamera.WorldToViewportPoint(target);
        bool inFront = vp.z > 0f;
        bool inScreen = vp.x >= 0f && vp.x <= 1f && vp.y >= 0f && vp.y <= 1f;
        if (!inFront || !inScreen) return false;

        // Occlusion: raycast desde cámara al punto
        Vector3 dir = (target - camPos).normalized;
        if (Physics.Raycast(camPos, dir, out RaycastHit hit, dist, occlusionMask, QueryTriggerInteraction.Ignore))
        {
            // Si golpea algo que NO es la entidad, está tapada
            if (!hit.collider.transform.IsChildOf(transform))
                return false;
        }

        return true;
    }

    public void StartDissolveAndRespawn()
    {
        if (routine != null) StopCoroutine(routine);
        routine = StartCoroutine(DissolveThenRespawn());
    }

    private IEnumerator DissolveThenRespawn()
    {
        dissolving = true;

        // Disuelve 0 -> 1 (si tu shader está invertido, cambia a 1 -> 0)
        float start = GetDissolve();
        float end = 1f;

        float t = 0f;
        while (t < dissolveDuration)
        {
            t += Time.deltaTime;
            float k = Mathf.Clamp01(t / dissolveDuration);
            SetDissolve(Mathf.Lerp(start, end, k));
            yield return null;
        }
        SetDissolve(end);

        // Apaga entidad
        SetVisible(false);
        active = false;

        // Espera 5s
        yield return new WaitForSeconds(respawnDelay);

        // Cambia al otro spawn (nunca repite)
        currentSlot = (currentSlot == SpawnSlot.A) ? SpawnSlot.B : SpawnSlot.A;
        TeleportToSpawn(currentSlot);

        // Reinicia
        SetDissolve(0f);
        SetVisible(true);
        active = true;
        dissolving = false;
        seenTimer = 0f;
    }

    private void TeleportToSpawn(SpawnSlot slot)
    {
        Transform sp = (slot == SpawnSlot.A) ? spawnA : spawnB;
        if (!sp) return;

        transform.SetPositionAndRotation(sp.position, sp.rotation);
    }

    private void SetVisible(bool v)
    {
        // apaga el renderer del cuerpo
        if (entityRenderer) entityRenderer.enabled = v;

        // apaga/enciende aura
        if (aura) aura.gameObject.SetActive(v);
    }

    private void SetDissolve(float value)
    {
        if (!entityRenderer) return;

        entityRenderer.GetPropertyBlock(mpb);
        mpb.SetFloat(dissolveProperty, value);
        entityRenderer.SetPropertyBlock(mpb);
    }

    private float GetDissolve()
    {
        if (!entityRenderer) return 0f;
        entityRenderer.GetPropertyBlock(mpb);

        // MaterialPropertyBlock no permite leer directo; guardamos “start” a ojo.
        // Para simplicidad, asumimos que si estamos activos y no disolviendo, está en 0.
        return dissolving ? 0.5f : 0f;
    }
}
