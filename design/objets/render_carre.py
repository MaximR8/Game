# -*- coding: utf-8 -*-
"""La fabrique du Carré des astres (FEATURES ② et ④, 27/09) : le tapis de jeu, les cadres de case,
les pierres des chiffres et les emblèmes des pouvoirs. Même éclairage que render_objets.py (l'or des
emblèmes de la barre, l'émail des médaillons) : rien n'est dessiné à la main.

Maxim, 26/09, sur les maquettes HTML : « les looks doivent être design pro d'un jeu HD ».

    python render_carre.py            # tout → carre/ (puis copier carre/*.png dans proto_degagement/carre/)
    python render_carre.py --planche  # seulement la planche de contrôle (carre/_planche.png)

Les mesures sont en pixels du jeu (l'écran fait 1080 × 2400) ; K dit combien de pixels d'image on
rend par pixel du jeu (1,5 : plus fin que l'écran du téléphone, qui agrandit le jeu de 1,13)."""
import os, sys, math
import numpy as np
from PIL import Image
import render_objets as R
from render_objets import lisse, norme, metal, environnement, reflet, OR, etoile_sdf, polygone_sdf, contour_courbe

BASE = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(BASE, "carre")
K = 1.5

# ── Le plateau (en pixels du jeu) : 3 × 3 cases de 300 × 420, 20 d'écart, un cadre de 36 ──
CASE_W, CASE_H, ECART, CADRE = 300.0, 420.0, 20.0, 36.0
N = 3
TAPIS_W = CADRE * 2 + N * CASE_W + (N - 1) * ECART      # 1012
TAPIS_H = CADRE * 2 + N * CASE_H + (N - 1) * ECART      # 1372
RAYON_TAPIS, RAYON_CASE = 40.0, 22.0

LAQUE_CENTRE = R._hex("#1d1738")
LAQUE_BORD = R._hex("#0c0a18")
LAQUE_CANAL = R._hex("#0a0813")


def grille_rect(Wg, Hg, k=K):
    W, H = int(round(Wg * k)), int(round(Hg * k))
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    return W, H, (x + 0.5) / k, (y + 0.5) / k


def normales_px(h, k=K, relief=1.0):
    dy, dx = np.gradient(h * relief, 1.0 / k)
    return norme(np.stack([-dx, -dy, np.ones_like(h)], axis=-1))


def occlusion_px(h, rayon_g, force=0.5, k=K):
    b = R.flou_boite(h, max(1, int(rayon_g * k)))
    return 1.0 - force * np.clip((b - h) / 2.0, 0, 1)


def ecrire_rect(nom, col, alpha, dossier=None):
    col = np.clip(col, 0, 1)
    col = 1.0 - np.exp(-col * 1.55)
    col = col / (1.0 - math.exp(-1.55))
    col = np.clip(col, 0, 1) ** (1 / 1.08)
    img = np.dstack([col, alpha])
    Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(dossier or SORTIE, nom))
    print("écrit", nom, img.shape[1], "×", img.shape[0])


def bourrelet(t, largeur, haut):
    """Un jonc bombé (demi-cylindre aplati) de 0 à `largeur`."""
    x = np.clip(t / largeur, 0, 1)
    return np.where((t >= 0) & (t <= largeur), haut * np.clip(np.sin(np.pi * x), 0, None) ** 0.6, 0.0)


def trait_sdf(x, y, ax, ay, bx, by):
    ex, ey = bx - ax, by - ay
    t = np.clip(((x - ax) * ex + (y - ay) * ey) / (ex * ex + ey * ey), 0, 1)
    return np.hypot(x - ax - ex * t, y - ay - ey * t)


def laque(n, base, ao, brillance=0.35):
    """La laque du tapis : un fond profond, un reflet net et étroit, un peu d'environnement sur les bords."""
    diff = np.clip(np.sum(n * R.L_CLE, -1), 0, 1)[..., None]
    spec = np.clip(np.sum(n * R.H_CLE, -1), 0, 1)[..., None] ** 90 * brillance
    fres = (0.04 + 0.96 * (1 - np.clip(n[..., 2:3], 0, 1)) ** 5)
    e = environnement(reflet(n))[..., None]
    col = base * (0.62 + 0.38 * diff) + e * fres * 0.30 + spec * np.array([0.95, 0.93, 1.0])
    return col * ao[..., None]


def cases_rect():
    for r in range(N):
        for c in range(N):
            x0 = CADRE + c * (CASE_W + ECART)
            y0 = CADRE + r * (CASE_H + ECART)
            yield x0, y0, x0 + CASE_W, y0 + CASE_H


# ───────────────────────── Le tapis ─────────────────────────
def tapis(nom="tapis-carre.png"):
    W, H, x, y = grille_rect(TAPIS_W, TAPIS_H)
    d_tapis = R._rect_arrondi(x, y, 0, 0, TAPIS_W, TAPIS_H, RAYON_TAPIS)
    t = -d_tapis                                        # la profondeur depuis le bord
    # le cadre : un jonc d'or, un canal d'émail nuit semé d'étoiles, un filet d'or
    h_jonc = bourrelet(t, 9.0, 5.0)
    h_filet = bourrelet(t - 27.0, 7.0, 3.6)
    canal = (t > 9.0) & (t < 27.0)
    # les étoiles du canal, à pas régulier sur chaque côté (les coins ont leur rosace)
    d_et = np.full(x.shape, 99.0, dtype=np.float32)
    mil = 18.0
    pas = 92.0
    for cote in range(4):
        long = TAPIS_W if cote % 2 == 0 else TAPIS_H
        nb = int((long - 2 * 80.0) // pas)
        debut = (long - nb * pas) / 2 + pas / 2
        for i in range(nb):
            s = debut + i * pas
            cx, cy = [(s, mil), (TAPIS_W - mil, s), (s, TAPIS_H - mil), (mil, s)][cote]
            d_et = np.minimum(d_et, etoile_sdf(x - cx, y - cy, 4, 9.0, 2.6))
    h_etoiles = np.where(canal, 2.6 * np.clip(-d_et / 2.2, 0, 1), 0.0)
    # les rosaces des coins : une bague d'or et une étoile à huit branches
    d_ros = np.full(x.shape, 99.0, dtype=np.float32)
    h_ros = np.zeros(x.shape, dtype=np.float32)
    for (cx, cy) in [(30, 30), (TAPIS_W - 30, 30), (30, TAPIS_H - 30), (TAPIS_W - 30, TAPIS_H - 30)]:
        rr = np.hypot(x - cx, y - cy)
        bague = bourrelet(rr - 17.0, 6.0, 3.5)
        etoile = np.clip(-etoile_sdf(x - cx, y - cy, 8, 15.0, 5.5) / 4.0, 0, 1) * 3.2
        disque = rr < 23.5
        h_ros = np.maximum(h_ros, np.where(disque, np.maximum(bague, etoile) + 1.0, 0.0))
        d_ros = np.minimum(d_ros, rr - 23.5)
    # le champ : la laque, avec un astrolabe gravé à l'or (des traits fins, une seule teinte)
    champ = t >= 34.0
    cx, cy = TAPIS_W / 2, TAPIS_H / 2
    rr = np.hypot(x - cx, y - cy)
    th = np.arctan2(y - cy, x - cx)
    grav = np.zeros(x.shape, dtype=np.float32)
    for rayon in (138.0, 300.0, 318.0):
        grav = np.maximum(grav, lisse(1.6, 0.4, np.abs(rr - rayon)))
    # les graduations entre les deux anneaux du milieu, plus longues tous les 30°
    pas_a = math.radians(5.0)
    k_a = np.round(th / pas_a)
    d_a = np.abs(th - k_a * pas_a) * rr
    longue = (np.mod(k_a, 6) == 0)
    grad = (d_a < 0.9) & (rr > 300.0) & (rr < np.where(longue, 338.0, 318.0))
    grav = np.maximum(grav, grad.astype(np.float32) * lisse(1.3, 0.5, d_a))
    d_rose = etoile_sdf(x - cx, y - cy, 8, 118.0, 26.0)
    grav = np.maximum(grav, lisse(1.4, 0.3, np.abs(d_rose)))
    # les cases : des alvéoles creusées, bordées d'un filet d'or
    d_case = np.full(x.shape, 99.0, dtype=np.float32)
    for (x0, y0, x1, y1) in cases_rect():
        d_case = np.minimum(d_case, R._rect_arrondi(x, y, x0, y0, x1, y1, RAYON_CASE))
    fond_case = 1.6 - 5.0 * lisse(0.0, -6.0, d_case)                 # la paroi, puis le fond
    h_liseret = bourrelet(d_case, 4.5, 2.4)
    h_champ = np.where(d_case < 0, fond_case, 1.6 + h_liseret) - 0.35 * grav
    # tout assemblé
    h = np.where(champ, h_champ, 0.0) + h_jonc + h_filet + np.where(canal, 0.6 + h_etoiles, 0.0)
    h = np.where(d_ros < 0, np.maximum(h, h_ros), h)
    h = h + (R.bruit_rect(W, H, 60, 11).astype(np.float32) - 0.5) * 0.02
    n = normales_px(h, relief=0.9)
    ao = occlusion_px(h, 7.0, 0.55)
    # les matières
    est_or = (h_jonc > 0) | (h_filet > 0) | ((h_etoiles > 0.02) & canal) | (d_ros < 0) | (champ & (h_liseret > 0.01) & (d_case >= 0))
    c_or = metal(n, OR, ao, 1.0)
    # la laque : plus claire au centre ; un poli large qui descend en travers
    k_c = np.clip(np.hypot((x - cx) / (TAPIS_W * 0.62), (y - cy) / (TAPIS_H * 0.62)), 0, 1)[..., None]
    base = LAQUE_CENTRE * (1 - k_c) + LAQUE_BORD * k_c
    poli = (0.5 + 0.5 * np.cos((x * 0.45 + y - 420.0) / 380.0))[..., None]
    base = base * (0.88 + 0.16 * poli)
    n1 = R.bruit_rect(W, H, 5, 71).astype(np.float32)
    n2 = R.bruit_rect(W, H, 11, 72).astype(np.float32)
    neb = lisse(0.45, 0.85, 0.65 * n1 + 0.35 * n2)[..., None]
    base = base * (1 - 0.5 * neb) + (base * 0.5 + R._hex("#2a1d52") * 0.5) * neb
    teal = lisse(0.55, 0.9, R.bruit_rect(W, H, 4, 73).astype(np.float32))[..., None]
    base = base * (1 - 0.35 * teal) + R._hex("#123a3a") * 0.35 * teal
    base = np.where((d_case < 0)[..., None], base * 0.78, base)             # le fond des alvéoles, plus sombre
    base = np.where(canal[..., None], LAQUE_CANAL, base)
    c_laque = laque(n, base, ao)
    # la gravure : de l'or pâle au fond du trait
    or_grave = R._hex("#caa968")
    c_laque = c_laque * (1 - 0.48 * grav[..., None]) + or_grave * (0.48 * grav)[..., None] * ao[..., None]
    rng = np.random.default_rng(5)
    poussiere = np.zeros(x.shape, dtype=np.float32)
    for i in range(420):
        px, py = rng.uniform(40, TAPIS_W - 40), rng.uniform(40, TAPIS_H - 40)
        rx0, rx1 = int(max(0, (px - 4) * K)), int(min(W, (px + 4) * K))
        ry0, ry1 = int(max(0, (py - 4) * K)), int(min(H, (py + 4) * K))
        d2 = (x[ry0:ry1, rx0:rx1] - px) ** 2 + (y[ry0:ry1, rx0:rx1] - py) ** 2
        poussiere[ry0:ry1, rx0:rx1] += np.exp(-d2 / 0.5) * (0.10 + 0.30 * rng.random())
    c_laque = c_laque + (poussiere * ao)[..., None] * R._hex("#efe9dc")
    col = np.where(est_or[..., None], c_or, c_laque)
    alpha = np.clip(0.5 - d_tapis * K, 0, 1)
    ecrire_rect(nom, col, alpha)


# ───────────────────────── Les cadres de case (sous la carte) ─────────────────────────
EMAUX = {
    # nom : (clair, sombre) de l'émail
    "jade": ("#3fae88", "#0e3a2c"),
    "rose": ("#c8485f", "#4a0f1f"),
}


def cadre_case(nom, style):
    """Ce qui entoure la carte dans son alvéole : un émail à la couleur du camp (jade, carmin), un
    filet d'or pour la case où l'on peut poser, ou la glace d'une case gelée. Le centre est vide :
    la carte le couvre (ou, pour la case ciblée, on voit le fond de l'alvéole)."""
    marge = 14.0
    Wg, Hg = CASE_W + 2 * marge, CASE_H + 2 * marge
    W, H, x, y = grille_rect(Wg, Hg)
    d = R._rect_arrondi(x, y, marge, marge, marge + CASE_W, marge + CASE_H, RAYON_CASE)
    t = -d
    if style in EMAUX:
        clair, sombre = R._hex(EMAUX[style][0]), R._hex(EMAUX[style][1])
        # l'émail remplit toute l'alvéole : une cuvette, plus claire vers le haut, un biseau vif au bord
        h = 2.0 * lisse(0.0, 7.0, t) + 0.6 * lisse(7.0, 40.0, t)
        n = normales_px(h, relief=1.0)
        ao = occlusion_px(h, 5.0, 0.4)
        k = np.clip((y - marge) / CASE_H, 0, 1)[..., None]
        teinte = clair * (1 - k) * 0.95 + sombre * k + clair * 0.05
        diff = np.clip(np.sum(n * R.L_CLE, -1), 0, 1)[..., None]
        spec = np.clip(np.sum(n * R.H_CLE, -1), 0, 1)[..., None] ** 110 * 1.2
        fres = (0.05 + 0.95 * (1 - np.clip(n[..., 2:3], 0, 1)) ** 4)
        e = environnement(reflet(n))[..., None]
        col = (teinte * (0.55 + 0.45 * diff) * (1 - fres) + e * fres * 0.6 + spec) * ao[..., None]
        # un filet d'or tout au bord
        f = bourrelet(t, 3.2, 1.0) > 0.02
        col = np.where(f[..., None], metal(normales_px(bourrelet(t, 3.2, 1.6)), OR, np.ones(t.shape), 1.0), col)
        alpha = np.clip(0.5 + t * K, 0, 1)
    elif style == "cible":
        # « ici » : un jonc d'or vif et épais, un filet intérieur, et un voile de jade net sur le fond
        h = bourrelet(t, 8.0, 3.4) + bourrelet(t - 13.0, 3.0, 1.2)
        n = normales_px(h)
        c_or = metal(n, OR * 1.12, np.ones(t.shape), 1.0)
        est_or = (h > 0.02)
        jade = R._hex("#5fd3a8")
        col = np.where(est_or[..., None], c_or, jade * 0.9)
        dedans = np.clip(0.5 + t * K, 0, 1)
        alpha = np.where(est_or, 1.0, 0.20 + 0.10 * lisse(60.0, 16.0, t)) * dedans
    elif style == "gel":
        # une plaque de glace : du verre pâle, un biseau net, un givre en étoiles fines
        h = 2.4 * lisse(0.0, 9.0, t)
        n = normales_px(h)
        fres = (0.06 + 0.94 * (1 - np.clip(n[..., 2:3], 0, 1)) ** 3)
        e = environnement(reflet(n))[..., None]
        spec = np.clip(np.sum(n * R.H_CLE, -1), 0, 1)[..., None] ** 140 * 1.6
        teinte = R._hex("#bfe3f2")
        col = teinte * 0.55 + e * fres * 0.7 + spec
        rng = np.random.default_rng(7)
        givre = np.zeros(x.shape, dtype=np.float32)
        for i in range(26):
            px, py, s = rng.uniform(30, Wg - 30), rng.uniform(30, Hg - 30), rng.uniform(6.0, 13.0)
            givre = np.maximum(givre, np.clip(-etoile_sdf(x - px, y - py, 6, s, s * 0.18) / 1.2, 0, 1))
        col = col + givre[..., None] * 0.55
        alpha = np.clip(0.5 + t * K, 0, 1) * (0.46 + 0.4 * lisse(12.0, 0.0, t) + 0.3 * givre)
    else:
        raise ValueError(style)
    ecrire_rect(nom, col, alpha)


# ───────────────────────── Les pierres des chiffres ─────────────────────────
def chiffre(nom, style, S=128, ss=3):
    """La pierre qui porte un chiffre : un cabochon d'émail bas (pour que le chiffre se lise), serti
    d'une bague d'or. Jade : tes cartes ; carmin : les siennes."""
    Nn, u, v = R.grille(S, ss)
    r = np.hypot(u, v)
    Rb0, Rb1 = 0.78, 0.97
    bague = (r >= Rb0) & (r <= Rb1)
    tb = np.clip((r - Rb0) / (Rb1 - Rb0), 0, 1)
    h = np.where(bague, 0.07 * np.sin(np.pi * tb) ** 0.7, 0.0)
    h = h + np.where(r < Rb0, 0.035 * (1 - (r / Rb0) ** 2), 0.0)
    n = R.normales(h, Nn)
    ao = R.occlusion(h, Nn, Nn * 0.01)
    c_or = metal(n, OR, ao, 1.0)
    clair, sombre = R._hex(EMAUX[style][0]), R._hex(EMAUX[style][1])
    lum = np.clip(np.hypot(u + 0.30, v + 0.36) / 1.15, 0, 1)[..., None]
    email = clair * (1 - lum) + sombre * lum
    email = email * (0.55 + 0.25 * (1 - lum))
    email = email * (1 - 0.30 * lisse(0.66, 0.78, r)[..., None])
    spec = np.clip(np.sum(n * R.H_CLE, -1), 0, 1)[..., None] ** 160 * 0.5
    col = np.where(bague[..., None], c_or, email + spec)
    alpha = lisse(Rb1 + 0.006, Rb1 - 0.006, r)
    garde = R.SORTIE
    R.SORTIE = SORTIE
    R.ecrire(nom, S, ss, col, alpha)
    R.SORTIE = garde


# ───────────────────────── Les emblèmes des pouvoirs ─────────────────────────
def capsule(u, v, ax, ay, bx, by, r):
    return trait_sdf(u, v, ax, ay, bx, by) - r


def fleche(u, v, ax, ay, bx, by, ep, tete):
    """Une flèche de a vers b : un fût et une pointe triangulaire."""
    lx, ly = bx - ax, by - ay
    ln = math.hypot(lx, ly)
    dx, dy = lx / ln, ly / ln
    px, py = -dy, dx
    base_x, base_y = bx - dx * tete * 1.2, by - dy * tete * 1.2
    fut = capsule(u, v, ax, ay, base_x, base_y, ep)
    tri = polygone_sdf(u, v, [(bx, by), (base_x + px * tete, base_y + py * tete), (base_x - px * tete, base_y - py * tete)])[0]
    return np.minimum(fut, tri)


def embleme_pouvoir_sdf(nom, u, v):
    if nom == "foudre":          # Thor
        return polygone_sdf(u, v, [(0.20, -0.94), (-0.50, 0.12), (-0.04, 0.12), (-0.24, 0.94), (0.54, -0.20), (0.08, -0.20), (0.34, -0.94)])[0]
    if nom == "esquive":         # Kitsune : le coup qui passe à côté — une flèche qui contourne
        cy = 0.18
        rr = np.hypot(u, v - cy)
        th = np.arctan2(v - cy, u)
        arc = np.abs(rr - 0.66) - 0.085
        dans = (th < -math.radians(8)) & (th > -math.radians(172))
        arc = np.where(dans, arc, 9.0)
        a_fin = -math.radians(8)
        bx, by = 0.66 * math.cos(a_fin), cy + 0.66 * math.sin(a_fin)
        tete = polygone_sdf(u, v, [(bx - 0.25, by - 0.02), (bx + 0.25, by - 0.02), (bx + 0.02, by + 0.34)])[0]
        a0 = -math.radians(172)
        ax_, ay_ = 0.66 * math.cos(a0), cy + 0.66 * math.sin(a0)
        bout = np.hypot(u - ax_, v - ay_) - 0.085
        et = etoile_sdf(u, v - 0.40, 4, 0.40, 0.11)
        return np.minimum(np.minimum(np.minimum(arc, tete), bout), et)
    if nom == "rempart":         # Golem : l'écu, frappé d'une étoile
        ecu = contour_courbe([((-0.72, -0.80), (0.72, -0.80), 0.08), ((0.72, -0.80), (0.0, 0.96), 0.22), ((0.0, 0.96), (-0.72, -0.80), 0.22)], 12)
        d = polygone_sdf(u, v, ecu)[0]
        creux = np.abs(d + 0.16) - 0.035
        et = etoile_sdf(u, v + 0.06, 4, 0.36, 0.10)
        return np.minimum(np.maximum(d, -creux), et)
    if nom == "maree":           # Bahamut : deux vagues
        d = np.full(u.shape, 9.0)
        for y0 in (-0.26, 0.30):
            onde = np.abs(v - (y0 + 0.17 * np.sin(u * 4.2 + 0.6))) - 0.11
            d = np.minimum(d, np.maximum(onde, np.abs(u) - 0.86))
        return d
    if nom == "gel":             # Yéti : le flocon
        d = np.full(u.shape, 9.0)
        for k in range(6):
            a = math.pi / 2 + k * math.pi / 3
            ca, sa = math.cos(a), math.sin(a)
            d = np.minimum(d, capsule(u, v, 0, 0, 0.88 * ca, 0.88 * sa, 0.075))
            for s in (-1, 1):
                b = a + s * math.radians(38)
                mx, my = 0.52 * ca, 0.52 * sa
                d = np.minimum(d, capsule(u, v, mx, my, mx + 0.26 * math.cos(b), my + 0.26 * math.sin(b), 0.058))
        return np.minimum(d, polygone_sdf(u, v, [(0.22 * math.cos(math.pi / 6 + k * math.pi / 3), 0.22 * math.sin(math.pi / 6 + k * math.pi / 3)) for k in range(6)])[0])
    if nom == "meta":            # Loki : l'échange
        return np.minimum(fleche(u, v, -0.82, -0.32, 0.86, -0.32, 0.085, 0.26), fleche(u, v, 0.82, 0.34, -0.86, 0.34, 0.085, 0.26))
    if nom == "ame":             # Anubis : l'ânkh
        boucle = np.abs(np.hypot(u / 0.34, (v + 0.46) / 0.40) - 1.0) * 0.36 - 0.075
        barre = capsule(u, v, -0.60, -0.02, 0.60, -0.02, 0.085)
        tige = capsule(u, v, 0, -0.02, 0, 0.92, 0.095)
        return np.minimum(np.minimum(boucle, barre), tige)
    if nom == "faim":            # Fenrir : trois griffures
        d = np.full(u.shape, 9.0)
        for dx in (-0.42, 0.0, 0.42):
            pts = contour_courbe([((dx + 0.30, -0.86), (dx - 0.30, 0.86), 0.10), ((dx - 0.30, 0.86), (dx + 0.30, -0.86), 0.02)], 8)
            d = np.minimum(d, polygone_sdf(u, v, pts)[0] - 0.02)
        return d
    if nom == "tetes":           # Cerbère : l'attaque en diagonale
        d = np.hypot(u, v) - 0.20
        for (sx, sy) in [(1, 1), (1, -1), (-1, 1), (-1, -1)]:
            d = np.minimum(d, fleche(u, v, sx * 0.26, sy * 0.26, sx * 0.86, sy * 0.86, 0.075, 0.22))
        return d
    if nom == "maledic":         # Baba Yaga : l'œil
        amande = np.maximum(np.hypot(u, v + 0.62) - 1.0, np.hypot(u, v - 0.62) - 1.0)
        iris = np.hypot(u, v) - 0.31
        pupille = np.hypot(u, v) - 0.15
        d = np.maximum(amande, -iris)
        return np.minimum(d, pupille)
    raise ValueError(nom)


POUVOIRS = ["foudre", "esquive", "rempart", "maree", "gel", "meta", "ame", "faim", "tetes", "maledic"]


def embleme_pouvoir(nom, e, S=192, ss=3):
    Nn, u, v = R.grille(S, ss)
    u, v = u * 1.08, v * 1.08
    d = embleme_pouvoir_sdf(e, u, v)
    tt = np.clip(-d, 0, None)
    h = 0.9 * np.minimum(tt, 0.075)
    h = h + (R.bruit(Nn, 23, 5) - 0.5) * 0.001
    n = R.normales(h, Nn)
    ao = R.occlusion(h, Nn, Nn * 0.01)
    col = metal(n, OR, ao, 1.0)
    alpha = lisse(0.006, -0.006, d)
    garde = R.SORTIE
    R.SORTIE = SORTIE
    R.ecrire(nom, S, ss, col, alpha)
    R.SORTIE = garde


# ───────────────────────── La planche de contrôle ─────────────────────────
def planche():
    """Le tapis avec, posés dessus, les cadres et quelques pierres — pour juger d'un coup d'œil."""
    t = Image.open(os.path.join(SORTIE, "tapis-carre.png"))
    W, H = t.size
    fond = Image.new("RGBA", (W + 700, H + 40), (8, 11, 10, 255))
    fond.alpha_composite(t, (20, 20))
    marge = 14.0
    for i, st in enumerate(["jade", "rose", "cible", "gel"]):
        im = Image.open(os.path.join(SORTIE, "case-%s.png" % st))
        r, c = [(0, 0), (1, 1), (0, 2), (2, 1)][i]
        x0 = CADRE + c * (CASE_W + ECART) - marge
        y0 = CADRE + r * (CASE_H + ECART) - marge
        fond.alpha_composite(im, (20 + int(round(x0 * K)), 20 + int(round(y0 * K))))
    for i, st in enumerate(["jade", "rose"]):
        im = Image.open(os.path.join(SORTIE, "chiffre-%s.png" % st))
        fond.alpha_composite(im, (W + 60 + i * 150, 40))
    for i, e in enumerate(POUVOIRS):
        im = Image.open(os.path.join(SORTIE, "pouvoir-%s.png" % e)).resize((120, 120), Image.LANCZOS)
        fond.alpha_composite(im, (W + 60 + (i % 4) * 150, 220 + (i // 4) * 150))
    fond.convert("RGB").save(os.path.join(SORTIE, "_planche.png"))
    print("planche écrite")


if __name__ == "__main__":
    os.makedirs(SORTIE, exist_ok=True)
    if "--planche" not in sys.argv:
        tapis()
        for st in ["jade", "rose", "cible", "gel"]:
            cadre_case("case-%s.png" % st, st)
        for st in ["jade", "rose"]:
            chiffre("chiffre-%s.png" % st, st)
        for e in POUVOIRS:
            embleme_pouvoir("pouvoir-%s.png" % e, e)
    planche()
