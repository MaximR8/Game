# -*- coding: utf-8 -*-
"""Mesurer des bruits de pièces (29/09/2026 — Maxim : « ça fait jeton, nous on veut un bruit de pièce, comme dans les vrais
coin pushers »). Ce qui sépare une pièce de métal d'un jeton de plastique se mesure :

  tinte   la durée pendant laquelle les aigus (3 à 12 kHz) sonnent encore après le choc (s, jusqu'à −30 dB) : le métal
          RÉSONNE (0,15 à 0,8 s), le plastique s'éteint aussitôt (< 0,05 s)
  aigus   la part d'énergie entre 3 et 12 kHz (%) : l'éclat du métal
  centre  le centre de gravité du spectre (Hz)
  chocs   le nombre d'attaques : une pièce seule (1 à 4 : ses rebonds) ou une pluie (beaucoup)
  duree   la longueur utile (s)

    python design/sons/mesure_pieces.py <fichiers…>
"""
import sys, glob, os, warnings
import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfiltfilt
warnings.filterwarnings("ignore")
sys.stdout.reconfigure(encoding="utf-8")


def mesurer(chemin):
    x, sr = sf.read(chemin, always_2d=True)
    m = x.mean(axis=1)
    env = np.abs(m)
    i0 = int(np.argmax(env > env.max() * 10 ** (-40 / 20)))
    idx = np.where(env > env.max() * 10 ** (-50 / 20))[0]
    m = m[i0: idx[-1] + 1]
    duree = len(m) / sr
    haut = sosfiltfilt(butter(4, [3000, min(12000, sr / 2 - 100)], "bandpass", fs=sr, output="sos"), m)
    e = np.convolve(haut ** 2, np.ones(int(0.005 * sr)) / int(0.005 * sr), "same")
    ipk = int(np.argmax(e))
    apres = np.where(e[ipk:] > e[ipk] * 1e-3)[0]
    tinte = (apres[-1]) / sr if len(apres) else 0.0
    F = np.abs(np.fft.rfft(m)) ** 2
    f = np.fft.rfftfreq(len(m), 1 / sr)
    aigus = 100 * F[(f > 3000) & (f < 12000)].sum() / F.sum()
    centre = (F * f).sum() / F.sum()
    n, h = 512, 128
    fr = np.array([np.abs(np.fft.rfft(m[i:i + n] * np.hanning(n))) for i in range(0, max(1, len(m) - n), h)])
    flux = np.maximum(0, np.diff(np.log1p(fr * 100), axis=0)).sum(1) if len(fr) > 1 else np.zeros(1)
    seuil = max(np.median(flux) + 3 * np.std(flux), flux.max() * 0.25)
    chocs = sum(1 for i in range(1, len(flux) - 1) if flux[i] > seuil and flux[i] >= flux[i - 1] and flux[i] >= flux[i + 1])
    return {"duree": duree, "tinte": tinte, "aigus": aigus, "centre": centre, "chocs": max(1, chocs)}


def afficher(nom, r):
    print("%-34s %5.2fs  tinte %5.2fs  aigus %4.0f%%  centre %5.0f Hz  chocs %3d" % (
        nom[:34], r["duree"], r["tinte"], r["aigus"], r["centre"], r["chocs"]))


if __name__ == "__main__":
    for motif in sys.argv[1:]:
        for f in sorted(glob.glob(motif)):
            try:
                afficher(os.path.basename(f), mesurer(f))
            except Exception as e:
                print(os.path.basename(f), "illisible :", e)
