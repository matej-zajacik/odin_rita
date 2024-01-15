package main

import "core:fmt"
import "vendor:raylib"



input_action_t :: struct
{
    input_method: action_input_method_t,
    bind:         int,
    state:        bool,
}



action_input_method_t :: enum
{
    KEYBOARD_KEY,
    MOUSE_BUTTON,
}



input_action_id_t :: enum
{
    MOVE_FORWARD,
    MOVE_BACKWARD,
    MOVE_LEFT,
    MOVE_RIGHT,

    SELECT_WRENCH,
    SELECT_PISTOL,
    SELECT_SHOTGUN,
    SELECT_RIFLE,
    SELECT_GATLING,

    USE_PRIMARY_ATTACK,
    USE_SECONDARY_ATTACK,
}



@(private="file") current_state:  [input_action_id_t]input_action_t
@(private="file") previous_state: [input_action_id_t]input_action_t
mouse_position: vec2_t
mouse_delta:    vec2_t



register_input_action :: proc(id: input_action_id_t, input_method: action_input_method_t, bind: int)
{
    current_state[id].input_method = input_method
    current_state[id].bind = bind
    previous_state[id].input_method = input_method
    previous_state[id].bind = bind
}



tick_input :: proc()
{
    for &action, index in current_state
    {
        previous_state[index].state = action.state

        switch action.input_method
        {
            case .KEYBOARD_KEY:
                action.state = raylib.IsKeyDown(raylib.KeyboardKey(action.bind))

            case .MOUSE_BUTTON:
                action.state = raylib.IsMouseButtonDown(raylib.MouseButton(action.bind))
        }
    }
}



get_input_action :: proc(id: input_action_id_t) -> bool
{
    return current_state[id].state;
}



get_input_action_down :: proc(id: input_action_id_t) -> bool
{
    return !previous_state[id].state && current_state[id].state;
}



get_input_action_up :: proc(id: input_action_id_t) -> bool
{
    return previous_state[id].state && !current_state[id].state;
}



tick_mouse :: proc()
{
    mouse_position = raylib.GetMousePosition()
    mouse_delta += raylib.GetMouseDelta()
}