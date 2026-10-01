"""Create the project's original grayscale, transparent Pip illustration."""

import math
import struct
import zlib
from pathlib import Path

SIZE = 512
pixels = bytearray(SIZE * SIZE * 4)


def blend_pixel(x, y, color):
    if not (0 <= x < SIZE and 0 <= y < SIZE):
        return
    offset = (y * SIZE + x) * 4
    pixels[offset:offset + 4] = bytes((*color, 255))


def ellipse(box, color):
    left, top, right, bottom = box
    cx, cy = (left + right) / 2, (top + bottom) / 2
    rx, ry = (right - left) / 2, (bottom - top) / 2
    for y in range(max(0, int(top)), min(SIZE, int(bottom) + 1)):
        for x in range(max(0, int(left)), min(SIZE, int(right) + 1)):
            if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1:
                blend_pixel(x, y, color)


def polygon(points, color):
    min_x = max(0, int(min(p[0] for p in points)))
    max_x = min(SIZE, int(max(p[0] for p in points)) + 1)
    min_y = max(0, int(min(p[1] for p in points)))
    max_y = min(SIZE, int(max(p[1] for p in points)) + 1)
    for y in range(min_y, max_y):
        for x in range(min_x, max_x):
            inside = False
            j = len(points) - 1
            for i, (px, py) in enumerate(points):
                qx, qy = points[j]
                if ((py > y + .5) != (qy > y + .5) and
                        x + .5 < (qx - px) * (y + .5 - py) / (qy - py) + px):
                    inside = not inside
                j = i
            if inside:
                blend_pixel(x, y, color)


def line(start, end, color, width):
    ax, ay = start
    bx, by = end
    radius = width / 2
    min_x, max_x = max(0, int(min(ax, bx) - radius)), min(SIZE, int(max(ax, bx) + radius + 1))
    min_y, max_y = max(0, int(min(ay, by) - radius)), min(SIZE, int(max(ay, by) + radius + 1))
    dx, dy = bx - ax, by - ay
    denom = dx * dx + dy * dy or 1
    for y in range(min_y, max_y):
        for x in range(min_x, max_x):
            t = max(0, min(1, ((x + .5 - ax) * dx + (y + .5 - ay) * dy) / denom))
            if math.hypot(x + .5 - ax - t * dx, y + .5 - ay - t * dy) <= radius:
                blend_pixel(x, y, color)


# Soft gray body, pointed ears, and rounded paws keep the color tint readable.
outline, fur, light, shadow = (58, 62, 60), (218, 220, 216), (245, 245, 239), (165, 169, 165)
polygon([(133, 166), (119, 47), (220, 113), (292, 111), (394, 48), (379, 174)], outline)
polygon([(148, 151), (137, 70), (211, 122), (219, 164)], fur)
polygon([(293, 163), (390, 70), (372, 157), (314, 180)], fur)
polygon([(161, 137), (151, 92), (198, 125)], shadow)
polygon([(321, 148), (373, 92), (359, 145)], shadow)
ellipse((127, 120, 385, 370), outline)
ellipse((139, 130, 373, 359), fur)
ellipse((164, 342, 263, 435), outline)
ellipse((249, 342, 348, 435), outline)
ellipse((177, 351, 255, 423), light)
ellipse((257, 351, 335, 423), light)
ellipse((196, 435, 310, 481), outline)
ellipse((205, 437, 301, 473), fur)
# Eye patches, bright eyes, and little highlights.
ellipse((177, 207, 244, 281), shadow)
ellipse((268, 207, 335, 281), shadow)
ellipse((197, 220, 225, 259), outline)
ellipse((287, 220, 315, 259), outline)
ellipse((204, 224, 212, 233), light)
ellipse((294, 224, 302, 233), light)
ellipse((241, 266, 271, 286), outline)
polygon([(242, 270), (270, 270), (256, 283)], shadow)
line((256, 284), (256, 297), outline, 6)
line((256, 296), (237, 307), outline, 6)
line((256, 296), (275, 307), outline, 6)
# Whiskers and small cheek dots.
for y in (278, 297, 316):
    line((208, y), (151, y - 8), shadow, 4)
    line((304, y), (361, y - 8), shadow, 4)
for x in (222, 235, 277, 290):
    ellipse((x - 3, 287, x + 3, 293), shadow)


def chunk(kind, data):
    return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data) & 0xffffffff)


raw = b''.join(b'\0' + pixels[y * SIZE * 4:(y + 1) * SIZE * 4] for y in range(SIZE))
png = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!2I5B', SIZE, SIZE, 8, 6, 0, 0, 0)) +
       chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))
Path('assets').mkdir(exist_ok=True)
Path('assets/pip.png').write_bytes(png)
print(f'Created assets/pip.png ({SIZE}x{SIZE}, RGBA)')
