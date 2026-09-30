# -*- coding: utf-8 -*-
"""Rendu des objets du plateau (pièces, bonus) en relief : carte de hauteur + éclairage métal/ivoire/jade.
Sortie : PNG RGBA à côté de ce script, utilisables tels quels dans la maquette et dans Godot.
Il faut numpy et Pillow : `python -m pip install numpy pillow`, puis `python render_objets.py`."""
import os, sys, math
BASE = os.path.dirname(os.path.abspath(__file__))
import numpy as np
from PIL import Image

SORTIE = BASE
os.makedirs(SORTIE, exist_ok=True)


def lisse(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def norme(v):
    return v / np.maximum(np.linalg.norm(v, axis=-1, keepdims=True), 1e-8)


def flou_boite(img, k):
    """Flou rectangulaire séparable (sommes cumulées), k = demi-largeur en pixels."""
    if k < 1:
        return img
    out = img
    for axe in (0, 1):
        pad = [(0, 0), (0, 0)]
        pad[axe] = (k + 1, k)
        c = np.cumsum(np.pad(out, pad, mode="edge"), axis=axe)
        if axe == 0:
            out = (c[2 * k + 1:, :] - c[:-2 * k - 1, :]) / (2 * k + 1)
        else:
            out = (c[:, 2 * k + 1:] - c[:, :-2 * k - 1]) / (2 * k + 1)
    return out


def bruit(n, cellules, graine):
    rng = np.random.default_rng(graine)
    g = rng.random((cellules + 1, cellules + 1))
    x = np.linspace(0, cellules, n, endpoint=False)
    i = np.floor(x).astype(int)
    f = x - i
    f = f * f * (3 - 2 * f)
    a = g[i][:, i] * (1 - f)[None, :] + g[i][:, i + 1] * f[None, :]
    b = g[i + 1][:, i] * (1 - f)[None, :] + g[i + 1][:, i + 1] * f[None, :]
    return a * (1 - f)[:, None] + b * f[:, None]


L_CLE = norme(np.array([-0.46, -0.62, 0.64]))
L_CONTRE = norme(np.array([0.62, 0.42, 0.66]))
VUE = np.array([0.0, 0.0, 1.0])
H_CLE = norme(L_CLE + VUE)
H_CONTRE = norme(L_CONTRE + VUE)


def environnement(R):
    haut = -R[..., 1]
    base = 0.05 + 0.80 * lisse(-0.25, 0.95, haut)
    horizon = 0.28 * np.exp(-((haut - 0.08) / 0.16) ** 2)
    boite = np.clip(np.sum(R * L_CLE, axis=-1), 0, 1) ** 14 * 2.1
    contre = np.clip(np.sum(R * L_CONTRE, axis=-1), 0, 1) ** 7 * 0.55
    sol = 0.06 * lisse(0.1, -0.9, haut)
    return np.clip(base - horizon + boite + contre - sol, 0, None)


def reflet(n):
    return 2.0 * n[..., 2:3] * n - VUE


def metal(n, albedo, ao, mat=1.0):
    mat = np.asarray(mat, dtype=np.float64)
    if mat.ndim == 2:
        mat = mat[..., None]
    e = environnement(reflet(n))[..., None]
    diff = np.clip(np.sum(n * L_CLE, -1), 0, 1)[..., None]
    spec = np.clip(np.sum(n * H_CLE, -1), 0, 1)[..., None] ** 80
    spec2 = np.clip(np.sum(n * H_CONTRE, -1), 0, 1)[..., None] ** 60 * 0.35
    col = albedo * (0.08 + 0.30 * diff + (0.95 * mat + 0.25 * (1 - mat)) * e) + (spec * 1.2 + spec2) * np.array([1.0, 0.96, 0.84])
    return col * ao[..., None]


def ivoire(n, ao):
    alb = np.array([0.95, 0.915, 0.835])
    diff = np.clip(np.sum(n * L_CLE, -1), 0, 1)[..., None]
    contre = np.clip(np.sum(n * L_CONTRE, -1), 0, 1)[..., None] * 0.22
    spec = np.clip(np.sum(n * H_CLE, -1), 0, 1)[..., None] ** 70 * 0.7
    fres = (0.04 + 0.96 * (1 - np.clip(n[..., 2:3], 0, 1)) ** 5)
    e = environnement(reflet(n))[..., None]
    col = alb * (0.30 + 0.62 * diff + contre) * (1 - 0.5 * fres) + e * fres * 0.6 + spec
    return col * ao[..., None]


def email_jade(n, ao, lum=1.0):
    alb = np.array([0.16, 0.62, 0.46]) * lum
    diff = np.clip(np.sum(n * L_CLE, -1), 0, 1)[..., None]
    spec = np.clip(np.sum(n * H_CLE, -1), 0, 1)[..., None] ** 120 * 1.6
    fres = (0.05 + 0.95 * (1 - np.clip(n[..., 2:3], 0, 1)) ** 4)
    e = environnement(reflet(n))[..., None]
    col = alb * (0.35 + 0.65 * diff) * (1 - fres) + e * fres * 0.8 + spec
    return col * ao[..., None]


OR = np.array([1.0, 0.74, 0.30])
ARGENT = np.array([0.86, 0.885, 0.93])


def grille(S, ss):
    N = S * ss
    y, x = np.mgrid[0:N, 0:N].astype(np.float64)
    u = (x + 0.5) / N * 2 - 1
    v = (y + 0.5) / N * 2 - 1
    return N, u, v


def normales(h, N):
    dv, du = np.gradient(h, 2.0 / N)
    return norme(np.stack([-du, -dv, np.ones_like(h)], axis=-1))


def occlusion(h, N, rayon_px):
    b = flou_boite(h, max(1, int(rayon_px)))
    return 1.0 - 0.42 * np.clip((b - h) / 0.03, 0, 1)


def ecrire(nom, S, ss, col, alpha):
    col = np.clip(col, 0, 1)
    col = 1.0 - np.exp(-col * 1.55)          # tonalité douce : pas de blanc cramé
    col = col / (1.0 - math.exp(-1.55))
    col = np.clip(col, 0, 1) ** (1 / 1.08)
    prem = col * alpha[..., None]
    p = prem.reshape(S, ss, S, ss, 3).mean(axis=(1, 3))
    a = alpha.reshape(S, ss, S, ss).mean(axis=(1, 3))
    rgb = p / np.maximum(a, 1e-6)[..., None]
    img = np.dstack([rgb, a])
    Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(SORTIE, nom))
    print("écrit", nom, S, "px")


# ───────────────────────── Formes (distances signées, rayon de l'objet = 1) ─────────────────────────
def etoile_sdf(px, py, n, ro, ri):
    r = np.hypot(px, py)
    th = np.arctan2(py, px)
    a = math.pi / n
    phi = np.mod(th + a * 0, 2 * a)
    phi = np.where(phi > a, 2 * a - phi, phi)
    x1, y1 = ro, 0.0
    x2, y2 = ri * math.cos(a), ri * math.sin(a)
    ex, ey = x2 - x1, y2 - y1
    ln = math.hypot(ex, ey)
    nx, ny = ey / ln, -ex / ln
    qx, qy = r * np.cos(phi), r * np.sin(phi)
    return (qx - x1) * nx + (qy - y1) * ny


def rect_arrondi_sdf(px, py, hx, hy, rad, angle):
    c, s = math.cos(angle), math.sin(angle)
    qx, qy = c * px + s * py, -s * px + c * py
    dx, dy = np.abs(qx) - (hx - rad), np.abs(qy) - (hy - rad)
    return np.hypot(np.maximum(dx, 0), np.maximum(dy, 0)) + np.minimum(np.maximum(dx, dy), 0) - rad


def grenetis(u, v, Rn, rayon, nombre, taille):
    th = np.arctan2(v, u)
    pas = 2 * math.pi / nombre
    tb = np.round(th / pas) * pas
    d = np.hypot(u - rayon * Rn * np.cos(tb), v - rayon * Rn * np.sin(tb))
    return np.exp(-(d / (taille * Rn)) ** 2)


# ───────────────────────── Les objets ─────────────────────────
def hauteur_piece(motif, N, u, v, graine):
    """Le relief d'une face de pièce : son bord, son grènetis, son motif (étoile ou lune)."""
    Rn = 0.92
    rr = np.minimum(np.hypot(u, v) / Rn, 1.0)
    h = 0.075 * lisse(0.78, 0.865, rr) - 0.11 * lisse(0.92, 1.0, rr) ** 1.6 - 0.012 * (1 - np.clip(rr / 0.78, 0, 1) ** 2)
    h += 0.022 * grenetis(u, v, Rn, 0.71, 48, 0.022)
    px, py = u / Rn, v / Rn
    if motif == "etoile":
        d = etoile_sdf(px, py, 8, 0.44, 0.2)
        releve = lisse(0.022, -0.022, d)
        anneau = lisse(0.02, 0.0, np.abs(np.hypot(px, py) - 0.56) - 0.012)
        h += 0.05 * releve + 0.028 * anneau + 0.02 * lisse(0.09, 0.06, np.hypot(px, py))
    else:
        d1 = np.hypot(px, py) - 0.40
        d2 = np.hypot(px - 0.17, py + 0.07) - 0.33
        releve = lisse(0.022, -0.022, np.maximum(d1, -d2))
        h += 0.055 * releve
    h += (bruit(N, 9, graine) - 0.5) * 0.004 + (bruit(N, 31, graine + 7) - 0.5) * 0.0018
    return h, releve


def relief_pieces(nom, S=512, ss=2):
    """Pour la poussette 3D (FEATURES ⑦, 25/09) : les deux faces côte à côte (étoile à gauche,
    lune à droite), chacune sur toute la face du disque. R, G : la normale (x, y) ; B : l'occlusion ;
    A : le motif en relief. Le jeu éclaire la pièce avec le même modèle métal, en temps réel."""
    moities = []
    for motif, graine in (("etoile", 1), ("lune", 2)):
        N, u, v = grille(S, ss)
        u, v = u * 0.92, v * 0.92          # le disque (rayon 0,92) remplit la case
        h, releve = hauteur_piece(motif, N, u, v, graine)
        n = normales(h, N)
        ao = occlusion(h, N, N * 0.012)
        rgba = np.dstack([n[..., 0] * 0.5 + 0.5, n[..., 1] * 0.5 + 0.5, ao, releve])
        rgba = rgba.reshape(S, ss, S, ss, 4).mean(axis=(1, 3))
        moities.append(rgba)
    img = np.concatenate(moities, axis=1)
    Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(SORTIE, nom))
    print("écrit", nom, img.shape[1], "x", img.shape[0])


def piece(nom, motif, S=128, ss=3, graine=1):
    N, u, v = grille(S, ss)
    Rn = 0.92
    rr = np.minimum(np.hypot(u, v) / Rn, 1.0)
    h = 0.075 * lisse(0.78, 0.865, rr) - 0.11 * lisse(0.92, 1.0, rr) ** 1.6 - 0.012 * (1 - np.clip(rr / 0.78, 0, 1) ** 2)
    h += 0.022 * grenetis(u, v, Rn, 0.71, 48, 0.022)
    px, py = u / Rn, v / Rn
    if motif == "etoile":
        d = etoile_sdf(px, py, 8, 0.44, 0.2)
        releve = lisse(0.022, -0.022, d)
        anneau = lisse(0.02, 0.0, np.abs(np.hypot(px, py) - 0.56) - 0.012)
        h += 0.05 * releve + 0.028 * anneau + 0.02 * lisse(0.09, 0.06, np.hypot(px, py))
    else:
        d1 = np.hypot(px, py) - 0.40
        d2 = np.hypot(px - 0.17, py + 0.07) - 0.33
        releve = lisse(0.022, -0.022, np.maximum(d1, -d2))
        h += 0.055 * releve
    h += (bruit(N, 9, graine) - 0.5) * 0.004 + (bruit(N, 31, graine + 7) - 0.5) * 0.0018
    n = normales(h, N)
    ao = occlusion(h, N, N * 0.012)
    mat = 1.0 - 0.3 * releve
    col = metal(n, OR, ao, mat)
    alpha = (np.hypot(u, v) / Rn <= 1.0).astype(np.float64)
    ecrire(nom, S, ss, col, alpha)


def jeton_xp(nom, S=128, ss=3):
    N, u, v = grille(S, ss)
    Rn = 0.92
    rr = np.minimum(np.hypot(u, v) / Rn, 1.0)
    h = 0.07 * lisse(0.76, 0.84, rr) - 0.11 * lisse(0.92, 1.0, rr) ** 1.6 - 0.01 * (1 - np.clip(rr / 0.76, 0, 1) ** 2)
    h += 0.02 * grenetis(u, v, Rn, 0.69, 40, 0.022)
    px, py = u / Rn, v / Rn
    d = etoile_sdf(px, py, 4, 0.52, 0.14)
    releve = lisse(0.02, -0.02, d)
    h += 0.06 * releve + 0.02 * lisse(0.08, 0.05, np.hypot(px, py))
    h += (bruit(N, 11, 5) - 0.5) * 0.003
    n = normales(h, N)
    ao = occlusion(h, N, N * 0.012)
    c_or = metal(n, OR, ao, 0.85)
    c_ar = metal(n, ARGENT, ao, 1.0)
    m = lisse(0.01, -0.01, d)[..., None]
    col = c_ar * (1 - m) + c_or * m
    alpha = (np.hypot(u, v) / Rn <= 1.0).astype(np.float64)
    ecrire(nom, S, ss, col, alpha)


def medaillon(nom, S=160, ss=3):
    N, u, v = grille(S, ss)
    Rn = 0.92
    rr = np.minimum(np.hypot(u, v) / Rn, 1.0)
    champ = rr < 0.8
    h = 0.08 * lisse(0.78, 0.845, rr) - 0.12 * lisse(0.93, 1.0, rr) ** 1.6 + 0.03 * (1 - np.clip(rr / 0.8, 0, 1) ** 2)
    perles = grenetis(u, v, Rn, 0.73, 40, 0.02)
    h += 0.02 * perles
    px, py = u / Rn, v / Rn
    ang = math.radians(-8)
    dcarte = rect_arrondi_sdf(px, py, 0.25, 0.34, 0.06, ang)
    carte = lisse(0.02, -0.02, dcarte)
    dint = np.abs(rect_arrondi_sdf(px, py, 0.19, 0.28, 0.035, ang)) - 0.011
    rainure = lisse(0.012, -0.004, dint) * carte
    c, s = math.cos(ang), math.sin(ang)
    qx, qy = c * px + s * py, -s * px + c * py
    dgem = np.abs(qx) / 0.085 + np.abs(qy) / 0.125 - 1.0
    gem = lisse(0.08, -0.08, dgem)
    h += 0.05 * carte - 0.012 * rainure + 0.025 * gem * (1 - np.clip(np.abs(qx) / 0.085 + np.abs(qy) / 0.125, 0, 1))
    n = normales(h, N)
    ao = occlusion(h, N, N * 0.012)
    c_or = metal(n, OR, ao, 0.9)
    c_iv = ivoire(n, ao)
    c_jd = email_jade(n, ao, 1.1)
    m_or = np.clip(np.maximum(lisse(0.79, 0.8, rr), np.maximum(carte, lisse(0.35, 0.6, perles) * champ)), 0, 1)
    col = c_iv * (1 - m_or)[..., None] + c_or * m_or[..., None]
    col = col * (1 - gem)[..., None] + c_jd * gem[..., None]
    alpha = (np.hypot(u, v) / Rn <= 1.0).astype(np.float64)
    ecrire(nom, S, ss, col, alpha)


def eclat(nom, S=192, ss=3):
    N, u, v = grille(S, ss)
    Rn = 0.92
    r = np.hypot(u, v)
    rr = np.minimum(r / Rn, 1.0)
    h = 0.085 * lisse(0.84, 0.9, rr) - 0.12 * lisse(0.94, 1.0, rr) ** 1.6
    h += (bruit(N, 13, 3) - 0.5) * 0.003
    n_monture = normales(h, N)
    ao = occlusion(h, N, N * 0.01)
    c_or = metal(n_monture, OR, ao, 1.0)
    # la pierre : dôme taillé, enveloppe basse de plans (table, étoiles, bezels, haléfis)
    g = 0.865 * Rn
    qx, qy = u / g, v / g
    plans = [(0.0, 0.0, 0.0, 0.30)]
    for k in range(8):
        plans.append((math.radians(k * 45), 0.40, 0.45, 0.30))
    for k in range(8):
        plans.append((math.radians(k * 45 + 22.5), 0.62, 0.62, 0.215))
    for k in range(16):
        plans.append((math.radians(k * 22.5 + 11.25), 0.86, 0.95, 0.075))
    hauteurs = []
    for th, a, sl, za in plans:
        if sl == 0:
            hauteurs.append(np.full_like(qx, za))
        else:
            hauteurs.append(za - sl * (qx * math.cos(th) + qy * math.sin(th) - a))
    Hs = np.stack(hauteurs, axis=0)
    idx = np.argmin(Hs, axis=0)
    pente = np.array([p[2] for p in plans])[idx]
    theta = np.array([p[0] for p in plans])[idx]
    ng = norme(np.stack([pente * np.cos(theta), pente * np.sin(theta), np.ones_like(qx)], axis=-1))
    hasard = (np.sin(idx * 12.9898 + 4.1) * 43758.5453) % 1.0
    nz = ng[..., 2:3]
    fres = 0.05 + 0.95 * (1 - nz) ** 3
    profond = np.array([0.0, 0.10, 0.075])
    moyen = np.array([0.05, 0.50, 0.35])
    clair = np.array([0.58, 1.0, 0.82])
    corps = profond + (moyen - profond) * (0.25 + 0.75 * nz) * (0.55 + 0.8 * hasard[..., None])
    rg = np.hypot(qx, qy)[..., None]
    lueur = clair * np.exp(-(rg / 0.34) ** 2) * 0.22
    e = environnement(reflet(ng))[..., None] * np.array([0.8, 1.0, 0.92])
    # lumière ponctuelle : le reflet glisse sur chaque facette au lieu de la remplir
    hz = np.min(Hs, axis=0)
    pos = np.stack([qx, qy, hz], axis=-1)
    Lp = norme(np.array([-0.75, -0.95, 1.5]) - pos)
    Hp = norme(Lp + VUE)
    Lq = norme(np.array([0.9, 0.7, 1.2]) - pos)
    Hq = norme(Lq + VUE)
    spec = np.clip(np.sum(ng * Hp, -1), 0, 1)[..., None] ** 260 * 2.4 + np.clip(np.sum(ng * Hq, -1), 0, 1)[..., None] ** 200 * 0.9
    c_gem = corps * (1 - fres) + e * fres * 0.8 + lueur + spec * np.array([0.95, 1.0, 0.97])
    m_gem = (rr < 0.868)[..., None].astype(np.float64)
    ombre_serti = 1.0 - 0.45 * lisse(0.80, 0.868, rr)[..., None]
    col = c_or * (1 - m_gem) + c_gem * ombre_serti * m_gem
    alpha = (r / Rn <= 1.0).astype(np.float64)
    ecrire(nom, S, ss, col, alpha)


# ───────────────────────── L'univers (FEATURES ⑭, 25/09) ─────────────────────────
# L'étoile d'invocation, la poussière d'étoile, les pierres élémentaires et la pierre de lune.
# Même éclairage que les pièces ; des facettes nettes, ni halo ni lueur autour.

def polygone_sdf(px, py, pts):
    """Distance signée exacte à un polygone (convexe ou non) : négative dedans. Renvoie aussi
    l'indice de l'arête la plus proche (la facette)."""
    pts = np.asarray(pts, dtype=np.float64)
    n = len(pts)
    dmin = np.full(px.shape, np.inf)
    idx = np.zeros(px.shape, dtype=np.int32)
    dedans = np.zeros(px.shape, dtype=bool)
    for i in range(n):
        ax, ay = pts[i]
        bx, by = pts[(i + 1) % n]
        ex, ey = bx - ax, by - ay
        wx, wy = px - ax, py - ay
        t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
        d = np.hypot(wx - ex * t, wy - ey * t)
        plus = d < dmin
        dmin = np.where(plus, d, dmin)
        idx = np.where(plus, i, idx)
        if ay != by:
            croise = ((ay > py) != (by > py)) & (px < (bx - ax) * (py - ay) / (by - ay) + ax)
            dedans ^= croise
    return np.where(dedans, -dmin, dmin), idx


def contour_courbe(cotes, pas=6):
    """Un contour fait d'arcs : chaque côté (a, b, bombé) devient `pas` segments."""
    out = []
    for (ax, ay), (bx, by), bombe in cotes:
        nx, ny = (by - ay), -(bx - ax)
        ln = math.hypot(nx, ny)
        nx, ny = nx / ln, ny / ln
        for k in range(pas):
            t = k / pas
            x = ax + (bx - ax) * t + nx * bombe * 4 * t * (1 - t)
            y = ay + (by - ay) * t + ny * bombe * 4 * t * (1 - t)
            out.append((x, y))
    return out


def forme(nom):
    """Les silhouettes des pierres, dans un disque de rayon ~0,88 (la case du lot)."""
    if nom == "trillion":      # Feu : le triangle de l'alchimie, pointe en haut
        a = [(0.0, -0.84), (0.80, 0.56), (-0.80, 0.56)]
        return contour_courbe([(a[0], a[1], 0.09), (a[1], a[2], 0.09), (a[2], a[0], 0.09)], 5)
    if nom == "losange":       # Foudre : l'éclair
        return [(0.0, -0.88), (0.48, -0.08), (0.0, 0.88), (-0.48, -0.08)]
    if nom == "goutte":        # Eau
        cy, r = 0.24, 0.58
        sommet = (0.0, -0.88)
        # les tangentes du sommet au cercle
        dist = abs(sommet[1] - cy)
        alpha = math.acos(r / dist)
        base = -math.pi / 2          # la direction du centre vers le sommet
        th0, th1 = base + alpha, base - alpha + 2 * math.pi
        pts = [sommet]
        for k in range(17):
            th = th0 + (th1 - th0) * k / 16
            pts.append((r * math.cos(th), cy + r * math.sin(th)))
        return pts
    if nom == "hexagone":      # Glace : le cristal
        return [(0.82 * math.cos(math.radians(90 + 60 * k)), 0.82 * math.sin(math.radians(90 + 60 * k))) for k in range(6)]
    if nom == "marquise":      # Nature : la feuille
        return contour_courbe([((0.0, -0.88), (0.0, 0.88), 0.46), ((0.0, 0.88), (0.0, -0.88), 0.46)], 8)
    if nom == "ovale":         # Esprit
        return [(0.64 * math.cos(2 * math.pi * k / 16), 0.84 * math.sin(2 * math.pi * k / 16)) for k in range(16)]
    if nom == "octogone":      # Roche : la taille émeraude
        hx, hy, c = 0.62, 0.82, 0.22
        return [(-hx + c, -hy), (hx - c, -hy), (hx, -hy + c), (hx, hy - c), (hx - c, hy), (-hx + c, hy), (-hx, hy - c), (-hx, -hy + c)]
    if nom == "rond":          # Lune : le cabochon
        return [(0.76 * math.cos(2 * math.pi * k / 64), 0.82 * math.sin(2 * math.pi * k / 64)) for k in range(64)]
    raise ValueError(nom)


PIERRES = {
    # type : (silhouette, profond, moyen, clair)
    "feu":    ("trillion", (0.20, 0.015, 0.0), (0.88, 0.20, 0.05), (1.0, 0.72, 0.42)),
    "foudre": ("losange",  (0.03, 0.04, 0.22), (0.30, 0.42, 1.0), (0.84, 0.90, 1.0)),
    "eau":    ("goutte",   (0.0, 0.08, 0.12), (0.06, 0.52, 0.66), (0.62, 0.95, 1.0)),
    "glace":  ("hexagone", (0.10, 0.20, 0.28), (0.60, 0.82, 0.94), (0.96, 1.0, 1.0)),
    "nature": ("marquise", (0.02, 0.10, 0.02), (0.26, 0.62, 0.16), (0.80, 0.98, 0.56)),
    "esprit": ("ovale",    (0.08, 0.02, 0.18), (0.56, 0.36, 0.92), (0.94, 0.84, 1.0)),
    "roche":  ("octogone", (0.06, 0.035, 0.02), (0.42, 0.25, 0.12), (0.92, 0.66, 0.40)),
}
SERTI = 0.07


def _serti(u, v, pts, N, largeur=SERTI):
    """Le serti clos : une bande de métal bombée tout autour de la pierre."""
    d, _ = polygone_sdf(u, v, pts)
    t = np.clip(d / largeur, 0, 1)
    h = np.where((d > 0) & (d < largeur), 0.05 * np.sin(np.pi * t) ** 0.7, 0.0)
    return d, h


# ───────────────────────── L'export 3D (FEATURES ⑭, 26/09) ─────────────────────────
# Pour que les objets soient éclairés EN DIRECT dans la machine, comme les pièces : leurs reflets
# bougent quand ils penchent. Chaque objet donne deux images et un contour :
#   <nom>-relief.png : R, G la normale (x, y) ; B l'occlusion ; A la matière
#                      (0 or · 85 argent · 170 pierre ou verre · 255 roche) ;
#   <nom>-corps.png  : la couleur du corps (ce qui ne dépend pas de la lumière) et la couverture ;
#   contours.json    : la silhouette, pour extruder le volume (unités de l'image : de −1 à 1).
EXPORT_3D = None          # le dossier où écrire, ou None
MAT_OR, MAT_ARGENT, MAT_PIERRE, MAT_ROCHE = 0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0
_CONTOURS = {}


def decaler(pts, w):
    """Le contour poussé vers l'extérieur de w (polygone étoilé autour du centre)."""
    pts = [np.array(q, dtype=np.float64) for q in pts]
    n = len(pts)
    aire = sum(pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1] for i in range(n))
    signe = 1.0 if aire > 0 else -1.0
    def normale(a, b):
        e = b - a
        m = np.array([e[1], -e[0]]) * signe
        return m / max(np.linalg.norm(m), 1e-9)
    out = []
    for i in range(n):
        n1 = normale(pts[i - 1], pts[i])
        n2 = normale(pts[i], pts[(i + 1) % n])
        b = n1 + n2
        b = b / max(np.linalg.norm(b), 1e-9)
        out.append((pts[i] + b * w / max(0.35, float(np.dot(b, n1)))).tolist())
    return out


def ecrire_3d(nom, S, ss, n, ao, mat, corps, alpha, contour, dessus_disque=False, sphere=False):
    if EXPORT_3D is None:
        return
    os.makedirs(EXPORT_3D, exist_ok=True)
    def reduire(x):
        return x.reshape(S, ss, S, ss, *x.shape[2:]).mean(axis=(1, 3))
    nn = reduire(n)
    nn = nn / np.maximum(np.linalg.norm(nn, axis=-1, keepdims=True), 1e-6)
    rel = np.dstack([nn[..., 0] * 0.5 + 0.5, nn[..., 1] * 0.5 + 0.5, reduire(np.clip(ao, 0, 1)), reduire(np.asarray(mat, dtype=np.float64))])
    Image.fromarray((np.clip(rel, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(EXPORT_3D, nom + "-relief.png"))
    a = reduire(alpha)
    c = reduire(np.clip(corps, 0, 1) * alpha[..., None]) / np.maximum(a, 1e-6)[..., None]
    Image.fromarray((np.clip(np.dstack([c, a]), 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(EXPORT_3D, nom + "-corps.png"))
    _CONTOURS[nom] = {"contour": [[round(x, 4), round(y, 4)] for x, y in contour], "dessus_disque": dessus_disque,
                      "sphere": sphere}
    print("écrit (3D)", nom)


def ecrire_contours():
    if EXPORT_3D is None:
        return
    import json
    with open(os.path.join(EXPORT_3D, "contours.json"), "w", encoding="utf-8") as f:
        json.dump(_CONTOURS, f, ensure_ascii=False, indent=1)


def _eclairage_pierre(ng, hz, qx, qy, facette, profond, moyen, clair, graine, avec_corps=False):
    hasard = (np.sin(facette * 12.9898 + graine * 7.31) * 43758.5453) % 1.0
    nz = ng[..., 2:3]
    fres = 0.05 + 0.95 * (1 - nz) ** 3
    profond, moyen, clair = np.array(profond), np.array(moyen), np.array(clair)
    corps = profond + (moyen - profond) * (0.25 + 0.75 * nz) * (0.55 + 0.8 * hasard[..., None])
    rg = np.hypot(qx, qy)[..., None]
    lueur = clair * np.exp(-(rg / 0.36) ** 2) * 0.20
    teinte = 0.75 + 0.25 * moyen / max(moyen.max(), 1e-6)
    e = environnement(reflet(ng))[..., None] * teinte
    pos = np.stack([qx, qy, hz], axis=-1)
    Lp = norme(np.array([-0.75, -0.95, 1.5]) - pos)
    Hp = norme(Lp + VUE)
    Lq = norme(np.array([0.9, 0.7, 1.2]) - pos)
    Hq = norme(Lq + VUE)
    spec = np.clip(np.sum(ng * Hp, -1), 0, 1)[..., None] ** 260 * 2.4 + np.clip(np.sum(ng * Hq, -1), 0, 1)[..., None] ** 200 * 0.9
    # des éclats de couleur dans quelques facettes : la lumière qui rebondit au fond de la pierre
    feu = (hasard[..., None] > 0.86) * clair * 0.35 * nz
    col = corps * (1 - fres) + e * fres * 0.8 + lueur + feu + spec * np.array([0.97, 1.0, 0.98])
    return (col, corps + lueur + feu) if avec_corps else col


def pierre(nom, type_id, S=512, ss=2):
    silhouette, profond, moyen, clair = PIERRES[type_id]
    N, u, v = grille(S, ss)
    pts = forme(silhouette)
    d, idx = polygone_sdf(u, v, pts)
    t = np.clip(-d, 0, None)
    # la taille à gradins : trois anneaux de facettes qui suivent le contour, puis la table
    t1, t2, t3 = 0.07, 0.15, 0.24
    h = 1.25 * np.minimum(t, t1) + 0.62 * np.clip(t - t1, 0, t2 - t1) + 0.30 * np.clip(t - t2, 0, t3 - t2)
    anneau = (t > t1).astype(np.int32) + (t > t2) + (t > t3)
    facette = idx * 4 + anneau
    n = normales(h, N)
    ds, hs = _serti(u, v, pts, N)
    ns = normales(hs + (bruit(N, 17, 4) - 0.5) * 0.002, N)
    ao = occlusion(hs, N, N * 0.01)
    c_or = metal(ns, OR, ao, 1.0)
    c_gem, corps = _eclairage_pierre(n, h, u, v, facette, profond, moyen, clair, len(type_id), avec_corps=True)
    ombre_serti = 1.0 - 0.40 * lisse(0.05, 0.0, t)[..., None]
    m_gem = (d <= 0)[..., None].astype(np.float64)
    col = c_or * (1 - m_gem) + c_gem * ombre_serti * m_gem
    alpha = lisse(SERTI + 0.004, SERTI - 0.004, ds)
    ecrire(nom, S, ss, col, alpha)
    dans = d <= 0
    ecrire_3d(nom[:-4], S, ss, np.where(dans[..., None], n, ns), np.where(dans, ombre_serti[..., 0], ao),
              np.where(dans, MAT_PIERRE, MAT_OR), corps, alpha, decaler(pts, SERTI))


def pierre_lune(nom, S=512, ss=2):
    """La pierre de lune : un cabochon laiteux, sans facettes ; dedans flotte un croissant de lumière
    bleue (l'adularescence), serti d'argent."""
    N, u, v = grille(S, ss)
    ax, ay = 0.76, 0.82
    q = (u / ax) ** 2 + (v / ay) ** 2
    h = 0.40 * np.sqrt(np.clip(1 - q, 0, 1))
    n = normales(h, N)
    pts = forme("rond")
    ds, hs = _serti(u, v, pts, N)
    d = np.sqrt(q) - 1.0
    ns = normales(hs, N)
    ao = occlusion(hs, N, N * 0.01)
    c_ar = metal(ns, ARGENT, ao, 1.0)
    nz = n[..., 2:3]
    rr = np.clip(np.sqrt(q), 0, 1)[..., None]
    lait = np.array([0.70, 0.75, 0.82]) * (1 - rr ** 2) + np.array([0.40, 0.46, 0.57]) * rr ** 2
    voile = (bruit(N, 6, 21)[..., None] - 0.5) * 0.08
    # le croissant : un disque moins un disque décalé, vu à travers le dôme (un peu agrandi)
    k = 1.0 / (1.0 + 0.25 * (1 - np.clip(q, 0, 1)))
    su, sv = u * k, v * k
    d1 = np.hypot(su + 0.04, sv + 0.02) - 0.40
    d2 = np.hypot(su - 0.13, sv + 0.10) - 0.35
    croissant = lisse(0.018, -0.018, np.maximum(d1, -d2))
    degrade = np.clip(0.55 + 0.9 * (-su * 0.6 - sv * 0.4), 0.3, 1.2)
    bleu = np.array([0.10, 0.42, 1.0]) * (croissant * degrade)[..., None] * 0.62 - np.array([0.12, 0.06, 0.0]) * croissant[..., None]
    fres = 0.04 + 0.96 * (1 - nz) ** 4
    e = environnement(reflet(n))[..., None]
    spec = lisse(0.9955, 0.998, np.sum(n * H_CLE, -1))[..., None] * 1.2 + lisse(0.993, 0.997, np.sum(n * H_CONTRE, -1))[..., None] * 0.35
    c_gem = (lait + voile + bleu) * (1 - fres * 0.6) + e * fres * 0.6 + spec
    ombre_serti = 1.0 - 0.35 * lisse(-0.06, 0.0, d)[..., None]
    m_gem = (ds <= 0)[..., None].astype(np.float64)
    col = c_ar * (1 - m_gem) + c_gem * ombre_serti * m_gem
    alpha = lisse(SERTI + 0.004, SERTI - 0.004, ds)
    ecrire(nom, S, ss, col, alpha)
    dans = ds <= 0
    ecrire_3d(nom[:-4], S, ss, np.where(dans[..., None], n, ns), np.where(dans, ombre_serti[..., 0], ao),
              np.where(dans, MAT_PIERRE, MAT_ARGENT), lait + voile + bleu, alpha, decaler(pts, SERTI))


def etoile_contour(ro_long=0.95, ro_court=0.64, ri=0.27):
    pts = []
    for k in range(16):
        th = math.radians(-90 + k * 22.5)
        if k % 2 == 1:
            r = ri
        else:
            r = ro_long if k % 4 == 0 else ro_court
        pts.append((r * math.cos(th), r * math.sin(th)))
    return pts


PALETTES_BILLE = {
    # le voile : fond, nuée principale, nuée secondaire, accent ; la teinte des reflets
    "etoile": (("#140d34", "#6a30b4", "#d0589a", "#3456c0"), (0.80, 0.70, 1.0)),
    "poussiere": (("#040b28", "#1b3c9c", "#2c7cc6", "#1a6a96"), (0.66, 0.82, 1.0)),
    # (30/09) le cœur d'étoile : ce que laisse la Supernova — une bille d'or et d'ambre, un soleil au centre
    "coeur": (("#2a1204", "#b8620e", "#f2b440", "#d9523e"), (1.0, 0.84, 0.58)),
}


def _echantillon_boucle(img, uv):
    """Comme _echantillon, mais la largeur boucle (la longitude d'une planète)."""
    H, W = img.shape[:2]
    x = np.mod(uv[..., 0], 1.0) * W - 0.5
    y = np.clip(uv[..., 1] * H - 0.5, 0, H - 1.001)
    x0 = np.floor(x).astype(int)
    y0 = np.floor(y).astype(int)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]
    xa, xb = np.mod(x0, W), np.mod(x0 + 1, W)
    a = img[y0, xa] * (1 - fx) + img[y0, xb] * fx
    b = img[y0 + 1, xa] * (1 - fx) + img[y0 + 1, xb] * fx
    return a * (1 - fy) + b * fy


def _echantillon(img, uv):
    """Lit une image (H, W, C) aux coordonnées uv (de 0 à 1), en bilinéaire."""
    H, W = img.shape[:2]
    x = np.clip(uv[..., 0] * W - 0.5, 0, W - 1.001)
    y = np.clip(uv[..., 1] * H - 0.5, 0, H - 1.001)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]
    a = img[y0, x0] * (1 - fx) + img[y0, x0 + 1] * fx
    b = img[y0 + 1, x0] * (1 - fx) + img[y0 + 1, x0 + 1] * fx
    return a * (1 - fy) + b * fy


def voile_bille(contenu, W=1024):
    """Le voile d'une bille, déroulé comme la carte d'une planète (largeur = 2 × hauteur) et SANS COUTURE
    sur les côtés : le jeu l'enroule sur la sphère par la longitude et la latitude, et le fait tourner
    (26/09 — Maxim : « ça fait encore un peu effet image plate »). Une nébuleuse et ses étoiles."""
    H = W // 2
    (fond, c1, c2, c3), _ = PALETTES_BILLE[contenu]
    graine = {"etoile": 70, "coeur": 110}.get(contenu, 90)

    def sans_couture(a):
        # fondu avec une copie décalée d'une demi-largeur : les deux bords se raccordent
        x = np.arange(W, dtype=np.float64)
        poids = np.sin(np.pi * x / W) ** 2
        return a * poids[None, :] + np.roll(a, W // 2, axis=1) * (1 - poids[None, :])

    n1 = sans_couture(bruit_rect(W, H, 6, graine + 1))
    n2 = sans_couture(bruit_rect(W, H, 14, graine + 2))
    n3 = sans_couture(bruit_rect(W, H, 30, graine + 3))
    # le fondu tasse les écarts : on les étire de nouveau
    def etire(a):
        return np.clip((a - a.mean()) / max(a.std(), 1e-6) * 0.16 + 0.5, 0, 1)
    n1, n2, n3 = etire(n1), etire(n2), etire(n3)
    f = 0.5 * n1 + 0.32 * n2 + 0.18 * n3
    g = 0.55 * n2 + 0.45 * n3
    voile = (_hex(fond) * np.ones((H, W, 1))
             + _hex(c1) * lisse(0.36, 0.74, f)[..., None] * 0.85
             + _hex(c2) * (lisse(0.56, 0.86, g) * lisse(0.42, 0.70, f))[..., None] * 0.6
             + _hex(c3) * lisse(0.58, 0.36, f)[..., None] * 0.35)
    y, x = np.mgrid[0:H, 0:W].astype(np.float64)
    rng = np.random.default_rng(graine)
    pts = np.zeros((H, W))

    def dx_boucle(px):
        d = np.abs(x - px)
        return np.minimum(d, W - d)

    for i in range(420):
        px, py = rng.uniform(0, W), rng.uniform(0, H)
        t = 0.8 + 1.4 * rng.random() ** 4
        # une étoile ronde SUR LA SPHÈRE : plus large en longitude près des pôles
        etire_lon = 1.0 / max(0.25, math.cos((py / H - 0.5) * math.pi))
        dx = dx_boucle(px) / etire_lon
        pts += np.exp(-(dx ** 2 + (y - py) ** 2) / (t * t)) * (0.45 + 0.6 * rng.random())
    for i in range(16):
        px, py, tl = rng.uniform(0, W), rng.uniform(H * 0.2, H * 0.8), 8 + 9 * rng.random()
        dx, dy = dx_boucle(px), np.abs(y - py)
        pts += np.exp(-(dx / 1.1) ** 2) * np.clip(1 - dy / tl, 0, 1) ** 2 + np.exp(-(dy / 1.1) ** 2) * np.clip(1 - dx / tl, 0, 1) ** 2
    return np.clip(voile + np.array([1.0, 0.97, 1.0]) * np.clip(pts, 0, 1.3)[..., None], 0, 1.4)


def coeur_bille(contenu, T=512, ss=2):
    """L'objet au centre, seul (RGBA) : l'étoile d'or éclairée, ou un tourbillon de poussière d'or."""
    N, u, v = grille(T, ss)
    if contenu in ("etoile", "coeur"):
        # le cœur d'étoile : un soleil à huit branches égales, plus trapu (l'étoile d'invocation en a quatre longues)
        forme = etoile_contour(0.96, 0.62, 0.30) if contenu == "etoile" else etoile_contour(0.90, 0.90, 0.46)
        d_et, _ = polygone_sdf(u, v, forme)
        t_et = np.clip(-d_et, 0, None)
        h_et = 0.9 * np.minimum(t_et, 0.2)
        n_et = normales(h_et, N)
        ao = occlusion(h_et, N, N * 0.008)
        col = metal(n_et, OR, ao, 1.0)
        a = lisse(0.006, -0.006, d_et)
    else:
        rng = np.random.default_rng(12)
        grains = np.zeros(u.shape)
        pas = 2.0 / N
        for i in range(1100):
            if i < 820:
                an = rng.random() ** 0.85 * 2.4 * math.pi
                rad = 0.03 + 0.88 * an / (2.4 * math.pi)
                ang = an + (math.pi if i % 2 else 0.0)
                x, y = rad * math.cos(ang) + rng.normal(0, 0.04), rad * math.sin(ang) * 0.9 + rng.normal(0, 0.04)
            else:
                rad = 0.32 * math.sqrt(rng.random())
                ang = rng.random() * 2 * math.pi
                x, y = rad * math.cos(ang), rad * math.sin(ang)
            taille = 0.011 + 0.016 * rng.random() ** 3
            cx, cy = int((x + 1) / pas), int((y + 1) / pas)
            m = int(0.09 / pas)
            y0, y1, x0, x1 = max(cy - m, 0), min(cy + m, N), max(cx - m, 0), min(cx + m, N)
            if y1 <= y0 or x1 <= x0:
                continue
            dd = (u[y0:y1, x0:x1] - x) ** 2 + (v[y0:y1, x0:x1] - y) ** 2
            grains[y0:y1, x0:x1] += np.exp(-dd / (taille * taille)) * (0.55 + 0.8 * rng.random())
        etin = np.zeros(u.shape)
        for (x, y, tl) in [(0.0, 0.0, 0.26), (-0.36, 0.24, 0.14), (0.40, -0.2, 0.12), (0.12, 0.52, 0.10)]:
            dx, dy = np.abs(u - x), np.abs(v - y)
            etin += np.exp(-(dx / 0.012) ** 2) * np.clip(1 - dy / tl, 0, 1) ** 2 + np.exp(-(dy / 0.012) ** 2) * np.clip(1 - dx / tl, 0, 1) ** 2
            etin += np.exp(-((dx ** 2 + dy ** 2) / 0.022 ** 2)) * 1.3
        g_ = np.clip(grains, 0, 1.0)
        e_ = np.clip(etin, 0, 1.0)
        col = _hex("#e8b44a")[None, None, :] * g_[..., None] + np.array([1.0, 0.93, 0.72]) * e_[..., None]
        a = np.clip(g_ + e_, 0, 1)
        col = col / np.maximum(a, 1e-3)[..., None]
    prem = col * a[..., None]
    p = prem.reshape(T, ss, T, ss, 3).mean(axis=(1, 3))
    aa = a.reshape(T, ss, T, ss).mean(axis=(1, 3))
    rgb = p / np.maximum(aa, 1e-6)[..., None]
    return np.dstack([np.clip(rgb, 0, 1), aa])


# Ce que le jeu fait de ces deux images (objets/bille.gdshader) — l'icône suit les mêmes règles.
TAILLE_COEUR = 0.62
L_BILLE = norme(np.array([-0.45, -0.55, 0.70]))


def bille_univers(nom, contenu, S=512, ss=2):
    """Les billes (26/09, Maxim : « l'XP comme l'étoile d'invocation, on dirait des boîtes à médicaments,
    il faut des sphères » ; « l'objet plein centre, pas de bille blanche, le voile sur toute la surface » ;
    puis « là, ça fait une image ronde plutôt qu'une vraie bille en 3D » et « la bille de poussière,
    pas mauve, on va confondre les deux »). Une vraie sphère : le voile enroulé dessus (il se serre vers le
    bord), l'objet qui flotte au centre, grossi par le verre ; l'ombre du côté opposé à la lumière, le
    bord plus sombre, la lumière qui ressort de l'autre côté (teintée), un reflet net."""
    voile = voile_bille(contenu)
    coeur = coeur_bille(contenu)
    _, teinte = PALETTES_BILLE[contenu]
    teinte = np.array(teinte)
    N, u, v = grille(S, ss)
    R = 0.9
    r2 = (u * u + v * v) / (R * R)
    dans = r2 < 1.0
    nz = np.sqrt(np.clip(1 - r2, 0, 1))
    nx, ny = u / R, v / R
    n = np.stack([nx, ny, nz], axis=-1)
    # 1. le voile, enroulé comme une planète : lu par la longitude et la latitude
    lon = np.arctan2(nx, np.maximum(nz, 1e-4))
    lat = np.arcsin(np.clip(ny, -1, 1))
    c_voile = _echantillon_boucle(voile, np.stack([0.5 + lon / (2 * math.pi) + 0.08, 0.5 + lat / math.pi], axis=-1))
    # 2. le volume : le côté de la lumière, le côté de l'ombre, le bord plus sombre
    lum = 0.40 + 0.60 * np.clip(np.sum(n * L_BILLE, -1), 0, 1)
    bord = 0.45 + 0.55 * np.clip(nz, 0, 1) ** 0.6
    col = c_voile * (lum * bord)[..., None]
    dl = -L_BILLE[:2] / np.linalg.norm(L_BILLE[:2])
    rxy = np.hypot(nx, ny)
    caust = lisse(0.35, 0.95, nx * dl[0] + ny * dl[1]) * lisse(0.2, 0.7, rxy) * (1 - lisse(0.85, 1.0, rxy))
    col = col + teinte * (caust * 0.35)[..., None]
    # 3. l'objet au centre, dans le verre
    c_coeur = _echantillon(coeur, np.stack([0.5 + 0.5 * (u / R) / TAILLE_COEUR, 0.5 + 0.5 * (v / R) / TAILLE_COEUR], axis=-1))
    hors = (np.abs(u / R) > TAILLE_COEUR) | (np.abs(v / R) > TAILLE_COEUR)
    a_c = np.where(hors, 0.0, c_coeur[..., 3]) * 0.95
    col = col * (1 - a_c[..., None]) + c_coeur[..., :3] * (0.85 + 0.15 * lum)[..., None] * a_c[..., None]
    # 4. le verre : un Fresnel teinté, des reflets nets
    fres = 0.04 + 0.96 * (1 - np.clip(nz, 0, 1)) ** 4
    e = environnement(reflet(n))
    col = col * (1 - 0.5 * fres)[..., None] + teinte * (e * fres * 0.6)[..., None]
    # le reflet de la fenêtre : un petit point vif, et un arc fin le long du bord, côté lumière
    #    (une pastille blanche ronde faisait « gommette »)
    point = lisse(0.9960, 0.9985, np.sum(n * H_CLE, -1)) * 1.2
    vers = np.array([-0.63, -0.77])
    cos_tl = (nx * vers[0] + ny * vers[1]) / np.maximum(rxy, 1e-4)
    arc = lisse(0.62, 0.70, rxy) * (1 - lisse(0.82, 0.88, rxy)) * lisse(0.55, 0.85, cos_tl) * 0.6
    spec = point + arc + lisse(0.9975, 0.999, np.sum(n * H_CONTRE, -1)) * 0.3
    col = col + spec[..., None]
    couvre = lisse(1.0 + 0.01, 1.0 - 0.01, np.sqrt(r2))
    ecrire(nom, S, ss, col, couvre)
    # pour le jeu : le voile et l'objet, à part (objets/bille.gdshader les assemble en direct)
    if EXPORT_3D is not None:
        os.makedirs(EXPORT_3D, exist_ok=True)
        base = nom[:-4]
        tv = np.clip(voile, 0, 1)
        Image.fromarray((tv * 255 + 0.5).astype(np.uint8), "RGB").resize((512, 256), Image.LANCZOS).save(os.path.join(EXPORT_3D, base + "-voile.png"))
        Image.fromarray((np.clip(coeur, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").resize((256, 256), Image.LANCZOS).save(os.path.join(EXPORT_3D, base + "-coeur.png"))
        cercle = [(0.905 * math.cos(2 * math.pi * k2 / 48), 0.905 * math.sin(2 * math.pi * k2 / 48)) for k2 in range(48)]
        _CONTOURS[base] = {"contour": [[round(x, 4), round(y, 4)] for x, y in cercle], "dessus_disque": False, "sphere": True,
                           "teinte": [round(float(c), 3) for c in teinte]}
        print("écrit (3D)", base)


def poussiere_etoile(nom, S=512, ss=2):
    bille_univers(nom, "poussiere", S, ss)


def etoile_invocation(nom, S=512, ss=2):
    bille_univers(nom, "etoile", S, ss)


# ───────────────────────── Les emblèmes des menus (FEATURES ⑮, 25/09) ─────────────────────────
# Des emblèmes d'or en relief, taillés à arêtes vives comme l'étoile : ils vivent dans la barre du bas.

def _spirale(u, v, k=3.0, r0=0.13, r1=0.90):
    r = np.hypot(u, v) + 1e-6
    th = np.arctan2(v, u)
    d = np.full(u.shape, 9.0)
    for phase in (0.0, math.pi):
        bras = k * np.log(r / r0) + phase
        delta = np.mod(th - bras + math.pi, 2 * math.pi) - math.pi
        w = 0.11 * (1 - np.clip((r - r0) / (r1 - r0), 0, 1)) + 0.025
        da = np.abs(delta) * r / math.sqrt(1 + k * k) - w
        da = np.where((r > r0 * 0.9) & (r < r1), da, 9.0)
        d = np.minimum(d, da)
    return np.minimum(d, r - 0.20)


def _embleme(nom, u, v):
    if nom == "nebuleuse":
        d = _spirale(u, v)
        for (x, y, s) in [(0.62, -0.55, 0.13), (-0.66, 0.50, 0.11), (0.70, 0.40, 0.08)]:
            d = np.minimum(d, etoile_sdf(u - x, v - y, 4, s, s * 0.28))
        return d
    if nom == "astrolabe":
        r = np.hypot(u, v)
        d = np.abs(r - 0.80) - 0.075
        d = np.minimum(d, np.abs(r - 0.36) - 0.035)
        d = np.minimum(d, polygone_sdf(u, v, etoile_contour(0.64, 0.42, 0.17))[0])
        for k in range(16):
            a = k * math.pi / 8
            cx, cy = 0.93 * math.cos(a), 0.93 * math.sin(a)
            d = np.minimum(d, np.hypot(u - cx, v - cy) - (0.045 if k % 2 == 0 else 0.03))
        return d
    if nom == "atlas":
        d_ar = rect_arrondi_sdf(u + 0.20, v - 0.02, 0.36, 0.52, 0.08, math.radians(-14))
        d_av = rect_arrondi_sdf(u - 0.16, v + 0.04, 0.36, 0.52, 0.08, math.radians(8))
        return d_ar, d_av
    if nom == "voyage":
        mont = [(-0.92, 0.62), (-0.40, -0.18), (-0.18, 0.10), (0.22, -0.52), (0.92, 0.62)]
        d = polygone_sdf(u, v, mont)[0]
        d = np.minimum(d, etoile_sdf(u + 0.52, v + 0.62, 4, 0.20, 0.055))
        return d
    if nom == "presages":
        d1 = np.hypot(u + 0.06, v) - 0.72
        d2 = np.hypot(u - 0.26, v + 0.14) - 0.62
        d = np.maximum(d1, -d2)
        d = np.minimum(d, etoile_sdf(u - 0.40, v - 0.34, 4, 0.24, 0.065))
        d = np.minimum(d, etoile_sdf(u - 0.62, v + 0.40, 4, 0.14, 0.04))
        return d
    raise ValueError(nom)


def embleme_rendu(fichier, e, S=256, ss=3):
    N, u, v = grille(S, ss)
    u, v = u * 1.06, v * 1.06
    formes = _embleme(e, u, v)
    if e == "atlas":
        d_ar, d_av = formes
        t_ar, t_av = np.clip(-d_ar, 0, None), np.clip(-d_av, 0, None)
        h_ar = 0.9 * np.minimum(t_ar, 0.07)
        h_av = 0.08 + 0.9 * np.minimum(t_av, 0.07)
        cadre = lisse(0.012, 0.0, np.abs(rect_arrondi_sdf(u - 0.16, v + 0.04, 0.25, 0.41, 0.05, math.radians(8))) - 0.012)
        c, s = math.cos(math.radians(8)), math.sin(math.radians(8))
        qx, qy = c * (u - 0.16) + s * (v + 0.04), -s * (u - 0.16) + c * (v + 0.04)
        losange = np.abs(qx) / 0.11 + np.abs(qy) / 0.16 - 1.0
        h_av = h_av - 0.02 * cadre + 0.06 * np.clip(-losange, 0, 1)
        h = np.where(d_av <= 0, h_av, np.where(d_ar <= 0, h_ar, 0.0))
        d = np.minimum(d_ar, d_av)
        ombre = np.where((d_av > 0) & (d_ar <= 0), 1.0 - 0.45 * lisse(0.06, 0.0, d_av), 1.0)
    else:
        d = formes
        t = np.clip(-d, 0, None)
        h = 0.9 * np.minimum(t, 0.075)
        ombre = np.ones(u.shape)
    h = h + (bruit(N, 23, 3) - 0.5) * 0.001
    n = normales(h, N)
    ao = occlusion(h, N, N * 0.01)
    col = metal(n, OR, ao, 1.0) * ombre[..., None]
    alpha = lisse(0.006, -0.006, d)
    ecrire(fichier, S, ss, col, alpha)


EMBLEMES = ["nebuleuse", "astrolabe", "atlas", "voyage", "presages"]


def emblemes(S=256):
    global SORTIE
    garde = SORTIE
    SORTIE = os.path.join(BASE, "univers")
    os.makedirs(SORTIE, exist_ok=True)
    for e in EMBLEMES:
        embleme_rendu("nav-%s.png" % e, e, S)
    fond = Image.new("RGBA", (len(EMBLEMES) * 150 + 20, 190), (11, 15, 14, 255))
    for i, e in enumerate(EMBLEMES):
        im = Image.open(os.path.join(SORTIE, "nav-%s.png" % e))
        fond.alpha_composite(im.resize((120, 120), Image.LANCZOS), (25 + i * 150, 12))
        fond.alpha_composite(im.resize((32, 32), Image.LANCZOS), (69 + i * 150, 145))
    fond.save(os.path.join(SORTIE, "_planche-nav.png"))
    print("planche des emblèmes écrite")
    SORTIE = garde


UNIVERS = ["etoile-invocation", "poussiere-etoile", "coeur-etoile"] + ["pierre-%s" % t for t in PIERRES] + ["pierre-lune"]


def univers(S=512):
    global SORTIE
    garde = SORTIE
    SORTIE = os.path.join(BASE, "univers" if S == 512 else "univers-%d" % S)
    os.makedirs(SORTIE, exist_ok=True)
    seul = [a for a in sys.argv[1:] if not a.startswith("--")]
    def veut(nom):
        return not seul or nom in seul
    if veut("etoile-invocation"):
        etoile_invocation("etoile-invocation.png", S)
    if veut("poussiere-etoile"):
        poussiere_etoile("poussiere-etoile.png", S)
    if veut("coeur-etoile"):
        bille_univers("coeur-etoile.png", "coeur", S)
    for t in PIERRES:
        if veut("pierre-" + t):
            pierre("pierre-%s.png" % t, t, S)
    if veut("pierre-lune"):
        pierre_lune("pierre-lune.png", S)
    fond = Image.new("RGBA", (len(UNIVERS) * 150 + 20, 300), (11, 15, 14, 255))
    for i, f in enumerate(UNIVERS):
        chemin = os.path.join(SORTIE, f + ".png")
        if not os.path.exists(chemin):
            continue
        im = Image.open(chemin)
        fond.alpha_composite(im.resize((140, 140), Image.LANCZOS), (15 + i * 150, 20))
        fond.alpha_composite(im.resize((46, 46), Image.LANCZOS), (15 + i * 150 + 47, 210))
    fond.save(os.path.join(SORTIE, "_planche.png"))
    print("planche écrite")
    SORTIE = garde


# ───────────────────────── L'interface (FEATURES ⑮, 26/09) ─────────────────────────
# Les boutons de jeu (épais, avec leur tranche) et les médaillons de la barre du bas.

def _rect_arrondi(x, y, x0, y0, x1, y1, r):
    """Distance signée à un rectangle aux coins arrondis (en pixels)."""
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    hx, hy = (x1 - x0) / 2 - r, (y1 - y0) / 2 - r
    dx, dy = np.abs(x - cx) - hx, np.abs(y - cy) - hy
    return np.hypot(np.maximum(dx, 0), np.maximum(dy, 0)) + np.minimum(np.maximum(dx, dy), 0) - r


def _hex(c):
    c = c.lstrip("#")
    return np.array([int(c[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


BOUTONS = {
    # nom : (haut, milieu, bas de la face), bord, tranche, reflet du haut
    "or": (("#fbe7ab", "#e6bf6c", "#c79a45"), "#7d5a22", ("#7a5520", "#4a3310"), 0.8),
    "sombre": (("#26352f", "#17221e", "#0e1512"), "#caa968", ("#4a3a1c", "#2c2210"), 0.28),
    "eteint": (("#8d8a82", "#6f6c66", "#595650"), "#4a4843", ("#3b3a36", "#262522"), 0.35),
    # l'onglet choisi du Voyage (Aventure · Duel · Classé, 28/09) : l'émail jade de la maquette
    "jade": (("#62b999", "#3f9c7d", "#235f4b"), "#caa968", ("#1a4a3a", "#0c2a20"), 0.45),
}


def bouton_image(nom, style, enfonce, W=200, H=170, R=34, tranche=16, ss=3):
    """Un bouton de jeu : une face émaillée, un filet, et sa tranche en dessous. Enfoncé, la face
    descend dans la tranche. Image 9 tranches : les coins font R + 4, le bas R + tranche + 4."""
    (c0, c1, c2), bord, (t0, t1), reflet = BOUTONS[style]
    c0, c1, c2, bord, t0, t1 = _hex(c0), _hex(c1), _hex(c2), _hex(bord), _hex(t0), _hex(t1)
    N_w, N_h = W * ss, H * ss
    y, x = np.mgrid[0:N_h, 0:N_w].astype(np.float64)
    x, y = (x + 0.5) / ss, (y + 0.5) / ss
    marge = 3.0
    bas_face = H - marge - tranche
    decal = (tranche - 3) if enfonce else 0
    # la tranche : la même forme, de la face jusqu'en bas
    d_tr = _rect_arrondi(x, y, marge, marge + tranche, W - marge, H - marge, R)
    d_face = _rect_arrondi(x, y, marge, marge + decal, W - marge, bas_face + decal, R)
    col = np.zeros((N_h, N_w, 3))
    alpha = np.zeros((N_h, N_w))
    # la tranche, plus sombre vers le bas
    tt = np.clip((y - (marge + tranche)) / (H - 2 * marge - tranche), 0, 1)[..., None]
    c_tr = t0 * (1 - tt) + t1 * tt
    a_tr = lisse(0.8, -0.8, d_tr)
    col = c_tr * a_tr[..., None]
    alpha = a_tr
    # la face : un dégradé à trois tons
    v = np.clip((y - (marge + decal)) / (bas_face - marge), 0, 1)[..., None]
    c_face = np.where(v < 0.45, c0 + (c1 - c0) * (v / 0.45), c1 + (c2 - c1) * ((v - 0.45) / 0.55))
    if enfonce:
        c_face = np.clip(c_face * 1.08, 0, 1)
    # le filet tout autour de la face, et le reflet net du haut
    f_bord = lisse(-3.2, -2.2, d_face)[..., None]
    c_face = c_face * (1 - f_bord) + bord * f_bord
    haut = (np.abs(y - (marge + decal + 5.0)) < 1.3) & (d_face < -5.5)
    c_face = np.where(haut[..., None], c_face * (1 - reflet) + np.array([1.0, 0.99, 0.92]) * reflet, c_face)
    a_face = lisse(0.8, -0.8, d_face)
    col = col * (1 - a_face[..., None]) + c_face * a_face[..., None]
    alpha = np.maximum(alpha, a_face)
    prem = col * alpha[..., None]
    p = prem.reshape(H, ss, W, ss, 3).mean(axis=(1, 3))
    a = alpha.reshape(H, ss, W, ss).mean(axis=(1, 3))
    rgb = p / np.maximum(a, 1e-6)[..., None]
    Image.fromarray((np.clip(np.dstack([rgb, a]), 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(SORTIE, nom))
    print("écrit", nom)


def medaillon_nav(nom, fond_centre, fond_bord, S=256, ss=3):
    """Le médaillon d'un onglet : un émail (sombre, ou jade pour l'onglet actif) dans une bague d'or
    grènetée, en relief et éclairée comme les pièces."""
    N, u, v = grille(S, ss)
    r = np.hypot(u, v)
    Rb0, Rb1 = 0.80, 0.97
    tb = np.clip((r - Rb0) / (Rb1 - Rb0), 0, 1)
    bague = (r >= Rb0) & (r <= Rb1)
    h = np.where(bague, 0.06 * np.sin(np.pi * tb) ** 0.7 + 0.014 * grenetis(u, v, 1.0, 0.885, 44, 0.016), 0.0)
    h += np.where(r < Rb0, 0.02 * (1 - (r / Rb0) ** 2), 0.0)
    n = normales(h, N)
    ao = occlusion(h, N, N * 0.01)
    c_or = metal(n, OR, ao, 1.0)
    rr = np.clip(r / Rb0, 0, 1)[..., None]
    fc, fb = _hex(fond_centre), _hex(fond_bord)
    # l'émail : plus clair en haut à gauche, d'où vient la lumière
    lum = np.clip(np.hypot(u + 0.28, v + 0.34) / 1.1, 0, 1)[..., None]
    email = fc * (1 - lum) + fb * lum
    email = email * (1 - 0.35 * lisse(0.72, 0.80, r)[..., None])
    e = environnement(reflet(n))[..., None]
    email = email + e * 0.05
    col = np.where(bague[..., None], c_or, email)
    alpha = lisse(Rb1 + 0.006, Rb1 - 0.006, r)
    ecrire(nom, S, ss, col, alpha)


def interface():
    global SORTIE
    garde = SORTIE
    SORTIE = os.path.join(BASE, "interface")
    os.makedirs(SORTIE, exist_ok=True)
    for style in BOUTONS:
        bouton_image("bouton-%s.png" % style, style, False)
        bouton_image("bouton-%s-enfonce.png" % style, style, True)
        bouton_image("bouton-%s-petit.png" % style, style, False, W=120, H=100, R=20, tranche=9)
        bouton_image("bouton-%s-petit-enfonce.png" % style, style, True, W=120, H=100, R=20, tranche=9)
    medaillon_nav("medaillon-sombre.png", "#26352f", "#070b09")
    medaillon_nav("medaillon-jade.png", "#48a283", "#0f2f25")
    SORTIE = garde


# ───────────────────────── Le dessus du bloc (26/09) ─────────────────────────
# Maxim, 26/09 : « le poussoir en blanc, je trouve ça pas ouf ». Trois matières à choisir, toutes de
# l'univers ; la texture est ancrée sur la face avant du bloc (elle glisse avec lui).

def _etoiles_nettes(u, v, pts, taille=1.0):
    """Des étoiles nettes (quatre branches fines, un cœur) aux points donnés, en pixels."""
    out = np.zeros(u.shape)
    for (x, y, tl) in pts:
        tl = tl * taille
        dx, dy = np.abs(u - x), np.abs(v - y)
        out += np.exp(-(dx / 1.3) ** 2) * np.clip(1 - dy / tl, 0, 1) ** 2 + np.exp(-(dy / 1.3) ** 2) * np.clip(1 - dx / tl, 0, 1) ** 2
        out += np.exp(-((dx ** 2 + dy ** 2) / 2.2 ** 2)) * 1.4
    return out


def _trait(u, v, a, b, ep=1.1):
    """Un trait fin et net de a à b (pixels)."""
    ax, ay = a
    bx, by = b
    ex, ey = bx - ax, by - ay
    t = np.clip(((u - ax) * ex + (v - ay) * ey) / (ex * ex + ey * ey), 0, 1)
    d = np.hypot(u - ax - ex * t, v - ay - ey * t)
    return lisse(ep + 0.8, ep - 0.3, d)


def bloc_dessus(nom, style, W=1024, H=420):
    y, x = np.mgrid[0:H, 0:W].astype(np.float64)
    u, v = x + 0.5, y + 0.5
    rng = np.random.default_rng(3)
    # un reflet doux et large qui descend en travers (le poli de la surface), pas une tache
    poli = 0.5 + 0.5 * np.cos((u * 0.35 + v - 140) / 260.0)
    if style == "nuit":
        haut, bas = _hex("#1d2a25"), _hex("#0e1613")
        tt = (v / H)[..., None]
        col = haut * (1 - tt) + bas * tt
        col = col * (0.92 + 0.12 * poli[..., None])
        # une constellation gravée à l'or : des traits fins, des étoiles nettes
        figures = [[(120, 330), (210, 250), (330, 285), (420, 190)], [(560, 120), (640, 210), (760, 170), (850, 250), (930, 190)],
                   [(250, 90), (300, 150), (380, 110)], [(640, 340), (720, 300), (800, 360)]]
        grav = np.zeros(u.shape)
        pts = []
        for fig in figures:
            for i in range(len(fig) - 1):
                grav = np.maximum(grav, _trait(u, v, fig[i], fig[i + 1]))
            for p in fig:
                pts.append((p[0], p[1], 11.0 + 5.0 * rng.random()))
        et = np.clip(_etoiles_nettes(u, v, pts), 0, 1.3)
        or_ = _hex("#caa968")
        col = col * (1 - 0.55 * grav[..., None]) + or_ * (0.55 * grav)[..., None]
        col = col + _hex("#f1d28a") * (0.8 * et)[..., None]
        # la poussière d'étoiles de fond, très fine
        for i in range(160):
            px, py = rng.uniform(0, W), rng.uniform(0, H)
            d2 = (u - px) ** 2 + (v - py) ** 2
            col += (np.exp(-d2 / 1.1) * (0.12 + 0.25 * rng.random()))[..., None] * _hex("#efe9dc")
    elif style == "nebuleuse":
        n1 = bruit_rect(W, H, 4, 51)
        n2 = bruit_rect(W, H, 9, 52)
        n3 = bruit_rect(W, H, 19, 53)
        n4 = bruit_rect(W, H, 37, 54)
        f = flou_boite(0.5 * n1 + 0.28 * n2 + 0.14 * n3 + 0.08 * n4, 6)
        g = flou_boite(0.55 * n2 + 0.3 * n3 + 0.15 * n4, 5)
        col = (_hex("#0d0a24")[None, None, :] * np.ones((H, W, 1))
               + _hex("#5a2aa0") * lisse(0.42, 0.80, f)[..., None] * 0.75
               + _hex("#c8508c") * (lisse(0.60, 0.88, g) * lisse(0.45, 0.72, f))[..., None] * 0.55
               + _hex("#2c4fb0") * lisse(0.60, 0.38, f)[..., None] * 0.35)
        col = col * (0.9 + 0.12 * poli[..., None])
        pts = [(rng.uniform(20, W - 20), rng.uniform(20, H - 20), 8 + 9 * rng.random()) for i in range(22)]
        col = col + np.array([1.0, 0.97, 1.0]) * np.clip(_etoiles_nettes(u, v, pts), 0, 1.3)[..., None] * 0.9
        for i in range(260):
            px, py = rng.uniform(0, W), rng.uniform(0, H)
            d2 = (u - px) ** 2 + (v - py) ** 2
            col += (np.exp(-d2 / 1.0) * (0.15 + 0.35 * rng.random()))[..., None] * _hex("#efe9dc")
    else:  # jade : une pierre nuageuse, marbrée de clair, piquée de quelques inclusions sombres
        n1 = bruit_rect(W, H, 3, 61)
        n2 = bruit_rect(W, H, 8, 62)
        n3 = bruit_rect(W, H, 17, 63)
        n4 = bruit_rect(W, H, 41, 64)
        nuage = flou_boite(0.45 * n1 + 0.3 * n2 + 0.17 * n3 + 0.08 * n4, 4)
        clair = lisse(0.52, 0.78, nuage)
        sombre = lisse(0.62, 0.80, flou_boite(0.6 * n3 + 0.4 * n4, 2)) * lisse(0.5, 0.3, nuage)
        col = (_hex("#17493a") * (1 - clair[..., None]) + _hex("#3f8a70") * clair[..., None])
        col = col * (1 - 0.35 * sombre[..., None])
        col = col * (0.88 + 0.2 * poli[..., None])
    img = np.clip(col, 0, 1)
    Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGB").save(os.path.join(SORTIE, nom))
    print("écrit", nom)


def bruit_rect(W, H, cellules, graine):
    """Un bruit doux, sans grille visible : un tirage au hasard sur une petite grille, agrandi en
    bicubique puis lissé (le bruit par valeurs montrait ses carrés sur de grandes surfaces)."""
    from PIL import ImageFilter
    rng = np.random.default_rng(graine)
    cx = max(2, cellules)
    cy = max(2, int(round(cellules * H / W)))
    g = rng.random((cy + 1, cx + 1))
    im = Image.fromarray((g * 255).astype(np.uint8), "L").resize((W, H), Image.BICUBIC)
    im = im.filter(ImageFilter.GaussianBlur(radius=max(1.0, W / cx / 4.0)))
    return np.asarray(im).astype(np.float64) / 255.0


def _bruit_rect_grille(W, H, cellules, graine):
    """(l'ancien bruit par valeurs, gardé pour mémoire)"""
    rng = np.random.default_rng(graine)
    cx = cellules
    cy = max(2, int(round(cellules * H / W)))
    g = rng.random((cy + 2, cx + 2))
    x = np.linspace(0, cx, W, endpoint=False)
    y = np.linspace(0, cy, H, endpoint=False)
    ix, iy = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = x - ix, y - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a = g[iy][:, ix] * (1 - fx)[None, :] + g[iy][:, ix + 1] * fx[None, :]
    b = g[iy + 1][:, ix] * (1 - fx)[None, :] + g[iy + 1][:, ix + 1] * fx[None, :]
    return a * (1 - fy)[:, None] + b * fy[:, None]


def blocs():
    global SORTIE
    garde = SORTIE
    SORTIE = os.path.join(BASE, "interface")
    os.makedirs(SORTIE, exist_ok=True)
    for st in ["nuit", "nebuleuse", "jade"]:
        bloc_dessus("bloc-%s.png" % st, st)
    SORTIE = garde


def banniere(nom, W, H, graine=0, palette="nebuleuse"):
    """Le fond d'une bannière de l'Astrolabe (28/09) : la matière « nebuleuse » du bloc de la machine (choisie par
    Maxim le 26/09), rendue À LA TAILLE où le jeu l'affiche (1 pixel du jeu = 1 pixel de l'image : les étoiles restent
    nettes ; étirée, l'image du bloc les aurait floutées). Les coins s'arrondissent dans le jeu (interface/arrondi.gdshader).
    JPEG : un fond opaque, ~5 fois plus léger qu'en PNG."""
    y, x = np.mgrid[0:H, 0:W].astype(np.float64)
    u, v = x + 0.5, y + 0.5
    rng = np.random.default_rng(3 + graine)
    aire = W * H / (1024.0 * 420.0)
    poli = 0.5 + 0.5 * np.cos((u * 0.35 + v - 140) / 260.0)
    n1 = bruit_rect(W, H, 4, 51 + graine)
    n2 = bruit_rect(W, H, 9, 52 + graine)
    n3 = bruit_rect(W, H, 19, 53 + graine)
    n4 = bruit_rect(W, H, 37, 54 + graine)
    f = flou_boite(0.5 * n1 + 0.28 * n2 + 0.14 * n3 + 0.08 * n4, 6)
    g = flou_boite(0.55 * n2 + 0.3 * n3 + 0.15 * n4, 5)
    # « nebuleuse » : le mauve du bloc ; « nuit » : les couleurs de l'interface (encre, jade, un voile d'or)
    fond, nuage, eclat, froid = {"nebuleuse": ("#0d0a24", "#5a2aa0", "#c8508c", "#2c4fb0"),
                                 "nuit": ("#061116", "#15604f", "#34a08a", "#1b3a6e")}[palette]
    col = (_hex(fond)[None, None, :] * np.ones((H, W, 1))
           + _hex(nuage) * lisse(0.42, 0.80, f)[..., None] * 0.75
           + _hex(eclat) * (lisse(0.60, 0.88, g) * lisse(0.45, 0.72, f))[..., None] * 0.55
           + _hex(froid) * lisse(0.60, 0.38, f)[..., None] * 0.35)
    col = col * (0.9 + 0.12 * poli[..., None])
    pts = [(rng.uniform(20, W - 20), rng.uniform(20, H - 20), 8 + 9 * rng.random()) for i in range(int(22 * aire))]
    col = col + np.array([1.0, 0.97, 1.0]) * np.clip(_etoiles_nettes(u, v, pts), 0, 1.3)[..., None] * 0.9
    for i in range(int(260 * aire)):
        px, py = rng.uniform(0, W), rng.uniform(0, H)
        x0, x1, y0, y1 = int(max(0, px - 4)), int(min(W, px + 5)), int(max(0, py - 4)), int(min(H, py + 5))
        d2 = (u[y0:y1, x0:x1] - px) ** 2 + (v[y0:y1, x0:x1] - py) ** 2
        col[y0:y1, x0:x1] += (np.exp(-d2 / 1.0) * (0.15 + 0.35 * rng.random()))[..., None] * _hex("#efe9dc")
    img = np.clip(col, 0, 1)
    Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGB").save(os.path.join(SORTIE, nom), quality=92)
    print("écrit", nom, W, H)


def bannieres():
    global SORTIE
    garde = SORTIE
    SORTIE = os.path.join(BASE, "interface")
    os.makedirs(SORTIE, exist_ok=True)
    banniere("banniere-peintre.jpg", 1020, 1700)
    banniere("banniere-grand.jpg", 1020, 1700, graine=7, palette="nuit")
    SORTIE = garde


if __name__ == "__main__":
    if "--blocs" in sys.argv:
        blocs()
        sys.exit(0)
    if "--bannieres" in sys.argv:
        bannieres()
        sys.exit(0)
    if "--interface" in sys.argv:
        interface()
        sys.exit(0)
    if "--nav" in sys.argv:
        emblemes()
        sys.exit(0)
    if "--3d" in sys.argv:
        EXPORT_3D = sys.argv[sys.argv.index("--3d") + 1]
        sys.argv.remove(EXPORT_3D)
    if "--univers" in sys.argv:
        taille = 512
        if "--taille" in sys.argv:
            taille = int(sys.argv[sys.argv.index("--taille") + 1])
            sys.argv.remove(str(taille))
        univers(taille)
        ecrire_contours()
        sys.exit(0)
    # 🔴 Rendus en 512 px (25/09) : à 128, agrandis par l'écran du téléphone, ils faisaient « JPEG ».
    haute = "--hd" in sys.argv
    piece("piece-etoile.png", "etoile", S=256 if haute else 128, graine=1)
    piece("piece-lune.png", "lune", S=256 if haute else 128, graine=2)
    jeton_xp("bonus-xp.png", S=512 if haute else 128)
    medaillon("bonus-ticket.png", S=512 if haute else 160)
    eclat("bonus-eclat.png", S=512 if haute else 192)
    if haute:
        relief_pieces("piece-relief.png")
    # planche de contrôle : sur fond d'encre, taille réelle et x3
    fond = Image.new("RGBA", (760, 330), (11, 15, 14, 255))
    x = 16
    for f, t_reel in (("piece-etoile.png", 28), ("piece-lune.png", 28), ("bonus-xp.png", 31), ("bonus-ticket.png", 38), ("bonus-eclat.png", 46)):
        im = Image.open(os.path.join(SORTIE, f))
        grand = im.resize((t_reel * 3, t_reel * 3), Image.LANCZOS)
        petit = im.resize((t_reel, t_reel), Image.LANCZOS)
        fond.alpha_composite(grand, (x, 20))
        fond.alpha_composite(petit, (x + (t_reel * 3 - t_reel) // 2, 200))
        x += t_reel * 3 + 16
    fond.save(os.path.join(SORTIE, "_planche.png"))
    print("planche écrite")
