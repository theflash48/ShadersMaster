using UnityEngine;

public class DoorGlitchDriver : MonoBehaviour
{
    [Header("Target")]
    public Renderer targetRenderer;
    public int materialIndex = 0;
    public bool useUnscaledTime = false;

    [Header("Dissolve (sinus)")]
    [Range(0f, 1f)] public float dissolveMin = 0.00f;
    [Range(0f, 1f)] public float dissolveMax = 0.25f;
    public float dissolveSpeed = 0.6f;

    [Header("Base Values")]
    public bool readBaseFromMaterialOnStart = true;
    public float baseGlitchStrength = 0.12f;
    public float baseRGBSplit = 0.014f;
    public float baseColorGlitchStrength = 2.0f;
    public float baseLineTearStrength = 0.14f;
    public float baseSnowStrength = 0.55f;
    public float baseOpacity = -1f;

    [Header("Burst Glitch")]
    public Vector2 burstInterval = new Vector2(1.0f, 3.0f);
    public Vector2 burstDuration = new Vector2(0.08f, 0.22f);
    public float burstGlitchAdd = 0.10f;
    public float burstRGBAdd = 0.010f;
    public float burstColorAdd = 1.6f;
    public float burstLineTearAdd = 0.08f;
    public float burstSnowAdd = 0.45f;

    [Header("Extra Flicker")]
    [Range(0f, 1f)] public float microFlicker = 0.25f;
    public float microFlickerSpeed = 18f;

    MaterialPropertyBlock mpb;
    int idDissolve, idGlitch, idRGB, idColor, idLineTear, idSnow, idOpacity;

    float nextBurstTime;
    float burstEndTime;
    bool bursting;

    void Awake()
    {
        if (!targetRenderer) targetRenderer = GetComponent<Renderer>();
        mpb = new MaterialPropertyBlock();

        idDissolve = Shader.PropertyToID("_Dissolve");
        idGlitch = Shader.PropertyToID("_GlitchStrength");
        idRGB = Shader.PropertyToID("_RGBSplit");
        idColor = Shader.PropertyToID("_ColorGlitchStrength");
        idLineTear = Shader.PropertyToID("_LineTearStrength");
        idSnow = Shader.PropertyToID("_SnowStrength");
        idOpacity = Shader.PropertyToID("_Opacity");
    }

    void Start()
    {
        if (!targetRenderer) return;

        if (readBaseFromMaterialOnStart)
        {
            var mats = targetRenderer.sharedMaterials;
            if (mats != null && materialIndex >= 0 && materialIndex < mats.Length && mats[materialIndex])
            {
                var m = mats[materialIndex];

                if (m.HasProperty(idGlitch)) baseGlitchStrength = m.GetFloat(idGlitch);
                if (m.HasProperty(idRGB)) baseRGBSplit = m.GetFloat(idRGB);
                if (m.HasProperty(idColor)) baseColorGlitchStrength = m.GetFloat(idColor);
                if (m.HasProperty(idLineTear)) baseLineTearStrength = m.GetFloat(idLineTear);
                if (m.HasProperty(idSnow)) baseSnowStrength = m.GetFloat(idSnow);
                if (baseOpacity < 0f && m.HasProperty(idOpacity)) baseOpacity = m.GetFloat(idOpacity);
            }
        }

        ScheduleNextBurst(GetTime());
    }

    void Update()
    {
        if (!targetRenderer) return;

        float t = GetTime();

        float s = Mathf.Sin(t * dissolveSpeed) * 0.5f + 0.5f;
        float dissolve = Mathf.Lerp(dissolveMin, dissolveMax, s);

        if (!bursting && t >= nextBurstTime)
        {
            bursting = true;
            burstEndTime = t + Random.Range(burstDuration.x, burstDuration.y);
        }

        float burstK = 0f;
        if (bursting)
        {
            float u = Mathf.InverseLerp(burstEndTime, burstEndTime - (burstEndTime - (burstEndTime - 0.0001f)), t);
            burstK = 1f - Mathf.InverseLerp(burstEndTime - 0.0001f, burstEndTime, t);
            burstK = Mathf.Clamp01(burstK);
            burstK = burstK * burstK;

            if (t >= burstEndTime)
            {
                bursting = false;
                ScheduleNextBurst(t);
                burstK = 0f;
            }
        }

        float flick = 1f + (Mathf.Sin(t * microFlickerSpeed) * 0.5f + 0.5f) * microFlicker;

        float glitch = (baseGlitchStrength + burstGlitchAdd * burstK) * flick;
        float rgb = (baseRGBSplit + burstRGBAdd * burstK) * flick;
        float col = (baseColorGlitchStrength + burstColorAdd * burstK) * flick;
        float tear = (baseLineTearStrength + burstLineTearAdd * burstK) * flick;
        float snow = (baseSnowStrength + burstSnowAdd * burstK) * flick;

        targetRenderer.GetPropertyBlock(mpb, materialIndex);

        mpb.SetFloat(idDissolve, dissolve);
        mpb.SetFloat(idGlitch, glitch);
        mpb.SetFloat(idRGB, rgb);
        mpb.SetFloat(idColor, col);
        mpb.SetFloat(idLineTear, tear);
        mpb.SetFloat(idSnow, snow);

        if (baseOpacity >= 0f)
        {
            float op = Mathf.Clamp01(baseOpacity * (1f - 0.10f * burstK));
            mpb.SetFloat(idOpacity, op);
        }

        targetRenderer.SetPropertyBlock(mpb, materialIndex);
    }

    float GetTime()
    {
        return useUnscaledTime ? Time.unscaledTime : Time.time;
    }

    void ScheduleNextBurst(float t)
    {
        float min = Mathf.Max(0.01f, burstInterval.x);
        float max = Mathf.Max(min, burstInterval.y);
        nextBurstTime = t + Random.Range(min, max);
    }
}
