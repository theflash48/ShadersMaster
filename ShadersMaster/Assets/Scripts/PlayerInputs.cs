using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerInputs : MonoBehaviour
{
    PlayerController pc;
    InputSystemActions inputs;
    
    public Vector2 move, look;

    void Awake()
    {
        inputs = new InputSystemActions();
        pc = GetComponent<PlayerController>();
    }

    void OnEnable()
    {
        inputs.Enable();

        // Reset de seguridad al habilitar
        pc.Move(Vector2.zero);
        pc.Look(Vector2.zero);

        inputs.Player.Move.performed += OnMove;
        inputs.Player.Move.canceled  += OnMove;
        inputs.Player.Look.performed += OnLook;
        inputs.Player.Look.canceled  += OnLook;
    }

    void OnDisable()
    {
        inputs.Player.Move.performed -= OnMove;
        inputs.Player.Move.canceled  -= OnMove;
        inputs.Player.Look.performed -= OnLook;
        inputs.Player.Look.canceled  -= OnLook;

        // Reset de seguridad al deshabilitar
        pc.Move(Vector2.zero);
        pc.Look(Vector2.zero);

        inputs.Disable();
    }

    void OnMove(InputAction.CallbackContext c)
    {
        move = c.ReadValue<Vector2>();
        pc.Move(c.ReadValue<Vector2>());
    }

    void OnLook(InputAction.CallbackContext c)
    {
        look = c.ReadValue<Vector2>();
        pc.Look(c.ReadValue<Vector2>());
    }
}