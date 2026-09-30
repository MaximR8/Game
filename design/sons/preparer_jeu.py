# -*- coding: utf-8 -*-
"""Les sons du JEU (29/09/2026) : ceux que Maxim a choisis sur la page d'écoute (design/canevas/sons/), prêts pour Godot.

CHOIX ci-dessous = les codes de la page d'écoute (A1…F12). Changer un son : changer sa lettre, relancer :
    python design/sons/preparer_jeu.py
→ proto_degagement/sons/*.ogg (puis --import). Chaque son est :
  · coupé à son attaque (le silence d'avant enlevé : il part sur l'image où la pièce touche) ;
  · mono, 44,1 kHz, OGG Vorbis ; au pic de −3 dB (le jeu règle ensuite le volume de chaque moment) ;
  · la musique : sans son silence de fin, et BOUCLÉE sans raccord (sa fin fondue dans son début, 2,5 s) — le jeu la
    joue en boucle.
Les candidats et leurs sources : preparer_ecoute.py (la même fabrique), sources/LICENCES.md (tout est CC0).
"""
import os, sys
import numpy as np
import soundfile as sf
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import preparer_ecoute as E
import espace as ES

# Choisis par Maxim le 29/09 sur la page d'écoute : « Sons : A1 · B1 · C2 · D3 · E2 · F5 ».
# La musique générale (F) : F5 d'abord ; « trop lente/douce » → MG9 (Moonlit Rabbits, F9) ; puis un joueur : « plus doux et
# cosmique » ; les cosmiques : « film d'horreur » ; retour au calme — Maxim, 29/09 : « j'adore la CA8 et la CA0 […] une
# plus calme, l'autre plus rythmée […] 2 situations » ; puis : « CA0 pour la Nébuleuse et l'autre pour le reste ».
#   F  (CA0 = Starfield Romance, F5)                → la Nébuleuse : musique-nebuleuse.ogg
#   MUSIQUE_ECRANS (CA8 = First Light Particles)    → les autres écrans hors combat : musique.ogg   (son.gd § musique_de)
CHOIX = {"A": "A1", "B": "B1", "C": "C2", "D": "D3", "E": "E2", "F": "F5"}
# La pièce lâchée (A) et le gain (C) : de VRAIES pièces enregistrées (29/09 — Maxim : « ça fait jeton, nous on veut un bruit
# de pièce, comme dans les vrais coin pushers » ; la page d'écoute, 7ᵉ tour : « Sons : PA8 · PC2 »). Elles remplacent A et C :
# la meilleure chute de chaque prise, nettoyée (design/sons/pieces.py ; Freesound, CC0 : sources/LICENCES.md).
# Puis, pour le gain : « PA8 c'est bon ; le PC on n'est pas satisfait, je pense que PA7 représente le mieux les pièces qui
# tombent en bas de la machine » — et, quand elles se suivent de près, le PAQUET (pieces.paquet : de vraies chutes empilées).
PIECES = {"A": ("PA8", "fs567478"), "C": ("PA7", "fs497069")}
PAQUETS = {"paquet-1": (6, 0.30), "paquet-2": (16, 0.60)}       # (combien de pièces, sur combien de secondes)
MUSIQUE_ECRANS = ("CA8", "calme/first-light-particles---cc0-atmospheric-pianoamb.mp3")
# Le reste du jeu (catalogue.py, G à Z) — choisi par Maxim le 29/09 :
# « Sons : G4 · H3 · I1 · J3 · K1 · L1 · M1 · N1 · O1 · P2 · Q3 · R1 · S1 · T3 · U1 · V1 · W2 · X1 · Y2 · Z2 ».
# (K et L — le verrou, la carte retournée — sont sortis le 29/09 : la bande-son de l'invocation les remplace, invocation.py)
CHOIX_SUITE = {"G": "G4", "H": "H3", "I": "I1", "J": "J3", "M": "M1", "N": "N1", "O": "O1",
               "P": "P2", "Q": "Q3", "R": "R1", "S": "S1", "T": "T3", "U": "U1", "V": "V1", "W": "W2", "X": "X1",
               "Y": "Y2", "Z": "Z2"}
# le fichier du jeu de chaque moment (M : cinq fichiers, rarete-1 à rarete-5 ; Z : la boucle du combat)
FICHIERS = {"G": "bouton", "H": "onglet", "I": "refus", "J": "portail", "K": "verrou", "L": "carte-retourne",
            "N": "rang", "O": "carte-pose", "P": "choc", "Q": "retourne-combat", "R": "pouvoir", "S": "protege",
            "T": "victoire", "U": "defaite", "V": "parfait", "W": "niveau", "X": "evolution", "Y": "recevoir"}

JEU = os.path.join(E.ICI, "..", "..", "proto_degagement", "sons")

SOURCES_A = {"A1": "kenney/impact-sounds/impactMetal_light_002.ogg", "A2": "kenney/casino-audio/chips-collide-2.ogg",
             "A3": "kenney/impact-sounds/impactTin_medium_001.ogg", "A4": "kenney/impact-sounds/impactGlass_light_001.ogg"}
SOURCES_B = {"B1": ["kenney/rpg-audio/handleCoins.ogg", "kenney/rpg-audio/handleCoins2.ogg"],
             "B2": ["kenney/casino-audio/chips-handle-%d.ogg" % i for i in range(1, 7)],
             "B3": ["kenney/casino-audio/chips-stack-%d.ogg" % i for i in range(1, 7)]}
SOURCES_D = {"D1": "kenney/music-jingles/jingles_PIZZI03.ogg", "D2": "kenney/interface-sounds/confirmation_002.ogg",
             "D4": "kenney/music-jingles/jingles_STEEL05.ogg"}
SOURCES_E = {"E1": "kenney/music-jingles/jingles_PIZZI14.ogg", "E2": "kenney/music-jingles/jingles_HIT08.ogg",
             "E3": "kenney/music-jingles/jingles_STEEL12.ogg"}
SOURCES_F = {"F1": "musique/sparkling_cosmic_dust.mp3", "F2": "musique/Heavenly_Loop_0.ogg", "F3": "musique/magic_space_0.mp3",
             "F4": "musique/dreams_of_a_silver_tower.ogg", "F5": "musique/starfield_romance_5.mp3", "F6": "musique/song18.mp3",
             "F7": "musique/GalacticTemple.ogg", "F8": "musique/Keep_your_dream_alive_seamless.ogg",
             "F9": "musique/moonlit_rabbits_midnight_periapsis.ogg", "F10": "musique/musicbox2_cute_tune.ogg",
             "F11": "musique/musicbox1_spooky_waltz.ogg", "F12": "musique/Rising_Moon.mp3"}
# les boucles déjà sans raccord (leur page le dit, et la mesure le confirme) : on ne les touche pas
SANS_RACCORD = {"F2", "F8"}


def ecrire(nom, m):
    """🔴 Par blocs de 32 768 échantillons : écrit d'un coup, un long OGG fait planter libsndfile (vu le 29/09 : la
    musique sortait VIDE, et le script mourait sans un mot, code 127).
    Un son mono (un bruitage) passe d'abord dans l'ESPACE du jeu (espace.py, « ES2 » : la salle) et sort stéréo ; une
    musique arrive déjà stéréo (espace.musique_boucle)."""
    os.makedirs(JEU, exist_ok=True)
    chemin = os.path.join(JEU, nom)
    tmp = chemin + ".tmp.ogg"
    if m.ndim == 1:
        ES.garder_sec(nom, m)
        m = ES.effet(m, ES.choisie())
    if np.max(np.abs(m)) > 0.99:
        m = m * (0.99 / np.max(np.abs(m)))
    m = np.clip(m, -1, 1).astype(np.float32)
    with sf.SoundFile(tmp, "w", E.SR, 1 if m.ndim == 1 else m.shape[1], format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(m), 32768):
            f.write(m[i:i + 32768])
    x, _ = sf.read(tmp)
    if abs(len(x) - len(m)) > E.SR * 0.05:
        sys.exit("%s : relu %d échantillons au lieu de %d" % (nom, len(x), len(m)))
    os.replace(tmp, chemin)
    return chemin


def court(m):
    return E.pic(E.queue(E.attaque(m)), -3)


def boucle(code, chemin=None, stereo=False):
    """La musique bouclée. stereo=True : ses deux canaux gardés (une source mono : le même son des deux côtés)."""
    x, sr = sf.read(os.path.join(E.SRC, chemin or SOURCES_F[code]), always_2d=True)
    m = x[:, :2] if stereo and x.shape[1] >= 2 else (np.repeat(x.mean(axis=1, keepdims=True), 2, axis=1) if stereo else x.mean(axis=1))
    if sr != E.SR:
        m = (np.stack([E.resample(m[:, c], int(len(m) * E.SR / sr)) for c in range(2)], axis=1) if stereo
             else E.resample(m, int(len(m) * E.SR / sr)))
    if code not in SANS_RACCORD:
        env = np.abs(m).max(axis=1) if stereo else np.abs(m)
        i0 = int(np.argmax(env > 10 ** (-45 / 20)))
        fin = len(E.queue(env[i0:], -50))
        m = m[i0:i0 + fin]
        n = int(2.5 * E.SR)
        k = np.linspace(0.0, 1.0, n)
        if stereo:
            k = k[:, None]
        debut = m[:n] * np.sqrt(k) + m[-n:] * np.sqrt(1.0 - k)      # la fin fondue dans le début (puissance égale)
        m = np.concatenate([debut, m[n:-n]])
    rms = np.sqrt(np.mean(m ** 2)) + 1e-12
    m = m * (10 ** (-20 / 20) / rms)
    if np.max(np.abs(m)) > 0.95:
        m = m * (0.95 / np.max(np.abs(m)))
    return m


def main():
    faits = []
    import pieces as P
    faits.append(ecrire("piece-pose.ogg", court(P.piece(PIECES["A"][1]))))
    # l'entrechoc (29/09 : « ça doit être des pièces ») remplace le froissement du poussoir (B, des grains de jetons) :
    # de vraies pièces qui tombent sur des pièces (pieces.ENTRECHOC)
    for i, sid in enumerate(P.ENTRECHOC):
        faits.append(ecrire("entrechoc-%d.ogg" % (i + 1), court(P.entrechoc(sid))))
    faits.append(ecrire("gain.ogg", court(P.piece(PIECES["C"][1]))))       # (le carillon C2 d'avant : plus joué)
    for nom, (n, duree) in PAQUETS.items():
        faits.append(ecrire(nom + ".ogg", P.paquet(n, duree, graine=len(nom) + n)))
    d = CHOIX["D"]
    # l'objet (29/09 — « il fait mal aux oreilles » → la page d'écoute, 9ᵉ tour : « OB2 ») : le même arpège, une octave plus
    # bas (523 Hz au lieu de 1 046), sans rien au-dessus de 2,5 kHz, une attaque de 15 ms (pieces.adoucir)
    import pieces as P2
    faits.append(ecrire("objet.ogg", court(P2.adoucir(E.arpege(523.25)))))
    faits.append(ecrire("plateau-vide.ogg", court(E.lire(SOURCES_E[CHOIX["E"]]))))
    faits.append(ecrire("musique-nebuleuse.ogg", ES.musique_boucle(boucle(CHOIX["F"], stereo=True), ES.choisie())))
    faits.append(ecrire("musique.ogg", ES.musique_boucle(boucle(*MUSIQUE_ECRANS, stereo=True), ES.choisie())))
    # le reste du jeu
    import catalogue as C
    for lettre, code in sorted(CHOIX_SUITE.items()):
        genre = C.MOMENTS[lettre][2]
        if genre == "musique":
            faits.append(ecrire("musique-combat.ogg", ES.musique_boucle(boucle(code, C.MOMENTS[lettre][3][code][1], stereo=True),
                                                                       ES.choisie())))
        elif genre == "famille":
            for k, s in enumerate(C.signal(code)):
                faits.append(ecrire("rarete-%d.ogg" % (k + 1), s))
        else:
            faits.append(ecrire(FICHIERS[lettre] + ".ogg", C.signal(code)))
    # le froissement (plus joué depuis le 29/09) et ses fichiers d'import : effacés
    for f in os.listdir(JEU):
        if f.startswith("froissement-") and (f.endswith(".ogg") or f.endswith(".ogg.import")):
            os.remove(os.path.join(JEU, f))
    with open(os.path.join(JEU, "CHOIX.txt"), "w", encoding="utf-8") as fh:
        fh.write("Les sons du jeu viennent de : %s\n(design/sons/preparer_jeu.py ; sources CC0 : design/sons/sources/LICENCES.md)\n"
                 % (" · ".join("%s=%s" % kv for kv in sorted(list({**CHOIX, **{k: v[0] for k, v in PIECES.items()}}.items())
                                                                  + list(CHOIX_SUITE.items())))
                    + " (F : la Nébuleuse) · autres écrans=" + MUSIQUE_ECRANS[0]))
    for f in faits:
        i = sf.info(f)
        print("%-22s %6.2f s  %s" % (os.path.basename(f), i.duration, "stéréo" if i.channels == 2 else "MONO"))


if __name__ == "__main__":
    main()
