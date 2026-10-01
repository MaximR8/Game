# `La Poussette` — Changelog & checklist de déploiement

> **But** : ne RIEN oublier au déploiement. Chaque version liste : ce qui change, les **actions
> manuelles**, et les **tests**. Statut : `🔜 EN ATTENTE` → `✅ EN PROD`.
>
> ⚠️ **CE FICHIER MENT QUAND ON OUBLIE DE LE METTRE À JOUR.**
> **La source de vérité est** `curl -sk -o /dev/null -w "%{http_code}\n" https://192.168.0.17:18443/index.html`
> **+ la date du `.pck`.** Vérifier là AVANT de conclure quoi que ce soit d'ici.
>
> 📌 *« En prod » ici veut dire : servi par le NAS — sur le téléphone de Maxim (réseau local) et, depuis le 27/09, chez
> les cousins (le site public, derrière un code : un seul export sert les deux). Ni magasin, ni backend.*

---

## ✅ **Les codes cadeaux marchent dans l'app (la table sur le serveur) ; le compte retente hors ligne** — **EN PROD** *(01/10/2026, 13 h 26 ; l'APK 0.3)*

**En clair.** Dans l'app Android, un code cadeau répondait « pas de connexion » : le jeu cherchait la liste des codes sur le
site à côté de lui (le NAS), et l'app n'a pas de site. La liste vit maintenant aussi sur le serveur du VPS : l'app et le web
la lisent là (le fichier du NAS reste le secours du web). Et le compte, hors ligne au lancement (pas de réseau, une page
ouverte avant un changement du portier), retente tout seul toutes les minutes.

🔴 **POURQUOI** — Maxim, 01/10 : *« j'ai mis le code HalaMadrid, il me dit que je suis pas en ligne ; mon cousin, toujours dans le
web, a voulu mettre le mot de passe, ça lui dit qu'il est hors ligne aussi »*. Le cousin : le portier avait bien la nouvelle
règle (vérifié) — sa page avait été ouverte AVANT le redémarrage (une app web d'iPhone reste ouverte des jours) : la fermer
pour de bon et la rouvrir.

· `codes_cadeaux/codes.py` : `publier_serveur` — un compte « administrateur des codes » (son identifiant d'appareil SECRET
  dans `registre.json`, privé) pose l'objet `config/codes` (permission de lecture 2 : tout joueur connecté) ; nouvelle
  commande `publier`. `codes.gd` : `ADMIN` (595ada12-…), `lire_table` lit le serveur d'abord. `compte.gd` : `lire_public`,
  `_reessayer` (toutes les `RECONNEXION_S`).

**Tests faits** : `test_compte` (16 : + la table lue sur le serveur, sans code en clair ; « Hala Madrid » y vaut 100 étoiles) ;
`test_codes` : OK. Déployé : `index.pck` servi à 13 h 26 ; l'APK 0.3 (versionCode 3).

---

## ✅ **La Supernova ; le cœur d'étoile ; les coûts relevés** — **EN PROD** *(30/09/2026, 23 h 57 ; l'APK Android 0.2 à 23 h 59)*

**En clair.** Les pièces tombées dans les fentes remplissent une **jauge** : la frise de lunes sous « La Poussette »
s'allume, une lune après l'autre. Neuf lunes : la **SUPERNOVA** — un flash, le mot en énorme, en lettres d'or, qu'un éclat
de lumière traverse, une gerbe d'étoiles nettes ; puis 30 s où la machine s'emballe : le poussoir deux fois plus vite, une
pluie de 36 pièces offertes sur le bloc, tout ce qui tombe devant compte double (« ×2 ») ; le mot se range en haut et compte
les secondes. À la fin, un **cœur d'étoile** (une bille d'or et d'ambre, un soleil au centre) tombe au milieu du plateau :
poussé jusqu'au bord, il est gagné. Trois cœurs allumeront une Nouvelle machine (la suite ; le « + » du plateau du jour
le dit). Et **les coûts relevés** : les cartes en éclats ×2,5 (héros 500, légende 2 200), un niveau 250 × le niveau,
évoluer 3 pierres (stade II) puis 10 (stade III).

🔴 **POURQUOI** — DECISIONS 30/09 (l'économie ; Maxim : *« Supernova c'est top, on affiche le mot en gros dans l'animation avec
des effets de lumière dessus »* ; *« augmenter les coûts… les pierres de manière drastique »*).

· `pusher_screen.gd` § la Supernova : `JAUGE_SUPERNOVA` 150 (au banc : une toutes les ~10 min de jeu soutenu), `_nourrir_jauge`
  (les fentes), `declencher_supernova`, `_tic_supernova` (la pluie, le temps), `_fin_supernova` (le cœur), `_dessiner_jauge`
  (la frise), le « ×2 » dans `_sur_gain` ; le cœur est un objet de la machine, pas du plateau du jour (`LOTS`).
  `supernova_fx.gd` : l'animation (le reflet ne passe que sur les lettres : `clip_children`). `Son.supernova`. `GS` :
  `jauge_supernova`, `coeurs` (sauvegardés, et donc aussi sur le serveur). L'objet : `design/objets/render_objets.py`
  (`"coeur"` dans les billes ; ⚠️ relancer tout `--univers` réécrit les pierres autrement : on n'a ajouté QUE le cœur).
· Les outils de test : un bouton « Supernova » (la voir tout de suite).
· Les coûts : `GS.PRIX_RANG`, `POUSSIERE_PAR_NIVEAU`, `PIERRES_EVOLUTION` ; tests mis à jour.

**Tests faits** : `test_supernova` (12 : la jauge et la frise, le déclenchement, le poussoir ×2, le son, la pluie, le ×2, le cœur
à la fin, compté, sauvegardé, hors du plateau du jour) ; `capture_supernova` (vu : le mot qui jaillit, le reflet, le mot rangé,
la pluie) ; `sim_poussoir` (2 × 10 min : une Supernova, un cœur ; le rendement sur la partie, 72-74 %) ; `test_collection`,
`test_objets` (les nouveaux coûts), `test_son`, `test_journee`, `test_codes`, `capture_collection`, `capture_accueil`,
`capture_journee`, `capture_menu` : OK. Déployé : `index.pck` servi à 23 h 57, healthcheck `200` ; l'APK 0.2 (versionCode 2 :
s'installe par-dessus la 0.1).

**Pas testé** : sur le téléphone.

### ✅ À tester
- [ ] Outils (appui long sur l'onglet Nébuleuse) → « Supernova » : le mot, la lumière, la pluie, le ×2, le cœur à la fin
- [ ] En jouant : la frise de lunes se remplit avec les pièces des fentes

---

## 🧪 **La première app Android (APK d'essai) : be.poizot.poussette 0.1** — *fabriquée le 30/09/2026, pas publiée*

**En clair.** Le jeu existe maintenant en **vraie app Android** (70 Mo), fabriquée sur le PC de Maxim, signée avec la clé du
jeu, à installer directement sur un téléphone Android (hors store). Elle parle au même serveur : un joueur qui a lié son
compte y retrouve sa partie (« J'ai déjà un compte »). Le web ne change pas.

🔴 **POURQUOI** — Maxim, 30/09 : *« l'idée c'est d'avoir une app et mon VPS, basta »* ; Codemagic reste à Vesta (et à
l'iPhone plus tard, sur un compte à part) : Android se fabrique sans lui (INFRA § l'app Android).

· Java 17 portable (`outils-jeu`), la clé `cles-la-poussette/` (hors du dépôt), le réglage d'export « Android », le portrait,
  les textures ETC2/ASTC. Vérifié : signature v2/v3 par la clé du jeu (`apksigner`) ; paquet, cible SDK 36, permissions
  (`aapt2`) ; le `.pck` web inchangé (à 128 octets près : les réglages).

**Pas testé** : sur un téléphone Android (la fluidité de la Nébuleuse hors du navigateur — D13 —, le son, le clavier du
panneau Compte).

---

## ✅ **Lier son compte par mail : retrouver sa partie sur un autre téléphone ; le code HALAMADRID** — **EN PROD** *(29/09/2026, 23 h 41)*

**En clair.** Dans le Menu → Compte : **« Lier mon compte »** (un mail, un mot de passe de 8 caractères ou plus) sur le
téléphone qui a la partie ; **« J'ai déjà un compte »** sur un autre : le jeu montre ce que contient la partie du compte
(étoiles, poussières, cartes) et ce qu'elle remplace, puis **« Reprendre ma partie »** — le téléphone rejoint le compte (aux
lancements suivants, il le retrouve tout seul) ; sa machine à pièces reste la sienne. Une fois lié : « Compte lié à
m•••@… ». Chaque refus a sa phrase (mail pris, mot de passe trop court, faux, mail inconnu, pas de réseau). Et un code
cadeau : **HALAMADRID** (« Hala Madrid », les espaces ne comptent pas) → **100 étoiles**, une fois par partie, sans fin.

🔴 **POURQUOI** — Maxim, 29/09 : *« Go next, mets-moi aussi un petit code cadeau "Hala Madrid" qui donne 100 tickets »* ; la suite de ⑥.

· `compte.gd` : `lier_mail`, `retrouver` (le compte d'un mail et sa partie, sans toucher à celui du téléphone), `adopter`
  (l'ancien compte de l'appareil effacé, un nouvel identifiant d'appareil lié au compte retrouvé), `_raison`, `masquer`.
  🔴 **Pas de « mot de passe oublié »** : Nakama n'envoie pas de mail (il viendra avec Google, ou un service d'envoi).
· `presages_ecran.gd` : `_ouvrir_compte`, `_ouvrir_lier`, `_ouvrir_retrouver`, `_confirmer_reprise` ; `_saisie` / `_champ_html`
  (deux VRAIS champs de la page sur le web — mail, mot de passe — comme le code cadeau) ; ils partent avec le panneau.

**Tests faits** : `test_compte` (14, contre le vrai serveur : lier, les refus — trop court, pris, faux, inconnu —, la partie
retrouvée sur un « autre téléphone », qui rejoint le compte et le retrouve seul au lancement suivant ; les comptes d'essai
effacés) ; `capture_menu` (le Compte, Lier, Retrouver, la confirmation : vus) ; `test_son`, `test_journee`, `test_codes` : OK.
Déployé : `index.pck` servi à 23 h 41, healthcheck `200`.

**Pas testé** : sur le téléphone (les deux champs du clavier, la reprise entre deux téléphones).

### ✅ À tester
- [ ] Téléphone A : Compte → Lier mon compte (ton mail, un mot de passe) → « Compte lié »
- [ ] Téléphone B (ou un autre navigateur) : Compte → J'ai déjà un compte → la partie de A, « Reprendre ma partie »
- [ ] Code cadeau : Hala Madrid → 100 étoiles

---

## ✅ **La partie est sauvegardée en ligne (le compte de l'appareil) ; le Compte s'ouvre dans le Menu** — **EN PROD** *(29/09/2026, 23 h 31 ; chez les cousins : après le redémarrage du portier)*

**En clair.** Chaque téléphone a maintenant son compte sur le serveur du jeu, créé sans rien demander. La partie reste
écrite sur le téléphone comme avant, et part AUSSI au serveur, en arrière-plan (au plus une fois par minute, et tout de suite
quand l'app passe en arrière-plan). Le jeu n'attend jamais le serveur : sans réseau, il réessaie plus tard. Dans le Menu, le
médaillon **Compte** s'ouvre : « Ta partie est sauvegardée en ligne · dernière sauvegarde il y a 2 min · joueur n° … », et
« Lier mon compte » (mail, Google) annoncé — la suite.

🔴 **POURQUOI** — ⑥ (FEATURES ligne 6) : Maxim, 29/09 : *« lier le compte à Google, Apple, mail, Facebook, Discord »*, *« le jeu
encapsulé dans l'app, seules les données dans une DB »*. Le serveur est en place (INFRA § le serveur des comptes).

· `compte.gd` (`Compte`, créé par `main.gd` comme le son) : l'identifiant d'appareil tiré au hasard une fois
  (`user://compte.cfg`, comme les Réglages : il suit l'appareil) ; `connecter` (Nakama : `authenticate/device`), `envoyer`
  (`PUT /v2/storage`, collection `partie`, la sauvegarde + `maj`), `lire`, `effacer` ; `GS.save_game` le prévient. Les
  tests (sauvegarde coupée) ne touchent ni au réseau ni au fichier.
· Le Menu (`presages_ecran.gd` § `_ouvrir_compte`) : le Compte n'est plus scellé ; les Amis le restent.
· Le portier : `connect-src` ouvre `https://` et `wss://lapoussette.duckdns.org` (`portier/nginx-public.conf`).

**Actions manuelles** : 🔴 **redémarrer le conteneur `jeu-public`** (Container Manager → `jeu-public` → Redémarrer) : sans ça, le
site public (les cousins) bloque les appels au serveur — le jeu marche quand même, sa partie reste sur le téléphone.

**Tests faits** : `test_compte` (CONTRE LE VRAI SERVEUR : un appareil neuf, la partie envoyée et relue, le même compte retrouvé,
une version qui remplace l'autre, le compte effacé — stable 2 fois, ~0,5 s par réponse) ; `test_son`, `test_journee`,
`test_objets`, `test_codes`, `capture_menu` (le panneau Compte), `test_portier` (30) : OK. **Dans Chrome** (le site local) :
le jeu crée son compte, lit, envoie sa partie — tout à 200, le CORS passe ; la partie relue sur le serveur ; le compte
d'essai effacé. Déployé : `index.pck` servi à 23 h 31, healthcheck `200`.

**Pas testé** : sur le téléphone ; le site public (après le redémarrage du portier).

---

## ✅ **Toute pièce tombée devant est gagnée ; les fentes avalent vraiment, sur les côtés** — **EN PROD** *(29/09/2026, 22 h 40)*

**En clair.** Un bug : ~1 pièce sur 4 qui tombait DEVANT n'était pas comptée (poussée lentement, elle basculait presque à la
verticale et passait sous le plateau avant d'avoir « entièrement franchi la ligne ») — d'où « 4-5 pièces tombent et le jeu en
donne 1 ou 2 ». Maintenant, tout ce qui bascule par-dessus le bord est gagné. Et les fentes n'avalaient rien (0,4 de large,
moins qu'une demi-pièce : collée au mur, une pièce gardait son centre sur le plancher) : elles font maintenant 0,7, et
s'arrêtent AVANT le bord (un coin plein devant) — une pièce perdue tombe sur le côté, au milieu du plateau, jamais là où l'on
gagne.

🔴 **POURQUOI** — Maxim, 29/09 : *« j'ai pas l'impression que des pièces tombent sur les côtés, des fois on a 4-5 pièces qui
tombent et le jeu en donne que 1 ou 2 ; mieux pour être sûr qu'il faut racheter des pièces, mais ça peut énerver les
utilisateurs »*. Mesuré (`sim_poussoir`, compteur `ratees_au_bord`) : 83 à 89 pièces tombées devant sans être comptées pour ~230
gagnées ; 0 à 1 % dans les fentes. ⚠️ **Le « 27 % perdu dans les fentes » d'avant était faux** : c'étaient ces pièces-là.

· `pusher_screen.gd` : la règle du bord (`bp.z > BORD and bp.y < 0.0` gagne aussi) ; `fente` 0,7, `fente_z0` 10,8, `fente_z1`
  13,3 (static : `sim_poussoir fente=…` les essaie), le plancher en trois morceaux, la fente dessinée fermée des deux bouts.
· Au banc (2 graines × 2 jours) : 0,6 → 20 % dans les fentes, le lendemain 29 à 45 pièces nettes ; **0,7 → 28 à 30 %, le
  lendemain 69 à 83** ; 0,8 → 31 à 32 %, 73 à 77. Les défis restent à 35 (~155 pièces par jour).

**Tests faits** : `sim_poussoir` (0 pièce tombée devant sans être comptée ; 26 % dans les fentes), `test_son`, `test_journee`,
`test_objets`, `capture_journee` : OK. Déployé : `index.pck` servi à 22 h 40 (43 804 212 octets), healthcheck `200`.

---

## ✅ **Le poussoir se tait ; les pièces s'entrechoquent en vraies pièces ; l'objet gagné refait (OB2)** — **EN PROD** *(29/09/2026, 20 h 26 ; l'objet à 22 h 16)*

✅ **22 h 16 — Maxim : « OB2 »** : le son de l'objet refait — le même arpège une octave plus bas (523 Hz), rien au-dessus de
2,5 kHz, attaque de 15 ms, à −9 dB (2 % de son énergie entre 2 et 6 kHz, contre 43 % ; centre 810 Hz au lieu de 1 790) ; la lune
monte d'une quarte (+5, −2 dB) et non plus d'une quinte. `preparer_jeu.py` (`pieces.adoucir`), `son.gd` § `objet`. `test_son` : OK.
Déployé : `index.pck` servi à 22 h 16 (43 803 924 octets), healthcheck `200`.

**En clair.** Le bloc du haut ne fait plus aucun bruit en bougeant (c'étaient des grains de jetons à chaque poussée). Quand
une pièce tombe sur le tas (du bloc, d'une pile), elle tinte en arrivant : de vraies pièces sur des pièces (quatre prises
CC0), ~80 par minute en jouant, discrètes. Le son d'un objet gagné est baissé de 9 dB en attendant son nouveau son (page
d'écoute, 9ᵉ tour : OB1 à OB3).

🔴 **POURQUOI** — Maxim, 29/09 : *« quand le plateau du haut se rétracte, il y a un son de jeton […] quand les pièces
s'entrechoquent, c'est aussi un son de jeton, ça doit être des pièces pour l'entrechoc, et le plateau qui se rétracte, pas de
bruit »* ; *« le son quand on gagne des objets, je suis pas fan, il fait mal aux oreilles »* — mesuré : le carillon sortait 9 à
11 dB au-dessus de toutes les pièces, son énergie entre 1 et 6 kHz.

· `son.gd` : `entrechoc()` (au plus un toutes les 80 ms), `NIVEAUX` (`entrechoc` −13, `objet` 0 → −9) ; le froissement n'est
  plus joué. `pusher_screen.gd` : toutes les 3 images, près de la face du bloc, une pièce qui tombait (vitesse < −2) et qui
  arrive sonne ; une pièce lâchée par le joueur a déjà son son (`lachee`). `design/sons/pieces.py` : `ENTRECHOC`,
  `main_objets` (la page OB).

**Tests faits** : `test_son` (31 : le poussoir se tait ; une pièce qui tombe sur le tas s'entrechoque ; deux dans la même image,
un seul — stable 2 fois) ; `sim_poussoir` (80 entrechocs par minute, script de physique 0,07 ms) ; `test_journee`,
`test_objets`, `capture_journee` : OK. Déployé : `index.pck` servi à 20 h 26 (43 812 036 octets), healthcheck `200`.

---

## ✅ **La Nébuleuse refaite pour les gros paquets : tout le plateau posé, les amas, les fentes, les vraies pièces** — **EN PROD** *(29/09/2026, 19 h 54)*

**En clair.** Les 12 objets du jour sont **tous sur le plateau** dès le matin : le ticket d'invocation au fond, la moitié des
pierres n'importe où (une surprise, parfois près du bord), les autres pierres derrière, les poussières devant. **Chaque objet
est posé sur un petit tas de pièces** : quand il tombe, le tas tombe avec lui, et ça fait un **gros bruit de pièces**. Les
pièces sont de **vraies pièces enregistrées** (celle qu'on lâche : PA8 ; celles qui tombent dans le bac : PA7) ; quand elles
se suivent, un **paquet** sonne (le petit à la 3ᵉ pièce, le gros à la 7ᵉ ou quand un objet tombe). Pour que le plateau ne se
vide pas en deux minutes : **deux fentes** sur les côtés, à l'avant, où des pièces se perdent (comme les vraies machines) ; le
**bloc du haut** ne garde que 5 pièces ; les défis donnent un peu moins de pièces (35 au lieu de 60, la semaine 120 au lieu
de 200). L'idée : que les joueurs aient envie d'acheter des pièces pour jouer plus.

🔴 **POURQUOI** — Maxim, 29/09 : *« pas fan du bruit des pièces qui tombent, ça fait jeton, nous on veut un bruit de pièce, comme
dans les vrais coin pushers »* ; *« PA8 c'est bon ; le PC on n'est pas satisfait, je pense que PA7 représente le mieux les pièces
qui tombent en bas de la machine ; la satisfaction c'est quand un gros paquet tombe d'un coup […] peut-être c'est mieux de
mettre toutes les récompenses dispo directement sur le plateau, pas 3 qu'on fait réapparaître ; quand un objet tombe, il
tombe avec un petit amas de pièces […] c'est la sensation addictive qu'on cherche »* ; *« les plus gros objets au fond, il faut
rendre le plateau moins facile »* ; *« 1 ticket d'invocation, la moitié des pierres aléatoirement sur le plateau et le reste en
ordre XP »* ; *« on peut pas faire un mix des solutions ? l'idée c'est que les gens achètent des pièces »* ; *« sur la poussette
en haut, ne laisse que 4-5 pièces »*. (DECISIONS 29/09.)

· **Le plateau** (`plateau.gd`) : `a_poser()` (ce qu'il reste et où), `pierres_au_hasard(jour)` (écrit par la date), les pierres
  gagnées retenues **par leur nom** (elles ne tombent plus dans l'ordre). **La machine** (`pusher_screen.gd`) :
  `_completer_plateau` pose tout, `_poser_avec_amas` (une place loin des autres, 5 pièces en couronne, l'objet dessus ; les
  pièces PRISES sur le bloc du haut puis le plateau, créées seulement sur une machine neuve) ; plus aucun objet ne revient ;
  `FENTE`, `FENTE_Z` (le plancher plus étroit à l'avant, les fentes dessinées, `perdues`) ; `SUR_BLOC` ; `GEO_VERSION` 12.
· **Les sons** : `design/sons/pieces.py` (115 prises CC0 de Freesound, la meilleure chute de chacune ; `paquet(n, durée)` : de
  vraies chutes empilées et le choc du tas) ; `son.gd` : `MONTEE` (la cascade discrète : +3,5 demi-tons au plus — une vraie
  pièce montée d'une octave sonnait comme un jouet), `PAQUET_S`, `objet_tombe`, 24 voix (des pièces qui tintent ~1 s).
· Les outils : `sim_poussoir` (`graine=`, `plateau=`, `deux_jours` ; les paquets ; les fentes), `mesure_pieces.py`,
  `tests/film_nebuleuse.tscn` (le film, avec le son).

**Actions manuelles** : aucune. (Le tas de chaque joueur repart à neuf une fois : GEO_VERSION.)

**Tests faits** : `sim_poussoir` (3 graines × 2 jours : 68 à 138 pièces nettes le lendemain ; 26 à 29 % dans les fentes ; rien
hors jeu, aucun objet qui en chevauche un autre ; rechargé à l'identique) ; `test_son` (la cascade discrète, les paquets),
`test_journee` (237 : ce qu'on pose et où, une pierre gagnée hors de l'ordre), `capture_journee` (12 sur le tas), `test_objets`,
`test_codes`, `capture_poussoir`, `capture_accueil` : OK ; `banc_perf` : ~6 ms par image à 214 pièces (les 9 objets de plus ne
pèsent pas : ce sont les pièces qui coûtent, et leur nombre au plus fort n'a pas monté) ; **le film** (`film_nebuleuse`, 85 s,
un joueur très rapide) : les 12 objets gagnés, 15 petits paquets et 5 gros, 77 pièces dans les fentes — publié sur la page
d'écoute. Déployé : `index.pck` servi à 19 h 54 (43 793 892 octets), healthcheck `200`.

**Pas testé** : sur le téléphone (les images par seconde de la Nébuleuse, D13 ; la sensation des paquets au haut-parleur).

### ✅ À tester
- [ ] Le matin : les 12 objets sur le plateau, chacun sur son petit tas ; le bloc du haut presque vide
- [ ] Un objet qui tombe : le gros bruit de pièces ; des pièces qui se suivent : le paquet
- [ ] Les fentes : des pièces s'y perdent sur les côtés ; un objet qui y tomberait revient sur le tas
- [ ] La journée : vider le plateau prend-il la plupart des pièces du jour ? (la mesure du 12/10)

---

## ✅ **Deux musiques calmes : Starfield Romance à la Nébuleuse, First Light Particles ailleurs ; le cadeau du jour lisible** — **EN PROD** *(29/09/2026, 18 h 05)*

**En clair.** Retour au calme. La Nébuleuse joue **Starfield Romance** (la première musique) ; l'Astrolabe, l'Atlas, le Voyage et le
Menu jouent **First Light Particles** (du même auteur, Yoiyami, un peu plus rythmée) ; le combat garde la sienne. En changeant
d'écran, la musique passe par un fondu, et **chacune reprend où elle en était** (la musique du combat, du début). Et la phrase
du cadeau du jour ne déborde plus de son panneau (elle passe sur deux lignes).

🔴 **POURQUOI** — un joueur, via Maxim : *« je m'attendais à quelque chose de plus doux et cosmique »* ; les neuf cosmiques
(page d'écoute, 5ᵉ tour) : *« trop film d'horreur, on va repartir sur du plus calme comme la première, qui détend »* ; au 6ᵉ tour
(les neuf plus proches de Starfield Romance, mesurées parmi 59 pistes CC0) : *« j'adore la CA8 et la CA0 […] une plus calme,
l'autre plus rythmée […] 2 situations ? »* → *« CA0 pour la Nébuleuse et l'autre pour le reste »*.

· `son.gd` : `Son.musique_de(écran)`, `changer_musique` qui garde la place de chaque musique (`_positions`, calculée au temps
  écoulé — pas au lecteur, qui sur le web est un échantillon du navigateur) ; un fondu coupé en route (des onglets touchés vite)
  remet le bus à son volume. `main.gd` § `_aller_vers` change la musique à chaque écran.
· Les fichiers : `musique-nebuleuse.ogg` (F5), `musique.ogg` (CA8 : `preparer_jeu.MUSIQUE_ECRANS`), tous deux dans la salle.
· Pour choisir une musique sans l'entendre : `design/sons/mesure_musiques.py` (l'allure, la dureté, la clarté du ton, le souffle,
  le grave ; la distance à un modèle). Les cosmiques rejetées avaient du souffle (platitude 0,14 à 0,34 contre 0,06), des nappes
  graves, des tons mineurs. Sources : `design/sons/sources/calme/` et `cosmique/` (CC0, LICENCES.md).

**Actions manuelles** : aucune.

**Tests faits** : `test_son` étendu (29 vérifications : la Nébuleuse a sa musique ; l'Atlas l'autre ; la place de la Nébuleuse
gardée, 11,7 s ; au retour, elle reprend là) ; `capture_accueil` (le cadeau du jour sur deux lignes, vu), `capture_menu`,
`capture_collection` : OK ; les boucles au raccord : pas de clic ; **dans Chrome** : l'Astrolabe lance First Light Particles (129 s),
le lecteur du navigateur reçoit la position de départ. Déployé : `index.pck` servi à 18 h 05 (43 702 044 octets), healthcheck `200`.

**Pas testé** : sur le téléphone ; dans Chrome, le retour à la Nébuleuse à mi-musique (l'accueil du premier lancement retient sur
l'Astrolabe — vérifié par `test_son`).

### ✅ À tester
- [ ] La Nébuleuse : Starfield Romance ; un autre onglet : First Light Particles ; revenir : elle reprend où elle en était

---

## ✅ **Le son a un espace : la stéréo, une salle commune, le grave refait pour le haut-parleur** — **EN PROD** *(29/09/2026, 13 h 14)*

**En clair.** Le son n'est plus plat : tout le jeu sonne dans **la même salle** (une réverbération courte, 0,9 s : une pièce
qui tombe sonne 0,4 s au lieu de 0,13), en **stéréo**, les bruitages devant et la musique un peu derrière. Le grave de la
musique, que le haut-parleur du téléphone ne jouait pas, est remplacé par ses harmoniques : on l'entend.

🔴 **POURQUOI** — Maxim, 29/09 : *« j'ai l'impression que les musiques sonnent collé-collé, mais qu'elles ne sont pas dans l'App,
je sais pas expliquer si c'est un souci de réverbe, de basse »* ; à nos questions : au **haut-parleur du téléphone**, *« plate,
sans espace »*, les deux musiques, et les bruitages aussi. Mesuré : tout était **mono** (Moonlit Rabbits l'est à la source ; la
musique du combat, stéréo, était aplatie par `preparer_jeu`), **sec** (aucune réverbération), et Moonlit Rabbits mettait 47 % de
son énergie sous 120 Hz. Quatre versions d'une même scène de 38 s sur la page d'écoute (ES1 aujourd'hui → ES4 le ciel
ouvert), à volume égal : Maxim a gardé **« ES2 », la salle**.

· **`design/sons/espace.py`** : la réponse de salle (synthétisée, stéréo décorrélée, rien sous 250 Hz), l'élargisseur d'une
  source mono (qui s'annule en mono : un haut-parleur unique rend le son entier), le haut-parleur (coupé sous 70 Hz,
  harmoniques du grave, +2,5 dB au-dessus de 3 kHz) ; `CHOISI = "ES2"`. **Cuit dans les fichiers** (le web de Godot joue des
  échantillons : aucun effet de bus n'y passe) : `preparer_jeu.ecrire` passe chaque bruitage dans l'espace, `invocation.py`
  aussi, les musiques par `espace.musique_boucle` (la queue de la fin retombe sur le début : la boucle reste sans raccord).
· Les bruitages **secs** sont gardés dans `design/sons/secs/` (la scène d'écoute part d'eux ; les fichiers du jeu ont déjà
  leur espace — le remettre le doublerait).
· **Tous les sons du jeu sont stéréo** : `proto_degagement/sons/` passe de 4,1 à 7,5 Mo ; `index.pck` 40,8 → 44,4 Mo.

**Actions manuelles** : aucune.

**Tests faits** : `test_son` (26 vérifications) ; `capture_astrolabe`, `capture_menu` : OK ; les boucles mesurées au raccord
(le saut y est plus petit qu'un pas ordinaire : pas de clic) ; en mono, −0,6 dB (la musique) et −0,9 dB (le combat) : rien ne
se creuse ; **dans Chrome** (`son.js`) : les bruitages partent avec leur queue (la pièce : 0,93 s), la musique tourne, le
témoin à −22 dB. Déployé : `index.pck` servi à 13 h 14 (44 427 668 octets), healthcheck `200`.

**Pas testé** : sur le téléphone.

### ✅ À tester
- [ ] Au haut-parleur : le son a-t-il de l'espace, la musique est-elle « dans l'app » ? La basse de Moonlit Rabbits s'entend-elle ?
- [ ] Une rafale de pièces dans la Nébuleuse : la salle ne brouille pas (sinon, ES2 → réverbération plus courte)

---

## ✅ **L'invocation a sa bande-son, calée sur l'animation ; une musique plus vive ; la musique à 50 %** — **EN PROD** *(29/09/2026, 12 h 14 ; les choix de Maxim à 12 h 26)*

**En clair.** L'invocation ne joue plus trois sons posés dessus : elle suit le rituel. Un souffle monte pendant que l'astrolabe
tourne, chaque étoile qui s'allume sonne une note plus haute que la précédente, l'astrolabe se verrouille d'un coup, les étoiles
sont aspirées, la carte apparaît dans une tension, et **la révélation éclate au moment où la carte se retourne**. En ×10, chaque
dos qui arrive monte d'une note, chaque carte retournée a son coup (plus riche avec la rareté). **Le petit clap de la fin est
supprimé.** La musique générale devient **Moonlit Rabbits** (plus rythmée), et la musique part à **50 %** par défaut.

🔴 **POURQUOI** — Maxim, 29/09 : *« Je suis pas fan de la musique général, elle est trop lente/douce. Le son d'animation d'une
invocation aussi, ça doit être spectaculaire, ça doit marcher avec l'animation, le petit clap à la fin est horrible »* ; puis,
sur la page d'écoute (deux films de l'invocation, treize musiques) : *« Sons : IV1 · MG9 — Met le son général à 50 par défaut »*.

· **La bande-son** : synthétisée (`design/sons/invocation.py`, aucune licence), ambiance **céleste** (cloches, verre, souffle clair
  — IV1) ; la cosmique (IV2) n'est plus embarquée (`--toutes` la refait, pour un film). Le jeu la joue en **partition** :
  `Son.partition` (un minuteur par son, annulé si on passe), écrite à partir des instants du rituel (`collection_screen`
  § `_partition_simple`, `_partition_multi`) ; le souffle s'étire à la durée du rituel ; les étoiles montent en gamme
  (`Son.notes_etoiles`). Les sons K1 (verrou) et L1 (le clap) sont sortis.
· **La musique générale** : `preparer_jeu.py` `CHOIX["F"] = "F9"` (la même source que MG9), bouclée sur 5 min 19. **Le volume
  par défaut** : `Reglages.musique = 0.5` (un téléphone qui a déjà bougé son curseur garde le sien).
· **Le film de l'invocation** : `tests/film_invocation.tscn -- celeste` (Godot enregistre image et son ; INFRA § les sons).

**Actions manuelles** : aucune.

**Tests faits** : `test_son` (26 vérifications, dont les sons de la bande-son) ; `capture_astrolabe`, `capture_collection`,
`capture_accueil` : OK ; les deux films vérifiés image par image (le verrou tombe sur le verrouillage, la révélation sur le
retournement ; aucun écrêtage : pic −0,7 dB) ; **le son mesuré dans Chrome** : la nouvelle musique (319 s) part, bus à 0,5, sortie
entre −20 et −31 dB. Déployé : `index.pck` servi à 12 h 26 (40 821 284 octets), healthcheck `200`.

**Pas testé** : sur le téléphone.

### ✅ À tester
- [ ] Une invocation simple : le souffle, les étoiles qui montent, le coup du verrou, la révélation au retournement — plus de clap
- [ ] Une ×10 : les dos qui arrivent en montant, chaque carte retournée ; passer (toucher) coupe la partition proprement
- [ ] La musique générale : Moonlit Rabbits, à mi-volume dans les Réglages

---

## ✅ **Le son dans tout le jeu : l'interface, l'invocation, le combat (et sa musique), la collection** — **EN PROD** *(29/09/2026, 10 h 25 ; les sons de Maxim à 10 h 44)*

**En clair.** Chaque bouton a son petit clic, chaque onglet son tic, un bouton éteint un choc sourd. L'invocation sonne : le
portail s'ouvre, l'astrolabe se verrouille d'un clic, la carte se retourne — et une carte rare carillonne, plus riche de l'Or
au Full art ; une Légende ou un Mythe a son accord. Le combat a **sa propre musique**, et ses sons : la carte posée, le choc
des deux chiffres, la carte retournée (**en cascade** : dans une chaîne, chaque retournement monte d'une note), le pouvoir, l'esquive
et le rempart, la victoire, la défaite, la victoire parfaite. Et la collection : monter de niveau, l'évolution (la pierre qui
éclate, le blanc, l'éclosion), obtenir une carte, recevoir un défi, un coffre, un code.

🔴 **POURQUOI** — Maxim, 29/09 : *« faudrait mettre du son dans tout le jeu maintenant, faire un truc aussi pour les invocations,
quand on chope une belle carte, une rareté haute, des petits sons aux boutons, musique différente en combat et des sons pour le
combat, quand les pouvoirs sont activés, carte retournée »*.

· **Choisis par Maxim à l'écoute, 10 h 44** : *« G4 · H3 · I1 · J3 · K1 · L1 · M1 · N1 · O1 · P2 · Q3 · R1 · S1 · T3 · U1 · V1 · W2 ·
  X1 · Y2 · Z2 »* — la musique du combat : *Prepare Your Swords* (bojidar-bg, CC0), bouclée sur 84 s. *(10 h 25 : les favoris
  provisoires de Claude.)* Le catalogue : `design/sons/catalogue.py` (CC0 : Kenney, OpenGameArt ; synthétisés : le portail, les
  cloches de rareté, l'accord céleste, le sortilège, l'éclosion…) ; les fichiers : `preparer_jeu.py` (`CHOIX_SUITE`).
· **Le lecteur** (`son.gd`) : chaque son chargé à son premier usage ; son niveau (`NIVEAUX`) ; `Son.rarete(1..5)`, `Son.rang`,
  `Son.retourne_combat(k)` (la cascade d'un coup), `Son.fin` ; **la musique change par un fondu du BUS** (le jeu ⇄ le combat :
  `changer_musique`) — le volume d'un son qui joue ne suit pas sur le web.
· **Les accroches** : `Style.jeu` (tous les boutons, le refus), `barre_nav` (les onglets), `collection_screen` (`_sons_rituel` : le
  portail et le verrou à l'instant du rituel ; le retournement ; `_eclat_rare` ; `_annoncer_rang` ; la vedette), `evolution.gd`,
  `carre_ecran` (`_poser`, `_duel_et_retournement`, `_retourner`, les pouvoirs, `_fin`), `main.gd` (la musique du combat, le
  cadeau du jour), `chapitre_ecran` (les coffres), `presages_ecran` (recevoir, le code).

**Actions manuelles** : aucune.

**Tests faits** : `test_son` étendu (26 vérifications : l'onglet, le bouton, le refus, le portail, le verrou, le retournement, la
rareté d'un Full art, un duel joué jusqu'au bout — sa musique, 9 poses, les chocs, la cascade qui repart à do à chaque coup, la
fin — puis la musique du jeu au retour ; stable 4 fois sur 4 après deux corrections du TEST : une vraie pièce tombée pendant la
cascade, un retournement d'Anubis sans choc) ; `capture_arene`, `capture_astrolabe`, `capture_collection`, `capture_accueil`,
`capture_menu`, `test_codes` : OK ; les glyphes : aucun absent ; **le son mesuré dans Chrome** (`outils/navigateur/son.js`) : la
musique entre −20 et −35 dB, les touchers s'entendent. Déployé : `index.pck` servi à 10 h 25 (40 612 220 octets), healthcheck `200`.

**Pas testé** : sur le téléphone.

### ✅ À tester
- [ ] Les boutons cliquent ; les onglets tictent ; un bouton éteint fait un choc sourd
- [ ] Une invocation : le portail, le clic de l'astrolabe, la carte qui se retourne ; une carte rare carillonne ; une Légende, son accord
- [ ] Un combat : sa musique ; poser, les chocs, une chaîne qui monte ; un pouvoir ; la fin ; au retour, la musique du jeu
- [ ] Monter un niveau, faire évoluer une carte

---

## ✅ **La Nébuleuse sonne ; les Présages deviennent le Menu (Réglages, Code cadeau)** — **EN PROD** *(29/09/2026, 9 h 09 ; les sons de Maxim à 9 h 16 ; le son qui sort vraiment à 9 h 36)*

> 🔴 **9 h 36 — le son ne sortait pas** (Maxim : *« j'entends pas le son »*). Mesuré dans Chrome (`outils/navigateur/son.js`) :
> le jeu démarrait bien ses sons, aux bons volumes, mais la sortie restait à **−120 dB** (un son témoin, lui, sortait à
> −20 dB). **Cause** : les bus Musique et Effets étaient créés en cours de partie (`AudioServer.add_bus`) ; sur le web, où les
> sons sont des échantillons du navigateur, ils n'étaient reliés à rien. **Corrigé** : les bus sont déclarés dans le projet
> (`default_bus_layout.tres`). Et **la musique restait à −40 dB 25 s** : le volume d'un son qui joue n'y suit pas (le fondu
> d'entrée) → plus de fondu ; elle part à son niveau, un peu plus haut (−2 au lieu de −6 : à 60 %, ~−30 dB). Remesuré sur
> le jeu servi : la musique entre −20 et −35 dB dès le départ, les poses au toucher. **`test_son` passait pendant la panne** :
> il lit ce que le jeu demande (le pilote muet de Godot), pas ce qui sort.

**En clair.** Le jeu a du son : la pièce qu'on lâche tinte quand elle touche, les pièces poussées froissent, chaque pièce
qui tombe du bord fait « cling » — et quand elles tombent à la suite, chaque cling monte d'une note —, un objet gagné
carillonne, le plateau du jour vidé a sa fanfare, et une musique douce tourne en fond. Sous les défis des Présages, un
menu : Réglages (musique, effets, vibrations), Code cadeau, et Compte et Amis (scellés : ils arrivent avec les comptes).
Maxim crée un code cadeau d'une commande, sans toucher au jeu.

🔴 **POURQUOI** — Maxim, 29/09 : *« ma femme m'a dit être accro à la poussette, mais elle dit que ce serait encore pire si
elle avait le son, les pièces qui tombent, un bruit addictif quand on fait tomber un objet, une petite musique de fond »* ;
*« la page Présage pourrait être un peu la page Menu […] faudrait mettre un Redeem code, comme ça je peux mettre des codes
promos »* ; l'ordre proposé (le son et le Menu d'abord, les comptes ensuite) : *« oui go »*. DECISIONS 29/09.

· **Les sons** (`son.gd`, `Son.global` ; les fichiers : `proto_degagement/sons/*.ogg`, ~1,9 Mo) — **choisis par Maxim à
  l'écoute, 9 h 16** : *« Sons : A1 · B1 · C2 · D3 · E2 · F5 »* — le métal léger (la pose), la poignée de pièces (le
  froissement), la **pièce d'or synthétisée** (le gain, en cascade), l'arpège céleste (l'objet), le coup d'éclat (le plateau
  vidé), **Starfield Romance** (yoiyami, 3 min 34, bouclée sans raccord). *(9 h 09 : les favoris provisoires de Claude.)* Ils viennent de packs
  **CC0** (Kenney, OpenGameArt ; `design/sons/sources/LICENCES.md`) ou sont **synthétisés** (le carillon du gain, l'arpège de
  l'objet). La fabrique : `design/sons/preparer_ecoute.py` (la page d'écoute), `preparer_jeu.py` (les fichiers du jeu, selon
  `CHOIX`) — coupés à leur attaque (au plus 2 ms de silence avant), au même pic ; la musique bouclée sans raccord.
· **Quand ça sonne** (`pusher_screen.gd`) : la pose, au **premier contact de CETTE pièce** (`_sonner_a_la_pose` : seule elle
  écoute ses contacts, jusqu'au premier ; le tas, jamais — D13) ; le gain à chaque pièce passée (la cascade : do ré mi sol la
  do, retombe après 0,7 s de calme) ; l'objet (l'étoile au ton juste, la poussière +2, une pierre −3, la lune +7) ; la
  fanfare 0,55 s après le dernier objet du jour ; le froissement, des grains au hasard quand le poussoir avance (plus de 30
  pièces). La musique démarre au lancement, monte en 3 s (le navigateur la libère au premier toucher).
· **Les Réglages** (`reglages.gd`, `user://reglages.cfg` — l'appareil, pas la partie) : deux bus, Musique et Effets ; les
  vibrations, coupables : **toutes** passent désormais par `Reglages.vibrer` (14 appels).
· **Le Menu** (`presages_ecran.gd` § `_menu`) : quatre médaillons aux icônes tracées à l'or sous le défi de la semaine ;
  Compte et Amis scellés (« Arrive avec les comptes ») ; Réglages et Code cadeau en panneau par-dessus la page.
· **Le code cadeau** (`codes.gd` ; la commande : `codes_cadeaux/codes.py`) : le jeu lit `web/codes/codes.json` à côté de lui
  (chez les cousins aussi, par le portier), **sans les codes en clair** (l'empreinte SHA-256 d'un sel et du code) ; une fois
  par partie ; une date de fin ; étoiles, poussière, pièces, éclats, pierres. Sur le téléphone, le clavier vient pour un
  vrai champ HTML posé sur la place du champ (l'option « clavier virtuel » de Godot est expérimentale). **Un premier code :
  BIENVENUE** (5 étoiles, jusqu'au 31/12).

**Actions manuelles** : aucune pour déployer. Pour un code : `python codes_cadeaux/codes.py ajouter <CODE> --etoiles 10
--fin 2026-12-31` (voir `liste`, `retirer`) — en ligne tout de suite.

**Tests faits** : `test_son` (12 vérifications : la pose au contact et pas au geste, la cascade, les objets, la fanfare, le
froissement, la musique), `test_codes` (20 : l'empreinte identique à celle de Python, les refus et le passage, une fois,
la sauvegarde, les bus), `capture_menu` (9 vérifications, 7 captures), `sim_poussoir -- duree=90` (1,72 ms par image, 0
hors jeu), `test_journee`, `capture_journee`, `capture_accueil` : OK. Les glyphes : 56 972 caractères, aucun absent. La
commande des codes : un code, un doublon refusé, un code tiré au hasard, retiré. Déployé : `index.pck` servi à 9 h 09
(36 853 272 octets ; les sons et les scripts vérifiés dedans), `codes/codes.json` servi (`200`), healthcheck `200`.

**Pas testé** : sur le téléphone — le son (le vrai volume, la cascade à l'oreille), le clavier du code cadeau.

### ✅ À tester
- [ ] Le premier toucher lance la musique ; Réglages : la musique et les effets se baissent, les vibrations se coupent
- [ ] Lâcher des pièces : un tintement quand elles touchent ; une cascade quand plusieurs tombent du bord de suite
- [ ] Un objet gagné carillonne ; le dernier objet du jour : la fanfare
- [ ] Code cadeau : taper `bienvenue` (le clavier vient) → « Reçu : 5 étoiles ! » ; une seconde fois → « déjà »
- [ ] La Nébuleuse garde ses images/s avec le son

---

## ✅ **Les chiffres des cartes se lisent en combat ; le point d'or se voit** — **EN PROD** *(29/09/2026, 8 h 15)*

**En clair.** Dans le Carré, la carte de ta main que tu touches grandit tout de suite à la taille du plateau : ses quatre
chiffres se lisent comme ceux des cartes posées, et elle garde cette taille quand tu la fais glisser. La main de
l'adversaire, minuscule en haut, descend en grand quand on la touche. Et le point d'or des onglets est plus gros, avec un
anneau qui bat.

🔴 **POURQUOI** — Maxim, 29/09 : *« le point d'or manque un peu de visibilité »* ; *« ma femme m'a dit que pendant les
parties, elle avait du mal à voir les numéros sur les cartes […] quand on prend la carte avec le doigt, on peut pas grossir
la carte ? »* ; fiche : *« go »*. Mesuré avant : la main à 186 px (des chiffres de ~1,2 mm sur le téléphone), la main
adverse à 78 px (illisible), le plateau à 280 px (~2 mm, lisible).

· **La loupe** (`carre_ecran.gd` § `LOUPE`, `_centre_loupe`, `_appui`) : le doigt posé sur une carte de ta main, elle monte
  et passe à 280 px (×1,43) — même quand ce n'est pas ton tour, pour la lire ; lâchée sans glisser, elle devient la choisie et
  reste grande ; retouchée, elle reprend sa place. En glissant, elle garde la taille du plateau (un peu plus au-dessus d'une
  case où elle peut tomber).
· 🔴 **Le doigt se lit sur la place de chaque carte au repos** (`_carte_main_sous`), pas sur son dessin : une carte agrandie
  déborde sur ses voisines, un doigt sur une voisine prend la voisine.
· **La main un peu plus large** : 196 px au lieu de 186, 12 d'écart au lieu de 20.
· **La main adverse** (`_montrer_main_adv`) : touchée, elle descend en grand (à la taille de ta main) par-dessus le haut du
  plateau, qui s'assombrit ; toucher l'une de ses cartes la lit dans la bande ; ailleurs, elle remonte ; elle remonte aussi
  d'elle-même quand l'adversaire joue.
· **Le combat guidé** : sa consigne remonte un peu (`GUIDE_Y` 1800), au-dessus de la carte agrandie.
· **Le point d'or** (la barre du bas, et l'onglet « Ciel du Peintre ») : ~1,5× plus gros, cerclé de sombre, un reflet, et un
  anneau net qui s'élargit toutes les 1,5 s — pas de halo.

**Actions manuelles** : aucune.

**Tests faits** : `capture_arene` (6 vérifications de plus : la loupe, la choisie, la voisine, la reposée, la main adverse
qui descend puis remonte ; 2 captures), `capture_carre -- 11 7 tuto` (le combat guidé), `capture_astrolabe`,
`capture_accueil` : OK. Déployé : `index.pck` servi à 8 h 15 (36 546 324 octets), healthcheck `200`.

**Pas testé** : sur le téléphone.

### ✅ À tester
- [ ] Poser le doigt sur une carte de ta main : elle grandit, ses chiffres se lisent ; la glisser : elle reste grande
- [ ] Toucher une carte puis une case : la carte choisie reste grande ; retouchée, elle reprend sa place
- [ ] Toucher la main adverse en haut : elle descend en grand ; toucher ailleurs : elle remonte
- [ ] Le point d'or sur l'onglet Astrolabe (une partie qui n'a pas pris son cadeau) : se voit-il de loin ?
- [ ] Demander à ta femme si elle lit mieux

---

## ✅ **L'Astrolabe s'ouvre : deux ciels où invoquer, dont un Full art garanti** — **EN PROD** *(28/09/2026, 22 h 27 ; le cadeau en ×10 à 22 h 38)*

**En clair.** Le dernier onglet est ouvert : on invoque maintenant dans l'Astrolabe, et on y choisit son ciel. **Le Grand
Ciel**, toujours là, aux chances de toujours. **Le Ciel du Peintre** : le Full art y tombe deux fois plus, jamais sur un
sbire, et **la centième invocation en donne un d'office** — un compteur le dit en gros ; au premier Full art, ce ciel se
referme pour de bon. **Sa première invocation ×10 est offerte**, un cadeau pour tout le monde (un point d'or sur l'onglet le
signale). Dans l'Atlas, **« Mes decks »** prend la place de l'invocation, en haut.

🔴 **POURQUOI** — Maxim, 28/09 : *« on peut débloquer la dernière page maintenant, les portails […] un portail normal avec
les taux de drops qu'on connaît et un portail Full art ×2 […] au premier drop d'une Full art le portail disparaît […] le
100ème ticket garantit une Full art »* ; fiche : *« 1. je te fais confiance 2. si l'utilisateur a dépensé 100 étoiles, la
100ème c'est d'office un Full art 3. minimum un héros 4. oui 5. oui »* ; *« offre la première invocation Full art aux gens,
c'est un cadeau »* ; *« fais un beau design »* ; *« valide direct, pas besoin de capture »*. DECISIONS 28/09.

· **Les ciels** (`portails.gd`, `GS.tirer` / `invoquer_multi` / `probas` / `probas_cartes` par ciel) : le Grand Ciel ne change
  rien (le hasard s'y tire dans le même ordre qu'avant). Le Ciel du Peintre : Full art 0,2 % (pris sur la Base : 73,8 %),
  un Full art y est retiré parmi Héros, Mythe, Légende, sur une carte qui ne l'a pas ; chaque carte compte (un ×10 : 10) ;
  celle qui atteint 100 est un Full art d'office ; le ciel se referme après le tirage où tombe son Full art (un ×10 va au
  bout) ; la première ×10 est offerte et compte dans les 100 (le compteur passe à 90) — un ×1 se paie toujours (22 h 38,
  Maxim : *« c'est une invocation ×10 que je voulais donner en cadeau, pas 1 »*). Les probabilités de chaque ciel se calculent
  depuis ses poids (les rangs en tiennent compte : Sbire 59,9 %, Héros 25,1 %). État dans `GS.voyage["portails"]` : **pas
  de migration** (une partie sans la clé : le compteur à 0, le cadeau dû).
· **La page** (`astrolabe_ecran.gd`) : deux onglets (comme le Voyage), puis un grand panneau par ciel, ses boutons dedans.
  Ses fonds sont rendus par la fabrique à leur taille exacte (`render_objets.py --bannieres`, 1020 × 1700, JPEG ~110 Ko :
  le mauve de la Nébuleuse pour le Peintre, jade et nuit pour le Grand Ciel), les coins arrondis par
  `interface/arrondi.gdshader`. **Le Grand Ciel** : un astrolabe qui tourne lentement, trois cartes en éventail (un Mythe en
  Or, une Légende en Prismatique, un Héros Élémentaire), trois pastilles de chances. **Le Ciel du Peintre** : une Légende en
  Full art, en 3D, qui se balance et joue dans la lumière (`Carte3D.vitrine`), puis le limbe de l'astrolabe — 100
  graduations qui s'allument en or, l'étoile du Full art au bout — et « FULL ART GARANTI DANS 63 » (« PLUS QUE 7 » à 10 de
  la fin, le nombre bat). Les cartes montrées changent chaque jour. La pastille « CADEAU » flotte sur « Invoquer ». Refermé :
  un mot, une fois (« ton Full art t'attend dans l'Atlas »), puis le Grand Ciel seul.
· 🔴 **La vitrine ne coûte rien ailleurs** : ses deux SubViewports n'existent que la page vue, sur le Peintre ; pendant une
  invocation, la bannière ne se dessine plus (elle revient à la fermeture). Au banc (`banc_invocation`, lancé de
  l'Astrolabe) : une fois l'animation partie, **aucune image au-delà de 33 ms** (la pire : 11,5 ms).
· 🔴 **La couche des révélations de l'Atlas se cachait avec l'Atlas** (« une CanvasLayer ne suit pas son parent » : on la lui
  faisait suivre) — lancée de l'Astrolabe, l'invocation aurait été invisible. Elle reste allumée pour une révélation, une
  ×10 ou les probabilités.
· **« Encore »** invoque dans le même ciel ; le ciel refermé sur ce Full art : « Fermer » seul, au milieu. La révélation du
  Full art garanti le dit (« Le Full art garanti du Ciel du Peintre ! »).
· **L'Atlas** : en haut, « TON DECK POUR COMBATTRE », ses 5 cartes, son nom, son poids, et « Mes decks », qui ouvre la liste
  par-dessus l'Atlas (retour : « ‹ L'Atlas »). Les boutons de decks du Voyage restent.
· **L'accueil du premier pack** montre l'Astrolabe (plus l'Atlas) ; pendant le pack, le Grand Ciel laisse la place à la
  consigne.
· **Les outils de test** (D1) passent dans l'Astrolabe : « +10 étoiles », « Prisma », « Full art », et deux nouveaux,
  « Peintre +10 » (le compteur) et « Rouvrir » (le Peintre, comme neuf).

**Actions manuelles** : aucune.

**Tests faits** : `test_portails` (41 vérifications ; au banc de 12 000 joueurs, 18,1 % avant la garantie, 90,7 invocations
en moyenne, jamais plus de 100), `capture_astrolabe` (14 captures, 23 vérifications), `capture_accueil`, `capture_collection`,
`capture_journee`, `capture_arene`, `test_tirage`, `test_collection`, `test_journee`, `test_objets`, `test_cartes`,
`test_carre`, `test_aventure`, `test_decks`, `test_classe` : OK. Les glyphes : aucun absent. `banc_invocation` : ci-dessus.
Déployé : `index.pck` servi à 22 h 27 (36 543 972 octets ; la page et les deux fonds vérifiés dedans), healthcheck `200`.
Le cadeau en ×10 : `test_portails` et `capture_astrolabe` repassés (OK), servi à 22 h 38 (36 543 924 octets), healthcheck `200`.
Les captures n'ont pas été montrées (*« pas besoin »*).

**Pas testé** : sur le téléphone.

### ✅ À tester
- [ ] L'onglet Astrolabe a un point d'or ; dedans, le Ciel du Peintre, « CADEAU » sur « Invoquer ×10 », « offerte »
- [ ] La ×10 offerte : aucune étoile prise, le compteur passe à 90, le point d'or disparaît
- [ ] La carte en vitrine se balance ; au doigt, elle se tourne (son dos)
- [ ] Le Grand Ciel : l'astrolabe tourne, les trois cartes ; « Les probabilités » de chaque ciel
- [ ] Outils (appui long sur « Nébuleuse ») : « Peintre +10 » jusqu'à 90 → « PLUS QUE 10 » en or ; un ×10 → le Full art
      garanti, jamais un sbire ; le mot d'adieu, le Grand Ciel seul ; « Rouvrir » pour recommencer
- [ ] L'Atlas : « Mes decks » en haut, la liste par-dessus, « ‹ L'Atlas »
- [ ] Fluidité : l'invocation part sans à-coup depuis l'Astrolabe ; la Nébuleuse garde ses images/s

---

## ✅ **La victoire parfaite s'anime aussi au Duel et au Classé** — **EN PROD** *(28/09/2026, 20 h 36)*

**En clair.** Gagner un duel ou un classé avec les 9 cartes du Carré fait maintenant la même chose que dans l'Aventure :
la constellation d'or relie les cartes, « Parfait ! », et le panneau de fin dit « Parfait — Les 9 cartes du Carré sont à toi ».

🔴 **POURQUOI** — Maxim, 28/09 : *« j'ai testé le duel et classé, c'est top, juste l'animation d'un perfect win ne se fait pas
dans ce mode »*. `_fin_arene` (le Duel et le Classé) ne regardait jamais la victoire parfaite ; seul `_fin_aventure` le faisait.

· `carre_ecran.gd` § `_fin_arene` : `Aventure.defi_reussi("parfait", …)`, `_constellation_parfaite()`, 2,3 s au lieu de
  0,9 s avant le panneau, le titre « Parfait ». Rien ne change aux gains (la victoire parfaite ne rapporte rien de plus,
  comme dans l'Aventure). Le résultat reste écrit avant l'animation (une app fermée pendant ne perd rien).
· `tests/capture_arene` : un duel parfait joué pour de vrai (tu commences ; les cartes d'en face passent à toi avant
  chacun de tes coups), vérifié et photographié.

**Actions manuelles** : aucune.

**Tests faits** : `capture_arene` OK (30 vérifications, dont « parfait : les 9 cartes à toi ») ; les captures montrent la
constellation puis le panneau « Parfait ». Déployé : `index.pck` servi à 20 h 36 (35 690 980 octets — la même taille
qu'à 20 h 18 : les fichiers du `.pck` sont calés sur 16 octets ; vérifié dans le `.pck` servi que `_constellation_parfaite`
y est appelée 3 fois, contre 2 avant), healthcheck `200`.

### ✅ À tester
- [ ] Un duel ou un classé gagné 9 à 0 : la constellation d'or, « Parfait ! », puis le panneau « Parfait »

---

## ✅ **Le rang d'une carte se voit ; l'ouverture des cartes ne saccade plus** — **EN PROD** *(28/09/2026, 20 h 18)*

**En clair.** On sait maintenant si une carte est une Légende, un Mythe, un Héros ou un sbire : c'est écrit en couleur sur la
carte, annoncé quand elle se retourne à l'invocation, compté dans le bilan d'une ×10, et l'Atlas les range par rang. Et
l'animation d'ouverture ne saccade plus au départ : l'image de la carte se prépare sur l'écran immobile, avant que le portail
ne bouge.

🔴 **POURQUOI** — Maxim, 28/09 : *« on sait pas quand on a une carte mythe, légende, héros ? »* ; *« l'animation d'ouverture
de carte lag au début, après ça va »* ; la proposition : *« Ok »* ; captures : *« Go »*.

· **Le rang, partout pareil** (`Style.couleur_rang`, `nom_rang`) : LÉGENDE en or, MYTHE en violet, HÉROS en ivoire, SBIRE en
  gris. **Sur la carte** : dans le bandeau du haut, pour toutes (à la place du rôle, qui ne sert plus au Carré), plus grand
  (`Vignettes.VERSION` 6 : les photos de la grille se refont une fois). **À la révélation** : au retournement,
  « INVOCATION » devient le rang ; une Légende ou un Mythe claque (étincelles, vibration). **Dans une ×10** : une Légende
  vient au centre, en grand, sous « LÉGENDE » ; à la fin, une pastille sur chaque Mythe et chaque Légende (dans le coin :
  au-dessus, elle tombait sur la carte d'avant ; au milieu, elle cachait le chiffre du haut) ; le bilan commence par
  « 1 Légende · 1 Mythe ». **Dans l'Atlas** : quatre sections, les Légendes d'abord (« 2 sur 8 »), puis les Mythes, les
  Héros, les sbires. *Le Full art n'a pas de bandeau (rien sur son image que ce qui sert au jeu) : son rang se voit à
  l'invocation et dans l'Atlas.*
· **La saccade de l'ouverture** — mesurée au banc (`tests/banc_invocation`, `banc_image`) : chaque carte révélée décodait son
  illustration (800 × 1000, ~18 ms sur le PC, plusieurs fois plus sur le téléphone) au moment même où l'animation partait —
  une image de 130 à 240 ms au départ de CHAQUE invocation, 270 à 310 ms pour une ×10 (sur le PC) —, et l'illustration
  sortait de la mémoire à la carte suivante. Maintenant : 1. le toucher fait paraître le voile (1 ms) ; 2. l'illustration se
  décode sur ce voile immobile, et part à la carte graphique ; 3. le portail ne bouge qu'après. **Les illustrations restent
  en mémoire** (`CarteView.texture_art` : les 12 dernières pleines, les 30 dernières vignettes) : une carte déjà vue ne
  coûte plus rien (les sbires tombent 6 fois sur 10). L'illustration d'une Légende ou d'un Full art qui viendra au centre
  d'une ×10 se charge pendant l'attente, pas en plein vol. **Le préchauffage** couvre l'élémentaire de chaque type et la carte
  en 3D. Au banc, une fois partie, **aucune image au-delà de 33 ms** (la pire : 7 ms, une ×10 : 23 ms).

**Actions manuelles** : aucune.

**Tests faits** : `capture_collection` étendu — la grille par rang, une Légende et un Héros révélés (« LÉGENDE », « HÉROS »),
une ×10 avec une Légende au centre et le bilan « 1 Légende · 1 Mythe » : OK (il a vu les pastilles mal placées, deux fois).
Les 9 tests, `capture_accueil`, `capture_arene`, `capture_journee` : OK. Les glyphes : 51 837 caractères, aucun absent.
Déployé : `index.pck` servi à 20 h 18 (35 690 980 octets), healthcheck `200`.

**Pas testé** : sur le téléphone — le ressenti de l'ouverture (la pause au toucher reste, sur un écran immobile, plus courte
quand la carte est connue).

### ✅ À tester
- [ ] Invoquer : le voile vient tout de suite ; le portail part sans à-coup ; au retournement, le rang s'affiche
- [ ] Une ×10 : pas d'à-coup au départ ; une Légende vient au centre ; les pastilles ; le bilan
- [ ] L'Atlas : les Légendes en haut, puis Mythes, Héros, sbires ; le rang en couleur sur chaque carte
- [ ] La première ouverture de l'Atlas : « Préparation de ta collection » une fois (les photos se refont)

---

## ✅ **La collection : les éclats, « Obtenir », jamais de Full art en double, l'évolution plus longue** — **EN PROD** *(28/09/2026, 18 h 48)*

**En clair.** Chaque carte invoquée donne des éclats ; avec eux, on obtient la carte qu'on veut, dans la variante qu'on
veut — sauf le Full art, qui reste de la pure chance. Un prismatique ou un Full art tiré n'est jamais un doublon. Et
faire évoluer une carte demande maintenant du temps : le niveau 5 puis 10, 1 puis 2 pierres.

🔴 **POURQUOI** — Maxim, 28/09 : *« pokemon te donne des cristaux quand tu ouvres des packs et tu peux tout acheter comme
carte sauf les Full art »* ; *« imagine j'ai un doublon d'une carte en Full art, ça m'énerverait que ça me donne de la
poussière »* ; *« ça doit être difficile d'évoluer les cartes, faut une belle durée de vie »* ; fiche : *« Ok »* ; captures :
*« Ok pour moi »*. DECISIONS 28/09, « L'économie de la journée ».

· **Les éclats** (`GS.eclats`, `ECLATS_PAR_INVOCATION = 5`) : 5 par carte invoquée (le premier pack compris) ; un vrai doublon
  (même carte, même variante) en donne plus (base 5, Or 10, Ombre 20, Élémentaire 40, prismatique 100, Full art 300) —
  **plus de poussière pour un doublon**. Ils se voient au-dessus de la grille de l'Atlas (l'icône : la gemme jade sertie
  d'or, `objets/eclat.png`).
· **Obtenir** (`GS.prix`, `obtenir` ; l'Atlas) : une carte qu'on n'a pas s'ouvre enfin quand on la touche (« Pas encore à
  toi · Légende », « Obtenir · 900 éclats ») ; sur une carte qu'on a, ses variantes qui manquent montrent leur prix (le Full
  art : « chance », il ne s'achète pas). Sbire 60, Héros 200, Mythe 450, Légende 900 ; × 2 (Or), 3 (Ombre), 5 (Élémentaire),
  10 (prismatique). **Deux touches** : la première demande « Sûr ? ».
· **Jamais en double** (`GS.tirer`) : on tire le rang, puis la variante, puis la carte — un prismatique ou un Full art tombe
  sur une carte du rang qui ne l'a pas encore (tant qu'il en reste). Les pourcentages affichés ne changent pas ; l'écran des
  probabilités le dit.
· **L'évolution** : le stade II au niveau 5 et 1 pierre, le III au niveau 10 et 2 pierres (celles de son type d'abord, la lune
  complète) ; un niveau coûte 100 × le niveau ; **niveau maximum 10** (un sbire, un héros à un seul stade : pas de niveau).
  Rien ne recule : un stade atteint, un niveau gagné restent. Le bouton : « Évoluer · LVL 10 » / « 2 pierres de foudre ».
· 🔴 **La sauvegarde passe en v4** : `"eclats"` avait servi jusqu'à la v2 pour les anciennes pierres (converties en lune) ;
  il n'est lu comme monnaie qu'en v4 — sinon une vieille partie aurait eu ses pierres ET autant d'éclats, sans un mot.
· En route : le défi « Fais monter une carte » n'est plus proposé si aucune ne peut monter (le niveau maximum).

**Actions manuelles** : aucune.

**Tests faits** : **`test_collection`** (nouveau) : 33 vérifications — 200 000 tirages avec une collection où une seule carte
par rang n'a ni prismatique ni Full art : **tous** les tirés rares tombent sur elle (2 219 sur 2 219), les taux des rangs et
des variantes à moins de 0,35 point de l'affiché ; le témoin (tout le rang l'a : n'importe quelle carte) ; les éclats, les
prix, obtenir (le refus ET le passage), les niveaux, la sauvegarde ; `ECHEC` quand on casse exprès la règle (214 sur 2 219).
`test_objets` (l'évolution 5/10, 1/2 pierres, la lune qui complète, le pluriel ; une v2 ne donne pas d'éclats ; une v4 oui),
`test_tirage`, `test_journee`, `test_classe`, `test_aventure`, `test_decks`, `test_carre`, `test_cartes` : OK.
**`capture_collection`** (nouveau) : l'Atlas et ses éclats, une carte à obtenir (deux touches), obtenue, le niveau maximum,
les probabilités, une invocation et une ×10 — OK ; `capture_accueil`, `capture_arene`, `capture_journee` : OK. Les glyphes :
51 304 caractères, aucun absent. Déployé : `index.pck` servi à 18 h 48 (35 686 164 octets), healthcheck `200`.

**Pas testé** : sur le téléphone.

### ✅ À tester
- [ ] L'Atlas : les éclats en haut de la grille ; une ×10 en ajoute au moins 50
- [ ] Toucher une carte « À découvrir » : « Obtenir · N éclats » ; deux touches ; elle entre dans la collection
- [ ] Une carte qu'on a : ses variantes qui manquent, avec leur prix ; le Full art : « chance »
- [ ] Monter une carte : 100 × le niveau ; au niveau 10 : « Niveau maximum »
- [ ] Évoluer : niveau 5 et 1 pierre, puis niveau 10 et 2 pierres

---

## ✅ **La journée : le plateau du jour, les pièces des défis, les Présages** — **EN PROD** *(28/09/2026, 16 h 40)*

**En clair.** La Nébuleuse ne donne plus sans fin : chaque jour, son plateau porte 12 objets connus d'avance (1 étoile,
3 pierres, 8 poussières), puis « revient demain ». Les pièces ne remontent plus toutes seules : on les gagne avec les
défis du jour, dans l'onglet Présages qui s'ouvre (3 défis, un bonus, un défi de la semaine), et avec le cadeau du jour.

🔴 **POURQUOI** — le banc du 28/09 : la Nébuleuse rapportait **~48 étoiles par heure** de jeu, sans limite ; Maxim, 23/09 :
*« ça doit être dur d'avoir une invocation ×10 »* ; 28/09 : *« arrêter de donner des pièces la minute et en faire gagner
dans les défis journaliers et hebdo, comme ça on met des pièces dans les packs pour que les gens jouent »* ; *« 1. Oui ok »*
(une ×10 tous les ~4 jours) ; captures : *« Go »*. DECISIONS 28/09, « L'économie de la journée ».

· **Le plateau du jour** (`plateau.gd`) : 12 objets par jour — 1 étoile, **3 pierres écrites par le calendrier** (le même jour
  pour tous ; la lune 12 fois sur 100), 8 poussières. La machine garde un objet par rang tant qu'il en reste aujourd'hui ;
  un objet gagné n'est remplacé que s'il en reste ; tout gagné : plus d'objet, « Revient demain ». Minuit en pleine partie :
  le plateau d'un nouveau jour. Le panneau du bas montre les 12 objets ; ceux qu'on a gagnés s'éteignent.
· **Les pièces** (`pusher_screen.gd`) : **plus de recharge** (+1 toutes les 3 s jusqu'ici) **ni de plafond** (150). Elles
  viennent du cadeau du jour (25), des défis, et de ce que la machine rend. Sans pièce : *« Plus de pièces : les Présages
  en donnent. »* La réserve se relit à chaque gain (avant, elle ne bougeait qu'à la chute d'une pièce).
· **Les Présages** (`presages.gd`, `presages_ecran.gd`, l'onglet de la barre, qui était scellé) : **3 défis par jour**, tirés
  par le calendrier parmi 12, seulement ce que le joueur a ouvert (un nouveau joueur : la Nébuleuse), un de la Nébuleuse et
  un du Voyage ; fixés pour la journée. **60 pièces** chacun ; **les 3 reçus : 1 pierre de lune** ; **la semaine** (les 3
  défis 5 jours, du lundi au dimanche) : **3 étoiles et 200 pièces**. « Y aller » mène à l'onglet du défi ; « Recevoir » fait
  s'envoler les pièces vers la Nébuleuse, les étoiles et la lune vers le bandeau ; un point sur l'onglet tant qu'il y a à
  recevoir. Ce qui les fait avancer : la Nébuleuse (objets, pièces, plateau vidé), la fin d'un combat (combats, cartes
  retournées, chaîne, victoires de l'Aventure et ses ★, du Duel, du Classé), l'Atlas (monter une carte, invoquer).
· **Retirés** : le compteur du plateau d'avant (`GS.PLATEAU_JOUR`, `gains_jour`, `objets_restants`) et le tirage au hasard
  de l'objet (`PusherScreen.tirer_lot`) ; la liste des pierres ne vit plus qu'à un endroit (`Plateau.PIERRES`).

**Actions manuelles** : aucune.

**Tests faits** : **`test_journee`** (nouveau) : 233 vérifications — le plateau (le refus au-delà du quota ET le passage
avant, minuit, abîmé), les défis (un nouveau joueur sans défi du Voyage, 60 jours de tirages, fixés dans la journée), les
événements, recevoir une fois, le bonus, la semaine (4 jours non, 5 oui, lundi repart), les branchements, la sauvegarde :
`RESULTAT: OK` — et `ECHEC (4)` quand on casse exprès « reçu une fois » (le test sait échouer). `test_objets` (les pierres du
calendrier : lune 12 %, six types à parts égales), `test_classe`, `test_aventure`, `test_decks`, `test_carre`,
`test_tirage`, `test_cartes` : OK. **`sim_poussoir -- duree=900`** : vider le plateau coûte **123 pièces nettes en jouant vite
(4 min), 148 au rythme moyen (9 min), 175 calmement (14 min)** — d'où 60 par défi (205 par jour avec le cadeau) ; ses
contrôles comptent les objets qu'il reste aujourd'hui (vidé : 0 ; entamé : 2). **`capture_journee`** (nouveau) : le plateau
neuf, entamé, vidé (0 objet posé), les Présages, « Recevoir », la semaine, sans pièce — OK. `capture_accueil`,
`capture_arene` (corrigé : il supposait un classé gagné, 3 passages sur 3) : OK. Les glyphes : 50 689 caractères, aucun
absent. Déployé : `index.pck` servi à 16 h 40 (35 681 060 octets), healthcheck `200`.

**Pas testé** : sur le téléphone ; un vrai minuit en pleine partie (testé en changeant la date, pas en attendant).

### ✅ À tester
- [ ] La Nébuleuse : les 12 objets du jour en bas ; gagnés, ils s'éteignent ; tout gagné : « Revient demain »
- [ ] Les pièces ne remontent plus toutes seules ; la réserve n'a plus de « / 150 »
- [ ] Présages : 3 défis ; « Y aller » ; fini → « Recevoir », les pièces s'envolent, la réserve de la Nébuleuse les montre
- [ ] Les 3 reçus → la pierre de lune ; le point sur l'onglet s'éteint quand tout est reçu
- [ ] Demain : de nouveaux défis, un plateau plein, et la semaine compte le jour d'hier si ses 3 défis étaient faits

---

## ✅ **Le Duel et le Classé** — **EN PROD** *(28/09/2026, 14 h 53)*

**En clair.** Le Voyage a trois onglets : Aventure, Duel, Classé. Le Duel oppose un adversaire de ta force, et ta cote
monte ou descend. Le Classé est une échelle de six rangs, de Météore à Zénith, qui se mérite : plus tu montes, plus
l'adversaire est fort, et chaque mois une saison se termine avec sa récompense. Les deux s'ouvrent une fois le
Chevalier sans tête battu ; 5 victoires par jour rapportent de la poussière, en Duel ou en Classé.

🔴 **POURQUOI** — la fiche du 28/09, acceptée (*« 1. OK 2. ok »*) ; DECISIONS 26/09 (MMR ±100, +25/−20, saisons) et
28/09 (deux entrées). Maxim : *« ça doit se mériter, les autres qui veulent pas joueront pas classé »* ; *« Poussière et
étoile et nébuleuse sont déjà utilisés autre part »* ; les adversaires présentés comme l'ordinateur : *« oui ok pour
l'instant »*. Captures validées : *« Go go »*.

· **Les adversaires** (`carre/fantomes.gd`) : l'ordinateur, sous le nom d'un personnage (« Cerbère, gardien des Enfers »).
  Un deck de joueur (5 cartes, poids 14, cartes qu'on peut avoir), dont la force et l'ordinateur viennent d'un seul
  chiffre, la cote (800 → 1 800 : force de deck 85 → 140, Apprenti → Maître, tiré au sort dans une part qui glisse ; au
  banc, un passage net faisait un mur). Plus il est fort, plus sa carte de tête est rare (full art en haut).
· **Le Duel** (`duel.gd`, `duel_ecran.gd`) : cote 1 000 au départ ; l'adversaire à ±100 ; Elo (K 24) ; les 5 derniers
  duels ; « Chercher un adversaire » lance le combat tout de suite.
· **Le Classé** (`classe.gd`, `classe_ecran.gd`) : 6 rangs × 3 marches de 100 points (le Zénith : sans marche, ses points
  s'accumulent) ; +25 / −20, le surplus passe à la marche suivante ; chaque rang atteint est un plancher ; l'adversaire
  d'une marche a une force fixe (800 + 60 par marche). La saison = le mois du téléphone, nommée d'une constellation
  (la Lyre en septembre, le Cygne en octobre…) ; à la 1ʳᵉ ouverture dans un nouveau mois : la récompense du meilleur rang
  (si l'on a joué), donnée puis montrée une fois, et −1 rang par mois passé. Une horloge qui recule ne rejoue rien.
· **Ce qu'ils partagent** (`arene.gd`) : l'ouverture après le 1er boss (le cadenas dit qui battre) ; la poussière du jour
  (30 × 5 victoires, Duel ou Classé, donnée avec le résultat) ; le combat écrit « en cours » dès qu'il commence —
  « Quitter » (deux touches : *« Sûr ? »*) ou l'app fermée en plein combat = une défaite.
· **Le combat** (`carre_ecran.gd`) : sous le nom de l'adversaire, sa cote ou la marche jouée ; la fin : la cote qui
  bouge, ou la barre des points qui se remplit et la marche passée (*« Tu passes Éclipse III ! »*) ; la poussière qui
  s'envole ; « Encore » (un nouvel adversaire) et « Retour ».
· **Le Voyage** (`voyage_ecran.gd`) : les onglets (un bouton jade de la fabrique pour celui qu'on regarde) remplacent le
  titre « Le Voyage » ; « Changer » de deck revient au bon écran.
· **La fabrique** : les 6 emblèmes des rangs (`design/objets/render_rangs.py` → `carre/rang-*.png`), le bouton jade
  (`render_objets.py`, style « jade » : ses 4 images seulement, rien d'autre réécrit).
· **En route** : `Style.bulle` passe sous l'élément s'il n'y a pas la place au-dessus ; `Style.habiller` (changer l'habit
  d'un bouton) ; la flèche « → » n'est dans aucune de nos polices (vue en boîte à la capture) → « › ».
· **Deux outils de test de plus** (D1, réseau local) : l'appui long sur « Nébuleuse » ouvre aussi le Duel et le Classé
  (sans rien écrire), et met un bouton « Test : fin de saison » dans le Classé (la récompense est donnée pour de vrai).

**Actions manuelles** : aucune.

**Tests faits** : **`test_classe`** (nouveau) : 4 966 vérifications — les decks des adversaires (légaux, même graine =
même adversaire), les marches, le surplus et le manque, le plancher qui retient ET qui laisse descendre, le Zénith, les
saisons (récompense une fois, rien sans avoir joué, horloge reculée, 3 mois d'absence, changement d'année), Elo, la
poussière du jour (6 victoires → 5 × 30), le combat interrompu (une fois), l'aller-retour JSON, une sauvegarde
abîmée : `RESULTAT: OK` (il avait échoué avant la correction de `donnees()`, qui refabriquait son dictionnaire).
`test_aventure`, `test_decks`, `test_carre`, `test_objets` : OK. **`tests/capture_arene`** (nouveau) : de vrais combats
joués jusqu'au bout dans le vrai jeu, 13 captures, les vérifications en route (en cours puis effacé, +30, abandon = −20
en deux touches, récompense de saison une fois) : OK. Le banc **`tests/banc_fantomes -- echelle 8 250`** : 8 saisons de
250 parties par profil — débutant (au hasard) : Aurore III ; moyen, deck de départ : Éclipse III ; moyen, meilleur deck :
Galaxie III ; fort (le Maître), meilleur deck : Zénith 8 fois sur 8, en ~86 parties. Tous les textes des nouveaux
écrans passés à la police (7 263 caractères, aucun absent ; le contrôle attrape bien « → »). Déployé : `index.pck`
servi à 14 h 53 (35 663 564 octets), healthcheck `200`.

**Pas testé** : sur le téléphone ; le temps que met le Maître à jouer sur le téléphone (en haut de l'échelle, c'est lui
qui joue) ; une vraie fin de mois (le 1er octobre, la saison de la Lyre finira pour de vrai).

### ✅ À tester
- [ ] Sur une partie qui n'a pas battu le Chevalier sans tête : Duel et Classé ont un cadenas, la bulle le dit
- [ ] Appui long sur « Nébuleuse » (réseau local) : les onglets s'ouvrent
- [ ] Duel : cote 1 000 ; « Chercher un adversaire » ; gagné → la cote monte, +30 poussière, 1/5
- [ ] Classé : +25 dans la barre ; à 100, la marche passe (l'emblème change) ; perdu à un plancher : on reste
- [ ] « Quitter » en plein classé : « Sûr ? », puis −20 ; fermer l'app en plein classé → une défaite à la réouverture
- [ ] « Test : fin de saison » : le panneau, « Recevoir », les étoiles s'envolent ; relancer : rien de donné deux fois
- [ ] Contre un adversaire du haut (Galaxie, Zénith) : aucune saccade quand l'ordinateur réfléchit
- [ ] L'Aventure comme avant (un niveau, ses ★, « Niveau suivant »)

---

## ✅ **Le premier pack offert, guidé — et plus de cartes prêtées** — **EN PROD** *(28/09/2026, 8 h 36)*

**En clair.** Au tout premier lancement, le jeu montre du doigt le chemin : l'Atlas, un premier pack de 10 cartes
offert, puis le Voyage et le premier combat. Le pack est au hasard, mais donne toujours au moins 5 cartes différentes,
dont 3 héros : chacun a de quoi composer son deck. Le cadeau de 10 étoiles et les cartes prêtées disparaissent.

🔴 **POURQUOI** — la fiche du lot, acceptée le 27/09 (*« Oui ok »*) : *« les sbires sont les cartes nulles, c'est elles
qu'on a souvent en pack »* ; un premier ×10 donne surtout des sbires, d'où la garantie de 3 héros ; *« non »* aux cartes
prêtées. Maxim, 28/09 : *« Go »*. Et Maxim joue sans lire : une consigne de moins de huit mots, le reste grisé.

· **L'accueil** (`accueil.gd`, une couche au-dessus de tout) : après le cadeau du jour, l'onglet Atlas est montré du
  doigt (*« Ton premier pack t'attend »*), puis le ×10 devenu **« Premier pack · offert »** (*« Il est offert : ouvre-le ! »*) ;
  l'invocation ×10 se joue ; refermée, l'onglet Voyage (*« À toi de jouer ! »*), puis « Jouer » (*« Ton premier combat »*),
  et le guide du combat prend le relais. Le reste de l'écran s'assombrit et ne répond pas (un bloqueur percé : seul le
  trou laisse passer le doigt). Le décor est celui du guide du combat.
· **Le pack** (`GS.tirer_premier_pack`, `ouvrir_premier_pack`) : 10 cartes tirées comme au jeu, puis retouchées — un
  sbire cède sa place à un héros (tiré à ses chances : Héros, Mythe, Légende) jusqu'à 3 héros différents, un doublon à
  une carte nouvelle jusqu'à 5 différentes. Sur 1 000 packs (`test_tirage`) : la garantie toujours tenue ; 363 packs
  avec une Légende ; 873 avec un doublon — ça reste un tirage. L'écran des probabilités le dit.
· **Qui le reçoit** : une partie qui ne l'a jamais ouvert **et** a moins de 5 cartes (`premier_pack_du`) — les nouveaux
  joueurs, et un cousin qui n'aurait pas dépensé ses 10 étoiles. Une seule fois. Son premier deck, s'il était né
  incomplet, se recompose avec le pack.
· **Retirés** : le cadeau de départ (10 étoiles, 27/09) ; **les cartes prêtées** du deck composé tout seul et des decks
  enregistrés (une carte qu'on n'a pas quitte le deck). *Le premier combat guidé garde son deck scénarisé (le guide dit
  quelle carte poser où) : ce n'est pas un prêt, c'est le tuto.*

**Tests faits** : `test_cartes`, `test_carre`, `test_decks` (la carte prêtée d'avant quitte le deck), `test_aventure`,
`test_objets` (le pack : dû, ouvert, une fois ; 5 cartes → pas dû), `test_tirage` (1 000 packs), `verif_duels` :
`RESULTAT: OK` ; **`tests/capture_accueil`** : le tout premier lancement de bout en bout, dans le vrai jeu — 12
vérifications (le trou laisse passer le doigt, le reste non ; 0 étoile dépensée ; le premier deck valide) : OK ;
`capture_carre`, `capture_cartes` sans erreur. Déployé : `index.pck` servi à 8 h 36 (35 047 696 octets),
healthcheck `200`.

**Pas testé** : sur un téléphone neuf. Pour le revoir sur le tien, il faudrait une partie neuve (outil RAZ de la Nébuleuse,
réseau local) — elle efface ta collection.

### ✅ À tester
- [ ] Un cousin qui arrive : le cadeau du jour, puis « Ton premier pack t'attend » sur l'Atlas
- [ ] « Premier pack · offert » : le ×10 se joue sans étoile ; au moins 3 héros dedans
- [ ] Refermé : « À toi de jouer ! » sur le Voyage, puis « Jouer », puis le combat guidé
- [ ] Pendant l'accueil, toucher ailleurs ne fait rien
- [ ] Les probabilités : la phrase sur le premier pack

---

## ✅ **Le prismatique irisé, les étoiles lisibles, la légende de Saint Georges** — **EN PROD** *(28/09/2026, 0 h 11)*

**En clair.** Le prismatique retrouve de l'éclat : tout son cadre est en chrome irisé, et son nom brille. Les étoiles « ★ »
de l'Aventure s'affichent enfin sur le téléphone (elles sortaient en boîte). Saint Georges a sa légende de Mons ; le
Chinchin et l'Homme de feuilles, leurs nouvelles images.

🔴 **POURQUOI** — Maxim, 28/09 : *« les prismatiques sont trop sobres maintenant : le côté noir et le nom en blanc, on dirait
la carte de base avec un contour arc-en-ciel »* ; *« Golem, à côté du XVI, il y a un symbole bizarre ; je l'ai vu aussi
dans l'Aventure »* ; la légende de Saint Georges : la page de la Ville de Mons (« La légende dorée ») ; *« reupload les
images du Chinchin et de l'Homme de feuilles, j'ai mis à jour »*.

· **Le prismatique** (`carte_view.gd`) : le fond du cadre laisse passer la matière (alpha 0,6) — tout le cadre devient du
  chrome irisé, qui glisse avec la lumière ; le spectre à 0,45 ; le nom a un reflet irisé (`nom_irise.gdshader`,
  `teinte` 0,6), plus pâle que l'arc-en-ciel franc du full art. La hiérarchie tient : le full art reste au-dessus.
· **Le symbole bizarre** : Castoro n'a ni « ★ » ni les lettres en exposant (« ᵉ », « ʳ »). Sur le web, aucune police du
  système ne les remplace : une boîte. → **une police de secours d'un glyphe**, l'étoile, dessinée pour le jeu
  (`polices/Etoile.ttf`, `Style.SECOURS`, branchée sur toutes les polices) ; « XVIe » sans exposant dans la légende du
  Golem. 🔴 Et Castoro n'a plus le droit d'appeler les polices du système (`allow_system_fallback=false` dans ses
  `.import`) : **le PC montre désormais ce que montre le téléphone** — c'est pour ça que les captures ne voyaient rien.
· **La légende de Saint Georges** (`legendes.gd`) : d'après la Légende dorée racontée par la Ville de Mons — Silène en
  Libye, le dragon, la fille du roi, la ceinture.
· **Les images** du Chinchin (désormais en 2:3) et de l'Homme de feuilles, reconverties. Vignettes en v5.

**Tests faits** : `test_cartes`, `test_carre`, `test_decks`, `test_aventure`, `test_objets`, `test_tirage` : `RESULTAT: OK` ;
captures (repli système coupé) : l'étoile du Voyage, Saint Georges prismatique et son dos, le dos du Golem. Déployé :
`index.pck` servi à 0 h 11 (35 042 724 octets), healthcheck `200`.

✅ **Testé par Maxim sur son téléphone (28/09)** : *« oui c'est bien »* ; le prismatique : *« parfait »*.

### ✅ À tester — https://192.168.0.17:18443/
- [ ] Le Voyage, une terre : les « ★ » s'affichent (plus de boîte)
- [ ] Le Golem retourné : « au XVIe siècle », sans symbole
- [ ] Un prismatique (outils → « Prisma ») : cadre chrome irisé, nom irisé ; toujours sous le full art
- [ ] Saint Georges retourné : sa nouvelle légende
- [ ] Le Chinchin et l'Homme de feuilles : leurs nouvelles images

---

## ✅ **Les sbires dans les invocations, et les héros par rangs : Héros, Mythe, Légende** — **EN PROD** *(27/09/2026, 23 h 58)*

**En clair.** Les invocations donnent maintenant des sbires, bien plus souvent que des héros. Et les héros ont un rang :
les Légendes sont rares et plus fortes, mais pèsent plus lourd dans le deck. Au passage, un combat qui pouvait se figer
(très rarement) est corrigé.

🔴 **POURQUOI** — Maxim, 27/09 : *« lance les sbires et intègre-les dans les tirages, ils ont plus de chance de tomber que
les héros ; il faudrait aussi déterminer les héros en fonction de leur puissance et rendre plus difficile à avoir les plus
forts »*. Mesure faite (20 000 parties), les 31 héros gagnent entre 47 et 55 % : ils sont presque égaux, c'était voulu
(verrou c). Maxim a choisi, entre trois voies, **« plus fort mais plus lourd »**.

· **Les sbires** (`MoteurCarre.SBIRES`) : les 9 illustrés par Maxim entrent dans la collection — Chinchin, Homme de
  feuilles, Diable du Doudou, Esprit de foudre, d'eau, de feu, sylvestre, de roche, Feu follet. Un seul stade, poids 1, pas
  de niveau ni d'évolution, les 6 variantes (full art compris). Leurs images : `cartes/<id>-1.jpg` (800 × 1000) et
  `cartes/min/` (480 × 600), depuis `Cartes/Illustration/`. **Le Chinchin et l'Homme de feuilles** (Maxim et son papa) :
  17 de somme au lieu de 14 — au banc, 47,7 % et 48,1 %, devant les autres sbires (42 à 45,5 %), sous le héros le plus
  faible (48,5 %). Les 5 sans image (Farfadet, Draugr, Oni, Ondine, Raijū) restent des adversaires de l'Aventure ; ses
  sbires sont figés (`Aventure.SBIRES_AVENTURE`) : ses niveaux ne bougent pas pour eux.
· **Les rangs** (`MoteurCarre.RANGS`) : 8 Légendes (Thor, Loki, Bahamut, Quetzalcoatl, Anubis, Fenrir, Sun Wukong,
  l'Oiseau-Tonnerre), 11 Mythes (Cerbère, Kitsune, Nian, Minotaure, Roc, Ifrit, Baba Yaga, Golem, Wendigo, El Biète,
  Saint Georges), 12 Héros — classés par la stature du personnage (proposé par Claude ; « je te fais confiance là-dessus, on verra les retours des utilisateurs » (Maxim, 28/09)). Un Mythe :
  +1 à son chiffre le plus faible ; une Légende : +1 à ses trois plus faibles, et **pèse 1 de plus**. Au banc (decks de 14,
  20 000 parties) : Héros 52 %, Mythe 53 %, Légende 51 %, sbire 45 % — un deck de Légendes ne gagne pas à coup sûr. Le
  rang se lit en or en haut de la carte (Mythe, Légende), au dos, et sous la carte en grand.
· **Le tirage** (`GS.RARETES`, `tirer_carte`) : le rang d'abord — **Sbire 60 %, Héros 25 %, Mythe 11 %, Légende 4 %**
  (provisoire, D11) —, puis une carte du rang, puis la variante (inchangée). L'écran des probabilités montre les deux tables.
· **L'Atlas** : une rangée « Les sbires · n sur 9 » sous les héros ; un sbire en grand n'a ni LVL ni évolution. Chaque
  sbire a sa légende au dos (`legendes.gd`). Vignettes en v4.
· 🔴 **Le combat qui se figeait** (`MoteurCarre.poser`) : quand Anubis, retourné en pleine chaîne, reprenait une carte, elle
  restait dans la file et attaquait pour son nouveau camp — les deux camps se relançaient la chaîne **sans fin** (Cerbère en
  diagonale). Trouvé par le banc à la 17 610ᵉ partie ; la parité (400 parties) ne l'avait pas vu. Désormais une carte qui a
  changé de camp n'attaque plus. Même correction dans le moteur web, et la parité régénérée (3 996 coups identiques).
· **Le deck composé tout seul** (`VoyageEcran.deck_auto`) essaie chaque carte à chacun de ses stades : une Légende
  rabaissée d'un stade vaut mieux que laissée dehors. **Le fabricant de niveaux** (`Aventure._ajuster`) a une seconde passe
  (tous les remplaçants, un héros pour un autre) quand la première reste trop loin de la force visée.
· **Les bancs** : `tests/banc_cartes` (la puissance de chaque carte ; `poids` : des decks de collection, par rang).
  `test_tirage` devient une scène (il passe par le moteur) et vérifie les rangs par le vrai chemin (200 000 cartes, écart
  < 0,13 point).

**Tests faits** : `test_cartes`, `test_carre` (parité), `test_decks` (+ les rangs), `test_aventure`, `test_objets`,
`test_tirage`, `verif_duels` : `RESULTAT: OK` ; `banc_aventure` : 90 % à la 1ʳᵉ terre, 45 % à la 10ᵉ (la courbe tient) ;
`capture_carre` et `capture_cartes` sans erreur. Déployé : `index.pck` servi à 23 h 58 (35 049 188 octets), healthcheck `200`.

**Pas testé** : sur le téléphone. ⚠️ **Un deck enregistré avec des Légendes peut devenir trop lourd** (elles pèsent 1 de
plus) : « Combattre » s'éteint et dit « Trop lourd : 15 / 14 » ; il suffit de baisser un stade dans Mes decks.

### ✅ À tester — https://192.168.0.17:18443/
- [ ] Atlas → « Les probabilités » : la carte (Sbire 60 %, Héros 25 %, Mythe 11 %, Légende 4 %), puis sa variante
- [ ] Une invocation ×10 : surtout des sbires, avec leur illustration
- [ ] Atlas, en bas : la rangée « Les sbires » ; un sbire en grand : « Pas de niveau pour un sbire », sa légende au dos
- [ ] Une Légende (Thor, Loki…) : « LÉGENDE » en or en haut de la carte, au dos, et sous la carte en grand
- [ ] Mes decks : un sbire se met dans un deck (poids 1) ; une Légende pèse 1 de plus
- [ ] Un combat de l'Aventure : rien ne change pour toi, sinon les chiffres des Mythes et Légendes

---

## ✅ **La carte en 3D, son dos qui raconte, et le full art qui passe devant le prismatique** — **EN PROD** *(27/09/2026, 22 h 24)*

**En clair.** Dans l'Atlas, la carte en grand se tourne du doigt, comme une vraie carte qu'on tient : elle s'incline et
joue dans la lumière ; tournée jusqu'au bout, elle montre son dos, qui raconte sa légende et explique son pouvoir. Le
prismatique est plus discret, et le nom d'un full art est écrit en arc-en-ciel qui défile.

🔴 **POURQUOI** — Maxim, 27/09 : *« faudra juste que leur pouvoir soit lisible quelque part »* ; puis, sur la fiche (toucher
pour retourner) : *« non, pas toucher la carte : on peut la faire bouger avec son doigt, donc une carte en 3D ; je
relirai dans le jeu les textes »*. Et une remarque qu'on lui a faite : *« la prismatique tape plus à l'œil que la full
art »* → *« oui top, juste le nom du héros doit bien être en couleur arc-en-ciel qui bouge »*.

· **La carte en 3D** (`carte_3d.gd`, `cartes/shaders/carte_3d.gdshader`) : la carte et son dos sont dessinés à plat dans
  deux SubViewports ; un shader les pose sur un plan qui tourne, en perspective (un rayon par pixel). Glisser : le tour
  suit le doigt (la largeur de la carte = un demi-tour), la bascule haut / bas jusqu'à ~20°. Lâcher : la carte retombe
  sur la face la plus proche, ou, lancée d'un geste vif, sur la suivante. La lumière de la carte (holo, reflets, chrome)
  suit l'inclinaison. Au repos, elle respire à peine. Seule la face visible se redessine. Un toucher sans glisser ouvre
  toujours le plein écran ; une carte qu'on ouvre se présente de face.
· **Son dos** (`dos_info.gd`) : sur le dos de sa variante, un panneau : le nom, la forme, rôle · type · pays, **la
  légende** (`legendes.gd`, 31 héros, 2-3 phrases tirées du vrai folklore — **à relire par Maxim**), **le pouvoir**
  (emblème, nom, quand, effet — la même phrase que la bande du combat, `MoteurCarre.texte_pouvoir`), ou « Pas de pouvoir :
  ses chiffres sont un peu plus hauts » (`MoteurCarre.sans_pouvoir`, commun au combat désormais).
· **Le prismatique** : bord 2,2 u (au lieu de 3,8), chrome plus sombre, spectre 0,35, lueur 0,16. 🔴 La lumière de la carte
  réimposait un spectre de 0,6 à 1,0 à chaque image, quel que soit le réglage : il suit désormais celui de la variante.
  Sa signature reste le holo sur l'illustration. Le nom irisé lui est retiré.
· **Le full art** : son nom en arc-en-ciel franc qui défile (`cartes/shaders/nom_arc.gdshader`).
· **Les vignettes de l'Atlas** passent en **v3** (refaites au premier lancement : le prismatique et le nom ont changé).

**Tests faits** : `test_cartes`, `test_carre`, `test_decks`, `test_aventure`, `test_objets`, `test_tirage` : `RESULTAT: OK` ;
un niveau entier par `capture_carre` sans erreur ; `capture_cartes` photographie la carte inclinée, le demi-tour, un dos
avec pouvoir (Thor) et sans (El Biète) — canevas du Voyage, rangées « Le prismatique plus discret » et « La carte en 3D ».
Déployé : `index.pck` servi à 22 h 24 (32 197 824 octets), healthcheck `200`.

**Pas testé** : sur le téléphone (le geste, la fluidité des deux SubViewports).

### ✅ À tester — https://192.168.0.17:18443/
- [ ] Atlas → toucher une carte : glisser le doigt de côté la fait tourner ; en haut / en bas, elle bascule
- [ ] La tourner jusqu'au bout : son dos, la légende et le pouvoir (relire les textes)
- [ ] Lâcher à mi-chemin : elle retombe sur la face la plus proche ; un geste vif la retourne
- [ ] Un toucher sans glisser : le plein écran s'ouvre toujours
- [ ] Un full art (outils → « Full art ») : le nom en arc-en-ciel qui défile ; un prismatique (« Prisma ») : plus discret
- [ ] Fluide pendant qu'on tourne la carte (sinon, le dire : deux cartes se dessinent à la fois)

---

## ✅ **La carte du Carré (v6) : les chiffres sur le cadre, le full art casse la fenêtre** — **EN PROD** *(27/09/2026, 21 h 53)*

**En clair.** Une seule carte, la même dans l'Atlas, dans la main et sur le plateau. L'image est dans une fenêtre, les
quatre chiffres sur le cadre, au milieu du côté qu'ils défendent. Le full art, lui, couvre toute la carte : on le
reconnaît enfin en combat.

🔴 **POURQUOI** — Maxim, 27/09 : *« on décide du design des cartes avant que je te donne les sbires, parce que là on tue
l'utilité des full art »*. En combat, la carte normale montrait l'illustration du nom jusqu'en bas, les chiffres posés
dessus : un full art n'y gagnait qu'une bande en haut (planche « Avant » du canevas). Et la carte de l'Atlas montrait
encore des PV/ATT et un ultime de La Poussée. Maxim a délégué le design (*« tu connais le jeu… trouve un design qui
marche »*), puis l'a validé sur les captures (*« Super je valide le nouveau design »*).

· **La carte** (`carte_view.gd`) :
  - l'image dans une fenêtre (76 × 90 u), le cadre autour ;
  - **les 4 chiffres sur le cadre** (`CarteView.PIERRES`, la seule liste des positions) : deux cartes voisines montrent
    leurs chiffres face à face, de part et d'autre de leur frontière ;
  - en bas, la plaque du nom (forme et stade), le type à gauche du chiffre du bas, le pouvoir à droite ; en haut, en
    petit, le rôle et le pays ;
  - **retirés** (ils venaient de La Poussée) : PV/ATT, ultime, ruban, numéro de collection, gemme ;
  - le full art : l'image sur toute la carte, les textes sur du verre.
· **Le combat** (`carre/carte_carre.gd`) : la carte du combat EST celle de l'Atlas ; elle ne fait plus que colorer ses
  pierres (jade / carmin) et montrer ses bonus.
· **L'Atlas** : les vignettes passent en **v2** (`vignettes.gd`) — refaites au premier lancement (l'écran « Préparation »
  quelques secondes), les anciennes photos effacées du téléphone. Le badge LVL de la vue en grand est épinglé sur le coin
  (au milieu, il cachait le chiffre du haut).
· **L'ancienne carte** : `design/archives/carte_v5/`. **La planche du design** : `tests/planche_design` (les 6 variantes,
  un sbire, un full art — en combat et dans l'Atlas, en 1080 px).

**Tests faits** : `test_cartes`, `test_carre`, `test_decks`, `test_aventure`, `test_objets` : `RESULTAT: OK` ; un niveau
entier joué par `capture_carre` (pose, duels, retournements, fin) sans erreur ; captures du vrai rendu : canevas du Voyage,
rangée « La carte du Carré ». Déployé : `index.pck` servi à 21 h 53 (32 178 576 octets), healthcheck `200`.

**Pas testé** : sur le téléphone.

### ✅ À tester — https://192.168.0.17:18443/
- [ ] Atlas : la première ouverture passe par « Préparation » quelques secondes, puis chaque carte a ses 4 chiffres
- [ ] Un full art (appui long sur « Nébuleuse » → « Full art » dans l'Atlas) : l'image sur toute la carte
- [ ] Toucher une carte : la vue en grand, le badge LVL sur le coin, rien ne cache le chiffre du haut
- [ ] Un combat : deux cartes voisines montrent leurs chiffres face à face ; le chiffre qui gagne enfle, le pouvoir s'anime
- [ ] Une invocation ×10 : les cartes se retournent avec leurs chiffres

---

## ✅ **La Nébuleuse allégée : des pièces un peu plus grosses, un tiers de moins** — **EN PROD** *(27/09/2026, 20 h 29)*

**En clair.** Les pièces sont 15 % plus larges, et il y en a un tiers de moins sur le plateau, qui reste bien fourni.
La physique coûte un tiers de moins : la machine devrait moins saccader, et moins tourner au ralenti.

🔴 **POURQUOI** — Maxim, 27/09 : *« ça saccade, c'est chiant »*. **La première vraie mesure au compteur**, sur son
téléphone : **33-35 images/s, pire image 40-47 ms, physique 16-18 ms à 333-356 pièces**. 60 pas de physique par
seconde demanderaient ~1 000 ms de calcul par seconde : le téléphone n'en faisait que ~34, **la machine tournait à ~57 %
de sa vitesse**. ⛔ Le « 60 images/s » écrit le 26/09 n'avait jamais été mesuré (il venait de « ça freeze plus »).
Maxim : *« on peut faire les pièces légèrement plus grosses et diminuer la quantité, c'est pas un souci — faut juste
que le plateau soit fourni »*.

· **Ce que le banc a appris** (`tests/sim_poussoir`, reproductible, PC) :
  - un solveur allégé (Jolt, 6 ou 4 itérations) : **aucun gain**, et la machine rend moins bien ; écarté ;
  - une physique à 30 Hz : **plus chère** par image (3,7-4,2 ms contre 2,3), la machine rend moins bien ; écartée ;
  - **ce qui coûte, c'est le nombre de pièces qui se touchent** : rayon 0,46 → ~215 pièces, 1,6 ms (−32 %) ;
    rayon 0,48 → ~198 pièces, 1,6 ms, mais deux fois plus d'objets gagnés.
· **Le réglage** (`pusher_screen.gd`) : `R_PIECE` 0,40 → **0,46** ; plafond 360 → **270**, départ 300 → **225** (÷ 1,32,
  l'aire d'une pièce) ; `GEO_VERSION` 10 → **11** — **le tas sauvegardé repart neuf** (de grosses pièces rechargées aux
  anciennes places s'emboîteraient : le piège du 20/09). La progression ne bouge pas.
· **L'effet sur l'économie** (à revoir avec ⑧, D11) : au banc, **9 objets gagnés en 3 minutes au lieu de 6** ; la
  machine rend 58-91 % des pièces qu'on lui donne (66-86 % avant).
· **Captures** (vrai rendu) : le plateau avant et après, bien fourni dans les deux cas.

**Tests faits** : `sim_poussoir` OK (0 hors jeu, 0 chevauchement, rechargé 215 sur 215) ; `test_objets` OK.

**Mesuré sur le téléphone** (20 h 31-20 h 32, au compteur) : **34 à 43 images/s, physique 12,1 à 14,3 ms à 253-264
pièces** (avant : 33-35 images/s, 16-18 ms à 333-356) — ~0,048 ms par pièce, comme le banc le prévoyait ; la machine en
porte plus qu'au banc (~215) parce que Maxim la nourrit plus vite. Maxim : *« ça va un peu mieux, c'est vivable, on garde
ça pour l'instant »*. **60 images/s ne sont pas atteintes sur le web** : dette D13.

**Les apps (décidé par Maxim, 27/09)** : on garde le web pour l'instant (les cousins jouent aussi sur PC ; l'un d'eux
joue en stream). Android et iPhone viendront par **Codemagic** (Maxim y a un compte, et ses comptes développeur Apple
et Android). *En natif, la physique devrait aller plus vite (du vrai code, plusieurs cœurs) — à mesurer au compteur
avant de sortir l'app, pas à supposer.*

---

## ✅ **Correctif : les animations gardent leur vitesse hors de la Nébuleuse** — **EN PROD** *(27/09/2026, 20 h 04)*

**En clair.** Au combat, dans l'Atlas et dans le Voyage, une carte se retourne toujours à la même vitesse, même si
le téléphone peine un instant. Avant, elle ralentissait avec lui.

🔴 **POURQUOI** — Maxim, 27/09 : *« ça saccade, dans la Nébuleuse et en plein combat : les cartes se flip mais à des
vitesses différentes, des fois ça va vite, des fois c'est lent ; ça casse la dynamique »*.

· **La cause** : un seul pas de physique par image (`project.godot`), pour que la machine reste stable. Mais alors,
  quand une image dépasse 16 ms, **tout le temps du jeu** n'avance que de 16 ms : les animations ralentissent avec
  l'image (INFRA § pièges, 26/09).
· **Le correctif** (`main.gd` § `_regler_temps`) : 1 pas par image dans la Nébuleuse (inchangé), 8 ailleurs. Là, la
  machine est en pause (`pusher_screen` § `_visibilite`), aucune physique ne tourne : le temps suit la vraie horloge.
· **Le compteur d'images** (outils de test, réseau local seulement) s'affiche maintenant sur **tous les écrans, combat
  compris** : les images de la seconde, la pire image (en ms), l'écran. Pour mesurer où ça rame, au lieu de le supposer.

**Tests faits** : `tests/capture_carre` en vrai rendu — 8 pas au combat, dans le Voyage et dans l'Atlas, 1 dans la
Nébuleuse ; tout le parcours OK, zéro `SCRIPT ERROR`.

**Pas testé** : sur le téléphone. **Reste à mesurer** : pourquoi des images rament (la Nébuleuse, le combat) — avec le
compteur. Les saccades elles-mêmes (des images qui tardent) ne disparaissent pas avec ce correctif : seule la vitesse
des animations redevient régulière.

---

## ✅ **Le jeu s'ouvre aux cousins, derrière un code** — **EN PROD** *(27/09/2026, 19 h 21 — ⑯ ; Maxim est entré : « ok ça marche »)*

**En clair.** Les cousins ouvriront `https://jeu.naspoizot.synology.me`, taperont une fois un code de 5 mots, et
joueront, chacun sur son téléphone. Sans le code, rien du jeu ne sort. Le jeu de Maxim, sur son réseau, ne change pas.

🔴 **POURQUOI** — Maxim, 27/09 : *« je vais donner accès à mes cousins… il faut juste mettre un code… faut bien blinder
cette page d'accès pour éviter toute tentative d'intrusion sur le NAS / mon réseau, car j'ai Vesta, le jeu et d'autres
projets importants »*. Fiche acceptée : un code unique pour tous ; l'ancienne règle `naspoizot.synology.me` (502) coupée ;
chacun sa partie sur son téléphone, pour l'instant.

· **Le portier** (`portier/`) : nginx (non root) sert le jeu SEULEMENT avec le cookie ; un petit service Python
  (sans dépendance) vérifie le cookie et le code. Le code : 5 mots au hasard ; seule son empreinte est sur le NAS ;
  le cookie est signé, valable 90 jours ; changer le code met tout le monde dehors. Le détail : INFRA § Le jeu PUBLIC.
· **Le blindage** : essais freinés (5/min), adresse bloquée après 10 échecs, entrée fermée pour tous après 50 ;
  conteneurs isolés, en lecture seule, sans privilège ; n'écoute que sur 127.0.0.1 ; en-têtes de sécurité.
· **Les outils de test** (D1, D4) ne s'ouvrent plus que depuis le réseau local (`main.gd` § `outils_permis`).
· **La page du code** dit aux cousins où vit leur partie (et d'installer le jeu sur l'écran d'accueil, sur iPhone).

**Actions manuelles (Maxim)** : la règle du proxy inversé dans DSM (et son en-tête `X-Real-IP`), couper l'ancienne
règle, vérifier la box (443 seulement), le blocage automatique et la double authentification de DSM,
`docker compose up -d` dans `portier/`. Puis Claude lance `portier/verifier_dehors.py`.

**Tests faits** : `portier/test_portier.py` — 30 vérifications, `RESULTAT: OK` (cookie juste / expiré / retouché /
d'une autre clé ; code juste en majuscules et tirets / faux ; blocage d'une adresse, puis de tous ; corps trop gros ;
méthodes ; la page ne recopie rien de ce qu'on tape ; le journal ne garde pas les codes tapés). Le vrai secret accepte
le code et refuse un mot faux. Le jeu local réexporté (outils verrouillés hors réseau local) : `200`.

· **Les deux pannes du premier essai** (corrigées) :
  - 🔴 **la box envoie le 443 public vers le port 8443 du NAS** (règle VOO « 443 → 8443 »), pas vers 443. L'ancienne
    règle `naspoizot.synology.me` écoutait sur 8443 ; supprimée, plus rien n'y répondait (« connection refused »).
    La règle `jeu.naspoizot.synology.me` écoute donc sur **8443** ;
  - nginx écrivait ses redirections en entier, avec SON port (`http://…:8080/entree`) : `absolute_redirect off`.
    Le script de dehors acceptait toute redirection finissant par `/entree` : il l'aurait laissée passer ; il exige
    maintenant `/entree` exactement.
· **Le cadeau de départ** (Maxim : *« il faut donner 10 tickets ou faire une invocation au début du jeu, sinon on
  n'a pas de carte »*) : une partie sans aucune carte, qui ne l'a jamais reçu, passe à **10 étoiles** (une
  invocation ×10), une seule fois (`GS.cadeau_de_depart`, `voyage.cadeau_depart`). Provisoire : le lot « premier
  pack offert » le remplacera par le mini tuto. En ligne à 19 h 21 ; `tests/test_objets` : ses 3 témoins, OK.

**Vérifié de dehors** (`portier/verifier_dehors.py`, par le vrai chemin, le vrai certificat) : 31 vérifications,
`RESULTAT: OK` — sans le code, aucun fichier du jeu ne sort (ni le secret) ; le manifeste et l'icône, oui ; les
en-têtes ; PUT et DELETE refusés ; un code faux refusé ; les essais rapprochés freinés (429) ; le bon code donne le
cookie (Secure, HttpOnly, SameSite) ; avec lui, le jeu est servi.

**Pas testé** : en 4G par un cousin ; l'installation en app sur iPhone ; que le portier voit bien l'adresse de chaque
visiteur (le journal du portier doit montrer des adresses publiques, pas 172.x — sinon l'en-tête `X-Real-IP` manque).

---

## ✅ **Mes decks : tu composes tes decks toi-même** — **EN PROD** *(27/09/2026, 18 h 22 — sorti de l'étape 3)*

**En clair.** Avant le combat, « Changer » ouvre **Mes decks** : jusqu'à 6 decks. On touche un deck pour le choisir,
et c'est lui qui combat. « Modifier » ouvre l'éditeur : on touche une carte de sa collection pour l'ajouter, on
touche une carte du deck pour régler son stade et sa variante, ou pour la retirer.

🔴 **POURQUOI** — Maxim, 27/09, après la 1ʳᵉ terre : *« je pouvais pas faire mon propre deck, donc j'ai joué avec celui
imposé »*. La fiche d'alignement est acceptée (« Oui ok ») : on peut jouer une carte en dessous de son stade pour
alléger le poids, et le premier deck est le deck automatique.

· **La logique** (`carre/decks.gd`) :
  - 6 decks au plus, il en reste toujours un ; 5 cartes, poids 14 au plus ;
  - **une carte ajoutée entre au stade le plus haut qui tient dans le poids** ; trop lourde, en double ou une
    6ᵉ, elle est refusée, et une bulle dit pourquoi (« Trop lourd : 16 / 14 ») ;
  - le stade se règle de I à celui qu'on a atteint ; la variante, parmi celles qu'on possède ;
  - **la sauvegarde** (`voyage.decks`) est relue avec prudence : une carte inconnue ou pas à toi part, un stade
    trop haut redescend, une variante qu'on n'a pas redevient celle qu'on affiche.
· **L'écran** (`carre/decks_ecran.gd`) :
  - **la liste** : chaque deck avec ses 5 cartes, son poids, « CHOISI » ou « INCOMPLET », et « Modifier » ;
  - **l'éditeur** : les 5 places, la jauge du poids, les réglages de la carte touchée juste en dessous (pas de
    fenêtre qui s'ouvre), « Composer tout seul » (le plus fort sous 14), « Supprimer ». La collection défile au
    doigt, et se construit quelques cartes par image pour ne pas geler ;
  - tout au toucher, **aucun nom à taper** (les decks s'appellent Deck 1, Deck 2…).
· **Avant le combat** : « TON DECK · DECK 1 », son poids, « Changer ». **« Combattre » s'éteint si le deck est
  incomplet ou trop lourd**, et dit pourquoi quand on le touche.
· **Les cartes prêtées** (collection de moins de 5 cartes) restent possibles jusqu'au prochain lot, où elles
  disparaîtront au profit des sbires et du premier pack offert.

**Actions manuelles** : aucune.

**Tests faits** :
- `tests/test_decks` : 32 vérifications, `RESULTAT: OK` (chaque règle avec ses deux témoins) ;
- `tests/test_aventure`, le banc de parité : OK ;
- `tests/capture_carre` en vrai rendu : la liste, l'éditeur, une carte réglée ; une carte retirée (« Combattre »
  s'éteint), puis remise **par un vrai toucher dans la collection qui défile** ; c'est bien le deck choisi qui
  combat. `RESULTAT: OK`, zéro `SCRIPT ERROR`.

**À tester sur le téléphone** :
- [ ] Avant le combat → Changer → Mes decks : Deck 1 est là, choisi.
- [ ] Modifier : toucher une carte de ta collection → elle entre ; trop lourde → la bulle le dit.
- [ ] Toucher une carte du deck : stade I/II/III (jusqu'au tien), variante, Retirer ; la jauge suit.
- [ ] Faire défiler ta collection au doigt : fluide, et un toucher n'ajoute pas une carte par erreur.
- [ ] Un deck à 4 cartes : Combattre éteint, il dit pourquoi.
- [ ] Nouveau deck, le choisir, combattre : c'est bien lui qui joue.
- [ ] Fermer l'app, la rouvrir : tes decks et ton choix sont là.

**Pas testé** : sur le téléphone (la fluidité de l'éditeur avec toute ta collection, surtout).

---

## ✅ **L'Aventure : 10 terres, 100 combats, des ★ et des coffres** — **EN PROD** *(27/09/2026, 15 h 36 — étape 2 de ⑱, « go » de Maxim sur les captures)*

**En clair.** Le Voyage devient une Aventure : 10 terres de légendes et 10 niveaux dans chacune, le 10ᵉ étant
son boss. Chaque niveau rapporte jusqu'à 3 ★, et les ★ ouvrent les coffres de la terre. Un niveau est toujours le
même, sans aucun hasard, et on voit tout le deck de l'adversaire avant de combattre.

🔴 **POURQUOI** — la fiche d'alignement de l'étape 2, acceptée par Maxim le 27/09 (« Go ») ; DECISIONS du 26/09 (le Voyage).

· **Les écrans** (`carre/voyage_ecran.gd`, `chapitre_ecran.gd`, `avant_combat.gd`, `dessin.gd`) :
  - **le Voyage** : le prochain combat en grand (« Continuer »), puis les 10 terres, chacune avec son boss dans
    un médaillon, ses ★ et son état (en cours, terminée, ou scellée avec le nom du boss à battre) ;
  - **une terre** : ses 10 niveaux sont les étoiles d'une constellation, du 1ᵉʳ en bas au boss en haut.
    Une étoile gagnée est d'or et porte ses ★ ; la prochaine bat, entourée des anneaux de jade du guide ;
  - **ses 3 coffres**, montrés par ce qu'ils donnent : à 10 ★ une pierre de la terre, à 20 ★ une étoile
    d'invocation, à 30 ★ deux étoiles et une lune. On les ouvre du doigt, et le gain s'envole jusqu'au bandeau ;
  - **avant le combat** : l'adversaire, tout son deck, la règle du niveau (ses terres), les 3 ★ à gagner, la
    récompense de la 1ʳᵉ victoire, ton deck. Un boss dit sa réplique ;
  - **la fin d'un niveau** : les ★ s'allument une à une, les gains volent jusqu'au bandeau, puis « Niveau
    suivant », « Rejouer » ou « La terre ». **La victoire parfaite** (les 9 cartes à toi) relie les cartes par
    une constellation d'or, pour la gloire.
· **Les niveaux** (`carre/aventure.gd`) :
  - **les 10 boss** sont écrits à la main (leur cour, leur réplique, leurs terres) ; **les 90 autres niveaux**
    sont fabriqués à partir de leur numéro ;
  - **la difficulté** monte avec l'ordinateur (Apprenti pour la 1ʳᵉ terre, Aventurier jusqu'à la 4ᵉ, Maître
    ensuite) et avec **la force** du deck adverse (la somme de ses chiffres, et 2 par pouvoir) ;
  - **les ★** : gagner, gagner avec 6 cartes ou plus, et un défi (garder sa 1ʳᵉ carte, retourner celle du chef,
    faire une chaîne, en retourner 3 d'un coup). La 1ʳᵉ terre n'a pas le défi « 3 d'un coup » ;
  - **les récompenses** (provisoires, D11) : la 1ʳᵉ victoire d'un niveau donne 30 + 10 × terre de poussière,
    un boss 3 étoiles d'invocation. Rejouer ne rapporte que les ★ qui manquent.
· **Écart à la fiche, accepté par Maxim** : la 3ᵉ ★ d'un boss est « Retourne la carte de <boss> », et non la victoire
  parfaite. Au banc, un joueur moyen réussit la victoire parfaite contre un boss 0 à 7 % du temps, et le coffre
  de 30 ★ serait hors d'atteinte. Le boss commence toujours, pour qu'on puisse retourner sa carte.
  🔄 *Le texte disait d'abord « Prends la carte de… » : Maxim l'a lu comme une carte donnée en récompense
  (« je vois pas l'intérêt de donner la carte si elle est dispo dans les packs »). Rien n'est donné, les cartes ne
  viennent que des invocations. D'où « Retourne », comme les autres défis.*
· **Mesuré au banc** (`tests/banc_aventure`, 80 parties par niveau, joueur moyen) — la moyenne par terre : 90 %,
  83 %, 80 %, 76 %, 63 %, 60 %, 61 %, 52 %, 45 %, 50 % ; les boss : 67 %, 52 %, 50 %, 52 %, 43 %, 38 %, 51 %, 48 %,
  45 %, 47 % ; un débutant qui joue au hasard gagne 43 à 100 % des niveaux de la 1ʳᵉ terre. Aucun niveau sous 15 %.
· **Le deck** reste composé tout seul (le plus fort sous le poids 14), jusqu'à « Mes decks » (étape 3).
· **Retirés** : le combat d'essai contre trois adversaires (Wukong, Thor, Cerbère deviennent des niveaux), et son
  banc (`tests/banc_carre`).
· **Sauvegarde** : une clé de plus (`voyage.aventure`), lue avec prudence. Une ancienne sauvegarde démarre
  l'Aventure à zéro ; le combat guidé déjà fait reste fait.

**Actions manuelles** : aucune.

**Tests faits** :
- `tests/test_aventure` : 3 103 vérifications, `RESULTAT: OK` ;
- le banc de parité (400 parties) et `tests/verif_duels` : OK ;
- `tests/capture_carre` en vrai rendu, trois parcours (un niveau, le boss Fenrir, le combat guidé) : OK, zéro
  `SCRIPT ERROR`. Il vérifie qu'un coffre ne s'ouvre qu'une fois, que « Combattre » lance le bon niveau, que les ★
  sont enregistrées, que le niveau suivant s'ouvre et que « La terre » y ramène.

**À tester sur le téléphone** :
- [ ] Voyage : le prochain combat, les 10 terres (la 1ʳᵉ ouverte, les autres scellées).
- [ ] Une terre : la constellation, l'étoile qui bat, un niveau scellé qui dit pourquoi.
- [ ] Avant le combat → Combattre → gagner : les ★ s'allument, la poussière vole jusqu'au bandeau.
- [ ] Rejouer un niveau déjà gagné : rien de plus, sauf une ★ nouvelle.
- [ ] 10 ★ dans une terre : le coffre s'ouvre, la pierre s'envole ; une 2ᵉ fois, rien.
- [ ] Battre le boss : +3 étoiles, la terre suivante s'ouvre.
- [ ] Fermer l'app en pleine terre, la rouvrir : ★ et coffres sont là.
- [ ] 60 images/s sur la constellation.

**Pas testé** : sur le téléphone ; la difficulté ressentie par un vrai joueur (le banc joue comme l'Aventurier).
**Déployé** : le NAS sert le nouveau paquet (32,2 Mo, 15 h 36) ; le `.wasm.gz` est du même export.

---

## ✅ **Correctif : Korrigan, Ifrit et Anansi cassaient la carte du combat** — **EN PROD** *(27/09/2026, 9 h 46)*

**En clair.** Ces trois héros n'ont qu'une forme. Le combat les compte comme un stade III, mais la carte cherchait
alors leur 3ᵉ illustration, qui n'existe pas, et son dessin plantait. S'ils entraient dans ton deck
automatique, le Voyage cassait. La carte dessine maintenant leur vraie forme, et leur force reste celle d'un stade III.

· Trouvé par `tests/test_aventure` (27/09), qui vérifie désormais, pour chaque héros à chaque stade, que
  l'illustration à dessiner existe (`CarteCarre.forme_de`).

**Actions manuelles** : aucune.

---

## ✅ **Chaque duel montre les chiffres qui se battent vraiment** — **EN PROD** *(27/09/2026, 9 h 11 — correctif)*

**En clair.** Pendant un duel, les deux chiffres montrés sont maintenant ceux qui ont combattu. Avant, l'écran
montrait d'emblée les chiffres de la fin du coup. Une carte prise à côté de Bahamut y avait déjà gagné sa
Marée, et un 6 contre 5 s'affichait « 6 contre 6 ».

🔴 **POURQUOI** — Maxim, 27/09, sur le téléphone : *« j'ai utilisé Bahamut contre Yéti, il avait moins de points
et ça a retourné ma carte quand même »*.

· **Le diagnostic** (`tests/verif_duels`, 1 500 parties, 9 425 retournements) :
  - **le moteur est juste** : c'est celui du web, et les 99 fois où le Yéti prend Bahamut étaient toutes
    prévisibles d'après les chiffres affichés ;
  - **l'écran mentait dans 354 duels (4 %)** : il affichait la fin du coup dès la pose. Les causes : **la
    Marée de Bahamut**, qui suit la carte quand elle change de camp, **la Faim de Fenrir** et **Anubis**.
· **Le correctif** :
  - le moteur note, sur demande de l'écran, l'état du plateau après la pose puis après chaque événement
    (`MoteurCarre.poser(…, trace)`). Ses calculs ne changent pas : la parité avec le web tient ;
  - l'écran suit cette trace pas à pas (`carre_ecran._animer`). Le duel montre les deux vrais chiffres,
    puis la conséquence arrive après le retournement, par exemple la carte prise qui gagne sa Marée en or.
· **Ce qui reste normal, et se voit** : une chaîne (« En chaîne ! »), une terre (« +1 Nature »), les pouvoirs
  de Thor, Loki et Fenrir. Seuls les deux chiffres qui se touchent comptent.

**Actions manuelles** : aucune.

**Tests faits** :
- `tests/verif_duels` : l'ancien affichage contredit **354** duels (le témoin), le nouveau **0** ;
- le banc de parité (400 parties) : OK ;
- trois combats en vrai rendu (`tests/capture_carre`, dont le combat guidé) : OK, zéro `SCRIPT ERROR`.

**À tester sur le téléphone** :
- [ ] Un combat avec Bahamut dans ton deck : quand tu prends une carte collée à lui, le duel montre le vrai
      chiffre, puis la carte prise passe en or (+1).
- [ ] Quand ta carte est prise, le chiffre adverse montré pendant le duel est plus grand que le tien.

---

## ✅ **Le Carré des astres est dans le jeu : on joue au doigt, en glissant ses cartes** — **EN PROD** *(27/09/2026, 8 h 42 — étape 1 de ⑱, « go » de Maxim)*

**En clair.** Le Voyage s'ouvre dans la barre du bas. On y joue au Carré des astres contre trois
adversaires. On **fait glisser une carte de sa main jusqu'à une case du tapis** (ou on touche la carte,
puis la case). Le tout premier combat est guidé, pas à pas.

🔴 **POURQUOI** — la fiche d'alignement acceptée le 27/09 (« Go ») : on construit le Carré dans le vrai jeu,
en trois étapes (① le Carré jouable, ② l'Aventure, ③ Mes decks + Duel + Classé). Puis Maxim, en disant go
pour le déploiement : *« fais juste en sorte qu'on puisse drag and drop les cartes sur le tapis »*.

· **Le Carré** (`proto_degagement/carre/`) :
  - le moteur (`moteur_carre.gd`), repris de la v2 web : 400 parties rejouées coup par coup, 3 996 coups identiques ;
  - la carte du combat (`carte_carre.gd`) : la carte de l'Atlas et ses variantes, 4 chiffres en croix
    dans des pierres (jade : les tiennes, carmin : les siennes), l'emblème de son pouvoir ;
  - l'écran (`carre_ecran.gd`) : le tapis, le score, la bande qui dit ce qui se passe (ou le pouvoir de la
    carte touchée), la pose, le duel des deux chiffres, le retournement ;
  - le guide du premier combat (`guide_carre.gd`) : des cartes prêtées, un voile avec un trou sur ce qu'il
    faut toucher, une consigne de moins de 8 mots, un retournement dès le 2ᵉ coup ;
  - les images viennent de la fabrique `design/objets/render_carre.py` : le tapis, les cadres de case, les
    pierres des chiffres, les 10 emblèmes.
· **Le Voyage d'essai** (`voyage_ecran.gd`) : trois adversaires, **Wukong** (Apprenti), **Thor** (Aventurier) et
  **Cerbère** (Maître). Ton deck se compose tout seul avec tes 5 cartes les plus fortes (poids ≤ 14) ; s'il en
  manque, on t'en prête. Les sbires montrent leur pierre, faute d'illustration.
· **Le glisser-déposer** (ajouté ce matin) :
  - la carte prise **reste sous le doigt à l'endroit où on l'a prise**, sans saut ni recul. Avant, la main se
    rangeait en même temps et tirait la carte vers sa place pendant 0,22 s ;
  - **la case où elle tomberait s'allume en plein** (les autres cases libres respirent), la carte grandit
    au-dessus d'elle, et le téléphone vibre un petit coup ;
  - **pas besoin de viser au pixel** : la case la plus proche du centre de la carte est prise, jusqu'à 60 px
    hors de la case ;
  - lâchée ailleurs, la carte revient dans la main ;
  - dans le guide, la consigne devient « **Glisse cette carte** », la carte glissée passe au-dessus du voile,
    et une carte lâchée à côté fait revenir le guide sur elle (avant, il restait sur la case).
· **Mesuré au banc** (`tests/banc_carre`) : un débutant qui joue au hasard bat l'Apprenti 78 % du temps, un
  joueur moyen 90 %.

**Actions manuelles** : aucune (le volume du NAS est monté en direct).

**Tests faits** :
- le banc de parité (400 parties) : `RESULTAT: OK` ;
- `tests/capture_carre`, en vrai rendu, avec de vrais événements de doigt : un glisser vers une case la pose,
  un glisser lâché sur la bande ramène la carte et le guide ; un combat normal et le combat guidé joués
  jusqu'au bout ; `RESULTAT: OK`, zéro `SCRIPT ERROR` ;
- le NAS sert le nouveau paquet (32,1 Mo, 8 h 42) et le `.wasm.gz` du même export.

**À tester sur le téléphone** :
- [ ] Voyage (barre du bas) → un combat : le premier est guidé. Suivre le guide jusqu'au bout.
- [ ] Glisser une carte : elle reste sous le doigt, sans saut ; la case visée s'allume, le téléphone vibre.
- [ ] La lâcher entre deux cases, ou un peu à côté : elle tombe dans la plus proche.
- [ ] La lâcher sur la bande ou dans la main : elle revient.
- [ ] Toucher une carte, puis une case : ça marche toujours.
- [ ] Un combat contre chacun des trois, jusqu'à l'écran de fin ; Rejouer, puis Retour.
- [ ] Dire si le mouvement est fluide (60 images/s) pendant qu'on glisse et pendant un retournement.

**Pas testé** : sur le téléphone (le seul banc valable) ; la vibration (le PC n'en a pas).

---

## 🧪 **Le Carré des astres v2 : les cartes, les decks, trois niveaux** — **prototype web, PAS dans le jeu** *(26/09/2026, nuit)*

**En clair.** Le Carré se joue en 3×3, avec ses decks, des cartes qui montrent leurs variantes, des pouvoirs
qu'on voit, et un ordinateur à trois niveaux. Le 4×4 devient un événement.

🔴 **POURQUOI** — Maxim, sur la v1 : *« on repart sur du 3×3 et on fait des events 4×4 de temps en temps ;
le pouvoir du Yéti est beaucoup trop fort ; l'ordi ne fait aucune mauvaise décision, je suis nouveau, je
tombe sur cette IA, je désinstalle ; revoir les cartes : c'est là que les gens sont contents d'utiliser
leur full art, prismatique… ; le plateau dans la DA ; une page pour créer des decks ; les pouvoirs, il faut
qu'on les voie et qu'on sache de quoi il s'agit »*.

· **La carte** (`src/c2_carre3.js` § `carte`, `.css` § variantes) :
  - le format 5:7 ;
  - les **4 chiffres en croix dans le coin** (comme Triple Triad), pour que l'illustration reste entière ;
  - les **six variantes** avec les palettes du jeu (`carte_view.gd`) : l'or et son reflet, l'ombre
    graphite et sa brume, l'élémentaire aux couleurs du type et ses particules, le prismatique chrome et
    son holo, le **full art** plein cadre et son arc-en-ciel qui tourne ;
  - des images en 400 px (`img/hd/`).
· **Les pouvoirs visibles** : une icône nette par pouvoir (10 dessins vectoriels) sur la carte. Une **fiche**
  s'ouvre quand on touche une carte : son nom, quand il agit, ce qu'il fait, ce qu'il devient au stade III.
  En partie, chaque pouvoir qui se déclenche s'annonce, avec son icône.
· **Les decks** : une page « Mes decks » (6 au plus). L'éditeur a sa collection, des filtres (type,
  pouvoir, sbires) et la jauge de poids (5 cartes, **poids 14 au plus**) ; on y règle le stade et la
  variante d'une carte. On choisit son deck avant la partie.
· **Le plateau** : une plaque de nuit cerclée d'or, avec un astrolabe en filigrane. **Chaque retournement
  trace un trait d'or** entre les deux cartes.
· **Les règles** :
  - le 3×3 par défaut ;
  - **l'événement « Grand Carré »** en 4×4, avec un gouffre et 3 renforts dans chaque main ;
  - **Yéti** : il ne bloque plus toutes les attaques autour de lui ; à la pose, il gèle **une case vide**
    (deux au stade III), où l'adversaire ne peut pas poser à son prochain tour ;
  - **Thor** passe de +2 à +1 ;
  - **Loki** copie, moins 1 ;
  - **Fenrir** : +2 au plus ;
  - **Kitsune** et **Bahamut** gagnent +1.
· **L'ordinateur** : trois niveaux.
  - **Apprenti** : souvent au hasard.
  - **Aventurier** : le meilleur coup immédiat, sans voir plus loin.
  - **Maître** : il prévoit ta réponse.
· **Mesuré au banc** :
  - **les niveaux** : un joueur moyen gagne 86 % contre l'Apprenti, 57 % et 45 % contre les deux
    Aventuriers, 38 % contre le Maître ; **un débutant qui joue au hasard bat l'Apprenti 73 % du temps** ;
  - **les cartes** : 1 200 parties avec des decks au hasard de même poids donnent entre 44 % et 57 % de
    victoires par carte. Le Yéti rééquilibré est à 56 %, Kitsune et Bahamut étaient les plus faibles des
    cartes à pouvoir (46 % et 48 %) : d'où leur +1.
· **Tests** : la page des decks (créer, remplir, régler stade et variante, choisir) et une partie complète
  contre chacun des 5 adversaires, jouée au hasard jusqu'à l'écran de fin : aucune erreur.

**Pas testé** : sur le téléphone de Maxim ; l'équilibre des cartes après les derniers réglages (non remesuré).

---

## 🧪 **⑱ Le combat est choisi : le Carré des astres** — **prototype web, PAS dans le jeu** *(26/09/2026, nuit)*

**En clair.** Après 27 démos de combat jouées sur le téléphone, Maxim a choisi le **Carré des astres** : on
pose ses cartes sur une grille, le plus grand chiffre du côté qui touche retourne la carte d'en face, et
les retournements s'enchaînent. Sa v1 est jouable dans l'Arène d'essai.

🔴 **POURQUOI** — Maxim : *« j'ai vraiment accroché, rapide, fun et stratégique… il me rappelle Queen's
Blood… là on tient la base »*. Le pourquoi complet : `docs/reviews/DECISIONS.md` (quatre entrées du 26/09).

· **L'Arène d'essai** (https://claude.ai/artifact/2VwvtbPRojqsHKTvwjE3Ny, source `design/canevas/arene/`,
  refaite par `python build.py`). En haut, le Carré v1 ; en dessous, repliés, les 11 concepts « stratégie
  avant le combat », les 8 concepts de Maxim et les 8 premiers essais, tous avec un tuto guidé.
· **Le Carré v1** (`src/c1_carre2.js`) :
  - un plateau 4×4 avec 1 gouffre, ou 3×3 pour comparer ;
  - un deck de 10 cartes, les mains visibles, pas de pioche ;
  - les chaînes, et 3 terres (+1 à leur type) ;
  - **un pouvoir pour 10 héros** : Thor, Kitsune, Golem, Bahamut, Yéti, Loki, Anubis, Fenrir, Cerbère, Baba Yaga ;
  - le stade monte les chiffres (+3 au II, +3 au III) et renforce le pouvoir ;
  - **le poids du deck** : sbire 1, stade I 2, II 3, III 4, et 28 au plus ;
  - trois adversaires.
· **Mesuré au banc (l'ordinateur contre lui-même, même deck des deux côtés)** :
  - le 4×4 plein donnait **20 % de victoires au 1er joueur** (65 % au 2e) ;
  - avec **un gouffre**, soit un nombre impair de cases : **52 / 48**, sur 60 parties ;
  - le 3×3 : 50 / 50 ;
  - « poser 2 cartes au 1er tour » dessert le 1er joueur (21 %).
· **Tests** : 6 parties complètes (3×3 et 4×4, les trois adversaires, avec et sans tuto) jouées au
  hasard jusqu'à l'écran de fin, sans aucune erreur. Les 11 concepts « stratégie » : combats
  déterministes, et chaque adversaire a au moins une solution (vérifié sur des centaines de préparations).
· **L'analyse** : `docs/reviews/CARRE-DES-ASTRES.md`. **Les concepts écartés** : `docs/reviews/ANALYSE-TCG.md`,
  `docs/reviews/CONCEPTS-STRATEGIE.md`.

**Pas testé** : le Carré v1 sur le téléphone de Maxim ; l'équilibre des 10 pouvoirs (valeurs provisoires).

---

## ✅ **Les billes en vraies sphères, sans chevauchement** — **EN PROD** *(26/09/2026, 16 h 09 — validé sur captures, canevas v10)*

**En clair.** Les deux billes ne peuvent plus se dessiner l'une dans l'autre, et elles se lisent comme
de vraies sphères : rondes à l'écran, éclairées d'un côté, le voile qui tourne comme une planète.

🔴 **POURQUOI** — Maxim, 26/09, 15 h 53, sur le téléphone : *« bug, les deux se sont chevauchées ; ça fait
encore un peu effet image plate et pas vraie 3D »*.

· **Le chevauchement** : leurs corps étaient restés les disques plats d'avant (0,28), qui glissaient l'un
  sur l'autre sous les boules dessinées. Une bille a maintenant un corps **à sa taille** (aussi épais
  qu'elle est dessinée) et **qui ne penche pas** (`axis_lock_angular_x/z`) ; au rechargement, elle revient
  droite, à une hauteur libre. `tests/sim_poussoir` vérifie désormais qu'aucun objet n'en chevauche un autre.
· **La sphère telle qu'on la voit** (`bille.gdshader`) : la vue est oblique, une vraie boule s'y
  affichait en œuf ; la bille est un ellipsoïde aplati (`Volumes.APLATI` 0,42) au contour presque rond
  à l'écran, et sa normale est calculée **à l'écran**, comme celle d'une sphère parfaite.
· **Le voile en planète** (`render_objets.py`, `voile_bille`) : une carte déroulée (2 × 1), sans couture,
  enroulée par la longitude et la latitude, qui **tourne** (`tourne`) et passe derrière le bord pendant
  que l'objet reste au centre. Le volume plus marqué (l'ombre, le bord). La poussière franchement bleue.
· **Mesures** : `sim_poussoir` OK ×2 (0 chevauchement, 3 objets sur le tas), `test_objets` OK.

---

## ✅ **De vraies billes en 3D, des pièces de nouveau nettes** — **EN PROD** *(26/09/2026, 15 h 48 — validé sur captures, canevas v9)*

**En clair.** La poussière d'étoile et l'étoile d'invocation sont de **vraies billes en 3D** : la
poussière **bleu nuit** avec un tourbillon d'or au centre, l'étoile d'invocation **mauve** avec l'étoile
d'or au centre. Les pièces ont retrouvé leur relief (elles étaient devenues ternes), sans revenir aux
extrêmes.

🔴 **POURQUOI** — Maxim, 26/09 : *« maintenant les pièces ont l'air ternes, plus du tout HD »* ;
*« l'XP comme l'étoile d'invocation, on dirait des boîtes à médicaments ; il faut en faire des sphères,
transparentes, avec la poussière d'étoile dedans, et l'étoile d'invocation »* ; puis, sur la première
version : *« l'objet doit être plein centre, je ne veux pas d'une bille blanche, le voile mauve avec les
étoiles doit être sur toute la surface de la bille »* ; puis : *« là, ça fait une image ronde plutôt
qu'une vraie bille en 3D »* et *« la bille de poussière, pas mauve, on va confondre les deux »*.

· **Les pièces** : la cause de la matité — `adoucir` compressait la luminosité pixel par pixel, donc le
  relief aussi (contraste du relief mesuré : 0,078 → 0,052). Il garde maintenant 85 % du contraste
  (`garde_contraste`) ; les extrêmes ENTRE pièces sont tenus par la pente seule (`resserre` 0,3) ; le
  relief s'exprime un peu plus (`relief_vif` 1,1), les reflets nets aussi (`eclat` 0,9). Mesuré sur le
  tas : relief **0,079**, écart entre pièces **0,18** (0,27 avant les retouches).
  Mesures : `design/objets/mesure_pieces.py <capture>` (le lissé à la taille d'une pièce, et ce qui reste : le relief).
· **Les billes** (`objets/bille.gdshader`, `Volumes.bille_mesh`, `render_objets.py`, `bille_univers`) :
  une sphère un peu aplatie (0,62), au rayon du corps, pleine, en **deux couches** : le **voile**
  (`*-voile.png`, la nébuleuse) enroulé sur la sphère — lu par la normale, il se serre vers le bord —
  et qui tourne lentement ; l'**objet** (`*-coeur.png`) qui flotte au centre, plaqué dans l'axe de la
  caméra (la vue est oblique) et grossi par le verre. Puis le volume : l'ombre du côté opposé à la
  lumière, le bord plus sombre, la lumière qui ressort de l'autre côté (teintée), un Fresnel teinté, et
  le reflet de la fenêtre (un point vif, un arc le long du bord — une pastille ronde faisait « gommette »).
  Elle reste **droite** sur son corps. Le corps physique ne change pas : le jeu reste le même.
· **Les icônes** : le même modèle (l'icône et le jeu se ressemblent) ; la poussière bleu nuit, l'étoile
  mauve (Maxim : « on va confondre les deux »).
· **Mesures** : `test_objets` OK, `test_cartes` OK, `sim_poussoir` OK (3 objets sur le tas).

---

## ✅ **La bille d'invocation, des pièces resserrées, le bloc mauve** — **EN PROD** *(26/09/2026, 8 h 54 — validé sur captures, canevas v6)*

**En clair.** L'étoile d'invocation devient une **bille de verre** (une galaxie dedans, l'étoile d'or au
cœur). Les pièces n'ont plus d'extrêmes très clairs ou très sombres, mais gardent leur relief. Le
dessus du bloc n'est plus ivoire : c'est un **ciel mauve étoilé** (« Nébuleuse »).

🔴 **POURQUOI** — Maxim, 26/09, sur le téléphone : *« c'est super, ça freeze plus »* ; *« l'étoile
d'invocation, plutôt une bille transparente avec l'intérieur galaxie et l'étoile dorée au milieu »* ;
*« les pièces, il y en a certaines très claires et d'autres très sombres, faut garder le jeu de lumière
mais certaines c'est trop »* ; *« le poussoir en blanc, je trouve ça pas ouf »* → il a choisi *« le mauve »*.

· **La bille** (`render_objets.py`, `etoile_invocation`) : verre clair sans monture, galaxie violette et
  rose, étoile d'or du rituel au cœur, un croissant de lumière net au bord (la caustique : ce qui dit
  « verre »). Dans la machine : rayon 0,64, tranche de verre violet (`Volumes._tranche`).
· **Les pièces** (`corps.gdshader`, `metal2`) : le ciel reflété en deux parts — la **pente** de la pièce
  (sa normale d'ensemble) resserrée autour d'un gris moyen (`resserre` 0,55), le **relief** gardé entier
  (borné : plus de cernes noirs) ; un or un peu plus profond et saturé (`adoucir`). Mesuré sur le tas :
  écart de luminosité (5 %-95 %) **0,41 → 0,29**.
· **Le bloc** (`pusher_screen.gd`, `style_bloc`) : « nebuleuse » (`interface/bloc-nebuleuse.png`, rendu par
  `render_objets.py --blocs`), ancré sur la face avant ; « nuit », « jade » et « ivoire » restent pour
  comparer (`tests/capture_blocs.tscn`).
· **Mesures** : `test_objets` OK, `test_cartes` OK, `sim_poussoir` OK (3 objets sur le tas).

---

## ✅ **L'interface vivante (lot ⑮)** — **EN PROD** *(26/09/2026, 7 h 20 — validé sur captures par Maxim, canevas v5)*

**En clair.** Le jeu a son bandeau et sa barre de jeu vidéo, les objets gagnés **s'envolent** jusqu'à
leur compteur (plus de fenêtre « Gagné », la machine ne s'arrête plus), les boutons sont épais et
répondent au doigt, monter de niveau fait éclater « LVL » en or, et **évoluer est une scène en plein
écran** : la pierre en 3D, sa vibration, la poussière, le blanc qui s'évapore en poussière d'or.

🔴 **POURQUOI** — les choix de Maxim sur le canevas (25-26/09) : le bandeau « Constellations », la barre
« Médaillons » (noms « Céleste », la machine s'appelle **Nébuleuse**) ; *« plus de pop-up, on les voit
s'envoler jusqu'au menu en haut »* ; *« les boutons doivent être marquants »* ; *« LVL, c'est
international »* ; l'évolution *« juste géniale »*, sans étoile au dévoilement, le blanc qui s'évapore.

· **Le bandeau** (`bandeau.gd`) : étoiles, poussière, pierres ; des chiffres d'or cerclés de sombre qui
  défilent ; la case Pierres montre la dernière gagnée et ouvre la **bourse** (le compte de chacune).
· **La barre** (`barre_nav.gd`) : Nébuleuse · Astrolabe · Atlas · Voyage · Présages. Les emblèmes sont
  rendus en or (`render_objets.py --nav`). **Astrolabe, Voyage, Présages sont scellés** (cadenas, et ils
  disent quand ils s'ouvriront). L'appui long sur Nébuleuse montre les outils de test (D1).
· **Le vol** (`effets.gd`) : un objet gagné bondit et file vers son compteur en semant des étoiles
  nettes ; le compteur le reçoit (« +1 », étincelles). Une pièce file dans la réserve. L'objet revient
  sur le tas 1,4 s après.
· **Le cadre du bas** : la réserve et son anneau (la prochaine pièce), et **le plateau du jour** à la
  place du « Dernier gain » : les objets qu'il reste à gagner aujourd'hui (12, provisoire) — **compté et
  affiché seulement** ; le blocage, le nombre et le « + » (un plateau de plus) viennent avec ⑱.
· **Les boutons** (`Style.bouton`) : émail d'or ou sombre, avec leur tranche ; la face descend sous le
  doigt ; au lâcher, rebond et étincelles ; vibration courte (Android) ; un bouton éteint tremble et dit
  pourquoi.
· **Monter de niveau** : la poussière file dans la carte (plus le niveau coûte, plus il en entre) ;
  « LVL n » éclate en or puis se range dans le badge au-dessus de la carte. **« Niv. » devient « LVL »**.
· **Évoluer** (`evolution.gd`, `interface/evaporation.gdshader`) : la pierre du type, **en 3D** (le même
  volume que dans la machine), se pose, vibre 2 s, éclate ; carte blanche, étoiles filantes et
  constellations d'or ; le blanc s'évapore en poussière d'or. Toucher passe tout.
· **Corrigé — la pierre du fond pouvait disparaître** (version d'hier soir) : amincis à 0,18, les objets
  larges passaient parfois sous le sol. L'épaisseur physique revient à 0,28 (le dessin reste à 0,18), et
  un objet sorti du plateau sans être gagné revient sur le tas.
· **Mesures** : `test_objets` OK, `test_cartes` OK, `test_tirage` OK, `sim_poussoir` OK ×3 (3 objets
  toujours sur le tas) ; captures `tests/capture_poussoir.tscn`, **`tests/capture_gestes.tscn`** (nouveau :
  la fiche, le niveau, l'évolution image par image).

### ✅ À tester — https://192.168.0.17:18443/ (après le déploiement)
- [ ] Un objet gagné s'envole jusqu'au bandeau ; le compteur défile ; les pièces filent dans la réserve
- [ ] La barre du bas : Nébuleuse ↔ Atlas ; un menu scellé dit quand il s'ouvre
- [ ] Toucher « Pierres » : la bourse
- [ ] Monter une carte de niveau, puis la faire évoluer (toucher pour passer, puis pour fermer)

---

## ✅ **Les objets de l'univers, en 3D (lot ⑭)** — **EN PROD** *(25/09/2026, 23 h 58 — validé sur captures par Maxim)*

**En clair.** Les tickets deviennent des **étoiles d'invocation**, l'XP de la **poussière d'étoile**, les
éclats des **pierres** (une par type, et la pierre de lune qui remplace n'importe laquelle). Dans la
machine, ce sont de **vrais volumes** éclairés en direct comme les pièces. Une pièce tombée va dans la
réserve, et ne donne plus rien d'autre. Les pièces ont moins de reflets clairs.

🔴 **POURQUOI** — *« on ne fait pas des tickets d'invocation mais des étoiles d'invocation ; pour l'XP, de
la poussière d'étoile ; pour upgrader la carte, des pierres »* (24/09) ; *« mets-les bien en 3D, même
principe que les pièces (attention, les pièces ont toujours trop de reflet clair) »* ; *« les pièces ne
rajoutent pas d'XP, ça rajoute des pièces en réserve »* (25/09).

· **La sauvegarde v3** (`game_state.gd`) : `poussiere`, `etoiles`, `pierres` (type → nombre). Une
  sauvegarde plus ancienne est **convertie 1 pour 1** au chargement : tickets → étoiles, XP → poussière,
  éclats → pierres de lune. Personne ne perd rien (`tests/test_objets.gd`).
· **L'évolution** prend **une pierre du type de la carte**, sinon une pierre de lune (Saint Georges : la
  lune seulement). Le coût définitif se décide au point ⑱ (`PIERRES_PAR_EVOLUTION`).
· **Le plateau** : un objet de chaque rang — la poussière près du bord, l'étoile au milieu, une pierre
  au fond (un des six types, la lune à 12 %). Les objets sont moins épais (0,28 → 0,18) et plus grands.
· **Le rendu** : `design/objets/render_objets.py --univers --taille 256 --3d univers-256/3d` exporte, pour
  chaque objet, son relief (normales, occlusion, matière), la couleur de son corps et sa silhouette
  (`objets/3d/`). `objets/volumes.gd` en fait un volume ; `corps.gdshader` (mode objet) l'éclaire : or,
  argent, pierre ou verre, roche. ⚠️ Import des `*-relief.png` : **sans « fix alpha border »** (la matière
  est dans l'alpha ; l'or vaut 0 et serait écrasé), sans compression.
· **Les reflets des pièces** : la boîte à lumière reflétée 2,1 → 1,3, les reflets nets 1,2 → 0,7.
· **Mesures** : `test_objets` OK (27 vérifications), `test_cartes` OK, `test_tirage` OK, `sim_poussoir` OK
  (3 min : 7 objets gagnés, 0 hors jeu).

### ✅ À tester — https://192.168.0.17:18443/ (après le déploiement)
- [ ] Tes tickets, ton XP et tes éclats sont devenus des étoiles, de la poussière et des pierres de lune
- [ ] Sur le plateau : l'étoile, le globe et une pierre, en relief, les reflets qui bougent
- [ ] Faire évoluer une carte avec une pierre de son type, puis avec une pierre de lune

---

## ✅ **La collection tient à 30 cartes comme à 300, des pièces moins contrastées** — **EN PROD** *(25/09/2026, 22 h 07)*

**En clair.** La grille de la collection ne garde plus qu'**une douzaine de cases**, réutilisées
pendant qu'on défile : 31 cartes ou 300, c'est le même travail. Les photos des cartes se prennent
**quand on les obtient** (pendant l'écran de résultat), plus à l'ouverture. La machine s'arrête
quand on quitte la poussette. Les pièces sont moins sombres et moins claires aux extrêmes.

🔴 **POURQUOI** — *« le premier chargement de la collection a laggé fort, puis c'était fluide, puis
j'ai joué 2 min à la poussette, je suis revenu sur la collection et ça laggait encore »* ; *« il y
aura de plus en plus de cartes, donc faut trouver une solution finale »* ; *« réduis les 2 extrêmes »*
(Maxim).

· **La grille recyclée** (`collection_screen.gd`) : la carte n° i va dans la case i modulo le
  nombre de cases ; seules les cases visibles (plus une rangée de marge) existent. La hauteur de la
  grille suit le nombre de cartes, pas le nombre de nœuds.
· **La mémoire bornée** (`vignettes.gd`) : 48 photos en mémoire au plus (les plus anciennes
  s'en vont), relues du téléphone **une par image** — jamais un paquet d'un coup.
· **Les photos à l'obtention** : une carte gagnée est photographiée pendant le rituel, une carte
  évoluée ou changée de variante dès le bouton touché ; la grille l'a déjà. S'il en manque 3 ou plus (première ouverture, mise à jour), un écran
  **« Préparation de ta collection »** les prend une fois, avec une jauge — au lieu d'un gel.
· **La machine en pause** quand la poussette est cachée : ni physique ni rendu 3D derrière la
  collection (c'est ce qui faisait laguer au retour) ; le tas est sauvé 0,6 s après.
· **Les pièces adoucies** (`objets/corps.gdshader`, `adoucir`) : la luminosité de chaque point est
  rapprochée de 45 % vers un gris moyen, teinte gardée ; l'ombre de l'horizon passe de 0,28 à 0,12.
· **Au PC** (`tests/banc_perf.gd`) : ouvrir la collection **16 ms** la toute première fois (les
  photos suivent en ½ s), **9 ms** ensuite, **0,6 ms** pour la rouvrir ; **1,7 ms par image**
  affichée en défilant (3,5 avant).

### ✅ À tester — https://192.168.0.17:18443/
- [ ] Ouvrir la collection : l'écran « Préparation » passe une fois, puis plus jamais
- [ ] Défiler vite, dans les deux sens : fluide ?
- [ ] Jouer 2 minutes à la poussette, revenir à la collection : plus de lag ?
- [ ] Les pièces : plus de très sombres ni de très claires ?

---

## ✅ **Plus de gels, une collection qui défile comme une galerie** — **EN PROD** *(25/09/2026, 20 h 52)*

**En clair.** Le jeu est calé sur 60 images par seconde, la physique ne rattrape plus son retard
d'un coup, et la grille de la collection est faite de **photos des cartes** : défiler ne construit
ni n'anime plus rien. La carte vivante (lumière, particules) reste quand on la touche.

🔴 **POURQUOI** — *« Il y a de légers freeze quand le poussoir pousse les pièces en bas »* ; *« la
collection, le scroll est bizarre, pas fluide et donne mal aux yeux »* (Maxim).

· **60 images par seconde au plus** (`application/run/max_fps`). Le téléphone de Maxim affiche à
  120-144 Hz : le jeu se dessinait deux fois plus souvent que la physique et l'élan du défilement
  n'avancent (60 Hz) — une image sur deux immobile, puis un saut. C'est la saccade qui fatigue les
  yeux, et le double de travail pour le téléphone (chaleur, gels).
· **Un pas de physique par image au plus** : si le téléphone prend du retard, la machine ralentit
  d'un rien au lieu de geler.
· **Les pièces envoyées d'un bloc** au rendu (`multimesh_set_buffer`) : le moteur garde les ~330
  pièces éveillées en permanence (le tas touche le bloc qui bouge) — mesuré, `tests/banc_pics.gd`.
· **La grille en photos** (`vignettes.gd`) : chaque carte est photographiée une fois hors écran, à
  la résolution de l'écran, et gardée sur le téléphone (`user://vignettes/`) ; refaite seulement si
  son stade ou sa variante change. Au PC : l'ouverture 12 ms la première fois (les photos se
  prennent en ½ s), 28 ms ensuite ; **3,5 ms par image affichée** (6 à 8 avec les cartes vivantes).

### ✅ À tester — https://192.168.0.17:18443/
- [ ] La poussette une minute, en regardant le bloc pousser : plus de gel ?
- [ ] La collection : défiler vite, dans les deux sens — fluide, reposant pour les yeux ?
- [ ] Toucher une carte : elle s'ouvre en grand, vivante

---

## ✅ **Fluide, net, et un jeu plutôt qu'une page web** — **EN PROD** *(25/09/2026, 19 h 54)*

**En clair.** La poussette et la collection sont allégées de partout, **les pièces sont de vraies
pièces en métal rendues en 3D** (relief, tranche moletée, reflets qui bougent quand elles
penchent), les objets et les icônes sont nets, et le jeu se comporte comme une app : il
s'installe sur l'écran d'accueil (sans barre de navigateur), passe en plein écran au premier
toucher, ses boutons s'enfoncent et rebondissent, ses écrans glissent.

🔴 **POURQUOI** — *« Sur GSM la poussette lag pas mal »* ; *« ça lag aussi fortement quand on ouvre la
page Collection »* ; *« les pièces, on dirait des bêtes JPEG, et l'ensemble du jeu fait page web
floue, pas un jeu »* ; *« fais au mieux pour améliorer les performances, ça doit être fluide »* (Maxim).

### Ce qui faisait ramer (mesuré, `tests/banc_perf.gd`)
· 🔴 **Chaque pièce gagnée réécrivait toute la sauvegarde, tas de 300 pièces compris** (17 ms sur
  le PC, une à deux fois par seconde) → **la réserve et l'XP s'écrivent au plus toutes les 5 s**,
  un objet ou une carte tout de suite, **le tas dans son propre fichier** (`user://tas.json`) toutes
  les 20 s et quand on quitte la poussette ou l'app. *(Dette D9 soldée.)*
· **Le dessin de la machine** : 900 dessins par image depuis GDScript (~6 ms) → les pièces et les
  objets sont **rendus en 3D, d'un seul appel** (`machine_rendu.gd`, `objets/corps.gdshader`) :
  **~0,2 ms**. Le décor fixe n'est plus redessiné à chaque image.
· **La physique** : jusqu'à 8 pas de rattrapage par image quand le téléphone prend du retard
  (l'effet boule de neige) → **2 au plus** ; la sélection d'objets à la souris (un rayon lancé dans
  les 300 pièces à chaque mouvement du doigt, pour rien) → **coupée** ; la boucle du bord → une
  lecture par pièce. **Lâcher une pièce** : 1,6 ms → 0,3 ms (seules les voisines comptent).
· **La collection** : elle se reconstruisait en entier à chaque ouverture (**2,5 s** la première
  fois sur le PC) → **gardée** ; une carte n'est construite que quand elle approche de l'écran, une
  par image, avec un fondu ; **des vignettes 480 × 600** pour la grille et le ×10 ; les shaders des
  cartes sont **préchauffés au démarrage** (ils bloquaient 150 à 300 ms à leur premier dessin).
  **L'ouverture : 4 ms, la réouverture : 1 ms.**
· **Le serveur interdisait tout cache** (`no-store`) : le téléphone retéléchargeait le jeu entier
  à chaque lancement → `no-cache` : il redemande, reçoit « inchangé », et un nouvel export est
  toujours vu tout de suite. ⚠️ **Actif après le redémarrage du conteneur** (action de Maxim).

**Au PC, la poussette : 10,6 → ~5,5 ms par image.** Le reste se lit sur le téléphone : appui long
sur « La Poussette », le compteur des outils dit les images/s, la physique, le script et le rendu.

### Ce qui fait « jeu »
· **Les pièces en 3D** : le même modèle métal que les rendus en relief, calculé en direct ; la
  profondeur est vraie (ce qui est devant passe devant), bords lissés, au plein de l'écran.
· **Les objets et leurs icônes refaits en 512 px** (au lieu de 128 à 192) ; les icônes de la barre
  du bas et des types rendues 2 à 3 fois plus grandes.
· **L'app** : installable sur l'écran d'accueil (icône, écran de démarrage aux couleurs du jeu,
  portrait, sans barre du navigateur) ; **plein écran au premier toucher** dans le navigateur ; plus
  de rebond de page ni de sélection de texte.
· **Les boutons s'enfoncent et rebondissent** (tous : `Style.bouton`), **les écrans glissent** d'un
  onglet à l'autre.
· Le paquet : **29 Mo** (26 avant, + les vignettes ; les grandes illustrations perdent leurs
  mipmaps, inutiles depuis les vignettes).

**Mesuré** : tirage, cartes et banc de la poussette `RESULTAT: OK` (le même jeu qu'avant, au pas de
physique près) · photos du vrai rendu (poussette, popup, collection, rituel).

### ✅ À tester — https://192.168.0.17:18443/
- [ ] **Redémarrer le conteneur du jeu** (ci-dessous), puis ouvrir le jeu deux fois : la 2ᵉ, il démarre vite
- [ ] La poussette pendant une minute : fluide ? le compteur (appui long) : images/s ?
- [ ] Les pièces de près : du métal, pas des images
- [ ] La collection : s'ouvre-t-elle tout de suite ?
- [ ] Chrome → ⋮ → « Ajouter à l'écran d'accueil » : l'app s'ouvre sans barre de navigateur

---

## ✅ **⑦ La poussette 3D est dans le jeu** — **EN PROD** *(25/09/2026, 17 h 33)*

**En clair.** La machine de l'essai entre dans le jeu : **les pièces et les objets s'empilent**, sur
le bloc comme sur le plateau ; on lâche une pièce au-dessus du doigt, elle tombe sur ce qui est
dessous ; les objets restent au-dessus du tas. Le décor, la réserve, le popup de gain et les outils
de test ne changent pas. **Le tas de la poussette 2D repart à zéro une fois** (la réserve, les
cartes et les objets gagnés ne bougent pas).

🔴 **POURQUOI** — *« La poussette est géniale comme ça, on prend ça »* ; *« on passe à la suite »* (Maxim).

· **Ce que le banc a appris** (`tests/sim_poussoir.gd`, 3 minutes de jeu à deux pièces par seconde) :
  nourrie sans arrêt, **la machine se stabilise vers 335 pièces** et rend alors 70 à 90 % de ce
  qu'on lui donne. ⛔ **Un plafond sous cet équilibre la bloque** — vu à 260 : on ne peut plus rien
  lâcher, et sans pièces lâchées rien ne pousse (2 gains par minute). D'où : **plafond 360**, et une
  machine neuve qui part **garnie de 300 pièces**, pour qu'elle rende tout de suite.
· **Une pièce ne tient pas en tour** : lâchée sur une pile, elle se pose à l'endroit le plus bas
  tout près du doigt ; si tout y est déjà haut (5 pièces), elle reste en réserve — *« Trop de
  pièces ici »*. Vu au banc : sans ça, des tours de 3 unités contre le fronton.
· **Un objet gagné revient sur le tas**, à sa profondeur, quand on ferme le popup (avant : le
  plateau entier était regarni quand les trois étaient tombés).
· **La sauvegarde garde le tas tel quel** : la position et l'orientation de chaque corps, et la
  place du bloc dans son aller-retour.
· ⚠️ **Le coût** : ~5 ms par image sur le PC à 330 pièces (l'essai en mesurait 2,2 à 200). **Le
  téléphone est le seul banc qui compte** : appui long sur « La Poussette », le compteur est en
  bas des outils.

**Mesuré** : le banc `RESULTAT: OK` — 0 corps hors jeu, 168 pièces posées sur d'autres, 0 objet
couvert, 8 objets gagnés et revenus, la sauvegarde recharge le même tas (332 sur 332) · les cartes
`RESULTAT: OK` · 6 photos du vrai rendu (repos, pièces lâchées sur d'autres, tas, popup, outils).

### ✅ À tester — https://192.168.0.17:18443/
- [ ] Lâcher des pièces sur le bloc, y compris sur d'autres : elles s'empilent, puis débordent
- [ ] Gagner un objet : le popup, puis l'objet qui revient sur le tas
- [ ] **Le compteur d'images** (appui long sur « La Poussette ») après une minute de jeu : ≥ 55 ?
- [ ] Fermer le jeu, le rouvrir : le même tas

---

## ✅ **⑬ Le rituel des constellations, et neuf nouveaux héros** — **EN PROD** *(25/09/2026, 17 h 11)*

**En clair.** L'invocation suit la ligne D validée par Maxim : **l'astrolabe tourne, se verrouille, et
dessine l'étoile à huit branches ; des constellations s'allument éparpillées sur tout l'écran — leur
nombre dit la rareté ; leurs étoiles se posent sur le cadran, l'astrolabe se resserre en l'emblème du
dos, la carte se retourne.** En ×10, une constellation par carte, de la couleur de sa rareté, dont
les étoiles filent vers la place de la carte ; les Base se retournent d'abord, la plus rare en
dernier. **Le halo, le pilier, les fissures, l'éclair, les battements et la secousse ont disparu.**
Et **neuf nouveaux héros** : Minotaure, Cuélebre, Oiseau-Tonnerre, Anubis, Yéti, Chupacabra,
Tikbalang, Bunyip, Troll — **31 héros**.

🔴 **POURQUOI** — *« Je valide D, faut juste retirer le ralliement des constellations par l'oval »* ;
*« que les constellations qui apparaissent ne soient pas autour du rond en cercle, il faut les
éparpiller partout sur l'écran »* ; *« faut ajouter aussi les nouvelles cartes »* (Maxim, 24-25/09).

· **Le nombre de constellations** : Base 2 · Or 3 · Ombre 4 · Élémentaire 5 · Prisma 7 · Full art 9.
· **Dessin net** (`rituel.gd`, réécrit) : étoiles à branches fines et cœur blanc, traits à la plume,
  anneaux fins quand une étoile s'allume. Or et plus : quatre éclats sur les coins de la carte ;
  Prisma et Full art : leur nom en grand. Toucher l'écran passe tout.
· **Durées** : ~3 s pour une Base, ~3,5 s pour un Full art ; le ×10 ~4 s avant les retournements.
· ⚠️ **Le paquet passe à 26 Mo** (88 illustrations). Si le chargement traîne sur le téléphone :
  baisser la qualité des images (une ligne par `.import`).
· ⚠️ Types, rôles, ultimes et chiffres des neuf : propositions (`docs/art/HEROS.md`).

**Mesuré** : tirage `RESULTAT: OK` (31 héros) · cartes `RESULTAT: OK` · 23 captures du vrai rendu
(ciel, verrou, cadran, dos, retournement, en simple Base et Full art, et en ×10).

### ✅ À tester — https://192.168.0.17:18443/ (appui long sur « La Poussette » → Prisma, Full art)
- [ ] Une invocation simple : l'astrolabe, les constellations éparpillées, le dos, le retournement
- [ ] Un Prisma et un Full art (plus de constellations, le nom en grand)
- [ ] Un ×10 : les couleurs des constellations, les étoiles qui filent vers les cartes
- [ ] Toucher l'écran passe tout · fluidité · temps de chargement (26 Mo)

---

## ✅ **Le rituel retenu : l'astrolabe entouré de constellations** — **validé le 24/09, dans le jeu le 25/09** *(24/09/2026)*

**En clair.** Maxim a tranché entre les trois directions du canevas « Rituel des constellations » :
**l'astrolabe (B), sans les traits qui se croisent, entouré des constellations de C, qui se
rejoignent tout autour — plus il y en a, plus le tirage est beau** ; la carte arrive **de dos et se
retourne**. La maquette est **la ligne D, en haut du canevas** :
https://claude.ai/artifact/PqeP9uQQGBcQs2AdT2nbrF — Base, Or, Prisma, Full art et **le ×10**.
Rien ne change dans le jeu avant l'accord (fiche ⑬, FEATURES).

🔴 **POURQUOI** — *« J'aime bien la B et la C. La B, pour la prisma et la full art, tous les traits
qui se relient, ça fait n'importe quoi ; sinon tout le reste est nickel. La C, je préfère que la
carte apparaisse de dos et se retourne. L'animation de la B en corrigeant full art et prisma + les
constellations qui se rejoignent tout autour, plus il y a de constellations mieux est le drop
(faut penser au multi drop aussi) »* (Maxim, 24/09).

· **Ce qui se croise, et rien d'autre** : l'anneau de huit étoiles, le cadran, et au verrou l'étoile
  à huit branches. Le pentagramme, les liens multicolores et la couronne du full art sont partis.
· **Le nombre de constellations dit la rareté** : Base 2 · Or 3 · Ombre 4 · Élémentaire 5 ·
  Prisma 7 · Full art 9. Elles se rejoignent le long d'une grande ellipse, puis leurs étoiles se
  posent sur le cadran, l'astrolabe se resserre en l'emblème du dos, la carte se retourne.
· **Prisma et full art** : une seule teinte irisée qui dérive, plus un trait par couleur.
· **Le ×10** : une constellation par carte, **de la couleur de sa rareté** — on compte l'or et
  l'irisé avant le retournement ; chacune file vers sa carte, les Base se retournent d'abord, la
  plus rare en dernier.

### ✅ À faire — Maxim
- [ ] Regarder la ligne D (et le ×10) ; dire ce qui ne va pas, ou « go »

---

## ✅ **Vingt-deux héros : onze nouveaux, et Saint Georges en trois stades** — **EN PROD** *(23/09/2026, 21 h 24)*

**En clair.** Onze nouveaux héros entrent dans la collection, chacun avec ses trois illustrations
(une par stade) : **Cerbère, le Golem, Fenrir, le Roc, Quetzalcoatl, le Kelpie, la Banshee, le
Mothman, le Chevalier sans tête, Baba Yaga et le Wendigo**. **Saint Georges passe à trois stades**,
avec ses nouvelles illustrations.

🔴 **POURQUOI** — *« Les persos, il y a déjà les images, je les ai nommées selon la convention avec
1, 2, 3 pour que tu connaisses l'évolution ; il faut créer tous ces persos (juste remplacer le Saint
Georges actuel par celui-là) »* (Maxim).

· **Les illustrations** : `Cartes/Illustration/<Nom>1..3.png` → `proto_degagement/cartes/<id>-1..3.jpg`
  (800 × 1000, recadrées au format de la carte), avec leur `.import` écrit avant le premier import.
  Trois noms de fichier mal orthographiés pris tels quels : `Banshe2`, `cerbere1`, `Wendingo1`.
· ⚠️ **Types, rôles, noms des stades, ultimes, PV et ATT des onze sont des propositions de Claude**
  — le tableau est dans `docs/art/HEROS.md`, à corriger librement.
· **Le paquet du jeu passe à 17,7 Mo** (61 illustrations). Si le chargement devient long sur le
  téléphone : baisser la qualité des images (`compress/lossy_quality` dans leurs `.import`).

**Mesuré** : tirage `RESULTAT: OK` (22 héros) · cartes **389/389** · planches des 22 cartes
photographiées, cadrage vérifié.

### ✅ À tester — https://192.168.0.17:18443/
- [ ] La collection montre 22 héros ; les nouveaux tombent à l'invocation
- [ ] Les trois stades de Saint Georges
- [ ] Le temps de chargement sur le téléphone (17,7 Mo)

---

## ✅ **Les invocations deviennent spectaculaires** — **EN PROD** *(23/09/2026, 21 h)*

**En clair.** Le portail et les révélations montent en puissance : des étoiles filantes, un pilier
de lumière, de la poussière d'étoiles, des fissures de lumière sur le dos des cartes rares, leur
cœur qui bat, l'écran qui tremble, et le nom des très rares en grand, irisé.

🔴 **POURQUOI** — *« Les animations d'ouverture de pack sont bien comme ça, mais ajoute plus
d'effets, ça doit être plus spectaculaire »* (Maxim).

· **Le portail** : des étoiles filantes convergent des bords de l'écran, le cercle s'allume, un
  **pilier de lumière** descend ; tout éclate — l'écran tremble, la poussière d'étoiles retombe.
· **Or, ombre, élémentaire** : la carte s'allume, **bat une fois** sous de fines **fissures de
  lumière**, se retourne dans une onde, des étincelles et de la poussière d'étoiles.
· **Prismatique** : les autres s'éteignent ; elle s'élève dans les rayons, **se fend de lumière**,
  son **cœur bat deux fois**, tremble — puis l'éclair, **l'écran tremble**, et **« PRISMATIQUE »**
  en grand, irisé, au-dessus d'elle.
· **Full art** : le noir se fait ; il vient au centre sous **un pilier de lumière**, dans des rayons
  arc-en-ciel, **se fend de lumière**, son **cœur bat trois fois** — puis un grand éclair, **une forte
  secousse**, et **« FULL ART »** en grand.
· Toucher l'écran passe toujours tout.

**Mesuré** : tirage et cartes `RESULTAT: OK` ; **15 écrans photographiés** (portail, fissures du
prismatique et du full art, bannières, bilan) sans erreur.

### ✅ À tester — https://192.168.0.17:18443/ (appui long sur « La Poussette » → « Prisma », « Full art »)

- [ ] Le portail : étoiles filantes, pilier, éclatement, l'écran tremble
- [ ] Un prismatique : fissures, battements, bannière PRISMATIQUE, secousse
- [ ] Un full art : au centre, pilier, fissures, bannière FULL ART, forte secousse
- [ ] Fluide pendant les effets

---

## ✅ **⑦ L'essai 3D de la poussette — adopté par Maxim** *(23/09/2026, 20 h · revu à 20 h 50 et 21 h 19 · adopté le 24/09)*

> ✅ **Adopté le 24/09** : *« La poussette est géniale comme ça, on prend ça »* (Maxim). Étape 2 :
> la machine 3D dans le jeu (fiche ⑦, FEATURES), avec les objets de l'univers (⑭). ⚠️ *La ligne
> « Mesure » du téléphone n'a pas été envoyée : l'avis de Maxim vaut feu vert, le chiffre reste à relire.*
>
> 🔄 **Revu à 21 h 19** (*« fais juste en sorte que les bonus soient toujours au-dessus du tas, pour
> bien les voir »*) : les objets sont plus épais qu'une pile de pièces, posés en dernier sur le tas,
> et **secouent les pièces qui tombent sur eux**. Test T3 : **0 objet sur 3** couvert, au départ comme
> après trois minutes.
>
> 🔄 **Revu à 20 h 50 après l'essai de Maxim** (*« la gravité n'est pas assez lourde, les pièces
> glissent, pas d'effet d'enfoui, je ne peux pas poser une pièce au-dessus des autres — fais les
> tests toi-même »*) :
> · **plus lourd** (gravité ×5 : à cette échelle, la vraie gravité rend tout flottant) ;
> · **le bloc va et vient comme une bielle** — il ralentit en bout de course : plus aucun glissement ;
> · **les pièces glissent entre elles, le plateau est poli, le bloc accroche** — trop de frottement
>   entre pièces, et le tas poussé se redressait sur la tranche au lieu d'avancer ;
> · **le dessin en perspective oblique** : la tranche des pièces, la face du bloc, l'ombre de
>   chaque pièce sur celles du dessous — l'empilement se lit ;
> · **on lâche n'importe où** : la pièce tombe sur ce qui est dessous ;
> · **les tests automatiques** (`-- tests`) : **12/12** pièces lâchées sur une autre y restent ·
>   **0 px** de glissement sur le bloc · **3/3** objets enfouis · trois minutes de jeu sans rien
>   d'envolé ni de traversé, et **pleine, la machine rend ce qu'on lui donne** ;
> · ⚠️ **l'enseignement** : en 3D, les pièces s'empilent sur 2 à 3 couches — la machine a besoin de
>   **~260 pièces** pour déborder, contre ~90 en 2D. C'est ce chiffre que le téléphone doit tenir ;
> · **la mesure se fait toute seule** à l'ouverture de la page (100, 150, 200, 260 pièces).

**En clair.** Une version d'essai de la machine où **les pièces et les objets se superposent** :
la physique passe en 3D (Jolt), le dessin reste le nôtre. Elle est servie **à une adresse à
part** — **https://192.168.0.17:18443/essai/** — le jeu n'a pas changé. Son seul but : **mesurer
sur le téléphone** combien de pièces tiennent à 60 images/s.

🔴 **POURQUOI** — *« je dois pouvoir la mettre et que les pièces se superposent, aussi bien sur le
poussoir que sur le plateau »* ; fiche ⑦ acceptée (*« go next »*, Maxim). Le seuil posé : **≥ 55
images/s à 150 pièces**, sinon on s'arrête là.

· **Ce qu'on y voit** : le bloc qui glisse sous le fronton, les pièces **empilées** sur le bloc et
  sur le plateau, les objets **en partie enfouis** ; glisser le doigt en haut **lâche des pièces
  au-dessus**, qui tombent sur ce qui est dessous. Boutons **100 · 150 · 200 pièces** et **Semer
  ×10** ; en haut du panneau, le compteur d'images.
· **Ce qu'on n'y voit pas** : ni gains, ni réserve, ni sauvegarde — ce n'est pas le jeu.
· **Mesuré sur le PC** (temps réel par image) : 100 pièces **0,73 ms** · 150 pièces **1,15 ms** ·
  200 pièces **1,61 ms** — du même ordre que la poussette 2D actuelle avec deux fois moins de corps.
  ⚠️ *Le téléphone est le seul banc qui compte.*

### ✅ À mesurer sur le téléphone — https://192.168.0.17:18443/essai/

- [ ] « 150 pièces », attendre 10 s : le compteur d'images/s (≥ 55 ?)
- [ ] Pareil avec « 200 pièces », puis « 100 pièces »
- [ ] Glisser le doigt en haut pendant 10 s : le compteur tient-il ?
- [ ] L'empilement se lit-il ? Les pièces tombent-elles bien sur les autres ?
- [ ] Me donner les trois chiffres (100, 150, 200)

---

## ✅ **L'invocation devient un rituel, et toutes les cartes ont leur full art** — **EN PROD** *(23/09/2026, 19 h 45)*

**En clair.** Un **portail** s'ouvre avant chaque invocation, et **sa couleur annonce la plus belle
carte du tirage**. Les cartes rares se révèlent dans un éclat ; **le prismatique et le full art**
dans les rayons et l'éclair — le full art vient au centre, en grand. **Toutes les cartes peuvent
tomber en full art** (0,1 %) : l'illustration peinte en entier, les textes sur verre. Et **le tirage
n'est pas cassé** : vérifié sur 200 000 cartes par le vrai chemin du jeu.

🔴 **POURQUOI** — *« 5 tirages de 10, 2 Prisma, 2 élémentaire, 6 ombre, le taux est broken »* ;
*« faudrait faire une animation pour le tirage et une animation quand ça dévoile des cartes
gradées, surtout la prisma et full art ; elles peuvent toutes être full art maintenant, donc go »*
(Maxim).

### Le taux n'est pas cassé

· **200 000 cartes par le vrai chemin** (20 000 invocations ×10, comme le bouton) : Base 73,80 %
  (affiché 73,9) · Or 15,06 (15) · Ombre 6,97 (7) · Élémentaire 3,03 (3) · Prismatique 1,03 (1) ·
  Full art 0,105 (0,1). **Écart maximal : 0,1 point.** Le test le vérifie désormais à chaque fois.
· **La série de Maxim** (50 cartes) : 2 prismatiques arrivent **1 fois sur 11**, 6 ombres **1 fois
  sur 7** — une série chanceuse, pas un tirage faussé. Des rares encore plus rares, c'est un
  changement de taux, d'une ligne.

### Ce qui change pour les gens

· **Le portail** : douze étoiles s'allument en cercle et se relient en constellation, un astrolabe
  se trace, des poussières de lumière spiralent ; le cercle se resserre et éclate. **Sa couleur
  trahit la plus belle carte** : jade (rien de rare), or, argent (ombre), la couleur du type
  (élémentaire), irisé (prismatique), arc-en-ciel (full art).
· **Le ×10** : les dix dos jaillissent du portail vers leur place.
· **Une rare se retourne dans un éclat** (une onde, des étincelles). **Le prismatique** s'élève,
  tremble dans les rayons pendant que les autres s'éteignent, puis l'éclair. **Le full art** quitte
  sa place, vient au centre en grand, tremble dans des rayons arc-en-ciel, se retourne dans un grand
  éclair, reste un instant, puis rejoint sa place.
· **L'invocation simple** : le même portail ; **toucher l'écran passe tout**, comme au ×10.
· **Le full art** : l'illustration peinte couvre **toute la carte** ; nom, ruban et ultime sur **du
  verre sombre** ; **un arc-en-ciel qui tourne sur le bord** ; un reflet irisé, des scintillements
  blancs ; un dos blanc irisé. **Tous les héros** peuvent l'avoir.
· **Deux outils de test** (appui long sur « La Poussette ») : « Prisma » et « Full art » donnent une
  carte de cette rareté, avec sa mise en scène — pour ne pas tirer mille cartes.

### 📏 Mesuré

· Tirage (dont le vrai chemin, 200 000 cartes) et cartes (168 construites, full art compris) :
  `RESULTAT: OK`. **13 écrans photographiés** au vrai rendu — portail, prismatique, full art au
  centre, bilan, invocation simple de full art — aucune erreur.
· Le paquet : 6,9 Mo.

⚠️ **Non couvert** : la fluidité du portail et des rayons **sur le téléphone**.

### ✅ À tester sur le téléphone — https://192.168.0.17:18443/

- [ ] Invocation ×1 : le portail s'ouvre, la carte en jaillit ; toucher l'écran passe l'animation
- [ ] Invocation ×10 : les dos jaillissent du portail ; sa couleur annonce la plus belle carte
- [ ] Une rare se retourne dans un éclat ; un prismatique se fait attendre (rayons, tremblement)
- [ ] Appui long sur « La Poussette », puis « Full art » dans la collection : il arrive en grand, dans les rayons
- [ ] La carte full art : image sur toute la carte, textes lisibles sur le verre, bord arc-en-ciel
- [ ] Toucher pendant un ×10 : tout se retourne et reprend sa place
- [ ] Fluide sur le téléphone pendant le portail et les rayons

---

## ✅ **Retouches après le premier essai : poussette, cartes, taux** — **EN PROD** *(23/09/2026, 19 h)*

**En clair.** Suite à l'essai de Maxim sur le téléphone : une pièce lâchée sur une autre ne file
plus en bas ; un objet n'est gagné qu'une fois **la ligne entièrement passée** ; les taux de rareté
baissent (full art 0,1 %, prismatique 1 %) ; la carte s'affiche en plein écran ; le ruban ne dit
plus que le rôle, le pays passe en bas ; la collection n'a plus de barre de défilement.

🔴 **POURQUOI** — *« je mets une pièce sur une déjà présente sur le poussoir, elle est directement
en bas, pas bon »*, *« ils doivent passer la ligne en bas complètement, pas juste la toucher »*,
*« la FA c'est 0,1 %, prisma 1 %, les autres raretés tu baisses de 1 %, la différence à Basic »*,
*« on doit pouvoir afficher la carte en plein écran »*, *« juste l'info du type d'unité, la
provenance en bas en plus petit, le pays suffit »*, *« la barre défilante ne doit pas
apparaître »* (Maxim). La **superposition** des pièces et des objets, elle, demande une vraie
physique 3D : proposée à part *(FEATURES ⑦)*.

### Ce qui change pour les gens

· **Une pièce lâchée là où il n'y a pas de place ne tombe pas** : elle reste dans la réserve, et
  l'aide dit « Pas de place ici ». *(Avant : elle roulait par-dessus le tas et filait sur le plateau.)*
· **Le bord** : un objet ou une pièce dont le centre passe la ligne **bascule** et file dans la
  gouttière en s'effaçant ; il n'est gagné **qu'une fois la ligne entièrement passée**. *(Avant : dès
  qu'il la touchait, le centre encore 29 px avant.)*
· **Les taux** : Base 73,9 % · Or 15 % · Ombre 7 % · Élémentaire 3 % · Prismatique 1 % · Full art
  0,1 %. Tant qu'aucun héros n'a d'illustration full art, sa part revient aux autres (Base 74 %).
· **La carte en plein écran** : toucher la carte en grand, ou « Plein écran » ; la lumière suit le
  doigt, un toucher ramène.
· **Le ruban des cartes ne dit plus que le rôle** (GARDE, FRAPPEUR, APPUI) ; **le pays**, en petit,
  passe en bas, au-dessus du numéro — le pays seul, sans la ville.
· **La collection défile au doigt, sans barre.**

⛔ **Ce que ça ne touche pas** : la sauvegarde (le tas se recharge tel quel), l'économie, le tirage
lui-même (seuls les poids changent).

### 📏 Mesuré

· Banc de la poussette, deux profils : 0 avertissement, aucun chevauchement (≤ 2 px), rechargement
  identique. Tirage (100 000 cartes, écart ≤ 0,21 point) et cartes : `RESULTAT: OK`. 16 écrans
  photographiés au vrai rendu, sans erreur.
· ⚠️ **La machine paie nettement moins** : sur 4 minutes de semis au banc, **15 lots au lieu de 27 à
  32** pour un joueur rapide, **3 au lieu de 12** pour un joueur lent. Il faut pousser les objets
  plus loin, et une pièce sans place ne tombe plus. C'est le sens de « le jeu est trop simple » ;
  à juger au doigt.

### ✅ À tester sur le téléphone — https://192.168.0.17:18443/

- [ ] Lâcher une pièce sur une autre, sur le bloc : rien ne tombe, « Pas de place ici », la réserve ne baisse pas
- [ ] Un objet au bord : il bascule quand son centre passe la ligne, s'efface dans la gouttière, puis le popup
- [ ] Une pièce au bord : pareil, « +3 » quand elle a passé la ligne
- [ ] Carte en grand → toucher la carte ou « Plein écran » : la carte seule, la lumière suit le doigt, un toucher ramène
- [ ] Les rubans disent GARDE / FRAPPEUR / APPUI ; le pays est lisible en bas
- [ ] La collection défile au doigt, sans barre
- [ ] Les probabilités affichent 74 % · 15 % · 7 % · 3 % · 1 % (le full art : « aucun héros n'en a encore »)

---

## ✅ **Lot B : la collection et les invocations — et le bloc devient une vraie machine** — **EN PROD** *(23/09/2026)*

**En clair.** La collection et les invocations passent au look « Conte mystique » : l'invocation
×10 prend tout l'écran, avec des cartes presque trois fois plus grandes, et les cartes s'écrivent
en Castoro. Sur la poussette, les pièces du bloc se comportent comme sur une vraie machine : le
bloc les porte, elles s'entassent contre le mur du fond, et celles de devant débordent.

🔴 **POURQUOI CE LOT EXISTE** — *« l'invocation est petite là, les cartes sont minuscules à l'écran
quand il y en a 10, faut prendre tout l'écran »* et *« le plateau poussoir est toujours pas bon au
niveau des collisions des pièces qui sont au-dessus »* ; à la question posée, **« Comme une vraie
machine »** (Maxim). Mesuré avant de toucher : deux pièces du bloc se chevauchaient jusqu'à
**62 px** (pour 80 de diamètre).

### Ce qui change pour les gens

· **L'invocation ×10 prend tout l'écran** : les dix cartes en quinconce (3-2-3-2), **320 px de
  large au lieu de 190** ; le bilan en haut, « Encore ×10 » et « Fermer » en bas. Elle couvre aussi
  le bandeau et la navigation.
· **L'invocation simple** : la carte en grand, son nom, ce qu'elle apporte, « Encore · N tickets ».
· **La collection** : un panneau Invocation (Invoquer, Invoquer ×10, le coût dessous, « Les
  probabilités ») ; la grille posée sur le ciel ; sous chaque carte, **les pastilles du stade, le
  niveau, la variante à sa couleur** et une gemme par variante possédée ; les héros à découvrir
  restent de dos, éteints.
· **La carte en grand** et **les probabilités** : même style, en plein écran.
· **Les cartes en Castoro** (Castoro Titling pour les petites capitales) ; un nom, une forme ou un
  ruban trop long **rapetisse au lieu d'être coupé**.
· **La poussette** : le haut du bloc devient un **fronton** fixe, où montent le nom et les lunes ;
  **le bloc porte ses pièces dans les deux sens** ; quand il recule, **elles s'entassent contre le
  mur et celles de devant tombent** ; il **part garni de deux rangs**, donc la première pièce lâchée
  en fait déjà tomber une. On lâche les pièces **en glissant le doigt en haut de la machine** :
  au pied du mur s'il y a la place, sinon **elle roule par-dessus le tas et tombe devant**.
  **Plus aucune pièce n'est posée dans une autre.**
· Le bloc **reprend sa place** au chargement, avec ses pièces.

### 🔧 Corrigés en route — des défauts trouvés par les tests, pas par toi

· 🔴 **Le popup de gain gelait le jeu avec `Engine.time_scale = 0`.** Godot fait alors quand même
  ses pas de physique, avec un pas de 0, et divise par lui dans les contacts : **des pièces en NaN
  à chaque lot gagné**, dès qu'un tas se touche. Avec le bloc garni, c'était systématique
  *(2,35 millions d'avertissements en 4 minutes au banc)*. Désormais la physique est **arrêtée**
  (`PhysicsServer2D.set_active`). *Probablement présent avant, en plus rare.*
· **Le rechargement déplaçait des pièces** : recalage plus strict que les murs, et fait devant la
  position la plus avancée du bloc au lieu de la vraie. Il est maintenant **à l'identique**.
· **Des textes à la ligne débordaient de leur panneau** (la note des probabilités, un peu la phrase
  du cadeau du jour) : `Style.libelle` active le retour à la ligne avant la taille.

⛔ **Ce que ça ne touche pas** : les règles, le tirage, les cartes elles-mêmes (dessin, effets).
⚠️ **Le tas sauvegardé repart à zéro une fois** (`GEO_VERSION` 8 → 9) : le plateau est regarni à
la première ouverture. Rien d'autre n'est perdu (XP, tickets, éclats, cartes).

### 🔴 Les décisions à ne pas défaire

| | |
|---|---|
| **Le mur du fond est à 600 px : le fronton** (`MUR`) | Reculé, le bloc garde ce qui tient entre le mur et sa lèvre. Mur en haut du cadre : **près de 90 pièces**, plus que le plafond de 115 corps avec le plateau. À 600 : **deux rangs, 23 pièces**. |
| **Geler le jeu, c'est `PhysicsServer2D.set_active(false)`** — jamais `Engine.time_scale = 0` | Un pas de physique nul divise par zéro dans les contacts : NaN en cascade, sans une erreur. |
| **La position du bloc se lit dans `face_y`**, jamais dans `face.position` | Avec `sync_to_physics`, le nœud garde son ancienne place jusqu'au pas suivant : relue trop tôt, elle ment. |
| **Une pièce lâchée va à la place libre la plus proche** (`_place_libre`), sinon elle roule devant | Posée dans une autre, le moteur les sépare d'un coup, en les projetant : c'était « les collisions du dessus ». |
| **Les grands moments de la collection vivent dans une `CanvasLayer`** | Main dessine le bandeau et la navigation par-dessus les écrans : sans couche, le ×10 ne peut pas prendre tout l'écran. |

### 📏 Mesuré

· **Nouveau banc `tests/sim_poussoir`** : un joueur sème pendant 4 minutes, popup de gain compris.
  Quatre profils (rapide ou lent, fronton ou bloc) : **pire chevauchement 2,4 px** (62,5 avant),
  enfoncement dans le mur ≤ 1,9 px, **94 corps au plus** (plafond 115), **0 avertissement**, tas
  rechargé **identique**.
· Physique sur le PC : **~0,7 ms** par pas, comme avant — le bloc garni ne coûte presque rien.
· Tirage et cartes : `RESULTAT: OK`, 142 cartes construites. **Le vrai rendu** (OpenGL ES 3.0) :
  15 écrans photographiés, aucune erreur *(tests/capture_poussoir, tests/capture_cartes)*.
· Le paquet du jeu : **6,9 Mo** (−0,8 Mo : Fraunces et Barlow ne sont plus exportées).
· ⚠️ **La machine rend un peu plus** : 27 à 32 lots pour 4 minutes de semis intense, contre 24
  avant. À reprendre avec l'économie.

⚠️ **Non couvert** :
· **La fluidité sur le téléphone** : ~25 pièces bougent maintenant en permanence sur le bloc.
· Le geste sur le fronton, au doigt.

### ✅ À tester sur le téléphone — https://192.168.0.17:18443/

- [ ] En semant sans arrêt, le compteur reste ≥ 55 images/s (appui long sur « La Poussette »)
- [ ] Le bloc porte ses pièces : elles avancent ET reculent avec lui
- [ ] Quand il recule, elles s'entassent contre le fronton ; celles de devant tombent sur le plateau
- [ ] Aucune pièce du bloc n'en chevauche une autre
- [ ] Glisser le doigt sur le fronton lâche les pièces au pied du mur ; bloc plein, elles roulent par-dessus et tombent devant
- [ ] Gagner un lot : le popup s'ouvre, tout s'arrête, et tout repart normalement après « Empocher »
- [ ] Fermer l'onglet et revenir : le tas et le bloc sont où on les a laissés
- [ ] Invocation ×10 : tout l'écran, cartes lisibles ; toucher retourne tout ; toucher une carte l'ouvre en grand
- [ ] Invocation simple, carte en grand, probabilités : lisibles, les boutons répondent
- [ ] La grille : stade, niveau et variante lisibles sous chaque carte ; les héros à découvrir sont de dos

---

## ✅ **Le nouveau look, lot A : le ciel, le bandeau et la poussette** — **EN PROD** *(23/09/2026)*

**En clair.** Le jeu prend la direction « Conte mystique », universelle : un ciel étoilé vivant
derrière les écrans, un bandeau et une navigation à filets d'or et lueur jade, et une poussette
redessinée — pièces et bonus rendus en relief, bloc ivoire à la frise de lunes. La collection
suivra au lot B.

🔴 **POURQUOI CE LOT EXISTE** — *« refaire le look général qui match mieux et aussi le coin
pusher »* ; puis, sur le canevas, *« le fond un truc genre constellation, et animé le tout — un
beau rendu »* et *« les jetons et objets de la poussette sont très moches »* (Maxim). Direction
choisie en cinq séries sur le canevas « Directions du look », page 5 *(DECISIONS du 23/09)*.

### Ce qui change pour les gens

· **Le ciel** : nébuleuses qui dérivent, étoiles qui scintillent, la Grande Ourse, Cassiopée et le
  Cygne qui se tracent, des étoiles filantes, des lucioles — derrière les deux écrans.
· **Le bandeau** : verre sombre à double filet d'or ; l'expérience, les tickets et les éclats ont
  pour icônes **les objets qu'on gagne sur le plateau**.
· **La navigation** : icônes, lueur jade sous l'onglet actif.
· **La poussette** : cadre laqué à filets d'or ; plateau miroir du ciel (étoiles, reflet de lune) ;
  bloc ivoire avec son nom et une frise de lunes ; **mur du fond fixe**, seule la face avance ;
  **pièces et bonus rendus en relief** (pièce frappée étoile ou lune, jeton d'argent de
  l'expérience, médaillon d'ivoire du ticket, jade taillé de l'éclat) ; repères de profondeur avec
  l'objet qu'on y gagne ; bord gagnant jade d'où montent des étincelles ; pièces au bord allumées.
· **Sous la machine** : le panneau Réserve (pièces, recharge, dernier gain) et l'aide.
· **Le popup de gain** et le **cadeau du jour** dans le même style.
· **Les outils de test sont cachés** : un appui long sur « La Poussette » les montre ou les cache,
  dans les deux écrans.
· **Le dragon du Doudou s'appelle El Biète.**
· Typo **Castoro** (texte) et **Castoro Titling** (étiquettes), libres (OFL).
⛔ **Ce que ça ne touche pas** : la physique, les règles, l'économie, le tirage, la sauvegarde, les
cartes et la collection (lot B).

### 🔴 Les décisions à ne pas défaire

| | |
|---|---|
| **Chaque objet est dessiné à la position et au rayon de son corps** (`Style.cote_objet`) | L'image d'un disque de rayon r fait 2·r / 0,92 de côté. Une taille à l'œil ferait croire que les pièces se chevauchent. |
| **Le ciel : textures calculées une fois, pas de shader plein écran** (`ciel.gd`) | Une quarantaine de propriétés animées par image : le téléphone ne paie presque rien. |
| **Les objets sont des images rendues** (`design/objets/render_objets.py`) | Le dessin vectoriel plat a été jugé « très moche » deux fois ; le rendu en relief (carte de hauteur + éclairage) est passé. |
| **Une seule source pour le look** (`style.gd`) | Couleurs, polices, panneaux et boutons ; la collection s'y branchera au lot B. |

### 📏 Mesuré

· Tirage et cartes : `RESULTAT: OK`, aucune erreur de script.
· **Le vrai rendu** (OpenGL ES 3.0, comme le téléphone) : poussette au repos et avec des pièces
  semées, popup de gain, outils affichés, collection sur le ciel — aucune erreur *(tests/capture_poussoir)*.
· Hors écran sur le PC : ~150 images/s. Le paquet du jeu : **7,7 Mo** (+0,5 Mo : polices et objets).

⚠️ **Non couvert** :
· **La fluidité sur le téléphone** avec le ciel animé : c'est le test de Maxim ci-dessous.

### ✅ À tester sur le téléphone — https://192.168.0.17:18443/

- [ ] Le ciel bouge doucement, sans ralentir le jeu (compteur d'images ≥ 55 : appui long sur « La Poussette »)
- [ ] Pièces et bonus sont les nouveaux objets, à la bonne taille : deux pièces voisines ne se chevauchent pas
- [ ] Le fond du bloc reste contre le mur, seule la face avance ; les pièces semées restent posées, celles qui dépassent tombent
- [ ] Une pièce ou un bonus qui passe le bord donne son gain ; le popup s'affiche dans le nouveau style
- [ ] Le bandeau se met à jour après un gain, « Dernier gain » aussi
- [ ] Appui long sur « La Poussette » : les outils apparaissent (et « +10 tickets » dans la collection), puis disparaissent
- [ ] On passe à la collection et on revient
- [ ] Tout reste lisible, y compris les petites étiquettes dorées

---

## ✅ **Retouche : l'ombre passe au graphite** — **EN PROD** *(23/09/2026)*

**En clair.** La carte ombre n'a plus de couleur : graphite et fumée au lieu du violet, et une
brume plus légère. Elle ne se confond plus avec l'élémentaire esprit.

🔴 **POURQUOI** — *« l'effet de l'ombre est trop fort, faut faire plus léger, aussi la carte ombre se
confond avec la carte élémentaire esprit »* (Maxim).

· **La carte** : cadre graphite, filets et coins argent, illustration grisée, vignette neutre.
· **Sa brume** : moins dense et plus claire ; elle reste sur le cadre.
· **Son dos** : étoile argent dans la brume *(elle était violette)*.
· **La maquette** suit *(v5.2)*.
⛔ **Ce que ça ne touche pas** : les probabilités, les autres variantes, la poussette.

📏 **Mesuré** : 142 cartes construites et dessinées, aucune erreur ; la carte ombre en grand, avant
et après, au vrai rendu (OpenGL ES 3.0).

- [ ] Sur le téléphone : l'ombre se lit comme une ombre, plus comme un esprit

---

## ✅ **L'invocation ×10, les dos qui trahissent la rareté, et les effets** — **EN PROD** *(23/09/2026)*

**En clair.** On peut invoquer dix cartes d'un coup : elles arrivent de dos et se retournent une à
une. Le dos trahit déjà la rareté, on devine ce qu'on a tiré avant de le voir. Les effets de la
maquette vivent maintenant dans le jeu : le cadre du feu en fusion, les éclairs, la neige, les
bulles, les feuilles, les feux follets, la brume de l'ombre, les éclats du prismatique. Et la
collection garde toutes les variantes tirées d'un héros : on choisit celle qu'on affiche.

🔴 **POURQUOI CE LOT EXISTE** — *« faudrait qu'on puisse faire des multi invocation par 10 ticket,
on voit toutes les cartes de dos et ça se retourne 1 à 1 »*, *« chaque rareté a une petite diff
légère dans le dos »*, *« les effets élémentaire ne sont pas là, ni l'effet d'ombre »*, *« choisir la
rareté qu'on veut afficher quand on en a pack plusieurs »* (Maxim).

### Ce qui change pour les gens

· **« ×10 · 10 TICKETS »** : dix cartes, **mêmes probabilités** qu'une à une, aucun bonus *(choix de
  Maxim)*. La donne de dos, puis les retournements un par un ; une carte rare marque un temps et
  s'allume. **Toucher l'écran retourne tout.** Un bilan : nouvelles cartes, nouvelles variantes, XP,
  la plus belle. Toucher une carte l'ouvre en grand.
· **Les dos** : la base garde le dos de la maquette. **Or** : liseré et étoile dorés, un reflet qui
  passe. **Ombre** : étoile violette dans la brume. **Élémentaire** : le halo du type qui déborde sur
  les côtés. **Prismatique** : étoile blanche, liseré irisé, des éclats.
· **Les effets**, partout (grille, carte en grand, invocations), plus légers dans les petites
  cartes : feu *(métal en fusion, braises, embrasement)*, foudre *(éclairs qui frappent et
  illuminent, arcs, courant)*, eau *(caustiques, bulles qui éclatent, gouttes)*, glace *(neige sur
  trois profondeurs et rafales, givre)*, nature *(feuilles qui tournoient, spores, rais de soleil,
  pousses)*, esprit *(feux follets, brume fantôme)*, ombre *(brume sur le cadre)*, prismatique
  *(éclats)*.
· **Les variantes d'un héros se collectionnent** : chaque variante tirée rejoint la carte. Une plus
  rare que l'affichée prend sa place à l'arrivée ; **des pastilles, sur la carte en grand, laissent
  choisir celle qu'on affiche.**
⛔ **Ce que ça ne touche pas** : la poussette, ses lots, le cadeau du jour, le serveur.

### 🔴 Les décisions à ne pas défaire

| | |
|---|---|
| **Le ×10 est dix invocations simples** (`GS.invoquer_multi`) | Mêmes probabilités, exactement 10 tickets, une seule sauvegarde. Un bonus changerait les chances affichées — il faudrait alors les afficher. |
| **Les effets d'une carte ne tournent que si elle est à l'écran** (`CarteView._maj_effets_visibles`) | Une grille pleine de cartes animées, défilée ou cachée, ne coûte rien au téléphone. |
| **Surfaces en shaders, montées droites en particules du moteur, le reste dessiné à la main** (`carte_fx.gd`) | Les particules du moteur ne savent ni onduler ni réagir à une rafale : la neige, les feuilles et les bulles sont dessinées à la main, comme dans la maquette. |
| **`GS.sauvegarde_active`** | Les tests et la séance de captures coupent la sauvegarde : ils n'écrivent plus jamais le fichier du PC. |
| **Une sauvegarde d'avant garde sa carte** | Sa variante devient la première de sa collection de variantes. |

### 📏 Mesuré

· **Le ×10** : 100 invocations ×10 simulées = **1 000 cartes pour exactement 1 000 tickets** ; refus
  sans rien dépenser à 9 tickets ; aucune variante en double, l'affichée toujours possédée ; choisir
  une variante possédée marche, une non possédée est refusée.
· **142 cartes construites et dessinées** (dont les cinq dos), une invocation ×10 déroulée jusqu'au
  bilan, aucune erreur.
· **Le vrai rendu** (OpenGL ES 3.0, comme le téléphone) : collection pleine d'effets, carte en feu et
  carte ombre en grand, ×10 de dos, à mi-course et au bilan.
· Le paquet du jeu : **7,2 Mo** (+60 Ko pour tous les effets).

⚠️ **Non couvert** :
· **La fluidité sur le téléphone**, avec dix cartes animées : c'est le test de Maxim ci-dessous.

### Actions manuelles

· Aucune : le jeu est déjà servi par le NAS.

### Tests — sur le téléphone, `https://192.168.0.17:18443`

- [ ] « ×10 » est grisé sous 10 tickets, et en retire exactement 10
- [ ] Les dix dos arrivent un par un ; on reconnaît l'or, l'ombre, l'élémentaire, le prismatique avant qu'ils se retournent
- [ ] Les cartes se retournent une à une ; toucher l'écran les retourne toutes
- [ ] Le bilan correspond à ce qui est tombé ; toucher une carte l'ouvre en grand
- [ ] Chaque type en élémentaire a son effet, l'ombre sa brume, le prismatique ses éclats — dans la grille, en grand, aux invocations
- [ ] Sur la carte en grand, les pastilles changent la variante affichée
- [ ] La collection pleine de cartes animées reste fluide ; la poussette tourne toujours comme avant

---

## ✅ **Les cartes dans le jeu** — **EN PROD** *(23/09/2026)*

**En clair.** Les onze héros sont dans le jeu, en vraies cartes : les mêmes que la maquette, avec
leurs illustrations, leurs stades et les matières des six variantes. Un ticket donne une carte
tirée au hasard ; elle arrive de dos et se retourne. La collection montre ce qu'on possède ; une
carte s'ouvre en grand et joue dans la lumière sous le doigt ; on y monte de niveau et on la fait
évoluer.

🔴 **POURQUOI CE LOT EXISTE** — *« Met les cartes en jeu pour moi tester, met aussi de quoi me
donner des tickets »* (Maxim). La maquette ne suffisait plus : il faut les tenir en main.

### Ce qui change pour les gens

· **Les 11 héros** remplacent les 6 créatures de test : Dragon du Doudou, Thor, Bahamut, Nian,
  Kitsune, Loki, Sun Wukong *(3 stades)* ; Korrigan, Saint Georges, Ifrit, Anansi *(1 stade)*.
· **L'invocation** : 1 ticket = 1 carte, héros au hasard, au stade 1. La variante suit la table :
  Base 70,3 % · Or 16,1 % · Ombre 8,0 % · Élémentaire 4,0 % · Prismatique 1,6 %. Le full art ne
  tombe pas : aucun héros n'en a encore.
· **La révélation** : la carte arrive de dos et se retourne ; une lueur d'autant plus forte que
  la variante est rare.
· **Les doublons** *(proposition g, acceptée sur la fiche du 23/09)* : +25 XP, et une meilleure
  variante améliore la carte possédée, qui garde son stade.
· **L'évolution** : du stade s au stade s+1 au niveau 3 × s, pour un éclat.
· **La carte en grand** : la lumière suit le doigt — le chrome du prismatique, le reflet de l'or.
· **Les probabilités** s'affichent depuis l'écran, calculées par le code du tirage lui-même.
· **Un bouton de test « +10 TICKETS »** *(dette D1)*.
⛔ **Ce que ça ne touche pas** : la poussette, ses lots, le cadeau du jour, le serveur. **Pas
d'effets animés sur les cartes** (particules, brume, métal en fusion) : c'est le lot suivant.

### 🔴 Les décisions à ne pas défaire

| | |
|---|---|
| **La carte se mesure en « u » = 1 % de sa largeur** | Comme les `cqw` de la maquette : la même carte en miniature et en grand. Une cote en pixels casserait l'une des deux. |
| **Les pourcentages affichés se CALCULENT depuis les poids du tirage** | `GS.probas()`. Jamais une valeur recopiée à la main : l'affichage est une obligation (Apple, Google), il ne doit pas pouvoir mentir. |
| **Les illustrations s'importent en WebP avec mipmaps** (`cartes/*.jpg.import`) | Par défaut Godot les importe sans perte : ~1,5 Mo chacune au lieu de 185 Ko. |
| **Un `cadrage` par héros et par stade** (`game_state.gd`) | La carte ne montre que ~69 % de la hauteur de l'image, et les têtes sont haut. |
| **Sauvegarde v2** | Une sauvegarde v1 garde ses tickets, son XP et ses pièces ; ses créatures, retirées du jeu, sont ignorées. |

### 📏 Mesuré

· **Le tirage : 100 000 tirages simulés**, écart maximal **0,17 point** par variante, aucun full
  art. `tests/test_tirage.gd` vérifie aussi qu'aucune illustration ne manque.
· **137 cartes construites et dessinées** (chaque héros × stade × variante, recto et verso), aucune
  erreur — `tests/test_cartes.tscn`.
· **Les shaders compilent en OpenGL ES 3.0** (ANGLE, le langage de WebGL2) et en OpenGL : captures
  de la collection, d'une carte en grand et d'une invocation — `tests/capture_cartes.tscn`.
· Le paquet du jeu passe de **1,5 à 7,2 Mo** (illustrations 4,5 Mo, polices 1,2 Mo). Les anciennes
  figurines et les tests sont exclus de l'export.

⚠️ **Non couvert** :
· **Pas encore vu sur le téléphone** : c'est le test de Maxim ci-dessous.
· Les effets animés des variantes — lot suivant.

### Actions manuelles

· Aucune : le jeu est déjà servi par le NAS.

### Tests — sur le téléphone, `https://192.168.0.17:18443`

- [ ] La poussette tourne comme avant
- [ ] LA COLLECTION → « +10 TICKETS » ajoute 10 tickets
- [ ] INVOQUER : la carte arrive de dos, se retourne, montre le héros et sa variante ; un ticket de moins
- [ ] 20 invocations : plusieurs variantes différentes, pas de plantage
- [ ] Un doublon dans une meilleure variante améliore la carte possédée
- [ ] Toucher une carte : elle s'ouvre en grand, la lumière suit le doigt
- [ ] Faire évoluer une carte (il faut des éclats : le lot ÉCLAT de la poussette) : l'illustration change
- [ ] Fermer l'onglet, revenir : la collection est toujours là

---

## ✅ **La poussette jouable, et les six premières cartes** — **EN PROD** *(22/09/2026)*

**En clair.** On lâche des jetons au doigt sur le bloc d'une machine à poussée. Le bloc les
emmène, les dépose sur le plateau, pousse la masse, et ce qui franchit la gouttière rapporte de
l'XP, des tickets et des éclats. Les tickets ouvrent des cartes dans une collection de six.
Tout est sauvegardé : le tas reste où on l'a laissé.

🔴 **POURQUOI CE LOT EXISTE** — il fallait savoir si le geste tenait avant de construire quoi que
ce soit dessus. Un premier essai (« le dégagement », gratter une gangue) a été **jeté après test
sur téléphone** : aucun spectacle, aucune tension. La poussette l'a remplacé.

### Ce qui change pour les gens

· **Le mini-jeu** : temps réel, aucun bouton dans le jeu, on touche le bloc directement. On peut
  **garder le doigt appuyé** pour semer une rangée.
· **Le tapis roulant** : les jetons posés sur le bloc voyagent avec lui, puis **basculent** sur le
  plateau quand il se retire. Le cycle complet d'un jeton prend plusieurs allers-retours.
· **Trois lots placés par rareté** : `XP` près du bord *(banal)*, `TICKET` au milieu *(normal)*,
  `ÉCLAT` tout au fond *(rare)*. **La distance est le prix.**
· **Un popup de gain** qui arrête complètement la machine jusqu'à validation.
· **La collection** : six cartes avec cadre, illustration, affinité, rôle, PV/ATT, rareté, `FOIL`.
· **Le cadeau du jour** au premier lancement de la journée.
⛔ **Ce que ça ne touche pas** : il n'y a **aucun combat** dans le jeu. Aucun PvE, aucun PvP,
aucun backend, aucun compte.

### 🔴 Les décisions à ne pas défaire

| | |
|---|---|
| **Un seul poussoir, plateau court** | 425 px de tas pour 160 px de course. À 987 px, la poussée mourait avant le bord et le plateau saturait : **le joueur se retrouvait bloqué**. |
| **Le collideur du poussoir est sa seule FACE avant** | Sinon, en reculant, il racle les jetons au lieu de se dérober. Les jetons *sur* la plaque sont sur un **calque séparé** — ils ne voient ni la face ni le tas. |
| **`linear_damp = 1.4`, frottement `0.08`** | À 3,0 / 0,40 les jetons étaient collants : la poussée se dissipait avant de sortir du tas. **Ils doivent glisser.** |
| **`GEO_VERSION` dans `pusher_screen.gd`** | À incrémenter **dès qu'une cote du plateau bouge**. Sans ça, une vieille sauvegarde recharge des corps à l'intérieur du poussoir. |
| **Le cadre des cartes est du CODE** | L'illustration est générée, le cadre est dessiné par le moteur. C'est ce qui fera que 200 cartes se ressemblent sans qu'aucune illustration n'ait à être cohérente avec les autres. |

### 📏 Mesuré

· **60 images/seconde à 115 corps physiques**, sur Xiaomi 14T Pro, Chrome, WASM sans threads.
· **Falaise de performance mesurée** : 145 corps → 60 fps · **205 corps → 3 fps**.
· **0 avertissement NaN sur 900 images**, vérifié sur un tas neuf **et** sur une vieille
  sauvegarde réinjectée exprès *(un garde-fou se prouve avec deux témoins)*.
· Transfert réseau : 39,5 Mo de `.wasm` → **10 Mo** compressés.

⚠️ **Non couvert, et c'est assumé** :
· **La mesure du geste n'a jamais été faite sérieusement.** « Maxim le relance-t-il dix fois sans
  qu'on le lui demande » n'a pas été observé — le prototype a surtout servi de banc de réglage.
· Aucun test par quelqu'un d'autre que Maxim.
· Aucun test sur un autre téléphone, ni sur iOS.
· L'équilibrage de l'économie (XP, tickets, éclats) n'a jamais été regardé.

### Actions manuelles

**Aucune** pour rejouer : le dossier `web/` est monté en direct dans le conteneur, **recharger la
page suffit**.

Pour **redémarrer le serveur** après une modification de `nginx.conf`, sur le NAS :
```bash
cd /volume1/docker/_NOUVEAU_PROJET && sudo docker compose up -d --force-recreate
```

### Les tests après le deploy

- [ ] `curl -sk -o /dev/null -w "%{http_code}\n" https://192.168.0.17:18443/index.html` → `200`
- [ ] `ls -la web/index.wasm web/index.wasm.gz` → **le `.gz` doit être ≥ au `.wasm`**
- [ ] Ouvrir `https://192.168.0.17:18443/` **sur le téléphone**, accepter l'avertissement de
      certificat
- [ ] Le compteur en bas à droite affiche **≥ 50 fps** avec le plateau garni
- [ ] Semer au doigt : les jetons se posent **sur le bloc**, voyagent, puis **basculent**
- [ ] Faire tomber un lot : la machine **s'arrête**, le popup s'affiche, `EMPOCHER` la relance
- [ ] **Non-régression** : aller dans LA COLLECTION, invoquer, revenir — le tas est intact
- [ ] Fermer l'onglet, rouvrir : **le tas est exactement où on l'a laissé**

---

## 🗑️ Écarté en route — pour ne pas le refaire

| Quoi | Pourquoi |
|---|---|
| **« Le dégagement »** *(gratter une gangue au pouce)* | Testé sur téléphone, jugé mort dans la main. **Aucune des quatre propriétés d'un bon mini-jeu** : pas de ratio effort/spectacle, pas de récolte qui s'empile, pas de presque-raté, pas de variation. |
| **Le plinko à 3 points de largage** | Écrit puis jeté avant test : **le choix du joueur y est une illusion**, la trajectoire est randomisée dès le troisième rebond. |
| **Deux poussoirs, deux étages** | Construit et testé. Trop compliqué, et les jetons se **téléportaient** visuellement d'un étage à l'autre. Un seul poussoir fait le même travail. |
| **Le détourage automatique des illustrations** | **Cinq tentatives, cinq échecs.** Contour doux sur fond de ton voisin = impossible sans outil dédié. La solution est une ligne de prompt à la source. |
