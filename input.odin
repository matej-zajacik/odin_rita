package main

import "core:fmt"
import "vendor:raylib"



Input_Action :: struct
{
    input_method: Action_Input_Method,
    bind:         int,
    state:        bool,
}



Action_Input_Method :: enum
{
    KEYBOARD_KEY,
    MOUSE_BUTTON,
}



Input_Action_Id :: enum
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



@(private="file") current_state:  [Input_Action_Id]Input_Action
@(private="file") previous_state: [Input_Action_Id]Input_Action
mouse_position: Vector2
mouse_delta:    Vector2



register_input_action :: proc(id: Input_Action_Id, input_method: Action_Input_Method, bind: int)
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



get_input_action :: proc(id: Input_Action_Id) -> bool
{
    return current_state[id].state;
}



get_input_action_down :: proc(id: Input_Action_Id) -> bool
{
    return !previous_state[id].state && current_state[id].state;
}



get_input_action_up :: proc(id: Input_Action_Id) -> bool
{
    return previous_state[id].state && !current_state[id].state;
}



tick_mouse :: proc()
{
    mouse_position = raylib.GetMousePosition()
    mouse_delta += raylib.GetMouseDelta()
}