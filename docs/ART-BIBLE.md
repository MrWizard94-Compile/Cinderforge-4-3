# CINDERFORGE — Art Bible (Vertical Slice)

**Owner:** Executor (Grok) · **Style:** 2D forge ink · **Engine:** Godot 4  

---

## 1. Palette (locked)

| Role | Hex | Notes |
|------|-----|--------|
| Coal void | `#0A0706` | Clear color / deep bg |
| Iron | `#1C1410` | Floors, UI panels |
| Iron edge | `#3A2A22` | Lines |
| Ember | `#FF7A26` | Primary accent, perfect hits |
| Ember deep | `#E8451C` | Danger, lava |
| Molten gold | `#FFB347` | Heat high / rewards |
| Bone | `#F3EBE3` | Text |
| Ash | `#C4B4A4` | Secondary text |
| Silhouette | `#0D0A08` | Enemy bodies |

**Rule:** If it’s not in this table, it doesn’t ship in the slice.

---

## 2. Style keywords

- HellForge / Diablo UI energy without cloning Diablo  
- **Silhouette-first** enemies (readable in 1 second)  
- Ember edge lighting (rim = 1–2 px glow)  
- No photoreal; no muddy greys  
- UI: Cinzel titles if font embedded; otherwise bold geometric  

**Not this:** cute pastel, pure pixel-perfect NES, realistic gore photo textures.

---

## 3. Resolution & tech

| Asset | Spec |
|-------|------|
| Base PPU | 32 or 64 px/unit (pick one in Godot; prefer **32** for speed) |
| Player | ~48–64 px tall sprite sheet |
| Enemies | Same scale band |
| Tiles | 32×32 or 64×64  
| Export | PNG RGBA; power-of-two atlases where easy |
| VFX | Soft additive particles + simple meshes/quads |

---

## 4. Asset list (slice MVP)

### Environment (`art/env/`)

- [ ] `tile_floor_coal` ×3 variants  
- [ ] `tile_wall_iron`  
- [ ] `tile_grate`  
- [ ] `tile_lava` (animated 2–4 frames)  
- [ ] `prop_anvil`, `prop_chain`, `prop_bellows`  
- [ ] `door_boss`  

### Player (`art/player/`)

- [ ] Idle (2–4 frame)  
- [ ] Run (4–6)  
- [ ] Strike light (3–4)  
- [ ] Dash (3)  
- [ ] Hit / death  

### Enemies (`art/enemies/`)

- [ ] Wretch: idle, walk, swipe, death  
- [ ] Archer: idle, draw, fire, death  
- [ ] Guard: idle, block, open, overhead, death  
- [ ] Boss: idle, slam windup, slam, stagger, death  

### VFX (`art/vfx/`)

- [ ] Hit spark  
- [ ] Perfect-hit ring (beat)  
- [ ] Dash dust  
- [ ] Death sparks  
- [ ] Heat aura (soft)  

### UI (`art/ui/`)

- [ ] Heat meter bar  
- [ ] Beat pip / halo  
- [ ] HP pips  
- [ ] Damage number font style (ember / bone)  
- [ ] Pause panel  

---

## 5. Production pipeline

1. Blockout with colored rectangles in Godot (Claude)  
2. Silhouette drafts (Grok — AI draft OK)  
3. Human pass: edge, palette enforce, readability  
4. Import + slice  
5. Juice pass last  

**AI policy (game marketing):** drafts only; final feel must look directed. Pitch leads with music + craft.

---

## 6. Reference anchors (internal)

- HellForge crest / site ember UI  
- Brand coal backgrounds  
- Not external IP  

---

*Art bible v1 — start blockout; replace placeholders as sheets land.*
