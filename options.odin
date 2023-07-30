package main

import "core:encoding/json"
import "core:log"
import "core:os"
import "core:slice"
import "core:strings"
import "shared:util"



GAME_OPTIONS_FILE_NAME :: "options.json"



game_options: struct
{
    mouse_sensitivity: f32,
    difficulty: enum
    {
        EASY,
        MEDIUM,
        HARD,
    },
}



init_game_options :: proc()
{
    using game_options
    mouse_sensitivity = 0.125
}



load_game_options :: proc()
{
    util.read_json_file_to_obj(GAME_OPTIONS_FILE_NAME, &game_options)
}



save_game_options :: proc()
{
    util.write_obj_to_json_file(&game_options, GAME_OPTIONS_FILE_NAME)
}