# 3D Printing Workflow: Dremel DigiLab 3D45

This document describes the full autonomous 3D printing pipeline from STL to
physical part, as executed by Claude Code. It includes safety checks learned
from an actual crash incident.

## Printer

- **Model**: Dremel DigiLab 3D45-01
- **Build volume**: 255 x 155 x 170 mm (center-zero coordinate system)
- **Nozzle**: 0.4 mm, 1.75 mm filament (PLA/PETG)
- **Heated glass bed**, enclosed chamber with internal LED
- **Network**: Ethernet at 192.168.1.222 (static or DHCP)
- **No authentication** on the REST API

## Available Slicers

### 1. Dremel DigiLab 3D Slicer (RECOMMENDED)

- Location: `~/.local/bin/DremelSlicer.AppImage`
- Extract: `cd /tmp && ~/.local/bin/DremelSlicer.AppImage --appimage-extract`
  then rename `squashfs-root` to `dremel-slicer`
- Binary: `/tmp/dremel-slicer/bin/dremel-3d-slicer`
- Built-in 3D45 profiles at `/tmp/dremel-slicer/resources/profiles/Dremel/`
- **Fork of OrcaSlicer** — supports `--slice 0` for headless CLI operation
- Uses manufacturer-tested start/end gcode and print profiles
- **Coordinate system is already correct** (center-zero, +-127.5 x +-77.5)

**CLI example:**
```bash
/tmp/dremel-slicer/bin/dremel-3d-slicer \
  --load-settings "machine.json;process.json;filament.json" \
  --slice 0 \
  --outputdir /home/phil/ClaudeCAD \
  /home/phil/ClaudeCAD/part.stl
```

Profile files (under `/tmp/dremel-slicer/resources/profiles/Dremel/`):
- Machine: `machine/Dremel 3D45 0.4 nozzle.json`
- Process: `process/0.20mm Standard @Dremel 3D45 0.4.json`
- Filament: `filament/Dremel PLA @3D45.json`

Output lands in `--outputdir` as `plate_1.gcode`.

### 2. CuraEngine 5.12

- Location: `~/.local/bin/Cura.AppImage`
- Extract: `cd /tmp && ~/.local/bin/Cura.AppImage --appimage-extract`
- Binary: `/tmp/squashfs-root/CuraEngine` (requires special loader invocation)
- Definition file: `dremel_3d45.def.json` in the repo

**CuraEngine requires a custom loader** because of bundled library dependencies:
```bash
CR=/tmp/squashfs-root/runtime/compat
LP="$CR:$CR/lib/x86_64-linux-gnu:$CR/usr/lib/x86_64-linux-gnu:/tmp/squashfs-root"
export CURA_ENGINE_SEARCH_PATH=/tmp/squashfs-root/share/cura/resources/definitions:/tmp/squashfs-root/share/cura/resources/extruders
$CR/lib64/ld-linux-x86-64.so.2 --library-path $LP /tmp/squashfs-root/CuraEngine \
  slice -j dremel_3d45.def.json -l part.stl -o part.gcode \
  -s roofing_layer_count=1 -s flooring_layer_count=1
```

**Critical settings in `dremel_3d45.def.json`:**
- `machine_center_is_zero: true` — MUST be true (see Crash Incident below)
- `machine_width: 255`, `machine_depth: 155`
- Start gcode must NOT contain Cura template placeholders like
  `{material_bed_temperature_layer_0}` — CuraEngine CLI does not expand them.
  Use literal values or the reference start gcode from
  `metalman3797/Cura-Dremel-Printer-Plugin`.

## STL Preparation

Parts designed in OpenSCAD are exported to STL via:
```bash
openscad -o part.stl export_part.scad
```

If the part needs reorientation for printing (e.g., laying a tilted cut face
flat on the bed), create a wrapper `.scad` that imports the STL, applies
`rotate()` and `translate()` to place the flat face at z=0, then export that
to a new `part_print.stl`.

## Pre-Print Safety Checks (MANDATORY)

### Step 1: STL bounding box

Parse the STL to determine the expected XY footprint:
```python
import re
xs, ys, zs = [], [], []
with open("part.stl") as f:
    for line in f:
        m = re.match(r'\s*vertex\s+([-\d.e+]+)\s+([-\d.e+]+)\s+([-\d.e+]+)', line)
        if m:
            xs.append(float(m.group(1)))
            ys.append(float(m.group(2)))
            zs.append(float(m.group(3)))
print(f"X: {min(xs):.2f} .. {max(xs):.2f}")
print(f"Y: {min(ys):.2f} .. {max(ys):.2f}")
print(f"Z: {min(zs):.2f} .. {max(zs):.2f}")
```
(For binary STLs, use struct.unpack with 50-byte triangle records.)

### Step 2: Gcode bounds check

After slicing, extract ALL G0/G1 X/Y/Z coordinates and verify they fall
within the Dremel bed limits:
- **X**: -127.5 to +127.5
- **Y**: -77.5 to +77.5
- **Z**: 0 to 170

```python
import re
xs, ys = [], []
with open("part.gcode") as f:
    for line in f:
        if re.match(r'^G[01]\s', line):
            xm = re.search(r'X([-\d.]+)', line)
            ym = re.search(r'Y([-\d.]+)', line)
            if xm: xs.append(float(xm.group(1)))
            if ym: ys.append(float(ym.group(1)))
if max(xs) > 127.5 or min(xs) < -127.5:
    raise ValueError(f"X out of bounds: {min(xs):.2f}..{max(xs):.2f}")
if max(ys) > 77.5 or min(ys) < -77.5:
    raise ValueError(f"Y out of bounds: {min(ys):.2f}..{max(ys):.2f}")
print("PASS: all coordinates within bed limits")
```

### Step 3: Cross-slicer validation (recommended)

Slice the same STL with BOTH the Dremel Slicer and CuraEngine. Compare the
first-layer XY bounding boxes. They should be similar in size (within a few
mm) and both well inside the bed limits. If one slicer produces coordinates
far from the other, investigate before printing.

### Step 4: Visual inspection

Suggest the user open the gcode in a web-based viewer such as:
- https://gcode.ws/
- https://ncviewer.com/

Configure the viewer with bed size 255x155, center-zero, and visually confirm
the toolpath is centered on the bed.

**DO NOT upload gcode to the printer until steps 1-2 pass and the user has
had the opportunity to review.**

## Printer REST API

All commands are `POST http://192.168.1.222/command` with the command as the
POST body (not JSON, just the raw string).

| Command | Purpose |
|---|---|
| `GETPRINTERSTATUS` | Returns JSON: temps, progress, job state |
| `GETPRINTERINFO` | Firmware, serial, IP, model |
| `PRINT=filename.gcode` | Start a print |
| `PAUSE` | Pause active print |
| `RESUME` | Resume paused print |
| `CANCEL` or `CANCEL=filename.gcode` | Cancel/abort print |

### File upload
```bash
curl -s -F "print_file=@part.gcode" http://192.168.1.222/print_file_uploads
```

### Camera
- Snapshot: `GET http://192.168.1.222:10123/?action=snapshot` (JPEG)
- Stream: `GET http://192.168.1.222:10123/?action=stream` (MJPEG)

## Print Execution

1. Upload gcode: `curl -F "print_file=@part.gcode" http://192.168.1.222/print_file_uploads`
2. Start print: `curl -X POST -d "PRINT=part.gcode" http://192.168.1.222/command`
3. Monitor: poll `GETPRINTERSTATUS` for progress, temps, job state
4. Camera: grab snapshots to confirm first-layer adhesion

### Important firmware behaviors

- The printer runs **Z-probe calibration** before each print. During
  calibration, `GETPRINTERSTATUS` may show `status=busy` with no job name
  and zero temp targets. **Do not send CANCEL during calibration** — it will
  abort the print silently.
- After a print completes (or fails), the touchscreen shows a **"BUILD
  COMPLETE. CLEAR THE BUILD PLATFORM."** modal. This modal **blocks all new
  print jobs** until the user physically taps ACCEPT on the touchscreen.
  There is **no API command to dismiss this dialog**. The PRINT command will
  return `{"error_code":200,"message":"success"}` but the print will not
  actually start.
- If PRINT returns `{"error_code":404,"message":"busy"}`, the printer is in
  a non-idle state (calibrating, dialog up, etc.). Do not retry in a loop —
  ask the user to check the touchscreen.

### Sequential multi-part printing

If printing multiple parts (e.g., 1 base + 2 clamps), they MUST be printed
as **separate sequential jobs**, not combined on one plate (unless a single
combined gcode is sliced). Between jobs:
1. Wait for "BUILD COMPLETE" — user must tap ACCEPT
2. User clears the part from the bed
3. Optionally re-apply glue stick (PVA lasts many prints, 24+ hours is fine)
4. Upload and start the next gcode

## Crash Incident Report (2026-04-08)

### What happened

The print head slewed to X~149, Y~64 (non-center-zero coordinates) which
placed it far off the right edge of the physical bed. The head crashed into
the raised plastic rim of the glass build plate, causing grinding. The user
had to emergency power-off.

### Root cause

The `dremel_3d45.def.json` file for CuraEngine was missing
`"machine_center_is_zero": { "default_value": true }`. Without this setting,
CuraEngine output coordinates in a 0..254 / 0..152 frame (origin at front-left
corner). The Dremel 3D45 firmware interprets all coordinates as center-zero
(origin at bed center, +-127.5 / +-77.5). So a coordinate like X=149 — which
CuraEngine intended as "149mm from the left edge" — was interpreted by the
firmware as "149mm from center," which is 21.5mm past the right edge of the
bed.

### Additional contributing factor

The CuraEngine start gcode contained Cura template placeholders like
`{material_bed_temperature_layer_0}`. CuraEngine's CLI mode does NOT expand
these. The Dremel firmware received the literal string `M190 S{material_...}`
as the temperature target, which it could not parse. On the first attempt,
this caused the printer to declare "BUILD COMPLETE" immediately without
printing. The coordinate-frame bug was only discovered on the second attempt
after the template issue was fixed.

### Lessons

1. **Always include `machine_center_is_zero: true`** in the Dremel def.json.
2. **Always run the gcode bounds check** (Step 2 above) before uploading.
3. **Never use Cura template placeholders** in start/end gcode for CLI slicing.
4. **Prefer the Dremel Slicer** — it ships with manufacturer-tested profiles
   that have the correct coordinate system, start gcode, and print parameters.
5. **Cross-validate with two slicers** when possible.
6. **Do not send CANCEL during calibration** — it silently aborts.
7. **Do not retry PRINT in a loop** if the printer is busy or has a dialog up.
