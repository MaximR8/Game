extends Node

# ─────────────────────────────────────────────────────────────
# L'ÉTAT DU JEU — autoload « GS ». Source unique.
#
# ⛔ Aucune valeur de jeu ne se recopie ailleurs : les écrans
#    lisent ici, ils ne gardent pas leur propre compte.
# ─────────────────────────────────────────────────────────────

signal changed

const SAVE_PATH := "user://save.json"
# 🔴 Le tas de la poussette (300 corps) a SON fichier : il pèse 40 Ko, et l'écrire à chaque
#    pièce gagnée faisait saccader le téléphone (FEATURES ⑦, 25/09).
const TAS_PATH := "user://tas.json"
# Les petits gains (XP, pièces) s'écrivent au plus toutes les N secondes.
const SAUVEGARDE_DIFFEREE_S := 5.0
# v2 (23/09/2026) : les cartes remplacent les six créatures de test.
# Une sauvegarde v1 garde ses tickets, son XP et ses pièces ; sa
# collection (des créatures qui n'existent plus) est remise à zéro.
const SAVE_VERSION := 4        # v3 (26/09) : étoiles, poussière, pierres (FEATURES ⑭) ; v4 (28/09) : les éclats (⑧ lot B)

# Les types. Chaque carte en a un ; la variante Élémentaire en prend la
# matière. « aucun » : Saint Georges, en attendant un septième type.
const TYPES := {
	"feu":    {"nom": "Feu",    "elt": Color("#e0743a"), "clair": Color("#ffc38a"), "sombre": Color("#4a1d0c")},
	"foudre": {"nom": "Foudre", "elt": Color("#6f8fff"), "clair": Color("#dfe8ff"), "sombre": Color("#1a1e4d")},
	"eau":    {"nom": "Eau",    "elt": Color("#2f95ad"), "clair": Color("#a8e6f0"), "sombre": Color("#0c2f3a")},
	"glace":  {"nom": "Glace",  "elt": Color("#8fc3de"), "clair": Color("#f2fbff"), "sombre": Color("#26404f")},
	"nature": {"nom": "Nature", "elt": Color("#6f9a4c"), "clair": Color("#d4e8b0"), "sombre": Color("#203014")},
	"esprit": {"nom": "Esprit", "elt": Color("#9a7de0"), "clair": Color("#efe4ff"), "sombre": Color("#281d44")},
	"aucun":  {"nom": "Sans type", "elt": Color("#8e8a82"), "clair": Color("#e6e0d4"), "sombre": Color("#2b2926")},
}

# Les variantes, de la plus courante à la plus rare. Le poids est sur
# 1000. 🔴 Les pourcentages affichés au joueur se CALCULENT depuis ces
# poids (probas()) : jamais une valeur recopiée à la main ailleurs.
# Le full art : l'illustration peinte en entier, sur toute la carte — tous les
# héros en ont un depuis le 23/09 (« elles peuvent toutes être full art », Maxim).
const VARIANTES := [
	# Taux posés par Maxim le 23/09 au soir : full art 0,1 %, prismatique 1 %,
	# or, ombre et élémentaire un point de moins chacun, le reste à la base.
	{"id": "base",   "nom": "Base",        "poids": 739},
	{"id": "or",     "nom": "Or",          "poids": 150},
	{"id": "ombre",  "nom": "Ombre",       "poids": 70},
	{"id": "elem",   "nom": "Élémentaire", "poids": 30},
	{"id": "prisme", "nom": "Prismatique", "poids": 10},
	{"id": "full",   "nom": "Full art",    "poids": 1},
]

# LA RARETÉ D'UNE CARTE (27/09) — on tire d'abord le rang, puis une carte de ce rang au hasard ; la
# variante se tire à part (VARIANTES). Maxim : « les sbires ont plus de chance de tomber que les
# héros », « rendre plus difficile à avoir les plus forts ». Le rang d'un héros : MoteurCarre.RANGS
# (une Légende a de plus gros chiffres, et pèse plus lourd dans le deck). Les taux sont provisoires (D11).
# 🔴 Les pourcentages affichés au joueur se CALCULENT depuis ces poids (probas_cartes()).
const RARETES := [
	{"id": "sbire",   "nom": "Sbire",   "poids": 600},
	{"id": "heros",   "nom": "Héros",   "poids": 250},
	{"id": "mythe",   "nom": "Mythe",   "poids": 110},
	{"id": "legende", "nom": "Légende", "poids": 40},
]

# Les héros. Types, rôles, ultimes et chiffres : des propositions.
# « pays » : le pays seul, sans la ville (demande de Maxim, 23/09) — l'histoire
# complète de chaque héros est dans docs/art/HEROS.md.
# « cadrage » : où la carte recadre l'illustration, stade par stade
# (0 = on garde le haut, 1 = le bas) — dans ces peintures la tête est haut.
const HEROS := [
	{"id": "doudou", "nom": "El Biète", "type": "feu", "role": "Garde", "pays": "Belgique",
		"formes": ["Dragonnet", "Dragon de procession", "Dragon du Lumeçon"], "cadrage": [0.40, 0.0, 0.04],
		"ult_nom": "Crin porte-bonheur", "ult": "quand il tombe, la ligne ne recule pas.", "pv": 110, "att": 10, "num": "004"},
	{"id": "thor", "nom": "Thor", "type": "foudre", "role": "Frappeur", "pays": "Scandinavie",
		"formes": ["Bambin au marteau", "Guerrier", "Dieu du tonnerre"], "cadrage": [0.22, 0.0, 0.06],
		"ult_nom": "Mjöllnir trop lourd", "ult": "frappe deux fois, mais agit toujours en dernier.", "pv": 60, "att": 26, "num": "012"},
	{"id": "bahamut", "nom": "Bahamut", "type": "eau", "role": "Appui", "pays": "Arabie",
		"formes": ["Alevin", "Poisson des abysses", "Poisson-monde"], "cadrage": [0.30, 0.25, 0.25],
		"ult_nom": "Porter le monde", "ult": "soigne l'allié de devant de 15 PV à chaque manche.", "pv": 70, "att": 6, "num": "007"},
	{"id": "nian", "nom": "Nian", "type": "glace", "role": "Frappeur", "pays": "Chine",
		"formes": ["Petit monstre", "Bête des montagnes", "Nian du réveillon"], "cadrage": [0.45, 0.18, 0.06],
		"ult_nom": "Nuit du réveillon", "ult": "l'ennemi de devant passe son prochain tour.", "pv": 58, "att": 22, "num": "010"},
	{"id": "kitsune", "nom": "Kitsune", "type": "esprit", "role": "Frappeur", "pays": "Japon",
		"formes": ["Renarde à une queue", "Trois queues", "Neuf queues"], "cadrage": [0.40, 0.30, 0.28],
		"ult_nom": "Kitsunebi", "ult": "ses coups ignorent l'armure des gardes.", "pv": 55, "att": 24, "num": "009"},
	{"id": "loki", "nom": "Loki", "type": "esprit", "role": "Appui", "pays": "Scandinavie",
		"formes": ["Gamin farceur", "Métamorphe", "Loki du Ragnarök"], "cadrage": [0.25, 0.12, 0.03],
		"ult_nom": "Métamorphose", "ult": "copie l'ultime de l'ennemi d'en face.", "pv": 62, "att": 16, "num": "013"},
	{"id": "wukong", "nom": "Sun Wukong", "type": "nature", "role": "Frappeur", "pays": "Chine",
		"formes": ["Singe de pierre", "Roi des Singes", "Grand Sage égal du Ciel"], "cadrage": [0.28, 0.22, 0.14],
		"ult_nom": "Bâton Ruyi", "ult": "frappe toute la ligne d'en face, à demi-force.", "pv": 64, "att": 22, "num": "001"},
	{"id": "korrigan", "nom": "Korrigan", "type": "nature", "role": "Appui", "pays": "France",
		"formes": ["Lutin des landes"], "cadrage": [0.25],
		"ult_nom": "Ronde de nuit", "ult": "échange sa place avec l'allié de devant.", "pv": 65, "att": 12, "num": "011"},
	{"id": "georges", "nom": "Saint Georges", "type": "aucun", "role": "Garde", "pays": "Belgique",
		"formes": ["Chevalier du Lumeçon", "Saint Georges en armes", "Vainqueur du Dragon"], "cadrage": [0.2, 0.2, 0.2],
		"ult_nom": "Combat du Lumeçon", "ult": "renvoie à l'attaquant la moitié des dégâts reçus.", "pv": 120, "att": 12, "num": "003"},
	{"id": "ifrit", "nom": "Ifrit", "type": "feu", "role": "Frappeur", "pays": "Arabie",
		"formes": ["Djinn de feu"], "cadrage": [0.08],
		"ult_nom": "Braise éternelle", "ult": "ses coups brûlent : 5 dégâts à chaque manche.", "pv": 58, "att": 28, "num": "006"},
	{"id": "anansi", "nom": "Anansi", "type": "nature", "role": "Appui", "pays": "Ghana",
		"formes": ["Araignée conteuse"], "cadrage": [0.28],
		"ult_nom": "Toile des contes", "ult": "immobilise l'ennemi de devant pendant une manche.", "pv": 60, "att": 14, "num": "008"},
	# Les onze du 23/09 (illustrés par Maxim). Types, rôles, formes, ultimes, chiffres : propositions.
	{"id": "cerbere", "nom": "Cerbère", "type": "feu", "role": "Garde", "pays": "Grèce",
		"formes": ["Chiot des Enfers", "Molosse à deux têtes", "Gardien des Enfers"], "cadrage": [0.4, 0.25, 0.2],
		"ult_nom": "Nul ne passe", "ult": "gagne le double d'armure à chaque coup encaissé.", "pv": 115, "att": 12, "num": "014"},
	{"id": "golem", "nom": "Golem", "type": "nature", "role": "Garde", "pays": "Tchéquie",
		"formes": ["Petit golem d'argile", "Golem de Prague", "Colosse du pont Charles"], "cadrage": [0.45, 0.25, 0.15],
		"ult_nom": "Le nom sacré", "ult": "revient une fois à la vie, avec la moitié de ses PV.", "pv": 125, "att": 8, "num": "015"},
	{"id": "fenrir", "nom": "Fenrir", "type": "glace", "role": "Frappeur", "pays": "Scandinavie",
		"formes": ["Louveteau enchaîné", "Loup des neiges", "Fenrir déchaîné"], "cadrage": [0.4, 0.3, 0.2],
		"ult_nom": "Gleipnir brisé", "ult": "chaque ennemi tombé ajoute 5 à son ATT.", "pv": 62, "att": 24, "num": "016"},
	{"id": "roc", "nom": "Roc", "type": "foudre", "role": "Frappeur", "pays": "Arabie",
		"formes": ["Oisillon du Roc", "Aigle d'orage", "Roc des tempêtes"], "cadrage": [0.5, 0.3, 0.25],
		"ult_nom": "Serres du ciel", "ult": "emporte l'ennemi de devant au bout de sa colonne.", "pv": 60, "att": 25, "num": "017"},
	{"id": "quetzalcoatl", "nom": "Quetzalcoatl", "type": "foudre", "role": "Appui", "pays": "Mexique",
		"formes": ["Serpenteau à plumes", "Serpent des nuées", "Serpent du soleil levant"], "cadrage": [0.3, 0.25, 0.2],
		"ult_nom": "Souffle du vent", "ult": "soigne toute sa colonne de 8 PV à chaque manche.", "pv": 66, "att": 10, "num": "018"},
	{"id": "kelpie", "nom": "Kelpie", "type": "eau", "role": "Frappeur", "pays": "Écosse",
		"formes": ["Poulain du loch", "Cheval des brumes", "Kelpie des tempêtes"], "cadrage": [0.35, 0.3, 0.25],
		"ult_nom": "Crinière d'algues", "ult": "l'ennemi qu'il frappe ne peut plus être soigné.", "pv": 60, "att": 23, "num": "019"},
	{"id": "banshee", "nom": "Banshee", "type": "eau", "role": "Appui", "pays": "Irlande",
		"formes": ["Pleureuse des falaises", "Dame blanche", "Messagère du trépas"], "cadrage": [0.2, 0.2, 0.2],
		"ult_nom": "Le cri", "ult": "à sa première action, l'ennemi le plus faible perd 20 PV.", "pv": 58, "att": 14, "num": "020"},
	{"id": "mothman", "nom": "Mothman", "type": "esprit", "role": "Appui", "pays": "États-Unis",
		"formes": ["Petite phalène", "Homme-phalène", "Présage aux yeux rouges"], "cadrage": [0.35, 0.25, 0.2],
		"ult_nom": "Présage", "ult": "ses alliés esquivent le premier coup du combat.", "pv": 62, "att": 12, "num": "021"},
	{"id": "chevalier", "nom": "Chevalier sans tête", "type": "esprit", "role": "Frappeur", "pays": "Irlande",
		"formes": ["Cavalier des brumes", "Dullahan", "Chevalier sans tête"], "cadrage": [0.3, 0.3, 0.3],
		"ult_nom": "Chevauchée funeste", "ult": "frappe en premier au premier tour, où qu'il soit.", "pv": 64, "att": 23, "num": "022"},
	{"id": "babayaga", "nom": "Baba Yaga", "type": "esprit", "role": "Appui", "pays": "Russie",
		"formes": ["Vieille de la forêt", "Sorcière au mortier", "Dame de l'isba"], "cadrage": [0.15, 0.15, 0.15],
		"ult_nom": "Malédiction", "ult": "les coups de l'ennemi de devant font 30 % de moins.", "pv": 60, "att": 12, "num": "023"},
	{"id": "wendigo", "nom": "Wendigo", "type": "glace", "role": "Frappeur", "pays": "Canada",
		"formes": ["Rôdeur des neiges", "Wendigo affamé", "Wendigo de l'hiver"], "cadrage": [0.15, 0.15, 0.15],
		"ult_nom": "Faim sans fin", "ult": "se soigne de la moitié des dégâts qu'il inflige.", "pv": 62, "att": 22, "num": "024"},
	# Les neuf du 25/09 (illustrés par Maxim). Types, rôles, formes, ultimes, chiffres : propositions.
	{"id": "minotaure", "nom": "Minotaure", "type": "feu", "role": "Frappeur", "pays": "Grèce",
		"formes": ["Veau du labyrinthe", "Minotaure", "Seigneur du Labyrinthe"], "cadrage": [0.25, 0.2, 0.2],
		"ult_nom": "Charge du labyrinthe", "ult": "frappe deux fois l'ennemi de devant au premier tour.", "pv": 70, "att": 22, "num": "025"},
	{"id": "cuelebre", "nom": "Cuélebre", "type": "eau", "role": "Garde", "pays": "Espagne",
		"formes": ["Serpenteau des grottes", "Cuélebre ailé", "Gardien des trésors"], "cadrage": [0.3, 0.25, 0.2],
		"ult_nom": "Écailles d'airain", "ult": "les deux premiers coups qu'il reçoit ne font rien.", "pv": 110, "att": 11, "num": "026"},
	{"id": "thunderbird", "nom": "Oiseau-Tonnerre", "type": "foudre", "role": "Frappeur", "pays": "Amérique du Nord",
		"formes": ["Oisillon d'orage", "Oiseau-Tonnerre", "Seigneur des tempêtes"], "cadrage": [0.35, 0.25, 0.2],
		"ult_nom": "Coup de tonnerre", "ult": "frappe toute la colonne ennemie pour la moitié de son ATT.", "pv": 60, "att": 24, "num": "027"},
	{"id": "anubis", "nom": "Anubis", "type": "esprit", "role": "Appui", "pays": "Égypte",
		"formes": ["Chacal des sables", "Gardien des tombeaux", "Peseur des âmes"], "cadrage": [0.3, 0.2, 0.2],
		"ult_nom": "La pesée des âmes", "ult": "un allié tombé revient, avec 30 % de ses PV.", "pv": 64, "att": 12, "num": "028"},
	{"id": "yeti", "nom": "Yéti", "type": "glace", "role": "Garde", "pays": "Népal",
		"formes": ["Petit yéti", "Yéti des cimes", "Colosse de l'Himalaya"], "cadrage": [0.3, 0.25, 0.2],
		"ult_nom": "Avalanche", "ult": "l'ennemi de devant passe son prochain tour.", "pv": 120, "att": 10, "num": "029"},
	{"id": "chupacabra", "nom": "Chupacabra", "type": "nature", "role": "Frappeur", "pays": "Mexique",
		"formes": ["Chiot épineux", "Chupacabra", "Chupacabra affamé"], "cadrage": [0.35, 0.25, 0.2],
		"ult_nom": "Épines dorsales", "ult": "renvoie 25 % des dégâts qu'il reçoit.", "pv": 60, "att": 23, "num": "030"},
	{"id": "tikbalang", "nom": "Tikbalang", "type": "nature", "role": "Appui", "pays": "Philippines",
		"formes": ["Poulain des bambous", "Tikbalang", "Seigneur des sentiers"], "cadrage": [0.3, 0.25, 0.2],
		"ult_nom": "Égarement", "ult": "une fois, l'ennemi de devant frappe un de ses alliés.", "pv": 62, "att": 13, "num": "031"},
	{"id": "bunyip", "nom": "Bunyip", "type": "eau", "role": "Garde", "pays": "Australie",
		"formes": ["Petit bunyip", "Bunyip des marais", "Bunyip des billabongs"], "cadrage": [0.3, 0.25, 0.2],
		"ult_nom": "Cri du marais", "ult": "les ennemis perdent 10 % de leur ATT.", "pv": 112, "att": 11, "num": "032"},
	{"id": "troll", "nom": "Troll", "type": "nature", "role": "Garde", "pays": "Norvège",
		"formes": ["Trollet des bois", "Troll des montagnes", "Troll de pierre"], "cadrage": [0.3, 0.25, 0.2],
		"ult_nom": "Peau de pierre", "ult": "prend moitié moins de dégâts tant qu'il a plus de la moitié de ses PV.", "pv": 130, "att": 9, "num": "033"},
]

# 🔴 Les objets de l'univers (FEATURES ⑭, 26/09) : les tickets sont des ÉTOILES d'invocation, l'XP
#    de la POUSSIÈRE d'étoile, les éclats des PIERRES — une par type, et la pierre de lune qui
#    remplace n'importe laquelle. Une vieille sauvegarde est convertie 1 pour 1 (load_game).
# 🔴 L'ÉVOLUTION EST LONGUE (28/09, ⑧ lot B — Maxim : « ça doit être difficile d'évoluer les cartes, faut une belle
#    durée de vie ») : un niveau coûte 100 × le niveau ; du stade s au stade s+1 : le niveau 5 × s, et s pierres de
#    son type (la lune complète s'il en manque). Un héros à trois stades s'arrête au niveau 10 (4 500 poussières
#    pour y arriver) ; un héros à un seul stade, comme un sbire, n'a pas de niveau. Avant : 40 × le niveau, niveau 3 × s,
#    une pierre, sans plafond (la poussière ne servait plus à rien après 16 800).
const POUSSIERE_PAR_NIVEAU := 100
const NIVEAU_PAR_STADE := 5

# 🔴 LES ÉCLATS (28/09, ⑧ lot B — Maxim : « pokemon te donne des cristaux quand tu ouvres des packs et tu peux tout
#    acheter comme carte sauf les Full art ») : chaque carte invoquée en donne ; ils achètent n'importe quelle carte,
#    dans n'importe quelle variante — sauf le Full art, qui reste de la pure chance. Un vrai doublon (même carte, même
#    variante) donne des éclats en plus, selon sa rareté ; plus de poussière (« imagine j'ai un doublon d'une carte en
#    Full art, ça m'énerverait que ça me donne de la poussière »).
const ECLATS_PAR_INVOCATION := 5
const PRIX_RANG := {"sbire": 60, "heros": 200, "mythe": 450, "legende": 900}
const PRIX_VARIANTE := {"base": 1, "or": 2, "ombre": 3, "elem": 5, "prisme": 10}     # pas de Full art
const ECLATS_DOUBLON := {"base": 5, "or": 10, "ombre": 20, "elem": 40, "prisme": 100, "full": 300}
# Tirées, ces variantes tombent sur une carte qui ne les a pas encore (tant qu'il en reste dans le rang) : jamais en
# double. Le rang et la variante sont tirés comme avant — les pourcentages affichés restent vrais.
const VARIANTES_SANS_DOUBLE := ["prisme", "full"]
# Les pierres qu'on peut avoir : les six types, et la lune. La roche viendra avec la roue des types.
const PIERRES := ["feu", "foudre", "eau", "glace", "nature", "esprit", "lune"]
const NOMS_PIERRES := {"feu": "pierre de feu", "foudre": "pierre de foudre", "eau": "pierre d'eau",
	"glace": "pierre de glace", "nature": "pierre de nature", "esprit": "pierre d'esprit", "lune": "pierre de lune"}

var poussiere: int = 0
var etoiles: int = 1
var eclats: int = 0              # (28/09, ⑧ lot B) : ils achètent une carte, dans l'Atlas
var pierres: Dictionary = {}     # type de pierre -> nombre
# Le Voyage (le Carré des astres, 27/09) : le combat guidé, l'Aventure, les decks, le Duel, le Classé —
# et, depuis le 28/09, ce qui suit le jour : la poussière du jour (arene.gd), le plateau du jour
# (plateau.gd), les défis des Présages (presages.gd). Chacun lit sa clé avec prudence : une sauvegarde
# plus ancienne se charge telle quelle (FEATURES ②).
var voyage: Dictionary = {}

# (Le plateau du jour, compté ici depuis le 26/09, est devenu une vraie limite le 28/09 : plateau.gd.)
# Les cartes possédées : id du héros -> {"stade", "niveau",
#   "variante" (celle qu'on affiche), "variantes" (toutes celles qu'on a tirées)}
var cartes: Dictionary = {}
# Les tests coupent la sauvegarde : sinon ils écriraient le fichier du PC.
var sauvegarde_active := true
var last_daily: String = ""
var parties: int = 0

# 🔴 Le tas de la poussette est un ÉTAT DE JEU, pas un décor :
# il se sauvegarde, sinon « ce qui est au bord ce soir est encore
# au bord demain » ne veut rien dire.
var tas_pieces: Array = []      # [[x, y], ...]
var tas_lots: Array = []        # [{"x":, "y":, "type":}, ...]
var tas_bloc: Dictionary = {}   # {"y":, "avance":} : où en était le bloc

# Les pièces EN MAIN. Une poussette se joue en continu : on lâche
# quand on veut, et ce qui tombe du bord revient en main.
# ⛔ Jamais de minuteur bloquant : la main se régénère toute seule.
var main_pieces: int = 30

# Estampille de la geometrie du plateau au moment de la sauvegarde.
# 🔴 Un tas enregistre avec d'ANCIENNES cotes replace des pieces la ou
# le poussoir se trouve desormais : penetration massive, forces
# infinies, NaN en cascade. Le jeu ne plante pas, il devient fou.
# Si l'estampille ne correspond plus, on REGENERE au lieu de charger.
var tas_geo: int = 0


var _a_ecrire := false
var _depuis_ecriture := 0.0


func _ready() -> void:
	load_game()


# ─────────────────────────────────────────────────────────────
# LE PREMIER PACK OFFERT (28/09) — au tout premier lancement, un ×10 offert, guidé pas à pas
# (accueil.gd) : au hasard, mais au moins 5 cartes différentes, dont 3 héros. Il remplace le cadeau
# de départ (10 étoiles, 27/09) et les cartes prêtées du premier deck (Maxim : « non » aux prêtées) :
# chacun a ses 5 cartes pour combattre. Dû tant qu'on ne l'a pas ouvert et qu'on a moins de 5 cartes
# (un cousin qui a dépensé ses 10 étoiles l'a déjà : il n'est pas dû).
# ─────────────────────────────────────────────────────────────
const PACK_DIFFERENTES := 5
const PACK_HEROS := 3


func premier_pack_du() -> bool:
	return not bool(voyage.get("premier_pack", false)) and cartes.size() < PACK_DIFFERENTES


# Le tirage du premier pack, isolé pour être testé (tests/test_tirage.gd) : 10 cartes tirées comme
# au jeu, puis retouchées jusqu'à la garantie — un sbire cède sa place à un héros tiré dans les rangs
# des héros, puis un doublon à une carte qu'on n'a pas encore. Les variantes : comme au jeu.
# Rend [[id, variante], …].
func tirer_premier_pack(rng: RandomNumberGenerator) -> Array:
	var ids: Array = []
	for i in 10:
		ids.append(tirer_carte(rng))
	for garde in 40:
		if _heros_differents(ids) >= PACK_HEROS:
			break
		ids[_place_a_ceder(ids, true)] = _tirer_hors(rng, ids, true)
	for garde in 40:
		if _differentes(ids) >= PACK_DIFFERENTES:
			break
		ids[_place_a_ceder(ids, false)] = _tirer_hors(rng, ids, false)
	var lot: Array = []
	for id in ids:
		lot.append([id, tirer_variante(heros(str(id)), rng)])
	return lot


func _differentes(ids: Array) -> int:
	var vus := {}
	for id in ids:
		vus[id] = true
	return vus.size()


func _heros_differents(ids: Array) -> int:
	var vus := {}
	for id in ids:
		if not est_sbire(str(id)):
			vus[id] = true
	return vus.size()


# La place qui cède : un doublon d'abord (un sbire en double, si on cherche un héros), sinon un sbire.
func _place_a_ceder(ids: Array, pour_un_heros: bool) -> int:
	var vus := {}
	for k in ids.size():
		var id := str(ids[k])
		if vus.has(id) and (not pour_un_heros or est_sbire(id)):
			return k
		vus[id] = true
	for k in ids.size():
		if est_sbire(str(ids[k])):
			return k
	return ids.size() - 1


# Une carte qu'on n'a pas encore dans le pack : tirée comme au jeu, ou parmi les héros seulement
# (leur rang d'abord, à leurs chances : Héros, Mythe, Légende).
func _tirer_hors(rng: RandomNumberGenerator, ids: Array, heros_seulement: bool) -> String:
	for essai in 60:
		var id := ""
		if heros_seulement:
			var total := 0
			for x in RARETES:
				if x["id"] != "sbire":
					total += int(x["poids"])
			var t := rng.randi_range(0, total - 1)
			for x in RARETES:
				if x["id"] == "sbire":
					continue
				t -= int(x["poids"])
				if t < 0:
					var l := ids_du_rang(str(x["id"]))
					id = str(l[rng.randi_range(0, l.size() - 1)])
					break
		else:
			id = tirer_carte(rng)
		if not ids.has(id):
			return id
	return str(HEROS[rng.randi_range(0, HEROS.size() - 1)]["id"])


# Ouvrir le premier pack : ses 10 cartes entrent dans la collection (comme un ×10), une seule fois.
func ouvrir_premier_pack() -> Array:
	if not premier_pack_du():
		return []
	_rng.randomize()
	var lot: Array = []
	for x in tirer_premier_pack(_rng):
		lot.append(_recevoir(heros(str(x[0])), str(x[1])))
	voyage["premier_pack"] = true
	# le premier deck avait pu naître incomplet (moins de 5 cartes) : il se recompose avec le pack
	var d = voyage.get("decks", null)
	if typeof(d) == TYPE_DICTIONARY and (d.get("liste", []) as Array).size() <= 1:
		voyage.erase("decks")
	save_game()
	changed.emit()
	return lot


# La sauvegarde différée : un petit gain la demande, elle part au plus tard N
# secondes après — ou tout de suite si l'app passe en arrière-plan ou se ferme.
func demander_sauvegarde() -> void:
	_a_ecrire = true


func _process(delta: float) -> void:
	_depuis_ecriture += delta
	if _a_ecrire and _depuis_ecriture >= SAUVEGARDE_DIFFEREE_S:
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED 			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _a_ecrire:
			save_game()


# ─────────────────────────────────────────────────────────────
# Le quotidien — la règle des deux jours commence ici
# ─────────────────────────────────────────────────────────────

# 🔴 Les pièces ne se rechargent plus toutes seules (28/09, ⑧) : le cadeau du jour et les défis des Présages
#    en donnent.
const PIECES_CADEAU := 25


func claim_daily() -> bool:
	# Renvoie true si un cadeau du jour vient d'être donné.
	var today := Time.get_date_string_from_system()
	if last_daily == today:
		return false
	last_daily = today
	etoiles += 1
	poussiere += 30
	main_pieces += PIECES_CADEAU
	save_game()
	changed.emit()
	return true


func daily_en_attente() -> bool:
	return last_daily != Time.get_date_string_from_system()


# ─────────────────────────────────────────────────────────────
# Gains
# ─────────────────────────────────────────────────────────────

# Un objet gagné sur le plateau : de la poussière, des étoiles, ou une pierre.
func gagner(gain_poussiere: int, gain_etoiles: int, pierre: String = "") -> void:
	poussiere += gain_poussiere
	etoiles += gain_etoiles
	if pierre != "":
		pierres[pierre] = nb_pierres(pierre) + 1
	# une étoile ou une pierre s'écrit tout de suite ; de la poussière, au plus tard dans 5 s
	if gain_etoiles > 0 or pierre != "":
		save_game()
	else:
		demander_sauvegarde()
	changed.emit()


func nb_pierres(t: String) -> int:
	return int(pierres.get(t, 0))


func total_pierres() -> int:
	var n := 0
	for t in pierres:
		n += int(pierres[t])
	return n


# Outil de test (dette D1 : à retirer avant d'ouvrir le jeu à d'autres).
func donner_etoiles(n: int) -> void:
	etoiles += n
	save_game()
	changed.emit()


# Outil de test (dette D1) : une carte tirée d'office dans la variante voulue,
# pour voir sa mise en scène sans tirer mille cartes. Même arrivée qu'un tirage.
func donner_carte_test(v: String) -> Dictionary:
	var h: Dictionary = HEROS[randi() % HEROS.size()]
	var r := _recevoir(h, v)
	save_game()
	changed.emit()
	return r


# ─────────────────────────────────────────────────────────────
# Les héros et les variantes
# ─────────────────────────────────────────────────────────────

func heros(id: String) -> Dictionary:
	for h in HEROS:
		if h["id"] == id:
			return h
	# un sbire (27/09) : il entre dans la collection comme un héros, à un seul stade
	for sb in MoteurCarre.SBIRES:
		if sb["id"] == id:
			return MoteurCarre.sbire_carte(sb)
	push_error("Carte inconnue : %s" % id)
	return {}


func est_sbire(id: String) -> bool:
	return bool(heros(id).get("sbire", false))


func variante(id: String) -> Dictionary:
	for v in VARIANTES:
		if v["id"] == id:
			return v
	push_error("Variante inconnue : %s" % id)
	return {}


func rang_variante(id: String) -> int:
	for i in VARIANTES.size():
		if VARIANTES[i]["id"] == id:
			return i
	return 0


# Les probabilités telles que le joueur les voit, calculées depuis les poids — ceux du ciel où l'on invoque
# (Portails : le Ciel du Peintre double le Full art).
func probas(portail := "grand") -> Array:
	var poids := Portails.poids_variantes(portail)
	var total := 0
	for w in poids:
		total += int(w)
	var r: Array = []
	for i in VARIANTES.size():
		r.append({"id": VARIANTES[i]["id"], "nom": VARIANTES[i]["nom"], "pct": 100.0 * float(poids[i]) / float(total)})
	return r


# Les cartes qu'on peut tirer dans un rang : les sbires illustrés, ou les héros de ce rang.
func ids_du_rang(r: String) -> Array:
	if r == "sbire":
		return MoteurCarre.sbires_invocables()
	var l := []
	for h in HEROS:
		if str(MoteurCarre.RANGS.get(str(h["id"]), "heros")) == r:
			l.append(str(h["id"]))
	return l


func rang_nom(r: String) -> String:
	for x in RARETES:
		if x["id"] == r:
			return str(x["nom"])
	return ""


# Les chances d'un rang, telles que le joueur les voit, et combien de cartes il compte.
# Un rang vide ne tombe jamais : sa part revient aux autres. Dans un ciel où le Full art ne tombe que sur certains
# rangs (le Ciel du Peintre : jamais un sbire), les chances de chaque rang en tiennent compte.
func probas_cartes(portail := "grand") -> Array:
	var total := 0
	for x in RARETES:
		if not ids_du_rang(str(x["id"])).is_empty():
			total += int(x["poids"])
	var permis := Portails.rangs_full(portail)
	var total_p := 0
	for x in RARETES:
		if permis.has(str(x["id"])) and not ids_du_rang(str(x["id"])).is_empty():
			total_p += int(x["poids"])
	var pf := 0.0                # la chance d'un Full art, dans ce ciel
	if total_p > 0:
		var pv := Portails.poids_variantes(portail)
		var tv := 0
		for w in pv:
			tv += int(w)
		pf = float(pv[rang_variante("full")]) / float(tv)
	var r: Array = []
	for x in RARETES:
		var n := ids_du_rang(str(x["id"])).size()
		var p := float(x["poids"]) / float(total) if n > 0 else 0.0
		if pf > 0.0 and n > 0:
			p = p * (1.0 - pf) + (pf * float(x["poids"]) / float(total_p) if permis.has(str(x["id"])) else 0.0)
		r.append({"id": x["id"], "nom": x["nom"], "n": n, "pct": 100.0 * p})
	return r


# Le tirage d'une carte : son rang, puis l'une des cartes de ce rang.
# Le rang d'une carte tirée (RARETES : Sbire, Héros, Mythe, Légende) ; « permis » : parmi ces rangs seulement.
func tirer_rang(rng: RandomNumberGenerator, permis: Array = []) -> String:
	var tirables: Array = []
	var total := 0
	for x in RARETES:
		if not permis.is_empty() and not permis.has(str(x["id"])):
			continue
		if not ids_du_rang(str(x["id"])).is_empty():
			tirables.append(x)
			total += int(x["poids"])
	var t := rng.randi_range(0, total - 1)
	for x in tirables:
		t -= int(x["poids"])
		if t < 0:
			return str(x["id"])
	return "heros"


func tirer_carte(rng: RandomNumberGenerator) -> String:
	var ids := ids_du_rang(tirer_rang(rng))
	return str(ids[rng.randi_range(0, ids.size() - 1)]) if not ids.is_empty() else str(HEROS[0]["id"])


# Une invocation : le rang, la variante, puis la carte (28/09) — un prismatique ou un Full art tombe sur une carte
# du rang qui ne l'a pas encore, s'il en reste. Rend [id, variante].
# Le ciel (Portails) donne ses poids de variantes ; un Full art n'y tombe que dans ses rangs permis (le Ciel du Peintre :
# jamais un sbire — le rang est alors retiré parmi eux) ; « force_full » : la garantie, un Full art d'office.
# 🔴 Au Grand Ciel, le hasard se tire dans le même ordre qu'avant (le rang, puis la variante) : rien n'y change.
func tirer(rng: RandomNumberGenerator, portail := "grand", force_full := false) -> Array:
	var r := tirer_rang(rng)
	var v := "full" if force_full else tirer_variante({}, rng, Portails.poids_variantes(portail))
	var permis := Portails.rangs_full(portail)
	if v == "full" and not permis.is_empty() and not permis.has(r):
		r = tirer_rang(rng, permis)
	var ids := ids_du_rang(r)
	if VARIANTES_SANS_DOUBLE.has(v):
		var sans := _sans_variante(ids, v)
		# un Full art du Peintre dont le rang est complet : une carte d'un autre rang permis qui ne l'a pas
		if sans.is_empty() and v == "full" and not permis.is_empty():
			for rp in permis:
				sans.append_array(_sans_variante(ids_du_rang(str(rp)), v))
		if not sans.is_empty():
			ids = sans
	return [str(ids[rng.randi_range(0, ids.size() - 1)]), v]


func _sans_variante(ids: Array, v: String) -> Array:
	var sans := []
	for id in ids:
		if not (cartes.has(id) and (cartes[id]["variantes"] as Array).has(v)):
			sans.append(id)
	return sans


# Le tirage de la variante, isolé pour être testé (tests/test_tirage.gd).
# Toutes les variantes peuvent tomber sur tous les héros. « poids » : ceux d'un ciel (vide : VARIANTES).
func tirer_variante(_h: Dictionary, rng: RandomNumberGenerator, poids: Array = []) -> String:
	if poids.size() != VARIANTES.size():
		poids = []
		for v in VARIANTES:
			poids.append(int(v["poids"]))
	var total := 0
	for w in poids:
		total += int(w)
	var t := rng.randi_range(0, total - 1)
	for i in VARIANTES.size():
		t -= int(poids[i])
		if t < 0:
			return str(VARIANTES[i]["id"])
	return str(VARIANTES[0]["id"])


# ─────────────────────────────────────────────────────────────
# Invocation — le tirage
# ─────────────────────────────────────────────────────────────

var _rng := RandomNumberGenerator.new()


func peut_invoquer(n: int = 1, portail := "grand") -> bool:
	return n > 0 and Portails.ouvert(portail) and etoiles >= Portails.cout(portail, n)


func invoquer(portail := "grand") -> Dictionary:
	var lot := invoquer_multi(1, portail)
	return lot[0] if lot.size() == 1 else {}


# Invoque n cartes d'un coup dans un ciel (Portails) : n étoiles (le premier ×10 du Ciel du Peintre est offert), chaque
# carte tirée comme une invocation simple (mêmes probabilités), une seule sauvegarde à la fin.
# La garantie : chaque carte compte ; celle qui atteint le compte (la centième sans Full art) est un Full art d'office.
# Un ciel « unique » se referme après le tirage où tombe son Full art (un ×10 va au bout).
# Renvoie la liste des résultats — vide s'il manque des étoiles, ou si le ciel est refermé. Chaque résultat dit aussi
# son ciel (« portail ») et s'il vient de la garantie (« garanti »).
func invoquer_multi(n: int, portail := "grand") -> Array:
	if not peut_invoquer(n, portail):
		return []
	var cout := Portails.cout(portail, n)
	if cout < n:
		Portails.prendre_offerte(portail)
	etoiles -= cout
	_rng.randomize()
	var g := Portails.garantie(portail)
	var ferme := false
	var lot: Array = []
	for i in n:
		var force := false
		if g > 0:
			Portails.compter(portail)
			force = Portails.compte(portail) >= g
		var x := tirer(_rng, portail, force)
		var r := _recevoir(heros(str(x[0])), str(x[1]))
		r["portail"] = portail
		r["garanti"] = force
		lot.append(r)
		if str(x[1]) == "full" and g > 0:
			Portails.full_tombe(portail)
			ferme = ferme or bool(Portails.fiche(portail).get("unique", false))
	if ferme:
		Portails.fermer(portail)
	Presages.evenement("invocation", n)
	save_game()
	changed.emit()
	return lot


# Une carte tirée entre dans la collection, et donne ses éclats (5, et un vrai doublon en donne plus).
# Renvoie {"heros", "variante", "nouvelle", "nouvelle_variante", "amelioree", "doublon", "eclats"}.
func _recevoir(h: Dictionary, v: String) -> Dictionary:
	var id: String = h["id"]
	var r := _ajouter(id, v)
	r["heros"] = h
	r["doublon"] = not bool(r["nouvelle"]) and not bool(r["nouvelle_variante"])
	r["eclats"] = ECLATS_PAR_INVOCATION + (int(ECLATS_DOUBLON.get(v, 5)) if r["doublon"] else 0)
	eclats += int(r["eclats"])
	return r


# Une carte (dans une variante) entre dans la collection : nouvelle, nouvelle variante, ou déjà là.
func _ajouter(id: String, v: String) -> Dictionary:
	var r := {"variante": v, "nouvelle": false, "nouvelle_variante": false, "amelioree": false}
	if not cartes.has(id):
		cartes[id] = {"stade": 1, "variante": v, "variantes": [v], "niveau": 1}
		r["nouvelle"] = true
		return r
	var e: Dictionary = cartes[id]
	var vs: Array = e["variantes"]
	if not vs.has(v):
		vs.append(v)
		r["nouvelle_variante"] = true
		# (g) : une variante plus rare que celle affichée prend sa place —
		# le joueur peut revenir à une autre depuis la carte en grand.
		if rang_variante(v) > rang_variante(str(e["variante"])):
			e["variante"] = v
			r["amelioree"] = true
	return r


# ─────────────────────────────────────────────────────────────
# Obtenir une carte avec ses éclats (28/09, ⑧ lot B)
# ─────────────────────────────────────────────────────────────

# Le prix d'une carte dans une variante ; -1 si elle ne s'achète pas (le Full art, une carte inconnue).
func prix(id: String, v: String) -> int:
	if not PRIX_VARIANTE.has(v) or MoteurCarre.fiche(id).is_empty():
		return -1
	return int(PRIX_RANG.get(MoteurCarre.rang(id), PRIX_RANG["heros"])) * int(PRIX_VARIANTE[v])


func possede(id: String, v: String) -> bool:
	return cartes.has(id) and (cartes[id]["variantes"] as Array).has(v)


func peut_obtenir(id: String, v: String) -> bool:
	var p := prix(id, v)
	return p > 0 and not possede(id, v) and eclats >= p


func obtenir(id: String, v: String) -> Dictionary:
	if not peut_obtenir(id, v):
		return {}
	eclats -= prix(id, v)
	var r := _ajouter(id, v)
	r["heros"] = heros(id)
	save_game()
	changed.emit()
	return r


# Le joueur choisit, parmi les variantes qu'il possède, celle qu'on affiche.
func choisir_variante(id: String, v: String) -> bool:
	if not cartes.has(id) or not (cartes[id]["variantes"] as Array).has(v):
		return false
	cartes[id]["variante"] = v
	save_game()
	changed.emit()
	return true


# ─────────────────────────────────────────────────────────────
# Progression d'une carte
# ─────────────────────────────────────────────────────────────

func cout_niveau(id: String) -> int:
	if not cartes.has(id):
		return 0
	return POUSSIERE_PAR_NIVEAU * int(cartes[id]["niveau"])


# Le niveau le plus haut utile : celui qui ouvre le dernier stade (10 pour un héros à trois stades). Un sbire, un
# héros à un seul stade : 1 (pas de niveau à monter).
func niveau_max(id: String) -> int:
	if est_sbire(id) or not cartes.has(id):
		return 1
	return maxi(1, NIVEAU_PAR_STADE * (stade_max(id) - 1))


# Un sbire ne monte pas de niveau (un seul stade, pas d'évolution : décidé le 27/09) ; personne au-delà de niveau_max.
func peut_monter(id: String) -> bool:
	return cartes.has(id) and not est_sbire(id) and int(cartes[id]["niveau"]) < niveau_max(id) and poussiere >= cout_niveau(id)


func monter_niveau(id: String) -> bool:
	if not peut_monter(id):
		return false
	poussiere -= cout_niveau(id)
	cartes[id]["niveau"] = int(cartes[id]["niveau"]) + 1
	Presages.evenement("niveau")
	save_game()
	changed.emit()
	return true


func stade_max(id: String) -> int:
	return (heros(id)["formes"] as Array).size()


func niveau_pour_evoluer(id: String) -> int:
	if not cartes.has(id):
		return 0
	return NIVEAU_PAR_STADE * int(cartes[id]["stade"])


func peut_evoluer(id: String) -> bool:
	if not cartes.has(id):
		return false
	if int(cartes[id]["stade"]) >= stade_max(id):
		return false
	return not plan_evolution(id).is_empty() and int(cartes[id]["niveau"]) >= niveau_pour_evoluer(id)


# Combien de pierres pour le stade suivant : 1 pour le stade II, 2 pour le stade III.
func pierres_pour_evoluer(id: String) -> int:
	return int(cartes[id]["stade"]) if cartes.has(id) else 1


# Les pierres que prendra l'évolution : celles de son type d'abord, la lune complète ({type: n, lune: m}) ;
# {} s'il n'y en a pas assez. (Saint Georges, sans type : la lune seulement.)
func plan_evolution(id: String) -> Dictionary:
	if not cartes.has(id):
		return {}
	var n := pierres_pour_evoluer(id)
	var t := str(heros(id)["type"])
	var du_type := mini(n, nb_pierres(t)) if PIERRES.has(t) and t != "lune" else 0
	var de_lune := n - du_type
	if nb_pierres("lune") < de_lune:
		return {}
	var plan := {}
	if du_type > 0:
		plan[t] = du_type
	if de_lune > 0:
		plan["lune"] = de_lune
	return plan


# La pierre qu'on montre pendant l'évolution (celle de son type si elle en prend une, sinon la lune) ; "" s'il en manque.
func pierre_pour_evoluer(id: String) -> String:
	var plan := plan_evolution(id)
	if plan.is_empty():
		return ""
	for t in plan:
		if t != "lune":
			return t
	return "lune"


# Ce qu'il faut pour faire évoluer une carte, en toutes lettres : « 1 pierre d'esprit », « 2 pierres de feu ».
func pierre_demandee(id: String) -> String:
	var t := str(heros(id)["type"]) if cartes.has(id) else ""
	var n := pierres_pour_evoluer(id)
	var nom := str(NOMS_PIERRES.get(t, "pierre de lune"))
	return "%d %s" % [n, nom if n <= 1 else "pierres" + nom.substr(6)]      # « pierre d'eau » → « pierres d'eau »


func evoluer(id: String) -> bool:
	if not peut_evoluer(id):
		return false
	var plan := plan_evolution(id)
	for p in plan:
		pierres[p] = nb_pierres(p) - int(plan[p])
		if int(pierres[p]) <= 0:
			pierres.erase(p)
	cartes[id]["stade"] = int(cartes[id]["stade"]) + 1
	save_game()
	changed.emit()
	return true


# ─────────────────────────────────────────────────────────────
# Sauvegarde
# ─────────────────────────────────────────────────────────────

func save_game() -> void:
	if not sauvegarde_active:
		return
	_a_ecrire = false
	_depuis_ecriture = 0.0
	_ecrire(SAVE_PATH, JSON.stringify(donnees_sauvegarde()))
	if Compte.global != null:
		Compte.global.partie_changee()      # (29/09) elle partira aussi au serveur, en arrière-plan


func donnees_sauvegarde() -> Dictionary:
	return {
		"v": SAVE_VERSION,
		"poussiere": poussiere,
		"etoiles": etoiles,
		"eclats": eclats,
		"pierres": pierres,
		"cartes": cartes,
		"last_daily": last_daily,
		"parties": parties,
		"main_pieces": main_pieces,
		"voyage": voyage,
	}


# Le tas de la poussette, dans son fichier (écrit par la poussette, rarement).
func save_tas() -> void:
	if not sauvegarde_active:
		return
	_ecrire(TAS_PATH, JSON.stringify({"tas_geo": tas_geo, "tas_pieces": tas_pieces, "tas_lots": tas_lots,
		"tas_bloc": tas_bloc}))


func _ecrire(chemin: String, texte: String) -> void:
	# 🔴 On écrit dans un .tmp puis on renomme : un open(path, WRITE)
	# vide la cible AVANT d'écrire. Si ça plante en route, il ne reste
	# rien — et une sauvegarde vidée ne le dit pas.
	var tmp := chemin + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Sauvegarde impossible : %s" % FileAccess.get_open_error())
		return
	f.store_string(texte)
	f.close()

	# Contrôle que le .tmp n'est pas vide avant d'écraser l'original.
	var check := FileAccess.open(tmp, FileAccess.READ)
	if check == null or check.get_length() == 0:
		if check != null:
			check.close()
		push_warning("Sauvegarde annulée : le fichier temporaire est vide.")
		return
	check.close()

	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp),
		ProjectSettings.globalize_path(chemin)
	)
	# Sur le web, globalize_path ne s'applique pas : on repasse en direct.
	if not FileAccess.file_exists(chemin):
		var da := DirAccess.open("user://")
		if da != null:
			da.rename(tmp.get_file(), chemin.get_file())


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	if txt.strip_edges() == "":
		return
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	lire_sauvegarde(parsed)


# Ce que contient une sauvegarde (lue), appliqué au jeu. À part de load_game pour que les tests
# vérifient la conversion d'une vieille sauvegarde sans toucher au vrai fichier (tests/test_objets.gd).
func lire_sauvegarde(parsed: Dictionary, avec_tas := true) -> void:
	# v3 : étoiles, poussière, pierres ; une sauvegarde plus ancienne est convertie 1 pour 1
	#     (tickets → étoiles, XP → poussière, éclats → pierres de lune) : personne ne perd rien.
	poussiere = int(parsed.get("poussiere", parsed.get("xp", 0)))
	etoiles = int(parsed.get("etoiles", parsed.get("tickets", 1)))
	# 🔴 « eclats » a servi deux fois : jusqu'à la v2, les anciennes pierres (converties plus bas en pierres de lune) ;
	#    depuis la v4 (28/09), la monnaie des cartes. On ne la lit que dans une sauvegarde v4 — sinon une vieille partie
	#    aurait ses pierres ET autant d'éclats, sans un mot.
	var vl = parsed.get("v", 0)
	var version := int(vl) if typeof(vl) in [TYPE_INT, TYPE_FLOAT] else 0
	var ec = parsed.get("eclats", 0)
	eclats = maxi(0, int(ec)) if version >= 4 and typeof(ec) in [TYPE_INT, TYPE_FLOAT] else 0
	pierres = {}
	var pp = parsed.get("pierres", null)
	if typeof(pp) == TYPE_DICTIONARY:
		for t in pp.keys():
			if PIERRES.has(str(t)) and int(pp[t]) > 0:
				pierres[str(t)] = int(pp[t])
	elif int(parsed.get("eclats", 0)) > 0:
		pierres["lune"] = int(parsed.get("eclats", 0))
	last_daily = str(parsed.get("last_daily", ""))
	parties = int(parsed.get("parties", 0))
	main_pieces = int(parsed.get("main_pieces", 30))
	var vy = parsed.get("voyage", {})
	voyage = vy if typeof(vy) == TYPE_DICTIONARY else {}
	tas_geo = int(parsed.get("tas_geo", 0))
	var tp = parsed.get("tas_pieces", [])
	tas_pieces = tp if typeof(tp) == TYPE_ARRAY else []
	var tl = parsed.get("tas_lots", [])
	tas_lots = tl if typeof(tl) == TYPE_ARRAY else []
	var tb = parsed.get("tas_bloc", {})
	tas_bloc = tb if typeof(tb) == TYPE_DICTIONARY else {}
	if avec_tas:
		_charger_tas()
	cartes = {}
	# Une sauvegarde v1 n'a pas de cartes (ses « owned » sont des créatures
	# retirées) : on ne les reprend pas.
	var c = parsed.get("cartes", {})
	if typeof(c) != TYPE_DICTIONARY:
		return
	for k in c.keys():
		var e = c[k]
		var id := str(k)
		# Une carte d'un héros retiré, ou mal formée, est ignorée — et on le dit.
		if typeof(e) != TYPE_DICTIONARY or heros(id).is_empty():
			push_warning("Carte ignorée au chargement : %s" % id)
			continue
		var v := str(e.get("variante", "base"))
		if variante(v).is_empty():
			v = "base"
		# Avant le 23/09, une carte ne gardait qu'une variante : c'est sa collection.
		var vs: Array = []
		var lues = e.get("variantes", [v])
		if typeof(lues) == TYPE_ARRAY:
			for x in lues:
				if not variante(str(x)).is_empty() and not vs.has(str(x)):
					vs.append(str(x))
		if not vs.has(v):
			vs.append(v)
		cartes[id] = {
			"stade": clampi(int(e.get("stade", 1)), 1, stade_max(id)),
			"variante": v,
			"variantes": vs,
			"niveau": maxi(1, int(e.get("niveau", 1))),
		}


func _charger_tas() -> void:
	if not FileAccess.file_exists(TAS_PATH):
		return
	var f := FileAccess.open(TAS_PATH, FileAccess.READ)
	if f == null:
		return
	var t = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(t) != TYPE_DICTIONARY:
		return
	tas_geo = int(t.get("tas_geo", 0))
	tas_pieces = t.get("tas_pieces", []) if typeof(t.get("tas_pieces")) == TYPE_ARRAY else []
	tas_lots = t.get("tas_lots", []) if typeof(t.get("tas_lots")) == TYPE_ARRAY else []
	tas_bloc = t.get("tas_bloc", {}) if typeof(t.get("tas_bloc")) == TYPE_DICTIONARY else {}


func reset_tout() -> void:
	poussiere = 0
	etoiles = 1
	eclats = 0
	pierres = {}
	cartes = {}
	voyage = {}
	last_daily = ""
	parties = 0
	tas_pieces = []
	tas_lots = []
	tas_bloc = {}
	main_pieces = 30
	tas_geo = 0
	save_game()
	save_tas()
	changed.emit()
