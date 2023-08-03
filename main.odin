package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:runtime"
import "core:strings"
import "vendor:raylib"
import "shared:queedo"



Vector2 :: raylib.Vector2
Rect    :: raylib.Rectangle
Color   :: raylib.Color



Input_Action :: enum
{
    MOVE_FORWARD,
    MOVE_BACKWARD,
    MOVE_LEFT,
    MOVE_RIGHT,

    SELECT_GUN_WRENCH,
    SELECT_GUN_PISTOL,
    SELECT_GUN_SHOTGUN,
    SELECT_GUN_RIFLE,
    SELECT_GUN_GATLING,

    USE_PRIMARY_ATTACK,
    USE_SECONDARY_ATTACK,
}



current_frame:  int
mouse_position: raylib.Vector2
mouse_delta:    raylib.Vector2



main :: proc()
{
    s: queedo.Init_Settings;
    s.window_title  = "Rita"
    s.window_width  = 1600
    s.window_height = 900
    s.frame_rate    = FRAME_RATE
    s.init_callback = init_game
    s.tick_callback = tick_game
    s.draw_callback = draw_game
    s.quit_callback = quit_game

    queedo.init(s)
}



init_game :: proc()
{
    os.set_current_directory("bin")

    raylib.DisableCursor()

    init_game_options()
    load_game_options()
    save_game_options()

    init_blueprints()
    init_actors()
    init_guns()

    queedo.init_input_actions(len(Input_Action))
    queedo.register_input_action(int(Input_Action.MOVE_FORWARD),         .KEYBOARD_KEY, int(raylib.KeyboardKey.W))
    queedo.register_input_action(int(Input_Action.MOVE_BACKWARD),        .KEYBOARD_KEY, int(raylib.KeyboardKey.S))
    queedo.register_input_action(int(Input_Action.MOVE_LEFT),            .KEYBOARD_KEY, int(raylib.KeyboardKey.A))
    queedo.register_input_action(int(Input_Action.MOVE_RIGHT),           .KEYBOARD_KEY, int(raylib.KeyboardKey.D))
    queedo.register_input_action(int(Input_Action.SELECT_GUN_WRENCH),    .KEYBOARD_KEY, int(raylib.KeyboardKey.ONE))
    queedo.register_input_action(int(Input_Action.SELECT_GUN_PISTOL),    .KEYBOARD_KEY, int(raylib.KeyboardKey.TWO))
    queedo.register_input_action(int(Input_Action.SELECT_GUN_SHOTGUN),   .KEYBOARD_KEY, int(raylib.KeyboardKey.THREE))
    queedo.register_input_action(int(Input_Action.SELECT_GUN_RIFLE),     .KEYBOARD_KEY, int(raylib.KeyboardKey.FOUR))
    queedo.register_input_action(int(Input_Action.SELECT_GUN_GATLING),   .KEYBOARD_KEY, int(raylib.KeyboardKey.FIVE))
    queedo.register_input_action(int(Input_Action.USE_PRIMARY_ATTACK),   .MOUSE_BUTTON, 0)
    queedo.register_input_action(int(Input_Action.USE_SECONDARY_ATTACK), .MOUSE_BUTTON, 1)

    reset_camera()
    load_map("data/test_map.json")

    init_scanline_fx()

    test()
}



tick_game :: proc(dt: f64)
{
    current_frame  = queedo.current_frame
    mouse_position = queedo.mouse_position
    mouse_delta    = queedo.mouse_delta

    tick_actors()
    tick_camera()
}



quit_game :: proc()
{
}



test :: proc()
{
    spawn_actor(.SPIDERLING, {5, 5}, 0)
}



spiderling_tick :: proc(actor: ^Actor)
{
    actor.tick_timer -= 1

    if actor.tick_timer > 0 do return

    actor.desired_dir = angle_to_vector(rand.float32_range(0, math.TAU))
    actor.tick_timer = 45
    queedo.draw_debug_line(actor.position, actor.position + actor.desired_dir, ONE_PX_THICKNESS_SCALE, raylib.YELLOW, 45)
}