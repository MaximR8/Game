# -*- coding: utf-8 -*-
"""La Supernova dans le décor peint (02/10/2026) — Maxim : « c'est nickel, sublime, juste la Supernova, l'animation n'est
pas assez spectaculaire ». Les pièces de l'explosion, rendues comme celles de la fabrique (design/objets/render_objets.py) :

  · le MOT : SUPERNOVA en lettres d'or en relief (la police des étiquettes du jeu, Castoro Titling), cerclées d'émail nuit
    comme le cadran, deux étoiles d'or à facettes de part et d'autre ;
  · le RAI : un rayon de lumière effilé, net sur ses bords (pas de halo flou) — l'astrolabe en lance une couronne ;
  · l'ÉCLAT : l'étoile à huit branches du cœur de l'explosion, fine et nette, blanche au centre, dorée aux pointes.

    python design/machines/supernova.py   → design/machines/lunes/mot-supernova.png, rai.png, eclat-nova.png
                                            (et copiées dans proto_degagement/machines/lunes/)"""
import math, os, shutil, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

sys.stdout.reconfigure(encoding="utf-8")
BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(BASE, "..", "objets"))
import render_objets as R  # noqa: E402

SORTIE = os.path.join(BASE, "lunes")
JEU = os.path.join(BASE, "..", "..", "proto_degagement", "machines", "lunes")
POLICE = os.path.join(BASE, "..", "..", "proto_degagement", "polices", "CastoroTitling-Regular.ttf")


def _tonalite(col):
    col = np.clip(col, 0, 1)
    col = 1.0 - np.exp(-col * 1.55)
    col = col / (1.0 - math.exp(-1.55))
    return np.clip(col, 0, 1) ** (1 / 1.08)


def _ecrire(nom, col, alpha, ss, tonalite=True):
    """col (H, W, 3), alpha (H, W) au suréchantillonnage ss → l'image réduite, en alpha droit."""
    if tonalite:
        col = _tonalite(col)
    H, W = alpha.shape
    h, w = H // ss, W // ss
    prem = (col * alpha[..., None])[:h * ss, :w * ss].reshape(h, ss, w, ss, 3).mean(axis=(1, 3))
    a = alpha[:h * ss, :w * ss].reshape(h, ss, w, ss).mean(axis=(1, 3))
    rgb = prem / np.maximum(a, 1e-6)[..., None]
    img = Image.fromarray((np.clip(np.dstack([rgb, a]), 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")
    img.save(os.path.join(SORTIE, nom))
    os.makedirs(JEU, exist_ok=True)
    shutil.copyfile(os.path.join(SORTIE, nom), os.path.join(JEU, nom))
    return img


def _normales(h_px):
    """Les normales d'une hauteur donnée en pixels (une pente de 1 : 45°)."""
    dv, du = np.gradient(h_px)
    return R.norme(np.stack([-du, -dv, np.ones_like(h_px)], axis=-1))


def _bombe(dist, larg):
    """Un profil bombé (un quart de cercle) sur `larg` pixels depuis le bord, plat au-delà."""
    t = np.clip(dist / larg, 0, 1)
    return larg * np.sqrt(t * (2 - t))


def _email(n, ao):
    nz = n[..., 2:3]
    fres = 0.04 + 0.96 * (1 - nz) ** 5
    e = R.environnement(R.reflet(n))[..., None]
    spec = R.lisse(0.996, 0.999, np.sum(n * R.H_CLE, -1))[..., None] * 0.9
    return np.array([0.025, 0.045, 0.12]) * ao[..., None] + e * fres * 0.45 + spec


def mot_supernova(W=1400, H=300, ss=2):
    WI, HI = W * ss, H * ss
    # les lettres, espacées comme une inscription (un peu d'air entre elles)
    taille = int(HI * 0.62)
    police = ImageFont.truetype(POLICE, taille)
    mot = "SUPERNOVA"
    approche = taille * 0.07
    largeurs = [police.getlength(ch) for ch in mot]
    total = sum(largeurs) + approche * (len(mot) - 1)
    etoile_r = HI * 0.17
    place = WI - 2 * (etoile_r * 2.0 + HI * 0.12)
    if total > place:
        taille = int(taille * place / total)
        police = ImageFont.truetype(POLICE, taille)
        approche = taille * 0.07
        largeurs = [police.getlength(ch) for ch in mot]
        total = sum(largeurs) + approche * (len(mot) - 1)
    img = Image.new("L", (WI, HI), 0)
    dr = ImageDraw.Draw(img)
    asc, desc = police.getmetrics()
    bb = police.getbbox("SUPERNOVA")
    y0 = (HI - (bb[3] - bb[1])) / 2 - bb[1]
    x = (WI - total) / 2
    for ch, lw in zip(mot, largeurs):
        dr.text((x, y0), ch, fill=255, font=police)
        x += lw + approche
    lettres = np.asarray(img, dtype=np.float64) / 255.0 > 0.5
    # les deux étoiles à quatre branches, de part et d'autre
    yy, xx = np.mgrid[0:HI, 0:WI].astype(np.float64)
    cy = HI * 0.5
    etoiles = np.zeros((HI, WI), dtype=bool)
    h_et = np.zeros((HI, WI))
    for cx in [(WI - total) / 2 - etoile_r * 1.35, (WI + total) / 2 + etoile_r * 1.35]:
        px, py = (xx - cx) / etoile_r, (yy - cy) / etoile_r
        sdf = R.etoile_sdf(px, py, 4, 1.0, 0.26)
        dans = sdf < 0
        etoiles |= dans
        # des facettes : la hauteur monte vers le centre (le pli des branches fait les arêtes)
        h_et = np.maximum(h_et, np.where(dans, np.clip(-sdf, 0, None) * etoile_r * 0.55, 0.0))
    # l'émail nuit qui cerne lettres et étoiles
    forme = lettres | etoiles
    bord_email = 9 * ss
    email = ndimage.binary_dilation(forme, iterations=bord_email) & ~forme
    d_l = ndimage.distance_transform_edt(lettres)
    h_l = _bombe(d_l, 7.5 * ss) * 1.15
    d_e = ndimage.distance_transform_edt(forme | email)
    h_email = np.where(email, _bombe(d_e, bord_email * 0.8) * 0.35, 0.0)
    h = np.where(lettres, h_l + bord_email * 0.30, 0.0)
    h = np.where(etoiles, h_et + bord_email * 0.30, h)
    h = np.where(email, h_email, h)
    n = _normales(h)
    flou = ndimage.uniform_filter(h, size=9 * ss)
    ao = 1.0 - 0.38 * np.clip((flou - h) / (bord_email * 0.5), 0, 1)
    c_or = R.metal(n, R.OR, ao, 1.0)
    c_email = _email(n, ao)
    col = np.where(forme[..., None], c_or, c_email)
    alpha_forme = ndimage.uniform_filter((forme | email).astype(np.float64), size=max(1, ss))
    # l'ombre portée, courte et nette (posée sous l'inscription, pas un halo)
    ombre = ndimage.shift(alpha_forme, (7 * ss, 0), order=1)
    ombre = ndimage.gaussian_filter(ombre, 2.5 * ss) * 0.55
    alpha = alpha_forme + ombre * (1 - alpha_forme)
    col = np.where(alpha_forme[..., None] > 0.001, col, 0.0)
    col = col * (alpha_forme / np.maximum(alpha, 1e-6))[..., None]      # l'ombre : noire
    return _ecrire("mot-supernova.png", col, alpha, ss)


def rai(W=64, H=512, ss=4):
    """Un rayon effilé, vers le haut : la base en bas (au centre de l'explosion), la pointe en haut ; net sur ses bords."""
    WI, HI = W * ss, H * ss
    yy, xx = np.mgrid[0:HI, 0:WI].astype(np.float64)
    t = 1.0 - (yy + 0.5) / HI                      # 0 à la base, 1 à la pointe
    x = (xx + 0.5) / WI * 2 - 1
    demi = 0.92 * (1.0 - t) ** 1.15
    dans = R.lisse(demi + 0.012, demi - 0.012, np.abs(x))
    coeur = (1 - np.clip(np.abs(x) / np.maximum(demi, 1e-4), 0, 1)) ** 0.6
    intens = (1.0 - t) ** 0.9 * (0.55 + 0.45 * coeur)
    col = np.ones((HI, WI, 3))
    return _ecrire("rai.png", col, dans * intens, ss, tonalite=False)


def eclat_nova(S=512, ss=3):
    """L'étoile du cœur de l'explosion : quatre grandes branches, quatre petites en diagonale, très fines ; blanche au
    centre, dorée vers les pointes ; un petit cœur net."""
    N, u, v = R.grille(S, ss)
    r = np.hypot(u, v)
    th = np.arctan2(v, u)
    # la branche la plus proche : paire (en croix) longue, impaire (en diagonale) courte
    k = np.round(th / (math.pi / 4)).astype(int)
    portee = np.where(k % 2 == 0, 0.98, 0.52)
    larg = 0.05 * (1 - np.clip(r / portee, 0, 1)) ** 1.3
    d_branche = np.abs(np.sin(th - k * math.pi / 4)) * r
    dans = R.lisse(larg + 0.004, larg - 0.004, d_branche) * (r < portee)
    coeur = R.lisse(0.075, 0.065, r)
    a = np.clip(np.maximum(dans, coeur), 0, 1)
    t = np.clip(r / 0.9, 0, 1)
    col = np.dstack([np.ones_like(t), 1.0 - 0.16 * t, 1.0 - 0.52 * t])
    intens = np.clip(1.15 - 0.85 * t, 0.25, 1.0)
    return _ecrire("eclat-nova.png", col * intens[..., None], a, ss, tonalite=False)


if __name__ == "__main__":
    os.makedirs(SORTIE, exist_ok=True)
    m = mot_supernova()
    rai()
    eclat_nova()
    print("supernova : mot", m.size, "+ rai + éclat")
