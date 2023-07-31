package main

import "core:math"
import "vendor:raylib"



main_cam: raylib.Camera2D



tick_camera :: proc()
{
    main_cam.target = player.position
    main_cam.rotation = math.to_degrees(player.angle - math.PI / 2)
}



reset_camera :: proc()
{
    main_cam.offset = {f32(raylib.GetScreenWidth()) * 0.5, f32(raylib.GetScreenHeight()) * 0.5}
    main_cam.rotation = 0.0
    main_cam.target = {}
    set_camera_zoom(1.0)
}



set_camera_zoom :: proc(zoom: f32)
{
    main_cam.zoom = zoom * TILE_SIZE
}