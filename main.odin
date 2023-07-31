package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
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



draw_game :: proc()
{
    raylib.BeginMode2D(main_cam)
    {
        raylib.DrawTextureEx(map_tex, {}, 0.0, 1.0 / TILE_SIZE, raylib.WHITE)

        for actor in actors
        {
            // We don't draw actors yet.
            if actor == nil do continue
        }

        // We only draw debug colliders.
        draw_colliders()
    }
    raylib.EndMode2D()

    text := strings.clone_to_cstring(fmt.tprintf("ang: %v (%v°)", player.angle, math.to_degrees(player.angle)), context.temp_allocator)
    raylib.DrawText(text, 8, 8, 16, raylib.WHITE)
}



quit_game :: proc()
{
}



test :: proc()
{
    spawn_actor(.SPIDERLING, {5, 5}, 0)
}