# -*- coding: utf-8 -*-
"""La page d'écoute des sons (29/09/2026) : les candidats de chaque moment de la Nébuleuse, prêts à écouter.

Claude ne les entend pas : ce script les prépare à la mesure — l'attaque au début (le silence d'avant coupé, pour que le
son tombe pile sur l'image), les volumes égalisés, les musiques en extraits de 40 s ; il fabrique les « séries » et les
« cascades » (le même son, en montant d'une gamme pentatonique : le truc des machines à sous) ; il SYNTHÉTISE deux
carillons (« céleste », « pièce d'or ») et un arpège. Maxim écoute et choisit.

Sources : design/sons/sources (LICENCES.md — tout est CC0). Sortie : design/canevas/sons/ecoute/*.mp3 + sons.json.
Il faut : python -m pip install soundfile scipy numpy
"""
import json, os, sys
import numpy as np
import soundfile as sf
from scipy.signal import resample

ICI = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ICI, "sources")
SORTIE = os.path.join(ICI, "..", "canevas", "sons", "ecoute")
SR = 44100
PENTA = [0, 2, 4, 7, 9, 12]           # la cascade : do ré mi sol la do


def lire(chemin):
    x, sr = sf.read(os.path.join(SRC, chemin), always_2d=True)
    m = x.mean(axis=1)
    if sr != SR:
        m = resample(m, int(len(m) * SR / sr))
    return m


def attaque(m, rel_db=-24.0, avance=0.002):
    """Coupe le silence d'avant l'attaque : le premier échantillon à rel_db sous le pic, moins 2 ms."""
    seuil = np.max(np.abs(m)) * 10 ** (rel_db / 20)
    i = int(np.argmax(np.abs(m) > seuil))
    return m[max(0, i - int(avance * SR)):]


def queue(m, rel_db=-60.0):
    seuil = np.max(np.abs(m)) * 10 ** (rel_db / 20)
    idx = np.where(np.abs(m) > seuil)[0]
    return m[: idx[-1] + 1] if len(idx) else m


def pic(m, db=-3.0):
    return m * (10 ** (db / 20) / (np.max(np.abs(m)) + 1e-12))


def ton(m, demi_tons):
    """Monte (ou descend) d'autant de demi-tons, en rééchantillonnant (le son raccourcit : comme une vraie machine)."""
    r = 2 ** (demi_tons / 12)
    return resample(m, max(8, int(len(m) / r)))


def poser(liste, duree=None):
    """liste de (instant en s, signal, gain) → un seul signal."""
    fin = max(t + len(s) / SR for t, s, g in liste)
    out = np.zeros(int((duree or fin) * SR) + 1)
    for t, s, g in liste:
        i = int(t * SR)
        n = min(len(s), len(out) - i)
        out[i:i + n] += s[:n] * g
    return out


def ecrire(nom, m, stereo=False):
    os.makedirs(SORTIE, exist_ok=True)
    data = m if not stereo else m
    sf.write(os.path.join(SORTIE, nom), np.clip(data, -1, 1), SR, format="MP3")
    return nom


# ── les synthèses ─────────────────────────────────────────────

def cloche(f, duree=1.3):
    """Un carillon clair : des partiels presque harmoniques qui s'éteignent chacun à son rythme, une attaque de 2 ms,
    un petit clic de métal (la pièce qui touche le bac)."""
    t = np.arange(int(duree * SR)) / SR
    s = np.zeros_like(t)
    for r, a, d in [(1.0, 1.0, 0.9), (2.0, 0.45, 0.45), (3.0, 0.22, 0.28), (4.16, 0.12, 0.18), (5.43, 0.06, 0.1)]:
        s += a * np.exp(-t / d) * np.sin(2 * np.pi * f * r * t)
    s *= np.minimum(1.0, t / 0.002)
    rng = np.random.default_rng(int(f))
    clic = np.diff(rng.normal(0, 1, int(0.006 * SR) + 1)) * np.exp(-np.arange(int(0.006 * SR)) / (0.0015 * SR))
    s[: len(clic)] += 0.08 * clic
    return s


def piece_or(f):
    """Deux notes vives, la deuxième une quarte au-dessus (le « ka-tching » des pièces de jeu vidéo), en onde douce."""
    def note(fr, duree, dec):
        t = np.arange(int(duree * SR)) / SR
        w = np.sin(2 * np.pi * fr * t) + 0.28 * np.sin(2 * np.pi * 3 * fr * t) + 0.1 * np.sin(2 * np.pi * 5 * fr * t)
        return w * np.exp(-t / dec) * np.minimum(1.0, t / 0.002)
    a = note(f, 0.075, 0.06)
    b = note(f * 2 ** (5 / 12), 0.45, 0.14)
    return np.concatenate([a, b])


def arpege(f):
    return poser([(i * 0.075, cloche(f * 2 ** (st / 12), 1.4), 1.0 if i < 3 else 1.2) for i, st in enumerate([0, 4, 7, 12])])


# ── les fabrications ──────────────────────────────────────────

def serie(m, n=3, pas=0.28, var=1.0):
    rng = np.random.default_rng(7)
    return poser([(i * pas, ton(m, rng.uniform(-var, var)), rng.uniform(0.75, 1.0)) for i in range(n)])


def cascade(m, pas=0.14):
    return poser([(i * pas, ton(m, st), 1.0) for i, st in enumerate(PENTA)])


def froissement(fichiers, duree=7.0, gain=0.55):
    rng = np.random.default_rng(3)
    grains = [attaque(lire(f)) for f in fichiers]
    t, liste = 0.0, []
    while t < duree - 0.4:
        g = grains[rng.integers(len(grains))]
        liste.append((t, ton(g, rng.uniform(-1.5, 1.5)), gain * rng.uniform(0.5, 1.0)))
        t += rng.uniform(0.3, 0.75)
    m = poser(liste, duree)
    fondu = np.minimum(1.0, np.minimum(np.arange(len(m)), len(m) - np.arange(len(m))) / (0.3 * SR))
    return m * fondu


def extrait(chemin, duree=40.0, rms_db=-20.0):
    x, sr = sf.read(os.path.join(SRC, chemin), always_2d=True)
    if x.shape[1] == 1:
        x = np.repeat(x, 2, axis=1)
    m = x.mean(axis=1)
    i0 = int(np.argmax(np.abs(m) > 10 ** (-45 / 20)))
    x = x[i0: i0 + int(duree * sr)]
    if sr != SR:
        x = np.stack([resample(x[:, c], int(len(x) * SR / sr)) for c in range(2)], axis=1)
    n = len(x)
    env = np.minimum(1.0, np.minimum(np.arange(n) / (1.0 * SR), (n - np.arange(n)) / (3.0 * SR)))
    x = x * env[:, None]
    rms = np.sqrt(np.mean(x ** 2)) + 1e-12
    x = x * (10 ** (rms_db / 20) / rms)
    return x, np.max(np.abs(x))


def main():
    fiches = []

    def son(groupe, code, nom, detail, fichiers):
        fiches.append({"groupe": groupe, "code": code, "nom": nom, "detail": detail, "fichiers": fichiers})

    # A — la pièce lâchée touche le plateau (un choc court) : seule, puis trois de suite
    for code, nom, f in [("A1", "Métal léger", "kenney/impact-sounds/impactMetal_light_002.ogg"),
                         ("A2", "Jetons de casino", "kenney/casino-audio/chips-collide-2.ogg"),
                         ("A3", "Fer-blanc", "kenney/impact-sounds/impactTin_medium_001.ogg"),
                         ("A4", "Verre fin", "kenney/impact-sounds/impactGlass_light_001.ogg")]:
        m = pic(queue(attaque(lire(f))), -4)
        son("A", code, nom, f, [ecrire(code + ".mp3", m), ecrire(code + "-serie.mp3", pic(serie(m), -4))])

    # B — les pièces poussées : un froissement fait de grains tirés au hasard (7 s)
    for code, nom, fs in [("B1", "Poignée de pièces", ["kenney/rpg-audio/handleCoins.ogg", "kenney/rpg-audio/handleCoins2.ogg"]),
                          ("B2", "Jetons qu'on manie", ["kenney/casino-audio/chips-handle-%d.ogg" % i for i in range(1, 7)]),
                          ("B3", "Jetons qu'on empile", ["kenney/casino-audio/chips-stack-%d.ogg" % i for i in range(1, 7)])]:
        son("B", code, nom, ", ".join(os.path.basename(f) for f in fs), [ecrire(code + ".mp3", pic(froissement(fs), -8))])

    # C — une pièce tombe du bord : le gain ; seule, puis en cascade (chaque suivante monte d'une note)
    for code, nom, m in [("C1", "Carillon céleste (synthèse)", cloche(1318.5)),
                         ("C2", "Pièce d'or (synthèse)", piece_or(987.77)),
                         ("C3", "Verre qui chante", lire("kenney/interface-sounds/glass_002.ogg")),
                         ("C4", "Corde pincée", lire("kenney/interface-sounds/pluck_002.ogg"))]:
        m = pic(queue(attaque(m)), -4)
        son("C", code, nom, "synthèse" if "synthèse" in nom else "kenney interface-sounds",
            [ecrire(code + ".mp3", m), ecrire(code + "-cascade.mp3", pic(cascade(m), -3))])

    # D — un objet gagné (l'étoile, une pierre, la lune)
    for code, nom, m in [("D1", "Pizzicato", lire("kenney/music-jingles/jingles_PIZZI03.ogg")),
                         ("D2", "Confirmation", lire("kenney/interface-sounds/confirmation_002.ogg")),
                         ("D3", "Arpège céleste (synthèse)", arpege(1046.5)),
                         ("D4", "Steel-drum", lire("kenney/music-jingles/jingles_STEEL05.ogg"))]:
        son("D", code, nom, "", [ecrire(code + ".mp3", pic(queue(attaque(m)), -3))])

    # E — le plateau du jour vidé : une petite fanfare
    for code, nom, f in [("E1", "Pizzicato, final", "kenney/music-jingles/jingles_PIZZI14.ogg"),
                         ("E2", "Coup d'éclat", "kenney/music-jingles/jingles_HIT08.ogg"),
                         ("E3", "Steel-drum, final", "kenney/music-jingles/jingles_STEEL12.ogg")]:
        son("E", code, nom, f, [ecrire(code + ".mp3", pic(queue(attaque(lire(f))), -3))])

    # F — la musique de fond : 40 s de chacune, au même volume
    for code, (nom, f) in zip(["F%d" % i for i in range(1, 20)], [
            ("Sparkling Cosmic Dust", "musique/sparkling_cosmic_dust.mp3"),
            ("Heavenly Loop", "musique/Heavenly_Loop_0.ogg"),
            ("Magic Space", "musique/magic_space_0.mp3"),
            ("Dreams of a Silver Tower", "musique/dreams_of_a_silver_tower.ogg"),
            ("Starfield Romance", "musique/starfield_romance_5.mp3"),
            ("Crystal Cave", "musique/song18.mp3"),
            ("Galactic Temple", "musique/GalacticTemple.ogg"),
            ("Keep your dream alive", "musique/Keep_your_dream_alive_seamless.ogg"),
            ("Moonlit Rabbits", "musique/moonlit_rabbits_midnight_periapsis.ogg"),
            ("Boîte à musique — Cute Tune", "musique/musicbox2_cute_tune.ogg"),
            ("Boîte à musique — Spooky Waltz", "musique/musicbox1_spooky_waltz.ogg"),
            ("Fantasy — Rising Moon", "musique/Rising_Moon.mp3")]):
        x, p = extrait(f)
        if p > 0.98:
            x = x * (0.98 / p)
        os.makedirs(SORTIE, exist_ok=True)
        sf.write(os.path.join(SORTIE, code + ".mp3"), np.clip(x, -1, 1), SR, format="MP3")
        son("F", code, nom, f, [code + ".mp3"])

    with open(os.path.join(SORTIE, "sons.json"), "w", encoding="utf-8") as fh:
        json.dump(fiches, fh, ensure_ascii=False, indent=1)
    total = sum(os.path.getsize(os.path.join(SORTIE, f)) for f in os.listdir(SORTIE))
    print("%d candidats, %d fichiers, %.1f Mo" % (len(fiches), len(os.listdir(SORTIE)), total / 1e6))


def suite():
    """La page d'écoute, deuxième partie (29/09) : les moments G à Z du catalogue (catalogue.py) — le reste du jeu."""
    import catalogue as C
    fiches = []
    for lettre, (titre, ou, genre, cands) in C.MOMENTS.items():
        for code, (nom, _) in cands.items():
            if genre == "musique":
                x, p = extrait(cands[code][1])
                if p > 0.98:
                    x = x * (0.98 / p)
                os.makedirs(SORTIE, exist_ok=True)
                sf.write(os.path.join(SORTIE, code + ".mp3"), np.clip(x, -1, 1), SR, format="MP3")
                fichiers = [code + ".mp3"]
            elif genre == "famille":
                cinq = C.signal(code)
                fichiers = [ecrire(code + ".mp3", pic(poser([(i * 1.9, s, 1.0) for i, s in enumerate(cinq)]), -3))]
            else:
                m = C.signal(code)
                fichiers = [ecrire(code + ".mp3", m)]
                if genre == "cascade":
                    fichiers.append(ecrire(code + "-cascade.mp3", pic(cascade(m, 0.2), -3)))
            fiches.append({"groupe": lettre, "code": code, "nom": nom, "fichiers": fichiers})
    with open(os.path.join(SORTIE, "sons2.json"), "w", encoding="utf-8") as fh:
        json.dump({"moments": {l: [t, o, g] for l, (t, o, g, _) in C.MOMENTS.items()}, "sons": fiches}, fh, ensure_ascii=False, indent=1)
    print("%d candidats (G à Z)" % len(fiches))


# La page d'écoute, troisième tour (29/09 — Maxim : « pas fan de la musique générale, trop lente/douce » ; « le son d'une
# invocation doit être spectaculaire, marcher avec l'animation ») : les musiques générales les plus VIVES (mesurées : la
# part d'attaques nettes — Starfield Romance en avait 3 %, celles-ci 6 à 9 %), et les deux films de l'invocation.
MUSIQUES_VIVES = [
    ("MG1", "RPG Overworld", "generale/RPG_Overworld.mp3"),
    ("MG2", "Fairy Adventure", "generale/fairy_adventure_bpm140.ogg"),
    ("MG3", "Magic Town", "generale/Magic_Town.mp3"),
    ("MG4", "Celtic Loop", "generale/celtic.mp3"),
    ("MG5", "A New Town", "generale/025_A_New_Town.mp3"),
    ("MG6", "Gem King's Gallery", "generale/gem_kings_gallery-short-original_0.ogg"),
    ("MG7", "Sparkling Cosmic Dust", "musique/sparkling_cosmic_dust.mp3"),
    ("MG8", "Keep your dream alive", "musique/Keep_your_dream_alive_seamless.ogg"),
    ("MG9", "Moonlit Rabbits", "musique/moonlit_rabbits_midnight_periapsis.ogg"),
    ("MG10", "Happy Adventure", "generale/happy_adveture.mp3"),
    ("MG11", "Determined to Fly", "generale/climax.mp3"),
    ("MG12", "Flowerbed Fields", "generale/flowerbed_fields.ogg"),
    ("MG13", "Superhero", "generale/Superhero_fullmix_0.ogg"),
]


def troisieme(films):
    import shutil
    fiches = []
    for code, nom, chemin in MUSIQUES_VIVES:
        x, p = extrait(chemin)
        if p > 0.98:
            x = x * (0.98 / p)
        os.makedirs(SORTIE, exist_ok=True)
        sf.write(os.path.join(SORTIE, code + ".mp3"), np.clip(x, -1, 1), SR, format="MP3")
        fiches.append({"groupe": "MG", "code": code, "nom": nom, "fichiers": [code + ".mp3"]})
    for code, nom, f in [("IV1", "Céleste : cloches, verre, souffle clair", "celeste.mp4"),
                         ("IV2", "Cosmique : grave, gong, ample", "cosmique.mp4")]:
        shutil.copy(os.path.join(films, f), os.path.join(SORTIE, code + ".mp4"))
        fiches.insert(0 if code == "IV1" else 1, {"groupe": "IV", "code": code, "nom": nom, "fichiers": [code + ".mp4"]})
    moments = {
        "IV": ["L'invocation, en vidéo", "Quatre invocations (Base, Or, Prismatique, Full art), puis une ×10 avec une Légende et un Full art. Le son suit l'animation : chaque étoile qui s'allume, le verrou de l'astrolabe, les étoiles aspirées, la révélation. Mets le son.", "video"],
        "MG": ["La musique générale, plus vive", "Les treize plus rythmées de toutes (mesurées), 40 secondes de chacune, au même volume.", "musique"],
    }
    with open(os.path.join(SORTIE, "sons3.json"), "w", encoding="utf-8") as fh:
        json.dump({"moments": moments, "sons": fiches}, fh, ensure_ascii=False, indent=1)
    print("%d éléments (films et musiques)" % len(fiches))


# Cinquième tour (29/09 — un retour de joueur, relayé par Maxim : « je m'attendais à quelque chose de plus doux et
# cosmique » ; Maxim avait trouvé Starfield Romance « trop lente/douce ») : des musiques COSMIQUES qui avancent — mesurées
# entre les deux (Starfield : 0,9 attaque/s ; Moonlit Rabbits : 1,8/s, attaques franches) : des attaques douces, une
# pulsation régulière. Toutes CC0 (sources/cosmique/, LICENCES.md). Chaque extrait est rendu COMME DANS LE JEU : la salle
# (espace.py, ES2), le grave refait pour le haut-parleur, au même volume.
MUSIQUES_COSMIQUES = [
    ("CO1", "Dreamlike State", "cosmique/dreamlike-state.mp3"),
    ("CO2", "Spacious", "cosmique/spacious.mp3"),
    ("CO3", "Celestial Harmony", "cosmique/celestial-harmony.mp3"),
    ("CO4", "Stellar Trailblazer", "cosmique/stellar-trailblazer.mp3"),
    ("CO5", "Through the Universe", "cosmique/through-the-universe.mp3"),
    ("CO6", "Floating in Space", "cosmique/floating-in-space.wav"),
    ("CO7", "Daydream", "cosmique/daydream.mp3"),
    ("CO8", "Magic Space", "musique/magic_space_0.mp3"),
    ("CO9", "Somnium", "cosmique/somnium.mp3"),
    ("CO0", "Aujourd'hui : Moonlit Rabbits", "musique/moonlit_rabbits_midnight_periapsis.ogg"),
]


# Sixième tour (29/09 — Maxim, après les cosmiques : « là ça fait trop film d'horreur, on va repartir sur du plus calme
# comme la première qu'on avait mise […] plusieurs dans ce style, qui détendent ») : les plus PROCHES de Starfield Romance,
# mesurées (mesure_musiques.py : l'allure, la dureté, la clarté du ton, le souffle, le grave). Les cosmiques rejetées avaient
# du souffle (platitude 0,14 à 0,34 contre 0,06), des nappes graves, des tons mineurs ; celles-ci sont propres et claires.
# Sources : sources/calme/ (CC0, LICENCES.md).
MUSIQUES_CALMES = [
    ("CA1", "Crickets", "calme/crickets-general-calm-ambient-music.mp3"),
    ("CA2", "Sunset Plains (Yoiyami, l'auteur de Starfield Romance)", "calme/sunset-plains.mp3"),
    ("CA3", "Waking States", "calme/waking-states.mp3"),
    ("CA4", "Calm Piano 1", "calme/calm-piano-1-vaporware.mp3"),
    ("CA5", "Forget Me Not", "calme/forget-me-not.ogg"),
    ("CA6", "Infinite World", "calme/infinite-world.wav"),
    ("CA7", "Calm Ambient 1", "calme/calm-ambient-1-synthwave-4k.mp3"),
    ("CA8", "First Light Particles (Yoiyami)", "calme/first-light-particles---cc0-atmospheric-pianoamb.mp3"),
    ("CA9", "Good Ending", "calme/good-ending-diamond-dust.wav"),
    ("CA0", "La première : Starfield Romance", "musique/starfield_romance_5.mp3"),
]


def cosmiques(duree=40.0, liste=None):
    import espace as ES
    v = ES.choisie()
    fiches = []
    for code, nom, chemin in liste or MUSIQUES_COSMIQUES:
        x, sr = sf.read(os.path.join(SRC, chemin), always_2d=True)
        x = x[:, :2] if x.shape[1] >= 2 else np.repeat(x, 2, axis=1)
        if sr != SR:
            x = np.stack([resample(x[:, c], int(len(x) * SR / sr)) for c in range(2)], axis=1)
        # l'extrait part là où la musique est installée (son niveau sur 5 s atteint sa médiane − 3 dB), pas dans l'intro
        f = int(5 * SR)
        n5 = np.array([np.sqrt(np.mean(x[i:i + f] ** 2)) for i in range(0, max(1, len(x) - f), SR)])
        i0 = int(np.argmax(n5 >= np.median(n5) * 10 ** (-3 / 20))) * SR
        x = x[i0: i0 + int(duree * SR)]
        g, d = x[:, 0], x[:, 1]
        if np.sum(g * d) / (np.sqrt(np.sum(g * g) * np.sum(d * d)) + 1e-12) > 0.98:
            x = ES.elargir(x.mean(axis=1))
        y = ES.mouiller(ES.haut_parleur(x), v["ir"], v["musique"])[:len(x)]
        n = len(y)
        env = np.minimum(1.0, np.minimum(np.arange(n) / (1.0 * SR), (n - np.arange(n)) / (3.0 * SR)))
        y = y * env[:, None]
        y *= 10 ** (-20 / 20) / (np.sqrt(np.mean(ES.filtre(y, 150, None) ** 2)) + 1e-12)   # à volume égal, au haut-parleur
        if np.max(np.abs(y)) > 0.97:
            y *= 0.97 / np.max(np.abs(y))
        sf.write(os.path.join(SORTIE, code + ".mp3"), np.clip(y, -1, 1), SR, format="MP3")
        fiches.append((code, nom))
        print(code, nom, "à partir de %d s" % (i0 // SR))
    return fiches


if __name__ == "__main__":
    if "--suite" in sys.argv:
        suite()
    elif "--cosmiques" in sys.argv:
        cosmiques()
    elif "--calmes" in sys.argv:
        cosmiques(liste=MUSIQUES_CALMES)
    elif "--troisieme" in sys.argv:
        troisieme(sys.argv[sys.argv.index("--troisieme") + 1])
    else:
        main()
