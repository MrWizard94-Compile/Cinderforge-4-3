# CINDERFORGE

Heavy-metal **rhythm-action roguelite** prototype (WPAI).  
Original metal stems drive Heat; combat rewards on-beat hits.

## Run (Godot 4.3+)

1. Download **Godot 4.3+** standard build (~120 MB, free): https://godotengine.org/download/windows/  
   *(Not currently installed on PATH on this dev box — Rob needs this once.)*
2. **Import** → `C:\WPAI\Games\Cinderforge\project.godot`
3. First open reimports audio (Weaponized Mind stems are large WAVs — wait).
4. **F5** Play.

### Controls

| Key | Action |
|-----|--------|
| **WASD** | Move |
| **Space** / click | Attack (on-beat → more damage + Heat + music layers) |
| **Shift** | Dash (on-beat → longer i-frames) |
| **T** | Tap-tempo (set BPM live) |
| **N** | Continue after reward / restart after win |
| **R** | Retry after death |

### Feel gate

1. Tap **T** with the drums a few times.  
2. Kill the tutorial **Wretch** with on-beat strikes — hear guitars/vox climb.  
3. Clear arenas → **First Hammer** boss.

## Layout

```
Cinderforge/
  project.godot
  Main.tscn                 Arena (rooms + UI + camera juice)
  scenes/Player.tscn
  scenes/Enemy.tscn
  scripts/
    Arena.gd                Run loop: Intro → A → Reward → B → Boss
    RhythmCore.gd           Beat clock, Heat, stem layering
    Player.gd               Move / dash / attack → rhythm
    Enemy.gd                Wretch, Archer, Guard, Boss
  audio/weaponized_mind/    Stem WAVs (slice track #1)
  art/bible/                Concept sheets
  docs/                     Combat, art bible, stem prep
```

## Lanes

| Who | Owns |
|-----|------|
| Claude | Rhythm core origin, orchestrator/QA |
| Grok | Combat, enemies, art direction, juice, run loop (this build) |
| Director | Green-light, Godot install, track/BPM feel |

## Next polish

- [ ] Bake real BPM files (stop guessing via tap only)  
- [ ] Replace polygons with `art/` sprites  
- [ ] OGG + AudioStreamSynchronized for production  
- [ ] Wire Chain Reaction + Undeath stems  
- [ ] More juice (hit numbers, death sparks)  

*AI is in the name; the wizard is in the work.*
