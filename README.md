# Rita

Top-down shooter written in Odin &amp; Raylib.

# To Do

- [ ] Implement projectiles:
    - [ ] Impact functionality.
    - [ ] Projectile collision.
    - [x] Change actor move code to prevent tunneling.
    - [x] Pistol projectile attack for starters.
- [ ] Make a particle system.
- [x] Add debug drawing stuff to Queedo lib.
- [x] Rework `actors` from `[]^Actor` to `[]Actor`. Simply have a fixed array of values instead of pointers of heap-allocated actors, so iteration is faster, and we can also completely ditch the whole pooling shabang.
- [x] Add a "scan-line" screen effect.
- [x] Change world units to 1 unit = 1 tile.
- [x] Add a camera and rotation system so that we always head "up".
- [x] Remove the mass-dependent push-away of actors. When an actor tries to move into another actor, it should simply push itself away.
- [x] Currently, diagonal movement against walls has no effect on the other, unblocked axis. We need to do this.