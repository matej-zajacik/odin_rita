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



Color   :: raylib.Color
Rect    :: raylib.Rectangle
Sound   :: raylib.Sound
Vector2 :: raylib.Vector2



window_width:  int
window_height: int
should_quit:   bool
current_frame: int



main :: proc()
{
    context.logger = get_logger()
    os.set_current_directory("bin")

    raylib.InitWindow(1600, 900, "Rita")

    init_game()
    main_loop()
    quit_game()

    raylib.CloseWindow()
}



main_loop :: proc()
{
    last_time:        f64
    fixed_step_timer: f64
    fps_timer:        f64
    fps_counter:      int
    fps_value:        f64

    for !should_quit && !raylib.WindowShouldClose()
    {
        //
        // Memory
        //

        free_all(context.temp_allocator)

        //
        // Time
        //

        current_time := raylib.GetTime()
        dt := current_time - last_time
        last_time = current_time
        fixed_step_timer += dt

        fps_timer += dt
        fps_counter += 1

        if fps_timer > 0.5
        {
            fps_value = f64(fps_counter) / 0.5
            fps_timer -= 0.5
            fps_counter = 0
        }

        //
        // Events
        //

        // ...

        //
        // Tick
        //

        tick_mouse()

        for fixed_step_timer >= FIXED_DT
        {
            fixed_step_timer -= FIXED_DT
            tick_debug_shapes()
            tick_input()
            tick_game()
            mouse_delta = {}
            current_frame += 1
        }

        //
        // Render
        //

        raylib.BeginDrawing()
        draw_game()
        raylib.EndDrawing()
    }
}



request_quit :: proc()
{
    should_quit = true
}