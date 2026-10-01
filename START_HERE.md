# 🌱 START HERE — `LA POUSSETTE` *(nom de travail, pas décidé)*

> **À lire au début de CHAQUE nouvelle conversation.** Maxim dira « lis START_HERE.md ».
>
> ⛔ **Les règles du § LES RÈGLES ne sont PAS des suggestions** : chacune a été payée par un
> défaut réel. Celles marquées *(21/09)* ont été payées **sur ce projet-ci**.

## ⚡ Protocole (fais exactement ça)

1. Tu es Claude, tu bosses avec **Maxim** (solo dev) sur **La Poussette**. Français, tutoiement,
   ton direct.
2. Après avoir lu ce fichier : **vérifie l'état réel** (`curl -sk -o /dev/null -w "%{http_code}\n"
   https://192.168.0.17:18443/index.html`), **résume en 2 lignes** où on en est, puis **annonce le
   LOT EN COURS** et **demande : « on part là-dessus ou tu as autre chose ? »**.
3. Selon sa réponse, **va lire le(s) doc(s) du routeur** (§ Routeur) **AVANT d'agir**.
4. ⛔ **On s'aligne AVANT de coder.** Fiche d'alignement, puis **attendre l'accord** :
   - **Ce que je compte faire** — approche + 1-2 alternatives écartées · fichiers touchés · effort
     **en sessions** · arbitrages à trancher
   - **Ce que ça impacte** — **crash** et **valeur fausse silencieuse**, évalués séparément · ce
     que ça NE touche pas · migration oui/non
   - **Les tests après** — checklist copiable, **téléphone compris**
   - *Seule exception : bugfix trivial (1-3 lignes).*
5. Fournis toujours les **commandes exactes**.
6. 🔴 **À LA FIN DE CHAQUE LOT, applique la CHECKLIST DE CLÔTURE** — de toi-même.

---

## 🅰️ OÙ ON EN EST — *vérifié en direct le 29/09/2026, 9 h 09*

> **Le jeu tourne sur le téléphone de Maxim** (https://192.168.0.17:18443/, installable en app) **et chez les cousins**
> (https://jeu.naspoizot.synology.me, derrière un code de 5 mots — INFRA § Le jeu PUBLIC ; aucun backend : chacun sa
> partie dans son navigateur). La Nébuleuse tourne à 34-43 images/s sur le web (D13).
> **La Nébuleuse** (la machine, en 3D) : on lâche des pièces au doigt ; les objets tombés s'envolent jusqu'au bandeau :
> la **poussière d'étoile**, l'**étoile d'invocation**, une **pierre** (six types, ou la lune). **Chaque jour, 12 objets
> connus d'avance** (le plateau du jour), puis « revient demain » ; **les pièces ne se rechargent plus** : elles viennent
> des **Présages** (3 défis par jour, un défi de la semaine) et du cadeau du jour.
> **L'Atlas** : **31 héros** — 8 **Légendes**, 11 **Mythes**, 12 **Héros** (plus rares, plus forts, plus lourds dans le
> deck) — et **9 sbires** ; **les éclats** (5 par carte invoquée) **obtiennent la carte qu'on veut** (sauf le Full art) ;
> jamais de Full art ni de prismatique en double ; six variantes ; **la carte du Carré** (les 4 chiffres sur le cadre, le full art casse la
> fenêtre) ; **la carte en grand se tourne au doigt, en 3D : son dos dit sa légende et son pouvoir** ; LVL et évolution
> par pierre ; **en haut, le deck qui combat et « Mes decks »** (28/09).
> **L'Astrolabe** (28/09, 22 h 27 — toute la barre du bas est ouverte) : on y invoque, dans un **ciel**. **Le Grand Ciel**
> (Sbire 60 %, Héros 25 %, Mythe 11 %, Légende 4 % ; Full art 0,1 %) ; **le Ciel du Peintre** — Full art ×2, jamais un
> sbire, **le 100ᵉ garanti**, refermé au premier Full art, **la première ×10 offerte**.
> **Le Voyage** : le **Carré des astres** (le combat), trois onglets — **l'Aventure** (10 terres × 10 niveaux), **le Duel**
> (une cote, un adversaire de ta force), **le Classé** (Météore → Zénith, une saison par mois) — et **Mes decks**. Les
> adversaires du Duel et du Classé sont l'ordinateur, sous le nom d'un personnage ; 5 victoires par jour → de la poussière ;
> la victoire parfaite (9 à 0) a sa constellation d'or partout.
> **Le son** (29/09) : la pièce qui touche, le froissement du poussoir, le « cling » du gain **en cascade**, l'objet, la
> fanfare du plateau vidé, **deux musiques calmes** (la Nébuleuse : Starfield Romance ; les autres écrans : First Light
> Particles ; chacune reprend où elle en était ; à 50 % par défaut) ; **de vraies pièces** (la pièce lâchée, le bac, les paquets) — **choisis par Maxim** à l'écoute
> (29/09, 9 h 16 ; la musique à 12 h 26). **L'invocation a sa bande-son calée sur le rituel** (céleste : le souffle, les étoiles
> qui montent, le verrou, la révélation au retournement — `Son.partition`). **Tout sonne dans la même salle, en stéréo**
> (`design/sons/espace.py`, ES2, cuit dans les fichiers ; le grave refait pour le haut-parleur du téléphone). **Les
> Présages sont aussi le Menu** : Réglages (musique, effets, vibrations), **Code cadeau** (`codes_cadeaux/codes.py`, sans
> serveur ; BIENVENUE = 5 étoiles), Compte et Amis scellés (les comptes : FEATURES ligne 6).
> **Le tout premier lancement** : le cadeau du jour, puis **le premier pack offert, guidé** (l'Astrolabe → le pack → le
> Voyage → le premier combat guidé).
>
> 📏 **Mesures à relire** — 🔄 *28/09 : Maxim teste, il ne joue pas ; l'usage se lit chez **le cousin et sa femme**
> (mémoire `maxim-teste-ne-joue-pas`).* **Le 5/10** : ont-ils ouvert le Duel ou le Classé ? vident-ils leur plateau du jour, reçoivent-ils leurs défis ? **Le 12/10** : la journée, trop courte ou trop longue ? Le Ciel du Peintre : la ×10 offerte prise, leur compteur, refermé ? Avec le son, sa femme joue-t-elle plus longtemps ? **Le 1/11** : leur rang à la fin
> de la saison du Cygne, et jouent-ils encore une fois leurs 5 victoires du jour faites ? **Sa femme lit-elle mieux les chiffres
> en combat** (la loupe, 29/09) ? Leurs retours sur les rangs des
> héros et sur l'accueil (pack ouvert, premier combat joué ?). Sur le téléphone de Maxim : le Maître, en haut de
> l'échelle, joue-t-il sans saccade ?

### 🟠 CE QUI RESTE OUVERT — par ordre d'urgence

**⓪** **Les comptes** (FEATURES ligne 6) — ✅ **le serveur est en place (29/09)** : Nakama 3.41 sur le VPS de Maxim,
`https://lapoussette.duckdns.org` (INFRA § le serveur des comptes). ✅ **le jeu s'y sauvegarde (29/09, 23 h 31)** : le compte de
l'appareil, la partie envoyée en arrière-plan (`compte.gd`), le Compte dans le Menu. ✅ **Lier par mail (23 h 41)** : « Lier mon compte »,
« J'ai déjà un compte » (retrouver sa partie sur un autre téléphone). **Reste** : Google et Apple **avec l'app** (pas le NAS : la cible, c'est l'app + le VPS) (l'identifiant OAuth : Maxim, chez Google) ; une page de confidentialité (RGPD)
avant d'ouvrir au public ; redémarrer `jeu-public` (la CSP du portier).
**①** **Les retours de Maxim sur le téléphone** (la journée, la collection, les rangs, l'ouverture) et sur le Duel et le
Classé. Puis les réglages provisoires qui restent (D11) : les taux des rangs et leurs bonus, le « + » du plateau
(« bientôt »), les récompenses de saison, les prix en éclats. *Idée gardée* : sous une carte « À découvrir » de l'Atlas,
son prix en éclats (rien ne dit qu'on peut la toucher pour l'obtenir).
**②** **Les 5 sbires de l'Aventure n'ont pas d'image** (Farfadet, Draugr, Oni, Ondine, Raijū — D12) : illustrés, ils
deviendraient invocables.
**③** **La Nébuleuse ne tient pas 60 images/s sur le web** (D13) : l'app native (Codemagic) le dira.
**④** **Les événements du calendrier** (le Grand Carré 4 × 4, les thèmes des saisons — DECISIONS 26/09 ; et des ciels à
thème dans l'Astrolabe, une fiche dans `Portails.LISTE`) ne sont pas faits.
**⑤** **Le nom du jeu n'est pas choisi.** « La Poussette » est un nom de travail. La Tarasque manque.
**⓪bis** 🗓️ **L'économie et la Nébuleuse de demain (DECISIONS 30/09 et 01/10)** : ✅ la Supernova et le cœur d'étoile
(30/09, 23 h 57). 🔄 *01/10 — les 18 points de ChatGPT, commentés par Maxim (« on ne vend ni la chance ni la victoire ») ; l'ordre
proposé par Claude, 🟡 à confirmer :* la Nouvelle machine (3 cœurs) → la série de 7 jours → **la machine cosmique** (un vrai meuble,
à thèmes) → les Trésors → le banc de l'économie (à 150 cartes, un joueur gratuit ne doit pas mettre 2 ans) → la pose en grand et un
premier style → le premier événement (2 prototypes de mini-jeux, joués par le cousin et sa femme) → les Maîtrises (avec le cadran) →
la boutique (une monnaie payante pour du connu : le pass de 3 mois, les styles, les thèmes ; après un juriste). En fond : les cartes
vers ~150. Les coûts relevés (éclats ×2,5, niveau 250, pierres 3 et 10).
**⑥** **Les idées de Maxim pour la Nébuleuse (29/09)** — reprises au-dessus (⓪bis) : une **jauge** que remplissent les pièces tombées dans
les fentes — pleine, la machine passe en **« super machine »** (gains doublés) ; des **objets d'événement** et des mini-jeux
programmés 2 à 3 jours d'affilée (comme Clash of Critters) ; des packs **« Nouvelle machine »** (avec la boutique).

---

## 🎬 LE LOT EN COURS

> ### **À choisir avec Maxim** — ses retours du téléphone (la journée, la collection, les rangs, l'ouverture) et sur le Duel
> et le Classé (gardés pour plus tard) d'abord ; sinon, § CE QUI RESTE OUVERT.
>
> #### *Le lot qui vient d'être clos — la Nébuleuse refaite pour les gros paquets (29/09, en ligne à 19 h 54)*
>
> Maxim : *« ça fait jeton, on veut un bruit de pièce, comme dans les vrais coin pushers […] la satisfaction c'est quand un gros
> paquet tombe d'un coup »*. Tout le plateau du jour posé, chaque objet sur un amas ; de vraies pièces (Freesound CC0) et les
> paquets ; deux fentes sur les côtés, le bloc du haut presque vide, des défis à 35 pièces (DECISIONS 29/09). `plateau.gd`
> (`a_poser`), `pusher_screen.gd` (`_poser_avec_amas`, `FENTE`), `design/sons/pieces.py`, `sim_poussoir` (`deux_jours`).
> 🗓️ *Idée de Maxim pour la boutique* : des packs avec **une « Nouvelle machine »** (un plateau de plus). **Pas vu sur le téléphone.**
>
> #### *Juste avant — deux musiques calmes (29/09, en ligne à 18 h 05)*
>
> Un joueur : *« plus doux et cosmique »* ; les cosmiques : *« film d'horreur »* ; Maxim : *« CA0 pour la Nébuleuse et l'autre pour le
> reste »*. `Son.musique_de`, la place de chaque musique gardée ; `design/sons/mesure_musiques.py` (choisir une musique par la
> mesure). Et le cadeau du jour sur deux lignes. **Pas vu sur le téléphone.** En cours : le son des pièces (*« ça fait jeton »*).
>
> #### *Juste avant — l'espace du son (29/09, en ligne à 13 h 14)*
>
> Maxim : *« les musiques sonnent collé-collé, mais elles ne sont pas dans l'App »* — au haut-parleur, *« plate, sans espace »*.
> Mesuré : tout mono, tout sec, la musique dans un grave que le téléphone ne joue pas. Quatre versions d'une scène → **ES2, la
> salle** : `design/sons/espace.py` (cuit par `preparer_jeu` et `invocation.py` ; les secs dans `design/sons/secs/`). **Pas vu
> sur le téléphone.**
>
> #### *Juste avant — la bande-son de l'invocation, une musique plus vive (29/09, en ligne à 12 h 26)*
>
> Maxim : *« pas fan de la musique générale, trop lente/douce ; l'invocation doit être spectaculaire, marcher avec
> l'animation ; le petit clap à la fin est horrible »* → *« IV1 · MG9, le son général à 50 par défaut »*. `design/sons/invocation.py`
> (la bande-son, synthétisée), `son.gd` § `partition`, `collection_screen` § `_partition_simple`, `_partition_multi` ; le film :
> `tests/film_invocation.tscn`. **Pas vu sur le téléphone.** Ensuite : **les comptes** (§ CE QUI RESTE OUVERT ⓪).
>
> #### *Juste avant — le son dans tout le jeu (29/09, en ligne à 10 h 25)*
>
> Maxim : *« faudrait mettre du son dans tout le jeu »*. L'interface, l'invocation (la rareté de l'Or au Full art, le rang), le
> combat (sa musique, la cascade des retournements), la collection. `son.gd` (le lecteur, `changer_musique` par le bus),
> `design/sons/catalogue.py` (les candidats G à Z). Les sons de Maxim en ligne à 10 h 44 ; **pas vu sur le téléphone.**
>
> #### *Juste avant — la Nébuleuse sonne ; les Présages deviennent le Menu (29/09, en ligne à 9 h 09)*
>
> La femme du cousin : *« ce serait encore pire si j'avais le son »* ; Maxim : *« la page Présage pourrait être la page Menu
> […] un Redeem code »*. `son.gd` (les moments de la machine, la cascade), `reglages.gd` (deux bus, les vibrations),
> `codes.gd` + `codes_cadeaux/codes.py`, le Menu (`presages_ecran.gd` § `_menu`) ; la fabrique des sons : `design/sons/`
> (CC0). Tests : `test_son`, `test_codes`, `capture_menu`. Les sons de Maxim en ligne à 9 h 16 ; **pas vu sur le téléphone.**
>
> #### *Juste avant — les chiffres des cartes se lisent en combat ; le point d'or se voit (29/09, en ligne à 8 h 15)*
>
> La femme du cousin, via Maxim : *« elle avait du mal à voir les numéros sur les cartes »* ; Maxim : *« le point d'or manque
> un peu de visibilité »*. La carte de la main touchée grandit à la taille du plateau (`carre_ecran.gd` § `LOUPE`), le doigt se
> lit sur la place au repos ; la main adverse descend en grand au toucher ; la main un peu plus large ; le point d'or plus gros,
> un anneau qui bat (CHANGELOG). **Pas vu sur le téléphone.**
>
> #### *Juste avant — ⑩ l'Astrolabe : deux ciels, un Full art garanti (28/09, en ligne à 22 h 27 ; le cadeau en ×10 à 22 h 38)*
>
> Maxim, 28/09 : *« on peut débloquer la dernière page maintenant, les portails […] un portail normal […] et un portail
> Full art ×2 […] le 100ème ticket garantit une Full art »* ; *« offre la première invocation Full art aux gens »* ;
> *« fais un beau design »* ; *« valide direct, pas besoin de capture »*. **En ligne à 22 h 27** (CHANGELOG, DECISIONS) :
> `portails.gd` (les règles), `GS.tirer` / `invoquer_multi` par ciel, `astrolabe_ecran.gd` (la page ; ses fonds :
> `render_objets.py --bannieres`), « Mes decks » en haut de l'Atlas, l'accueil du premier pack par l'Astrolabe. Tests :
> `test_portails` (banc de 12 000 joueurs), `capture_astrolabe`. **Pas vu sur le téléphone.**
> *Juste avant (20 h 36)* — la victoire parfaite s'anime aussi au Duel et au Classé (`_fin_arene`).
>
> #### *Avant — le rang d'une carte se voit ; l'ouverture sans saccade (28/09, en ligne à 20 h 18)*
>
> Maxim, 28/09 : *« on sait pas quand on a une carte mythe, légende, héros ? »* Avant, le rang n'était écrit qu'en tout
> petit dans le bandeau de la carte (un Héros y montrait son rôle), et dans le texte de la carte en grand ; l'invocation ne le
> disait pas (son portail suit la variante). **En ligne le 28/09, 20 h 18** (CHANGELOG ; dernière rangée du
> canevas du Voyage) : le rang dans le bandeau de chaque carte, en couleur (`Style.couleur_rang`, `Vignettes.VERSION` 6) ;
> « LÉGENDE » au retournement ; une Légende au centre d'une ×10, une pastille sur les Mythes et les Légendes, le bilan qui les
> compte ; l'Atlas rangé par rang. **Et la saccade de l'ouverture** (*« l'animation d'ouverture de carte lag au début »*) :
> les illustrations restent en mémoire (`CarteView.texture_art`), le voile paraît d'abord et l'illustration se décode sur
> lui, le portail ne part qu'après ; le préchauffage couvre l'élémentaire de chaque type et la carte 3D. Banc :
> `tests/banc_invocation` (une fois partie, aucune image > 33 ms), `tests/banc_image`.
>
> #### *Juste avant — ⑧ lot B, la collection (28/09, en ligne à 18 h 48)*
>
> Tout est au CHANGELOG (28/09, 18 h 48) : les éclats (5 par carte ; ils obtiennent toute carte, toute variante sauf le Full
> art), jamais de Full art ni de prismatique en double, l'évolution à 5 / 10 et 1 / 2 pierres, la sauvegarde v4.
> *Juste avant (28/09)* — ⑧ lot A, la journée (16 h 40) ; le Duel et le Classé (14 h 53) : CHANGELOG et DECISIONS.
>
> *Avant (27-28/09)* — la carte v6, la 3D et son dos, le prismatique, les sbires, les rangs des héros, le premier pack
> offert et guidé : CHANGELOG et DECISIONS.
>
> #### *Avant (25-27/09)* — ⑭ les objets de l'univers, ⑮ l'interface vivante, ⑱ le choix du combat (27 démos, puis le
> Carré des astres), l'Aventure, Mes decks, l'accès des cousins (⑯). Le pourquoi : DECISIONS ; le détail : CHANGELOG.
> *Ce que Claude apporte encore à ⑱* : les points ouverts de ⑧ et ⑨ (FEATURES), les chiffres d'aujourd'hui
> (`tests/sim_poussoir`, `tests/banc_cartes`), deux ou trois directions comparées, avec un avis tranché.

---

## 🧾 LES DETTES OUVERTES

| | La dette | Où | Échéance |
|---|---|---|---|
| **D1** | **Outils de test dans le jeu** : `+50 pièces`, `Regarnir`, `RAZ` (Nébuleuse), `+10 étoiles`, `Prisma`, `Full art`, **`Peintre +10`**, **`Rouvrir`** (l'Astrolabe, depuis le 28/09 ; avant, l'Atlas), **le Duel et le Classé ouverts** et **« Test : fin de saison »** (Voyage, 28/09) — **cachés**, un **appui long sur l'onglet « Nébuleuse »** les montre | `pusher_screen.gd` § `_ui()` · `astrolabe_ecran.gd` § `_construire_outils` · `main.gd` § `_basculer_outils` · `barre_nav.gd` (`appui_long`) · `GS.donner_etoiles()` · `pusher_screen.demo_gain()` · `voyage_ecran.gd` § `montrer_outils` · `Arene.ouvert_pour_test` | 🔄 **Réglée pour ⑯ le 27/09** : les outils ne s'ouvrent que depuis le réseau local (192.168.…) — `main.gd` § `outils_permis` ; ils restent à retirer avant un store |
| ~~**D2**~~ | ~~Filigrane en étoile sur les 6 images générées~~ | — | 🔄 **Soldée le 23/09** : les figurines ne servent plus (exclues de l'export) ; les illustrations des héros sont d'autres images |
| ~~**D3**~~ | ~~Les illustrations ne sont pas détourables~~ | — | 🔄 **Soldée le 22/09** : avec les cartes, rien n'est à détourer |
| **D4** | **Le compteur d'images** est dans les outils de test (caché depuis le 23/09) | `pusher_screen.gd` § `lbl_perf` | 🔄 Comme D1 : réservé au réseau local depuis le 27/09 |
| ~~**D6**~~ | ~~Le code affiche encore des raretés commune/rare/légendaire~~ | — | ✅ **Soldée le 23/09** : les cartes n'ont plus que des variantes |
| ~~**D7**~~ | ~~Le code a encore les affinités ocre / ardoise / mousse~~ | — | ✅ **Soldée le 23/09** : remplacées par les types (`GS.TYPES`) |
| **D5** | **`MAX_PIECES = 270` : un plafond au-dessus de l'équilibre de la machine (~255, pièces de 0,46 depuis le 27/09 ; avant : 360 pour ~335)** *(25/09, revu 27/09)* | `pusher_screen.gd` | À relire avec le compteur du téléphone. *(28/09 : plus de recharge des pièces — ⑧ lot A ; le plafond ne se ressent plus que si l'on lâche tout d'un coup)* |
| ~~**D9**~~ | ~~Chaque gain réécrit toute la sauvegarde~~ | — | ✅ **Soldée le 25/09** : sauvegarde différée, le tas dans son fichier |
| ~~**D8**~~ | ~~« Pas de place ici » : une pièce ne peut pas se poser sur une autre~~ | — | ✅ **Soldée le 25/09** : les pièces se superposent (⑦) |
| **D10** | **L'essai 3D (`/essai/`) utilise encore les anciennes images** (`objets/xp.png`, `ticket.png`) — gardées pour lui seul *(`eclat.png` sert de nouveau au jeu depuis le 28/09 : l'icône des éclats)* | `essais/essai_3d.gd` | Supprimer l'essai (et ces images) quand on n'en a plus besoin — **il a été adopté le 24/09** |
| **D12** | **Les sbires de l'Aventure sans illustration** *(27/09)* : Farfadet, Draugr, Oni, Ondine, Raijū montrent leur pierre (les 9 illustrés sont en ligne depuis le 27/09, 23 h 58). Une image chacun les rendrait invocables (`"image": true` dans `MoteurCarre.SBIRES`, l'image dans `cartes/`). | `MoteurCarre.SBIRES` · `carte_view.gd` § `_image_sbire` | Quand Maxim les génère |
| **D13** | **La Nébuleuse ne tient pas 60 images/s sur le web** *(27/09)* : 34-43 images/s, physique 12-14 ms à ~260 pièces (Xiaomi 14T Pro, WASM sans threads). Ce qui coûte : le nombre de pièces qui se touchent (solveur allégé et physique à 30 Hz : écartés au banc) | `pusher_screen.gd` (`R_PIECE`, `MAX_PIECES`) · `project.godot` (1 pas par image) | **L'app native (Codemagic)**, mesurée au compteur ; sinon, moins de pièces encore, ou la physique sur plusieurs cœurs (threads + en-têtes COOP/COEP) |
| **D11** | **Des réglages provisoires, en attente de ⑱** : les rangs au tirage (27/09) — `GS.RARETES` Sbire 60 %, Héros 25 %, Mythe 11 %, Légende 4 %, et leurs bonus (`MoteurCarre.BONUS_RANG`, `POIDS_RANG`) ; l'Aventure (27/09) — 1ʳᵉ victoire : `30 + 10 × terre` de poussière, `Aventure.ETOILES_BOSS = 3`, coffres (pierre, 1 étoile, 2 étoiles + lune) ; **la collection (28/09, ⑧ lot B)** — `GS.ECLATS_PAR_INVOCATION = 5`, `PRIX_RANG` (60 / 200 / 450 / 900), `PRIX_VARIANTE` (×1 à ×10), `ECLATS_DOUBLON`, `POUSSIERE_PAR_NIVEAU = 100`, `NIVEAU_PAR_STADE = 5` ; le « + » du plateau du jour n'ouvre qu'une bulle « bientôt » ; **la journée (28/09, ⑧ lot A)** — `Plateau.CONTENU` (1 étoile, 3 pierres, 8 poussières), `Plateau.CHANCE_LUNE = 0.12`, `Presages.PIECES_DEFI = 60` (réglé au banc), `LUNE_BONUS = 1`, la semaine `5 jours → 3 étoiles + 200`, `GS.PIECES_CADEAU = 25` ; **le Duel et le Classé (28/09)** — `Arene.POUSSIERE_VICTOIRE = 30`, `VICTOIRES_JOUR = 5`, `Classe.RECOMPENSES` (Météore 50 poussières … Zénith 5 étoiles + 500), `Duel.K = 24` ; leur difficulté est réglée au banc, pas provisoire (`Fantomes.COTE_*`, `FORCE_*`, `Classe.COTE_PALIER_0`, `COTE_PAR_PALIER`) | `game_state.gd` · `pusher_screen.gd` · `carre/arene.gd` · `carre/classe.gd` | **⑧ (le lot proposé)** |

---

## ⏰ LES ÉCHÉANCES DATÉES

| Quoi | Quand | Ce qui se passe si on rate |
|---|---|---|
| *(aucune)* | — | Pas de deadline sur ce projet, c'est assumé |

---

## 🎯 C'est quoi `La Poussette`

- **Un jeu mobile de collection.** Une machine à poussée *(coin pusher, « la Nébuleuse »)* sert de
  robinet : on y gagne de la **poussière d'étoile** (les niveaux), des **étoiles d'invocation** et des
  **pierres** (les évolutions). Les étoiles donnent des **cartes**, qui serviront à se battre en PvE
  puis en PvP asynchrone.
- **Les cinq piliers demandés par Maxim** : collection · gacha · récompense journalière ·
  mini-jeux · **jamais bloqué plus de 2 jours**.
- **L'univers** : **folklore et légendes** — Wukong, Thor, Loki, Bahamut, et Saint Georges avec
  le Dragon du Doudou. Évolutions en 1 ou 3 stades, du mignon au badass.
- **La cible** : des **adultes, hommes et femmes, qui paient**. Registre *art toy* de
  collectionneur (POP MART), pas jouet pour enfant.
- **Modèle** : l'argent achète la **prestance** (foil, cosmétiques, vitesse), **jamais la
  puissance**. Un F2P atteint les sommets, il lui faut plus de temps. 🔄 *01/10 : « on ne vend ni la chance ni la
  victoire » — une monnaie payante qui n'achète que du connu (pass, styles, thèmes) ; la vitesse, seulement un bonus
  plafonné dans le pass (🟡 à confirmer, DECISIONS 01/10).*
- 🎯 **La cible du portefeuille : ~20 k€/an par app**, sur plusieurs apps et plusieurs années.
  ⛔ *Ne jamais recalculer sur 100 k€.*

### 📊 Les chiffres — dernier relevé le 28/09/2026

| | |
|---|---|
| Utilisateurs | **Maxim + des cousins** (depuis le 27/09, le site public ; chacun sa partie, aucun backend) |
| Images/seconde sur Xiaomi 14T Pro | 🔴 **33 à 35 dans la Nébuleuse** (pire image 40-47 ms), **physique 16-18 ms** à 333-356 pièces — **première vraie mesure au compteur, 27/09**. ⛔ *Le « 60 » d'avant venait de « ça freeze plus » (26/09), pas du compteur.* Combat : pas encore mesuré. **27/09, 20 h 31, pièces de 0,46 : 34 à 43 images/s, physique 12-14 ms à 253-264 pièces** (« vivable, on garde ça pour l'instant ») — D13 |
| Cartes existantes | **31 héros** (8 Légendes, 11 Mythes, 12 Héros) · **9 sbires** invocables (+5 de l'Aventure, sans image) · 97 illustrations · 6 variantes · 40 légendes |
| Contenu de combat | **Le Carré des astres** (27/09) : **l'Aventure, 100 niveaux** (10 boss écrits, 90 fabriqués) + le combat guidé ; **le Duel et le Classé** (28/09) : 6 rangs × 3 marches, des adversaires fabriqués de la cote 800 à 1 800 |

---

## 🔁 Comment on mène un lot

**① DÉMARRER.** Lire le § de la feature dans `FEATURES.md`, **puis le code**, **puis** la fiche
d'alignement, **puis attendre l'accord**.

**② LIVRER.** Exporter et déployer *(§ Routeur → `INFRA.md`)*. Fournir la checklist de tests
sans qu'on la demande.

**③ CLORE — la checklist ci-dessous.**

### ✅ LA CLÔTURE D'UN LOT — sans qu'on le demande

| | Quoi | Où |
|---|---|---|
| **0** | 🔴 **UN TITRE EN CLAIR + 2-3 lignes de langage courant** | partout |
| **1** | **L'entrée du lot** : ce qui change, les actions manuelles, les tests | `CHANGELOG.md` (en haut) |
| **2** | **La feature passe à ✅ livré**, avec sa version | `FEATURES.md` — sa ligne **et** son § |
| **3** | 🔴 **Le pointeur « LOT EN COURS » avance** | **ce fichier** |
| **4** | **La mesure** et **quand la relire** | `FEATURES.md` |
| **5** | 🔴 **Corriger toute note que le lot vient de PÉRIMER** | partout |
| **6** | Les compteurs · **rayer la dette soldée** | ce fichier |
| **7** | 🔴 **LA LISTE DES ACTIONS DE MAXIM**, complète, en fin de lot | dans le chat, en dernier |

> 🔴 **LE POINT 7.** Format : **quoi · où exactement · combien de temps · ce que ça débloque**.
> ⛔ **Zéro action de Claude dans cette liste** — si Claude peut le faire, il le fait.

---

## 🤝 Comment bosser avec Maxim

### 🆕 LE TOUR DE TABLE — avant toute recommandation

| Le département | Sa question |
|---|---|
| **Produit** | Ça sert quelle fuite ? |
| **Technique** | Ça touche quoi *(fichier:ligne)* ? Risque de **crash** et de **valeur fausse silencieuse** ? |
| **Mesure** | Quel **cadran** ça déplace, et **quand on le relit** ? |
| **Marketing** | Est-ce que ça se **raconte** ? Est-ce que ça se **montre** en 15 secondes ? |
| **Légal** | Données personnelles, IP, taux de gacha, RGPD ? |
| **Économie** | 🆓 ou 🔒, et **pourquoi** ? |
| **Contenu** | Ça demande du contenu à écrire ou à générer ? |
| **Utilisateur** | Le cas **non-IT**, l'**état vide**, le **mobile** ? |

✅ **Un département qui n'a rien à dire dit « rien ».** ⛔ **Jamais plus d'une ligne.**

### Les principes de travail

- **Qualité avant vitesse.** **Alignement avant d'implémenter.**
- **Un avis tranché, pas un panorama.** Si Claude hésite, il dit ce qu'il ferait.
- **Ne pas surestimer l'effort** — l'étalon est **~1 feature par semaine**.
- 🖼️ **Tout rendu visuel se montre AVANT d'être déployé.** Maxim juge sur des **captures du vrai
  jeu**, posées dans le canevas du lot (un seul lien, versionné) ; il répond vite (« go ») : montrer,
  puis déployer, puis clore. Ses goûts appris : mémoire `gouts-visuels-maxim`.
- 🔴 **MAXIM DÉCIDE DU GOÛT, CLAUDE DÉCIDE DE LA MÉTHODE.** *(21/09)* Voir la règle sur les
  thèmes, plus bas — elle a coûté cinq propositions rejetées d'affilée.
- **Repartir sur un chat neuf quand la conversation s'allonge.**

---

## 📏 LES RÈGLES

> 🔴 **Ce sont les garde-fous.** Celles marquées *(21/09)* ont été payées sur CE projet.

### 🧭 La méthode

- 🔴 **TROIS HYPOTHÈSES FAUSSES D'AFFILÉE = ON CHANGE DE MOYEN, PAS DE PISTE.**
  ⛔ *Enfreinte le 21/09 : cinq tentatives de détourage automatique, cinq échecs. La solution
  était une ligne de prompt à la source.*
- 🔴 **UN DÉFAUT D'ART SE CORRIGE À LA SOURCE, PAS EN POST-TRAITEMENT.** *(21/09)* Si l'image
  générée est mal cadrée, sur fond ambigu ou avec une ombre portée, **on change le prompt** — on
  n'écrit pas un algorithme pour rattraper.
- 🔴 **CLAUDE NE PROPOSE PAS D'UNIVERS.** *(21/09)* Cinq thèmes proposés, cinq rejetés : abysses,
  masques, faune spéculative, fête foraine, objets. **La méthode qui marche : Maxim envoie des
  images ou des noms de jeux qu'il aime, Claude en extrait les règles.** Il reconnaît ce qui lui
  plaît quand il le voit ; le décrire n'est pas son travail.
- **Compter, pas lire.** *(21/09)* Un `head -15` derrière un `grep` a fait passer **10 000
  avertissements pour 12**. Utiliser `grep -c`.
- **LIRE LE CODE AVANT DE PROPOSER UN MODÈLE.**
- 🔴 **Un `grep`/`find` qui ne trouve rien ne prouve rien tant que sa portée n'a pas été
  vérifiée.** ⛔ *Vécu le 20/09 : un `&&` cassé par un `cp` en échec a annulé silencieusement un
  patch, et le test suivant « prouvait » le contraire de la réalité.*
- **Une note de blocage périme** : vérifier avant de resservir un « c'est bloqué ».
- 📌 **Un Artifact n'est jamais la source unique** : il se supprime d'un clic.

### 🔬 Les mesures et les cadrans

- 🔴 **`--headless` NE REND RIEN.** *(21/09)* « 600 images sans erreur » ne dit **rien** d'un
  écran. Un fond peint par-dessus tout le plateau a passé ce contrôle sans broncher.
  ⛔ **Le seul banc valable est le téléphone.**
- 🔴 **Un plafond mesuré, jamais supposé.** *(21/09)* Xiaomi 14T Pro : **145 corps → 60 fps,
  205 corps → 3 fps**. La falaise est vers 180.
- **Un garde-fou se prouve avec DEUX témoins, le refus ET le passage.**
- 🔴 **UN MOTEUR DE JEU SE PASSE AU BANC DE MILLIERS DE PARTIES.** *(27/09)* 400 parties de parité n'avaient pas vu la
  chaîne sans fin (Anubis + Cerbère) : elle est tombée à la 17 610ᵉ du banc (`tests/banc_cartes`). Un processus qui grossit
  sans finir, c'est une boucle : la chercher par dichotomie, avec des repères sur `printerr` (la sortie normale arrive en retard).
- **Un contrôle qui ne peut pas échouer ne contrôle rien.**
- 🔴 **LE SON DU WEB SE MESURE DANS UN NAVIGATEUR.** *(29/09 — « j'entends pas le son »)* `test_son` (Godot, pilote muet)
  lisait les sons demandés, tous justes, pendant que le jeu web se taisait (un bus créé en cours de partie, relié à rien ; un
  fondu de volume qui ne passait pas). Le seul banc du son : **`outils/navigateur/son.js`** (Chrome, l'analyseur sur la sortie,
  un son témoin) — puis le téléphone.
- **Un `catch` muet transforme une panne en absence.**
- **Un correctif se remesure LÀ OÙ IL AGIT.**
- 🔴 **UN BANC DE CHARGEMENT LANCÉ DEPUIS LE NAS MESURE AUSSI LE RÉSEAU.** *(28/09)* Le projet est sur `\\nas01` : charger
  une image y coûtait 45 à 466 ms, dont ~18 ms de décodage. Le jeu en ligne, lui, a tout en mémoire. Pour isoler le décodage :
  recharger sans le cache de Godot (`CACHE_MODE_IGNORE`), le fichier est alors dans le cache du système (`tests/banc_image`).

### 💻 Le code et les données

- 🔴 **Un script qui réécrit un fichier écrit dans un `.tmp` puis renomme.**
- 🔴 **Après chaque script qui écrit, vérifier que la cible n'est pas vide.**
- 🔴 **Une sauvegarde de positions PÉRIME quand la géométrie change.** *(21/09)* Des corps
  rechargés dans un collideur → forces infinies → **6,8 millions de NaN en 600 images**, sans un
  seul plantage. Parade : une **estampille de version** qui régénère au lieu de charger.
- 🔴 **`queue_free()` est différé.** *(21/09)* Un corps « libéré » reste **une image de plus** dans
  le monde physique. `remove_child()` d'abord.
- 🔴 **Geler le jeu, c'est ARRÊTER la physique, pas le temps.** *(23/09)* À `Engine.time_scale = 0`,
  Godot fait quand même ses pas de physique, avec un pas nul, et divise par lui : **NaN à chaque lot
  gagné**, sans une erreur. `PhysicsServer2D.set_active(false)`.
- **Un banc qui ferme le popup dans la même image ne voit pas le popup.** *(23/09)* Le défaut
  ci-dessus est passé au premier banc : il faut tenir le popup ouvert comme un joueur.
- **Une liste en double est une liste fausse** : dériver, jamais recopier.
- **Un index n'est pas un identifiant.**
- 🔴 **LE CORPS PHYSIQUE A LA FORME DU DESSIN.** *(26/09)* Des billes dessinées sur les disques plats
  d'avant se sont dessinées l'une dans l'autre (les disques glissaient l'un sur l'autre) ; des objets
  amincis à 0,18 passaient sous le sol. Changer le dessin d'un objet, c'est vérifier son corps.
  `tests/sim_poussoir` vérifie qu'aucun objet n'en chevauche un autre.
- 🔴 **UN RENDU PARTIEL NE RÉÉCRIT PAS LES FICHIERS D'ENSEMBLE.** *(26/09)* Rendre deux objets a
  réécrit `contours.json` avec ces deux seuls objets, et un rendu en 256 a écrasé les originaux en 512.
  Après un rendu partiel : **tout régénérer** avant de copier dans le jeu.

### 🖼️ L'écran

- 🔴 **L'ORDRE D'AJOUT DANS L'ARBRE EST L'ORDRE DE DESSIN.** *(21/09)* Un fond ajouté après le
  monde le recouvre entièrement : la physique tournait, 107 corps existaient, **on ne voyait
  rien**. ⛔ *Une panne d'affichage ressemble à du vide, pas à une erreur.*
- 🔴 **Un plafond technique que le joueur RESSENT est un aveu de faiblesse.** *(21/09)*
  « Plateau plein » est un message de développeur. Une **contrainte de jeu** (une main limitée)
  fait le même travail et devient un plaisir.
- 🔴 **UN GLYPHE ABSENT DE CASTORO SORT EN BOÎTE SUR LE TÉLÉPHONE.** *(21/09, puis 28/09)* Emoji, « ★ », lettres en exposant (« XVIᵉ », « 1ʳᵉ ») : le web n'a pas de police du système pour les rattraper. Le PC, lui, les rattrapait — les captures ne voyaient rien ; depuis le 28/09, Castoro n'y a plus droit (`allow_system_fallback=false`). L'étoile a sa police de secours (`polices/Etoile.ttf`) ; pour tout autre signe : vérifier la police avant de l'écrire — **`python proto_degagement/tests/verif_glyphes.py <scripts .gd>`** (28/09 : « → » était en boîte ; tout le jeu passe, 48 518 caractères).
- 🔴 **UNE RETOUCHE DE RENDU SE MESURE, AVANT ET APRÈS.** *(26/09)* Resserrer la lumière des pièces
  « à l'œil » a aussi écrasé leur relief : *« ternes, plus du tout HD »*. `design/objets/mesure_pieces.py`
  sépare l'écart entre pièces et le relief dans les pièces : on règle l'un sans toucher l'autre.
- 🔴 **LA VUE DE LA MACHINE EST OBLIQUE.** *(26/09)* Une vraie boule s'y dessine en œuf, et une image
  plaquée d'en haut remonte vers le haut de l'objet. Ce qui doit paraître rond ou centré se calcule **à
  l'écran** (`objets/bille.gdshader`).
- **WebGL ne lisse pas une texture en flottants 32 bits** *(26/09)* : lue avec un filtre, elle vaut 0
  (le blanc de l'évolution disparaissait d'un coup). Des textures 8 bits.
- **Un écran ne promet JAMAIS plus que le moteur ne fait.**
- 🔴 **UN TRAVAIL LOURD SE FAIT SUR UN ÉCRAN IMMOBILE, JAMAIS AU PREMIER PAS D'UNE ANIMATION.** *(28/09 — *« l'animation
  d'ouverture de carte lag au début »*)* Décoder une illustration au moment où le portail partait : l'animation sautait
  d'autant. Le voile d'abord, le décodage sur lui, l'animation ensuite ; et ce qui se charge en plein vol (une vedette) se
  charge avant. Le banc qui le prouve compte les images UNE FOIS l'animation partie (`tests/banc_invocation`).
- 🔴 **CHANGER LE DESSIN D'UNE CARTE, C'EST INCRÉMENTER `Vignettes.VERSION`.** *(27/09)* La grille de l'Atlas montre des
  photos des cartes gardées sur le téléphone : sans ça, elle garde l'ancien dessin, sans une erreur (vu à la capture).
- 🔴 **UN RÉGLAGE SANS EFFET À L'ÉCRAN EST RÉÉCRIT AILLEURS.** *(27/09)* Le spectre du prismatique passait de 0,8 à 0,22 :
  rien ne changeait, `_appliquer_lumiere` le réimposait à chaque image. Chercher qui écrit le paramètre
  (`grep set_shader_parameter`) avant de pousser plus fort.
- 🔴 **UN DUEL MONTRE LES CHIFFRES DE SON INSTANT, PAS CEUX DE LA FIN DU COUP.** *(27/09)* L'écran du Carré
  affichait la fin du coup dès la pose : une carte prise à côté de Bahamut y avait déjà sa Marée, et 354 duels
  sur 9 425 montraient un perdant aussi fort que le gagnant (*« il avait moins de points et ça a retourné ma
  carte »*). Le moteur trace chaque instant (`MoteurCarre.poser(…, trace)`) ; `tests/verif_duels` le vérifie.
- **Quand on retire une chose, retirer aussi ce qui n'existait que pour elle.**

### 🚢 Le déploiement

- **Le healthcheck est le PREMIER contrôle après tout deploy.**
- 🔴 **Godot 4 sur le web exige un CONTEXTE SÉCURISÉ** — HTTPS obligatoire, et désactiver les
  threads **n'évite pas** ce test. *(20/09)*
- **Un déploiement ne livre que les fichiers écrits AVANT lui** — le `.gz` doit être plus récent
  que le `.wasm`.
- 🔐 **Aucun secret sur une machine qu'on rend.**

---

## 🧭 Routeur — « je veux… » → lis d'abord

| Tu veux… | Lis |
|---|---|
| Comprendre l'état / le récent | **`CHANGELOG.md`** (haut) |
| **La feuille de route — quoi faire ensuite** | **`docs/specs/FEATURES.md`** |
| **Le combat : le Carré des astres** (moteur, écran, carte, guide, glisser-déposer) | `proto_degagement/carre/` (`moteur_carre.gd` · `carre_ecran.gd` · `carte_carre.gd` · `guide_carre.gd`) · ses images : `design/objets/render_carre.py` · ses règles : `docs/reviews/CARRE-DES-ASTRES.md` · ses tests : `tests/test_carre`, `verif_duels`, `capture_carre` |
| **L'Astrolabe : les ciels où l'on invoque** (28/09, ⑩ : le Grand Ciel ; le Ciel du Peintre — Full art ×2, le 100ᵉ garanti, refermé au premier, la 1ʳᵉ ×10 offerte) | `portails.gd` (les règles, `GS.voyage["portails"]`) · `game_state.gd` § `tirer`, `invoquer_multi`, `probas`, `probas_cartes` (par ciel) · `astrolabe_ecran.gd` (la page, la vitrine, le limbe) · `collection_screen.gd` § `invoquer_dans`, `montrer_probas`, `_maj_encore`, `_couche_pour_astrolabe` · ses fonds : `design/objets/render_objets.py --bannieres` · ses tests : `tests/test_portails`, `capture_astrolabe` · le pourquoi : DECISIONS 28/09 |
| **« Mes decks » en haut de l'Atlas** (28/09) | `collection_screen.gd` § `_maj_deck`, `_ouvrir_decks` · `carre/decks_ecran.gd` (`retour_texte`) |
| **Le son** (29/09 : quand ça sonne, la cascade, les niveaux ; tout le jeu depuis 10 h 25) | `son.gd` (`NIVEAUX`, `gain`, `pose`, `rarete`, `rang`, `retourne_combat`, `fin`, `changer_musique`) · les candidats G à Z : `design/sons/catalogue.py` · `pusher_screen.gd` § `_sonner_a_la_pose`, `_sur_gain`, `_gagner_objet`, le froissement dans `_physics_process` · les fichiers : `proto_degagement/sons/` ← `design/sons/preparer_jeu.py` (`CHOIX`) · la page d'écoute : `design/sons/preparer_ecoute.py`, `design/canevas/sons/` · licences : `design/sons/sources/LICENCES.md` · test : `tests/test_son` |
| **Le Menu, les Réglages, le code cadeau** (29/09) | `presages_ecran.gd` § `_menu`, `_ouvrir_reglages`, `_ouvrir_code`, `_champ_web` · `reglages.gd` · `codes.gd` · la commande : `codes_cadeaux/codes.py` (registre privé : `codes_cadeaux/registre.json` ; public : `web/codes/codes.json`) · tests : `tests/test_codes`, `capture_menu` · le pourquoi : DECISIONS 29/09 |
| **Les comptes, le serveur** (à faire) | FEATURES ligne 6 (Nakama, le VPS de Maxim, l'app ne parle qu'au serveur) · ⑯ |
| **Le premier pack offert, l'accueil guidé** (28/09 ; par l'Astrolabe depuis 22 h 27) | `accueil.gd` · `GS.premier_pack_du`, `tirer_premier_pack`, `ouvrir_premier_pack` · ses captures : `tests/capture_accueil` |
| **La carte en 3D, son dos, les légendes** (27/09) | `carte_3d.gd` · `cartes/shaders/carte_3d.gdshader` · `dos_info.gd` · `legendes.gd` |
| **Les sbires, les rangs des héros, la puissance des cartes** | `MoteurCarre.SBIRES`, `RANGS`, `BONUS_RANG`, `POIDS_RANG` · `GS.RARETES`, `tirer_carte` · le banc : `tests/banc_cartes` (`-- 20000 0 poids`) |
| **Le Duel et le Classé** (28/09 : la cote, les rangs, les saisons, les adversaires, la poussière du jour, quitter = perdre) | `carre/fantomes.gd` (l'adversaire) · `duel.gd` · `classe.gd` · `arene.gd` (le partagé) · les écrans : `duel_ecran.gd`, `classe_ecran.gd`, `carre_ecran.gd` § `_fin_arene` · les emblèmes : `design/objets/render_rangs.py` · ses tests : `tests/test_classe`, `capture_arene`, le banc `banc_fantomes` (`-- echelle 8 250`) · le pourquoi : DECISIONS 28/09 |
| **Le rang d'une carte, l'ouverture fluide** (28/09) | `Style.couleur_rang`, `nom_rang` · `carte_view.gd` § le bandeau, `texture_art` (les illustrations en mémoire) · `collection_screen.gd` § `_annoncer_rang`, `_en_vedette`, `_maj_grille` (les sections), `montrer_revelation` / `montrer_multi` (le voile d'abord) · `main.gd` § `_prechauffer_cartes` · ses bancs : `tests/banc_invocation`, `banc_image` |
| **La collection** (28/09, ⑧ lot B : les éclats, « Obtenir », jamais de Full art en double, l'évolution à 5 / 10 et 1 / 2 pierres, la sauvegarde v4) | `game_state.gd` § `tirer`, `_recevoir`, `prix`, `obtenir`, `niveau_max`, `plan_evolution` · `collection_screen.gd` § `_maj_detail`, `_obtenir` · ses tests : `tests/test_collection`, `capture_collection`, `test_objets` |
| **La journée** (28/09, ⑧ lot A : le plateau du jour connu d'avance, les pièces sans recharge, les défis des Présages) | `plateau.gd` · `presages.gd` · `presages_ecran.gd` · `pusher_screen.gd` § `_completer_plateau`, `_maj_plateau_jour` · `carre_ecran.gd` § `_defis` · ses tests : `tests/test_journee`, `capture_journee`, `sim_poussoir -- duree=900` · le pourquoi : DECISIONS 28/09 |
| **Mes decks** (6 decks, l'éditeur, le deck choisi qui combat) | `carre/decks.gd` (la logique) · `carre/decks_ecran.gd` (l'écran) · son test : `tests/test_decks` |
| **L'Aventure** (les 10 terres, les boss, les 90 niveaux fabriqués, les ★, les coffres, la progression) | `carre/aventure.gd` · les écrans : `voyage_ecran.gd`, `chapitre_ecran.gd`, `avant_combat.gd`, `dessin.gd` · ses tests : `tests/test_aventure`, `banc_aventure` (la courbe) |
| Les règles de « La Poussée » *(💤 non retenue le 26/09)* | `docs/specs/FEATURES.md` § LA POUSSÉE |
| **Le POURQUOI d'une décision passée** | **`docs/reviews/DECISIONS.md`** |
| Déployer, exporter, les pièges | `docs/ops/INFRA.md` |
| Le code du mini-jeu | `proto_degagement/pusher_screen.gd` |
| Les cartes et la collection | `proto_degagement/collection_screen.gd` |
| **La carte en jeu** (dessin, matières des variantes, dos) | `proto_degagement/carte_view.gd` · `cartes/shaders/` |
| **Les effets des cartes** (feu, foudre, eau, glace, nature, esprit, ombre, prismatique) | `proto_degagement/carte_fx.gd` · `cartes/shaders/` |
| **Le look « Conte mystique »** (couleurs, polices, panneaux, boutons) | `proto_degagement/style.gd` · la référence : `image.png` et le canevas « Directions du look », page 5 |
| **Le ciel animé** (nébuleuses, étoiles, constellations, étoiles filantes) | `proto_degagement/ciel.gd` · textures : `design/ciel/render_ciel.py` |
| **Les objets du plateau** (pièces, billes, pierres) — rendus en relief, puis en volume dans le jeu | `design/objets/render_objets.py` (la fabrique : `docs/ops/INFRA.md` § La fabrique des images) → `proto_degagement/objets/` · `objets/volumes.gd` · `objets/corps.gdshader` · `objets/bille.gdshader` |
| **Le bandeau, la barre du bas, les effets, les boutons** | `proto_degagement/bandeau.gd` · `barre_nav.gd` · `effets.gd` · `style.gd` (`bouton`, `jeu`, `bulle`) |
| **L'évolution en plein écran, le niveau (LVL)** | `proto_degagement/evolution.gd` · `interface/evaporation.gdshader` · `collection_screen.gd` § `_monter_niveau`, `_evoluer` |
| **Les monnaies, les pierres, le plateau du jour, la sauvegarde v3** | `proto_degagement/game_state.gd` · `tests/test_objets.gd` |
| Les tests automatiques | `proto_degagement/tests/` — commandes dans `docs/ops/INFRA.md` |
| **L'essai 3D de la poussette** (⑦ — servi sur `/essai/`) | `proto_degagement/essais/essai_3d.gd` — export dans `docs/ops/INFRA.md` |
| **Le rituel d'invocation et les révélations** (l'astrolabe, les constellations ; lancées depuis l'Astrolabe, révélées par l'Atlas) | `proto_degagement/rituel.gd` · `collection_screen.gd` § `montrer_revelation`, `montrer_multi` |
| **Le banc de la poussette** (3 minutes de jeu simulées : hors jeu, empilement, objets qui se chevauchent, rechargement) | `proto_degagement/tests/sim_poussoir.gd` |
| **Le design des cartes et leurs variantes** | `docs/specs/FEATURES.md` § ⑤ |
| **Les prompts des héros** | `docs/art/HEROS.md` |
| **Les illustrations des héros** | `Cartes/Illustration/` |
| L'état sauvegardé | `proto_degagement/game_state.gd` |

### 🔗 Les maquettes *(copies de secours : le contenu est dans les docs)*

- **Le Voyage — les 7 écrans, puis toutes les captures du Carré** (la carte v6, la 3D, les sbires, les rangs, l'accueil du premier pack, le Duel et le Classé : une rangée par livraison, jusqu'au 28/09) (⑱, 26/09 : Aventure, chapitre, avant le combat, le Carré, victoire parfaite, Duel, Classé) — https://claude.ai/artifact/8KzpzjDJ7JFRJErCxHTkVG · sa source : `design/canevas/voyage/`
- **Les sons de la Nébuleuse — la page d'écoute** (29/09 : 6 moments, 30 candidats CC0 ou synthétisés ; Maxim choisit) — https://claude.ai/artifact/JET9DYuQ9eH1iHFCbLMQ6g · sa source : `design/canevas/sons/` · la fabrique : `design/sons/`
- **Arène d'essai — seize styles de combat jouables, avec tuto** (⑱, 26/09 : les 8 concepts de Maxim + 8 premiers essais) — https://claude.ai/artifact/2VwvtbPRojqsHKTvwjE3Ny · sa source : `design/canevas/arene/` · l'analyse : `docs/reviews/ANALYSE-TCG.md`
- **Démo jouable de La Poussée** — https://claude.ai/artifact/QLraLoLfD9EihuRst5P2pe
- **Direction visuelle (format + fiction)** — https://claude.ai/artifact/QHTvwDWKz177BATcmci25u
- **Six variantes (design des cartes)** — https://claude.ai/artifact/Xx9JHnUJgwkLCS6NVnLdp6
- **Directions du look** — https://claude.ai/artifact/4mN8fjvJvYXryAgTKxarai
- **Rituel des constellations** (les invocations ; la ligne D est retenue) — https://claude.ai/artifact/PqeP9uQQGBcQs2AdT2nbrF
- **Objets de l'univers** (⑭ + ⑮ : les objets, les quatre propositions de bandeau et de barre, les gestes, puis les captures du vrai jeu jusqu'aux billes) — https://claude.ai/artifact/ScGX7aLFGUqn9g49SQAUJj · sa source (la page et ses images) : `design/canevas/objets-univers/`

---

## 🧠 Mémoire

⚠️ Une mémoire ou une note est une **photo à un instant T** → **vérifier en code** avant
d'affirmer qu'un fichier, un flag ou une fonction existe encore.

---

*Dernière mise à jour : 29/09/2026, 9 h 20 — la Nébuleuse sonne (sons provisoires), le Menu des Présages (Réglages, Code cadeau) : en ligne à 9 h 09. Ensuite : **les sons choisis par Maxim**, puis **les comptes** (Nakama, son VPS).*
