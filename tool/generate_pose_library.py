#!/usr/bin/env python3
"""Generates original vector (SVG) pose-reference silhouettes for the
Help me Pose built-in library, plus a JSON manifest describing them.

These are procedurally generated stick/capsule figures -- original artwork
created for this app, not derived from any photograph or third-party asset --
so there is no copyright/licensing concern distributing them with the app.

Run: python3 gen_poses.py <output_assets_dir>
"""
import json
import math
import os
import sys

W, H = 600, 900
STROKE = "#15151A"
BG = "none"


def pt(x, y):
    return (round(x, 1), round(y, 1))


def add(p, dx, dy):
    return (p[0] + dx, p[1] + dy)


def project(origin, length, angle_deg):
    """angle measured from vertical-down = 0, positive = clockwise (screen coords)."""
    rad = math.radians(angle_deg)
    return (origin[0] + length * math.sin(rad), origin[1] + length * math.cos(rad))


def limb(a, b, width):
    return f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" stroke="{STROKE}" stroke-width="{width}" stroke-linecap="round"/>'


def circle(c, r, fill=STROKE):
    return f'<circle cx="{c[0]}" cy="{c[1]}" r="{r}" fill="{fill}"/>'


def svg_wrap(body, viewbox=f"0 0 {W} {H}"):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{viewbox}" '
        f'width="{viewbox.split()[2]}" height="{viewbox.split()[3]}">\n{body}\n</svg>\n'
    )


def figure(
    cx=300,
    hip_y=560,
    torso_len=220,
    torso_lean=0,
    neck_len=30,
    head_r=42,
    shoulder_w=95,
    hip_w=70,
    upper_arm=110,
    lower_arm=100,
    upper_leg=175,
    lower_leg=175,
    l_shoulder_angle=15,
    l_elbow_angle=10,
    r_shoulder_angle=-15,
    r_elbow_angle=-10,
    l_hip_angle=8,
    l_knee_angle=4,
    r_hip_angle=-8,
    r_knee_angle=-4,
    head_tilt=0,
    scale=1.0,
    torso_w=46,
):
    hip_c = (cx, hip_y)
    neck = project(hip_c, -torso_len, torso_lean)
    head_c = project(neck, -(neck_len + head_r * 0.6), torso_lean + head_tilt)

    shoulder_perp = torso_lean + 90
    shoulder_l = project(neck, shoulder_w / 2, shoulder_perp)
    shoulder_r = project(neck, shoulder_w / 2, shoulder_perp + 180)

    hip_perp = torso_lean + 90
    hip_l = project(hip_c, hip_w / 2, hip_perp)
    hip_r = project(hip_c, hip_w / 2, hip_perp + 180)

    elbow_l = project(shoulder_l, upper_arm, torso_lean + l_shoulder_angle)
    hand_l = project(elbow_l, lower_arm, torso_lean + l_shoulder_angle + l_elbow_angle)
    elbow_r = project(shoulder_r, upper_arm, torso_lean + r_shoulder_angle)
    hand_r = project(elbow_r, lower_arm, torso_lean + r_shoulder_angle + r_elbow_angle)

    knee_l = project(hip_l, upper_leg, l_hip_angle)
    foot_l = project(knee_l, lower_leg, l_hip_angle + l_knee_angle)
    knee_r = project(hip_r, upper_leg, r_hip_angle)
    foot_r = project(knee_r, lower_leg, r_hip_angle + r_knee_angle)

    parts = [
        limb(hip_l, knee_l, 30),
        limb(knee_l, foot_l, 26),
        limb(hip_r, knee_r, 30),
        limb(knee_r, foot_r, 26),
        limb(shoulder_l, elbow_l, 22),
        limb(elbow_l, hand_l, 18),
        limb(shoulder_r, elbow_r, 22),
        limb(elbow_r, hand_r, 18),
        limb(hip_l, hip_r, torso_w),
        limb(neck, hip_c, torso_w),
        limb(shoulder_l, shoulder_r, torso_w * 0.9),
        circle(hand_l, 11),
        circle(hand_r, 11),
        circle(foot_l, 13),
        circle(foot_r, 13),
        circle(head_c, head_r),
    ]
    return "\n".join(parts)


def hand_pose(mode="open"):
    """Close-up stylised hand/arm silhouette for the Hand Poses category."""
    wrist = (300, 620)
    palm_c = (300, 500)
    parts = [limb((300, 820), wrist, 34), circle(palm_c, 58)]
    base_angles = {
        "open": [-40, -14, 6, 26, 46],
        "fist": [-18, -6, 4, 14, 24],
        "point": [-46, -8, 60, 70, 78],
        "peace": [-46, -18, 55, 30, 46],
        "wave": [-30, -10, 10, 30, 50],
        "ok": [-40, -8, 8, 26, 46],
    }
    lens = {
        "open": [95, 115, 122, 112, 92],
        "fist": [34, 40, 42, 40, 34],
        "point": [40, 118, 44, 40, 34],
        "peace": [40, 118, 118, 42, 34],
        "wave": [95, 112, 118, 108, 88],
        "ok": [70, 62, 118, 110, 90],
    }
    angles = base_angles.get(mode, base_angles["open"])
    lengths = lens.get(mode, lens["open"])
    for ang, ln in zip(angles, lengths):
        tip = project(palm_c, ln, ang - 90)
        parts.append(limb(palm_c, tip, 15))
        parts.append(circle(tip, 8))
    return "\n".join(parts)


def couple_pose(variant=0):
    presets = [
        dict(cx=190, l_shoulder_angle=40, l_elbow_angle=-10, r_shoulder_angle=-10, r_elbow_angle=-6),
        dict(cx=410, l_shoulder_angle=10, l_elbow_angle=-6, r_shoulder_angle=-40, r_elbow_angle=10),
    ]
    p0 = dict(presets[0])
    p1 = dict(presets[1])
    if variant % 5 == 1:
        p0["torso_lean"] = 6
        p1["torso_lean"] = -6
    elif variant % 5 == 2:
        p0["l_shoulder_angle"] = 70
        p1["r_shoulder_angle"] = -70
    elif variant % 5 == 3:
        p0["hip_y"] = 560
        p1["hip_y"] = 540
    elif variant % 5 == 4:
        p0["head_tilt"] = 10
        p1["head_tilt"] = -10
    a = figure(scale=0.82, torso_len=200, upper_arm=95, lower_arm=88, upper_leg=155, lower_leg=155, **p0)
    b = figure(scale=0.82, torso_len=200, upper_arm=95, lower_arm=88, upper_leg=155, lower_leg=155, **p1)
    return a + "\n" + b


def portrait_pose(head_tilt=0, shoulder_drop=0):
    neck = (300, 520)
    head_c = project(neck, 70, head_tilt)
    shoulder_l = project(neck, 130, 90 + shoulder_drop)
    shoulder_r = project(neck, 130, -90 + shoulder_drop)
    torso_bottom = (300, 900)
    parts = [
        limb(shoulder_l, torso_bottom, 60),
        limb(shoulder_r, torso_bottom, 60),
        limb(shoulder_l, shoulder_r, 70),
        limb(neck, (300, 470), 40),
        circle(head_c, 78),
    ]
    return "\n".join(parts)


CATEGORY_BUILDERS = {}


def register(name):
    def deco(fn):
        CATEGORY_BUILDERS[name] = fn
        return fn

    return deco


@register("standing")
def build_standing(i):
    arm_variants = [
        dict(l_shoulder_angle=12, r_shoulder_angle=-12, l_elbow_angle=6, r_elbow_angle=-6),
        dict(l_shoulder_angle=35, r_shoulder_angle=-12, l_elbow_angle=-60, r_elbow_angle=-6),
        dict(l_shoulder_angle=100, r_shoulder_angle=-100, l_elbow_angle=-20, r_elbow_angle=20),
        dict(l_shoulder_angle=170, r_shoulder_angle=-15, l_elbow_angle=0, r_elbow_angle=-6),
        dict(l_shoulder_angle=25, r_shoulder_angle=-25, l_elbow_angle=-90, r_elbow_angle=90),
        dict(l_shoulder_angle=8, r_shoulder_angle=-8, l_elbow_angle=4, r_elbow_angle=-4),
        dict(l_shoulder_angle=60, r_shoulder_angle=-15, l_elbow_angle=-100, r_elbow_angle=-6),
        dict(l_shoulder_angle=15, r_shoulder_angle=-60, l_elbow_angle=6, r_elbow_angle=100),
        dict(l_shoulder_angle=175, r_shoulder_angle=-175, l_elbow_angle=0, r_elbow_angle=0),
        dict(l_shoulder_angle=20, r_shoulder_angle=-45, l_elbow_angle=-10, r_elbow_angle=-90),
    ]
    leg_spread = [4, 8, 14, 4, 20, 6, 10, 4, 8, 14][i]
    v = arm_variants[i]
    return figure(l_hip_angle=leg_spread, r_hip_angle=-leg_spread, torso_lean=[0, 2, -3, 0, 4, 0, -2, 3, 0, -4][i], **v)


@register("sitting")
def build_sitting(i):
    hip_y = 480
    variants = [
        dict(l_hip_angle=85, r_hip_angle=-85, l_knee_angle=-88, r_knee_angle=88, l_shoulder_angle=10, r_shoulder_angle=-10, l_elbow_angle=4, r_elbow_angle=-4),
        dict(l_hip_angle=85, r_hip_angle=-85, l_knee_angle=-88, r_knee_angle=88, l_shoulder_angle=100, r_shoulder_angle=-10, l_elbow_angle=-90, r_elbow_angle=-4),
        dict(l_hip_angle=95, r_hip_angle=-70, l_knee_angle=-70, r_knee_angle=95, l_shoulder_angle=20, r_shoulder_angle=-20, l_elbow_angle=-30, r_elbow_angle=30),
        dict(l_hip_angle=80, r_hip_angle=-80, l_knee_angle=-95, r_knee_angle=95, l_shoulder_angle=90, r_shoulder_angle=-90, l_elbow_angle=-90, r_elbow_angle=90),
        dict(l_hip_angle=85, r_hip_angle=-85, l_knee_angle=-88, r_knee_angle=88, l_shoulder_angle=6, r_shoulder_angle=-40, l_elbow_angle=4, r_elbow_angle=-100),
        dict(l_hip_angle=88, r_hip_angle=-60, l_knee_angle=-88, r_knee_angle=110, l_shoulder_angle=15, r_shoulder_angle=-15, l_elbow_angle=-10, r_elbow_angle=10),
        dict(l_hip_angle=85, r_hip_angle=-85, l_knee_angle=-88, r_knee_angle=88, l_shoulder_angle=45, r_shoulder_angle=-45, l_elbow_angle=-110, r_elbow_angle=110),
        dict(l_hip_angle=70, r_hip_angle=-95, l_knee_angle=-95, r_knee_angle=70, l_shoulder_angle=10, r_shoulder_angle=-10, l_elbow_angle=4, r_elbow_angle=-4, torso_lean=8),
        dict(l_hip_angle=85, r_hip_angle=-85, l_knee_angle=-88, r_knee_angle=88, l_shoulder_angle=8, r_shoulder_angle=-8, l_elbow_angle=4, r_elbow_angle=-4, torso_lean=-10),
        dict(l_hip_angle=85, r_hip_angle=-85, l_knee_angle=-88, r_knee_angle=88, l_shoulder_angle=170, r_shoulder_angle=-170, l_elbow_angle=0, r_elbow_angle=0),
    ]
    return figure(hip_y=hip_y, **variants[i])


@register("leaning")
def build_leaning(i):
    leans = [12, 16, -14, 18, -16, 14, -12, 20, -18, 15]
    arm = [
        dict(l_shoulder_angle=8, r_shoulder_angle=-8, l_elbow_angle=4, r_elbow_angle=-4),
        dict(l_shoulder_angle=100, r_shoulder_angle=-8, l_elbow_angle=-90, r_elbow_angle=-4),
        dict(l_shoulder_angle=8, r_shoulder_angle=-100, l_elbow_angle=4, r_elbow_angle=90),
        dict(l_shoulder_angle=170, r_shoulder_angle=-8, l_elbow_angle=0, r_elbow_angle=-4),
        dict(l_shoulder_angle=8, r_shoulder_angle=-170, l_elbow_angle=4, r_elbow_angle=0),
        dict(l_shoulder_angle=30, r_shoulder_angle=-100, l_elbow_angle=-20, r_elbow_angle=-80),
        dict(l_shoulder_angle=100, r_shoulder_angle=-30, l_elbow_angle=-80, r_elbow_angle=20),
        dict(l_shoulder_angle=15, r_shoulder_angle=-15, l_elbow_angle=8, r_elbow_angle=-8),
        dict(l_shoulder_angle=60, r_shoulder_angle=-60, l_elbow_angle=-100, r_elbow_angle=100),
        dict(l_shoulder_angle=8, r_shoulder_angle=-8, l_elbow_angle=4, r_elbow_angle=-4),
    ]
    return figure(torso_lean=leans[i], l_hip_angle=leans[i] * 0.6, r_hip_angle=-6, **arm[i])


@register("walking")
def build_walking(i):
    stride = [20, 28, 34, 24, 30, 38, 22, 32, 26, 36]
    s = stride[i]
    return figure(
        torso_lean=6,
        l_hip_angle=s,
        r_hip_angle=-s,
        l_knee_angle=-18,
        r_knee_angle=22,
        l_shoulder_angle=-s * 0.7,
        r_shoulder_angle=s * 0.7,
        l_elbow_angle=-20,
        r_elbow_angle=20,
        head_tilt=[0, 4, -4, 2, -2, 5, -5, 3, -3, 0][i],
    )


@register("full_body")
def build_full_body(i):
    variants = [
        dict(l_shoulder_angle=175, r_shoulder_angle=-175, l_hip_angle=20, r_hip_angle=-20),
        dict(l_shoulder_angle=170, r_shoulder_angle=-30, l_hip_angle=-10, r_hip_angle=10, l_elbow_angle=0, r_elbow_angle=-90),
        dict(l_shoulder_angle=90, r_shoulder_angle=-90, l_elbow_angle=90, r_elbow_angle=-90, l_hip_angle=40, r_hip_angle=-10, l_knee_angle=-90),
        dict(l_shoulder_angle=45, r_shoulder_angle=-160, l_hip_angle=-30, r_hip_angle=30, l_knee_angle=10, r_knee_angle=-60, torso_lean=-8),
        dict(l_shoulder_angle=160, r_shoulder_angle=-45, l_hip_angle=30, r_hip_angle=-30, l_knee_angle=-60, r_knee_angle=10, torso_lean=8),
        dict(l_shoulder_angle=10, r_shoulder_angle=-10, l_hip_angle=50, r_hip_angle=-6, l_knee_angle=-100, r_knee_angle=0, torso_lean=-6),
        dict(l_shoulder_angle=140, r_shoulder_angle=-140, l_elbow_angle=-80, r_elbow_angle=80, l_hip_angle=6, r_hip_angle=-6),
        dict(l_shoulder_angle=60, r_shoulder_angle=-60, l_elbow_angle=100, r_elbow_angle=-100, l_hip_angle=6, r_hip_angle=-46, l_knee_angle=0, r_knee_angle=90),
        dict(l_shoulder_angle=175, r_shoulder_angle=-40, l_elbow_angle=0, r_elbow_angle=90, l_hip_angle=14, r_hip_angle=-14, torso_lean=-4),
        dict(l_shoulder_angle=20, r_shoulder_angle=-20, l_hip_angle=8, r_hip_angle=-8, l_knee_angle=0, r_knee_angle=0),
    ]
    return figure(**variants[i])


@register("portrait")
def build_portrait(i):
    tilts = [0, 6, -6, 10, -10, 4, -4, 8, -8, 0]
    drops = [0, 4, -4, 6, -6, 0, 3, -3, 5, -5]
    return portrait_pose(head_tilt=tilts[i], shoulder_drop=drops[i])


@register("hand_poses")
def build_hand(i):
    modes = ["open", "fist", "point", "peace", "wave", "ok", "open", "point", "peace", "fist"]
    return hand_pose(modes[i])


@register("couple_poses")
def build_couple(i):
    return couple_pose(i)


@register("outdoor")
def build_outdoor(i):
    ground = f'<line x1="40" y1="860" x2="560" y2="860" stroke="{STROKE}" stroke-width="4" stroke-linecap="round" opacity="0.5"/>'
    sun = circle((500, 140), 34, fill=STROKE)
    base = build_full_body(i)
    return ground + "\n" + sun + "\n" + base


@register("creative")
def build_creative(i):
    variants = [
        dict(torso_lean=-22, l_shoulder_angle=170, r_shoulder_angle=-40, r_elbow_angle=-90, l_hip_angle=-20, r_hip_angle=30, l_knee_angle=20),
        dict(torso_lean=24, l_shoulder_angle=40, r_shoulder_angle=-170, l_elbow_angle=90, l_hip_angle=20, r_hip_angle=-30, r_knee_angle=-30),
        dict(l_shoulder_angle=90, r_shoulder_angle=-90, l_elbow_angle=90, r_elbow_angle=-90, l_hip_angle=60, r_hip_angle=-6, l_knee_angle=-110, head_tilt=-10),
        dict(l_shoulder_angle=175, r_shoulder_angle=-175, l_hip_angle=45, r_hip_angle=-45, l_knee_angle=-30, r_knee_angle=30, torso_lean=-10),
        dict(l_shoulder_angle=20, r_shoulder_angle=-160, r_elbow_angle=-100, l_hip_angle=-40, r_hip_angle=10, l_knee_angle=60, torso_lean=14, head_tilt=12),
        dict(l_shoulder_angle=100, r_shoulder_angle=-20, l_elbow_angle=-100, l_hip_angle=10, r_hip_angle=-50, r_knee_angle=90, torso_lean=-14),
        dict(l_shoulder_angle=160, r_shoulder_angle=-60, r_elbow_angle=90, l_hip_angle=30, r_hip_angle=-10, l_knee_angle=-40, head_tilt=-8),
        dict(l_shoulder_angle=6, r_shoulder_angle=-6, l_hip_angle=70, r_hip_angle=-70, l_knee_angle=-90, r_knee_angle=90, torso_lean=0),
        dict(l_shoulder_angle=140, r_shoulder_angle=-140, l_elbow_angle=-60, r_elbow_angle=60, l_hip_angle=-25, r_hip_angle=25, torso_lean=18, head_tilt=10),
        dict(l_shoulder_angle=90, r_shoulder_angle=-140, l_hip_angle=15, r_hip_angle=-45, l_knee_angle=0, r_knee_angle=-70, torso_lean=-16),
    ]
    return figure(**variants[i])


CATEGORY_META = {
    "standing": ("Standing", "Balanced, everyday standing poses ideal for portraits and lookbooks."),
    "sitting": ("Sitting", "Seated poses for chairs, steps, ledges and the floor."),
    "leaning": ("Leaning", "Relaxed poses leaning against a wall, doorway or railing."),
    "walking": ("Walking", "Mid-stride candid walking poses for natural movement."),
    "full_body": ("Full Body", "Dynamic full-figure poses showing the whole body."),
    "portrait": ("Portrait", "Head-and-shoulders framing for close-up portraits."),
    "hand_poses": ("Hand Poses", "Hand and gesture references for detail shots."),
    "couple_poses": ("Couple Poses", "Two-person poses for couples and duo shoots."),
    "outdoor": ("Outdoor Poses", "Open-air poses suited to parks, streets and nature."),
    "creative": ("Creative Poses", "Expressive, editorial and artistic pose ideas."),
}

TAGS = {
    "standing": ["standing", "casual", "portrait"],
    "sitting": ["sitting", "seated", "relaxed"],
    "leaning": ["leaning", "wall", "casual"],
    "walking": ["walking", "candid", "movement"],
    "full_body": ["full body", "dynamic", "action"],
    "portrait": ["portrait", "headshot", "close-up"],
    "hand_poses": ["hands", "gesture", "detail"],
    "couple_poses": ["couple", "duo", "together"],
    "outdoor": ["outdoor", "nature", "travel"],
    "creative": ["creative", "editorial", "artistic"],
}


def main():
    out_root = sys.argv[1] if len(sys.argv) > 1 else "assets/poses"
    manifest = []
    for slug, builder in CATEGORY_BUILDERS.items():
        cat_dir = os.path.join(out_root, slug)
        os.makedirs(cat_dir, exist_ok=True)
        title, _desc = CATEGORY_META[slug]
        for i in range(10):
            body = builder(i)
            svg = svg_wrap(body)
            fname = f"{slug}_{i + 1:02d}.svg"
            fpath = os.path.join(cat_dir, fname)
            with open(fpath, "w") as f:
                f.write(svg)
            manifest.append(
                {
                    "id": f"builtin_{slug}_{i + 1:02d}",
                    "title": f"{title} {i + 1}",
                    "category": slug,
                    "assetPath": f"assets/poses/{slug}/{fname}",
                    "thumbnailPath": f"assets/poses/{slug}/{fname}",
                    "tags": TAGS[slug],
                    "source": "Original vector illustration created for Help me Pose",
                    "license": "CC0 (created in-house, no third-party assets used)",
                }
            )
    manifest_path = os.path.join(out_root, "manifest.json")
    with open(manifest_path, "w") as f:
        json.dump({"categories": CATEGORY_META, "poses": manifest}, f, indent=2)
    print(f"Generated {len(manifest)} poses across {len(CATEGORY_BUILDERS)} categories at {out_root}")


if __name__ == "__main__":
    main()
