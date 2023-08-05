package main

import "core:log"
import "core:fmt"
import "core:os"
import "core:math"
import "core:mem"
import "core:encoding/json"
import "core:slice"
import "vendor:raylib"
import "util"



Map_JSON :: struct
{
    compressionlevel: int,
    width:            int,
    height:           int,
    infinite:         bool,

    layers: []struct
    {
        data: []int,
        name: string,
        type: string,

        objects: []struct
        {
            class:    string,
            width:    int,
            height:   int,
            x:        int,
            y:        int,
            rotation: int,
        },
    },
}



geo_colliders: [dynamic]Rect
map_tex:       raylib.Texture2D
map_width:     int
map_height:    int



load_map :: proc(file_name: string)
{
    map_json: Map_JSON
    util.read_json_file_to_obj(file_name, &map_json)

    map_width = map_json.width
    map_height = map_json.height

    player_start_position: Vector2
    player_start_found:    bool

    // Load the tileset image.
    tileset_image := raylib.LoadImage("data/tex_tileset_lab.png")
    image_w, image_h := tileset_image.width, tileset_image.height
    horiz_tiles := image_w / TILE_SIZE
    vert_tiles := image_h / TILE_SIZE
    tile_count := horiz_tiles * vert_tiles

    tileset_quads := make([]Rect, tile_count, context.temp_allocator)
    
    for i in 0..<tile_count
    {
        x := f32(i % horiz_tiles) * TILE_SIZE
        y := math.floor(f32(i) / f32(horiz_tiles)) * TILE_SIZE
        quad := Rect{x, y, TILE_SIZE, TILE_SIZE}
        tileset_quads[i] = quad
    }

    // We will bake the static tiles into a texture so that we can just render that texture instead of all the individual tiles every frame.
    map_image := raylib.GenImageColor(i32(map_json.width * TILE_SIZE), i32(map_json.height * TILE_SIZE), {})

    // Let's read the layers now.
    for &layer in map_json.layers
    {
        switch layer.type
        {
            case "tilelayer":
            {
                // This is the tile GID, as Tiled calls it, potentially with flags set.
                for tile_gid, i in layer.data
                {
                    // 0 means there's no tile.
                    if tile_gid == 0 do continue

                    tile_gid := tile_gid

                    // This is the grid position of the tile.
                    x := i % map_json.width
                    y := int(math.floor(f32(i) / f32(map_json.width)))

                    BIT31 : int : 1 << 31
                    BIT30 : int : 1 << 30
                    BIT29 : int : 1 << 29

                    // Flipping and rotation mumbo-jumbo.
                    flip_x := false
                    flip_y := false
                    flip_d := false
                    r := 0

                    if tile_gid & BIT31 > 0 do flip_x = true
                    if tile_gid & BIT30 > 0 do flip_y = true
                    if tile_gid & BIT29 > 0 do flip_d = true

                    // Remove the flags so we get the actual index into the tileset.
                    tile_gid &= ~(BIT31 | BIT30 | BIT29)

                    if flip_x
                    {
                        if flip_y && flip_d
                        {
                            flip_x = false
                            r = -1
                        }
                        else if flip_d
                        {
                            flip_x = false
                            r = 1
                        }
                    }
                    else if flip_y
                    {
                        if flip_d
                        {
                            flip_y = false
                            r = -1
                        }
                    }
                    else if flip_d
                    {
                        flip_y = true
                        r = 1
                    }

                    // Draw the tile to the canvas.
                    src_rect := tileset_quads[tile_gid - 1]
                    dst_rect := Rect{f32(x * TILE_SIZE), f32(y * TILE_SIZE), src_rect.width, src_rect.height}

                    tile_image := raylib.ImageFromImage(tileset_image, src_rect)

                    if flip_x
                    {
                        raylib.ImageFlipHorizontal(&tile_image)
                    }

                    if flip_y
                    {
                        raylib.ImageFlipVertical(&tile_image)
                    }

                    if r > 0
                    {
                        raylib.ImageRotateCW(&tile_image)
                    }
                    else if r < 0
                    {
                        raylib.ImageRotateCCW(&tile_image)
                    }

                    raylib.ImageDraw(&map_image, tile_image, {0.0, 0.0, f32(tile_image.width), f32(tile_image.height)}, dst_rect, {255, 255, 255, 255})

                    raylib.UnloadImage(tile_image)
                }
            }

            case "objectgroup":
            {
                switch layer.name
                {
                    case "actors":
                    {
                        for &obj in layer.objects
                        {
                            switch obj.class
                            {
                                case "player_start":
                                {
                                    if !player_start_found
                                    {
                                        player_start_found = true
                                        player_start_position = get_object_position(obj.x, obj.y)
                                    }
                                }
                            }
                        }
                    }

                    case "collision":
                    {
                        for &obj in layer.objects
                        {
                            r := Rect{f32(obj.x) / TILE_SIZE, f32(obj.y)  / TILE_SIZE, f32(obj.width)  / TILE_SIZE, f32(obj.height)  / TILE_SIZE}
                            append(&geo_colliders, r)
                        }
                    }
                }
            }
        }
    }

    // Convert the CPU image into a GPU texture now.
    map_tex = raylib.LoadTextureFromImage(map_image)

    // Get rid of the image.
    raylib.UnloadImage(map_image)

    init_sectors()

    if player_start_found
    {
        // log.infof("player_start_position: %v", player_start_position)
        spawn_player(player_start_position, 0)
    }



    get_object_position :: proc(x: int, y: int) -> Vector2
    {
        return Vector2{f32(x + HALF_TILE_SIZE) / TILE_SIZE, f32(y + HALF_TILE_SIZE) / TILE_SIZE}
    }
}



//
// Sectors
//

Sector :: struct
{
    neighbors:        [dynamic]^Sector,
    geo_colliders:    [dynamic]^Rect,
    actors:           [dynamic]^Actor,

    debug_tile_pos_x: int,
    debug_tile_pos_y: int,
    debug_rect:       Rect,
}



sectors:     []Sector
sector_cols: int
sector_rows: int



init_sectors :: proc()
{
    for &sector in sectors
    {
        delete(sector.neighbors)
        delete(sector.geo_colliders)
        delete(sector.actors)
    }

    delete(sectors)

    sector_cols = ((map_width - 1) / SECTOR_SIZE) + 1
    sector_rows = ((map_height - 1) / SECTOR_SIZE) + 1

    sectors = make([]Sector, sector_cols * sector_rows)

    for &sector, i in sectors
    {
        x := i % sector_cols
        y := i / sector_cols

        sector.debug_tile_pos_x = x
        sector.debug_tile_pos_y = y
        // sector.debug_rect = Rect{f32(x * TILE_SIZE * SECTOR_SIZE), f32(y * TILE_SIZE * SECTOR_SIZE), f32(TILE_SIZE * SECTOR_SIZE), f32(TILE_SIZE * SECTOR_SIZE)}
        sector.debug_rect = Rect{f32(x * SECTOR_SIZE), f32(y * SECTOR_SIZE), f32(SECTOR_SIZE), f32(SECTOR_SIZE)}

        //
        // Neighbor sectors
        //

        // Norths
        if y > 0
        {
            // North-west
            if x > 0
            {
                append(&sector.neighbors, get_sector(x - 1, y - 1))
            }

            // North
            append(&sector.neighbors, get_sector(x, y - 1))

            // North-east
            if x < sector_cols - 1
            {
                append(&sector.neighbors, get_sector(x + 1, y - 1))
            }
        }

        // West
        if x > 0
        {
            append(&sector.neighbors, get_sector(x - 1, y))
        }

        // East
        if x < sector_cols - 1
        {
            append(&sector.neighbors, get_sector(x + 1, y))
        }

        // Souths
        if y < sector_rows - 1
        {
            // South-west
            if x > 0
            {
                append(&sector.neighbors, get_sector(x - 1, y + 1))
            }

            // South
            append(&sector.neighbors, get_sector(x, y + 1))

            // South-east
            if x < sector_cols - 1
            {
                append(&sector.neighbors, get_sector(x + 1, y + 1))
            }
        }
    }

    //
    // Geometry colliders
    //

    temp_colliders := make([dynamic]^Rect, context.temp_allocator)
    reserve(&temp_colliders, 64)

    for &sector, i in sectors
    {
        clear(&temp_colliders)

        x := i % sector_cols
        y := i / sector_cols

        try_add_colliders(&sector, &temp_colliders)

        for neighbor_sector in sector.neighbors
        {
            try_add_colliders(neighbor_sector, &temp_colliders)
        }

        append(&sector.geo_colliders, ..temp_colliders[:])

        try_add_colliders :: proc(sector: ^Sector, arr: ^[dynamic]^Rect)
        {
            for &geo_collider_rect in geo_colliders
            {
                if !slice.contains(arr[:], &geo_collider_rect) && rects_intersect(sector.debug_rect, geo_collider_rect)
                {
                    append(arr, &geo_collider_rect)
                }
            }
        }
    }
}



get_sector :: #force_inline proc(x: int, y: int) -> ^Sector
{
    return &sectors[y * sector_cols + x]
}



//
// Debug
//

draw_colliders :: proc()
{
    for s in sectors
    {
        raylib.DrawRectangleLinesEx(s.debug_rect, ONE_PX_THICKNESS_SCALE, raylib.ORANGE)
    }

    for r in geo_colliders
    {
        raylib.DrawRectangleLinesEx(r, ONE_PX_THICKNESS_SCALE, raylib.GREEN)
    }

    for &actor in actors
    {
        if !actor_is_in_play(&actor) do continue

        draw_circle(actor.position, actor.bp.radius, ONE_PX_THICKNESS_SCALE, raylib.GREEN)
        raylib.DrawLineEx(actor.position, actor.position + get_actor_forward(&actor) * actor.bp.radius, ONE_PX_THICKNESS_SCALE, raylib.GREEN)
    }
}