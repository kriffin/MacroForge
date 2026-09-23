from PIL import Image, ImageDraw
# Flat logo for the minimap button and the addon list.
# Usage: python3 tools/make-flat-logo.py icons
import math, sys
S = 1024
GOLD, CYAN, BG = (255, 209, 0, 255), (0, 204, 255, 255), (22, 26, 38, 255)
im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
k = S / 512
def P(pts): return [(x * k, y * k) for x, y in pts]
# Disk
d.ellipse(P([(16, 16), (496, 496)]), fill=BG)
# Hammer (behind the anvil top), rotated 35 degrees around its head center
def rot(pts, cx, cy, a):
    a = math.radians(a); c, s = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in pts]
cx, cy = 300, 150
handle = rot([(290, 150), (310, 150), (310, 330), (290, 330)], cx, cy, -40)
head = rot([(225, 112), (375, 112), (375, 188), (225, 188)], cx, cy, -40)
d.polygon(P(handle), fill=CYAN)
d.polygon(P(head), fill=CYAN)
# Anvil
d.polygon(P([(88, 250), (180, 232), (180, 292)]), fill=GOLD)          # horn
d.rectangle(P([(176, 228), (428, 296)]), fill=GOLD)                  # face
d.polygon(P([(236, 296), (368, 296), (336, 366), (268, 366)]), fill=GOLD)  # waist
d.polygon(P([(196, 366), (408, 366), (436, 420), (168, 420)]), fill=GOLD)  # base
for size, name in [(64, "MacroForge_minimap"), (128, "MacroForge_flat_128")]:
    out = im.resize((size, size), Image.LANCZOS)
    out.save(f"{sys.argv[1]}/{name}.tga")
    
