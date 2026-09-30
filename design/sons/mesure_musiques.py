# -*- coding: utf-8 -*-
"""Mesurer des musiques pour en choisir (29/09/2026) — ce qu'on ne peut pas écouter, on le mesure.

Pour chaque piste (les 2 premières minutes, là où elle est installée) :
  attq/s    attaques par seconde (pics du flux spectral) : l'allure
  nettes    part des instants à attaque franche (%) : la dureté
  centre    centre de gravité du spectre (Hz) : clair ou sombre
  majeur    majeur − mineur (corrélations de Krumhansl sur le chroma) : > 0 lumineux, < 0 sombre
  clarte    netteté de la tonalité (corrélation du meilleur ton) : bas = flou, dissonant, bruiteux
  grave     part d'énergie sous 100 Hz (%) : les nappes graves, les drones
  bruit     platitude du spectre (médiane) : haut = souffle, bruit, texture
Et une DISTANCE au modèle (Starfield Romance, la musique que Maxim avait choisie), sur ces mesures normalisées.

    python design/sons/mesure_musiques.py <modèle> <fichiers…>
"""
import os, sys, glob, warnings
import numpy as np
import soundfile as sf
from scipy.signal import resample_poly
warnings.filterwarnings("ignore")
sys.stdout.reconfigure(encoding="utf-8")

NOTES = ["do", "do#", "ré", "mib", "mi", "fa", "fa#", "sol", "lab", "la", "sib", "si"]
MAJ = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
MIN = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])
SR = 22050


def charger(chemin, duree=120.0):
    x, sr = sf.read(chemin, always_2d=True)
    m = x.mean(axis=1)
    if sr != SR:
        m = resample_poly(m, SR, sr)
    f = 5 * SR                                                  # là où la musique est installée
    n5 = np.array([np.sqrt(np.mean(m[i:i + f] ** 2)) for i in range(0, max(1, len(m) - f), SR)])
    i0 = int(np.argmax(n5 >= np.median(n5) * 10 ** (-3 / 20))) * SR
    return m[i0:i0 + int(duree * SR)], len(x) / sr


def mesurer(chemin):
    m, d = charger(chemin)
    n, h = 2048, 512
    w = np.hanning(n)
    fr = np.array([np.abs(np.fft.rfft(m[i:i + n] * w)) for i in range(0, len(m) - n, h)]) + 1e-9
    f = np.fft.rfftfreq(n, 1 / SR)
    flux = np.maximum(0, np.diff(np.log1p(fr * 100), axis=0)).sum(1)
    seuil = np.median(flux) + 2.5 * np.std(flux)
    pics = [i for i in range(1, len(flux) - 1) if flux[i] > seuil and flux[i] >= flux[i - 1] and flux[i] >= flux[i + 1]]
    p = fr ** 2
    ok = (f > 60) & (f < 2000)
    pc = np.round(69 + 12 * np.log2(f[ok] / 440)).astype(int) % 12
    c = np.zeros(12)
    np.add.at(c, pc, p[:, ok].sum(0))
    cm = max((np.corrcoef(c, np.roll(MAJ, k))[0, 1], k) for k in range(12))
    cn = max((np.corrcoef(c, np.roll(MIN, k))[0, 1], k) for k in range(12))
    ton = NOTES[cm[1]] + " maj" if cm[0] >= cn[0] else NOTES[cn[1]] + " min"
    flat = np.exp(np.mean(np.log(fr[:, (f > 100) & (f < 8000)]), axis=1)) / np.mean(fr[:, (f > 100) & (f < 8000)], axis=1)
    return {
        "duree": d,
        "attq/s": len(pics) / (len(m) / SR),
        "nettes": 100 * np.mean(flux > np.median(flux) * 3),
        "centre": float(np.median((fr * f).sum(1) / fr.sum(1))),
        "majeur": cm[0] - cn[0],
        "clarte": max(cm[0], cn[0]),
        "grave": 100 * p[:, f < 100].sum() / p.sum(),
        "bruit": float(np.median(flat)),
        "ton": ton,
    }


CLES = ["attq/s", "nettes", "centre", "majeur", "clarte", "grave", "bruit"]
ECHELLE = {"attq/s": 0.5, "nettes": 4.0, "centre": 300.0, "majeur": 0.15, "clarte": 0.12, "grave": 12.0, "bruit": 0.05}


def distance(a, b):
    return float(np.sqrt(sum(((a[k] - b[k]) / ECHELLE[k]) ** 2 for k in CLES)))


def afficher(nom, r, dist=None):
    print("%-44s %4.0fs %5.2f %5.1f %6.0f %+6.2f %5.2f %5.1f %5.3f %-8s %s" % (
        nom[:44], r["duree"], r["attq/s"], r["nettes"], r["centre"], r["majeur"], r["clarte"], r["grave"], r["bruit"], r["ton"],
        "" if dist is None else "%.1f" % dist))


if __name__ == "__main__":
    modele = mesurer(sys.argv[1])
    print("%-44s %5s %5s %5s %6s %6s %5s %5s %5s %-8s %s" % ("piste", "durée", "attq", "nett", "centre", "maj", "clart", "grav", "bruit", "ton", "dist"))
    afficher("MODÈLE " + os.path.basename(sys.argv[1]), modele)
    for ch in sys.argv[2:]:
        for f in sorted(glob.glob(ch)):
            try:
                afficher(os.path.basename(f), r := mesurer(f), distance(r, modele))
            except Exception as e:
                print(os.path.basename(f), "illisible :", e)
