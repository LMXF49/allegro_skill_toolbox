# -*- coding: utf-8 -*-
# TTF/TTC outline extractor for Allegro SKILL "add Chinese text" module.
# Two modes:
#   CLI:  python ttf_outline.py <font> <text> <size_mil> <gap> <out> [png]
#   Job:  python ttf_outline.py --job <jobfile_gbk> --out <datfile>
# Job file (GBK) lines: FONT=<path> / SIZE=<mil> / GAP=<times> / TEXT=<text>
# Output data format (ASCII, trivially parseable by SKILL gets/parseString):
#   # ASTB_TTF_OUTLINE_V1
#   G <advanceMil>        ; glyph pen advance in mil (gap already applied to x)
#   S <npts>              ; solid contour (outer)
#   x y                   ; mil, y-up, absolute within the text line
#   H <npts>              ; hole contour, belongs to the nearest preceding S
# S/H classification by containment parity (works for both TT and CFF).
import sys

sys.stdout.reconfigure(encoding='ascii', errors='backslashreplace')

from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen


class FlatPen(BasePen):
    """Flatten glyph outline to polygon contours (quadratics/cubics -> lines)."""

    def __init__(self, glyphSet, seg=8):
        super().__init__(glyphSet)
        self.seg = seg
        self.contours = []
        self.cur = None

    def _moveTo(self, p):
        self.cur = [p]

    def _lineTo(self, p):
        self.cur.append(p)

    def _closePath(self):
        if self.cur:
            self.contours.append(self.cur)
        self.cur = None

    def _endPath(self):
        if self.cur:
            self.contours.append(self.cur)
        self.cur = None

    def _qCurveToOne(self, p1, p2):
        p0 = self.cur[-1]
        for i in range(1, self.seg + 1):
            t = i / self.seg
            mt = 1 - t
            x = mt * mt * p0[0] + 2 * mt * t * p1[0] + t * t * p2[0]
            y = mt * mt * p0[1] + 2 * mt * t * p1[1] + t * t * p2[1]
            self.cur.append((x, y))

    def _curveToOne(self, p1, p2, p3):
        p0 = self.cur[-1]
        for i in range(1, self.seg + 1):
            t = i / self.seg
            mt = 1 - t
            x = (mt ** 3) * p0[0] + 3 * mt * mt * t * p1[0] \
                + 3 * mt * t * t * p2[0] + (t ** 3) * p3[0]
            y = (mt ** 3) * p0[1] + 3 * mt * mt * t * p1[1] \
                + 3 * mt * t * t * p2[1] + (t ** 3) * p3[1]
            self.cur.append((x, y))


def point_in_contour(pt, cont):
    """Ray casting, pt=(x,y) inside polygon cont."""
    x, y = pt
    inside = False
    n = len(cont)
    j = n - 1
    for i in range(n):
        xi, yi = cont[i]
        xj, yj = cont[j]
        if (yi > y) != (yj > y):
            xint = (xj - xi) * (y - yi) / (yj - yi) + xi
            if x < xint:
                inside = not inside
        j = i
    return inside


def classify(contours):
    """Return list of (kind, contour): 'S' solid even depth, 'H' hole odd depth.
    H blocks are emitted immediately after their innermost containing S."""
    items = []
    for idx, c in enumerate(contours):
        depth = 0
        parent = -1
        for jdx, o in enumerate(contours):
            if jdx == idx:
                continue
            if point_in_contour(c[0], o):
                depth += 1
                parent = jdx
        kind = 'H' if depth % 2 == 1 else 'S'
        items.append([kind, c, parent])
    ordered = []
    for i, it in enumerate(items):
        if it[0] == 'S':
            ordered.append(it)
            for jt in items:
                if jt[0] == 'H' and jt[2] == i:
                    ordered.append(jt)
    placed = set(id(it) for it in ordered)
    for it in items:
        if id(it) not in placed:
            ordered.append(it)
    return [(it[0], it[1]) for it in ordered]


def run_extraction(font_path, text, size_mil, gap, out_path, png_path=None):
    font = TTFont(font_path, fontNumber=0, lazy=True)
    upm = font['head'].unitsPerEm
    scale = size_mil / upm
    cmap = font.getBestCmap()
    glyph_set = font.getGlyphSet()
    hmtx = font['hmtx']

    glyphs = []
    pen_x = 0.0
    total_w = 0.0
    for ch in text:
        if ch == ' ':
            pen_x += size_mil * 0.5 * gap
            total_w = pen_x
            continue
        cp = ord(ch)
        if cp not in cmap:
            print('WARN: U+%04X not in font cmap, skipped' % cp)
            continue
        gname = cmap[cp]
        pen = FlatPen(glyph_set)
        glyph_set[gname].draw(pen)
        advance = hmtx[gname][0] * scale
        conts = [[(x * scale + pen_x, y * scale) for (x, y) in c]
                 for c in pen.contours]
        glyphs.append((ch, advance, classify(conts)))
        pen_x += advance * gap
        total_w = pen_x

    with open(out_path, 'w', encoding='ascii', newline='\n') as f:
        f.write('# ASTB_TTF_OUTLINE_V1\n')
        for ch, advance, conts in glyphs:
            f.write('G %.4f\n' % advance)
            for kind, c in conts:
                f.write('%s %d\n' % (kind, len(c)))
                for (x, y) in c:
                    f.write('%.4f %.4f\n' % (x, y))
    print('glyphs=%d total_width_mil=%.2f data=%s'
          % (len(glyphs), total_w, out_path))

    if png_path:
        import matplotlib
        matplotlib.use('Agg')
        from matplotlib import pyplot as plt
        from matplotlib.path import Path
        from matplotlib.patches import PathPatch
        fig, ax = plt.subplots(figsize=(8, 4))
        for ch, advance, conts in glyphs:
            verts, codes = [], []
            for kind, c in conts:
                verts += list(c) + [c[0]]
                codes += [Path.MOVETO] + [Path.LINETO] * (len(c) - 1) + [Path.CLOSEPOLY]
            ax.add_patch(PathPatch(Path(verts, codes), facecolor='black',
                                   edgecolor='red', lw=0.5))
        ax.set_aspect('equal')
        ax.autoscale_view()
        fig.savefig(png_path, bbox_inches='tight', dpi=110)
        print('preview=%s' % png_path)
    return len(glyphs)


def _write_log(out_path, text):
    """SKILL reads <out>.log to surface the real failure reason.
    backslashreplace keeps non-ASCII (e.g. decoded Chinese) readable as
    \\uXXXX escapes so the log stays pure ASCII but loss-free."""
    try:
        with open(out_path + '.log', 'w', encoding='ascii',
                  errors='backslashreplace') as f:
            f.write(text)
    except Exception:
        pass


def main():
    args = sys.argv[1:]
    if '--job' in args:
        job = args[args.index('--job') + 1]
        out = args[args.index('--out') + 1]
        try:
            cfg = {}
            with open(job, encoding='gbk') as f:
                for line in f:
                    line = line.rstrip('\r\n')
                    if '=' in line:
                        k, v = line.split('=', 1)
                        cfg[k.strip().upper()] = v
            print('job text=%r font=%r' % (cfg.get('TEXT', ''),
                                             cfg.get('FONT', '')))
            nglyphs = run_extraction(cfg['FONT'], cfg.get('TEXT', ''),
                                     float(cfg.get('SIZE', '100')),
                                     float(cfg.get('GAP', '1.0')), out)
            if nglyphs == 0:
                _write_log(out, 'ERROR\nNo glyphs extracted: '
                                'font may not contain these characters\n'
                                'decoded text=%r\n' % cfg.get('TEXT', ''))
                print('ERROR: no glyphs extracted')
                sys.exit(1)
        except Exception:
            import traceback
            _write_log(out, 'ERROR\n' + traceback.format_exc())
            print('ERROR: extraction failed, see ' + out + '.log')
            sys.exit(1)
        _write_log(out, 'OK glyphs=%d decoded text=%r\n'
                        % (nglyphs, cfg.get('TEXT', '')))
        return
    if len(args) < 5:
        print('usage: ttf_outline.py <font> <text> <size_mil> <gap> <out> [png]')
        sys.exit(2)
    run_extraction(args[0], args[1], float(args[2]), float(args[3]), args[4],
                   args[5] if len(args) > 5 else None)


if __name__ == '__main__':
    main()
