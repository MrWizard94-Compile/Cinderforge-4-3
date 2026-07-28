# CINDERFORGE — Combat Design (Vertical Slice)

**Owner:** Executor (Grok) · **Engine:** Godot 4 · **Status:** Design locked for slice  
**Principle:** Everything works off-beat; **everything feels better on-beat** (Hi-Fi Rush).  
Music Heat is the reward (Hellsinger), not a hard fail state (not default NecroDancer).

---

## 1. Player (forged revenant)

| Action | Input (default) | On-beat bonus | Off-beat |
|--------|-----------------|---------------|----------|
| Light strike | Attack | ×1.5 dmg, +Heat | ×1.0 dmg, little/no Heat |
| Heavy strike | Attack hold / alt | ×2.0 dmg, +more Heat, longer windup snaps to beat if close | Weaker, more punishable |
| Dash | Dash | i-frames + short shockwave | Short dash only, no i-frames |
| Special (1 for slice) | Ability | Big Heat dump / room clear light | Cooldown only, weak |

**Heat (0–100)**  
- Builds on on-beat hits and multi-kills  
- Decays when idle or missing windows  
- Drives stem layers + enemy aggression  
- At 100: brief **Overheat** (extra damage + full mix); then soft decay  

**Timing window (v0)**  
- Perfect: ±40 ms  
- Good: ±90 ms  
- Miss: outside good  

Tune in playtest — pad windows first for “feel good,” tighten later.

---

## 2. Three enemies

### E1 — Cinder Wretch (fodder)

| | |
|--|--|
| **Role** | Cannon fodder, teach on-beat |
| **HP** | Low (2 light hits / 1 heavy on-beat) |
| **Behavior** | Walk toward player; telegraphed swipe every 2 beats |
| **On-beat player reward** | Die in clean 1–2 hits; small Heat |
| **Art** | Small hunched silhouette, ember eyes, coal body |
| **Audio cue** | Soft hiss before swipe |

### E2 — Slag Archer (ranged)

| | |
|--|--|
| **Role** | Force dash timing |
| **HP** | Medium |
| **Behavior** | Keeps distance; fires molten bolt on a beat; bolt travels on beat ticks |
| **On-beat player reward** | Dash through bolt on beat → reflect or nullify (juice) |
| **Art** | Tall thin silhouette, bow of bent rebar, glowing projectile |
| **Audio cue** | String creak / forge ping on draw |

### E3 — Anvil Guard (tank)

| | |
|--|--|
| **Role** | Block / parry fantasy without full parry system |
| **HP** | High |
| **Behavior** | Shield facing player; opens guard every 4th beat for 1 beat; heavy overhead if player idles |
| **On-beat player reward** | Heavy into open guard = stagger + big Heat |
| **Art** | Wide silhouette, slab shield, hammer arm |
| **Audio cue** | Metal clang on block |

---

## 3. Mini-boss — The First Hammer

| | |
|--|--|
| **Role** | Slice climax; full Heat + full track |
| **HP** | High; 2 phases |
| **Phase 1** | Alternates Wretch-swarm call + hammer slam (3-beat windup) |
| **Phase 2** (≤50% HP) | Faster slams; arena gains lava rims; music should be near-full layers |
| **Weak point** | After slam (recovery beat) — heavy on-beat = chunk damage |
| **Art** | Giant forge-golem, one arm hammer, chest furnace glow |
| **Fail state** | Player death → run reset; boss music restarts clean |

---

## 4. Juice checklist (must-have for “finished” feel)

| Priority | Effect |
|----------|--------|
| P0 | Hitstop 2–4 frames on on-beat hit |
| P0 | Screen shake scaled by Heat |
| P0 | Damage numbers (perfect = ember color) |
| P0 | Beat pulse on player silhouette (subtle) |
| P1 | Enemy flash white on hit |
| P1 | Death dissolve to sparks |
| P1 | Dash afterimage |
| P1 | Heat VFX density scales 0–100 |
| P2 | Chromatic aberration on Overheat |
| P2 | Bass thump SFX layered on perfect |

---

## 5. Godot integration notes (for Claude scaffold)

```
Player
  Attack() -> RhythmCore.EvaluateWindow() -> apply mult + Heat
Enemy
  Telegraph on beat index; attack resolves next beat
HeatMeter
  0..100; emits heat_changed(value)
StemMixer
  maps heat bands -> AudioStreamSynchronized volume per bus
```

**Enemy attacks should schedule on integer beats** so the world feels locked to the track even when the player freestyles.

---

## 6. Slice room flow

1. **Tutorial alcove** — one Wretch, beat indicator visible, no fail  
2. **Arena A** — mixed Wretches + 1 Archer  
3. **Reward** — pick one of two: wider window OR more Heat gain  
4. **Arena B** — Archers + Anvil Guard  
5. **Boss gate** — short corridor, music stinger  
6. **Boss** — First Hammer  

Die anywhere after alcove → restart run from Arena A with same loadout (true roguelite later; slice can restart whole path).

---

*Executor combat design v1 — extend when Godot skeleton arrives.*
