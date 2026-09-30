# -*- coding: utf-8 -*-
"""L'ESPACE DU SON (29/09/2026) — Maxim : « les musiques sonnent collé-collé, mais elles ne sont pas dans l'App, je sais pas
expliquer si c'est un souci de réverbe, de basse » ; à ses questions : au HAUT-PARLEUR du téléphone, « plate, sans
espace », les deux musiques, et les bruitages aussi.

Mesuré (29/09) :
  · tout le son du jeu est MONO — Moonlit Rabbits l'est à la source (corrélation gauche/droite 1,00) ; la musique du combat,
    stéréo (0,71), était aplatie par preparer_jeu ;
  · tout est SEC : pas une milliseconde de réverbération, ni dans les bruitages synthétisés ni autour de la musique ;
  · Moonlit Rabbits met 47 % de son énergie sous 120 Hz — là où le haut-parleur d'un téléphone ne rend presque rien ; les
    bruitages vivent tous au-dessus de 500 Hz : deux couches qui ne se touchent pas.

Ce module donne au son UN espace commun, CUIT DANS LES FICHIERS (le web de Godot joue des échantillons du navigateur : on ne
compte sur aucun effet de bus) :
  · une réverbération stéréo — une réponse de salle synthétisée (gauche et droite décorrélées, les aigus qui s'éteignent
    plus vite, rien sous 250 Hz pour ne pas épaissir le grave) : LA MÊME pour tout ; les bruitages devant (peu d'effet), la
    musique derrière (plus) ;
  · la stéréo : gardée (la musique du combat) ou faite pour une source mono (un élargisseur « complémentaire » : gauche =
    s + d, droite = s − d ; la somme des deux redonne s — un haut-parleur unique rend le son d'origine, sans creux) ;
  · le haut-parleur : le grave coupé sous 70 Hz (il ne sortait pas, il mangeait la place) et remplacé par ses harmoniques
    (l'oreille « entend » la basse qu'on ne joue plus), un peu de présence au-dessus de 3 kHz.

    python design/sons/espace.py          → la scène d'écoute en quatre versions : design/canevas/sons/ecoute/ES1..ES4.mp3

🔴 MAXIM A CHOISI « ES2 », LA SALLE (29/09, sur la page d'écoute) : CHOISI ci-dessous. preparer_jeu.py et invocation.py
cuisent cet espace dans CHAQUE fichier du jeu (les bruitages : effet ; les musiques : musique_boucle). En changer : changer
CHOISI, relancer les deux scripts, --import, export.
"""
import os, sys
import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfiltfilt, fftconvolve
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import preparer_ecoute as E

SR = E.SR
JEU = os.path.join(E.ICI, "..", "..", "proto_degagement", "sons")
# Les bruitages SECS (mono, sans espace), écrits à côté des fichiers du jeu par preparer_jeu et invocation.py : la scène
# d'écoute part d'eux (les fichiers du jeu ont déjà leur espace — le remettre le doublerait).
SECS = os.path.join(E.ICI, "secs")


def garder_sec(nom, m):
    os.makedirs(SECS, exist_ok=True)
    sf.write(os.path.join(SECS, nom), np.clip(m, -1, 1).astype(np.float32), SR, format="OGG", subtype="VORBIS")

# Les versions à comparer. rt : la durée de la réverbération (s, à −60 dB) ; effets / musique : son niveau sous le son
# direct (dB) ; None : la version d'aujourd'hui (mono, sèche).
VARIANTES = {
    "ES1": None,
    "ES2": {"nom": "La salle", "rt": 0.9, "effets": -14.0, "musique": -11.0},
    "ES3": {"nom": "La voûte", "rt": 2.2, "effets": -11.0, "musique": -9.0},
    "ES4": {"nom": "Le ciel ouvert", "rt": 3.6, "effets": -8.0, "musique": -7.0},
}
CHOISI = "ES2"          # Maxim, 29/09 : « Sons : ES2 »
_choisie = {}


def choisie():
    """La version du jeu, sa réponse de salle calculée une fois."""
    if "v" not in _choisie:
        v = VARIANTES[CHOISI]
        _choisie["v"] = None if v is None else dict(v, ir=reponse(v["rt"]))
    return _choisie["v"]


def filtre(x, bas=None, haut=None, ordre=2):
    """Passe-haut (bas), passe-bas (haut) ou passe-bande, sans déphasage (hors ligne : aller-retour)."""
    if bas and haut:
        sos = butter(ordre, [bas, haut], "bandpass", fs=SR, output="sos")
    elif bas:
        sos = butter(ordre, bas, "highpass", fs=SR, output="sos")
    else:
        sos = butter(ordre, haut, "lowpass", fs=SR, output="sos")
    return sosfiltfilt(sos, x, axis=0)


def reponse(rt, graine=29):
    """La réponse d'une salle, stéréo : réflexions précoces, puis une queue diffuse (les aigus s'éteignent deux fois plus
    vite que les graves), rien sous 250 Hz. Énergie 1 par canal : le son réverbéré sort au niveau du son direct."""
    rng = np.random.default_rng(graine)
    pre = 0.018
    n = int(rt * 1.25 * SR)
    t = np.arange(n) / SR
    ir = np.zeros((n, 2))
    for bas, haut, f in [(None, 900, 1.15), (900, 4500, 1.0), (4500, None, 0.5)]:
        for c in range(2):
            b = filtre(rng.standard_normal(n), bas, haut)
            ir[:, c] += b * 10 ** (-3.0 * t / (rt * f))
    ir *= np.minimum(1.0, t / 0.035)[:, None]                  # la queue se construit (diffusion)
    for k in range(10):                                        # les premières réflexions, alternées gauche / droite
        d = rng.uniform(0.003, 0.045)
        ir[int(d * SR), k % 2] += 3.0 * (1.0 - d / 0.06) * rng.choice([-1.0, 1.0])
    ir = np.vstack([np.zeros((int(pre * SR), 2)), ir])
    ir = filtre(ir, 250, 12000)
    return ir / np.sqrt(np.sum(ir ** 2, axis=0, keepdims=True))


def stereo(x):
    return x if x.ndim == 2 else np.stack([x, x], axis=1)


def elargir(m, force=0.3, circulaire=False):
    """Une source mono → stéréo, sans rien perdre en mono : g = m + d, dr = m − d (d : m au-dessus de 300 Hz, retardé de
    11 ms ; circulaire : une boucle, la fin retardée revient au début)."""
    d = filtre(m, 300, None)
    r = int(0.011 * SR)
    d = (np.roll(d, r) if circulaire else np.concatenate([np.zeros(r), d[:-r]])) * force
    return np.stack([m + d, m - d], axis=1)


def haut_parleur(x):
    """Le grave qu'un téléphone ne rend pas → ses harmoniques ; coupé sous 70 Hz ; +2,5 dB de présence au-dessus de 3 kHz."""
    x = stereo(x)
    b = filtre(x.mean(axis=1), 40, 140)
    rb = np.sqrt(np.mean(b ** 2)) + 1e-12
    h = np.tanh(2.5 * b / rb) * rb + 0.6 * (np.abs(b) - filtre(np.abs(b), None, 30))   # 3f (tanh) et 2f (redressé)
    h = filtre(h, 140, 450)
    h *= 0.55 * rb / (np.sqrt(np.mean(h ** 2)) + 1e-12)
    y = filtre(x, 70, None, ordre=3) + h[:, None]
    return y + (10 ** (2.5 / 20) - 1.0) * filtre(y, 3000, None)


def mouiller(x, ir, db):
    x = stereo(x)
    w = np.stack([fftconvolve(x[:, c], ir[:, c]) for c in range(2)], axis=1)
    y = np.zeros((len(w), 2))
    y[:len(x)] += x
    y += w * 10 ** (db / 20)
    return _couper(y)


def _couper(y, rel_db=-70.0):
    env = np.abs(y).max(axis=1)
    idx = np.where(env > env.max() * 10 ** (rel_db / 20))[0]
    return y[: idx[-1] + 1] if len(idx) else y


def effet(m, v):
    """Un bruitage (mono, du jeu) dans l'espace de la version v."""
    if v is None:
        return m
    return mouiller(m, v["ir"], v["effets"])


def musique_boucle(x, v):
    """Une musique bouclée (stéréo, preparer_jeu.boucle(..., stereo=True)) dans l'espace de la version v (None : mono,
    comme avant). Une source mono (gauche = droite) est élargie ; la réverbération de la fin retombe sur le début (la
    boucle reste sans raccord). Remise à −20 dB efficaces, comme boucle()."""
    if v is None:
        return x.mean(axis=1)
    g, d = x[:, 0], x[:, 1]
    if np.sum(g * d) / (np.sqrt(np.sum(g * g) * np.sum(d * d)) + 1e-12) > 0.98:
        x = elargir(x.mean(axis=1), circulaire=True)
    x = haut_parleur(x)
    n = len(x)
    w = np.stack([fftconvolve(x[:, c], v["ir"][:, c]) for c in range(2)], axis=1) * 10 ** (v["musique"] / 20)
    y = x + w[:n]
    y[:len(w) - n] += w[n:]
    y *= 10 ** (-20 / 20) / (np.sqrt(np.mean(y ** 2)) + 1e-12)
    if np.max(np.abs(y)) > 0.95:
        y *= 0.95 / np.max(np.abs(y))
    return y


def musique(code_ou_chemin, v):
    import preparer_jeu as J
    return musique_boucle(J.boucle(*code_ou_chemin, stereo=True), v)


# ── La scène : 38 secondes de jeu, jouées comme le jeu les joue (son.gd : NIVEAUX, bus, hauteurs) ──

NIV = {"pose": -7.0, "froissement": -19.0, "gain": -3.0, "objet": 0.0, "bouton": -12.0, "onglet": -9.0,
       "rarete": -2.0, "carte-pose": -5.0, "choc": -8.0, "retourne-combat": -4.0, "pouvoir": -2.0, "protege": -4.0,
       "victoire": 0.0, "musique": -2.0,
       "inv-souffle": -8.0, "inv-etoile": -13.0, "inv-verrou": 0.0, "inv-aspiration": -5.0, "inv-apparition": -5.0,
       "inv-tension": -9.0, "inv-revelation": 0.0}
BUS_EFFETS = 20 * np.log10(0.8)
BUS_MUSIQUE = 20 * np.log10(0.5)
PENTA = [0, 2, 4, 7, 9, 12]
GAMME = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
FICHIER = {"pose": "piece-pose"}


def evenements():
    rng = np.random.default_rng(3)
    ev = []                                                    # (t, nom du son, niveau, dB en plus, demi-tons)
    # la Nébuleuse : des pièces lâchées, le poussoir, des gains en cascade, un objet
    for t in [0.8, 1.25, 1.5, 2.4, 2.9, 3.3, 4.6, 5.1, 6.9, 7.4, 8.8, 9.2, 10.4, 11.0]:
        ev.append((t, "pose", "pose", rng.uniform(-2, 0), rng.uniform(-0.8, 0.8)))
    for i, t in enumerate([2.0, 4.0, 6.3, 8.2, 10.0]):
        ev.append((t, "froissement-%d" % (i % 2 + 1), "froissement", 0.0, 0.0))
    for serie in [[3.8, 4.15, 4.5, 4.8], [7.8, 8.1], [11.5, 11.8, 12.1, 12.4, 12.7, 13.0]]:
        for k, t in enumerate(serie):
            ev.append((t, "gain", "gain", 0.0, PENTA[k]))
    ev.append((9.6, "objet", "objet", 0.0, 0.0))
    ev.append((13.5, "onglet", "onglet", 0.0, 0.0))
    # l'invocation (les instants du film : le verrou 1,2 s après le souffle, la carte à 1,9 s, la révélation à 3,05 s)
    t0, lock = 14.3, 1.2
    ev.append((t0, "inv-celeste-souffle", "inv-souffle", 0.0, 12 * np.log2(1.6 / lock)))
    etoiles = np.linspace(0.12, 1.05, 8)
    for k, t in enumerate(etoiles):
        ev.append((t0 + t, "inv-celeste-etoile", "inv-etoile", rng.uniform(-2, 0), GAMME[int(k * len(GAMME) / len(etoiles))]))
    ev += [(t0 + lock, "inv-celeste-verrou", "inv-verrou", 0.0, 0.0),
           (t0 + lock + 0.25, "inv-celeste-aspiration", "inv-aspiration", 0.0, 0.0),
           (t0 + 1.9, "inv-celeste-apparition", "inv-apparition", 0.0, 0.0),
           (t0 + 1.9, "inv-celeste-tension", "inv-tension", 0.0, 0.0),
           (t0 + 3.05, "inv-celeste-revelation", "inv-revelation", 0.0, 0.0),
           (t0 + 3.1, "rarete-4", "rarete", 0.0, 0.0),
           (19.6, "bouton", "bouton", 0.0, 0.0)]
    # le combat
    for t, k in [(21.0, None), (23.5, None), (26.0, None), (29.0, None), (31.0, None)]:
        ev.append((t, "carte-pose", "carte-pose", 0.0, 0.0))
    for t in [21.35, 23.8, 31.3]:
        ev.append((t, "choc", "choc", 0.0, 0.0))
    for serie in [[21.6, 21.85], [24.05], [26.7, 26.95, 27.2], [31.55, 31.8, 32.05, 32.3]]:
        for k, t in enumerate(serie):
            ev.append((t, "retourne-combat", "retourne-combat", 0.0, PENTA[k]))
    ev += [(26.3, "pouvoir", "pouvoir", 0.0, 0.0), (29.4, "protege", "protege", 0.0, 0.0),
           (33.2, "victoire", "victoire", 0.0, 0.0)]
    return ev


def hauteur(x, demi_tons):
    if abs(demi_tons) < 1e-3:
        return x
    r = 2 ** (demi_tons / 12)
    n = int(len(x) / r)
    i = np.arange(n) * r
    return np.stack([np.interp(i, np.arange(len(x)), x[:, c]) for c in range(x.shape[1])], axis=1)


def poser(sortie, x, t, db):
    i = int(t * SR)
    n = min(len(x), len(sortie) - i)
    if n > 0:
        sortie[i:i + n] += x[:n] * 10 ** (db / 20)


def scene(code):
    v = VARIANTES[code]
    if v is not None:
        v = dict(v, ir=reponse(v["rt"]))
    duree = 38.0
    out = np.zeros((int(duree * SR), 2))
    cache = {}
    for t, nom, niveau, db, dt in evenements():
        if nom not in cache:
            m, _ = sf.read(os.path.join(SECS, FICHIER.get(nom, nom) + ".ogg"))
            cache[nom] = stereo(effet(m, v))
        poser(out, hauteur(cache[nom], dt), t, NIV[niveau] + BUS_EFFETS + db)
    # la musique du jeu (Moonlit Rabbits, source mono), puis celle du combat (stéréo) : le fondu du bus de son.gd
    mg = stereo(musique(("F9",), v))
    mc = stereo(musique(("Z2", "combat/prepare_your_swords.ogg"), v))
    g = NIV["musique"] + BUS_MUSIQUE
    tt = np.arange(len(out)) / SR
    bascule = 20.0
    env_g = np.clip(tt / 0.5, 0, 1) * np.clip(1 - (tt - bascule) / 0.35, 0, 1)
    env_c = np.clip((tt - bascule - 0.35) / 0.6, 0, 1) * np.clip((duree - tt) / 1.5, 0, 1)
    out += mg[:len(out)] * (env_g[:, None] * 10 ** (g / 20))
    ic = int((bascule + 0.35) * SR)
    seg = mc[:len(out) - ic]
    out[ic:ic + len(seg)] += seg * (env_c[ic:ic + len(seg), None] * 10 ** (g / 20))
    return out


def main():
    sortie = os.path.join(E.ICI, "..", "canevas", "sons", "ecoute")
    scenes = {c: scene(c) for c in VARIANTES}
    # à volume égal, tel que le haut-parleur d'un téléphone l'entend (au-dessus de 150 Hz) : sinon la plus forte gagne
    for c, x in scenes.items():
        rms = np.sqrt(np.mean(filtre(x, 150, None) ** 2))
        scenes[c] = x * (10 ** (-20 / 20) / rms)
    k = 0.95 / max(np.max(np.abs(x)) for x in scenes.values())
    for c, x in scenes.items():
        x = x * min(1.0, k)
        sf.write(os.path.join(sortie, c + ".mp3"), np.clip(x, -1, 1), SR, format="MP3")
        g, d = x[:, 0], x[:, 1]
        corr = np.sum(g * d) / np.sqrt(np.sum(g * g) * np.sum(d * d))
        print("%s  pic %.1f dB  corrélation G/D %.2f  %s" % (c, 20 * np.log10(np.max(np.abs(x))), corr,
                                                            VARIANTES[c]["nom"] if VARIANTES[c] else "aujourd'hui"))


if __name__ == "__main__":
    main()
