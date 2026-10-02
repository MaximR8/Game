# -*- coding: utf-8 -*-
"""Les lunes de la jauge et le cadran de la Supernova, pour les décors peints (02/10/2026) — Maxim, sur le premier essai :
« les animations font très pauvre, fait en CSS ; les lunes ne sont pas bien alignées dans les trous ; le compteur en
Supernova est coupé à moitié ». Donc de vrais objets, rendus comme ceux de la fabrique (design/objets/render_objets.py :
un relief, l'éclairage des pièces) :

  · une LUNE est un cabochon (un dôme de verre) qui remplit le trou de l'alvéole — le décor fournit déjà la bague d'or.
    Éteinte : un verre nuit, profond, où la phase se devine en laiteux ; allumée : une pierre de lune pleine, d'ivoire et
    d'or pâle, qui semble éclairée de l'intérieur (des tons, pas de halo), quelques cratères à peine marqués ;
  · le CADRAN du compte à rebours : un dôme d'émail nuit cerclé d'une bague d'or en relief.

    python design/machines/lunes.py      → design/machines/lunes/lune-<phase>.png, lune-allumee.png, cadran.png"""
import math, os, sys
import numpy as np
from PIL import Image

sys.stdout.reconfigure(encoding="utf-8")
BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(BASE, "..", "objets"))
import render_objets as R  # noqa: E402

SORTIE = os.path.join(BASE, "lunes")
# les phases des jauges à 7 et à 9 lunes (de la nouvelle à la nouvelle ; négatif : la lune décroît)
PHASES = sorted({0.0, 1.0} | {round(s * k, 4) for s in (1, -1) for k in (0.25, 0.5, 0.75, 1 / 3, 2 / 3)})


def _ecrire(nom, S, ss, col, alpha):
    col = np.clip(col, 0, 1)
    col = 1.0 - np.exp(-col * 1.55)
    col = col / (1.0 - math.exp(-1.55))
    col = np.clip(col, 0, 1) ** (1 / 1.08)
    prem = col * alpha[..., None]
    p = prem.reshape(S, ss, S, ss, 3).mean(axis=(1, 3))
    a = alpha.reshape(S, ss, S, ss).mean(axis=(1, 3))
    rgb = p / np.maximum(a, 1e-6)[..., None]
    Image.fromarray((np.clip(np.dstack([rgb, a]), 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(SORTIE, nom))


def _phase(u, v, k):
    """La part éclairée d'une lune de rayon 1 : 1 dedans, 0 dehors (le terminateur est une demi-ellipse)."""
    fk = abs(k)
    dans = (u * u + v * v) <= 1.0
    if fk < 0.001:
        return np.zeros(u.shape)
    if fk > 0.999:
        return dans.astype(np.float64)
    cote = 1.0 if k > 0 else -1.0
    rx = (1.0 - 2.0 * fk) * np.sqrt(np.clip(1.0 - v * v, 0, None))
    return (dans & (u * cote >= rx)).astype(np.float64)


def _dome(S, ss):
    N, u, v = R.grille(S, ss)
    q = u * u + v * v
    h = 0.42 * np.sqrt(np.clip(1.0 - q / 0.94 ** 2, 0, 1))
    n = R.normales(h, N)
    alpha = R.lisse(0.95, 0.93, np.sqrt(q))
    return N, u, v, q, n, alpha


def lune(k, S=256, ss=3):
    """Éteinte : le verre nuit, la phase qui s'y devine."""
    N, u, v, q, n, alpha = _dome(S, ss)
    rr = np.sqrt(np.clip(q, 0, 1))[..., None]
    # vu à travers le dôme : la phase un peu agrandie au centre (la loupe du verre)
    loupe = 1.0 / (1.0 + 0.22 * (1 - np.clip(q, 0, 1)))
    ph = _phase(u * loupe / 0.80, v * loupe / 0.80, k)
    ph = R.flou_boite(ph, max(1, int(N * 0.006)))[..., None]
    verre = np.array([0.020, 0.036, 0.095]) * (1 - 0.4 * rr) + np.array([0.05, 0.07, 0.16]) * 0.4 * rr
    # la phase : la pierre de lune éteinte (ses tons d'ivoire et d'or pâle, assombris, ses cratères) sous le verre
    crateres = (R.bruit(N, 7, 31)[..., None] - 0.5) * 0.14 + (R.bruit(N, 15, 32)[..., None] - 0.5) * 0.07
    lait = (np.array([0.66, 0.62, 0.54]) * (1 - rr ** 1.6) + np.array([0.50, 0.42, 0.30]) * rr ** 1.6) * (1 + crateres)
    corps = verre * (1 - 0.62 * ph) + lait * 0.62 * ph
    nz = n[..., 2:3]
    fres = 0.04 + 0.96 * (1 - nz) ** 4
    e = R.environnement(R.reflet(n))[..., None]
    spec = R.lisse(0.9955, 0.9985, np.sum(n * R.H_CLE, -1))[..., None] * 1.3 \
        + R.lisse(0.993, 0.997, np.sum(n * R.H_CONTRE, -1))[..., None] * 0.35
    col = corps * (1 - fres * 0.5) + e * fres * np.array([0.55, 0.62, 0.85]) * 0.7 + spec
    _ecrire("lune%+.3f.png" % k, S, ss, col, alpha)


def lune_allumee(S=256, ss=3):
    """Allumée : une pierre de lune pleine, qui semble éclairée du dedans (plus claire au cœur), des cratères légers."""
    N, u, v, q, n, alpha = _dome(S, ss)
    rr = np.sqrt(np.clip(q, 0, 1))[..., None]
    coeur = np.array([1.00, 0.96, 0.84])
    bord = np.array([0.93, 0.76, 0.46])
    corps = coeur * (1 - rr ** 1.6) + bord * rr ** 1.6
    crateres = (R.bruit(N, 7, 31)[..., None] - 0.5) * 0.10 + (R.bruit(N, 15, 32)[..., None] - 0.5) * 0.05
    corps = corps * (1 + crateres)
    nz = n[..., 2:3]
    fres = 0.04 + 0.96 * (1 - nz) ** 4
    e = R.environnement(R.reflet(n))[..., None]
    spec = R.lisse(0.9955, 0.9985, np.sum(n * R.H_CLE, -1))[..., None] * 1.0
    col = corps * (0.92 + 0.10 * (1 - rr)) * (1 - fres * 0.35) + e * fres * np.array([1.0, 0.9, 0.7]) * 0.35 + spec
    _ecrire("lune-allumee.png", S, ss, col, alpha)


def cadran(S=512, ss=2):
    """Le cadran du compte à rebours : un dôme d'émail nuit, une bague d'or en relief."""
    N, u, v = R.grille(S, ss)
    r = np.hypot(u, v)
    b0, b1 = 0.80, 0.96
    tb = np.clip((r - b0) / (b1 - b0), 0, 1)
    h_bague = np.where((r >= b0) & (r <= b1), 0.10 * np.sin(np.pi * tb) ** 0.7, 0.0)
    h_email = np.where(r < b0, 0.06 * np.sqrt(np.clip(1 - (r / b0) ** 2, 0, 1)), 0.0)
    h = h_bague + h_email
    n = R.normales(h, N)
    ao = R.occlusion(h, N, N * 0.01)
    c_or = R.metal(n, R.OR, ao, 1.0)
    nz = n[..., 2:3]
    fres = 0.04 + 0.96 * (1 - nz) ** 5
    e = R.environnement(R.reflet(n))[..., None]
    spec = R.lisse(0.996, 0.999, np.sum(n * R.H_CLE, -1))[..., None] * 0.9
    email = np.array([0.025, 0.045, 0.12]) * (0.8 + 0.2 * (1 - r / b0))[..., None]
    c_email = email + e * fres * 0.4 + spec
    est_or = (r >= b0)[..., None]
    col = np.where(est_or, c_or, c_email)
    alpha = R.lisse(b1 + 0.006, b1 - 0.006, r)
    _ecrire("cadran.png", S, ss, col, alpha)


def glissiere(S=256, ss=3):
    """Le chariot de la glissière (02/10 — Maxim : « comment on fait pour lâcher les pièces ? ») : une goulotte d'or vue de
    face, sa fente sombre en haut (où la pièce entre), une bande d'émail nuit et son étoile, une bague à la bouche (d'où la
    pièce tombe sur le bloc). Il glisse sur le rail, sous le doigt."""
    N, u, v = R.grille(S, ss)
    t = np.clip((v + 0.50) / 1.05, 0, 1)
    w = 0.60 * (1 - t) + 0.27 * t
    corps = (v > -0.52) & (v < 0.56) & (np.abs(u) < w)
    h_corps = np.where(corps, 0.16 * np.sqrt(np.clip(1 - (u / np.maximum(w, 1e-3)) ** 2, 0, 1)), 0.0)
    # la bague du haut (un bourrelet en ellipse) et sa fente
    eb = np.hypot(u / 0.68, (v + 0.60) / 0.15)
    bague = (eb < 1.0)
    h_bague = np.where(bague, 0.22 * np.sqrt(np.clip(1 - eb ** 2, 0, 1)) + 0.05, 0.0)
    fente = np.hypot(u / 0.46, (v + 0.60) / 0.065) < 1.0
    # la bouche, en bas
    em = np.hypot(u / 0.30, (v - 0.62) / 0.09)
    bouche = em < 1.0
    h_bouche = np.where(bouche, 0.14 * np.sqrt(np.clip(1 - em ** 2, 0, 1)) + 0.02, 0.0)
    # la bande d'émail et son étoile
    bande = corps & (v > -0.14) & (v < 0.20) & (np.abs(u) < w - 0.07)
    d_et = R.etoile_sdf(u, v - 0.03, 8, 0.14, 0.055)
    etoile = bande & (d_et < 0)
    h = np.maximum(np.maximum(h_corps, h_bague), h_bouche)
    h = np.where(bande, h - 0.03, h)
    h = np.where(etoile, h + 0.05 * np.clip(-d_et / 0.03, 0, 1), h)
    h = np.where(fente, h - 0.12, h)
    n = R.normales(h, N)
    ao = R.occlusion(h, N, N * 0.012)
    c_or = R.metal(n, R.OR, ao, 1.0)
    nz = n[..., 2:3]
    fres = 0.04 + 0.96 * (1 - nz) ** 5
    e = R.environnement(R.reflet(n))[..., None]
    c_email = np.array([0.03, 0.055, 0.15]) * ao[..., None] + e * fres * 0.4
    col = np.where((bande & ~etoile)[..., None], c_email, c_or)
    col = np.where(fente[..., None], np.array([0.01, 0.012, 0.03]), col)
    forme = corps | bague | bouche
    alpha = R.flou_boite(forme.astype(np.float64), max(1, ss // 2))
    _ecrire("glissiere.png", S, ss, col, alpha)


def rail(W=1024, H=48, ss=2):
    """Le rail de la glissière : une tringle d'or perlée (les perles de l'arche), d'un bout à l'autre du bloc."""
    Wn, Hn = W * ss, H * ss
    y, x = np.mgrid[0:Hn, 0:Wn].astype(np.float64)
    v = (y + 0.5) / Hn * 2 - 1
    xs = (x + 0.5) / ss
    r_tige = 0.42
    h_tige = np.where(np.abs(v) < r_tige, 0.42 * np.sqrt(np.clip(1 - (v / r_tige) ** 2, 0, 1)), 0.0)
    pas = 40.0
    cx = (np.floor(xs / pas) + 0.5) * pas
    dp = np.hypot((xs - cx) / (H * 0.5), v)
    h_perle = np.where(dp < 0.72, 0.72 * np.sqrt(np.clip(1 - (dp / 0.72) ** 2, 0, 1)), 0.0)
    bout = np.minimum(xs, W - xs)
    h = np.where(bout > 8, np.maximum(h_tige, h_perle), 0.0)
    dv, du = np.gradient(h, 2.0 / Hn)
    n = R.norme(np.stack([-du, -dv, np.ones_like(h)], axis=-1))
    ao = np.ones(h.shape)
    col = R.metal(n, R.OR, ao, 1.0)
    alpha = np.clip(h * 8.0, 0, 1)
    col = np.clip(col, 0, 1)
    col = 1.0 - np.exp(-col * 1.55)
    col = col / (1.0 - math.exp(-1.55))
    col = np.clip(col, 0, 1) ** (1 / 1.08)
    prem = col * alpha[..., None]
    p = prem.reshape(H, ss, W, ss, 3).mean(axis=(1, 3))
    a = alpha.reshape(H, ss, W, ss).mean(axis=(1, 3))
    rgb = p / np.maximum(a, 1e-6)[..., None]
    Image.fromarray((np.clip(np.dstack([rgb, a]), 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(SORTIE, "rail.png"))


if __name__ == "__main__":
    os.makedirs(SORTIE, exist_ok=True)
    for k in PHASES:
        lune(k)
    lune_allumee()
    cadran()
    glissiere()
    rail()
    print("lunes :", ", ".join("%+.3f" % k for k in PHASES), "+ allumée + cadran + glissière + rail")
