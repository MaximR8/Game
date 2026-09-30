# 🖥️ INFRA — à savoir toujours

> **Ce fichier répond à une seule question : où tourne quoi, et comment on y touche.**
> ⛔ **Il se remplit AVANT le premier déploiement**, pas après le premier incident.
>
> *État au 20/09/2026 : il n'y a qu'un prototype web. Ni base de données, ni API, ni secret, ni
> nom de domaine. Tout ce fichier décrit une chaîne de test locale, pas une production.*

## Les machines

| | Rôle | Adresse | Accès |
|---|---|---|---|
| **PC Windows** | Édition du code, moteur Godot, export | `192.168.0.169` *(Ethernet)* | la session Claude tourne ici |
| **NAS** | Sert le prototype au réseau local | `192.168.0.17` — `\\nas01\docker\` | Docker · Synology |
| **Téléphone** | 🔴 **Le seul banc valable** — Xiaomi 14T Pro | — | 6,67″ · 2712×1220 · **144 Hz** · saisie tactile jusqu'à 2160 Hz |

⚠️ **Où s'édite le code, et où s'exécutent les commandes** — ce ne sont pas le même endroit.
· On édite et on exporte : **le PC Windows**, dans `\\nas01\docker\_NOUVEAU_PROJET\`.
· On exécute Docker : **sur le NAS** — ⛔ *il n'y a aucun client `docker` sur le PC, les commandes
  `docker compose` se tapent sur le NAS (SSH, ou Container Manager de DSM).*

🔴 **Le PC ne peut PAS servir le prototype.** Son profil réseau est **Public** : le pare-feu
Windows bloque l'entrant, et le changer demande les droits administrateur. C'est pour ça que
tout passe par le NAS — qui a l'avantage d'être toujours allumé.

## Le cycle de déploiement

**① Exporter** *(sur le PC, depuis `_NOUVEAU_PROJET`)* :
```bash
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" --export-release "Web" "../web/index.html"
```

**①bis Corriger le service worker** *(depuis le 25/09 : le jeu est une app installable)* — le service
worker de Godot sert d'abord son cache, et n'installe une nouvelle version qu'une fois l'app fermée
partout. On lui fait prendre la main tout de suite :
```bash
printf "\nself.addEventListener('install', () => self.skipWaiting());\nself.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));\n" >> web/index.service.worker.js
```
⛔ *Une seule fois par export (l'export réécrit le fichier). Sans elle, un téléphone peut garder
l'ancienne version jusqu'à ce que l'app soit fermée partout.*

**② Recompresser** — le `.wasm` fait 39 Mo brut, 10 Mo compressé. `nginx` sert le `.gz` seul :
```bash
gzip -9 -k -f web/index.wasm && gzip -9 -k -f web/index.js
```
⛔ *Oublier cette étape ne casse rien : nginx retombe sur le fichier brut. Mais le `.gz` devient
périmé et **nginx sert l'ancien** — c'est une vieille version servie en silence.*

**③ Servir** *(sur le NAS, une seule fois — le volume est monté en direct, un réexport suffit
ensuite)* :
```bash
cd /volume1/docker/_NOUVEAU_PROJET && docker compose up -d
```

**④ Ouvrir sur le téléphone** *(même réseau Wi-Fi)* — 🔴 **en HTTPS, port 18443** :
```
https://192.168.0.17:18443/
```
⚠️ Le certificat est auto-signé : le navigateur affiche un avertissement au premier accès.
**Paramètres avancés → Continuer vers le site.** C'est normal et sans risque sur ton réseau local.
⛔ *Le port 8099 en clair existe encore, mais **Godot n'y démarrera jamais** — voir les pièges.*

🔴 **LE CONTRÔLE QUI NE SE SAUTE JAMAIS — le premier, avant toute autre requête :**
```bash
curl -s -o /dev/null -w "%{http_code} %{size_download}\n" http://192.168.0.17:8099/index.html
```
*Attendu : `200` et une taille non nulle. Un `200` avec 0 octet veut dire que le volume est monté
mais vide — le conteneur démarre quand même, et il ne dit rien.*

## 🧪 Les tests automatiques *(depuis `_NOUVEAU_PROJET`)*

```bash
# Le tirage : 100 000 tirages contre les probabilités affichées, et aucune illustration manquante
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_tirage.tscn
# Toutes les cartes (héros × stade × variante, recto et verso) construites et dessinées
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_cartes.tscn
# Les objets de l'univers (26/09) : la conversion d'une vieille sauvegarde, l'évolution par pierre
# (de son type, puis de lune, jamais gratuite), le tirage des pierres au fond du plateau — 27 vérifications
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_objets.tscn
# Le VRAI rendu, shaders compris — fenêtre hors écran pendant ~20 s, images PNG dans <dossier>
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/capture_cartes.tscn -- <dossier>
# Le Carré (27/09) : le banc de parité — le moteur web joue 400 parties, le jeu les rejoue coup par coup
node proto_degagement/tests/parite_carre.js 400
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_carre.tscn
# Le Carré : chaque duel montre-t-il les chiffres qui se battent ? (27/09) — l'ancien affichage doit en contredire
# des centaines (le témoin), le nouveau aucun
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/verif_duels.tscn -- 1500
# L'Aventure (27/09) : les 100 niveaux (toujours les mêmes, dessinables, la force visée), les ★ et leurs défis,
# la progression (récompenses une seule fois, coffres, boss, sauvegarde aller-retour, sauvegarde abîmée) — ~3 100 vérifications
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_aventure.tscn
# Mes decks (27/09) : ajouter au bon stade, refuser trop lourd / en double / une 6ᵉ, nettoyer une sauvegarde abîmée,
# 6 decks au plus, la sauvegarde aller-retour — 32 vérifications
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_decks.tscn
# L'Aventure : la courbe — chaque niveau joué N fois par un « joueur moyen » (et un débutant sur la 1ʳᵉ terre), ~2,5 min
# pour 100 niveaux × 80 parties. Options : [parties] [premier niveau] [dernier niveau]. Montre les decks des boss.
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/banc_aventure.tscn -- 80
# Le Duel et le Classé (28/09) : les adversaires (decks légaux, même graine = même adversaire), les marches, le plancher,
# le Zénith, les saisons (récompense une fois, horloge reculée, mois d'absence), Elo, la poussière du jour, le combat
# interrompu, la sauvegarde — ~5 000 vérifications
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_classe.tscn
# La journée (28/09, ⑧ lot A) : le plateau du jour (quota par rang, minuit, pierres du calendrier), les défis des
# Présages (le tirage, les événements, recevoir une fois, le bonus, la semaine), la sauvegarde — ~230 vérifications
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_journee.tscn
# Et dans le vrai jeu : le plateau neuf, entamé, vidé ; les Présages, « Recevoir », la semaine ; sans pièce — 8 captures
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_journee.tscn -- <dossier>
# Le banc de la machine dit aussi, depuis le 28/09, ce qu'elle rapporte par sorte et combien de pièces coûte le plateau
# du jour : « duree=<s> » (180 par défaut), « rythme=<s> » (une pièce toutes les…)
./Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path "./proto_degagement" res://tests/sim_poussoir.tscn -- rythme=1.0 duree=900
# La collection (28/09, ⑧ lot B) : jamais de Full art ni de prismatique en double (200 000 tirages, les taux inchangés), les
# éclats, les prix, obtenir, les niveaux plafonnés, la sauvegarde — ~30 vérifications
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_collection.tscn
# Et dans le vrai jeu : l'Atlas et ses éclats, une carte à obtenir, le niveau maximum, les probabilités, les invocations
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_collection.tscn -- <dossier>
# Les portails de l'Astrolabe (28/09, ⑩) : le Grand Ciel inchangé, le Peintre (Full art 0,2 % mesuré, jamais un sbire), le
# cadeau (refus ET passage), le compteur, la centième, la fermeture, le banc de 12 000 joueurs (jamais au-delà de 100,
# ~18 % avant), jamais en double, la sauvegarde (vieille, abîmée) — 41 vérifications, ~1 min
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_portails.tscn
# Et dans le vrai jeu : le cadeau, l'invocation offerte, le Grand Ciel, les probabilités des deux ciels, « Plus que 7 », le
# Full art garanti dans un ×10, la fermeture et son mot, sans étoile, « Mes decks » dans l'Atlas — 14 captures
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_astrolabe.tscn -- <dossier>
# Le son (29/09) : la pose au contact (pas au geste), la cascade, les objets, la fanfare, le froissement, la musique — le
# vrai jeu, sans écran (on lit ce qui a sonné : Son.journal) ; et le reste du jeu (l'interface, l'invocation, un duel entier, la
# musique du combat) — 26 vérifications. ⚠️ Il lit ce qui est DEMANDÉ : ce qui SORT se mesure dans Chrome (outils/navigateur/son.js)
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_son.tscn
# Les codes cadeaux et les réglages (29/09) : l'empreinte identique à celle de codes.py, refus et passage, une fois, les bus
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/test_codes.tscn
# Et dans le vrai jeu : le Menu des Présages, les Réglages, un code bon / déjà pris / faux — 7 captures
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_menu.tscn -- <dossier>
# L'ouverture des cartes (28/09) : image par image, les révélations (lancées de l'Astrolabe), une ×10, la carte en grand — la pire image, et UNE
# FOIS L'ANIMATION PARTIE (attendu : aucune au-delà de 33 ms) ; et ce que coûte chaque morceau du départ
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/banc_invocation.tscn
# Le décodage d'une illustration, seul (⚠️ depuis le NAS, le premier chargement mesure aussi le réseau : voir les
# rechargements « sans cache », qui ne mesurent que le décodage)
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/banc_image.tscn
# Les glyphes (28/09) : chaque caractère des textes des scripts existe-t-il dans Castoro ? (un absent sort en boîte
# sur le téléphone, jamais sur le PC). « absents des polices : aucun » attendu ; code de sortie 1 sinon.
python proto_degagement/tests/verif_glyphes.py proto_degagement/carre/*.gd proto_degagement/*.gd
# Leur banc : [parties par case] [pas de cote] → le taux de victoire de 5 profils de joueur contre chaque cote (~1,5 min
# à 40) ; « echelle [saisons] [parties] » → des saisons de Classé et du Duel jouées pour de vrai (~8 min à 8 × 250)
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" res://tests/banc_fantomes.tscn -- echelle 8 250
# Le Duel et le Classé dans le vrai jeu : les onglets scellés, un duel et un classé joués jusqu'au bout (et, depuis le 29/09,
# la loupe sous le doigt et la main adverse descendue ; un duel parfait), l'abandon en
# deux touches, la saison finie — 13 captures. RESULTAT: OK attendu.
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_arene.tscn -- <dossier>
# Le Carré dans le vrai jeu : le Voyage, une terre, un coffre qu'on ouvre, l'écran d'avant le combat, un niveau entier
# (glissé au doigt, la pose, le duel, le retournement, la fin avec ses ★ et ses gains), la victoire parfaite, le retour
# à la terre ; « tuto » : le premier combat guidé. Rendu à 1080 × 2400 quelle que soit la fenêtre. RESULTAT: OK attendu.
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/capture_carre.tscn -- <dossier> [niveau 11-100] [graine] [tuto]
# La Nébuleuse (la machine) — repos, semis, tas, un objet qui s'envole, outils, collection : ~10 s
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_poussoir.tscn -- <dossier>
# Les gestes (26/09) : la fiche d'une carte, la montée de niveau (LVL), l'évolution image par image
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_gestes.tscn -- <dossier>
# Le bloc dans ses quatre matières (ivoire, nuit, nébuleuse, jade), au même instant
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_blocs.tscn -- <dossier>
# Les pièces, mesurées sur une capture : l'écart ENTRE pièces et le relief DANS les pièces
python design/objets/mesure_pieces.py <dossier>/godot_poussoir_tas.png
# Ce que coûte une carte, étape par étape (⚠️ lu depuis le NAS : les accès fichiers y sont lents, pas dans le jeu exporté)
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 res://tests/banc_carte.tscn
# Les à-coups de la poussette, image par image (ce qui se passait dans chaque image lente)
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 --fixed-fps 60 res://tests/banc_pics.tscn
# Le banc de performance : le vrai jeu, rendu compris — la poussette poste par poste, la sauvegarde, le lâcher, la collection
./Godot_v4.7.2-stable_win64_console.exe --path "./proto_degagement" --rendering-driver opengl3_angle --resolution 540x1200 --position -3000,0 --fixed-fps 60 res://tests/banc_perf.tscn
# Le banc de la poussette 3D : 3 minutes de jeu en accéléré — hors jeu, rendement, empilement, objets couverts,
# objets qui se chevauchent (26/09), trois objets toujours sur le tas, rechargement
./Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path "./proto_degagement" res://tests/sim_poussoir.tscn -- rythme=0.5
```
*Le banc prend une option : `rythme=<secondes>` entre deux pièces, et affiche le temps par image du PC
chaque minute. ⚠️ Les captures prennent le temps DU JEU (`create_timer(s)`) : si la fenêtre rame,
le moteur ralentit le temps du jeu, et une capture en temps réel tomberait à côté.*

### ⑦ L'essai 3D — servi à part, sur `/essai/`

Le même projet, exporté avec le préréglage **« Web essai 3D »** (drapeau `essai3d` : `main.gd`
bascule alors sur `res://essais/essai_3d.tscn`). Le préréglage « Web » du jeu exclut `essais/*`.
```bash
# Exporter l'essai, puis recompresser (nginx sert les .gz)
./Godot_v4.7.2-stable_win64_console.exe --headless --path "./proto_degagement" --export-release "Web essai 3D" "../web/essai/index.html"
gzip -9 -k -f web/essai/index.wasm && gzip -9 -k -f web/essai/index.js
# Les tests de l'essai : empilement, glissement, objets enfouis, trois minutes de jeu, temps par image (~15 s)
./Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path "./proto_degagement" res://essais/essai_3d.tscn -- tests
```
⚠️ *L'essai et le jeu sont sur la même origine, donc le même stockage : **l'essai ne sauvegarde
jamais** (`GS.sauvegarde_active = false` à son départ).*
*Attendu : `RESULTAT: OK` pour les deux premiers, et **aucune ligne `SCRIPT ERROR`** dans la
sortie — un test peut afficher OK alors que le moteur a signalé une erreur à côté. Tests et
captures coupent la sauvegarde (`GS.sauvegarde_active`) : ils n'écrivent plus rien.*

## 🎨 La fabrique des images *(`design/objets/render_objets.py`, depuis `design/objets`)*

Tout ce qui se dessine en relief (les pièces, les objets, les emblèmes, les boutons, le bloc) sort de
ce script — **jamais d'image faite à la main**. Il faut `numpy` et `Pillow`.
```bash
python render_objets.py --univers                                # les 10 objets en 512 px → univers/ (les originaux)
python render_objets.py --univers --taille 256 --3d univers-256/3d   # les mêmes en 256 + ce qu'il faut au jeu → univers-256/
python render_objets.py --nav                                    # les 5 emblèmes des menus → univers/nav-*.png
python render_objets.py --interface                              # les boutons (or, sombre, éteint), les médaillons → interface/
python render_objets.py --blocs                                  # le dessus du bloc (nuit, nébuleuse, jade) → interface/
python render_objets.py --bannieres                              # les fonds des ciels de l'Astrolabe (28/09), 1020 × 1700 JPEG, à la taille du jeu → interface/banniere-*.jpg
python render_objets.py --hd                                     # les pièces et leur relief (piece-relief.png)
python render_carre.py                                           # le Carré (27/09) : tapis, cadres de case, pierres des chiffres, emblèmes → carre/
python render_rangs.py                                           # les 6 emblèmes des rangs du Classé (28/09) → carre/rang-*.png (+ _planche-rangs.png)
```
**Le Carré** : `carre/*.png` (sauf `_planche.png`) → `proto_degagement/carre/`, puis `--import` ; leurs `.import`
ont `mipmaps/generate=true` (les pierres de 128 px s'affichent à 56).
**Puis copier dans le jeu** (`proto_degagement/`) : `univers-256/*.png` → `objets/` (les icônes) ;
`univers-256/3d/*` → `objets/3d/` (relief, corps, voile, cœur, et **`contours.json`**) ;
`interface/*.png` et `interface/banniere-*.jpg` → `interface/` ; `univers/nav-*.png` → `interface/`. Puis `--import` (deux passes
pour un nouveau fichier). **Les billes** (poussière, étoile) : `*-voile.png` (la nébuleuse déroulée,
2 × 1, sans couture) et `*-coeur.png` (l'objet du centre), assemblés en direct par `objets/bille.gdshader`.
**Les autres objets** : `*-relief.png` (normale, occlusion, matière dans l'alpha) et `*-corps.png`,
extrudés par `objets/volumes.gd` et éclairés par `objets/corps.gdshader`.
- 🔴 **Un rendu partiel (`--univers pierre-feu`) réécrit `contours.json` avec ses seuls objets** : après
  un rendu partiel, **tout régénérer** (`--univers --taille 256 --3d univers-256/3d`) avant de copier.
- 🔴 **Les `*-relief.png` s'importent SANS « fix alpha border »** (`process/fix_alpha_border=false`,
  `compress/normal_map=2`, `detect_3d/compress_to=0`) : la matière est dans l'alpha, l'or y vaut 0 et
  serait écrasé par ses voisins. Régler le `.import` après le premier import, puis réimporter.


## 🔊 Les sons (29/09) — la fabrique et les codes cadeaux

```bash
python -m pip install soundfile scipy numpy                     # une fois
python design/sons/preparer_ecoute.py                            # la page d'écoute : design/canevas/sons/ecoute/*.mp3 (+ index.html)
python design/sons/preparer_jeu.py                               # les sons du jeu, selon CHOIX (en tête du script) → proto_degagement/sons/*.ogg
python design/sons/invocation.py                                 # la bande-son de l'invocation (céleste) → sons/inv-celeste-*.ogg (--toutes : + cosmique)
# (les deux passent chaque son dans l'ESPACE du jeu — design/sons/espace.py, CHOISI = "ES2" — et gardent le sec dans design/sons/secs/)
python design/sons/espace.py                                     # la scène d'écoute de l'espace, en quatre versions → ecoute/ES1..ES4.mp3 (lit les secs)
python design/sons/mesure_musiques.py <modèle> <fichiers…>       # mesurer des musiques (allure, dureté, ton, souffle, grave) et leur distance au modèle
python design/sons/preparer_ecoute.py --calmes                   # les extraits d'écoute « comme dans le jeu » (la salle, le haut-parleur, même volume)
# puis --import (un nouveau fichier), puis l'export
# le film de l'invocation (image + son, pour juger la bande-son SUR l'animation) :
./Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 540x1200 --write-movie film.avi --fixed-fps 30 res://tests/film_invocation.tscn -- celeste
python design/sons/preparer_ecoute.py --troisieme <dossier des films>   # la 3ᵉ page d'écoute (films IV, musiques MG)
python codes_cadeaux/codes.py ajouter NOEL2026 --etoiles 10 --fin 2026-12-31   # un code cadeau : en ligne tout de suite
python codes_cadeaux/codes.py liste                              # les codes, en clair (le registre privé : codes_cadeaux/registre.json)
python codes_cadeaux/codes.py retirer NOEL2026
```
- 🔴 **Sur le web, le son : des bus DÉCLARÉS, jamais créés en cours de partie ; aucun fondu sur un son qui joue.** Godot y
  joue les sons en échantillons du navigateur : un bus ajouté par `add_bus()` n'y est relié à rien (tout se tait, sans une
  erreur), et le volume d'un son déjà lancé n'y suit pas. Les bus : `proto_degagement/default_bus_layout.tres`. Mesurer ce
  qui SORT : `cd outils/navigateur && npm install puppeteer-core@23` (une fois), puis `node son.js https://192.168.0.17:18443/ .`
  (le niveau seconde par seconde ; un son témoin à −20 dB). *Vu le 29/09.*
- 🔴 **Un long OGG écrit d'un coup fait planter libsndfile** (soundfile, Windows) : le fichier sort VIDE et Python meurt sans un
  mot (code 127). `preparer_jeu.py` écrit par blocs et relit ce qu'il a écrit. *Vu le 29/09.*
- **La page d'écoute se publie depuis le dossier de travail de Claude** (l'outil refuse un chemin réseau) : sa source reste
  dans `design/canevas/sons/`.
- **Les codes** : `web/codes/codes.json` (public, des empreintes) n'est PAS écrit par l'export du jeu — il survit aux réexports.

## 🌍 Le jeu PUBLIC, pour les cousins *(⑯, 27/09 — `portier/`)*

**Le chemin** : Internet → la box (**443 public → 8443 du NAS**) → le reverse proxy de DSM (HTTPS **8443**,
certificat `*.naspoizot.synology.me`) → `127.0.0.1:18480` (conteneur `jeu-public`, nginx non root) → il demande
à `jeu-public-portier` (Python, sans dépendance) si le cookie est bon. **Sans le cookie, aucun fichier
du jeu ne sort** : toute adresse renvoie vers `/entree`, la page du code. Seuls le manifeste et les
icônes sortent (le navigateur les demande sans cookie, pour installer le jeu en app).

**Il sert le MÊME export que le jeu local** (`web/`, en lecture seule) : un réexport met à jour les deux.
Les outils de test (D1, D4) ne s'ouvrent que depuis 192.168.… (`main.gd` § `outils_permis`).

```bash
# Sur le NAS (SSH, ou Container Manager → Projet → dossier /docker/_NOUVEAU_PROJET/portier)
cd /volume1/docker/_NOUVEAU_PROJET/portier && sudo docker compose up -d     # démarrer
sudo docker compose logs portier --tail 50                                   # les essais (entrées, codes faux, blocages)
sudo docker compose down                                                     # TOUT FERMER (le jeu local continue)

# Sur le PC (depuis _NOUVEAU_PROJET)
python portier/nouveau_code.py              # un NOUVEAU code : il s'affiche une fois ; tous les cookies tombent
python portier/test_portier.py              # le portier, sans réseau : 30 vérifications, RESULTAT: OK
python portier/verifier_dehors.py <code>    # le portier vu de dehors, par le vrai chemin : RESULTAT: OK
```

**Le secret** : `portier/secret/portier.json` — l'empreinte du code (PBKDF2-SHA256, salée, 200 000 tours)
et la clé qui signe les cookies. **Jamais dans le dépôt** (`.gitignore`). Le code n'est écrit nulle part en clair.

**Le blindage** : 5 essais par minute et par adresse (nginx) ; 10 échecs en une heure → l'adresse est
bloquée une heure ; 50 échecs en une heure en tout → l'entrée est fermée pour tous (portier). Conteneurs non
root, en lecture seule, sans privilège, mémoire bornée, sur leur propre réseau (ils ne voient ni familyos ni
sa base) ; le jeu public n'écoute que sur 127.0.0.1. En-têtes : HSTS, CSP, X-Frame-Options, nosniff,
Referrer-Policy ; aucune version annoncée ; GET/HEAD/POST seulement. **Échec fermé** : sans secret, le portier
ne démarre pas ; sans portier, nginx refuse tout.

**Dans DSM** (réglé par Maxim le 27/09) : la règle de proxy inversé `jeu.naspoizot.synology.me` (HTTPS **8443**, HSTS) →
`http://localhost:18480`, avec l'en-tête personnalisé **`X-Real-IP` = `$remote_addr`** (sans lui, tous les
visiteurs ont la même adresse, et un seul tricheur bloquerait tout le monde) ; l'ancienne règle
`naspoizot.synology.me` (familyos, 502) coupée.
- 🔴 **LA BOX VOO ENVOIE LE 443 PUBLIC VERS LE PORT 8443 DU NAS** (Application → Transfert de port : « 443 → 8443 »).
  Une règle DSM qui écoute sur 443 marche depuis le réseau local, et **pas depuis Internet** (« connection refused »).
  *Trouvé le 27/09 : l'ancienne règle écoutait sur 8443 ; supprimée, plus rien n'y répondait.* La box transfère
  aussi le port 80 vers le NAS : il ne montre que la page d'accueil de Web Station — conseillé de le retirer
  (le certificat `*.naspoizot.synology.me` se renouvelle par le DNS de Synology, sans le port 80).
- **Container Manager n'affiche que les journaux écrits dans SON format** : un `logging: json-file` dans le compose
  donne « Aucun journal disponible » (27/09). Pas de `logging:` dans les compose du NAS.
- **nginx derrière un proxy : `absolute_redirect off`** — sinon ses redirections portent SON port et SON protocole
  (`http://…:8080/entree`).

- 🔴 **La partie d'un cousin vit dans SON navigateur** (le stockage du site, pas le cookie) : perdue s'il
  efface les données du site, en navigation privée, ou sur iPhone après 7 jours sans jouer — **sauf installé
  sur l'écran d'accueil**. L'adresse publique est un autre site que l'adresse locale : les parties ne se
  mélangent pas.

## 🤖 L'app Android — fabriquée sur le PC de Maxim *(30/09/2026)*

Pas de Codemagic pour Android (ses minutes restent à Vesta, et à l'iPhone plus tard) : Godot fabrique l'APK sous Windows.
- **Java 17 portable** : `C:\Users\Maxim\outils-jeu\jdk-17` (Temurin) — **rien de global** (ni JAVA_HOME, ni PATH : le
  Java 8 de Maxim reste le sien). Godot le connaît par ses réglages d'éditeur (`export/android/java_sdk_path`, dans
  `%APPDATA%\Godot\editor_settings-4.7.tres` ; la copie d'avant : `….avant-android`).
- **Le kit Android** : celui de Vesta (`%LOCALAPPDATA%\Android\Sdk`, build-tools 35 à 37, android-36) — on n'y a rien changé.
- **Les modèles d'export Android** de Godot 4.7.2 : `%APPDATA%\Godot\export_templates\4.7.2.stable\android_*` (tirés du
  `.tpz` officiel, gardé dans `outils-jeu`).
- **La clé de signature** : `C:\Users\Maxim\cles-la-poussette\poussette-release.jks` (alias `poussette`) et son mot de
  passe dans `LIRE-MOI.txt` à côté — ⛔ **jamais dans le dépôt**, à sauvegarder dans le gestionnaire de mots de passe de
  Maxim. Empreinte SHA-256 : `03:77:21:13:…:E4:69:40` (celle que Google demandera pour la connexion Google).
- Le réglage d'export « Android » (`export_presets.cfg`) : `be.poizot.poussette`, arm64 seulement, cible SDK 36, Internet +
  vibration ; le projet : portrait (`window/handheld/orientation=1`), textures ETC2/ASTC (exigé par Android ; le web n'en
  prend pas : son `.pck` n'a pas bougé).

```bash
K=C:/Users/Maxim/cles-la-poussette; P=$(grep 'Mot de passe' $K/LIRE-MOI.txt | sed 's/.*: //' | tr -d '\r')
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$K/poussette-release.jks GODOT_ANDROID_KEYSTORE_RELEASE_USER=poussette \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$P" ./Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement \
  --export-release "Android" ../android/la-poussette.apk                # → android/ (hors du dépôt), ~70 Mo
java -jar $LOCALAPPDATA/Android/Sdk/build-tools/37.0.0/lib/apksigner.jar verify --print-certs android/la-poussette.apk
```
- 🔴 Les mots de passe de la clé passent par des **variables d'environnement**, jamais par `export_presets.cfg` (vérifier :
  `grep -i keystore proto_degagement/export_presets.cfg` → vide).
- Pour le Play Store : un **AAB** (il faudra la fabrication Gradle de Godot) ; l'APK sert aux essais (installation directe).

## 📦 Le dépôt — github.com/MaximR8/Game (privé) *(30/09/2026)*

Le projet (`_NOUVEAU_PROJET`) est un dépôt Git depuis le 30/09 — pour Codemagic (l'app iPhone) et pour l'historique.
- **Ce qui y est** : le jeu (`proto_degagement/`, ses `.import`), la doc, les fabriques (`design/*.py`), le portier et les
  codes cadeaux **sans leurs secrets**, les outils. ~90 Mo.
- **Ce qui n'y est pas** (`.gitignore`) : ⛔ les secrets (`/certs/`, `portier/secret/`, `codes_cadeaux/registre.json`,
  les clés de signature `*.jks` / `*.keystore` / `*.p8`) ; le cache Godot ; `/web/` (l'export) ; les exécutables Godot ; les
  sources lourdes re-téléchargeables (`design/sons/sources/**` — sauf `LICENCES.md` et les `_pages.json` / `_sons.json`).
- 🔴 **Sous Windows, Git ne distingue pas les majuscules** : une règle `Cartes/` excluait aussi `proto_degagement/cartes/`
  (vu au 1er envoi : 0 carte). Les règles de dossier sont ancrées à la racine (`/Cartes/`).
- L'accès : une **clé de déploiement** propre au dépôt (`~/.ssh/github_poussette` sur le PC de Maxim, « Allow write
  access ») ; le dépôt la connaît par `git config core.sshCommand`.

```bash
cd //nas01/docker/_NOUVEAU_PROJET
git status && git add -A && git commit -m "…" && git push      # (les messages se terminent par la ligne Co-Authored-By)
git ls-files | grep -iE "certs/|secret|registre|\.jks|\.p8"    # doit rester VIDE
```

## 🗄️ Le serveur des comptes — Nakama sur le VPS de Maxim *(29/09/2026, ⑥)*

**L'adresse** : `https://lapoussette.duckdns.org` (DuckDNS, gratuit — Maxim ne veut ni acheter de domaine maintenant, ni
utiliser ceux de Vesta ou d'Empreinte3D ; un vrai domaine avec le store : une adresse à changer dans le jeu).
**Le VPS** : `ubuntu@51.210.47.220` (OVH, Ubuntu, 7,6 Go, 4 cœurs) — il porte aussi Vesta/FamilyOS (`vesta`, `vestadev`,
`getvesta-landing`) et la boutique d'Empreinte3D (Pina) : **on n'y touche pas**. **Maxim lance les commandes lui-même**
(pas d'accès SSH pour Claude : il colle les résultats).

```
Internet ──443──▶ nginx de l'hôte (site « lapoussette », certbot) ──▶ 127.0.0.1:7350 (Nakama, l'API)
                                                                       127.0.0.1:7351 (la console — jamais par nginx)
Nakama ──réseau Docker « interne »──▶ postgres (jamais publié)
```
- `/opt/lapoussette/` : `docker-compose.yml` (Nakama **3.41.0** figé ; postgres 16 ; plafonds 768 Mo / 512 Mo ; tout en
  127.0.0.1), `.env` (**les secrets, 600, générés sur le VPS** : la base, les clés de session, la console — jamais ailleurs),
  `sauvegarder.sh` + cron **3 h 30** → `sauvegardes/nakama-AAAA-MM-JJ.sql.gz` (14 jours).
- `/etc/nginx/sites-available/lapoussette` (+ lien dans `sites-enabled`) : son propre `map $lapoussette_connexion`
  (le WebSocket) ; certbot a ajouté le 443 et la redirection ; le certificat se renouvelle seul (expire le 28/12/2026).
- **La clé du jeu** (`SERVER_KEY`, `a384cd76…`) : elle sera DANS le jeu (le client s'en sert pour créer un compte) — pas un
  secret ; la clé par défaut de Nakama (`defaultkey`) est refusée (401).
- Au repos : Nakama 13 Mo, postgres 30 Mo. CORS : `Access-Control-Allow-Origin: *` (Nakama) — le jeu web l'appelle.

```bash
cd /opt/lapoussette && docker compose ps                      # l'état (les deux « healthy »)
docker compose logs nakama --tail 30                          # les journaux
curl -s https://lapoussette.duckdns.org/healthcheck           # dehors : 200
ssh -L 7351:127.0.0.1:7351 ubuntu@51.210.47.220               # la console : puis http://localhost:7351 (admin / CONSOLE_PASSWORD du .env)
./sauvegarder.sh                                              # une sauvegarde tout de suite
gunzip -c sauvegardes/nakama-AAAA-MM-JJ.sql.gz | docker compose exec -T postgres psql -U nakama -d nakama   # restaurer
```
- **Vérifié de dehors le 29/09** : un compte créé (appareil), une partie écrite puis relue, le compte **effacé**
  (`DELETE /v2/account` : 200, puis 401 — Apple l'exige) ; la console fermée dehors.
- ⚠️ *Vu en passant (pas le jeu)* : les ports **3000, 3001, 3100** de Vesta répondent depuis Internet en HTTP direct (ufw
  inactif, Docker publie sur 0.0.0.0) — à fermer dans leurs compose (`"127.0.0.1:3000:3000"`), si Maxim le veut.
- Le jeu : `proto_degagement/compte.gd` ; son test contre le vrai serveur : `tests/test_compte.tscn` (crée un compte d'essai et
  l'efface). La CSP du portier ouvre `https://` et `wss://lapoussette.duckdns.org` (29/09) — **redémarrer `jeu-public`** après
  un changement de `nginx-public.conf`.
- À faire : copier les sauvegardes hors du VPS (le NAS) ; `chmod 700 sauvegardes`.

## ✅ La vérification avant chaque mise en production

> **Un déploiement ne livre que les fichiers écrits AVANT lui.** Après chaque export, vérifier que
> le `.wasm` et son `.gz` ont bien le même horodatage :
```bash
ls -la web/index.wasm web/index.wasm.gz
```
> **Un `.gz` plus ancien que son `.wasm` = c'est l'ancienne version qui part sur le téléphone.**

## 🔐 Les secrets

- **Depuis le 29/09 : ceux du serveur des comptes**, dans `/opt/lapoussette/.env` sur le VPS (600), et nulle part ailleurs.
  La clé du jeu (`SERVER_KEY`) n'en est pas un : elle est dans le client.
- ⛔ **Aucun secret dans le dépôt** quand il y en aura. Aucun sur une machine qu'on rend.
- 📌 *Une réserve hors projet — gestionnaire de mots de passe ou dossier à part — pour ce qui n'est
  pas retéléchargeable : clé de signature Android, codes de secours 2FA du compte Play.*

## Les pièges de cette infra

> 🔴 **À remplir au fur et à mesure, et surtout APRÈS chaque incident.** Chaque ligne ici est une
> soirée qu'on ne repassera pas.

- **Le pare-feu du PC est en profil Public** — rien ne se sert depuis le PC sans droits admin.
  *Découvert le 20/09/2026, avant d'avoir perdu une session dessus.*
- **Les templates d'export Godot ne sont pas dans le `.exe`.** Ils vivent dans
  `%APPDATA%\Godot\export_templates\4.7.2.stable\`. Sans eux, **aucun export n'est possible** et
  le message d'erreur ne le dit pas clairement. *Installés le 20/09/2026 — seuls les gabarits web
  `nothreads`, les autres plateformes ne sont pas couvertes.*
- 🔴 **Godot 4 sur le web exige un CONTEXTE SÉCURISÉ, et ce test est inconditionnel.** Le moteur
  vérifie `window.isSecureContext` au démarrage : seuls `https://` et `localhost` le satisfont.
  Sur `http://<ip>`, il s'arrête sur *« Secure Context — check web server configuration »*.
  ⛔ **Désactiver les threads N'ÉVITE PAS ce test** — ce sont deux contrôles différents, et on a
  perdu un aller-retour à le croire. D'où le certificat auto-signé dans `certs/`, et le port
  **18443**. *Rencontré le 20/09/2026.*
- **`thread_support` est à `false`** dans `export_presets.cfg`, exprès : avec les threads, le
  navigateur exige **en plus** les en-têtes COOP/COEP et refuse de démarrer sans message lisible.
- **Le certificat de `certs/` n'est PAS un secret** — il est auto-signé, valable sur le réseau
  local, et se regénère en une commande. ⛔ *Il ne crée pas d'exception à la règle « aucun secret
  dans le dépôt » : le jour où il y aura de vraies clés, elles ne vivront pas là.*
- **`nginx.conf` et `nginx-common.inc`** : le `.inc` porte les réglages communs aux deux écoutes.
  ⛔ *L'extension n'est pas `.conf` exprès — nginx inclut automatiquement tous les `.conf` de
  `conf.d/`, on aurait un doublon silencieux.*
- **`nginx` fait REVALIDER chaque fichier** (`no-cache` + ETag, depuis le 25/09) : le navigateur
  garde le jeu mais redemande à chaque lancement, et reçoit « 304, inchangé » s'il n'a pas bougé —
  un réexport est vu tout de suite, sans retélécharger 29 Mo à chaque lancement. ⛔ *Pas de
  `no-store` : il interdisait de rien garder (le téléphone retéléchargeait tout, à chaque fois).*
  ⚠️ *Une modification de `nginx-common.inc` ne prend effet qu'au redémarrage du conteneur
  (`docker compose up -d --force-recreate`, ou « Redémarrer » dans Container Manager).*
- 🔴 **Une sauvegarde de positions physiques PÉRIME quand la géométrie bouge.** Le tas de la
  poussette est enregistré en coordonnées ; si les cotes du plateau changent, des pièces se
  rechargent **à l'intérieur du poussoir** → pénétration massive → forces infinies → NaN en
  cascade *(6,8 millions d'avertissements en 600 images)*. ⛔ **Le jeu ne plante pas : il devient
  fou en silence**, et sur le web les messages partent dans la console du navigateur, donc
  invisibles. Parade en place : `GEO_VERSION` dans `pusher_screen.gd` — **à incrémenter dès qu'une
  cote bouge** — plus un recalage de chaque pièce au chargement. *Rencontré le 20/09/2026.*
- **`--headless` ne rend RIEN.** « 600 images sans erreur » ne dit rien d'un écran : un fond peint
  par-dessus le plateau a passé ce contrôle sans broncher. ⛔ *Le seul banc valable reste le
  téléphone.*
- **Compter les avertissements, pas les lire.** Un `head -15` derrière un `grep` a masqué un flot
  de 10 000 messages en 2 images — il ressemblait à 12. Utiliser `grep -c`.
- 🔴 **Le plafond de corps physiques est MESURÉ, pas supposé** — Xiaomi 14T Pro, Chrome, WASM
  sans threads : **145 corps → 60 fps · 205 corps → 3 fps**. La falaise est vers 180.
  `MAX_CORPS = 115` dans `pusher_screen.gd`. ⛔ *Sans plafond, le joueur sème plus vite que la
  machine ne rend : le plateau accumule jusqu'à l'arrêt, et ça ressemble à un plantage alors que
  c'est une saturation.* *Mesuré le 20/09/2026.*
- **`queue_free()` est différé.** Un corps « libéré » reste **une image de plus** dans le monde
  physique. Regarnir un plateau juste après, c'est faire naître le nouveau tas à l'intérieur de
  l'ancien. ⛔ *`remove_child()` d'abord, `queue_free()` ensuite.*
- **Le Wi-Fi du téléphone et l'Ethernet du NAS doivent être sur le même réseau.** Un réseau
  « invité » qui isole les clients rend le port injoignable — et ça ressemble à une panne serveur.
- **Le NAS occupe déjà des ports « évidents ».** `8443` était pris — d'où `18443`. ⛔ *Avant de
  choisir un port sur ce NAS, le vérifier plutôt que le supposer :*
  ```bash
  sudo netstat -tulpn | grep LISTEN | sort -t: -k2 -n
  ```
- 🔴 **Godot importe les images SANS PERTE par défaut** : ~1,5 Mo par illustration dans le paquet
  web. Chaque image a donc son `.import` (`compress/mode=1` = WebP, `mipmaps/generate=true`) :
  **185 Ko**. ⛔ *Écrire le `.import` AVANT le premier import : Godot reprend ses réglages.*
  *Découvert le 23/09/2026, vérifié sur la taille des `.ctex`.*
- 🔴 **Une police ou un SVG nouveaux demandent DEUX passes de `--import`.** La première a importé
  les PNG et laissé les `.ttf` et les `.svg` sans `.import` ; la seconde les a pris. *Vu le
  23/09/2026 avec Castoro.* ⛔ *Vérifier que chaque nouveau fichier a son `.import` avant d'exporter.*
- 🔴 **`TextureRect` : le mode d'étirement AVANT la taille.** Sinon la taille de l'image fait
  plancher : une icône voulue à 70 px s'est affichée à 128 et a recouvert les chiffres du bandeau.
  *Corrigé dans `Style.icone`, le 23/09/2026.*
- **`--headless` ne compile pas les shaders.** Pour les valider, lancer la capture en fenêtre avec
  `--rendering-driver opengl3_angle` : **OpenGL ES 3.0, le langage de WebGL2**, donc du téléphone.
- **En `--script`, les autoloads ne sont pas des identifiants** : `GS` y est inconnu et tout script
  qui le cite refuse de compiler. D'où les tests **en scène** (`res://tests/*.tscn`).
- 🔴 **Un test qui passe avec zéro élément n'a rien prouvé.** Le premier test des cartes a affiché
  `OK` avec « 0 construite sur 0 ». Chaque test exige désormais **au moins un** élément.
- **Hors écran, le jeu tourne à des centaines d'images par seconde** : une capture qui attend
  « 100 images » part avant la fin d'une animation d'une seconde. **Attendre des secondes.**
- 🔴 **`Engine.time_scale = 0` ne gèle PAS la physique** : Godot fait ses pas avec un pas nul et
  divise par lui dans les contacts → **NaN en cascade** *(2,35 millions d'avertissements en 4 minutes
  au banc)*. Pour geler : `PhysicsServer2D.set_active(false)`. *Trouvé le 23/09/2026.*
- 🔴 **`AnimatableBody2D` avec `sync_to_physics` garde son ancienne place jusqu'au pas suivant** :
  relire `position` juste après l'avoir changée rend l'ancienne valeur. Le bloc tient donc sa
  position dans `face_y`. *Trouvé le 23/09/2026 : le tas se rechargeait décalé.*
- 🔴 **`Label` : le retour à la ligne AVANT la taille** — sinon sa largeur minimale est celle de
  tout le texte sur une ligne, et le texte déborde du panneau. `Style.libelle(..., retour = true)`.
  *Trouvé le 23/09/2026.*
- **Une capture du bloc se déclenche sur SA position, pas sur l'horloge** : en fenêtre, la physique
  prend du retard au démarrage. *(tests/capture_poussoir)*
- **Une `CanvasLayer` ne suit pas la visibilité de son parent** : la collection lui fait suivre la
  sienne (`_notification`).
- 🔴 **`Performance.TIME_PHYSICS_PROCESS` rend le PIRE de la dernière seconde RÉELLE**, pas le temps
  de l'image : en accéléré (`--fixed-fps`), il ne mesure rien — 0,00 ms puis 21 ms figés. Pour un
  banc, **chronométrer chaque image** (`Time.get_ticks_usec`). *Les chiffres « physique » du banc 2D
  sont donc des pires par seconde, pas des moyennes. Trouvé le 23/09/2026.*
- 🔴 **À l'échelle du jeu (1 unité = 100 px, une pièce de 0,8 unité), la gravité réelle rend tout
  flottant et glissant** : une vraie pièce tombe trente fois sa taille plus vite. Gravité ×5.
  *Ressenti par Maxim le 23/09 (« on dirait que les pièces glissent »).*
- 🔴 **Trop de frottement entre pièces, et le tas poussé se redresse** : des pièces debout, sur la
  tranche, et plus rien n'avance. Frottement 0,35 entre pièces, plateau poli 0,15.
- **Un bloc qui repart d'un coup fait glisser ce qu'il porte** : il va et vient comme une bielle.
- **Jolt (la physique 3D qui empile bien) est dans le gabarit web de Godot 4.7** — vérifié dans le
  `.wasm` (`JoltPhysicsServer3D`). Réglage : `physics/3d/physics_engine = "Jolt Physics"`.
- 🔴 **WebGL ne lisse pas une texture en flottants 32 bits** (`Image.FORMAT_RF`) : lue avec un filtre,
  elle vaut 0 — le blanc de l'évolution disparaissait d'un coup. **Des textures 8 bits** (`FORMAT_L8`).
  *Trouvé le 26/09/2026.*
- 🔴 **Une nouvelle `class_name` n'existe pas pour les tests tant que `--import` n'a pas tourné** — et le test
  n'échoue pas : son script ne compile pas, la scène ATTEND SANS FIN. *Le 27/09 : 10 minutes perdues sur
  `Aventure`.* ⛔ Après une nouvelle classe : `--headless --path ./proto_degagement --import` ; et lancer chaque
  test sous `timeout 400`.
- **Les effets (effets.gd) comptent en temps RÉEL, les captures attendent en temps du JEU** : hors écran à 25
  images/s, le temps du jeu va ~2× moins vite, et une constellation d'or est déjà effacée quand la photo part.
  Photographier un effet tôt après son départ. *Vu le 27/09 (la victoire parfaite).*
- **GDScript 4.7** : `trait` est un **mot réservé** (une fonction `trait()` ne compile pas) ; `round()`
  rend un `Variant` (écrire `roundf()` pour que `:=` sache le type) ; une variable ne peut pas porter le
  nom d'une autre **de la même fonction**. Chaque fois, le message vise le script qui DÉPEND du fautif
  (« Could not resolve class ») : vérifier le fautif seul avec `--check-only --script res://<fichier>.gd`.
  *Rencontrés le 26/09/2026.*
- **Un objet de la machine a un corps de la forme de son dessin** : amincis à 0,18, les objets larges
  passaient sous le sol ; des billes posées sur les disques d'avant se dessinaient l'une dans l'autre.
  *Le 26/09 : épaisseur physique 0,28 pour les pierres, un corps à la taille de la bille (qui ne penche
  pas) pour les billes ; `sim_poussoir` vérifie les chevauchements.*
- **Plafonner les pas de physique (`max_physics_steps_per_frame = 1`) ralentit AUSSI le temps du jeu**
  quand l'image rame : les minuteurs du jeu suivent. Une capture qui attend en temps réel tombe à côté ;
  attendre en temps du jeu. *Vu le 26/09/2026 (tests/capture_gestes).*
  🔴 **Depuis le 27/09, ce plafond ne vaut QUE dans la Nébuleuse** (`main.gd` § `_regler_temps` : 1 pas là, 8 ailleurs).
  Au combat, il ralentissait les retournements dès qu'une image ramait (Maxim : *« des fois vite, des fois lent, ça
  casse la dynamique »*) ; ailleurs, la machine est en pause, aucune physique ne tourne.
