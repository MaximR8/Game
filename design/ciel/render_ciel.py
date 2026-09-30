# -*- coding: utf-8 -*-
"""Les textures du ciel étoilé, calculées une fois : le jeu les anime légèrement (ciel.gd).
Sortie dans proto_degagement/ciel/. Il faut numpy et Pillow : `python -m pip install numpy pillow`."""
import os, math
import numpy as np
from PIL import Image

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "..", "..", "proto_degagement", "ciel")
os.makedirs(SORTIE, exist_ok=True)

TEINTES = [(1.0, 1.0, 1.0), (1.0, 0.965, 0.88), (0.84, 1.0, 0.94), (1.0, 0.91, 0.94), (1.0, 1.0, 1.0)]


def ecrire(nom, rgb, a):
    img = np.dstack([np.clip(rgb, 0, 1), np.clip(a, 0, 1)])
    Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(SORTIE, nom))
    print("écrit", nom, img.shape[1], "x", img.shape[0])


def lueur(n=256):
    y, x = np.mgrid[0:n, 0:n].astype(float)
    r = np.hypot(x + 0.5 - n / 2, y + 0.5 - n / 2) / (n / 2)
    a = np.clip(1 - r, 0, 1) ** 2.2
    ecrire("lueur.png", np.ones((n, n, 3)), a)


def champ(nom, n, nombre, sigma, eclat, graine):
    rng = np.random.default_rng(graine)
    rgb = np.zeros((n, n, 3))
    acc = np.zeros((n, n))
    y, x = np.mgrid[0:n, 0:n].astype(float)
    for _ in range(nombre):
        cx, cy = rng.uniform(0, n), rng.uniform(0, n)
        s = rng.uniform(*sigma)
        b = rng.uniform(*eclat)
        t = np.array(TEINTES[rng.integers(len(TEINTES))])
        # distance torique : la texture se répète sans couture
        dx = np.minimum(np.abs(x + 0.5 - cx), n - np.abs(x + 0.5 - cx))
        dy = np.minimum(np.abs(y + 0.5 - cy), n - np.abs(y + 0.5 - cy))
        g = b * np.exp(-(dx * dx + dy * dy) / (2 * s * s))
        if s > 1.2:
            g += b * 0.18 * np.exp(-(dx * dx + dy * dy) / (2 * (s * 4) ** 2))
        rgb += g[..., None] * t
        acc += g
    a = np.clip(acc, 0, 1)
    couleur = rgb / np.maximum(acc, 1e-6)[..., None]
    ecrire(nom, couleur, a)


def eclat_etoile(n=128):
    y, x = np.mgrid[0:n, 0:n].astype(float)
    dx, dy = x + 0.5 - n / 2, y + 0.5 - n / 2
    r2 = dx * dx + dy * dy
    a = np.exp(-r2 / (2 * 2.6 ** 2)) + 0.32 * np.exp(-r2 / (2 * 11 ** 2))
    a += 0.55 * np.exp(-dy * dy / (2 * 0.9 ** 2)) * np.exp(-np.abs(dx) / 20)
    a += 0.55 * np.exp(-dx * dx / (2 * 0.9 ** 2)) * np.exp(-np.abs(dy) / 20)
    ecrire("eclat-etoile.png", np.ones((n, n, 3)), np.clip(a, 0, 1))


def filante(w=256, h=16):
    y, x = np.mgrid[0:h, 0:w].astype(float)
    t = (x + 0.5) / w
    a = (1 - t) ** 1.7 * np.exp(-((y + 0.5 - h / 2) ** 2) / (2 * 1.5 ** 2))
    a += 0.9 * np.exp(-(((x + 0.5 - 6) ** 2) + (y + 0.5 - h / 2) ** 2) / (2 * 2.2 ** 2))
    rgb = np.dstack([1 - 0.25 * t, np.ones_like(t), 1 - 0.1 * t])
    ecrire("filante.png", rgb, np.clip(a, 0, 1))


if __name__ == "__main__":
    lueur()
    champ("etoiles-fines.png", 512, 240, (0.55, 0.9), (0.35, 0.85), 11)
    champ("etoiles-moyennes.png", 512, 46, (0.9, 1.6), (0.55, 1.0), 23)
    eclat_etoile()
    filante()
