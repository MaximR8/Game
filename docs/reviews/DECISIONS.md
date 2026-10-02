# 🧭 LES DÉCISIONS — le POURQUOI, pas le QUOI

> **À lire AVANT de rouvrir un sujet qu'on croit tranché.**
>
> 🔴 **Pourquoi ce fichier existe.** Le `CHANGELOG` dit ce qui a été fait, `FEATURES` dit ce qui
> reste. **Ni l'un ni l'autre ne dit pourquoi on a choisi ça plutôt qu'autre chose** — et c'est
> précisément ce qu'on redemande trois mois plus tard, quand l'argument est oublié et que la
> décision semble arbitraire.
>
> ⛔ **Une décision sans son argument se re-discute.** Une décision avec son argument se respecte,
> ou se renverse **en connaissance de cause**.

---

## Le format — une décision, cinq lignes

### `<La décision, énoncée en une phrase>` — `<date>`

**Ce qu'on a tranché** : `<…>`
**Ce qui a fait pencher** : `<le fait, le chiffre ou la phrase de Maxim — pas l'intuition>`
**Ce qu'on a écarté, et pourquoi** : `<l'alternative sérieuse, traitée sérieusement>`
**Ce que ça coûte, et qu'on assume** : `<la contrepartie — il y en a toujours une>`
🔓 **Ce qui la rouvrirait** : `<un fait mesurable, pas une impression>`

---

## Les décisions prises

### Les décors de la machine : les sept gardés, Base céleste par défaut ; les cartes à une seule évolution sont voulues — 02/10/2026

**Ce qu'on a tranché** (Maxim, 02/10) : *« on garde tous les décors, mais le céleste est celui par défaut »* — Base céleste,
Olympe, Valhalla, Égypte, Atlantide, Mille et une nuits, Aztèque (`Machine/`, relevés dans `design/machines/`). Et sur ses
nouveaux monstres : *« il y a des cartes avec une seule évolution, c'est voulu ; on retravaillera l'équilibrage des cartes et
leur puissance quand on aura tout »* — une carte peut avoir 1, 2 ou 3 stades (le jeu n'en connaît que 1 ou 3 : à ouvrir à 2).
**Ce qui a fait pencher** : l'essai (CHANGELOG 🧪 02/10) : la vraie machine tient dans chacun ; un thème de machine = un décor,
son relevé, l'habit du bloc — les thèmes des pass (DECISIONS 01/10) existent déjà.
**Ce qu'on a écarté, et pourquoi** : étirer les pièces avec la profondeur (Maxim : *« ça a déformé les pièces, c'est pas
beau »* — seule leur place s'étire) ; des animations dessinées à plat (*« fait en CSS »* — elles sont rendues comme les objets
de la fabrique, ou relues dans le décor lui-même).
**Ce que ça coûte, et qu'on assume** : chaque décor se relève à la main (le creux, la marche, les alvéoles : ~10 min) ; le jeu
devra charger un décor de 1024 × 1536 (à agrandir ×2 pour la netteté) ; l'équilibrage des cartes attend la fin de la
collection.
🔓 **Ce qui la rouvrirait** : le rendu sur le téléphone (la netteté, les images par seconde — D13).

### Dans la machine en perspective, le doigt choisit seulement gauche-droite : une glissière (la fente des vraies machines) suit le doigt et lâche les pièces sur le bloc — 02/10/2026

**Ce qu'on a tranché** (Claude, le design fonctionnel — Maxim, 02/10 : *« comment le joueur va poser ses pièces avec le plateau
incliné comme ça ? peu importe où il touche en hauteur d'écran, ça se met sur le plateau qui bouge ? ou alors un système de
fente comme les vraies machines ? »*) : **les deux à la fois**. Où que le doigt touche la machine (même bas, près du pouce),
seule sa position **gauche-droite** compte ; une petite **glissière** dorée, posée sur le haut du bloc, suit le doigt et les
pièces en tombent sur le bloc (toujours à la même profondeur). Glisser le doigt sème plusieurs pièces, comme aujourd'hui.
**Ce qui a fait pencher** : en perspective, le dessus du bloc ne fait plus qu'une mince bande à l'écran (viser la profondeur au
doigt serait imprécis) ; le bloc est haut sur l'écran (le pouce y arrive mal) ; les vraies machines font ainsi (une fente
qu'on oriente) — la référence de Maxim ; et la profondeur du lâcher ne change presque rien au jeu (le bloc emmène les pièces
contre le mur).
**Ce qu'on a écarté, et pourquoi** : viser la case au doigt (la vue d'aujourd'hui : précise de haut, imprécise en perspective) ;
une fente fixe au milieu (on perd le choix gauche-droite, le seul vrai geste de visée).
**Ce que ça coûte, et qu'on assume** : la glissière à dessiner dans chaque décor (un petit objet d'or, ou l'habit du thème) ;
le geste « glisse le doigt sur le bloc » devient « glisse le doigt » (la consigne change).
🔓 **Ce qui la rouvrirait** : le cousin et sa femme qui visent mal, ou cherchent à toucher le bloc. *(Montrée le 02/10 au soir :
le film « Lâcher les pièces » du canevas — le chariot d'or sur un rail perlé, `tests/capture_decor` mode `glissiere`.)*
🔄 **Le soir même** — Maxim : *« je la mettrais plus haut, qu'on anime les pièces qui tombent de là ; je changerais l'aspect »* ;
trois lance-pièces proposés (croissant, sphère armillaire, lanterne) → *« on part sur la B »* : **la sphère armillaire**, qui
flotte au-dessus du bloc, la pièce suivante en son cœur ; la pièce tombe en tournoyant. **En prod le 02/10 à 19 h 35**.

### On ne vend ni la chance ni la victoire : une monnaie payante pour du connu ; 150 cartes, puis des styles ; un vrai meuble de machine, à thèmes ; les Maîtrises — 01/10/2026

**Ce qu'on a tranché** (Maxim a passé à ChatGPT le jeu entier ; ses 18 points, commentés par Maxim : *« globalement
d'accord »*) :
- **La phrase** devient la règle de toute vente : *« On ne vend pas la chance. On ne vend pas la victoire. On vend la
  collection et la personnalisation. »* (doctrine, plus bas). Les rôles : le Carré = le jeu sérieux, la Nébuleuse = le
  quotidien, les événements = le terrain d'essai.
- **L'argent n'achète qu'une monnaie payante** (Maxim : *« on fait payer, à la limite, que les Éclats divins, qui servent de
  monnaie dans le jeu pour le reste »*). Elle achète **du connu, en une étape** (€ → la monnaie → l'objet ; jamais une autre
  monnaie) : le pass, les styles, les thèmes de machine, le cosmétique, des bundles par mythologie, une **boutique qui
  tourne** (une autre sélection chaque jour, rien de tiré au hasard). À côté de chaque prix, **le prix en euros** ; des
  paquets qui **tombent juste** (les principes européens de mars 2025, plus bas).
- **Le pass dure 3 mois** (Maxim : *« pour nous laisser le temps de créer les autres »*) ; jamais une carte du Classé en
  exclusivité. Le Classé garde ses saisons d'un mois.
- **Le contenu** : ~**150 cartes au lancement**, équilibrées ; ensuite 1-2 cartes de temps en temps — **pas de saisons de
  nouvelles cartes**. Le flux, ce sont **les styles** : une autre illustration de la même carte, rien ne change au jeu
  (Maxim : *« je peux faire une variante Looney Toon de Loki »*). Un style a **sa pose en grand** (on voit le dessin) et
  **son animation** (*« la carte céleste et la carte Seigneur des Enfers ne s'animent pas de la même manière »*).
- **La Nébuleuse devient un vrai meuble de machine, cosmique** (Maxim : *« actuellement le plateau, c'est un rectangle avec
  du texte, ça n'a pas le look d'une vraie machine »*) ; puis des **thèmes** purement visuels, un par pass. Sa maquette (cinq
  machines : Base céleste, Wukong céleste, Seigneur des Enfers, Nouvel An chinois, Corrompu) donne la composition : une
  arche, des colonnes, une scène au fond, un cadre d'or, l'interface dessous. **Un thème change le meuble, le fond, la
  lumière, la musique — jamais la couleur des pièces ni des objets** (Claude, la lisibilité : dans « Corrompu », les pièces
  violettes cachent la bille mauve) ; le skin de pièces est un autre cosmétique, qui garde le contraste. Le meuble est
  construit à thèmes dès le départ (un thème = des images, une lumière, une musique : pas de code) et reste léger (D13). La
  base reste universelle ; un thème peut aller à fond dans une culture ; un thème gratuit se gagne.
- **Les Maîtrises** (Maxim : *« excellent point »*) : une carte monte en maîtrise quand on la joue ; des récompenses
  cosmétiques seulement (avatar, cadre, titre, animation, style).
- **Les événements** : des mini-jeux hors du Carré (30/09) ; la carte comme **mascotte** (Maxim : *« on choisit une carte
  pour nous représenter pendant l'event »* — elle montre son style à tous) ; on les juge **au rendu** (*« ça doit donner
  envie de venir faire son mini-jeu quotidien »*) : deux prototypes, joués par le cousin et sa femme, on garde celui où ils
  reviennent. Proposés par Claude : la Chasse (une course à un doigt), le Trésor de Fafnir (la machine en événement : tout
  existe), le Raid comme une couche (les scores de tous tapent le même boss, une barre commune).
- **Les monnaies** : plus aucune nouvelle monnaie permanente (la payante mise à part) ; une par événement, convertie en
  poussière à la fin ; le cœur d'étoile est un objet, pas une monnaie ; 4 compteurs au plus par écran. Le rythme (Maxim) :
  *« pas fini en 2 jours, mais pas trop lésé »*.

✅ **Confirmé par Maxim le 01/10 au soir** (*« 1. oui 2. Comète c'est très bien 3. ok 4. non… 5. aligné 6. ok »*) — 1, 2
(**les Comètes**), 3, 5 et 6 tels quels ; **4 changé par Maxim** : *« le style de base pour tous les stades, et quand on
rajoute un style c'est pour les lvl 3 — plutôt un stade III alternatif »* ; *« au moins ça pousse les gens à monter leurs
cartes »* ; *« les cartes de base ont toutes la même animation d'entrée sur le plateau ; les cartes spéciales, elles, ont
leur animation bien spécifique (on ne fait pas d'office une carte spéciale par carte ; au pire ça fera 150 : jouable) »*.
Et sur la machine : *« on ne recolore ni les pièces ni les objets, seulement le décor ; le titre La Poussette peut dégager
(plus d'espace) ; j'aime le jeu de profondeur — nous on a une vue aérienne, là ça donne une impression de long plateau ;
des petites animations sur la machine ; la barre de la Supernova intégrée au décor, qui gère aussi l'animation de la
Supernova »*. Les cartes : *« on peut avancer tout doucement »*. Et les **skins du tapis du Carré**, un « base » dans le
même esprit que la machine céleste. Premier aperçu demandé : la machine « Base céleste » et le tapis céleste, en artifact.

Les six points, tels que proposés (l'avis de Claude, 01/10) :
1. **La monnaie payante n'achète pas de cartes** — ni pierres, ni poussière, ni étoiles, ni pièces, ni Nouvelle machine.
   Ça remplace le 30/09 (« vendre les éclats, le moteur principal ») : au Carré, le stade change les chiffres ; vendre les
   cartes, c'est vendre le Classé. La seule vitesse vendue : un bonus de ressources **plafonné** dans le pass payant
   (personne n'achète toute la collection le premier jour). Le moteur devient le pass, les styles, les thèmes.
2. **Un autre nom** qu'« Éclats divins » : à côté de nos éclats (la carte choisie), deux compteurs presque pareils. Par
   exemple les Comètes.
3. **Jamais de pièces vendues, nulle part** (avant : « zone grise, pas en Belgique ni aux Pays-Bas ») : payer, pousser,
   gagner des pierres et des étoiles qui font progresser, c'est le schéma jugé à Anvers.
4. **Un style = une illustration** pour tous les stades (le stade se lit au cadre ; sinon trois images par style) ; une
   animation **par style**, pas par carte ; la pose en grand ~0,6 s, sans bloquer la partie, vue aussi par l'adversaire ;
   le style change l'illustration, la finition (Or, Prisme…) reste le cadre ; un style ne tombe jamais d'une invocation.
5. **Les cibles du rythme** (un joueur gratuit, ~15 min par jour) : semaine 1, un deck complet et une évolution ; mois 1, sa
   carte préférée au stade III ; 3 mois, ~2/3 de la collection ; 6-9 mois, toute la collection de base ; les finitions, le
   Full art, les Maîtrises : sans fin. Réglées par un banc (six mois simulés), pas à l'œil.
6. **L'ordre** : la Nouvelle machine → la série de 7 jours → la machine cosmique (à thèmes) → les Trésors → le banc de
   l'économie → la pose en grand et un premier style (3-5 cartes) → le premier événement (2 prototypes) → les Maîtrises
   (avec le cadran du joueur) → la boutique (après un juriste). En fond : les cartes vers ~150.

**Ce qui a fait pencher** : les commentaires de Maxim (ci-dessus) ; **le tribunal de l'entreprise d'Anvers, 16/01/2025**
(LS contre Apple : 67 813 € dans les loot boxes payantes de *Top War* — un jeu de hasard sans licence, donc illégal ; **la
responsabilité d'Apple, qui héberge le jeu, posée à la Cour de justice de l'UE**) — si elle est retenue, les stores se
durciront en Belgique ; **les principes
du réseau européen des autorités de consommateurs (CPC) sur les monnaies de jeu, mars 2025** : le prix en euros, rien qui
cache le coût, pas d'échanges en chaîne, pas de paquet qui force à acheter plus que nécessaire, le droit de rétractation
expliqué, les enfants protégés ; le banc du rythme (300 joueurs gratuits simulés, ~17 invocations par semaine, les rangs
60/25/11/4 %, 5 éclats par invocation et par doublon, la carte manquante achetée dès que possible) : **aujourd'hui (40
cartes), toute la collection en ~24 semaines ; à 150 cartes aux mêmes chiffres, ~105 semaines (2 ans)** — le risque, c'est
« lésé », pas « fini en 2 jours » ; Queen's Blood, la référence de Maxim, a ~145 cartes.
**Ce qu'on a écarté, et pourquoi** : des saisons de 6 semaines avec de nouvelles cartes (des cartes toujours plus fortes,
un équilibrage sans fin ; Maxim : 3 mois) ; descendre à 4 monnaies (les pierres, la poussière, les éclats ont chacune leur
rôle) ; les mini-jeux longs ou à planifier — Mythic Survivors (5-8 min, des améliorations tirées au hasard, un gros
chantier), la Défense du village (de la planification), le Labyrinthe (des salles au hasard, des combats automatiques
qu'on regarde), la Mythic Arena (du temps réel à quatre en ligne : le plus cher de la liste) ; des thèmes qui recolorent
les objets ; les noms déposés (« Looney Tunes » est une marque, un style « cartoon » est libre ; les noms officiels d'une
fête — la Ducasse, le Doudou — à vérifier avant d'en vendre un pack).
**Ce que ça coûte, et qu'on assume** : moins de revenus des joueurs pressés (pas de cartes vendues) ; ~110 cartes à faire
(~160 à 250 illustrations selon la part de héros à trois stades — Maxim seul) ; une pose et une animation par style ; le
meuble de la machine à construire.
🔓 **Ce qui la rouvrirait** : l'avis d'un juriste ; la réponse de la Cour de justice de l'UE (Apple) ; la mesure des
cousins (reviennent-ils pour un mini-jeu ?) ; les chiffres de la boutique une fois ouverte.

### L'économie : l'argent n'achète JAMAIS du hasard ; la Nébuleuse gagne la Supernova, les Nouvelles machines, les Trésors, les événements — 30/09/2026

**Ce qu'on a tranché** :
- **Le principe** : les étoiles (les invocations, tirées au hasard) ne se vendent jamais ; on ne vend que du CERTAIN — les
  **éclats** (la carte et la variante de son choix : le moteur principal), le **Pass de la saison** (~5 €/mois, calé sur le
  Classé, récompenses affichées), le **cosmétique**. Les pièces (la machine, où elles tombent au hasard) : zone grise — pas
  vendues en Belgique ni aux Pays-Bas (le pays du store), sauf avis contraire d'un juriste. La parade si l'on voulait un jour
  vendre des invocations : **le Présage** (l'astrolabe montre la carte avant l'achat : plus de hasard au moment de payer).
- **La Supernova** (le « Furax » de Maxim) : les pièces tombées dans les fentes remplissent une jauge ; pleine, 30 s où la
  machine s'emballe (poussoir ×2, pluie de pièces offertes, tout compte double) — le mot SUPERNOVA en énorme, en lettres
  d'or balayées de lumière, un flash, une gerbe d'étoiles ; un **cœur d'étoile** tombe.
- **Le cœur d'étoile** : 3 cœurs allument une **Nouvelle machine** — un second plateau du jour (6 objets affichés d'avance :
  poussière, pierres, éclats, pièces, un trésor). Maxim : *« surtout commercialement, ça a de la valeur »*.
- **Les Trésors** : toutes les 3-4 h, une pièce de collection dans la machine (par mythologie) ; une collection complète →
  une variante AU CHOIX dans sa mythologie ; un double → des pièces ou de la poussière.
- **La série de 7 jours** : le cadeau du jour monte sur 7 jours (un cœur d'étoile le 7ᵉ).
- **Les événements** (2-3 jours, un par mythologie du jeu : Ragnarök, le Doudou, le Nouvel An lunaire, Samhain, les Mille et
  une nuits) : un **objet d'événement** gagné dans la machine (et la Supernova) ; il paie une partie d'un **mini-jeu qui n'est
  PAS le jeu de cartes** — rapide (30-45 s), à un doigt, d'ADRESSE (pas de hasard : on peut en vendre des parties), paliers
  bronze / argent / or affichés : le lancer de Mjöllnir, attrape le crin, les pétards de Nian, les feux follets, le tapis volant.
- **Les coûts relevés** (Maxim : *« augmenter le coût en éclats des cartes et variantes, en XP et pierres pour évoluer — les
  pierres de manière drastique »*) — proposés : éclats ×2,5 (héros 500, légende 2 200 ; les variantes ×2 à ×10 comme avant) ;
  un niveau 250 × niveau (100) ; stade II : 3 pierres de son type (1), stade III : 10 (2).
- **Les cosmétiques** (ce qui se voit EN JOUANT — la face de la carte est déjà prise par les variantes, le dos se voit peu) :
  thèmes de machine, skins de pièces, style de la Supernova ; au Carré en multi : tapis, cadran du joueur (portrait, cadre,
  titre), effets de pose et de retournement, emotes, animation de victoire ; l'aura des cartes en combat, le décor de la
  carte en grand, le cadre dans l'Atlas ; le thème de l'astrolabe ; bannière, avatar.
- **L'ordre** : la Supernova et le cœur (la Nouvelle machine) → les Trésors → la série de 7 jours → le premier événement
  (Ragnarök) → la boutique (après un juriste). Pas de fonctions « famille » (cadeaux entre joueurs, classement) : écarté.

**Ce qui a fait pencher** : les joueurs, via Maxim, 30/09 : *« la Nébuleuse, ils la vident très vite, donc ils n'ont plus rien à
faire après, faut donner envie de revenir plus souvent »* ; la loi belge (la Commission des jeux de hasard, 2018 : un achat en
argent réel qui mène à du hasard est un jeu de hasard — voir la mémoire « boutique-belgique » et FEATURES § ⑧) ; le plateau du
jour garde son rôle (les étoiles restent rares : les nouveautés donnent des pièces, de la poussière, des pierres, des éclats).
**Ce qu'on a écarté, et pourquoi** : vendre des tickets (illégal en Belgique) ; des mini-jeux au Carré (Maxim : *« des mini-jeux
qui n'impliquent pas le jeu de cartes, un truc rien à voir, rapides et fun »*) ; les fonctions famille (Maxim : non) ; vendre
des dos de cartes comme cosmétique phare (ils se voient peu).
**Ce que ça coûte, et qu'on assume** : sans vendre le hasard, le jeu gagne moins par joueur qu'un gacha classique — il gagne
par la collection choisie (éclats), le pass et le cosmétique ; le relèvement des coûts ralentit les joueurs actuels.
🔓 **Ce qui la rouvrirait** : l'avis d'un juriste sur la vente des pièces ; la mesure du 12/10 (la journée).

### Tout le plateau du jour est posé, chaque objet sur un amas ; des fentes sur les côtés ; le bloc du haut presque vide — 29/09/2026

**Ce qu'on a tranché** : les 12 objets du jour sont **tous sur le plateau** (plus trois qui reviennent) : le ticket au fond,
la moitié des pierres n'importe où (le jour décide lesquelles : 1 ou 2 sur 3), les autres pierres rangées derrière, les
poussières (l'XP) devant ; chaque objet est posé sur un **amas** de 5 pièces qui tombe avec lui (le gros paquet sonne). Pour
que le plateau garde son prix : **deux fentes** le long des côtés (🔄 *22 h 40 : 0,7 de large, de 10,8 à 13,3 — un coin plein
devant ; à 0,4 elles n'avalaient RIEN, le « 27 % » mesuré était un bug du bord, corrigé : CHANGELOG*) où ~28 % des pièces qui
quittent le plateau se perdent ; le **bloc du haut** ne garde que 5 pièces (machine neuve ; chaque nouveau jour, les
amas se font d'abord avec ses pièces en trop) ; les défis donnent 35 pièces (60), la semaine 120 (200).
**Ce qui a fait pencher** : Maxim, 29/09 : *« la satisfaction c'est quand un gros paquet tombe d'un coup […] mettre toutes les
récompenses dispo directement sur le plateau »* ; *« il faut rendre le plateau moins facile »* ; *« l'idée c'est que les gens
achètent des pièces pour jouer plus à la machine »* ; *« sur la poussette en haut, ne laisse que 4-5 pièces »*. Le banc
(`sim_poussoir`, plusieurs graines, `deux_jours`) : tout posé, le plateau se vidait pour 52 à 72 pièces nettes (123 à 175
le 28/09) ; avec les fentes et le bloc vide, le lendemain sur la même machine : 68 à 138 (~100), pour ~155 pièces données
par jour ; 3,2 à 3,8 pièces par chute, 61 à 71 % des pièces en paquets de 4 et plus.
**Ce qu'on a écarté, et pourquoi** : un plateau qui frotte plus (0,3 ; 0,5) — il faut un tas plus haut, la machine touche son
plafond de pièces et se **bloque**, et les pièces avancent au compte-gouttes (des paquets plus petits : 1,7 par chute) ; des
fentes de 0,7 (45 % des pièces perdues sous les yeux du joueur : trop dur à vivre) ; un tas plus lourd (plus de corps à
calculer : la Nébuleuse tient déjà à peine ses images sur le web, D13) ; créer les pièces des amas (60 pièces offertes chaque
jour : le plateau à moitié prix).
**Ce que ça coûte, et qu'on assume** : des pièces perdues sur les côtés (le genre le fait, les joueurs le connaissent) ; les
lignes « banal, normal, rare » du plateau ont disparu (les objets disent où ils sont) ; le tas sauvegardé repart à zéro une
fois (GEO_VERSION 12).
🔓 **Ce qui la rouvrirait** : la mesure du 12/10 (la journée trop courte ou trop longue) ; la boutique : Maxim pense à des
packs avec **une « Nouvelle machine »** (un plateau de plus, d'autres récompenses) — à concevoir avec les achats.

### Le son : des sources CC0 choisies à l'oreille par Maxim, déclenchées par les moments du jeu (jamais par les chocs) — 29/09/2026

**Ce qu'on a tranché** : Claude rassemble des candidats (packs **CC0** : Kenney, OpenGameArt ; et des carillons qu'il
synthétise), les prépare à la mesure (l'attaque au début, les volumes égalisés, la musique bouclée sans raccord), les met
sur une **page d'écoute** ; **Maxim choisit** (le goût). Dans le jeu, les sons partent des **moments que le jeu connaît
déjà** (la pièce lâchée à son premier contact, le passage du bord, l'objet, le plateau vidé, le poussoir qui avance) ; le
gain monte **en cascade** (do ré mi sol la do) quand les pièces se suivent. Réglages : deux bus (Musique, Effets), par appareil.
**Ce qui a fait pencher** : Maxim, 29/09 : *« tu es capable de lire les fichiers audio pour caler le son au bon moment ? »*
— Claude mesure un son, ne l'entend pas ; la même méthode que l'image (Claude décide de la méthode, Maxim du goût).
La Nébuleuse tient à peine ses images (D13) : faire sonner chaque choc demanderait d'écouter les contacts de 260 pièces.
**Ce qu'on a écarté, et pourquoi** : écouter les chocs entre pièces (trop cher en physique) ; des sons sous licence CC-BY
ou achetés (un crédit obligatoire, un coût) ; la génération par IA (les droits commerciaux dépendent de l'abonnement).
**Ce que ça coûte, et qu'on assume** : la pièce qui cogne une autre pièce ne fait aucun bruit ; le froissement est un
grain tiré au hasard, pas le bruit réel du tas.
🔓 **Ce qui la rouvrirait** : l'app native (plus de marge de physique) ; un sound designer.

### Le code cadeau sans serveur : un fichier d'empreintes à côté du jeu — 29/09/2026

**Ce qu'on a tranché** : le jeu lit `web/codes/codes.json` sur le NAS (comme le reste du jeu, par le portier chez les
cousins) ; il n'y trouve que l'**empreinte** de chaque code (SHA-256 d'un sel et du code normalisé), sa récompense, sa date
de fin. Maxim ajoute un code d'une commande (`codes_cadeaux/codes.py`), sans réexport. Un code vaut **une fois par partie**.
**Ce qui a fait pencher** : Maxim, 29/09 : *« comme ça je peux mettre des codes promos »* — tout de suite, alors que les
comptes (le serveur) viendront après.
**Ce qu'on a écarté, et pourquoi** : les codes en clair dans le jeu (lisibles dans le `.pck`) ; attendre le serveur.
**Ce que ça coûte, et qu'on assume** : sans compte, « une fois par partie » : effacer sa partie permet de reprendre un code
— on y perd tout le reste. Pas de quota global (« les 100 premiers »).
🔓 **Ce qui la rouvrirait** : les comptes — la vérification passe au serveur (une fois par compte, des quotas).

### On invoque dans deux ciels : le Grand Ciel, et le Ciel du Peintre (Full art ×2, garanti au 100ᵉ, refermé au premier) — 28/09/2026

**Ce qu'on a tranché** (⑩) : l'onglet **Astrolabe** s'ouvre ; on y choisit son ciel. **Le Grand Ciel**, permanent, aux
chances de toujours (le premier pack s'y ouvre). **Le Ciel du Peintre** : le Full art y tombe **deux fois plus** (0,2 % au
lieu de 0,1 %, pris sur la Base), **toujours sur un Héros, un Mythe ou une Légende** (jamais un sbire), sur une carte qui ne
l'a pas ; **la centième invocation sans Full art en donne un d'office** ; au premier Full art, **le ciel se referme pour de
bon** ; **sa première ×10 est offerte** (elle compte dans les 100 ; un ×1 se paie — Maxim : *« c'est une invocation ×10 que je
voulais donner en cadeau, pas 1 »*). Le compteur se voit en gros (« FULL ART GARANTI
DANS 63 »), en or à 10 de la fin (« PLUS QUE 7 »). **« Mes decks » passe en haut de l'Atlas**, à la place de l'invocation.
**Ce qui a fait pencher** : Maxim, 28/09 : *« un portail normal avec les taux de drops qu'on connaît et un portail Full art
×2 […] au premier drop d'une Full art le portail disparaît […] le 100ème ticket garantit une Full art »* ; puis *« si
l'utilisateur a dépensé 100 étoiles, la 100ème c'est d'office un Full art »* ; *« minimum un héros »* ; *« offre la première
invocation Full art aux gens, c'est un cadeau »*. Le nom (« Grand Ciel », « Ciel du Peintre » — le Peintre est une vraie
constellation, et un Full art est la carte peinte en entier) : proposé par Claude, *« je te fais confiance »*. Au banc
(`test_portails`, 12 000 joueurs) : 18 % ont leur Full art avant la garantie, en 91 invocations en moyenne, jamais plus
de 100 ; à ~17 étoiles par semaine, **la garantie, c'est ~6 semaines de jeu**.
**Ce qu'on a écarté, et pourquoi** : une chance qui monte de la 91ᵉ à la 99ᵉ (le « 90 » de la première phrase) — Maxim a
tranché pour la centième d'office, qui se lit sans calcul. Un Full art du Peintre sur un sbire — après des semaines, un
Full art Farfadet qui referme le ciel serait une punition. Garder l'invocation dans l'Atlas avec un sélecteur — la
dernière page serait restée scellée.
**Ce que ça coûte, et qu'on assume** : un Full art est désormais **atteignable à coup sûr**, une fois par compte (sa rareté
reste entière au Grand Ciel). Le Ciel du Peintre ne revient pas : il n'y a pas encore de calendrier d'événements (④).
🔓 **Ce qui la rouvrirait** : le cousin et sa femme qui ne touchent jamais au Peintre (le 12/10) — la garantie trop
lointaine ; ou qui l'ont refermé en une semaine — elle serait trop proche.

### L'économie de la journée : un plateau connu d'avance, des pièces qui se gagnent, une ×10 tous les ~4 jours — 28/09/2026

**Ce qu'on a tranché** (lot A de ⑧) : la Nébuleuse porte chaque jour **12 objets connus d'avance** (1 étoile, 3 pierres
écrites par le calendrier, 8 poussières), puis « revient demain ». **Plus de pièces à la minute ni de plafond** : elles
viennent du cadeau du jour (25), des **défis des Présages** (3 par jour, 60 chacun ; les 3 reçus : 1 pierre de lune ; la
semaine, 5 jours : 3 étoiles et 200 pièces), et plus tard de packs à acheter. Un joueur de chaque jour : **17 étoiles par
semaine, une ×10 tous les ~4 jours**. À suivre (lot B) : les **éclats** (5 par invocation ; ils achètent toute carte,
toute variante sauf le Full art), **un Full art ou un prismatique tiré n'est jamais un doublon**, un vrai doublon donne des
éclats et plus de poussière, **évoluer demande niveau 5 / 10 et 1 / 2 pierres**, un niveau coûte 100 × le niveau.
**Ce qui a fait pencher** : le banc du 28/09 — la Nébuleuse rapportait **~48 étoiles par heure**, sans fond (Maxim, 23/09 :
*« ça doit être dur d'avoir une invocation ×10 »*) ; la poussière ne servait plus à rien après 16 800 ; vider le plateau
coûte 123 (vite) à 175 (calme) pièces nettes, d'où 60 par défi. Maxim, 28/09 : *« arrêter de donner des pièces la minute
et en faire gagner dans les défis journaliers et hebdo, comme ça on met des pièces dans les packs pour que les gens
jouent »* ; *« 1. Oui ok »* (le rythme) ; *« pokemon te donne des cristaux quand tu ouvres des packs et tu peux tout
acheter comme carte sauf les Full art »* ; *« imagine j'ai un doublon d'une carte en Full art, ça m'énerverait que ça me
donne de la poussière »* ; *« ça doit être difficile d'évoluer les cartes, faut une belle durée de vie »* ; les deux lots :
*« Ok »*.
**Ce qu'on a écarté, et pourquoi** : garder la recharge et ne limiter que le plateau (Maxim ne veut pas de recharge) ; un
plateau tiré au hasard (moins lisible) ; des défis au hasard pour chaque joueur (contraire au calendrier écrit d'avance) ;
fabriquer les cartes avec la poussière (proposé par Claude) → le modèle de Pokémon, des éclats gagnés en invoquant.
**Ce que ça coûte, et qu'on assume** : un joueur ne peut plus « farmer » une soirée ; un nouveau joueur n'a que ~55 pièces
avant ses premiers défis. 🔴 **Le plateau est ce qui permet de vendre des pièces sans vendre de puissance** : des pièces en
plus font finir son plateau plus vite, pas gagner plus.
🔓 **Ce qui la rouvrirait** : des cousins qui ne vident jamais leur plateau faute de pièces, ou qui trouvent la journée trop
courte (le 12/10).

### Le Classé se mérite : la force de l'adversaire vient de la marche, pas du joueur — 28/09/2026

**Ce qu'on a tranché** : six rangs, **Météore → Comète → Aurore → Éclipse → Galaxie → Zénith** (trois marches de
100 points chacun, sauf le Zénith) ; +25 / −20 ; chaque rang atteint est un plancher ; la saison est le mois, −1 rang au
changement, la récompense va au meilleur rang (si l'on a joué). L'adversaire de chaque marche a une force fixe
(`Classe.cote_adversaire`) : qui cale reste là. Le Duel, lui, suit la cote du joueur (Elo, ±100). Les deux s'ouvrent
après le boss de la 1ʳᵉ terre. **La poussière du jour (5 victoires × 30) compte en Duel OU en Classé.** Quitter, ou
fermer l'app en plein combat, compte comme une défaite.
**Ce qui a fait pencher** : Maxim, 28/09 : *« ça doit se mériter, les autres qui veulent pas joueront pas classé »* ;
*« Poussière et étoile et nébuleuse sont déjà utilisés autre part, faut mettre autre chose »*, puis *« OK »* aux six
noms (Constellation et Légende disaient déjà autre chose aussi) ; *« ok »* à la poussière partagée (sinon, qui aime le
Classé ferait des duels par corvée). Le banc (`tests/banc_fantomes -- echelle`) : le meilleur joueur simulé, avec le
meilleur deck, touche le Zénith 8 saisons sur 8 (~86 parties) ; un joueur moyen cale à Éclipse ou Galaxie, même avec
le meilleur deck ; un débutant qui joue au hasard, à Aurore.
**Ce qu'on a écarté, et pourquoi** : le Classé réglé sur la cote comme le Duel (tout le monde gagne une partie sur deux
partout : les rangs ne veulent plus rien dire) ; les niveaux de l'Aventure comme adversaires (decks hors des règles
d'un joueur, connus par cœur) ; les deux modes ouverts dès le départ (Maxim joue sans lire : la 1ʳᵉ terre apprend
le jeu, le cadenas donne un but).
**Ce que ça coûte, et qu'on assume** : un joueur moyen ne verra jamais le Zénith ; le Zénith tombe en ~90 parties pour
le meilleur (la fiche disait ~150) ; sans backend, l'horloge du téléphone décide de la saison (une horloge reculée
ne rejoue rien, une horloge avancée finit la saison plus tôt).
🔓 **Ce qui la rouvrirait** : les cousins qui calent tous au même rang dès la première semaine, ou qui touchent le
Zénith sans avoir le meilleur deck.

### Les adversaires du Duel et du Classé sont l'ordinateur, présenté comme un personnage du jeu — 28/09/2026

**Ce qu'on a tranché** : sans backend, on joue contre l'ordinateur (`carre/fantomes.gd`), avec le nom d'un personnage
(« Cerbère, gardien des Enfers », les noms de l'Aventure), jamais un faux pseudo de joueur. Son deck est un deck de
joueur (5 cartes, poids 14) ; sa force (deck et ordinateur) vient d'un seul chiffre, sa cote ; plus il est fort, plus
sa carte de tête est rare (jusqu'au full art).
**Ce qui a fait pencher** : Maxim, 28/09 : *« Oui ok pour l'instant »*. Un adulte qui paie et découvre que ses
« rivaux » étaient des robots se sent trompé ; quand il y aura des comptes (⑯), on dira « joueur » sans avoir menti.
**Ce qu'on a écarté, et pourquoi** : de faux pseudos (le mensonge se découvre) ; un ordinateur qui change de niveau d'un
coup (au banc, le passage au Maître était un mur : 70 % → 25 % de victoires d'une cote à l'autre) — il est tiré au
sort, dans une part qui glisse.
**Ce que ça coûte, et qu'on assume** : moins l'illusion d'un jeu en ligne.
🔓 **Ce qui la rouvrirait** : des comptes (⑯), et des decks de vrais joueurs à affronter.

### Le premier pack est offert et guidé ; il garantit 5 cartes dont 3 héros ; plus de cartes prêtées — 28/09/2026

**Ce qu'on a tranché** : au tout premier lancement, un ×10 offert, montré du doigt pas à pas (l'Atlas, le pack, le
Voyage, le premier combat) ; au hasard, mais au moins 5 cartes différentes dont 3 héros. Il remplace le cadeau de 10
étoiles. Les cartes prêtées disparaissent ; le premier combat guidé garde son deck scénarisé.
**Ce qui a fait pencher** : la fiche du 27/09 (*« Oui ok »*), *« Go »* le 28/09 ; les sbires tombent 6 fois sur 10 —
sans garantie, un premier ×10 pourrait n'avoir qu'un héros ; Maxim joue sans lire.
**Ce qu'on a écarté, et pourquoi** : un pack écrit à la main (le même pour tous : plus de surprise) ; le premier combat
avec les cartes du pack (le guide ne pourrait plus dire quelle carte poser où).
**Ce que ça coûte, et qu'on assume** : un premier pack plus généreux qu'un ×10 ordinaire (un sur trois a une Légende) ;
l'écran des probabilités doit le dire (il le dit).
🔓 **Ce qui la rouvrirait** : des cousins qui s'arrêtent avant leur premier combat.

### Les héros ont un rang : plus rare, plus fort, plus lourd — 27/09/2026

**Ce qu'on a tranché** : trois rangs de héros — Héros, Mythe, Légende — et les sbires en dessous. Au tirage, le rang
d'abord (Sbire 60 %, Héros 25 %, Mythe 11 %, Légende 4 %). Une Légende a +1 à ses trois chiffres les plus faibles et pèse
1 de plus dans le deck ; un Mythe a +1 à son plus faible. **Renverse « aucune rareté de puissance » (22/09)**, dans la
ligne de ⑱ (« la rareté dit la fréquence de tirage, le coût dit la force »).
**Ce qui a fait pencher** : Maxim, *« rendre plus difficile à avoir les plus forts »* ; mesuré, les héros étaient presque
égaux (47 à 55 %) ; entre trois voies, il a choisi « plus fort mais plus lourd ».
**Ce qu'on a écarté, et pourquoi** : classer par la mesure (l'écart réel était trop faible pour que le rang veuille dire
quelque chose) ; plus fort sans contrepartie (qui tire ou paie le plus gagnerait plus souvent : l'argent achèterait la
puissance).
**Ce que ça coûte, et qu'on assume** : au banc, une Légende ne fait pas gagner plus qu'un Héros une fois son poids payé
(51 % contre 52 %) — elle est plus forte sur le plateau, pas plus rentable ; le classement des 31 héros par stature est
un choix de goût, proposé par Claude — « je te fais confiance là-dessus, on verra les retours des utilisateurs » (Maxim, 28/09).
🔓 **Ce qui la rouvrirait** : les retours des joueurs (Maxim, 28/09 : c'est sur eux qu'on choisira) ; des Légendes jugées décevantes (alors : +1 au bonus, remesuré au banc),
ou des decks de Légendes qui dominent.

### Les sbires tombent six fois sur dix ; le Chinchin et l'Homme de feuilles sont les meilleurs — 27/09/2026

**Ce qu'on a tranché** : les sbires illustrés entrent dans les invocations (60 % des tirages), à un stade, poids 1, sans
niveau. Le Chinchin et l'Homme de feuilles ont 17 de somme au lieu de 14.
**Ce qui a fait pencher** : Maxim, *« les sbires ont plus de chance de tomber »* ; *« le Chinchin et l'Homme de feuilles
sont inspirés de mon papa et moi… les 2 meilleurs sbires, sans trop abuser, pas meilleurs qu'une carte monstre »*.
**Ce qu'on a écarté, et pourquoi** : un 7 à l'Homme de feuilles (49,7 % au banc : au-dessus des héros les plus faibles).
**Ce que ça coûte, et qu'on assume** : un premier ×10 donne surtout des sbires — d'où le premier pack qui garantit 3 héros.
🔓 **Ce qui la rouvrirait** : un sbire qui passe devant un héros au banc.

### La carte de l'Atlas se tourne au doigt, en 3D ; son dos dit la légende et le pouvoir — 27/09/2026

**Ce qu'on a tranché** : dans la vue en grand, glisser le doigt fait tourner la carte en perspective ; son dos montre sa
légende (2-3 phrases de folklore) et son pouvoir (la phrase du combat). Un toucher ouvre toujours le plein écran.
**Ce qui a fait pencher** : Maxim, *« il faut que leur pouvoir soit lisible quelque part »*, puis, contre la fiche
(toucher pour retourner) : *« non, pas toucher la carte : on peut la faire bouger avec son doigt, donc une carte en 3D »*.
**Ce qu'on a écarté, et pourquoi** : toucher pour retourner (refusé par Maxim) ; une fiche texte sous la carte (elle
prendrait la place des boutons, et ne donne rien à manipuler). Une vraie scène 3D : un shader qui pose deux faces 2D en
perspective suffit, reste dans l'interface 2D, et réutilise la carte telle quelle.
**Ce que ça coûte, et qu'on assume** : deux cartes dessinées hors écran pendant qu'on tourne (seule la face visible se
redessine sinon) ; 31 légendes à tenir, et à traduire un jour (⑪).
🔓 **Ce qui la rouvrirait** : la vue en grand qui saccade sur le téléphone, ou un joueur qui ne trouve pas le dos.

### Le full art passe devant le prismatique — 27/09/2026

**Ce qu'on a tranché** : le prismatique perd son bord arc-en-ciel éclatant (bord fin, chrome à peine irisé) et son nom
irisé ; le full art prend un nom en arc-en-ciel franc qui défile. Le prismatique garde le holo sur l'illustration.
**Ce qui a fait pencher** : une remarque rapportée par Maxim, *« la prismatique tape plus à l'œil que la full art »* —
alors que le full art est dix fois plus rare (0,1 % contre 1 %). Puis *« oui top, juste le nom du héros doit bien être en
couleur arc-en-ciel qui bouge »*.
**Ce qu'on a écarté, et pourquoi** : renforcer le bord arc-en-ciel du full art — il couvre déjà toute la carte de son
image ; un second bord criard l'aurait alourdi.
**Ce que ça coûte, et qu'on assume** : un prismatique moins spectaculaire au premier regard ; il se révèle en inclinant
la carte.
🔓 **Ce qui la rouvrirait** : un prismatique qu'on ne distingue plus d'une carte de base.
🔄 **Rouverte le 28/09, exactement pour ça** (Maxim : *« on dirait la carte de base avec un contour arc-en-ciel »*) : le cadre entier du prismatique devient du chrome irisé, son nom a un reflet irisé pâle ; le full art garde l'arc-en-ciel franc et l'image sur toute la carte. ✅ *« Parfait les prisma »* (Maxim, 28/09).

### La carte du Carré : les chiffres sur le cadre, le full art casse la fenêtre — 27/09/2026

**Ce qu'on a tranché** : une seule carte partout (Atlas, main, plateau) ; l'illustration dans une fenêtre entourée du
cadre ; les quatre chiffres sur le cadre, au milieu du côté qu'ils défendent ; le full art couvre toute la carte. Plus de
PV/ATT ni d'ultime (La Poussée).
**Ce qui a fait pencher** : Maxim, *« là on tue l'utilité des full art »* — en combat, la carte normale montrait déjà
presque toute l'image : un full art (0,1 %) ne se voyait plus là où on le montre. Puis *« tu connais le jeu… trouve un
design »*, et *« je valide »* sur les captures.
**Ce qu'on a écarté, et pourquoi** : les chiffres en losange dans un coin (Triple Triad) — plus élégant, mais sur le
téléphone il faut lire un petit losange puis le rapporter au bon côté ; sur le cadre, deux voisines montrent leurs
chiffres face à face, le duel se lit sans chercher. Un cartouche en bas (Pokémon) : les chiffres n'y disent plus leur côté.
**Ce que ça coûte, et qu'on assume** : l'image d'une carte normale rapetisse (la fenêtre fait ~49 % de la carte) ; les
illustrations doivent laisser de l'air autour du personnage (les chiffres mordent sur les bords de la fenêtre).
🔓 **Ce qui la rouvrirait** : des chiffres illisibles sur le téléphone dans la main, ou Maxim qui ne reconnaît pas un
full art en combat.

### Les sbires ont les six variantes, full art compris — 27/09/2026

**Ce qu'on a tranché** : un sbire (carte commune, poids 1) peut tomber en or, ombre, élémentaire, prismatique, full art.
**Ce qui a fait pencher** : Maxim, *« un collectionneur voudra TOUT avoir en FA, y compris les sbires »*.
**Ce qu'on a écarté, et pourquoi** : des sbires en base seulement — la collection de variantes s'arrêterait aux héros,
alors que les sbires sont les cartes qu'on tire le plus.
**Ce que ça coûte, et qu'on assume** : rien en images (les variantes sont du code, verrou b) ; les taux affichés comptent
les sbires.
🔓 **Ce qui la rouvrirait** : des invocations où les variantes rares tombent surtout sur des sbires, et déçoivent.

### Le Voyage : une Aventure de 100 niveaux, un Duel et un Classé contre des fantômes — 26/09/2026

**Ce qu'on a tranché** :
- **L'Aventure** : 10 chapitres de 10 niveaux ; un chapitre = une terre de légendes, le niveau 10 = son
  boss. La difficulté monte par 4 leviers : l'intelligence de l'ordinateur (Apprenti → Maître+), son deck
  (poids 8 → 16), le plateau et les règles de partie. Les niveaux 1-10 servent de tuto. Seuls les 10
  boss sont écrits à la main, les 90 autres niveaux sont générés.
- **3 étoiles par niveau** (gagner · gagner avec 6 cartes ou plus · un défi propre au niveau) et des
  coffres de chapitre à 10, 20 et 30 ★.
- **La victoire parfaite** (toutes les cartes du plateau à sa couleur) a son animation : une
  constellation d'or relie les cartes.
- **Le Duel** : un adversaire à son MMR ±100. **Le Classé** : des points (+25 / −20), les rangs
  Poussière → Étoile → Constellation → Nébuleuse → Galaxie → Légende, et plus on monte, plus
  l'adversaire est fort (deck et intelligence). Les deux se jouent **contre des fantômes** (l'ordinateur
  réglé sur ton niveau), puis contre les decks d'autres joueurs quand il y aura des comptes (⑯).
- **Une saison par mois** : à la nouvelle saison, on redescend d'un rang ; chaque rang atteint est un
  plancher pour la saison ; les récompenses vont au meilleur rang atteint.

**Ce qui a fait pencher** : les propositions de Maxim (*« 100 niveaux de plus en plus durs… un mode combat
normal avec une fourchette de ±100 MMR, et un mode classé »*) ; *« oui nickel pour les duels et classé »* ;
*« ok »* pour les saisons, après la comparaison avec Hearthstone (retour en Bronze avec un bonus d'étoiles)
et Marvel Snap (−30 rangs par mois).
**Ce qu'on a écarté** :
- **Gagner une carte en battant un boss** : *« non, le seul moyen d'avoir une carte c'est les invocations »*
  (Maxim).
- **1 étoile d'invocation par niveau, ou 10 au boss** : 100 étoiles, soit 10 invocations ×10 gratuites,
  et plus aucune envie d'acheter.

**Ce que ça coûte, et qu'on assume** :
- **Les récompenses restent serrées** : 3 étoiles d'invocation au boss, 1 à 20 ★, 2 à 30 ★. Soit environ
  60 sur toute l'aventure (6 invocations ×10).
- **Rejouer un niveau ne rapporte que les ★ qui manquent.**
- **La poussière régulière vient du Duel, plafonnée à 5 victoires par jour.**

Et sans vrais joueurs, le Classé est une échelle contre l'ordinateur.
🔓 **Ce qui la rouvrirait** : des joueurs qui finissent l'aventure en une semaine, ou qui n'achètent plus.

### Tout ce qui vit dans le jeu suit un calendrier écrit d'avance — 26/09/2026

**Ce qu'on a tranché** : les saisons (un mois du calendrier), leurs thèmes, leurs récompenses et les
événements (le Grand Carré 4×4…) tournent seuls, sur un calendrier écrit une fois pour un an et rejoué
en boucle. Le jeu les calcule ; plus tard, le serveur (⑯) calculera les classements chaque nuit.
**Ce qui a fait pencher** : *« surtout faut tout automatiser, je dois pas taffer sur le jeu tous les jours
une fois sorti »* (Maxim).
**Ce qu'on a écarté** : des saisons et des événements lancés à la main.
**Ce que ça coûte, et qu'on assume** : moins de surprises ; du contenu à préparer d'avance, par lots.
🔓 **Ce qui la rouvrirait** : rien. C'est une contrainte de Maxim, pas un pari.

### Le combat du jeu est LE CARRÉ DES ASTRES — 26/09/2026

**Ce qu'on a tranché** : le combat est un jeu de grille à la Triple Triad. On pose ses cartes à tour
de rôle ; un chiffre plus grand du côté qui touche retourne la carte adverse, et les retournements
s'enchaînent. Le plus de cartes à sa couleur gagne. On l'enrichit en couches : la v1 (4×4, un deck
de 10, un pouvoir par héros, les terres), puis le plateau vivant (cases spéciales, règles), puis le
méta (Voyage, énigmes, tournois, PvP tour par tour, Bastion). L'analyse : `CARRE-DES-ASTRES.md`.
**Ce qui a fait pencher** : Maxim, après avoir joué les 27 démos : *« Le Carré des astres, j'ai fait
pas mal de parties, j'ai vraiment accroché, rapide, fun et stratégique… il me rappelle Queen's Blood
[FF7 Rebirth] que j'ai adoré… là on tient la base »* ; *« clairement »* (26/09, nuit).
**Ce qu'on a écarté** : La Poussée (démo incomprise : *« j'ai rien compris »*) ; un jeu de cartes
classique à main et pioche (le hasard de la pioche) ; les 8 concepts « TCG » et les 11 concepts
« stratégie avant le combat » (*« je veux un jeu rapide, pas quelque chose où il faut tout planifier
pendant des heures »*). Tous restent jouables dans l'Arène d'essai.
**Ce que ça coûte, et qu'on assume** : les PV, l'ATT, les rôles et les ultimes des cartes ne servent
plus ; une carte = 4 chiffres + un pouvoir, et **le dessin de la carte (⑤) est à revoir**. Triple Triad
est connu, et sur 3×3 il est « résolu » : le 4×4, les pouvoirs et les cases spéciales doivent le rendre
nôtre.
🔓 **Ce qui la rouvrirait** : Maxim qui ne relance plus le Carré après une semaine de jeu sur son téléphone.

### Les types ne servent qu'aux terres, pour l'instant — 26/09/2026

**Ce qu'on a tranché** : pas d'avantage de type au combat (pas de +1 contre un type qu'on bat).
Un type ne compte que sur une case de terre de son élément (+1 à tous ses chiffres).
**Ce qui a fait pencher** : *« les types pour les terres pour l'instant »* (Maxim).
**Ce qu'on a écarté** : la roue « qui bat qui » au combat. Elle alourdit la lecture d'une carte à 4 chiffres.
**Ce que ça coûte, et qu'on assume** : la roue des types (⑫ bis) n'a plus d'usage immédiat.
🔓 **Ce qui la rouvrirait** : des parties où les types ne pèsent sur rien.

### L'XP (la poussière) sert seulement à atteindre le niveau requis pour évoluer — 26/09/2026

**Ce qu'on a tranché** : le niveau n'ajoute rien aux chiffres de la carte. Il débloque l'évolution
(niveau 3 × stade, comme aujourd'hui). C'est **le stade** qui renforce les chiffres (+3 au II, +3 au III)
et le pouvoir.
**Ce qui a fait pencher** : *« je suis mitigé pour ça, pour l'instant l'XP permet juste d'atteindre le
niveau requis pour évoluer »* (Maxim, à propos des points à placer sur les côtés).
**Ce qu'on a écarté** : un point à placer sur le côté de son choix tous les 3 niveaux.
**Ce que ça coûte, et qu'on assume** : deux joueurs avec la même carte au même stade ont la même carte.
🔓 **Ce qui la rouvrirait** : la poussière qui s'accumule sans usage, une fois les évolutions faites.

### Les boîtes payantes (pierres, poussière, étoiles d'invocation) sont acceptées — 26/09/2026

**Ce qu'on a tranché** : la boutique vend des boîtes qui font monter et tirer plus vite. Un F2P
atteint le même sommet, en plus de temps. Le tirage au hasard payant est accepté, comme sur le store
belge de Clash of Critters, avec les taux affichés.
**Ce qui a fait pencher** : les captures de la boutique de Clash of Critters envoyées par Maxim, et le
constat qu'en Belgique la loi de 2018 n'est quasiment pas appliquée (82 des 100 jeux les plus rentables
sur iPhone en vendaient encore en 2023).
**Ce qu'on a écarté** : ne vendre que de la prestance. On gagne moins par payeur.
**Ce que ça coûte, et qu'on assume** : un risque légal belge faible mais réel, **à revérifier avant la
sortie** ; et en PvP, il faudra borner l'écart de puissance (niveaux plafonnés en classé).
🔓 **Ce qui la rouvrirait** : un changement de la loi, ou son application.

### Les pièces et les objets de la poussette sont RENDUS en 3D — 25/09/2026

**Ce qu'on a tranché** : les pièces et les objets sont de vrais disques 3D, dessinés en un seul
appel (`machine_rendu.gd`) avec le modèle métal des rendus en relief calculé en direct
(`objets/corps.gdshader`), dans la même perspective oblique que le dessin d'avant. Le décor
(cadre, fronton, plateau, bloc) reste en 2D.
**Ce qui a fait pencher** : *« les pièces, on dirait des bêtes JPEG »* et *« ça lag »* (Maxim) —
mesuré : le dessin 2D des pièces coûtait ~6 ms par image sur le PC (900 dessins depuis GDScript),
le rendu 3D ~0,2 ms ; et une image de 128 px agrandie ne sera jamais nette.
**Ce qu'on a écarté** : garder le dessin 2D en l'allégeant (reste flou, reste cher) ; une vraie
caméra en perspective (on perdait le cadrage et le décor validés).
**Ce que ça coûte, et qu'on assume** : un shader à maintenir ; le rendu « Compatibility » n'a ni
ombres portées ni lumières — les ombres sont des disques doux, la lumière est dans le shader.
🔓 **Ce qui la rouvrirait** : un téléphone qui peine sur le rendu 3D (le compteur des outils le dit).

### Le rituel : l'astrolabe entouré de constellations, la carte de dos qui se retourne — 24/09/2026

**Ce qu'on a tranché** : l'invocation suit la **ligne D** du canevas « Rituel des constellations » —
l'astrolabe (l'anneau de huit, le cadran, l'étoile à huit branches au verrou), **entouré de
constellations qui se rejoignent le long d'une ellipse ; leur nombre dit la rareté** ; la carte
arrive **de dos et se retourne**. En ×10, une constellation par carte, de la couleur de sa rareté.
**Ce qui a fait pencher** : *« J'aime bien la B et la C »* ; *« plus il y a de constellations mieux
est le drop »* (Maxim). Le signal de rareté devient **un nombre qu'on compte**, pas une couleur de
halo — et l'astrolabe qui se resserre en l'emblème du dos relie le rituel à la carte.
**Ce qu'on a écarté** : A (la constellation propre à chaque héros — 22 figures à dessiner) ; B
telle quelle en Prisma et Full art (*« tous les traits qui se relient, ça fait n'importe quoi »*) ;
C telle quelle (la carte qui se remplit depuis le cadre) ; le halo, le pilier, les fissures et
l'éclair du rituel du 23/09 (*« horrible »*, *« très moche »*).
**Ce que ça coûte, et qu'on assume** : un rituel plus long pour les grandes raretés — toucher
l'écran le passe.
🔓 **Ce qui la rouvrirait** : Maxim qui s'en lasse à l'usage, ou un ×10 illisible sur le téléphone.

### La poussette passe en 3D : l'essai est adopté — 24/09/2026

**Ce qu'on a tranché** : la machine du jeu devient celle de l'essai `/essai/` — physique 3D (Jolt),
dessin en perspective oblique, pièces et objets qui s'empilent, objets toujours au-dessus du tas.
**Ce qui a fait pencher** : *« La poussette est géniale comme ça, on prend ça »* (Maxim).
**Ce qu'on a écarté** : la poussette 2D et ses étages simulés à la main (FEATURES § ⑦).
**Ce que ça coûte, et qu'on assume** : **~260 pièces** pour que la machine déborde (2D : ~90) ;
le tas sauvegardé en 2D repart à zéro une fois.
🔓 **Ce qui la rouvrirait** : un téléphone qui ne tient pas 55 images/s machine pleine.

### Toutes les cartes ont leur full art : l'illustration peinte, en entier — 23/09/2026 (soir)

**Ce qu'on a tranché** : le full art montre **l'illustration de la carte en entier**, sur toute la
carte, les textes sur verre, un arc-en-ciel sur le bord (la maquette v2). **Tous les héros**, 0,1 %.
**Ce qui a fait pencher** : *« elles peuvent toutes être full art maintenant, donc go »* (Maxim) —
les illustrations sont désormais peintes avec leur décor complet.
**Ce qu'on a écarté** : une illustration à part par full art (décision du matin, renversée).
**Ce que ça coûte, et qu'on assume** : le full art ne montre pas une autre image — sa rareté est
dans la matière et la mise en scène.
🔓 **Ce qui la rouvrirait** : Maxim qui veut, pour certains héros, un full art dédié.

### La couleur du portail annonce la plus belle carte du tirage — 23/09/2026

**Ce qu'on a tranché** : le portail d'invocation prend la couleur de la meilleure carte du tirage :
jade, or, argent, la couleur du type, irisé, arc-en-ciel.
**Ce qui a fait pencher** : la même règle que **les dos qui trahissent la rareté**, déjà validée ;
l'attente devient une promesse.
**Ce qu'on a écarté** : un portail toujours pareil — rien à attendre pendant 1,5 s.
**Ce que ça coûte, et qu'on assume** : on sait qu'un full art est dans le lot avant de le voir (pas
lequel).
🔓 **Ce qui la rouvrirait** : Maxim qui préfère la surprise totale — une ligne (`_portail_de`).

### Le mur du fond descend : le bloc garde deux rangs, sous un fronton — 23/09/2026

**Ce qu'on a tranché** : la poussette est « comme une vraie machine » (Maxim) — le bloc porte ses
pièces dans les deux sens, elles s'entassent contre le mur du fond et débordent à l'avant. **Le mur
est à 600 px**, sous un fronton fixe qui porte le nom et les lunes.
**Ce qui a fait pencher** : reculé, le bloc garde tout ce qui tient entre le mur et sa lèvre. Mur en
haut du cadre (254 px) : **près de 90 pièces**, qui s'ajoutent aux ~70 du plateau — **au-delà du
plafond mesuré de 115 corps**. À 600 px : **deux rangs, 23 pièces**.
**Ce qu'on a écarté** : garder le mur en haut et simuler les pièces du bloc à la main (sans corps
physiques) — beaucoup de code, un comportement moins juste, un coût en GDScript incertain sur le
téléphone.
**Ce que ça coûte, et qu'on assume** : le bloc visible est plus court ; un tiers du cadre est un
fronton décoratif.
🔓 **Ce qui la rouvrirait** : la physique 3D *(FEATURES ⑦)*, si elle tient beaucoup plus de pièces
sur le téléphone.

### Les taux de rareté baissent : full art 0,1 %, prismatique 1 % — 23/09/2026

**Ce qu'on a tranché** : Base 73,9 % · Or 15 % · Ombre 7 % · Élémentaire 3 % · Prismatique 1 % ·
Full art 0,1 %.
**Ce qui a fait pencher** : *« vu comment tombe facilement la prisma, la FA c'est 0,1 %, prisma
1 %, les autres raretés tu baisses de 1 %, la différence à Basic »* (Maxim).
**Ce qu'on a écarté** : les taux de la maquette (70 / 16 / 8 / 4 / 1,6 / 0,4).
**Ce que ça coûte, et qu'on assume** : une collection plus lente à briller ; le full art n'existe pas
encore (aucune illustration), sa part revient aux autres.
🔓 **Ce qui la rouvrirait** : l'économie (⑧) — si les tickets deviennent très rares, des taux aussi
bas pourraient décourager.

### Le look du jeu : « Conte mystique », universel — 23/09/2026

**Ce qu'on a tranché** : l'interface et la poussette prennent le style et la colorimétrie de la
planche des personnages (`image.png`, « Conte mystique ») — encre, jade, ivoire, touche de rose,
or ; un ciel étoilé animé derrière les écrans ; des objets rendus en relief ; la typo Castoro.
**Sans thème de pays** : ni sakura ni motifs de renard — lune, constellations, feux follets.
**Ce qui a fait pencher** : cinq séries sur le canevas « Directions du look ». L'Écrin et l'Atlas
*« font trop IA »* ; le Reliquaire et le Portulan, *« très moches »* ; la planche des personnages
comme référence (*« on peut se fier à ça »*) ; *« ne garde pas ce qui est japonais, c'est le style,
la colorimétrie »* ; *« le fond genre constellation, animé, un beau rendu »* (Maxim).
**Ce qu'on a écarté, et pourquoi** : le pastiche (médiéval, fête foraine), les polices « IA »
(Fraunces, Barlow), le dessin vectoriel plat des objets — jugés laids ou génériques par Maxim.
**Ce que ça coûte, et qu'on assume** : un ciel animé derrière tout (un peu de calcul par image),
des objets à régénérer par script si on change leur dessin, et les cartes à repasser en Castoro
(lot B).
🔓 **Ce qui la rouvrirait** : la fluidité sous 55 images/s sur le téléphone à cause du ciel, ou un
rejet du rendu en jeu par Maxim.

### On gèle le thème du jeu et on prototype le GESTE d'abord — 20/09/2026

**Ce qu'on a tranché** : aucun univers n'est retenu. Le premier chantier est le **mini-jeu tactile
seul** — sans collection, sans gacha, sans DA autour.
**Ce qui a fait pencher** : trois sessions passées à chercher un sujet « que personne n'a pris ».
Or Clash of Critters tourne à ~150 k$/jour d'achats sur le thème **le plus rebattu du mobile**
(bestioles mignonnes) — ce qui le porte, c'est son pachinko. **Le sujet ne différencie pas ; le
geste, oui.**
**Ce qu'on a écarté, et pourquoi** : choisir l'univers d'abord. Écarté parce qu'un thème posé sur
un geste mou ne sauve rien, alors qu'un bon geste accepte n'importe quel thème par-dessus.
**Ce que ça coûte, et qu'on assume** : on code sans savoir à quoi ressemblera le jeu. Le prototype
sera **laid, et c'est voulu** — aucun visuel définitif, aucune direction artistique.
🔓 **Ce qui la rouvrirait** : le geste validé au pouce. À ce moment-là le thème redevient la
question n°1, et **les douze pistes ci-dessous se reprennent telles quelles**.

### L'invocation ×10 : dix tirages simples, sans bonus — 23/09/2026

**Ce qu'on a tranché** : ×10 = 10 tickets = 10 cartes, **aux mêmes probabilités** qu'une par une.
Pas de garantie, pas de remise.
**Ce qui a fait pencher** : *« Même proba, j'ai choppé 2 Prisma en 100 tirages, c'est déjà beaucoup
je trouve »* (Maxim).
**Ce qu'on a écarté** : la garantie « au moins un Or par ×10 » — elle change les chances, qu'il
faudrait alors afficher.
**Ce que ça coûte** : rien aujourd'hui. Le ×10 ne pousse pas à économiser ses tickets ; si on veut
l'y inciter un jour, ce sera une décision d'économie, avec ses chances affichées.
🔓 **Ce qui la rouvrirait** : l'équilibrage de l'économie (tickets gagnés contre tickets dépensés).

### La collection garde TOUTES les variantes d'un héros ; le joueur choisit l'affichée — 23/09/2026

**Ce qu'on a tranché** : chaque variante tirée rejoint la carte du héros. Une variante plus rare que
l'affichée prend sa place à l'arrivée ; le joueur peut revenir à n'importe laquelle de celles qu'il
possède.
**Ce qui a fait pencher** : *« ça serait bien de choisir la rareté qu'on veut afficher quand on en a
pack plusieurs »* (Maxim).
**Ce qu'on a écarté** : ne garder que la meilleure variante (la proposition g d'origine) — une
variante tirée ne doit jamais disparaître.
**Ce que ça coûte** : une liste de variantes par carte dans la sauvegarde. Une sauvegarde d'avant
garde sa variante comme première de la liste.
🔓 **Ce qui la rouvrirait** : rien.

### Le full art est une illustration à part — 23/09/2026

> 🔄 **Renversée le soir même** : toutes les cartes ont leur full art, l'illustration peinte en
> entier (voir plus haut).

**Ce qu'on a tranché** : le full art a **sa propre illustration**, dans un **autre style, plus
spectaculaire** que l'illustration normale — et **tous les héros n'en auront pas**.
**Ce qui a fait pencher** : *« Génial les full art, mais ça sera pas toutes les cartes et ça sera
une illustration différente, style différent, plus waow que ça »* (Maxim).
**Ce qu'on a écarté** : la proposition (f) — montrer en full art l'illustration normale en
entier, pour ne payer aucune image de plus.
**Ce que ça coûte, et qu'on assume** : **une illustration de plus par full art**, et un second
style à définir, avec son propre gabarit. Et une règle de tirage à écrire : le full art ne peut
tomber que sur un héros qui en a un.
🔓 **Ce qui la rouvrirait** : rien.

### Les effets des cartes sont de vraies particules — 22/09/2026

**Ce qu'on a tranché** : les effets animés des cartes (élémentaire, ombre, éclats du prismatique)
sont des **systèmes de particules** — tailles, vitesses, durées de vie et profondeurs toutes
différentes, avec des événements. Jamais un motif répété qui défile.
**Ce qui a fait pencher** : le verdict de Maxim sur la v2 — *« les effets on dirait des effets
PowerPoint 2001 »*. Un motif en grille qui avance à vitesse constante se repère au premier regard.
**Ce qu'on a écarté** : les particules en image de fond répétée (v2) ; le prisme en voile
arc-en-ciel uniforme, qui lavait toute la carte (*« moins marquante que la base »*).
**Ce que ça coûte, et qu'on assume** : du code d'effet par type — dans Godot, un `GPUParticles2D`
par comportement et un shader pour le holo — et un budget de performance à surveiller quand
plusieurs cartes animées sont à l'écran.
🔓 **Ce qui la rouvrirait** : un téléphone d'entrée de gamme qui ne tient pas le budget → effets
allégés sur les miniatures, jamais sur la carte en grand.

✅ *La v3 est validée par Maxim le 22/09 (« on peut partir là-dessus »), sauf le feu et l'eau,
refaits en v3.1. Base, or et full art sont validés tels quels.*

### Les cartes ont un TYPE, et l'élémentaire en dépend — 22/09/2026

**Ce qu'on a tranché** : chaque carte a un **type** (un élément). La variante Élémentaire habille
la carte dans la matière de son type — éclairs pour la foudre, neige pour la glace, braises pour
le feu.
**Ce qui a fait pencher** : *« L'élémentaire c'est en fonction de la carte, un type foudre aura
des éclairs, un type glace de la neige »* (Maxim). Et c'est cohérent avec la roue des types qu'il
avait décrite chez Clash of Critters.
**Ce qu'on a écarté** : le triangle provisoire `OCRE` / `ARDOISE` / `MOUSSE` du 21/09 — des
couleurs sans sens, qui ne disaient rien du héros.
**Ce que ça coûte, et qu'on assume** : **un effet à coder par type**, et une roue « qui bat qui »
à équilibrer. Plus il y a de types, plus les deux coûtent.
🔓 **Ce qui la rouvrirait** : rien.

⚠️ *Les six types (feu, foudre, eau, glace, nature, esprit) sont une **proposition de Claude**, pas
encore validée — voir `FEATURES.md` § ⑤.*

### Cartes : VERSION A, et les quatre verrous — validés le 22/09/2026

**Ce qu'on a tranché** : les unités **sont présentées** comme des cartes ; **le combat reste La
Poussée**. Avec quatre verrous : (a) la variante suit le héros à travers ses évolutions ; (b) les
variantes sont du code, pas des images ; (c) « même niveau » = même niveau final, chemin
différent ; (d) la matière monte avec le stade — vinyle, résine peinte, statue de collection.
**Ce qui a fait pencher** : *« Ok pour moi »* (Maxim), en réponse aux trois questions.
**Ce qu'on a écarté** : la version B (un vrai jeu de cartes, main/pioche/mana) — un autre projet,
dont l'équilibrage est un travail permanent.
**Ce que ça coûte, et qu'on assume** : une carte est un rectangle — on les distingue par
l'illustration et le cadre, plus par la silhouette.
🔓 **Ce qui la rouvrirait** : rien.

⚠️ **Shiva : hors v1.** C'était la recommandation de Claude ; le « ok pour moi » de Maxim couvrait
les trois questions d'un coup. **Noté comme interprété** — à rouvrir si Maxim y tenait.

### L'univers : FOLKLORE ET LÉGENDES — choisi par Maxim — 22/09/2026

**Ce qu'on a tranché** : les cartes sont des personnages du folklore et des légendes du monde.
Des très connus (Wukong, Thor, Loki, Ifrit, Bahamut…) et des moins connus. Avec la touche
personnelle de Maxim : **Saint Georges et le Dragon du Doudou** (Mons, le Lumeçon).
**Ce qui a fait pencher** : c'est le choix de Maxim — exactement la méthode convenue le 21/09
(*Maxim fixe l'univers, Claude en tire les règles*). Et son arc d'évolution répond à l'objection
du 20/09 : un nom connu n'est plus « déjà possédé » quand on le découvre en version bébé.
**Ce qu'on a écarté** : les créatures inventées comme personnages (Motte, Broque, Linge, Épingle,
Touffe, Cornu). ⚠️ *Lecture de Claude, à confirmer* : elles deviennent des placeholders, on garde
leur **gabarit de rendu**, pas leurs personnages.
**Ce que ça coûte, et qu'on assume** : terrain encombré (FGO, Smite, SMT). La différence ne vient
pas du sujet mais du **traitement** — l'arc d'évolution et le rendu.
🔓 **Ce qui la rouvrirait** : rien — c'est l'univers.

⛔ **LES LIMITES — vérifiées le 22/09/2026 :**
- **Mythologies sans pratiquants de masse** (nordique, grecque, égyptienne, chinoise classique,
  folklore européen, arabe, japonais) : **libres**.
- 🔴 **Divinités d'une religion VIVANTE** (hindouisme : Shiva, Kali, Ganesh…) : risque documenté.
  *Smite* (2012) a dû retirer puis redessiner Kali après des protestations hindoues, soutenues par
  des représentants catholiques, juifs et bouddhistes. Un stade « mignon » + une variante « ombre »
  d'une divinité vénérée aujourd'hui = **la combinaison la plus risquée possible**.
  → **À ARBITRER PAR MAXIM.** Reco de Claude : hors v1.
- **L'iconographie d'une œuvre protégée est interdite, le mythe est libre.** Bahamut *dragon*
  vient de *Donjons & Dragons* puis de *Final Fantasy* — le Bahamut du **mythe arabe est un
  poisson cosmique** qui porte le monde. Ifrit : le djinn du folklore est libre, le design de
  *Final Fantasy* non. Thor, Loki : les mythes sont libres, les designs *Marvel* non.

### Pas de raretés de PUISSANCE : toutes les cartes au même niveau, seules les VARIANTES sont rares — 22/09/2026

**Ce qu'on a tranché** : aucune carte n'est commune, rare ou légendaire. Chaque carte peut tomber
dans une **variante** (or, ombre, élémentaire, prismatique…) selon une probabilité. **La variante
ne change aucune statistique.**
**Ce qui a fait pencher** : *« pas 40 raretés, toutes les cartes sont au même niveau »* (Maxim).
C'est la doctrine de prestance appliquée à la lettre — plus propre que la proposition de Claude
du 21/09 (paliers commune/rare/légendaire), qui est **déjà dans le code et doit sauter**.
**Ce qu'on a écarté** : les paliers de rareté de puissance.
**Ce que ça coûte, et qu'on assume** : toute la rareté perçue repose sur les variantes — elles
doivent être spectaculaires. Et 🔴 **les probabilités doivent être affichées** dès qu'un tirage
est payant : Apple depuis décembre 2017, Google Play depuis 2019, et une loi en Corée du Sud.
🔓 **Ce qui la rouvrirait** : rien.

### Les évolutions : 1 ou 3 stades, du mignon au badass — 22/09/2026

**Ce qu'on a tranché** : certains personnages ont 1 stade, d'autres 3. Arc inspiré de Pokémon :
**stade 1 mignon, stade 2 sérieux, stade 3 badass.**
**Ce qui a fait pencher** : Maxim. Et un signe que l'idée est juste : certains mythes contiennent
déjà l'arc — le Wukong du *Voyage vers l'Ouest* naît singe de pierre, devient Roi des Singes, puis
Grand Sage égal du Ciel ; la kitsune gagne des queues en vieillissant.
**Ce que ça coûte, et qu'on assume** : **une illustration par stade.** C'est là que va le budget
d'images.
🔓 **Ce qui la rouvrirait** : rien.

### Le mini-jeu est une POUSSETTE, et elle est validée — 21/09/2026

**Ce qu'on a tranché** : le robinet du jeu est une **machine a poussée** (coin pusher), un seul
poussoir, plateau court, temps réel, aucun bouton.
**Ce qui a fait pencher** : c'est l'idée de Maxim, et elle a les quatre propriétés d'un mini-jeu
accrocheur — **un geste pour dix secondes de conséquences**, une récolte qui s'empile, le
**presque-raté** intégré au mécanisme, et de la physique qui varie à l'infini.
**Ce qu'on a écarté** : le grattage (« le dégagement »), jeté après test sur téléphone ; le plinko
(choix illusoire) ; les deux étages (trop compliqué, téléportation visuelle).
**Ce que ça coûte** : la physique plafonne vers 180 corps sur mobile. Toute densification
future se mesure, ne se suppose pas.
🔓 **Ce qui la rouvrirait** : si Maxim ne le relance pas de lui-même une fois le jeu habillé.

### La direction artistique : art toy, six figurines, gabarit tenu — 21/09/2026

**Ce qu'on a tranché** : figurines vinyle mates, palette désaturée, **expression ambiguë et
paupière basse**, socle visible, ligne de moulage, photographie produit sur fond neutre.
Six silhouettes distinctes : Motte, Broque, Linge, Epingle, Touffe, Cornu.
**Ce qui a fait pencher** : le gabarit de prompt a tenu sur les six d'un coup — même fond, même
lumière, même matière. **C'est la preuve qu'il est réutilisable pour les cinquante suivantes.**
**Ce qu'on a écarté** : le mignon primaire (trop enfant, hors cible).
**Ce que ça coûte** : une DA exigeante. Un écart vers le bariolé et tout retombe en jouet.
🔓 **Ce qui la rouvrirait** : rien.

⚠️ **Deux défauts à régler À LA SOURCE, pas en post-traitement** : un **filigrane en étoile** sur
les six images, et un fond doux avec ombre portée qui rend le détourage impossible.
🔄 *Périmé le 22/09/2026 : avec les cartes, plus rien n'est à détourer — la carte recadre
l'image. Le « fond blanc pur » est abandonné. Le filigrane, lui, reste à régler.*
🔄 *23/09/2026 — Maxim a généré les héros dans un autre style : des **illustrations peintes**,
décor complet, rubans rouges en fil conducteur — 25 images, 11 héros, dans `Cartes/Illustration/`.
Plus de figurine photographiée. 🗣️ **À confirmer par Maxim** : ce style remplace-t-il la DA
« art toy » ? Si oui, cette décision et le gabarit de `docs/art/HEROS.md` sont à réécrire.*

### CLAUDE NE PROPOSE PLUS D'UNIVERS — 21/09/2026

✅ *Appliqué le 22/09/2026 : c'est Maxim qui a fixé l'univers.*

**Ce qu'on a tranché** : le thème est **gelé**, et quand on y reviendra, **c'est Maxim qui fournit
les références** (images, jeux qu'il aime) et Claude qui en extrait les règles.
**Ce qui a fait pencher** : cinq univers proposés par Claude, **cinq rejetés** — abysses/herbier,
masques, faune spéculative, objets, fête foraine. Le taux d'échec dit que la méthode est
mauvaise, pas les goûts de Maxim. *« Honnêtement j'ai aucune idée »* — décrire ce qui lui plaît
n'est pas son travail ; le reconnaître quand il le voit, si.
**Ce qu'on a écarté** : continuer à pitcher.
**Ce que ça coûte** : on avance sans univers. C'est assumé — **le thème est une peau**, il se pose
à la fin sur un jeu qui tourne. C'est déjà la doctrine « le geste avant le thème ».
🔓 **Ce qui la rouvrirait** : rien.

### La cible : des ADULTES qui paient, pas des enfants — 20/09/2026

**Ce qu'on a tranché** : la direction artistique est celle de l'**art toy pour collectionneurs
adultes** (POP MART, Labubu, Skullpanda, Crybaby), pas du jouet pour enfants. Hommes **et**
femmes. Les unités sont des **figurines vinyle**, présentées comme des objets de vitrine.
**Ce qui a fait pencher** : *« tout fait trop enfant, c'est pas la cible, on veut des adultes
homme et femme qui paie »* (Maxim). Et le marché confirme : POP MART pèse ~44 Md$ mi-2026, a
vendu 100 M+ de Labubu en 2025, **~60 % d'acheteuses**, sur un mécanisme de **boîte mystère qui
EST un gacha**. Le marché chinois de l'art toy vise 15 Md$ en 2026.
**Ce qu'on a écarté** : le mignon primaire type Clash of Critters / Funko. Plus large mais
&laquo; enfant &raquo;, donc hors cible, et sans le pouvoir d'achat.
**Ce que ça coûte, et qu'on assume** : une DA **exigeante et tenue** — désaturée, matière,
expression ambiguë. Un écart vers le bariolé et tout l'édifice retombe en jouet pour enfant.
🔓 **Ce qui la rouvrirait** : rien à ce jour.

⛔ **Le style, oui. Les personnages, NON.** Labubu, Skullpanda, Dimoo et consorts sont des IP
protégées. On s'inspire du **langage visuel** (matière, palette, proportions, présentation),
jamais d'un design de personnage existant.

### L'argent achète la PRESTANCE, jamais la puissance — 20/09/2026

**Ce qu'on a tranché** : un F2P peut atteindre les sommets. Il lui faut **plus de temps** qu'un
payeur, pas moins de plafond. Ce qui se vend : shinies, cosmétiques, cadres de profil, vitesse.
**Ce qui a fait pencher** : *« un F2P peut atteindre les sommets mais en plus longtemps qu'un
p2w »* (Maxim). Et un argument de structure : **la frime exige des spectateurs**. Un PvP où les
payeurs écrasent vide le jeu de ceux devant qui l'on frime.
**Ce qu'on a écarté** : vendre de la puissance. Rapporte plus vite, casse la règle des deux jours,
et assèche le PvP.
**Ce que ça coûte, et qu'on assume** : moins de revenu par payeur, et il faut **beaucoup** de
cosmétiques pour que ça pèse.
🔓 **Ce qui la rouvrirait** : rien de mesurable à ce jour — c'est une doctrine, pas un pari.

### Le PvP est ASYNCHRONE, et il vient en second — 20/09/2026

**Ce qu'on a tranché** : on n'affronte pas un joueur en direct, mais **l'instantané de son
équipe**. Et on construit **le corps du jeu d'abord** : combat hors ligne, puis PvE, puis le PvP.
**Ce qui a fait pencher** : *« PvP en second step, faut le corps du jeu là »* (Maxim). Le PvP
asynchrone garde l'essentiel de la frime pour une fraction du coût : ni matchmaking temps réel,
ni serveur autoritaire, ni latence.
**Ce qu'on a écarté** : le PvP temps réel — double la taille du projet et ajoute un coût
d'exploitation permanent.
**Ce que ça coûte, et qu'on assume** : pas de duel en direct, jamais.
🔓 **Ce qui la rouvrirait** : une communauté qui le réclame ET un revenu qui paie l'exploitation.

#### Les douze pistes de thème — gelées le 20/09/2026, pas écartées

| | La piste | Ce qu'on en disait |
|---|---|---|
| 1 | La faune d'après nous *(Terre + 10 M d'années)* | Reco de Claude — combinatoire par construction |
| 2 | Les insectes | Écartée : une part du public ne les supporte pas |
| 3 | Le micro-vivant *(plancton, diatomées)* | Attachement faible |
| 4 | Les oiseaux *(carnet d'observation)* | Très doux — la tension reste à trouver |
| 5 | La faune abyssale | Déjà maquettée le 20/09 |
| 6 | La faune disparue *(paléontologie)* | Le dinosaure est saturé |
| 7 | La xénobiologie | Le SF générique guette |
| 8 | Les colonies *(sociétés, pas individus)* | Risque de lisibilité |
| 9 | Les migrateurs *(on collectionne des trajets)* | On possède mal un voyage |
| 10 | La faune nocturne d'ici | Peu de merveilleux |
| 11 | Les domestiqués | Glisse vers la gestion |
| 12 | Les cryptides | ⛔ Rechute dans le monstre |

⛔ **Les monstres mythologiques ont été examinés et écartés** — pas pour la saturation (FGO,
Summoners War et ses 1500 monstres, P&D), mais parce qu'**ils appartiennent déjà au joueur** :
tout le monde sait ce qu'est un minotaure, donc la collection ne peut plus étonner. *L'étonnement
est le carburant d'une collection.*
🔓 **ROUVERT LE 22/09/2026** — Maxim le veut : la condition est remplie. Et son arc
d'évolution répond à l'argument (Thor en bébé n'est plus « déjà possédé »). Voir « L'univers :
folklore et légendes ».

---

## Les doctrines — elles ne bougent pas sans en reparler

> **Une doctrine est une décision qui s'applique à toutes les suivantes.** Elle se fait préciser
> par celui qui l'a posée : *une doctrine en trois mots n'a pas la portée qu'on lui prête.*

- 🔴 **LE GESTE AVANT LE THÈME.** Ce qui différencie ce jeu est **ce qu'on fait avec le pouce**,
  pas ce qu'on collectionne. Toute proposition s'évalue d'abord là. *(posée le 20/09/2026)*
- **Une vue canonique par pièce de collection, jamais une séquence.** L'art est généré : montrer
  chaque sujet **une seule fois dans un cadre figé** évite le seul cas que la génération rate
  vraiment — le même sujet sous plusieurs angles. ⛔ *Ça interdit le sprite animé. Ça n'interdit
  rien de vivant.* *(posée le 20/09/2026)*
- 🔴 **LE COMBAT EST DÉTERMINISTE ET PILOTÉ PAR LES DONNÉES.** Mêmes équipes + même graine =
  même résultat, toujours. ⛔ *À poser AVANT la première ligne de combat : c'est ce qui rend le
  PvP asynchrone quasi gratuit plus tard, et c'est irrattrapable ensuite.* *(posée le 20/09/2026)*
- **La règle des deux jours** — un joueur n'est jamais bloqué plus de 48 h : ni par l'argent, ni
  par un minuteur, ni par un mur de difficulté. *(posée par Maxim le 20/09/2026)*
- 🔴 **ON NE VEND NI LA CHANCE NI LA VICTOIRE. On vend la collection et la personnalisation.** Rien de ce qui s'achète ne
  mène à un tirage (même par une monnaie du jeu), et rien de ce qui s'achète ne manque à un joueur gratuit. *(phrase de
  ChatGPT, adoptée par Maxim le 01/10/2026 ; sa portée, confirmée le 01/10 : la monnaie payante — les Comètes — n'achète
  pas de cartes, et aucune pièce ne se vend : DECISIONS 01/10)*

---

## 📌 Ce qui est VRAI sur ce projet et ne se re-discute pas

- 🎯 **La cible : ~20 k€/an pour cette app**, dans un portefeuille de plusieurs apps sur plusieurs
  années. ⛔ *Ne jamais recalculer sur 100 k€ — ce n'est pas l'objectif, et ça fausse tous les
  arbitrages qui en découlent.*
- **Maxim est seul.** L'étalon de livraison est **~1 feature par semaine**. ⛔ *Un dilemme bâti
  sur une surestimation de l'effort est un dilemme inventé.*
- **Rien n'est figé** : ce registre est une feuille de route, pas un contrat. Si
  l'implémentation apprend mieux, **on change le registre**. Seuls les **garde-fous**, les
  **contraintes externes** et les **doctrines** ne bougent pas sans en reparler.
