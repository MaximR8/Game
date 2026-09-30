# -*- coding: utf-8 -*-
"""La fabrique des emblèmes des rangs du Classé (FEATURES ligne 4, étape 3 du Carré, 28/09).

Six médaillons, du plus modeste au plus prestigieux : Météore → Comète → Aurore → Éclipse → Galaxie →
Zénith (Maxim, 28/09 : « OK »). Même éclairage que les médaillons de la barre (render_objets.py) :
un émail dans une bague d'or, et l'emblème frappé en or par-dessus. Rien n'est dessiné à la main.
La prestance monte avec le rang : l'émail change de couleur, la bague s'orne (grènetis, filet, clous).

    python render_rangs.py      # → carre/rang-*.png et carre/_planche-rangs.png
                                #   (puis copier carre/rang-*.png dans proto_degagement/carre/)"""
import os, math
import numpy as np
from PIL import Image
import render_objets as R
from render_objets import lisse, metal, environnement, reflet, OR, etoile_sdf, polygone_sdf, grenetis

BASE = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(BASE, "carre")
RANGS = ["meteore", "comete", "aurore", "eclipse", "galaxie", "zenith"]

# l'émail (centre, bord) et ce qui orne la bague, rang par rang
EMAIL = {
    "meteore": ("#2c3a34", "#080c0a"),
    "comete": ("#27394a", "#060b12"),
    "aurore": ("#2d5a4b", "#081a14"),
    "eclipse": ("#3a2c66", "#120d22"),
    "galaxie": ("#2c2f72", "#0a0b26"),
    "zenith": ("#62192d", "#16050a"),
}
ORNEMENTS = {                  # grènetis (nombre de grains), filet intérieur, clous
    "meteore": (0, False, 0),
    "comete": (32, False, 0),
    "aurore": (44, False, 0),
    "eclipse": (44, True, 0),
    "galaxie": (44, True, 8),
    "zenith": (56, True, 16),
}


def effile(u, v, ax, ay, bx, by, ra, rb):
    """Un trait de a vers b dont l'épaisseur passe de ra à rb."""
    px, py = u - ax, v - ay
    dx, dy = bx - ax, by - ay
    t = np.clip((px * dx + py * dy) / (dx * dx + dy * dy), 0, 1)
    return np.hypot(px - t * dx, py - t * dy) - (ra + (rb - ra) * t)


def courbe_effilee(u, v, a, b, courbure, ra, rb, pas=14):
    """Un trait courbe (un arc de parabole de a vers b), effilé."""
    lx, ly = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(lx, ly)
    nx, ny = -ly / ln, lx / ln
    pts = []
    for k in range(pas + 1):
        t = k / pas
        c = courbure * math.sin(math.pi * t)
        pts.append((a[0] + lx * t + nx * c, a[1] + ly * t + ny * c))
    d = np.full(u.shape, 9.0)
    for k in range(pas):
        t0, t1 = k / pas, (k + 1) / pas
        d = np.minimum(d, effile(u, v, pts[k][0], pts[k][1], pts[k + 1][0], pts[k + 1][1], ra + (rb - ra) * t0, ra + (rb - ra) * t1))
    return d


def embleme(nom, u, v):
    """La forme de l'emblème (distance signée : négative dedans), dans un carré de −1 à 1."""
    if nom == "meteore":        # une étoile qui file, et sa traînée
        d = etoile_sdf(u + 0.34, v - 0.34, 4, 0.44, 0.13)
        d = np.minimum(d, effile(u, v, -0.30, 0.30, 0.74, -0.74, 0.14, 0.016))
        for s in (-1, 1):
            ox, oy = s * 0.13, s * 0.13
            d = np.minimum(d, effile(u, v, -0.16 + ox * 1.3, 0.16 + oy * 1.3, 0.46 + ox * 1.3, -0.46 + oy * 1.3, 0.06, 0.010))
        return d
    if nom == "comete":         # une tête ronde, une chevelure qui s'étire
        d = np.hypot(u + 0.36, v - 0.36) - 0.24
        d = np.minimum(d, courbe_effilee(u, v, (-0.36, 0.36), (0.74, -0.52), 0.10, 0.20, 0.012))
        d = np.minimum(d, courbe_effilee(u, v, (-0.30, 0.22), (0.50, -0.80), -0.06, 0.08, 0.008))
        d = np.minimum(d, courbe_effilee(u, v, (-0.22, 0.40), (0.86, -0.16), 0.12, 0.07, 0.008))
        return d
    if nom == "aurore":         # des voiles de lumière au-dessus de l'horizon
        d = effile(u, v, -0.80, 0.62, 0.80, 0.62, 0.05, 0.05)
        cy = 0.62
        r = np.hypot(u, v - cy)
        th = np.arctan2(v - cy, u)
        haut = (th < -math.radians(18)) & (th > -math.radians(162))
        for R0, ep in [(0.40, 0.050), (0.60, 0.060), (0.82, 0.055)]:
            onde = R0 + 0.018 * np.sin(th * 6.0 + R0 * 5.0)
            fin = np.clip(np.sin(-(th + math.radians(18)) / math.radians(144) * math.pi), 0, 1)
            arc = np.abs(r - onde) - ep * (0.25 + 0.75 * fin)
            d = np.minimum(d, np.where(haut, arc, 9.0))
        d = np.minimum(d, etoile_sdf(u - 0.62, v + 0.70, 4, 0.16, 0.045))
        return d
    if nom == "eclipse":        # l'anneau du soleil caché, et sa couronne
        r = np.hypot(u, v)
        d = np.abs(r - 0.38) - 0.075
        for k in range(12):
            a = k * math.pi / 6 + math.pi / 12
            long = 0.86 if k % 2 == 0 else 0.70
            d = np.minimum(d, effile(u, v, 0.52 * math.cos(a), 0.52 * math.sin(a), long * math.cos(a), long * math.sin(a), 0.055, 0.010))
        return d
    if nom == "galaxie":        # deux bras en spirale, et quelques étoiles
        d = R._spirale(u * 1.05, v * 1.05, k=2.6, r0=0.12, r1=0.92) / 1.05
        for (x, y, s) in [(0.66, -0.60, 0.13), (-0.70, 0.56, 0.11), (0.74, 0.46, 0.08)]:
            d = np.minimum(d, etoile_sdf(u - x, v - y, 4, s, s * 0.28))
        return d
    if nom == "zenith":         # l'étoile au plus haut du ciel, au-dessus de la voûte
        d = etoile_sdf(u, v + 0.16, 8, 0.60, 0.25)
        d = np.maximum(d, -(np.hypot(u, v + 0.16) - 0.11))          # un cœur creusé
        d = np.minimum(d, np.hypot(u, v + 0.16) - 0.07)
        voute = np.abs(np.hypot(u, v - 1.55) - 0.98) - 0.05
        d = np.minimum(d, np.where(np.abs(u) < 0.72, voute, 9.0))
        for s in (-1, 1):
            d = np.minimum(d, etoile_sdf(u - s * 0.66, v + 0.56, 4, 0.15, 0.04))
        return d
    raise ValueError(nom)


def medaillon_rang(nom, S=384, ss=3):
    N, u, v = R.grille(S, ss)
    r = np.hypot(u, v)
    grains, filet, clous = ORNEMENTS[nom]
    Rb0, Rb1 = 0.80, 0.97
    tb = np.clip((r - Rb0) / (Rb1 - Rb0), 0, 1)
    bague = (r >= Rb0) & (r <= Rb1)
    h = np.where(bague, 0.06 * np.sin(np.pi * tb) ** 0.7, 0.0)
    if grains:
        h += np.where(bague, 0.014 * grenetis(u, v, 1.0, 0.885, grains, 0.016), 0.0)
    h += np.where(r < Rb0, 0.02 * (1 - (r / Rb0) ** 2), 0.0)
    orne = np.zeros(u.shape, dtype=bool)
    if filet:                   # un filet d'or à l'intérieur de l'émail
        f = np.abs(r - 0.735) - 0.012
        orne |= f < 0
        h += 0.02 * np.clip(-f / 0.012, 0, 1)
    if clous:                   # des clous d'or sur l'émail, au bord
        th = np.arctan2(v, u)
        pas = 2 * math.pi / clous
        tc = np.round(th / pas) * pas
        dc = np.hypot(u - 0.765 * np.cos(tc), v - 0.765 * np.sin(tc)) - (0.022 if clous <= 8 else 0.016)
        orne |= dc < 0
        h += 0.03 * np.clip(-dc / 0.02, 0, 1)
    # l'emblème, frappé au centre
    E = 0.64
    de = embleme(nom, u / E, v / E) * E
    te = np.clip(-de, 0, None)
    h += np.where(de < 0, 0.012 + 0.9 * np.minimum(te, 0.05), 0.0)
    h = h + (R.bruit(N, 23, 5) - 0.5) * 0.001
    n = R.normales(h, N)
    ao = R.occlusion(h, N, N * 0.01)
    c_or = metal(n, OR, ao, 1.0)
    fc, fb = R._hex(EMAIL[nom][0]), R._hex(EMAIL[nom][1])
    lum = np.clip(np.hypot(u + 0.28, v + 0.34) / 1.1, 0, 1)[..., None]
    email = fc * (1 - lum) + fb * lum
    email = email * (1 - 0.35 * lisse(0.72, 0.80, r)[..., None])
    # l'ombre de l'emblème sur l'émail (la lumière vient d'en haut à gauche)
    ombre = embleme(nom, (u - 0.025) / E, (v - 0.03) / E) * E
    email = email * (1 - 0.45 * lisse(0.03, -0.01, ombre)[..., None] * (de >= 0)[..., None])
    e = environnement(reflet(n))[..., None]
    email = email * ao[..., None] + e * 0.05
    est_or = bague | orne | (de < 0)
    col = np.where(est_or[..., None], c_or, email)
    alpha = lisse(Rb1 + 0.006, Rb1 - 0.006, r)
    garde = R.SORTIE
    R.SORTIE = SORTIE
    R.ecrire(nom_fichier(nom), S, ss, col, alpha)
    R.SORTIE = garde


def nom_fichier(nom):
    return "rang-%s.png" % nom


def planche():
    fond = Image.new("RGBA", (len(RANGS) * 330 + 30, 520), (8, 12, 11, 255))
    for i, nom in enumerate(RANGS):
        im = Image.open(os.path.join(SORTIE, nom_fichier(nom)))
        fond.alpha_composite(im.resize((300, 300), Image.LANCZOS), (30 + i * 330, 20))
        fond.alpha_composite(im.resize((110, 110), Image.LANCZOS), (125 + i * 330, 360))
    fond.save(os.path.join(SORTIE, "_planche-rangs.png"))
    print("planche écrite")


if __name__ == "__main__":
    os.makedirs(SORTIE, exist_ok=True)
    for nom in RANGS:
        medaillon_rang(nom)
    planche()
