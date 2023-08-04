package main

import "core:log"



Cheat_Id :: enum
{
    GOD,
    UNLIMITED_AMMO,
    NO_CLIP,

    GIVE_ALL,
    GIVE_AMMO,
    GIVE_GUNS,
}



cheats: [Cheat_Id]bool



set_cheat :: proc(id: Cheat_Id, on: bool)
{
    give_ammo :: proc()
    {
    }

    give_guns :: proc()
    {
    }

    #partial switch id
    {
        case .GIVE_ALL:
            give_guns()
            give_ammo()
        case .GIVE_AMMO:
            give_ammo()
        case .GIVE_GUNS:
            give_guns()

        case:
            cheats[id] = on
            log.infof("%v cheat: %v", id, on ? "on" : "off")
    }
}



toggle_cheat :: proc(id: Cheat_Id)
{
    set_cheat(id, !cheats[id])
}