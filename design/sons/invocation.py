# -*- coding: utf-8 -*-
"""La bande-son de l'invocation (29/09/2026 — Maxim : « le son d'animation d'une invocation, ça doit être spectaculaire,
ça doit marcher avec l'animation, le petit clap à la fin est horrible »).

Les sons de la PARTITION que le jeu joue en suivant le rituel, instant par instant (son.gd § partition ;
collection_screen § _partition_simple, _partition_multi) :
  souffle     l'astrolabe tourne et ralentit jusqu'au verrou (le jeu l'étire à la durée du rituel)
  etoile      une étoile de constellation s'allume (le jeu la fait monter en gamme, étoile après étoile)
  verrou      l'astrolabe se verrouille : le coup
  aspiration  les étoiles filent vers le cadran (la ×10 : vers les dix places — « envol »)
  apparition  le dos de la carte apparaît
  tension     l'attente, jusqu'au retournement
  revelation  la carte se retourne (l'invocation simple)
  flip        une carte de la ×10 se retourne (plus léger)
  arrivee     le dos d'une carte de la ×10 arrive à sa place
Deux AMBIANCES, comparées en vidéo : « celeste » (cloches, verre, souffle clair) et « cosmique » (grave, gong, ample).
Maxim a gardé CÉLESTE (29/09 : « IV1 ») : le jeu n'embarque qu'elle. « cosmique » reste ici, pour un film :
    python design/sons/invocation.py              → les sons céleste du jeu
    python design/sons/invocation.py --toutes     → les deux (puis tests/film_invocation.tscn -- cosmique)
Tout est synthétisé ici (numpy) : aucune licence. Sortie : proto_degagement/sons/inv-<ambiance>-<nom>.ogg.
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import preparer_ecoute as E

SR = E.SR
RNG = np.random.default_rng(29)


def _t(d):
    return np.arange(int(d * SR)) / SR


def passe_bas(x, fc):
    """Un filtre passe-bas à un pôle, dont la coupure peut varier dans le temps (fc : un nombre ou un tableau)."""
    fc = np.broadcast_to(np.asarray(fc, dtype=float), x.shape)
    a = np.exp(-2 * np.pi * fc / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a[i]) * x[i] + a[i] * acc
        y[i] = acc
    return y


def passe_haut(x, fc):
    return x - passe_bas(x, fc)


def bruit(d):
    return RNG.normal(0, 1, int(d * SR))


def cloche(f, d=1.2, dec=0.9):
    t = _t(d)
    s = np.zeros_like(t)
    for r, a, k in [(1.0, 1.0, 1.0), (2.0, 0.45, 0.5), (3.0, 0.22, 0.3), (4.16, 0.12, 0.2), (5.43, 0.06, 0.12)]:
        s += a * np.exp(-t / (dec * k)) * np.sin(2 * np.pi * f * r * t)
    return s * np.minimum(1.0, t / 0.002)


def gong(f, d=3.0):
    """Des partiels inharmoniques qui s'éteignent lentement (un gong, un bol)."""
    t = _t(d)
    s = np.zeros_like(t)
    for r, a, k in [(1.0, 1.0, 2.4), (1.47, 0.6, 1.8), (2.09, 0.5, 1.4), (2.56, 0.35, 1.1), (3.17, 0.25, 0.8), (4.3, 0.12, 0.5)]:
        s += a * np.exp(-t / k) * np.sin(2 * np.pi * f * r * t + r)
    return s * np.minimum(1.0, t / 0.004)


def pince(f, d=0.8):
    """Une corde pincée (Karplus-Strong) : nette, cristalline."""
    n = int(d * SR)
    p = max(2, int(SR / f))
    buf = RNG.uniform(-1, 1, p)
    out = np.empty(n)
    for i in range(n):
        v = buf[i % p]
        out[i] = v
        buf[i % p] = 0.996 * 0.5 * (v + buf[(i + 1) % p])
    return out


def boum(f0=60.0, d=1.2):
    """Un coup grave dont la hauteur tombe (un tambour de cérémonie)."""
    t = _t(d)
    f = f0 * (1 + 1.5 * np.exp(-t / 0.05))
    phase = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(phase) * np.exp(-t / 0.35) * np.minimum(1.0, t / 0.003)


def poser(liste, d=None):
    return E.poser(liste, d)


def fondu(x, entree=0.0, sortie=0.0):
    n = len(x)
    k = np.ones(n)
    if entree > 0:
        m = min(n, int(entree * SR))
        k[:m] *= np.linspace(0, 1, m)
    if sortie > 0:
        m = min(n, int(sortie * SR))
        k[n - m:] *= np.linspace(1, 0, m)
    return x * k


# ── les deux ambiances ────────────────────────────────────────

def souffle(amb, d=1.6):
    """Monte jusqu'au verrou (sa fin est au plus fort, coupée net : le verrou prend le relais)."""
    t = _t(d)
    k = t / d
    air = passe_bas(bruit(d), 300 * (20 ** k)) * (k ** 1.6)
    liste = [(0.0, air * (0.5 if amb == "celeste" else 0.7), 1.0)]
    if amb == "celeste":
        # des éclats de verre de plus en plus serrés, qui montent
        tt = 0.05
        i = 0
        while tt < d - 0.05:
            f = 1200 * 2 ** (1.6 * tt / d) * 2 ** (RNG.integers(0, 5) * 2 / 12)
            liste.append((tt, cloche(f, 0.4, 0.2), 0.12 + 0.25 * tt / d))
            tt += 0.16 * (1 - 0.75 * tt / d)
            i += 1
    else:
        grave = np.sin(2 * np.pi * np.cumsum(40 + 50 * k) / SR) * (k ** 1.2)
        liste.append((0.0, grave, 0.9))
        liste.append((0.0, passe_haut(bruit(d), 2000) * (k ** 3) * 0.15, 1.0))
    s = poser(liste, d)
    return fondu(s, entree=0.05)


def etoile(amb):
    if amb == "celeste":
        return cloche(1760.0, 0.7, 0.35)
    return poser([(0.0, pince(880.0, 0.6), 1.0), (0.0, np.sin(2 * np.pi * 440 * _t(0.4)) * np.exp(-_t(0.4) / 0.12), 0.35)])


def verrou(amb):
    clic = passe_haut(bruit(0.03), 3000) * np.exp(-_t(0.03) / 0.006)
    if amb == "celeste":
        accord = [(0.0, cloche(523.25 * r, 2.4, 1.3), 0.7) for r in [1.0, 1.25, 1.5, 2.0]]
        return poser([(0.0, clic, 1.2), (0.004, cloche(261.6, 2.6, 1.6), 0.8)] + accord)
    return poser([(0.0, clic, 1.2), (0.0, boum(55.0, 1.4), 1.6), (0.01, gong(110.0, 3.2), 0.9)])


def aspiration(amb, d=0.5):
    """À l'envers : un son qui s'éteint, joué à rebours, s'aspire vers son instant (l'arrivée des étoiles sur le cadran)."""
    if amb == "celeste":
        s = poser([(0.0, cloche(1046.5 * r, d, 0.25), 0.5) for r in [1.0, 1.5, 2.0]] + [(0.0, passe_haut(bruit(d), 1500) * np.exp(-_t(d) / 0.12) * 0.3, 1.0)], d)
    else:
        s = poser([(0.0, gong(220.0, d), 0.8), (0.0, passe_bas(bruit(d), 1200) * np.exp(-_t(d) / 0.15) * 0.8, 1.0)], d)
    return s[::-1]


def apparition(amb):
    if amb == "celeste":
        return poser([(0.0, boum(90.0, 0.4), 0.5), (0.02, cloche(1318.5, 0.9, 0.4), 0.4)])
    return poser([(0.0, boum(50.0, 0.8), 1.0), (0.0, passe_bas(bruit(0.3), 800) * np.exp(-_t(0.3) / 0.08), 0.6)])


def tension(amb, d=0.65):
    """L'attente du retournement : un trémolo qui monte et s'enfle, coupé net au retournement."""
    t = _t(d)
    k = t / d
    trem = 0.6 + 0.4 * np.sin(2 * np.pi * (10 + 14 * k) * t)
    if amb == "celeste":
        f = 1046.5 * 2 ** (k * 7 / 12)
        s = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.4 * np.sin(2 * np.pi * np.cumsum(f * 1.5) / SR)
    else:
        f = 110 * 2 ** (k * 12 / 12)
        s = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.3 * passe_bas(bruit(d), 1500)
    return s * trem * (k ** 1.5) * 0.6


def revelation(amb):
    """Le retournement : un « souffle » qui passe, puis l'éclat d'un accord."""
    d = 0.22
    swoosh = passe_bas(bruit(d), 500 + 6000 * np.sin(np.pi * _t(d) / d)) * np.sin(np.pi * _t(d) / d) ** 2
    if amb == "celeste":
        accord = [(0.18, cloche(523.25 * r, 2.6, 1.4), 0.6) for r in [1.0, 1.25, 1.5, 2.0, 2.5, 3.0]]
        eclat = [(0.18 + i * 0.035, cloche(2093.0 * 2 ** (st / 12), 0.8, 0.3), 0.3) for i, st in enumerate([0, 4, 7, 12, 16])]
        return poser([(0.0, swoosh, 0.8)] + accord + eclat)
    return poser([(0.0, swoosh, 1.0), (0.18, boum(45.0, 1.6), 1.6), (0.18, gong(130.8, 3.0), 0.8)]
                 + [(0.19, cloche(261.6 * r, 2.4, 1.2), 0.5) for r in [1.0, 1.5, 2.0]])


def flip(amb):
    d = 0.14
    swoosh = passe_bas(bruit(d), 800 + 5000 * np.sin(np.pi * _t(d) / d)) * np.sin(np.pi * _t(d) / d) ** 2
    if amb == "celeste":
        return poser([(0.0, swoosh, 0.6), (0.11, cloche(1046.5, 0.8, 0.35), 0.45)])
    return poser([(0.0, swoosh, 0.8), (0.1, pince(523.25, 0.7), 0.7), (0.1, boum(80.0, 0.3), 0.4)])


def arrivee(amb):
    if amb == "celeste":
        return cloche(2093.0, 0.35, 0.15)
    return pince(1046.5, 0.35)


FABRIQUES = {"souffle": souffle, "etoile": etoile, "verrou": verrou, "aspiration": aspiration, "apparition": apparition,
             "tension": tension, "revelation": revelation, "flip": flip, "arrivee": arrivee}


def main(dossier, ambiances=("celeste",)):
    import soundfile as sf
    import espace as ES
    os.makedirs(dossier, exist_ok=True)
    for amb in ambiances:
        for nom, fab in FABRIQUES.items():
            m = E.pic(fab(amb), -3)
            ES.garder_sec("inv-%s-%s.ogg" % (amb, nom), m)
            m = ES.effet(m, ES.choisie())                          # dans l'espace du jeu (espace.py : la salle, ES2)
            if np.max(np.abs(m)) > 0.99:
                m = m * (0.99 / np.max(np.abs(m)))
            chemin = os.path.join(dossier, "inv-%s-%s.ogg" % (amb, nom))
            tmp = chemin + ".tmp.ogg"
            with sf.SoundFile(tmp, "w", SR, m.shape[1] if m.ndim == 2 else 1, format="OGG", subtype="VORBIS") as f:
                for i in range(0, len(m), 32768):
                    f.write(np.clip(m[i:i + 32768], -1, 1).astype(np.float32))
            os.replace(tmp, chemin)
            print("%-34s %5.2f s" % (os.path.basename(chemin), len(m) / SR))


if __name__ == "__main__":
    main(os.path.join(E.ICI, "..", "..", "proto_degagement", "sons"),
         ("celeste", "cosmique") if "--toutes" in sys.argv else ("celeste",))
