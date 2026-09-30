# -*- coding: utf-8 -*-
"""Le catalogue des sons du reste du jeu (29/09/2026, après la Nébuleuse) : l'interface, l'invocation, le combat, la
collection, la musique de combat. Chaque moment (une lettre, G à Z) a ses candidats ; la page d'écoute les montre
(preparer_ecoute.py), le jeu prend ceux que Maxim garde (preparer_jeu.py, CHOIX).

Un candidat rend :
  · un son court (« court ») ;
  · une CASCADE (« cascade ») : le même son qui monte d'une gamme quand les retournements s'enchaînent ;
  · une FAMILLE (« famille ») : cinq sons, de l'Or au Full art (une carte rare : plus elle est rare, plus c'est riche) ;
  · une MUSIQUE (« musique »).
Tout est CC0 (sources/LICENCES.md) ou synthétisé ici.
"""
import numpy as np
import preparer_ecoute as E

SR = E.SR
PENTA = E.PENTA


def _t(duree):
    return np.arange(int(duree * SR)) / SR


def _env(t, attaque=0.003):
    return np.minimum(1.0, t / attaque)


# ── les synthèses ─────────────────────────────────────────────

def scintillement(duree=1.3):
    """Le portail qui s'ouvre : des cloches qui montent en glissant, un souffle d'étoiles (du bruit filtré qui s'éclaircit)."""
    t = _t(duree)
    rng = np.random.default_rng(11)
    s = np.zeros_like(t)
    for k in range(9):
        t0 = k * 0.11
        f = 660.0 * 2 ** (PENTA[k % 6] / 12 + (k // 6))
        tt = np.clip(t - t0, 0, None)
        on = (t >= t0)
        s += on * 0.35 * np.exp(-tt / 0.5) * np.sin(2 * np.pi * f * tt) * np.minimum(1.0, tt / 0.004)
    bruit = rng.normal(0, 1, len(t))
    k = 64
    lisse = np.convolve(bruit, np.ones(k) / k, mode="same")
    air = (bruit - lisse) * 0.05 * np.sin(np.pi * np.clip(t / duree, 0, 1)) ** 2
    return s + air


def cloches_rarete(niveau):
    """Une carte rare : 1 (Or) à 5 (Full art). Plus c'est rare, plus il y a de cloches, plus elles montent, plus ça dure ;
    le Full art finit par un accord et une traîne de scintillement."""
    n = [2, 3, 4, 6, 8][niveau - 1]
    base = [880.0, 880.0, 987.8, 1046.5, 1046.5][niveau - 1]
    notes = [(i * (0.085 - niveau * 0.006), base * 2 ** (PENTA[i % 6] / 12 + i // 6), 1.0) for i in range(n)]
    liste = [(t0, E.cloche(f, 1.2 + 0.2 * niveau), g) for t0, f, g in notes]
    if niveau >= 4:
        fin = notes[-1][0] + 0.12
        for r in [1.0, 1.25, 1.5, 2.0]:
            liste.append((fin, E.cloche(base * r, 2.0), 0.55))
    if niveau == 5:
        liste.append((0.0, scintillement(2.4), 1.0))
    return E.poser(liste)


def accord_celeste(f=523.25, riche=True):
    """Le rang annoncé (Mythe, Légende) : un accord de cloches, attaqué ensemble, qui s'ouvre."""
    liste = [(0.0, E.cloche(f * r, 2.2), 0.8) for r in ([1.0, 1.25, 1.5, 2.0, 2.5] if riche else [1.0, 1.25, 1.5])]
    liste.append((0.02, E.cloche(f * 0.5, 2.5), 0.6))
    return E.poser(liste)


def sortilege():
    """Un pouvoir s'active : un souffle grave qui enfle, puis trois cloches qui montent vite."""
    t = _t(0.9)
    grave = np.sin(2 * np.pi * (70 + 40 * t) * t) * np.exp(-t / 0.35) * np.minimum(1.0, t / 0.03) * 0.9
    liste = [(0.0, grave, 1.0)] + [(0.08 + i * 0.06, E.cloche(1174.7 * 2 ** (st / 12), 0.9), 0.7) for i, st in enumerate([0, 4, 7])]
    return E.poser(liste)


def tic_doux():
    """Changer de page : un tic très court, une note de verre."""
    t = _t(0.12)
    return np.sin(2 * np.pi * 2093.0 * t) * np.exp(-t / 0.025) * _env(t, 0.001) * 0.8


def choc_sourd():
    """Un bouton éteint : un petit choc sourd, grave, sans note (ça ne passe pas)."""
    t = _t(0.16)
    return np.sin(2 * np.pi * (180 - 300 * t) * t) * np.exp(-t / 0.04) * _env(t, 0.002)


def montee(n=3, f=784.0):
    """Monter de niveau : quelques cloches qui montent vite."""
    return E.poser([(i * 0.07, E.cloche(f * 2 ** (PENTA[i] / 12), 1.0), 1.0) for i in range(n)])


def eclosion():
    """L'évolution : une longue montée (huit notes), puis l'accord céleste."""
    liste = [(i * 0.09, E.cloche(523.25 * 2 ** (PENTA[i % 6] / 12 + i // 6), 1.2), 0.8) for i in range(8)]
    liste.append((0.8, accord_celeste(523.25 * 2), 1.0))
    return E.poser(liste)


# ── le catalogue ──────────────────────────────────────────────

def K(chemin):
    return lambda: E.lire("kenney/" + chemin)


# lettre : (le moment, où dans le jeu, le genre, {code: (nom, fabrique)})
MOMENTS = {
    "G": ("Un bouton touché", "Chaque bouton du jeu. Le plus fréquent de tous : court et discret.", "court", {
        "G1": ("Clic net", K("ui-audio/click1.ogg")),
        "G2": ("Interrupteur", K("ui-audio/switch3.ogg")),
        "G3": ("Sélection", K("interface-sounds/select_002.ogg")),
        "G4": ("Clic doux", K("interface-sounds/click_002.ogg"))}),
    "H": ("Changer d'onglet", "La barre du bas : Nébuleuse, Astrolabe, Atlas, Voyage, Présages.", "court", {
        "H1": ("Tic de verre (synthèse)", tic_doux),
        "H2": ("Survol", K("ui-audio/rollover2.ogg")),
        "H3": ("Carte qui glisse", K("casino-audio/card-slide-1.ogg"))}),
    "I": ("Un bouton éteint qu'on touche", "Le bouton tremble : ça ne passe pas (pas assez d'étoiles…).", "court", {
        "I1": ("Choc sourd (synthèse)", choc_sourd),
        "I2": ("Erreur", K("interface-sounds/error_004.ogg")),
        "I3": ("Retour", K("interface-sounds/back_002.ogg"))}),
    "J": ("Le portail s'ouvre (invocation)", "L'astrolabe se met à tourner, les constellations s'allument.", "court", {
        "J1": ("Scintillement (synthèse)", scintillement),
        "J2": ("Cloche grave", K("impact-sounds/impactBell_heavy_000.ogg")),
        "J3": ("Ouverture", K("interface-sounds/maximize_006.ogg"))}),
    "K": ("L'astrolabe se verrouille", "Ses cercles s'arrêtent d'un coup : le petit « clic » d'une mécanique.", "court", {
        "K1": ("Loquet de métal", K("rpg-audio/metalLatch.ogg")),
        "K2": ("Clic de métal", K("rpg-audio/metalClick.ogg")),
        "K3": ("Interrupteur", K("ui-audio/switch20.ogg"))}),
    "L": ("Une carte se retourne (invocation)", "La carte de dos se retourne ; en ×10, dix fois de suite.", "court", {
        "L1": ("Carte posée", K("casino-audio/card-place-1.ogg")),
        "L2": ("Carte qui glisse", K("casino-audio/card-slide-3.ogg")),
        "L3": ("Éventail", K("casino-audio/card-fan-1.ogg")),
        "L4": ("Page tournée", K("rpg-audio/bookFlip1.ogg"))}),
    "M": ("Une carte rare", "Écoute de l'Or au Full art : dans le jeu, chaque rareté a le sien, plus riche à chaque marche.", "famille", {
        "M1": ("Cloches célestes (synthèse)", lambda: [cloches_rarete(k) for k in range(1, 6)]),
        "M2": ("Verres qui chantent", lambda: [E.poser([(i * 0.1, E.ton(E.lire("kenney/interface-sounds/glass_002.ogg"), PENTA[i]), 1.0) for i in range(k + 1)]) for k in range(1, 6)]),
        "M3": ("Pizzicati", lambda: [E.lire("kenney/music-jingles/jingles_PIZZI%02d.ogg" % i) for i in [1, 3, 5, 10, 14]])}),
    "N": ("Le rang annoncé : Mythe, Légende", "Au retournement, « MYTHE » ou « LÉGENDE » s'affiche en grand.", "court", {
        "N1": ("Accord céleste (synthèse)", accord_celeste),
        "N2": ("Coup d'éclat", K("music-jingles/jingles_HIT03.ogg")),
        "N3": ("Pizzicato", K("music-jingles/jingles_PIZZI10.ogg"))}),
    "O": ("Combat : une carte posée", "Ta carte (ou la sienne) tombe sur sa case.", "court", {
        "O1": ("Carte posée", K("casino-audio/card-place-2.ogg")),
        "O2": ("Carte poussée", K("casino-audio/card-shove-2.ogg")),
        "O3": ("Bois léger", K("impact-sounds/impactWood_light_002.ogg"))}),
    "P": ("Combat : le choc des chiffres", "Deux chiffres qui se touchent s'affrontent (une étoile naît entre eux).", "court", {
        "P1": ("Métal", K("impact-sounds/impactMetal_light_004.ogg")),
        "P2": ("Verre", K("impact-sounds/impactGlass_medium_001.ogg")),
        "P3": ("Jetons", K("casino-audio/chips-collide-4.ogg"))}),
    "Q": ("Combat : une carte retournée", "Elle change de camp. En chaîne, chaque retournement monte d'une note.", "cascade", {
        "Q1": ("Carte qui glisse", K("casino-audio/card-slide-5.ogg")),
        "Q2": ("Corde pincée", K("interface-sounds/pluck_001.ogg")),
        "Q3": ("Pièce d'or (synthèse)", lambda: E.piece_or(783.99))}),
    "R": ("Combat : un pouvoir s'active", "Foudre, Marée, Faim… l'emblème du pouvoir pulse sur la carte.", "court", {
        "R1": ("Sortilège (synthèse)", sortilege),
        "R2": ("Ouverture", K("interface-sounds/maximize_008.ogg")),
        "R3": ("Steel-drum", K("music-jingles/jingles_STEEL02.ogg"))}),
    "S": ("Combat : Esquive, Rempart", "La carte protégée résiste.", "court", {
        "S1": ("Bouclier", K("impact-sounds/impactPlate_heavy_001.ogg")),
        "S2": ("Cloche", K("impact-sounds/impactBell_heavy_002.ogg")),
        "S3": ("Verre", K("interface-sounds/glass_005.ogg"))}),
    "T": ("Combat : victoire", "La fin, gagnée.", "court", {
        "T1": ("Pizzicato", K("music-jingles/jingles_PIZZI16.ogg")),
        "T2": ("Coup d'éclat", K("music-jingles/jingles_HIT15.ogg")),
        "T3": ("Steel-drum", K("music-jingles/jingles_STEEL16.ogg"))}),
    "U": ("Combat : défaite", "La fin, perdue (et l'égalité, un peu plus haut).", "court", {
        "U1": ("Pizzicato", K("music-jingles/jingles_PIZZI07.ogg")),
        "U2": ("Coup d'éclat", K("music-jingles/jingles_HIT07.ogg")),
        "U3": ("Steel-drum", K("music-jingles/jingles_STEEL07.ogg"))}),
    "V": ("Combat : victoire parfaite", "Les 9 cartes à toi : la constellation d'or.", "court", {
        "V1": ("Éclosion céleste (synthèse)", eclosion),
        "V2": ("Coup d'éclat", K("music-jingles/jingles_HIT16.ogg")),
        "V3": ("Pizzicato", K("music-jingles/jingles_PIZZI15.ogg"))}),
    "W": ("Monter de niveau", "LVL +1 dans l'Atlas (la poussière entre dans la carte).", "court", {
        "W1": ("Montée (synthèse)", montee),
        "W2": ("Confirmation", K("interface-sounds/confirmation_004.ogg")),
        "W3": ("Coup d'éclat", K("music-jingles/jingles_HIT01.ogg"))}),
    "X": ("L'évolution", "La carte devient blanche, s'évapore en poussière d'or, et révèle son nouveau stade.", "court", {
        "X1": ("Éclosion céleste (synthèse)", eclosion),
        "X2": ("Steel-drum", K("music-jingles/jingles_STEEL14.ogg")),
        "X3": ("Pizzicato", K("music-jingles/jingles_PIZZI12.ogg"))}),
    "Y": ("Recevoir (un défi, un coffre, un code)", "Ce qu'on reçoit s'envole vers le bandeau.", "court", {
        "Y1": ("Arpège céleste (synthèse)", lambda: E.arpege(1046.5)),
        "Y2": ("Confirmation", K("interface-sounds/confirmation_001.ogg")),
        "Y3": ("Pizzicato", K("music-jingles/jingles_PIZZI02.ogg"))}),
    "Z": ("La musique de combat", "40 secondes de chacune, au même volume. Elle remplace la musique du jeu pendant les combats.", "musique", {
        "Z1": ("Battle Theme A", "combat/battleThemeA_0.mp3"),
        "Z2": ("Prepare Your Swords", "combat/prepare_your_swords.ogg"),
        "Z3": ("Fantasy Orchestral Theme", "combat/FantasyOrchestralTheme_1.mp3"),
        "Z4": ("Determination", "combat/determination.mp3"),
        "Z5": ("Magic Puzzle", "combat/magic_puzzle_in-game_1_bpm110.ogg"),
        "Z6": ("Magician Village", "combat/magician_village_in_game_0.ogg"),
        "Z7": ("Wizard's Battlefield", "combat/wizards_battlefield_bpm165.ogg"),
        "Z8": ("The Hex", "combat/the_hex_09.mp3"),
        "Z9": ("Random Battle", "combat/Random_Battle_0.mp3"),
        "Z10": ("Rising Moon", "musique/Rising_Moon.mp3"),
        "Z11": ("Galactic Temple", "musique/GalacticTemple.ogg")}),
}


def signal(code):
    """Le son (ou la famille de cinq) d'un candidat, prêt : coupé à l'attaque, au pic de −3 dB."""
    lettre = code[0]
    genre = MOMENTS[lettre][2]
    fab = MOMENTS[lettre][3][code][1]
    if genre == "famille":
        return [E.pic(E.queue(E.attaque(m)), -3) for m in fab()]
    return E.pic(E.queue(E.attaque(fab())), -3)
