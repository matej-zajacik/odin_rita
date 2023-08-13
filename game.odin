package main

import "core:log"
import "core:math"
import "core:math/rand"
import "vendor:raylib"



init_game :: proc()
{
    raylib.DisableCursor()

    init_game_options()
    load_game_options()
    save_game_options()

    init_sounds()
    init_blueprints()
    init_array_of_free_indexes(&free_actor_indexes, MAX_ACTORS)
    init_array_of_free_indexes(&free_emitter_indexes, MAX_EMITTERS)
    init_guns()

    register_input_action(.MOVE_FORWARD,         .KEYBOARD_KEY, int(raylib.KeyboardKey.W))
    register_input_action(.MOVE_BACKWARD,        .KEYBOARD_KEY, int(raylib.KeyboardKey.S))
    register_input_action(.MOVE_LEFT,            .KEYBOARD_KEY, int(raylib.KeyboardKey.A))
    register_input_action(.MOVE_RIGHT,           .KEYBOARD_KEY, int(raylib.KeyboardKey.D))
    register_input_action(.SELECT_WRENCH,        .KEYBOARD_KEY, int(raylib.KeyboardKey.ONE))
    register_input_action(.SELECT_PISTOL,        .KEYBOARD_KEY, int(raylib.KeyboardKey.TWO))
    register_input_action(.SELECT_SHOTGUN,       .KEYBOARD_KEY, int(raylib.KeyboardKey.THREE))
    register_input_action(.SELECT_RIFLE,         .KEYBOARD_KEY, int(raylib.KeyboardKey.FOUR))
    register_input_action(.SELECT_GATLING,       .KEYBOARD_KEY, int(raylib.KeyboardKey.FIVE))
    register_input_action(.USE_PRIMARY_ATTACK,   .MOUSE_BUTTON, 0)
    register_input_action(.USE_SECONDARY_ATTACK, .MOUSE_BUTTON, 1)

    reset_camera()
    load_map("data/test_map.json")

    init_scanline_fx()

    test()
}



tick_game :: proc()
{
    tick_actors()
    tick_camera()
    tick_emitters()
}



quit_game :: proc()
{
}



test :: proc()
{
    spawn_actor(.SPIDERLING, {5, 5}, 0)
    toggle_cheat(.UNLIMITED_AMMO)
}



spiderling_tick :: proc(actor: ^Actor)
{
    actor.tick_timer -= 1

    if actor.tick_timer > 0 do return

    actor.desired_dir = angle_to_vector(rand.float32_range(0, math.TAU))
    actor.tick_timer = 45
    draw_debug_line(false, actor.position, actor.position + actor.desired_dir, ONE_PX_THICKNESS_SCALE, raylib.YELLOW, 45)
}