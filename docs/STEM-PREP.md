# CINDERFORGE — Stem Prep Notes (slice soundtrack)

**Tracks (Director locked):**  
1. Weaponized Mind  
2. Chain Reaction  
3. Undeath **or** Ruinous Wonder (pick one for boss; reserve the other)

**Source:** `C:\WPAI\Music\Tracks\<Name>\Stems\`

---

## Heat → layer recipe (all tracks)

| Heat | Layers audible (approx) |
|------|-------------------------|
| 0–25 | Drums + Bass |
| 26–50 | + Guitar |
| 51–75 | + Percussion/Synth/Keys |
| 76–100 | + Lead Vocals (+ Backing if present) |

---

## Per-track stem map

### Weaponized Mind (8 stems) — **primary combat track**

| File | Bus |
|------|-----|
| `2 Drums.wav` | always |
| `3 Bass.wav` | always / low heat |
| `4 Guitar.wav` | mid |
| `5 Keyboard.wav` / `6 Synth.wav` / `7 Other.wav` | high mid |
| `0 Lead Vocals.wav` | high heat |
| `1 Backing Vocals.wav` | overheat garnish |

### Chain Reaction (7 stems) — **arena B / intensity**

| File | Bus |
|------|-----|
| `1 Drums.wav` | always |
| `2 Bass.wav` | low |
| `3 Guitar.wav` | mid |
| `4 Percussion.wav` + `5 Synth.wav` | high mid |
| `0 Lead Vocals.wav` | high |

### Undeath (8) / Ruinous Wonder (9) — **boss**

Prefer **Undeath** for darker boss tone; **Ruinous Wonder** if more melodic climax wanted.  
Same drums→bass→guitar→vox ramp.

---

## Godot import checklist

1. Copy selected stems into `Cinderforge/audio/stems/<track_slug>/`  
2. Convert to **OGG** (recommended for interactive music features)  
3. Same start sample; trim leading silence identically across stems  
4. Create `bpm.txt` + `offset_ms.txt` per track (tap-tempo once)  
5. Wire `AudioStreamSynchronized` with one player; set volumes from Heat  

### Placeholder BPM (replace after tap)

| Track | Guess BPM (verify!) |
|-------|---------------------|
| Weaponized Mind | ~140–160 metal (tap!) |
| Chain Reaction | ~140–170 (tap!) |
| Undeath / Ruinous Wonder | tap |

**Do not ship with guessed BPM** — wrong BPM kills the whole feel gate.

---

## Rights / marketing

- Catalog is Suno Pro + human-directed; game pitch leads with **original metal + craft**.  
- Avoid “AI-generated game” as the Steam headline.

---

*Stem prep v1 — Claude scaffold can follow this map; Grok can help convert OGGs on request.*
