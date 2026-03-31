"""
Analyze gripperlite.step to identify:
1. The mounting surface (where a new plate attaches)
2. Two through-holes (location and diameter) for projecting into the new plate
"""

import cadquery as cq
from OCP.BRepAdaptor import BRepAdaptor_Surface
from OCP.GeomAbs import GeomAbs_Plane, GeomAbs_Cylinder
from OCP.GProp import GProp_GProps
from OCP.BRepGProp import BRepGProp
import json, math


def analyze_step(filepath: str) -> dict:
    result = cq.importers.importStep(filepath)
    bb = result.val().BoundingBox()
    print(f"Bounding box: X=[{bb.xmin:.2f}, {bb.xmax:.2f}], "
          f"Y=[{bb.ymin:.2f}, {bb.ymax:.2f}], Z=[{bb.zmin:.2f}, {bb.zmax:.2f}]")

    all_faces = result.faces().vals()
    print(f"Total faces: {len(all_faces)}")

    # ── Classify every face ──────────────────────────────────────────
    planar_faces = []
    cylindrical_faces = []

    for i, face in enumerate(all_faces):
        adaptor = BRepAdaptor_Surface(face.wrapped)
        props = GProp_GProps()
        BRepGProp.SurfaceProperties_s(face.wrapped, props)
        area = props.Mass()
        com = props.CentreOfMass()

        if adaptor.GetType() == GeomAbs_Plane:
            plane = adaptor.Plane()
            n = plane.Axis().Direction()
            loc = plane.Location()
            planar_faces.append({
                "idx": i, "area": round(area, 4),
                "normal": (round(n.X(), 3), round(n.Y(), 3), round(n.Z(), 3)),
                "location": (round(loc.X(), 3), round(loc.Y(), 3), round(loc.Z(), 3)),
            })

        elif adaptor.GetType() == GeomAbs_Cylinder:
            cyl = adaptor.Cylinder()
            loc = cyl.Location()
            axis = cyl.Axis().Direction()
            r = cyl.Radius()
            cylindrical_faces.append({
                "idx": i, "radius": round(r, 4), "diameter": round(2 * r, 4),
                "axis": (round(axis.X(), 3), round(axis.Y(), 3), round(axis.Z(), 3)),
                "center": (round(loc.X(), 3), round(loc.Y(), 3), round(loc.Z(), 3)),
                "com": (round(com.X(), 3), round(com.Y(), 3), round(com.Z(), 3)),
                "area": round(area, 4),
            })

    # ── Identify the mounting surface ────────────────────────────────
    # The largest downward-facing planar face at Z ≈ 0 is the mounting interface.
    bottom_faces = [
        f for f in planar_faces
        if abs(f["location"][2]) < 1.0 and abs(f["normal"][2]) > 0.9
    ]
    mounting_face = max(bottom_faces, key=lambda f: f["area"])
    print(f"\n{'='*60}")
    print(f"MOUNTING SURFACE: Face {mounting_face['idx']}")
    print(f"  Z        = {mounting_face['location'][2]:.3f} mm")
    print(f"  Normal   = {mounting_face['normal']}")
    print(f"  Area     = {mounting_face['area']:.2f} mm²")
    print(f"{'='*60}")

    # ── Identify through-holes in the base plate ─────────────────────
    # These are Z-axis cylinders near the base whose surfaces span the
    # base-plate thickness (Z ≈ 0 → 3.1 mm).  r = 3.2 mm at X = ±31.5.
    # Group by (rounded X, rounded Y, rounded radius).
    from collections import defaultdict

    groups = defaultdict(list)
    for c in cylindrical_faces:
        ax = c["axis"]
        # Z-aligned holes only
        if abs(abs(ax[2]) - 1.0) < 0.01:
            key = (round(c["center"][0], 0), round(c["center"][1], 0), round(c["radius"], 1))
            groups[key].append(c)

    # At each (X,Y) location, multiple concentric cylinders form a stepped
    # hole: the smallest-radius cylinder is the bolt through-hole; larger
    # ones are counterbores.  We want only the through-holes.
    from itertools import groupby as _gb

    # Collect all base-region Z-axis cylinders
    base_cyls = []
    for key, cyls in groups.items():
        avg_com_z = sum(c["com"][2] for c in cyls) / len(cyls)
        r = key[2]
        if 1.5 <= r <= 5.0 and avg_com_z < 10.0:
            base_cyls.append({
                "xy": (key[0], key[1]),
                "radius": cyls[0]["radius"], "diameter": cyls[0]["diameter"],
                "avg_com_z": round(avg_com_z, 3),
                "faces": [c["idx"] for c in cyls],
            })

    # Group by (X, Y) location, keep only the smallest radius (the through-hole)
    base_cyls.sort(key=lambda h: (h["xy"], h["radius"]))
    base_holes = []
    for xy, grp in _gb(base_cyls, key=lambda h: h["xy"]):
        grp = list(grp)
        through = grp[0]  # smallest radius at this location
        counterbores = grp[1:]
        entry = {
            "x": through["xy"][0], "y": through["xy"][1],
            "radius": through["radius"], "diameter": through["diameter"],
            "avg_com_z": through["avg_com_z"],
            "faces": through["faces"],
        }
        if counterbores:
            entry["counterbore_diameter"] = counterbores[0]["diameter"]
        base_holes.append(entry)

    base_holes.sort(key=lambda h: h["x"])

    print(f"\nTHROUGH-HOLES IN BASE PLATE ({len(base_holes)} found):")
    for h in base_holes:
        cb = f", counterbore d={h['counterbore_diameter']:.2f}" if "counterbore_diameter" in h else ""
        print(f"  Hole at X={h['x']:.1f}, Y={h['y']:.1f}")
        print(f"    Through-hole diameter = {h['diameter']:.2f} mm{cb}")
        print(f"    Cylindrical face indices: {h['faces']}")
    print(f"{'='*60}")

    summary = {
        "mounting_surface": {
            "face_idx": mounting_face["idx"],
            "z": mounting_face["location"][2],
            "normal": mounting_face["normal"],
            "area_mm2": mounting_face["area"],
        },
        "through_holes": [
            {
                "x": h["x"], "y": h["y"],
                "diameter_mm": h["diameter"], "radius_mm": h["radius"],
                **({"counterbore_diameter_mm": h["counterbore_diameter"]}
                   if "counterbore_diameter" in h else {}),
            }
            for h in base_holes
        ],
    }
    return summary


if __name__ == "__main__":
    summary = analyze_step("/home/phil/ClaudeCAD/gripperlite.step")
    print("\n── JSON summary ──")
    print(json.dumps(summary, indent=2))
    # Persist for downstream scripts
    with open("/home/phil/ClaudeCAD/gripperlite_analysis.json", "w") as f:
        json.dump(summary, f, indent=2)
    print("\nSaved to gripperlite_analysis.json")
