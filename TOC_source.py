import random
random.seed(7)

# ---- palette (same as pptx version, kept uniform) ----
DARK_BLUE   = "#2C4A5E"
MID_TEAL    = "#3B7A8C"
LIGHT_TEAL  = "#6FA8B5"
DEEP_LAYER1 = "#274B5E"
DEEP_LAYER2 = "#16303D"
ACCENT_GREEN= "#2F9E5B"
HOUSE_TAN   = "#B99568"
HOUSE_ROOF  = "#93714E"
TREE_GREEN  = "#5B8C6E"
WINDOW      = "#D6E4E8"
GROUND_LINE = "#1A2E38"

W, H = 3.25, 1.75
GROUND_Y = 1.15

def rect(x,y,w,h,fill,opacity=1,rx=0):
    rx_attr = f' rx="{rx}"' if rx else ''
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" opacity="{opacity}"{rx_attr}/>'

def circle(cx,cy,r,fill,opacity=1):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" opacity="{opacity}"/>'

def poly(pts,fill,opacity=1):
    p = " ".join(f"{x},{y}" for x,y in pts)
    return f'<polygon points="{p}" fill="{fill}" opacity="{opacity}"/>'

parts = []
parts.append(f'<rect x="0" y="0" width="{W}" height="{H}" fill="white"/>')

# ---- defs: gradients ----
defs = []
defs.append(f'''
<clipPath id="undergroundClip">
  <rect x="0.05" y="{GROUND_Y}" width="3.15" height="0.44"/>
</clipPath>
<linearGradient id="captureFlow" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0%" stop-color="{LIGHT_TEAL}" stop-opacity="0.95"/>
  <stop offset="100%" stop-color="{MID_TEAL}" stop-opacity="0.9"/>
</linearGradient>
<linearGradient id="injectFlow" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0%" stop-color="{MID_TEAL}" stop-opacity="0.95"/>
  <stop offset="100%" stop-color="{LIGHT_TEAL}" stop-opacity="0.55"/>
</linearGradient>
<radialGradient id="injectGlow" cx="50%" cy="50%" r="50%">
  <stop offset="0%" stop-color="{LIGHT_TEAL}" stop-opacity="0.45"/>
  <stop offset="100%" stop-color="{LIGHT_TEAL}" stop-opacity="0"/>
</radialGradient>
<linearGradient id="valueArrow" x1="0" y1="1" x2="1" y2="0">
  <stop offset="0%" stop-color="{ACCENT_GREEN}" stop-opacity="0.75"/>
  <stop offset="100%" stop-color="{ACCENT_GREEN}" stop-opacity="1"/>
</linearGradient>
''')

# ---- underground layers ----
parts.append(rect(0.05, GROUND_Y, 3.15, 0.22, DEEP_LAYER1))
parts.append(rect(0.05, GROUND_Y+0.22, 3.15, 0.22, DEEP_LAYER2))

# ---- ground line ----
parts.append(f'<line x1="0.05" y1="{GROUND_Y}" x2="3.20" y2="{GROUND_Y}" stroke="{GROUND_LINE}" stroke-width="0.02"/>')

# ---- factory ----
parts.append(rect(0.10, 0.62, 0.42, 0.53, DARK_BLUE, rx=0.015))
parts.append(rect(0.15, 0.40, 0.06, 0.24, DARK_BLUE, rx=0.008))
parts.append(rect(0.27, 0.34, 0.06, 0.30, DARK_BLUE, rx=0.008))
parts.append(rect(0.39, 0.44, 0.06, 0.20, DARK_BLUE, rx=0.008))
for wx,wy in [(0.16,0.72),(0.26,0.72),(0.16,0.90),(0.26,0.90)]:
    parts.append(rect(wx,wy,0.06,0.06,WINDOW,rx=0.008))

# ---- rising emission dots from the chimney (before joining the captured stream) ----
emission_dots = [
    (0.31, 0.31, 0.017, 0.55),
    (0.335, 0.255, 0.019, 0.50),
    (0.365, 0.20, 0.021, 0.45),
    (0.40, 0.155, 0.019, 0.40),
    (0.435, 0.115, 0.016, 0.35),
]
for dx, dy, size, op in emission_dots:
    parts.append(circle(dx, dy, size, LIGHT_TEAL, op))

# ---- CO2 label bubble ----
bx, by, br = 0.59, 0.27, 0.15
parts.append(circle(bx,by,br,LIGHT_TEAL))
parts.append(f'<text x="{bx}" y="{by+0.035}" font-family="Arial" font-weight="bold" font-size="0.12" fill="white" text-anchor="middle">CO&#8322;</text>')

# ---- capture flow: tapered ribbon with streamline texture, bubble -> tank inlet ----
# main tapered ribbon (filled bezier "river" shape narrowing toward the tank)
p0 = (0.74, 0.31)   # leaves the bubble
c1 = (0.86, 0.22)
c2 = (0.97, 0.28)
p1 = (1.08, 0.50)   # enters tank inlet
# build a tapered band by offsetting a perpendicular-ish width that shrinks along the path
capture_path = f'M {p0[0]},{p0[1]-0.035} C {c1[0]},{c1[1]-0.03} {c2[0]},{c2[1]-0.02} {p1[0]-0.01},{p1[1]-0.01} ' \
               f'L {p1[0]+0.01},{p1[1]+0.01} C {c2[0]},{c2[1]+0.02} {c1[0]},{c1[1]+0.03} {p0[0]},{p0[1]+0.035} Z'
parts.append(f'<path d="{capture_path}" fill="url(#captureFlow)"/>')
# two lighter streamline traces alongside for a flow-vis feel
for off, op in [(-0.05, 0.35), (0.05, 0.35)]:
    parts.append(f'<path d="M {p0[0]},{p0[1]+off} C {c1[0]},{c1[1]+off*0.7} {c2[0]},{c2[1]+off*0.4} {p1[0]},{p1[1]+off*0.15}" '
                  f'fill="none" stroke="{LIGHT_TEAL}" stroke-width="0.012" stroke-linecap="round" opacity="{op}"/>')
# small arrowhead at tank inlet
ah = [(1.06,0.47),(1.14,0.47),(1.10,0.545)]
parts.append(poly(ah, MID_TEAL))

# ---- capture / storage unit (cylinder) ----
parts.append(rect(1.00, 0.55, 0.24, 0.42, MID_TEAL))
parts.append(f'<ellipse cx="1.12" cy="0.55" rx="0.12" ry="0.05" fill="{MID_TEAL}"/>')
parts.append(f'<ellipse cx="1.12" cy="0.97" rx="0.12" ry="0.05" fill="{DEEP_LAYER1}"/>')

# ---- injection flow: pipe with flowing gradient + dispersing dot plume ----
parts.append(rect(1.09, 1.00, 0.06, 0.40, "url(#injectFlow)", rx=0.012))
tip = (1.12, 1.42)
parts.append('<g clip-path="url(#undergroundClip)">')
parts.append(f'<circle cx="{tip[0]}" cy="{tip[1]}" r="0.24" fill="url(#injectGlow)"/>')
# small downward arrowhead at the pipe tip
parts.append(poly([(1.07,1.38),(1.17,1.38),(1.12,1.46)], LIGHT_TEAL, 0.9))
# dispersing dot plume (denser/larger near tip, fading outward - shows pressurized spread)
plume = []
for i in range(16):
    ang = random.uniform(0, 3.14159)  # spread downward/sideways
    dist = random.uniform(0.03, 0.16)
    dx = tip[0] + dist*random.uniform(-1,1)
    dy = tip[1] + 0.04 + dist*random.uniform(0.15,0.75)
    dy = min(dy, GROUND_Y + 0.40)  # keep inside the deep layer band
    size = max(0.012, 0.030 - dist*0.09)
    op = max(0.25, 0.85 - dist*2.6)
    plume.append((dx,dy,size,op))
for dx,dy,size,op in plume:
    parts.append(circle(dx,dy,size,LIGHT_TEAL,op))
parts.append('</g>')

# ---- trees (varied sizes, spread across the gap to bridge the two clusters) ----
def tree(x, scale=1.0):
    tw, th = 0.11*scale, 0.16*scale
    parts.append(rect(x+tw*0.41, GROUND_Y-0.09*scale, 0.018*scale, 0.09*scale, HOUSE_ROOF, rx=0.006))
    parts.append(poly([(x,GROUND_Y-0.07*scale),(x+tw,GROUND_Y-0.07*scale),(x+tw/2,GROUND_Y-0.07*scale-th)], TREE_GREEN))
tree(1.30, 0.85)
tree(1.52, 1.15)
tree(1.74, 0.75)
tree(1.96, 1.05)
tree(2.16, 0.80)

# ---- houses (ascend left -> right, shifted closer to bridge the gap) ----
def house(x, bw, bh, rh, prominent=False):
    by_ = GROUND_Y - bh
    parts.append(rect(x, by_, bw, bh, HOUSE_TAN, rx=0.012))
    parts.append(poly([(x-0.03,by_),(x+bw+0.03,by_),(x+bw/2,by_-rh)], HOUSE_ROOF))
    parts.append(rect(x+bw*0.3, by_+bh*0.35, bw*0.22, bh*0.22, WINDOW, rx=0.008))
    cx = x+bw/2
    top = by_-rh-0.06
    # "$" price badge - full weight on the tallest (the payoff); quieter via opacity on the other two
    # (size is NOT reduced for non-prominent badges - shrinking text below ~0.085in would drop
    # under ACS's 6pt hard floor for TOC graphic text; opacity alone achieves de-emphasis safely)
    br = 0.085 + (bh-0.20)*0.25
    op = 1.0 if prominent else 0.62
    bcx, bcy = cx, top-br+0.02
    parts.append(circle(bcx, bcy, br, ACCENT_GREEN, op))
    parts.append(f'<text x="{bcx}" y="{bcy+br*0.38}" font-family="Arial" font-weight="bold" '
                  f'font-size="{br*1.2}" fill="white" text-anchor="middle" opacity="{op}">$</text>')
    parts.append(poly([(bcx-br*0.38,bcy-br+0.05),(bcx+br*0.38,bcy-br+0.05),(bcx,bcy-br-0.02)], ACCENT_GREEN, op))
house(2.26,0.14,0.20,0.10)                # shortest, leftmost
house(2.50,0.16,0.26,0.12)                # medium
house(2.74,0.20,0.34,0.14, prominent=True) # tallest, rightmost - the clear payoff

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}in" height="{H}in">
<defs>{defs[0]}</defs>
{"".join(parts)}
</svg>'''

with open("/home/claude/svg_toc/toc.svg","w") as f:
    f.write(svg)
print("written")
