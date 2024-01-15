package main

import "core:log"
import "core:math/rand"
import "vendor:miniaudio"
import "vendor:raylib"



sound_t :: miniaudio.sound



sound_flag_t :: enum
{
    LOOP,
    NO_RANDOMIZATION,
}

sound_flags_t :: bit_set[sound_flag_t]



sound_id_t :: enum
{
    PISTOL_FIRE,
}



audio_engine: miniaudio.engine
sounds:       [MAX_SOUNDS]sound_t



// https://miniaud.io/docs/manual/index.html

init_sounds :: proc()
{
    result := miniaudio.engine_init(nil, &audio_engine)

    if result != .SUCCESS
    {
        log.panicf("miniaudio: %v", result)
    }

    log.info("miniaudio: init ok")

    // miniaudio.engine_play_sound(&audio_engine, "data/snd_pistol.wav", nil)
    // miniaudio.sound_init_from_data_source(

    // ma_result result;
    // ma_sound sound;

    // result = ma_sound_init_from_file(&engine, "my_sound.wav", 0, NULL, NULL, &sound);
    // if (result != MA_SUCCESS) {
    //     return result;
    // }

    // ma_sound_start(&sound);
}