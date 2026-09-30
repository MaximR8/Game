# -*- coding: utf-8 -*-
"""De VRAIES pièces (29/09/2026 — Maxim : « pas fan du bruit des pièces qui tombent, ça fait jeton, nous on veut un bruit de
pièce, comme dans les vrais coin pushers »).

Mesuré (mesure_pieces.py) : la pièce d'aujourd'hui (Kenney, impactMetal_light) ne TINTE que 0,09 s — un « toc », à peine
plus qu'un jeton de casino (0,04 à 0,06 s) ; une vraie pièce résonne de 0,2 à 1,3 s. Les sources : des prises de vraies
pièces sur Freesound, CC0 (sources/pieces/, _sons.json, LICENCES.md).

Ce module trouve, dans chaque enregistrement, les CHUTES (un événement entouré de silence), mesure chacune (combien elle
tinte, son éclat, ses rebonds), garde la meilleure, la nettoie (le souffle de la prise coupé sous un seuil, une fin douce).

    python design/sons/pieces.py            → la page d'écoute : ecoute/PA*.mp3 (la pièce lâchée), PC*.mp3 (le gain)
"""
import os, sys, json
import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfiltfilt
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import preparer_ecoute as E

SR = E.SR
SRC = os.path.join(E.SRC, "pieces")


def charger(chemin):
    x, sr = sf.read(chemin, always_2d=True)
    m = x.mean(axis=1)
    if sr != SR:
        m = E.resample(m, int(len(m) * SR / sr))
    return m


def enveloppe(m, ms=5):
    k = max(1, int(ms / 1000 * SR))
    return np.sqrt(np.convolve(m ** 2, np.ones(k) / k, "same"))


def chutes(m, silence_db=-38.0, blanc=0.22):
    """Les événements : au-dessus de (pic + silence_db), séparés d'au moins « blanc » secondes de calme."""
    env = enveloppe(m)
    seuil = env.max() * 10 ** (silence_db / 20)
    au = env > seuil
    ev, i, n = [], 0, len(m)
    while i < n:
        if not au[i]:
            i += 1
            continue
        j = i
        calme = 0
        while j < n and calme < blanc * SR:
            calme = calme + 1 if not au[j] else 0
            j += 1
        ev.append((max(0, i - int(0.004 * SR)), j - calme))
        i = j
    return ev


def qualites(seg):
    """tinte (s), éclat (part 3–12 kHz), rebonds, crête (dB)."""
    haut = sosfiltfilt(butter(4, [3000, 12000], "bandpass", fs=SR, output="sos"), seg)
    e = enveloppe(haut)
    ipk = int(np.argmax(e))
    apres = np.where(e[ipk:] > e[ipk] * 10 ** (-30 / 20))[0]
    tinte = apres[-1] / SR if len(apres) else 0.0
    F = np.abs(np.fft.rfft(seg)) ** 2
    f = np.fft.rfftfreq(len(seg), 1 / SR)
    eclat = F[(f > 3000) & (f < 12000)].sum() / (F.sum() + 1e-12)
    env = enveloppe(seg, 2)
    pics = [k for k in range(1, len(env) - 1) if env[k] > env.max() * 0.3 and env[k] >= env[k - 1] and env[k] > env[k + 1]]
    rebonds = 1 + sum(1 for a, b in zip(pics, pics[1:]) if b - a > 0.012 * SR)
    return {"tinte": tinte, "eclat": eclat, "rebonds": rebonds, "duree": len(seg) / SR}


def nettoyer(seg, porte_db=-45.0):
    """Le souffle de la prise : une porte douce (sous le seuil, le son s'éteint), puis une fin en fondu."""
    env = enveloppe(seg, 8)
    g = np.clip((20 * np.log10(env / env.max() + 1e-9) - porte_db) / 10.0, 0.0, 1.0)
    g = np.convolve(g, np.ones(int(0.01 * SR)) / int(0.01 * SR), "same")
    y = seg * g
    idx = np.where(np.abs(y) > np.abs(y).max() * 10 ** (-55 / 20))[0]
    y = y[: idx[-1] + 1]
    n = min(len(y), int(0.03 * SR))
    y[-n:] *= np.linspace(1.0, 0.0, n)
    return E.pic(E.attaque(y) if hasattr(E, "attaque") else y, -3)


def meilleure(chemin, duree_max=1.6, rebonds_max=6):
    """La plus belle chute seule d'un enregistrement : elle tinte, elle brille, peu de rebonds."""
    m = charger(chemin)
    best, score_best = None, -1.0
    for a, b in chutes(m):
        seg = m[a:b]
        if len(seg) < 0.08 * SR or len(seg) > duree_max * SR:
            continue
        q = qualites(seg)
        if q["rebonds"] > rebonds_max or q["tinte"] < 0.12:
            continue
        score = min(q["tinte"], 0.9) * (0.3 + q["eclat"]) / (1 + 0.15 * (q["rebonds"] - 1))
        if score > score_best:
            best, score_best = (seg, q), score
    return best


# ── La page d'écoute : chaque pièce seule, trois de suite, et EN JEU (10 s de Nébuleuse, la musique derrière) ──

def serie(m, rng, n=3, pas=0.23):
    """Trois pièces lâchées de suite, comme au doigt : chacune un peu différente (son.gd § pose : −2..0 dB, ±0,8 demi-ton)."""
    import espace as ES
    out = np.zeros((int((pas * n + 1.8) * SR), 2))
    for k in range(n):
        x = ES.hauteur(ES.stereo(m), rng.uniform(-0.8, 0.8))
        ES.poser(out, x, 0.05 + k * pas + rng.uniform(-0.03, 0.03), rng.uniform(-2, 0))
    return out


def cascade(m, pas=0.3):
    """Des gains qui se suivent : la cascade du jeu (do ré mi sol la do)."""
    import espace as ES
    out = np.zeros((int((pas * 6 + 2.0) * SR), 2))
    for k, dt in enumerate([0, 2, 4, 7, 9, 12]):
        ES.poser(out, ES.hauteur(ES.stereo(m), dt), 0.05 + k * pas, 0.0)
    return out


def en_jeu(pose=None, gain=None):
    """10 s de Nébuleuse, jouées comme le jeu les joue : les pièces lâchées, le poussoir, des gains en cascade, un objet ;
    la musique de la Nébuleuse (Starfield Romance) derrière ; tout dans la salle (espace.py) ; les niveaux de son.gd."""
    import espace as ES
    v = ES.choisie()
    remplace = {"pose": pose, "gain": gain}
    out = np.zeros((int(10.5 * SR), 2))
    cache = {}
    for t, nom, niveau, db, dt in ES.evenements():
        if t > 10.0 or nom not in ("pose", "gain", "objet") and not nom.startswith("froissement"):
            continue
        if nom not in cache:
            m = remplace.get(nom)
            if m is None:
                m, _ = sf.read(os.path.join(ES.SECS, ES.FICHIER.get(nom, nom) + ".ogg"))
            cache[nom] = ES.stereo(ES.effet(m, v))
        ES.poser(out, ES.hauteur(cache[nom], dt), t, ES.NIV[niveau] + ES.BUS_EFFETS + db)
    import preparer_jeu as J
    mus = ES.stereo(ES.musique_boucle(J.boucle("F5", stereo=True), v))[: len(out)]
    tt = np.arange(len(out)) / SR
    env = np.clip(tt / 0.5, 0, 1) * np.clip((10.5 - tt) / 1.0, 0, 1)
    out += mus * (env[:, None] * 10 ** ((ES.NIV["musique"] + ES.BUS_MUSIQUE) / 20))
    return out


def ecrire_mp3(nom, x, cible_db=-18.0):
    """À volume égal (au-dessus de 150 Hz, comme le haut-parleur l'entend), sans écrêter."""
    import espace as ES
    x = ES.stereo(x)
    x = x * (10 ** (cible_db / 20) / (np.sqrt(np.mean(ES.filtre(x, 150, None) ** 2)) + 1e-12))
    if np.max(np.abs(x)) > 0.97:
        x *= 0.97 / np.max(np.abs(x))
    sf.write(os.path.join(E.SORTIE, nom), np.clip(x, -1, 1), SR, format="MP3")


# Les candidates (29/09) : les meilleures chutes SEULES parmi 115 prises CC0 (classées par pieces.meilleure : combien elles
# tintent, leur éclat, peu de rebonds), seulement de VRAIES pièces (écartés d'après leur titre : une bague, une capsule, des
# bruitages de jeu synthétisés, des graines, des coquillages).
POSE = [("PA1", "Des pièces d'or", "fs770106"), ("PA2", "Une pièce sur des pièces", "fs435780"),
        ("PA3", "Des pièces dans un bol", "fs367273"), ("PA4", "Une pièce lâchée", "fs181904"),
        ("PA5", "De la monnaie", "fs640622"), ("PA6", "Une pièce", "fs566201"),
        ("PA7", "Une pièce (2)", "fs497069"), ("PA8", "Une pièce qui tombe", "fs567478")]
GAIN = [("PC1", "Une pièce sur des pièces", "fs435780", False), ("PC2", "Des pièces d'or", "fs770106", False),
        ("PC3", "Le carillon d'aujourd'hui + une pièce sur des pièces", "fs435780", True),
        ("PC4", "Le carillon d'aujourd'hui + des pièces d'or", "fs770106", True)]


def piece(sid):
    seg, _ = meilleure(os.path.join(SRC, sid + ".mp3"))
    return nettoyer(seg)


def main():
    import espace as ES
    v = ES.choisie()
    rng = np.random.default_rng(29)
    fiches = []
    pose0, _ = sf.read(os.path.join(ES.SECS, "piece-pose.ogg"))
    gain0, _ = sf.read(os.path.join(ES.SECS, "gain.ogg"))
    for code, nom, m in [("PA0", "Aujourd'hui", pose0)] + [(c, n, piece(s)) for c, n, s in POSE]:
        ecrire_mp3(code + ".mp3", ES.effet(m, v))
        ecrire_mp3(code + "-serie.mp3", serie(ES.effet(m, v), rng))
        ecrire_mp3(code + "-jeu.mp3", en_jeu(pose=m))
        q = qualites(m)
        fiches.append({"groupe": "PA", "code": code, "nom": nom, "fichiers": [code + ".mp3", code + "-serie.mp3", code + "-jeu.mp3"]})
        print("%s  tinte %.2f s  éclat %3.0f %%  rebonds %d  %s" % (code, q["tinte"], 100 * q["eclat"], q["rebonds"], nom))
    for code, nom, sid, avec in [("PC0", "Aujourd'hui (le carillon)", None, False)] + GAIN:
        if sid is None:
            m = gain0
        else:
            p = piece(sid)
            if avec:
                n = max(len(p), len(gain0))
                m = np.zeros(n)
                m[:len(gain0)] += gain0
                m[:len(p)] += p * 10 ** (-3 / 20)
                m = E.pic(m, -3)
            else:
                m = p
        ecrire_mp3(code + ".mp3", ES.effet(m, v))
        ecrire_mp3(code + "-cascade.mp3", cascade(ES.effet(m, v)))
        ecrire_mp3(code + "-jeu.mp3", en_jeu(gain=m))
        fiches.append({"groupe": "PC", "code": code, "nom": nom, "fichiers": [code + ".mp3", code + "-cascade.mp3", code + "-jeu.mp3"]})
        print(code, nom)
    json.dump(fiches, open(os.path.join(E.SORTIE, "sons7.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)




# ── LE PAQUET (29/09 — Maxim : « la satisfaction, c'est quand un gros paquet tombe d'un coup, ça fait un gros bruit de
#    plusieurs pièces qui tombent ») : de vraies chutes, prises dans plusieurs enregistrements, empilées sur quelques
#    dixièmes de seconde (plus serrées au début), chacune un peu plus haute ou plus basse, plus ou moins fort ; dessous, le
#    choc sourd du tas qui touche le bac. Le jeu le joue quand les pièces se suivent de près (son.gd § gain).
REPERTOIRE = ["fs770106", "fs435780", "fs367273", "fs181904", "fs640622", "fs566201", "fs497069", "fs567478", "fs197214",
              "fs411958", "fs688750"]


def paquet(n, duree, graine=7, choc_db=-14.0):
    rng = np.random.default_rng(graine)
    chutes = []
    for sid in REPERTOIRE:
        try:
            chutes.append(piece(sid))
        except Exception:
            pass
    out = np.zeros(int((duree + 1.6) * SR))
    for i in range(n):
        m = chutes[int(rng.integers(len(chutes)))]
        m = E.ton(m, rng.uniform(-2.5, 2.5))
        t = duree * rng.random() ** 1.6
        a = int(t * SR)
        g = 10 ** (rng.uniform(-9.0, 0.0) / 20)
        k = min(len(m), len(out) - a)
        out[a:a + k] += m[:k] * g
    # le choc du tas dans le bac : un bruit sourd, bref (60 à 500 Hz)
    nb = int(0.12 * SR)
    choc = sosfiltfilt(butter(2, [60, 500], "bandpass", fs=SR, output="sos"), rng.standard_normal(nb))
    choc *= np.exp(-np.arange(nb) / (0.03 * SR))
    choc *= np.max(np.abs(out)) / (np.max(np.abs(choc)) + 1e-12) * 10 ** (choc_db / 20)
    out[:nb] += choc
    return E.pic(E.queue(out, -60), -3)


# ── L'ENTRECHOC (29/09 — Maxim : « quand les pièces s'entrechoquent, c'est aussi un son de jeton, ça doit être des pièces »)
#    de vraies pièces qui tombent sur des pièces, courtes (le jeu les joue quand une pièce tombe du bloc du haut sur le tas)
ENTRECHOC = ["fs435780", "fs788073", "fs349282", "fs847341"]      # coin drop into coins, Coin_Drop_With_Coins, Coin on coins, coin-011


def entrechoc(sid):
    seg, _ = meilleure(os.path.join(SRC, sid + ".mp3"), duree_max=0.6, rebonds_max=3)
    return nettoyer(seg)


# ── L'OBJET GAGNÉ (29/09 — « le son quand on gagne des objets, je suis pas fan, il fait mal aux oreilles ») — mesuré : le
#    carillon d'aujourd'hui (quatre cloches à 1 046 Hz) sortait 9 à 11 dB AU-DESSUS de toutes les pièces, toute son énergie
#    entre 1 et 6 kHz (là où l'oreille est la plus sensible), et montait encore d'une quinte pour la lune.
def adoucir(m, coupe=2500.0, attaque=0.015):
    y = sosfiltfilt(butter(2, coupe, "lowpass", fs=SR, output="sos"), m)
    n = int(attaque * SR)
    y[:n] *= np.linspace(0.0, 1.0, n)
    return E.pic(y, -3)


def note_ronde(f=392.0, duree=2.2):
    """Une note ronde, grave, qui chante longtemps (un bol) : des partiels doux, une attaque lente, rien au-dessus de 3 kHz."""
    t = np.arange(int(duree * SR)) / SR
    s = np.zeros_like(t)
    for r, a, d in [(1.0, 1.0, 1.1), (2.0, 0.25, 0.6), (2.76, 0.12, 0.35), (5.4, 0.04, 0.2)]:
        s += a * np.exp(-t / d) * np.sin(2 * np.pi * f * r * t)
    s *= np.minimum(1.0, t / 0.02)
    return adoucir(s, 3000.0, 0.02)


OBJETS = {"OB1": ("Le paquet seul, sans mélodie", None, 0.0),
          "OB2": ("La même mélodie, une octave plus bas, adoucie", lambda: adoucir(E.arpege(523.25)), -9.0),
          "OB3": ("Une note ronde et grave, comme un bol", note_ronde, -8.0)}


def scene_objet(objet_m, objet_db):
    """7 s de Nébuleuse : des pièces lâchées, puis un OBJET qui tombe avec son amas (le gros paquet, des pièces dans le bac,
    le son de l'objet), puis quelques pièces encore ; la musique derrière. Les niveaux de son.gd."""
    import espace as ES, preparer_jeu as J
    v = ES.choisie()
    lire = lambda n: sf.read(os.path.join(ES.SECS, n + ".ogg"))[0]
    sons = {n: ES.stereo(ES.effet(lire(n), v)) for n in ["piece-pose", "gain", "paquet-2"]}
    out = np.zeros((int(7.5 * SR), 2))
    rng = np.random.default_rng(5)
    for t in [0.5, 0.9, 1.3, 1.9, 2.4, 5.2, 5.8]:
        ES.poser(out, ES.hauteur(sons["piece-pose"], rng.uniform(-0.8, 0.8)), t, ES.NIV["pose"] + ES.BUS_EFFETS + rng.uniform(-2, 0))
    t0 = 3.0
    ES.poser(out, sons["paquet-2"], t0, -1.0 + ES.BUS_EFFETS)
    if objet_m is not None:
        ES.poser(out, ES.stereo(ES.effet(objet_m, v)), t0 + 0.02, objet_db + ES.BUS_EFFETS)
    for k, dt in enumerate([0.05, 0.12, 0.2, 0.31, 0.45, 0.62, 1.4, 1.9]):
        ES.poser(out, ES.hauteur(sons["gain"], min(k, 5) * 0.7 + rng.uniform(-0.4, 0.4)), t0 + dt, ES.NIV["gain"] + ES.BUS_EFFETS)
    mus = ES.stereo(ES.musique_boucle(J.boucle("F5", stereo=True), v))[: len(out)]
    tt = np.arange(len(out)) / SR
    env = np.clip(tt / 0.5, 0, 1) * np.clip((7.5 - tt) / 1.0, 0, 1)
    out += mus * (env[:, None] * 10 ** ((ES.NIV["musique"] + ES.BUS_MUSIQUE) / 20))
    return out


def main_objets():
    import espace as ES
    v = ES.choisie()
    fiches = []
    obj0, _ = sf.read(os.path.join(ES.SECS, "objet.ogg"))
    for code, (nom, fab, db) in [("OB0", ("Aujourd'hui : le carillon", None, 0.0))] + list(OBJETS.items()):
        m = obj0 if code == "OB0" else (fab() if fab else None)
        ecrire_mp3(code + "-jeu.mp3", scene_objet(m, db))
        seul = np.zeros(int(2.5 * SR)) if m is None else np.concatenate([m * 10 ** (db / 20), np.zeros(int(0.5 * SR))])
        paq, _ = sf.read(os.path.join(ES.SECS, "paquet-2.ogg"))
        n = max(len(seul), len(paq))
        mix = np.zeros(n)
        mix[:len(paq)] += paq * 10 ** (-1.0 / 20)
        mix[:len(seul)] += seul
        ecrire_mp3(code + ".mp3", ES.effet(mix, v), cible_db=-20.0)
        fiches.append({"groupe": "OB", "code": code, "nom": nom, "fichiers": [code + ".mp3", code + "-jeu.mp3"]})
        print(code, nom)
    json.dump(fiches, open(os.path.join(E.SORTIE, "sons9.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main_objets() if "--objets" in sys.argv else main()
