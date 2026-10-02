# -*- coding: utf-8 -*-
"""Les décors peints de la machine (02/10/2026, essai) — Maxim les génère dans ChatGPT (REPRISE.md, les prompts) et les
dépose dans Machine/. Pour chaque décor, ce script prépare ce que le jeu doit savoir :

  · la CAMÉRA qui pose le vrai plateau 3D (sa physique, ses pièces) exactement dans le creux peint : on donne les coins du
    plateau dans l'image (l'avant, et le pied de la marche du fond) ; la caméra est cherchée pour deux champs (80° et 90°).
    Le creux peint est plus profond que notre plateau : la profondeur est ÉTIRÉE à l'image (×k ; la physique ne change pas) ;
  · le BLOC qui pousse prend l'habit de la marche peinte : son dessus et sa face, découpés dans l'image et redressés ;
  · les ALVÉOLES de l'arche (les lunes de la jauge, 7 ou 9 selon le décor), recentrées sur leur fond sombre ;
  · le MASQUE DE L'OR (le reflet qui glisse dessus, comme sur les cartes) ;
  · les ÉCLATS qui scintilleront : les étoiles les plus vives d'un ciel de nuit, ou les reflets de l'or (un ciel de jour) ;
  · le centre de l'EMBLÈME (le compte à rebours de la Supernova, son éclat) et les flammes (x, y du bas, largeur, hauteur).

    python design/machines/analyser.py [décor…]     → design/machines/<décor>.json, -or.png, -bloc-dessus.png, -bloc-face.png

Les mesures sont en pixels de l'image (1024 × 1536), relevées à la loupe sur une grille."""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageFilter
from scipy.optimize import least_squares

sys.stdout.reconfigure(encoding="utf-8")
BASE = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.normpath(os.path.join(BASE, "..", ".."))
SOURCE = os.path.join(RACINE, "Machine")

# Le plateau du jeu (pusher_screen.gd) : de X0 à X1, le bord à BORD, la face du bloc recule jusqu'à 7,6.
X0, X1, BORD, FACE_RECULEE, H_BLOC, MUR = 0.46, 10.34, 14.0, 7.6, 0.5, 6.0
CX = (X0 + X1) / 2
W_IMG, H_IMG = 1024, 1536

# Le relevé de chaque décor : le creux (avant, fond), le dessus et la face de la marche peinte (gauche-fond, droite-fond,
# gauche-avant, droite-avant), les alvéoles, l'emblème, les flammes, les éclats (« nuit » : les étoiles du ciel jusqu'à
# ciel_max_y ; « or » : les reflets de l'or).
DECORS = {
    "BaseCeleste": {
        "fichier": "BaseCeleste.png",
        "avant": {"y": 1287, "g": 12, "d": 1012}, "fond": {"y": 700, "g": 197, "d": 827},
        "dessus": [(222, 572), (802, 572), (200, 636), (826, 636)], "face": (200, 636, 826, 683),
        "alveoles": [(265, 208), (343, 171), (428, 148), (512, 138), (597, 148), (681, 171), (759, 208)], "r_alveole": 23.5,
        "embleme": (512, 383), "r_embleme": 195,
        "flammes": [(75, 512, 26, 46), (945, 512, 26, 46)],
        "eclats": "nuit", "ciel_max_y": 560,
    },
    "Grec": {
        "fichier": "Grec.png",
        "avant": {"y": 1252, "g": 38, "d": 988}, "fond": {"y": 745, "g": 218, "d": 806},
        "dessus": [(236, 592), (790, 592), (212, 668), (812, 668)], "face": (212, 668, 812, 712),
        "alveoles": [(218, 222), (313, 163), (412, 133), (510, 120), (608, 133), (712, 163), (804, 222)], "r_alveole": 26,
        "embleme": (510, 420), "r_embleme": 180,
        "flammes": [(62, 152, 62, 104), (948, 142, 62, 104)],
        "eclats": "or",
    },
    "Vahlalla": {
        "fichier": "Vahlalla.png",
        "avant": {"y": 1150, "g": 75, "d": 950}, "fond": {"y": 700, "g": 215, "d": 810},
        "dessus": [(240, 565), (785, 565), (222, 600), (800, 600)], "face": (222, 600, 800, 675),
        "alveoles": [(158, 318), (212, 233), (296, 165), (393, 125), (511, 93), (628, 123), (731, 166), (812, 233), (866, 318)],
        "r_alveole": 28,
        "embleme": (512, 400), "r_embleme": 150,
        "flammes": [(66, 330, 52, 92), (952, 322, 52, 92)],
        "eclats": "nuit", "ciel_max_y": 300,
    },
    "egypte": {
        "fichier": "egypte.png",
        "avant": {"y": 1257, "g": 8, "d": 1016}, "fond": {"y": 700, "g": 200, "d": 828},
        "dessus": [(225, 562), (800, 562), (198, 632), (828, 632)], "face": (198, 632, 828, 690),
        "alveoles": [(150, 385), (195, 290), (268, 224), (395, 160), (512, 140), (628, 160), (757, 224), (830, 290), (875, 385)],
        "r_alveole": 30,
        "embleme": (512, 368), "r_embleme": 95,
        "flammes": [],
        "eclats": "nuit", "ciel_max_y": 560,
    },
    "Atlantis": {
        "fichier": "Atlantis.png",
        "avant": {"y": 1263, "g": 15, "d": 1008}, "fond": {"y": 778, "g": 215, "d": 812},
        "dessus": [(235, 632), (790, 632), (210, 705), (815, 705)], "face": (210, 705, 815, 750),
        "alveoles": [(198, 333), (290, 245), (405, 190), (512, 165), (620, 190), (733, 245), (825, 333)], "r_alveole": 30,
        "embleme": (512, 445), "r_embleme": 150,
        "flammes": [],
        "eclats": "nuit", "ciel_max_y": 620,
    },
    "Persian": {
        "fichier": "Persian.png",
        "avant": {"y": 1248, "g": 35, "d": 990}, "fond": {"y": 738, "g": 205, "d": 818},
        "dessus": [(232, 565), (792, 565), (205, 640), (820, 640)], "face": (205, 640, 820, 712),
        "alveoles": [(155, 430), (165, 287), (243, 190), (372, 128), (512, 78), (650, 128), (778, 190), (856, 287), (868, 430)],
        "r_alveole": 31,
        "embleme": (512, 400), "r_embleme": 140,
        "flammes": [(65, 200, 22, 40), (955, 200, 22, 40)],
        "eclats": "nuit", "ciel_max_y": 300,
    },
    "Aztec": {
        "fichier": "Aztec",
        "avant": {"y": 1205, "g": 62, "d": 962}, "fond": {"y": 748, "g": 242, "d": 785},
        "dessus": [(262, 608), (765, 608), (245, 660), (780, 660)], "face": (245, 660, 780, 722),
        "alveoles": [(207, 305), (272, 210), (372, 140), (512, 110), (650, 140), (750, 210), (818, 305)], "r_alveole": 31,
        "embleme": (512, 420), "r_embleme": 210,
        "flammes": [(62, 352, 56, 84), (958, 352, 56, 84)],
        "eclats": "or",
    },
}


def projeter(params, pts):
    cy, cz, th, f = params
    out = []
    for (x, y, z) in pts:
        d = np.array([x - CX, y - cy, z - cz])
        fw = np.array([0.0, -math.sin(th), -math.cos(th)])
        up = np.array([0.0, math.cos(th), -math.sin(th)])
        zc = d @ fw
        out.append((W_IMG / 2 + f * d[0] / zc, H_IMG / 2 - f * (d @ up) / zc))
    return np.array(out)


def calibrer(dec, fov):
    """La caméra (sur l'axe du plateau) qui pose les coins du plateau du jeu dans le creux peint, pour un champ donné ;
    la profondeur étirée ×k autour du bord. Plus le champ est large, moins il faut étirer."""
    av, fo = dec["avant"], dec["fond"]
    image = np.array([(av["g"], av["y"]), (av["d"], av["y"]), (fo["g"], fo["y"]), (fo["d"], fo["y"])], dtype=float)
    f = (H_IMG / 2) / math.tan(math.radians(fov) / 2)

    def ecarts(p):
        cy, cz, th, zf = p
        return (projeter([cy, cz, th, f], [(X0, 0, BORD), (X1, 0, BORD), (X0, 0, zf), (X1, 0, zf)]) - image).ravel()

    meilleur = None
    for th0 in (0.5, 0.7, 0.9, 1.1):
        r = least_squares(ecarts, x0=[10.0, 22.0, th0, 6.0], bounds=([0.5, 8, 0.1, -6], [80, 120, 1.5, 13]))
        if meilleur is None or r.cost < meilleur.cost:
            meilleur = r
    cy, cz, th, zf = meilleur.x
    return {
        "fov_deg": fov,
        "position": [CX, round(float(cy), 4), round(float(cz), 4)],
        "plongee_deg": round(math.degrees(th), 4),
        "etirement": round(float((BORD - zf) / (BORD - FACE_RECULEE)), 4),
        "erreur_px": round(float(np.sqrt(np.mean(meilleur.fun ** 2))), 2),
    }


def recentrer_alveoles(lum, approx, r):
    """Chaque alvéole recentrée sur son fond sombre (la moyenne la plus basse dans un disque de rayon r)."""
    ri = int(r)
    yy, xx = np.mgrid[-ri:ri + 1, -ri:ri + 1]
    disque = (xx * xx + yy * yy) <= (r * 0.8) ** 2
    out = []
    for (x, y) in approx:
        best = None
        for dy in range(-8, 9):
            for dx in range(-8, 9):
                cx, cy = x + dx, y + dy
                bloc = lum[cy - ri:cy + ri + 1, cx - ri:cx + ri + 1]
                if bloc.shape != disque.shape:
                    continue
                m = bloc[disque].mean()
                if best is None or m < best[0]:
                    best = (m, cx, cy)
        out.append([int(best[1]), int(best[2])])
    return out


def masque_or(rgb):
    """L'or : rouge fort, vert moyen, bleu faible, saturé. Un masque doux (la lumière de l'or, pas sa simple présence)."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    sat = (mx - mn) / np.maximum(mx, 1e-3)
    teinte_or = (r > g) & (g > b) & (r > 0.35) & (sat > 0.35) & ((g / np.maximum(r, 1e-3)) > 0.45)
    m = np.where(teinte_or, np.clip((mx - 0.3) / 0.6, 0, 1), 0.0)
    return m, Image.fromarray((m * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(0.8))


def eclats(rgb, mor, dec, n=34, ecart=34):
    """Les points qui scintilleront : de nuit, les étoiles les plus vives du ciel peint (des maxima locaux clairs, peu
    saturés) ; de jour, les reflets les plus vifs de l'or."""
    lum = rgb.mean(axis=-1)
    mx = rgb.max(axis=-1)
    mn = rgb.min(axis=-1)
    sat = (mx - mn) / np.maximum(mx, 1e-3)
    nuit = dec["eclats"] == "nuit"
    h = min(dec.get("ciel_max_y", dec["avant"]["y"] - 40), rgb.shape[0] - 3)
    cand = []
    for y in range(3, h):
        for x in range(3, rgb.shape[1] - 3):
            v = lum[y, x]
            if nuit:
                if v < 0.72 or sat[y, x] > 0.45:
                    continue
            elif v < 0.82 or mor[y, x] < 0.5:
                continue
            fen = lum[y - 3:y + 4, x - 3:x + 4]
            if v >= fen.max() and v - np.median(fen) > (0.28 if nuit else 0.12):
                cand.append((float(v), x, y))
    cand.sort(reverse=True)
    pris = []
    for v, x, y in cand:
        if all((x - px) ** 2 + (y - py) ** 2 >= ecart * ecart for (px, py) in pris):
            pris.append((x, y))
        if len(pris) >= (n if nuit else 26):
            break
    return [[int(x), int(y)] for (x, y) in pris]


def _coeffs(dest, src):
    """Les 8 coefficients d'une perspective PIL : chaque point de la sortie (dest) va chercher son point dans l'image (src)."""
    A, B = [], []
    for (x, y), (X, Y) in zip(dest, src):
        A.append([x, y, 1, 0, 0, 0, -X * x, -X * y]); B.append(X)
        A.append([0, 0, 0, x, y, 1, -Y * x, -Y * y]); B.append(Y)
    return np.linalg.solve(np.array(A, float), np.array(B, float)).tolist()


def habits_bloc(im, nom, dec):
    """Le dessus de la marche peinte, redressé (1024 × 420 : l'image du bloc), et sa face (1024 × 128)."""
    W, H = 1024, 420
    q = dec["dessus"]            # gauche-fond, droite-fond, gauche-avant, droite-avant
    dessus = im.transform((W, H), Image.Transform.PERSPECTIVE, _coeffs([(0, 0), (W, 0), (0, H), (W, H)], q), Image.BICUBIC)
    dessus.save(os.path.join(BASE, "%s-bloc-dessus.png" % nom))
    x0, y0, x1, y1 = dec["face"]
    im.crop((x0, y0, x1, y1)).resize((1024, 128), Image.LANCZOS).save(os.path.join(BASE, "%s-bloc-face.png" % nom))


def traiter(nom, dec):
    im = Image.open(os.path.join(SOURCE, dec["fichier"])).convert("RGB")
    assert im.size == (W_IMG, H_IMG), im.size
    rgb = np.asarray(im).astype(np.float64) / 255.0
    lum = rgb.mean(axis=-1)
    cams = {str(fov): calibrer(dec, fov) for fov in (80, 90)}
    alv = recentrer_alveoles(lum, dec["alveoles"], dec["r_alveole"])
    mor, mor_img = masque_or(rgb)
    mor_img.save(os.path.join(BASE, "%s-or.png" % nom))
    points = eclats(rgb, mor, dec)
    habits_bloc(im, nom, dec)
    sortie = {
        "nom": nom,
        "image": "Machine/" + dec["fichier"],
        "taille": [W_IMG, H_IMG],
        "cameras": cams,
        "alveoles": alv,
        "r_alveole": dec["r_alveole"],
        "embleme": list(dec["embleme"]),
        "r_embleme": dec["r_embleme"],
        "flammes": [list(f) for f in dec["flammes"]],
        "etoiles": points,
        "avant_y": dec["avant"]["y"],
        "bloc_dessus": "design/machines/%s-bloc-dessus.png" % nom,
        "bloc_face": "design/machines/%s-bloc-face.png" % nom,
    }
    with open(os.path.join(BASE, "%s.json" % nom), "w", encoding="utf-8") as f:
        json.dump(sortie, f, ensure_ascii=False, indent=1)
    c = cams["80"]
    print("%-12s 80° : étirement ×%.2f, plongée %.0f°, erreur %.1f px · 90° : ×%.2f · %d alvéoles · %d éclats" % (
        nom, c["etirement"], c["plongee_deg"], c["erreur_px"], cams["90"]["etirement"], len(alv), len(points)))


if __name__ == "__main__":
    for nom, dec in DECORS.items():
        if len(sys.argv) > 1 and nom not in sys.argv[1:]:
            continue
        traiter(nom, dec)
