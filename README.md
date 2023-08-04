# Rita

Top-down shooter written in Odin &amp; Raylib.

# To Do

- [ ] Get rid of Queedo lib. Just inline everything into the project so it's more flexible and we don't need to jump around projects.
- [x] Implement projectiles:
    - [x] Impact functionality.
    - [x] Projectile collision.
    - [x] Change actor move code to prevent tunneling.
    - [x] Pistol projectile attack for starters.
- [ ] Make a particle system.
- [ ] Make a sound system.
    - Sounds should be able to attach to actors and play at their position.
    - Some non-positional sounds just play.
    - Probably a fixed sparse array of sounds just like `actors: []Actor`.
- [x] Add debug drawing stuff to Queedo lib.
- [x] Rework `actors` from `[]^Actor` to `[]Actor`. Simply have a fixed array of values instead of pointers of heap-allocated actors, so iteration is faster, and we can also completely ditch the whole pooling shabang.
- [x] Add a "scan-line" screen effect.
- [x] Change world units to 1 unit = 1 tile.
- [x] Add a camera and rotation system so that we always head "up".
- [x] Remove the mass-dependent push-away of actors. When an actor tries to move into another actor, it should simply push itself away.
- [x] Currently, diagonal movement against walls has no effect on the other, unblocked axis. We need to do this.