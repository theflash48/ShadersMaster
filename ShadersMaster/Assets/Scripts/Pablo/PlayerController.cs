using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class PlayerController : MonoBehaviour
{
    public Transform cam;

    public float speed = 10f;

    public float sens = 180f;
    public bool invertY = false;
    public float minPitch = -80f;
    public float maxPitch = 80f;

    CharacterController cc;
    Vector2 move, look;
    float pitch;

    void Awake()
    {
        cc = GetComponent<CharacterController>();

        if (!cam)
        {
            Camera found = GetComponentInChildren<Camera>();
            if (found) cam = found.transform;
        }
    }

    void OnEnable()
    {
        ApplyCursorLock(Application.isFocused);
    }

    void OnDisable()
    {
        ApplyCursorLock(false);
    }

    void OnApplicationFocus(bool hasFocus)
    {
        ApplyCursorLock(hasFocus);
    }

    void OnApplicationPause(bool paused)
    {
        if (paused) ApplyCursorLock(false);
    }

    void ApplyCursorLock(bool locked)
    {
        Cursor.lockState = locked ? CursorLockMode.Locked : CursorLockMode.None;
        Cursor.visible = !locked;
    }

    void Update()
    {
        float yaw = look.x * sens * Time.deltaTime;
        transform.Rotate(0f, yaw, 0f);

        if (cam)
        {
            float y = invertY ? look.y : -look.y;
            pitch += y * sens * Time.deltaTime;
            pitch = Mathf.Clamp(pitch, minPitch, maxPitch);
            cam.localEulerAngles = new Vector3(pitch, 0f, 0f);
        }

        if (move.x < 0.5 && move.x > -0.5) move.x = 0;
        if (move.y < 0.5 && move.y > -0.5) move.y = 0;

        Vector3 dir = (transform.right * move.x) + (transform.forward * move.y);
        cc.Move(dir * speed * Time.deltaTime);
    }

    public void Move(Vector2 v) => move = v;
    public void Look(Vector2 v) => look = v;
}