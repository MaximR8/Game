# 🗺️ FEATURES — le registre de ce qui RESTE À FAIRE

> **Rien n'existe tant que ce n'est pas écrit ici.**

## ⛔ LE PROTOCOLE — il commande tout

Quatre temps, dans cet ordre, **jamais raccourcis** :

| | Temps | Ce qui se passe | Ce qui est interdit |
|---|---|---|---|
| 1 | **Discuter** | Le besoin réel, les cas limites, ce que ça touche, les alternatives | Proposer une implémentation |
| 2 | **Décider** | **Une** recommandation tranchée. Maxim arbitre | Rester neutre, lister 4 options |
| 3 | **Valider** | Maxim dit explicitement qu'on est d'accord | Supposer l'accord |
| 4 | **Noter + dater** | On écrit ce qu'il faut faire, et **une date** | Écrire une date sans validation |

⛔ **Une seule feature par conversation.** ⛔ **Aucune date sans validation explicite.**
⛔ **Aucun code pendant une discussion.**

---

# 🗺️ LA FEUILLE DE ROUTE

**L'ordre : trancher la forme des unités → coder le combat → l'habiller → le contenu PvE → le
réseau.** Il vient de la logique — chaque étage porte le suivant — pas des dates.

| Rang | La feature | État · ce qu'on en sait |
|---|---|---|
| **1** | **Le combat : le Carré des astres** | ✅ **Décidé par Maxim le 26/09/2026** (⑱) : un jeu de grille façon Triple Triad (chiffres sur les côtés, retournements en chaîne), enrichi en couches. Remplace « version A » et La Poussée. Prototype v1 jouable dans l'Arène d'essai. Voir `docs/reviews/CARRE-DES-ASTRES.md` et DECISIONS. |
| **2** | **Coder le Carré des astres dans Godot** | ✅ **29/09, 8 h 15 : les chiffres se lisent** (la femme du cousin : *« du mal à voir les numéros »*) — la carte de la main touchée grandit à la taille du plateau, la main adverse descend en grand au toucher (CHANGELOG). 📏 **Mesure** : lit-elle mieux ? — **le 5/10** (leur demander). ✅ **Étape 1 livrée le 27/09/2026, 8 h 42** (« go » de Maxim ; CHANGELOG) : le Carré jouable dans le Voyage, **les cartes se glissent de la main au tapis** (la case visée s'allume ; toucher-toucher marche aussi). 📏 **Mesure** : ~~Maxim relance-t-il un combat ?~~ (🔄 28/09 : Maxim teste, il ne joue pas — la mesure se lit chez les cousins, ligne 4). **Étapes 2 et 3 livrées (27-28/09) : ligne 4.** *Le détail de l'étape 1* : le moteur repris du web (parité vérifiée : 400 parties, 3 996 coups identiques), l'écran de combat (tapis, pierres des chiffres, emblèmes des pouvoirs rendus par `design/objets/render_carre.py`), le retournement, le premier combat guidé, le Voyage descellé avec un combat d'essai (Apprenti, Aventurier, Maître). Captures : canevas du Voyage. *Avant :* 🗣️ **Après les retours de Maxim sur la v2 web** (le téléphone). **La v2** (26/09) : **3×3** par défaut, **4×4 en événement** (gouffre + 3 renforts), deck de **5** (poids ≤ 14), mains visibles, chaînes, terres, un pouvoir pour 10 héros (icône + fiche), la carte avec ses 6 variantes et les chiffres en croix, une page Mes decks, l'ordinateur en 3 niveaux (Apprenti, Aventurier, Maître). 🔄 *La Poussée : 💤 non retenue le 26/09 (démo incomprise).* |
| **3** | **La main limitée (~15 jetons)** | 🔄 **Remplacée le 28/09 par ⑧ lot A** : plus de recharge des pièces — celles de la journée (le cadeau, les défis) font la main ; chaque pièce compte. |
| **4** | **Le Voyage : l'Aventure (100 niveaux), le Duel, le Classé** | 🗓️ **Décidé le 26/09/2026** (DECISIONS) : 10 chapitres × 10 niveaux, un boss tous les 10 ; 3 ★ par niveau et des coffres de chapitre (récompenses serrées : les cartes ne viennent que des invocations) ; la victoire parfaite animée ; Duel (MMR ±100) et Classé (Poussière → Légende, saison mensuelle, remise d'un rang) contre des fantômes ; tout suit un calendrier automatique. ✅ **Les 7 maquettes validées « techniquement » (26/09)**, le look refusé (tout sortira de la fabrique). ✅ **L'Aventure est en ligne depuis le 27/09/2026, 15 h 36** (« go » de Maxim, CHANGELOG) : 10 terres × 10 niveaux (boss écrits, 90 niveaux fabriqués), les ★ et leurs défis, les coffres, la victoire parfaite ; la courbe mesurée au banc (joueur moyen : 90 % à la 1ʳᵉ terre, ~50 % à la 10ᵉ). La 3ᵉ ★ d'un boss : « Retourne la carte de <boss> » (accepté). 📏 **Mesure** : jusqu'où Maxim va dans l'Aventure en 3 jours, et s'il y revient seul — **à relire au prochain chat**. ✅ **Mes decks en ligne le 27/09, 18 h 22** (sorti de l'étape 3, CHANGELOG). ✅ **Les sbires dans les invocations, et les rangs des héros : en ligne le 27/09, 23 h 58** (CHANGELOG). ✅ **Le premier pack offert, guidé, et la fin des cartes prêtées : en ligne le 28/09, 8 h 36** (CHANGELOG). 📏 **Mesure** : les cousins ouvrent-ils leur pack et jouent-ils leur premier combat ? *L'Aventure (28/09)* : Maxim la teste sans y jouer ; le cousin et sa femme n'en disent que du bien → on la laisse telle quelle (*« on verra à l'usure »*). ✅ **LE DUEL ET LE CLASSÉ : en ligne le 28/09/2026, 14 h 53** (fiche *« 1. OK 2. ok »*, captures *« Go go »* ; CHANGELOG, DECISIONS 28/09) : trois onglets ; le Duel (cote Elo, adversaire à ±100) ; le Classé (Météore → Comète → Aurore → Éclipse → Galaxie → Zénith, 3 marches de 100 points, +25/−20, planchers, saison = le mois, −1 rang, récompense au meilleur rang) ; des adversaires qui sont l'ordinateur, présentés comme des personnages ; la poussière du jour (5 × 30, Duel ou Classé) ; quitter = perdre. Réglé au banc (`banc_fantomes -- echelle`) : le Zénith demande le meilleur deck ET le jeu du Maître (~86 parties) ; un joueur moyen cale à Éclipse ou Galaxie. 📏 **Mesure** : le rang du cousin et de sa femme à la fin de la saison du Cygne, et s'ils jouent encore une fois leurs 5 victoires du jour faites — **à relire le 1er novembre** (leur demander) ; d'ici là, **le 5 octobre** : ont-ils ouvert le Duel ou le Classé ? Et sur le téléphone de Maxim : le Maître en haut de l'échelle joue-t-il sans saccade ? |
| **5** | **Les cartes : univers, variantes, évolutions** | ✅ **28/09, 20 h 18 : le rang se voit** (Maxim : *« on sait pas quand on a une carte mythe, légende, héros ? »*) — dans le bandeau de chaque carte, en couleur ; annoncé au retournement ; une Légende au centre d'une ×10 ; l'Atlas par rang. Et l'ouverture sans saccade (CHANGELOG). 📏 **Mesure** : Maxim ne voit plus l'à-coup au départ (son téléphone). ✅ **Dans le jeu depuis le 23/09/2026** : 11 héros, 25 illustrations, les six variantes **avec leurs effets**, le tirage ×1 et ×10 (le ×10 sur tout l'écran), les dos qui trahissent la rareté, la collection de variantes (on choisit l'affichée), l'évolution, la carte en plein écran, le look « Conte mystique », les taux revus, **le portail
d'invocation et les révélations mises en scène**, **le full art pour tous** *(23/09)*. **22 héros depuis le 23/09 à 21 h 24** (onze nouveaux, Saint Georges en trois stades — types, rôles, ultimes proposés). ✅ **La carte du Carré (v6) en ligne le 27/09, 21 h 53** : les 4 chiffres sur le cadre, le full art casse la fenêtre, une seule carte partout (CHANGELOG, DECISIONS). 📏 **Mesure** : Maxim reconnaît-il un full art en combat, et lit-il les chiffres dans la main ? ✅ *« Oui, bien comme ça »* (27/09, sur son téléphone). ✅ **27/09, 22 h 24 : la carte de l'Atlas se tourne au doigt, en 3D ; son dos dit la légende et le pouvoir** ; le prismatique plus discret, le nom du full art en arc-en-ciel (CHANGELOG, DECISIONS). 📏 **Mesure** : Maxim tourne-t-il les cartes pour lire leur dos, sans qu'on le lui demande ? **À relire au prochain chat.** ✅ **27/09, 23 h 58 : les sbires (9) dans la collection et les invocations (60 %), les rangs des héros (Héros 25 %, Mythe 11 %, Légende 4 %)**. 📏 **Mesure** : les retours des joueurs (les cousins) sur les rangs — Légendes désirables ? trop de sbires au tirage ? « je te fais confiance là-dessus, on verra les retours des utilisateurs » (Maxim, 28/09). **À relire quand les cousins ont joué quelques jours.** Voir § ⑤. |
| **6** | **Backend + PvP asynchrone** | ✅ **Le serveur en place le 29/09/2026, 23 h 20** : Nakama 3.41.0 (et postgres 16) sur le VPS de Maxim, `https://lapoussette.duckdns.org` (DuckDNS : pas de domaine à acheter), derrière son nginx (certbot), tout en 127.0.0.1, sauvegardé chaque nuit ; vérifié de dehors : un compte, une partie écrite et relue, le compte effacé (INFRA § le serveur des comptes). ✅ **Le jeu s'y sauvegarde le 29/09, 23 h 31** : le compte de l'appareil (sans rien demander), la partie envoyée en arrière-plan, le Compte ouvert dans le Menu (`compte.gd`, `test_compte` contre le vrai serveur). ✅ **Lier par mail le 29/09, 23 h 41** (retrouver sa partie sur un autre téléphone ; pas encore de « mot de passe oublié »). **Reste : Google et Apple — AVEC L'APP** (Maxim, 30/09 : *« je veux pas le mettre sur mon NAS, ça sort du projet, l'idée c'est d'avoir une app et mon VPS, basta »* : la connexion Google se déclare avec l'identité de l'app — le paquet Android et l'empreinte de sa clé de signature —, pas avec l'adresse du NAS ; le projet Google Cloud « La Poussette » est créé sur un compte dédié, écran de consentement seulement ; Apple exigé par l'App Store dès qu'on propose Google), puis les amis. 🗣️ **Rouvert le 29/09** (les cousins jouent ; Maxim : *« lier le compte à Google, Apple, mail, Facebook, Discord »*, amis, sauvegarde en ligne). **La reco de Claude** : **Nakama** (serveur de jeu libre, Docker, SDK Godot 4) — comptes (mail, Google, Apple, Facebook ; Discord par un module), amis, sauvegarde en ligne, classements, puis le PvP asynchrone. **Où** : sur le VPS de Maxim (il y a Vesta/FamilyOS et le site d'Empreinte3D) s'il a la place (~1 à 2 Go de mémoire pour Nakama et sa base), puis un serveur dédié. 🔴 **L'app ne parle JAMAIS à la base directement** : elle parle au serveur (Nakama), qui seul touche la base (sinon, n'importe qui lit et modifie tout) ; et avant de vendre des étoiles, ce qui vaut de l'argent (les étoiles, les tirages, les achats) se décide au serveur, pas sur le téléphone. **Effort** : 2 sessions (mail + Google + sauvegarde en ligne), 1 (les amis), 1+ (Apple, Facebook, Discord). **La part de Maxim** : les caractéristiques du VPS ; les applis chez chaque fournisseur ; une page de confidentialité (RGPD) ; la suppression du compte (Apple l'exige). |
| **7** | **Le vrai coin pusher : pièces et objets se superposent** | ✅ **Dans le jeu depuis le 25/09** : la machine 3D, plafond 360 pièces (équilibre mesuré ~335). 🔴 **Mesuré au compteur le 27/09 : 33-35 images/s, physique 16-18 ms à 333-356 pièces** — la machine ne tient pas 60. Écartés au banc : un solveur allégé (aucun gain, rend moins bien), une physique à 30 Hz (plus chère par image). Ce qui coûte : le nombre de pièces qui se touchent. ✅ **27/09, 20 h 29 : pièces de 0,46 (au lieu de 0,40), ~215 sur le plateau au lieu de ~330, −32 % de physique au banc** ; plafond 270. **Mesuré au téléphone : 34-43 images/s, physique 12-14 ms à ~260 pièces** (« vivable, on garde ça pour l'instant ») — la suite : START_HERE D13. 🗓️ *Les apps (Maxim, 27/09)* : le web pour l'instant ; Android et iPhone plus tard par Codemagic, mesurés au compteur avant de sortir. Voir § ⑦. |
| **8** | **L'économie : des pièces qui se méritent** | ✅ **Lot A — la journée : en ligne le 28/09/2026, 16 h 40** (CHANGELOG, DECISIONS 28/09) : le plateau du jour connu d'avance (12 objets), plus de recharge des pièces, les Présages (3 défis du jour à 60 pièces, la semaine → 3 étoiles). Un joueur de chaque jour : ~17 étoiles par semaine. 📏 **Mesure** : le cousin et sa femme vident-ils leur plateau, reçoivent-ils leurs défis ? **À relire le 5/10** (leur demander) ; la journée trop courte ou trop longue ? **le 12/10**. ✅ **Lot B — la collection : en ligne le 28/09/2026, 18 h 48** (CHANGELOG) : les éclats (5 par invocation ; ils obtiennent toute carte, toute variante sauf le Full art), jamais de Full art ni de prismatique en double, l'évolution plus longue. 📏 **Mesure** : les cousins obtiennent-ils une carte avec leurs éclats ? **le 12/10**. ✅ **29/09, 19 h 54 : tout le plateau du jour posé** (chaque objet sur un amas de pièces, le ticket au fond, la moitié des pierres au hasard, l'XP devant), **deux fentes** sur les côtés (~27 % des pièces s'y perdent), le bloc du haut presque vide, les défis à **35 pièces** (la semaine 120) — vider le plateau coûte ~100 pièces nettes pour ~155 données par jour (DECISIONS 29/09). 🗓️ *Maxim* : *« que les gens achètent des pièces pour jouer plus à la machine »*, des packs avec **une « Nouvelle machine »** (un plateau de plus) — avec la boutique. 💡 *Idées de Maxim (29/09), pas faites* : une **jauge** remplie par les pièces tombées dans les fentes → la **« super machine »** (gains doublés) ; des **objets d'événement**, des mini-jeux programmés 2 à 3 jours d'affilée (comme Clash of Critters). ⚖️ **La boutique et la Belgique (29/09, à faire valider par un juriste)** : la Commission des jeux de hasard tient pour un jeu de hasard tout achat en argent réel qui mène à du hasard, même par une monnaie du jeu — **ni tickets d'invocation, ni pièces pour la machine** (la machine, puis le tirage : deux fois du hasard) ; vendre du **certain** : les éclats (une carte choisie), le cosmétique (thèmes de machine, dos, cadres), un pass aux récompenses affichées, une « Nouvelle machine » sans ticket sur son plateau ; sinon couper ces achats en Belgique et aux Pays-Bas. Voir § ⑧. |
| **9** | **L'évolution rend plus fort, et coûte plus** | ✅ **En ligne le 28/09/2026, 18 h 48, avec le lot B de ⑧** (accepté le 28/09, *« ça doit être difficile d'évoluer, faut une belle durée de vie »*) : niveau 5 et 1 pierre, puis niveau 10 et 2 pierres ; un niveau coûte 100 × le niveau (~6 mois pour tout monter). Le stade change déjà les chiffres en combat. Voir § ⑨. |
| **10** | **La page des invocations : des portails** | ✅ **L'Astrolabe en ligne le 28/09/2026, 22 h 27** (fiche *« 1. je te fais confiance 2. la 100ème d'office 3. minimum un héros 4. oui 5. oui »*, *« valide direct »* ; CHANGELOG, DECISIONS 28/09) : deux ciels — **le Grand Ciel** (permanent, les chances de toujours, le premier pack) et **le Ciel du Peintre** (Full art ×2, jamais un sbire, **le 100ᵉ garanti**, refermé au premier Full art, **la première ×10 offerte**) ; **« Mes decks » en haut de l'Atlas**. Toute la barre du bas est ouverte. 📏 **Mesure** : le cousin et sa femme ont-ils pris leur invocation offerte, où en est leur compteur, ont-ils refermé le Peintre ? — **le 12/10** (leur demander) ; sur le téléphone de Maxim : l'invocation part-elle sans à-coup depuis l'Astrolabe ? Voir § ⑩. |
| **11** | **Le jeu en plusieurs langues, l'anglais d'abord** | 🗣️ Posé par Maxim le 23/09. La fondation coûte moins cher tôt. Voir § ⑪. |
| **12** | **Le médaillon du type, au look « Conte mystique »** | 🗣️ Posé par Maxim le 23/09 : l'icône élémentaire des cartes ne colle plus à la DA. Voir § ⑫. |
| **13** | **Le rituel des constellations** | ✅ **Dans le jeu depuis le 25/09** : l'astrolabe, les constellations éparpillées (leur nombre dit la rareté), la carte de dos qui se retourne. Voir § ⑬. |
| **14** | **Les objets de l'univers** | ✅ **Clos le 26/09** (validé sur le téléphone : *« ok pour moi, on reste comme ça »*) : l'étoile d'invocation (bille mauve), la poussière d'étoile (bille bleue), six pierres + la lune, en volume dans la machine ; la sauvegarde v3 convertie. Voir § ⑭. |
| **15** | **L'interface vivante** | ✅ **Clos le 26/09** (en ligne depuis 7 h 20, retouches jusqu'à 16 h 09). 🗓️ **Dessiné (canevas v3, 26/09)** : le bandeau « Constellations », la barre « Médaillons », le gain qui s'envole, le plateau du jour, les boutons, LVL, l'évolution. **Accordé le 24/09** : des icônes nettes et vivantes, une barre du bas pour cinq menus, des noms dans l'univers, **une animation à chaque geste** (niveau, évolution, boutons). Voir § ⑮. |
| **16** | **Les comptes, et l'accès des cousins** | ✅ **L'accès par un code, en ligne le 27/09 à 19 h 21** (`portier/`, INFRA § Le jeu PUBLIC ; vérifié de dehors : 31 vérifications) ; *une partie neuve reçoit son premier pack offert, guidé (28/09 ; avant : 10 étoiles).* 📏 **Mesure** : combien de cousins entrent (le journal du portier) — à relire au prochain chat. Les comptes et la sauvegarde partagée, plus tard. *Avant :* 🗓️ Accordé dans l'ordre le 24/09. **Revu le 25/09** : le NAS est déjà ouvert (`naspoizot.synology.me`, port 443) — plus besoin de Cloudflare. Voir § ⑯. |
| **17** | **Revoir les types pour le combat — ajouter la Roche** | 🗣️ Posé par Maxim le 25/09 : *« il faudrait rajouter Roche en élément, et il y aurait Wukong, le Golem… »*. Voir § ⑫ bis. |
| **18** | **Le jeu lui-même : le gameplay, sa difficulté, où on va** | 🟡 **Le combat est tranché (26/09, nuit) : le Carré des astres.** 27 démos jouées (Arène d'essai), puis l'analyse et la v1. Tranché aussi : les types ne servent qu'aux terres ; l'XP sert seulement à atteindre le niveau d'évolution ; les boîtes payantes sont acceptées (DECISIONS). Le Voyage est tranché (26/09) ; le Carré est dans le jeu depuis le 27/09 (étape 1, ligne 2). **Reste** : les étapes 2 et 3, puis la difficulté, la boucle d'une journée, l'économie (⑧) et la direction à six mois. |
| **19** | **Le son** | ✅ **En ligne le 29/09/2026, 9 h 09** (la femme du cousin : *« ce serait encore pire si j'avais le son »* ; CHANGELOG, DECISIONS 29/09) : la pose (au contact), le froissement du poussoir, le gain **en cascade** (do ré mi sol la do), l'objet, la fanfare du plateau vidé, une musique en boucle ; deux bus (Réglages). **Les sons de Maxim en ligne à 9 h 16** (*« A1 · B1 · C2 · D3 · E2 · F5 »*, choisis sur la page d'écoute https://claude.ai/artifact/JET9DYuQ9eH1iHFCbLMQ6g) ; en changer : `design/sons/preparer_jeu.py` (sa ligne `CHOIX`), `--import`, export. 📏 **Mesure** : la femme du cousin joue-t-elle plus longtemps à la Nébuleuse ? — **le 12/10**. ✅ **29/09, 10 h 25 : le son dans tout le jeu** (l'interface, l'invocation et la rareté, le combat et sa musique, la collection) — **les sons de Maxim en ligne à 10 h 44** (*« G4 · H3 · I1 · J3 · K1 · L1 · M1 · N1 · O1 · P2 · Q3 · R1 · S1 · T3 · U1 · V1 · W2 · X1 · Y2 · Z2 »*) ; `design/sons/catalogue.py`, `preparer_jeu.py` (`CHOIX_SUITE`). ✅ **29/09, 12 h 26 : l'invocation a sa bande-son, calée sur le rituel** (*« ça doit être spectaculaire, ça doit marcher avec l'animation, le petit clap à la fin est horrible »* → film IV1, céleste : `design/sons/invocation.py`, `Son.partition`) ; **la musique générale devient Moonlit Rabbits** (MG9 ; F5 était *« trop lente/douce »*), **à 50 % par défaut** (`Reglages.musique`). ✅ **29/09, 13 h 14 : le son a un espace** (*« pas dans l'App […] plate, sans espace »*, au haut-parleur) — tout le jeu en stéréo, dans la même salle (ES2), le grave refait pour le téléphone : `design/sons/espace.py`, cuit dans les fichiers. ✅ **29/09, 18 h 05 : deux musiques calmes** (*« CA0 pour la Nébuleuse et l'autre pour le reste »*) — Starfield Romance à la Nébuleuse, First Light Particles ailleurs, chacune reprend où elle en était (`Son.musique_de`). |
| **20** | **Le Menu (Présages) : Réglages, Code cadeau ; Compte et Amis** | ✅ **Réglages et Code cadeau en ligne le 29/09/2026, 9 h 09** (Maxim : *« la page Présage pourrait être un peu la page Menu […] un Redeem code »*) : quatre médaillons sous les défis ; le code cadeau sans serveur (`codes_cadeaux/codes.py`, un fichier d'empreintes, une fois par partie ; **BIENVENUE** = 5 étoiles jusqu'au 31/12). **Compte et Amis : scellés**, ils arrivent avec les comptes (ligne 6). 📏 **Mesure** : les cousins tapent-ils le code BIENVENUE ? (le 5/10) |

**Fait (24-27/09)** : ⑬ → ⑦ étape 2 → ⑭ + ⑮, la perf (60 images/s, la collection recyclée), ⑱ (le combat
tranché), puis l'étape 1 du Carré dans le jeu (27/09).
**Ensuite** : **l'étape 2 du Carré, l'Aventure** (ligne 4), puis l'étape 3, puis **⑯ l'accès des cousins**.

*L'ordre proposé par Claude le 24/09 (accordé)* : **⑬ → ⑦ étape 2 → ⑭ + ⑮ → ⑯**, puis la
suite d'avant. *Pourquoi* : la maquette de ⑬ est prête ; ⑦ est adopté et c'est le cœur du jeu ; ⑭ et ⑮
se dessinent ensemble (mêmes objets, même bandeau) et la machine 3D les accueille ; ⑯ ouvre le jeu
quand il a son vrai visage — sa préparation côté Cloudflare peut commencer quand Maxim veut.

*L'ordre proposé le 23/09, pour la suite* : **⑦ → ⑪ → ⑧ → ② + ④ + ⑨ → ⑩**.
⑫ et les onze nouveaux héros se glissent où on veut. *Pourquoi cet ordre* : ⑦ est le geste, et ce
qui ne va pas aujourd'hui ; ⑪ coûte moins cher avant les lots pleins de texte ; ⑧ donne sa valeur
à une pièce avant que le mode histoire en distribue ; ② + ④ + ⑨ est le gros morceau (6 à 8
sessions) ; ⑩ n'a de sens qu'avec des tickets rares.

### Les états

`🗣️ en discussion` · `🗓️ validé + daté` · `🟡 codé, pas déployé` · `✅ livré (+ version)` ·
`💤 non retenu (avec la raison)` · `⛔ fermé (avec sa condition de RÉOUVERTURE)`

---

## ① CARTES — version A ou B *(🗣️ EN DISCUSSION, non validé)*

**Le besoin réel** : les unités doivent être **collectionnables et montrables**. Maxim veut que
les gens frimment avec leur pièce ultra-rare.

| | Ce que c'est | Coût |
|---|---|---|
| **A** | Les unités **sont présentées** comme des cartes. **La Poussée reste le combat.** | Faible — déjà maquetté |
| **B** | Ça devient **un jeu de cartes** *(main, pioche, mana, deck)* | 🔴 **Autre projet** |

**La reco de Claude : A.** Trois raisons :
1. **Le problème d'art disparaît.** Une carte est un cadre + une illustration — exactement ce que
   la génération d'images réussit le mieux. Ni détourage, ni cohérence multi-angles.
2. 🔴 **Le cadre est du CODE, l'illustration est générée.** 200 cartes se ressemblent sans
   qu'aucune illustration n'ait à être cohérente avec les autres.
3. **La frime est native** : foil, holo, full-art, alt-art, numérotée. Le vocabulaire le plus
   développé qui existe, sur des adultes qui paient cher.

**Ce que A coûte** : une carte est un rectangle. Le critère « on les distingue à 64 px » ne passe
plus par la silhouette mais par **l'illustration et le cadre**.

⛔ **Rien ne se code tant que Maxim n'a pas dit A ou B.**

---

## ② LA POUSSÉE — le format de combat *(conçu, testé, PAS codé)*

> 🔴 **Ces règles sont la source.** La démo web n'est qu'une copie qui peut disparaître.

**Le plateau** : un couloir de **10 cases**. Les deux armées s'y font face. La ligne démarre au
milieu. **Atteindre le bord adverse fait gagner.**

**Les quatre règles :**

| | La règle | Pourquoi elle est là |
|---|---|---|
| **1** | **L'ordre de ta colonne EST l'ordre d'action** | Une seule décision avant le combat, qui fait deux métiers |
| **2** | **Celui de devant encaisse TOUT** | Le même placement décide aussi qui tank — trois métiers pour une décision |
| **3** | **Chaque mort pousse la ligne d'une case** | On ne compte pas des dégâts, **on regarde une barre avancer** |
| **4** | **L'avantage de type pousse de 2 au lieu de 1** | Exploiter la roue des types **accélère**, au lieu de juste faire plus mal |

**Les types** : chaque carte a un **type** — un élément. Dégâts ×1,5 en avantage, ×0,7 en
désavantage. 🔄 *Le triangle provisoire `OCRE` / `ARDOISE` / `MOUSSE` est **retiré le 22/09/2026** :
Maxim a posé que les cartes ont un type (« un type foudre aura des éclairs »). Six types proposés
— voir § ⑤. 🗣️ **La roue « qui bat qui » reste à dessiner.***

**DOS AU MUR** : quand la ligne est repoussée à ≤ 2 cases de ton bord, tes survivants passent en
rage, **dégâts doublés**. C'est la mécanique à remontées — les parties qu'on raconte.

**Les rôles** : `garde` *(PV élevés, gagne de l'armure à chaque coup encaissé)* · `frappeur`
*(PV faibles, ATT élevée)* · `appui` *(soigne celui de devant, frappe peu)*.

**Auto ou manuel** : 🎯 **résolution automatique, avec UNE décision manuelle — le déclenchement
des ultimes.** Tout auto = on pose le téléphone au 50ᵉ étage. Tout manuel = épuisant au pouce.
Plus un bouton **AUTO / ×2** une fois l'étage réussi, pour que le farm soit instantané.

🔴 **LE COMBAT DOIT ÊTRE DÉTERMINISTE ET PILOTÉ PAR LES DONNÉES.** Mêmes équipes + même graine =
même résultat. *(Doctrine — voir `DECISIONS.md`.)* C'est ce qui rendra le PvP asynchrone presque
gratuit, et c'est irrattrapable ensuite.

**Les chiffres de la démo** *(relevés le 23/09 — la démo est la seule copie, les voici ici)* :

| | Dans la démo |
|---|---|
| **La ligne** | cases 0 à 10, départ **5** ; gagné à 10 ou quand l'adversaire n'a plus personne |
| **Une manche** | toute ma colonne agit, dans l'ordre, puis toute la sienne |
| **Une action** | frapper celui de devant ; **dégâts = ATT × type (1,5 / 0,7) × 2 si dos au mur, − armure**, 1 au minimum, arrondi |
| **La garde** | **+4 d'armure à chaque fois qu'il AGIT**, plafond 30 ⚠️ *(ce § dit « à chaque coup encaissé » : à trancher)* |
| **L'appui** | soigne celui de devant de sa valeur de soin (**15**) avant de frapper, sans dépasser ses PV |
| **Une mort** | pousse la ligne de **1**, de **2** si le coup fatal avait l'avantage de type |
| **Dos au mur** | mon camp quand la ligne est à ≤ 2, le sien à ≥ 8 : **dégâts ×2** |
| **Les équipes** | **4 contre 3** — la taille d'équipe n'est pas fixée par les règles |
| **Les chiffres** | garde 120 PV / 8 ATT · frappeurs 55-60 PV / 22-26 ATT · appui 70 PV / 6 ATT / 15 de soin |
| **Le hasard** | **aucun** — ni graine, ni tirage : même ordre, même résultat |
| **Les ultimes** | ⚠️ **absents de la démo** : leur déclenchement reste à concevoir |

**Ce qu'il reste à faire** : l'écrire dans Godot, hors ligne, avec les cartes existantes.
**Effort estimé : 4 à 6 sessions.**

**📏 LA MESURE** : *combien d'ordres de colonne différents les gens essaient sur un même
adversaire.* Si tout le monde joue le même, le placement ne sert à rien et le format est mauvais.
**Point de départ : non mesuré.**

---

## ③ LA MAIN LIMITÉE *(🗣️ en discussion)*

Aujourd'hui, un plafond technique (`MAX_CORPS = 115`) affiche « Plateau plein » — **un message de
développeur**. Une **main de ~15 jetons** qui se recharge ferait le même travail comme règle de
jeu : chaque jeton compte, le placement devient intéressant au lieu du mitraillage.

⚠️ **Tension à trancher avec la règle des 2 jours** : une main qui se recharge est un minuteur.
Lecture de Claude : la règle protège **la progression**, pas la session. À arbitrer par Maxim.

Idée liée : **des bonus limités dans le temps** (XP ×2 pendant 5 min) gagnés comme 4ᵉ lot sur le
plateau, avec un chrono à l'écran.

---

## ④ LE PvE *(🗣️ en discussion)*

**Le modèle visé** *(celui de Clash of Critters)* : 80 niveaux par monde, 50+ mondes, un boss tous
les 10. Simple, efficace, ça donne le sentiment de progression.

🔴 **Le piège** : 50 × 80 = **4000 combats**. Un studio peut. Pas un dev seul.

🎯 **La sortie : l'échelle est PARAMÉTRÉE, pas écrite.** Une courbe de difficulté génère la
composition ennemie à chaque étage. **Seuls les boss sont écrits à la main** — et on en réutilise
30 ou 40 en les habillant.

**La v1 retenue** : l'échelle paramétrée *(le corps)* · les boss tous les 10 *(les pics)* · une
**run roguelike** *(la variété, quasi gratuite)* · des **donjons quotidiens** *(la routine)*.
⛔ Le boss mondial attend le backend. ⛔ Les événements saisonniers coûtent en permanence : pas
tant que Maxim est seul.

🗣️ **Le « mode histoire » — proposition de Claude, 23/09, à discuter quand on y sera :**
- **Un chapitre = une terre de légendes** (le Nord, la Chine, les brumes celtes, l'Arabie, Mons…) ;
  ses ennemis sont **les héros de cette terre**, son boss **sa légende** — on affronte un héros
  avant de l'invoquer. Aucune image de plus.
- **La carte des chapitres est le ciel du jeu** : un chapitre est une constellation, chaque étoile
  un combat, le boss l'étoile la plus brillante. On réutilise le ciel qui existe.
- **Quelques lignes de conte par chapitre et par boss**, pas de dialogues : écrites par Claude,
  validées par Maxim.
- **Les récompenses** : pièces, tickets, éclats au premier passage ; de l'XP en rejouant. **Pas
  d'énergie** — ce serait un minuteur (règle des deux jours).
- **L'échelle reste paramétrée** : l'équipe ennemie d'une étoile est tirée d'une graine fixe →
  toujours la même, on peut chercher le bon ordre de colonne *(c'est la mesure de ②)*.

---

## ⑤ LES CARTES — univers, variantes, évolutions

> ✅ **Dans le jeu depuis le 23/09/2026** (`carte_view.gd`, `carte_fx.gd`, `game_state.gd`,
> `collection_screen.gd`) : les vingt-deux héros *(onze ajoutés le 23/09 à 21 h 24)*, leurs stades, les six variantes **et leurs effets**,
> l'invocation ×1 et ×10, les dos qui trahissent la rareté, la collection de variantes.
>
> 📏 **La mesure** : Maxim ouvre-t-il la collection et invoque-t-il **sans qu'on le lui demande** ?
> À relire après sa première semaine de test.

### ✅ Décidé par Maxim le 22/09/2026

- **Univers** : folklore et légendes du monde, connus et moins connus. Saint Georges et le Dragon
  du Doudou y sont.
- 🔄 ~~**Aucune rareté de puissance.**~~ *Renversé le 27/09 : les héros ont un rang (Héros, Mythe, Légende — plus rare, plus fort, plus lourd dans le deck), les sbires en dessous ; DECISIONS 27/09.* Toutes les cartes au même niveau. Seule la **variante** est
  rare : or, ombre, élémentaire, prismatique…
- **1 ou 3 stades d'évolution.** Arc : mignon → sérieux → badass.

### ✅ Les verrous — validés le 22/09/2026 *(« ok pour moi »)*

| | Le verrou | Pourquoi |
|---|---|---|
| **a** | 🔴 **La variante SUIT le personnage à travers ses évolutions** | Sinon personne ne fait évoluer une carte dorée — l'évolution détruirait la frime. |
| **b** | **Les variantes sont du CODE** *(filtre + traitement du cadre)*, pas des images | Sinon ×5 illustrations par stade. En code : **le budget d'images = personnages × stades, point.** |
| **c** | **« Même niveau » = même niveau FINAL, chemin différent** | Un perso à 1 stade doit valoir un perso à 3 stades une fois au bout. Le 3-stades coûte simplement plus d'éclats pour y arriver. |
| **d** | **La matière monte avec le stade** : vinyle *(mignon)* → résine peinte *(sérieux)* → statue de collection *(badass)* | Le vinyle ne sait pas faire « badass ». Toujours un objet photographié, donc la DA reste une ; et le stade 3 devient le collector qu'un adulte achète. |
| **e** | **Les divinités de religions vivantes** (Shiva…) | ✅ **Hors v1** — reco de Claude, *interprétée* dans le « ok pour moi ». À rouvrir si Maxim y tenait. |

### 🗣️ Le design des cartes — maquetté le 22/09/2026, à valider

> Maquette interactive (copie de secours) : https://claude.ai/artifact/Xx9JHnUJgwkLCS6NVnLdp6
> **La spec fait foi, pas la maquette.**
>
> **Verdict de Maxim sur la v2 (22/09/2026)** : la base *« un banger »*, l'or *« top »*, le full art
> *« ça va comme ça, c'est l'illustration qui changera tout »*. L'ombre : il voulait **de la brume
> sur le cadre**. L'élémentaire : la carte oui, les effets *« PowerPoint 2001 »*. Le prismatique :
> *« moins marquante que la base »*. ➡️ La **v3** refait ces trois-là.
>
> **Verdict sur la v3 (22/09/2026)** : *« on peut partir là-dessus »* — sauf **le feu** (*« les
> flammes sont ratées »*) et **l'eau** (*« trois faisceaux qui dépassent la carte, ça rend très
> mal »*). ➡️ **v3.1** : un vrai feu sous la carte, une eau sans faisceaux.
>
> **Verdict sur la v3.1 (22/09/2026)** : le feu, *« encore pire, ça sort de nulle part, on dirait
> un vieux gif »*. ➡️ **v4** : le feu vient du cadre lui-même — des veines incandescentes coulent
> dans le métal, les braises s'en échappent, une vague d'embrasement remonte la carte. **À revoir.**
>
> **Verdict sur la v4 (23/09/2026)** : des cartes mal cadrées (*« Thor, sa tête sort du cadre en
> haut, Dragon du Doudou aussi »*) ; le prismatique *« vend pas du rêve, le bord est trop large et
> pas assez waow à côté des autres »* ; les full art *« géniaux »*, mais ce sera une illustration
> à part. ➡️ **v5** : un cadrage par image ; le prismatique devient un holo sur l'illustration,
> au bord aussi fin que les autres. **À revoir.**
>
> **Verdict dans le jeu (23/09/2026)** : l'ombre *« trop forte »*, et elle *« se confond avec
> l'élémentaire esprit »*. ➡️ **Graphite et fumée**, une brume plus légère — dans le jeu et dans la
> maquette (v5.2).

**L'anatomie — la carte du Carré (v6, en ligne le 27/09/2026, 21 h 53)** *(DECISIONS 27/09)* : une seule carte
partout (Atlas, main, plateau). 1. l'**illustration** dans une **fenêtre**, le cadre autour — le **full art casse la
fenêtre** (l'image sur toute la carte, les textes sur verre) · 2. les **4 chiffres du Carré sur le cadre**, au milieu du
côté qu'ils défendent (`CarteView.PIERRES`) · 3. en bas, la **plaque** : le **nom**, la **forme** et le **stade** (●○○) ·
4. à gauche du chiffre du bas, le **type** ; à droite, l'**emblème du pouvoir** (s'il en a un) · 5. en haut, en petit, le
**rôle** et le **pays**. *Retirés avec La Poussée : l'ultime, PV/ATT, le ruban, le numéro de collection, la gemme.*
*Avant (v5, 22-23/09) : nom · forme et stade · affinité · illustration · rôle sur le ruban, pays · ultime · PV/ATT ·
numéro et marque de variante.*

**Les six variantes, et leurs probabilités** *(revues par Maxim le 23/09 : « la prisma tombe trop
facilement » — full art 0,1 %, prismatique 1 %, les autres un point de moins, le reste à la base)* :

| Variante | Proba. | Environ | Ce qui change *(tout est du code)* |
|---|---|---|---|
| **Base** | 73,9 % | 3 sur 4 | Rien — c'est la carte. Mate, filet de laiton. ✅ *Validée le 22/09* |
| **Or** | 15 % | 1 sur 7 | Cadre doré, étincelle, reflet qui balaie la surface. ✅ *Validée le 22/09* |
| **Ombre** | 7 % | 1 sur 14 | **Graphite et fumée** : clair-obscur sans couleur, et **une brume légère qui dérive sur le cadre**. ✅ *Validée le 22/09 (v3) — passée au graphite le 23/09 : violette, elle se confondait avec l'élémentaire esprit* |
| **Élémentaire** | 3 % | 1 sur 33 | **Selon le TYPE de la carte** : cadre dans la matière du type, et son effet **en vraies particules** (éclairs, neige, braises…). ✅ *Validée le 22/09 (v3) — feu et eau refaits en v3.1, à revoir* |
| **Prismatique** | 1 % | 1 sur 100 | **Le holo** : quand la carte s'incline, une bande de spectre balaie l'illustration et s'allume sur ses lumières ; cadre de chrome irisé, aussi fin que les autres ; paillettes et éclats *(v5, à revoir)* — 🔄 **27/09 : plus discret que le full art** (bord 2,2 u, moins de lueur) ; **28/09 : tout le cadre en chrome irisé, le nom en reflet irisé** (« trop sobre »), DECISIONS |
| **Full art** *(ultra rare)* | 0,1 % | 1 sur 1 000 | **L'illustration de la carte en entier**, pleine carte, textes sur verre, un arc-en-ciel qui tourne sur le bord — **tous les héros** *(Maxim, 23/09 au soir : « elles peuvent toutes être full art maintenant »)* — 🔄 **27/09 : son nom en arc-en-ciel qui défile** (Maxim) |

➡️ **Tous les héros peuvent tomber dans toutes les variantes**, full art compris. *(Taux vérifiés
par le vrai chemin du jeu sur 200 000 cartes, le 23/09.)*
🔴 **Ce tableau s'affiche dans l'écran d'invocation dès le premier jour** (Apple, Google Play).

**Deux propositions de Claude** *(tranchées le 23/09 : (f) écartée, (g) acceptée)* **:**

| | La proposition | Ce que ça change |
|---|---|---|
| **f** | ❌ **Écartée le 23/09** — le full art sera une illustration à part. *Proposition d'origine : chaque illustration générée au format de la carte, avec son décor ; la carte normale en montre le cadrage, le full art la montre entière.* | Le full art ne coûte **aucune image de plus** : 12 héros = **28 illustrations**, pas 56. En échange, le fond gris neutre devient **un décor — un diorama sous la figurine**. |
| **g** | ✅ **Acceptée le 23/09, puis élargie le même jour** : **chaque variante tirée rejoint la carte** — une plus rare que l'affichée prend sa place à l'arrivée, et **le joueur choisit celle qu'il affiche** (demande de Maxim). Un doublon rapporte 25 XP dans tous les cas. | Tirer « Thor prismatique » quand on a déjà Thor au stade 2 n'est jamais une déception. |

### Le type de la carte — l'élémentaire en dépend *(décidé par Maxim le 22/09/2026)*

*« L'élémentaire c'est en fonction de la carte : un type foudre aura des éclairs, un type glace,
de la neige. »* Six types **proposés par Claude**, chacun avec son effet — **tout en code** :

| Type | L'effet dans l'illustration | L'effet sur le cadre *(maquette v4)* |
|---|---|---|
| **Feu** | des braises qui s'échappent du cadre et montent ; la chaleur au pied de l'image | **le cadre en fusion** : des veines incandescentes coulent dans le métal ; l'**embrasement**, une vague de chaleur qui remonte la carte *(v4)* |
| **Foudre** | l'éclair frappe — parfois deux fois — et illumine toute la carte | un courant qui file le long du cadre, des arcs qui claquent |
| **Eau** | les reflets des vagues (caustiques), des bulles qui montent et éclatent | des gouttes qui glissent le long du cadre *(v3.1 : plus de faisceaux)* |
| **Glace** | de la neige sur trois profondeurs, des rafales | du givre qui pousse depuis le cadre, un reflet qui le traverse |
| **Nature** | des feuilles qui tournoient en tombant, des spores, des rais de soleil | des pousses aux quatre coins |
| **Esprit** | des feux follets en comètes, une brume fantôme | les follets passent sur le cadre et en sortent |

🔴 **La règle des effets** *(tirée du verdict « PowerPoint 2001 », 22/09/2026)* : **jamais un motif
répété qui défile à vitesse constante**. Un effet, c'est un **vrai système de particules** : tailles,
vitesses et durées de vie toutes différentes, **trois profondeurs** (proches = grosses et floues,
lointaines = petites et nettes), et **des événements** — l'éclair qui frappe, la rafale, la gerbe.
**Et rien de lumineux ne sort de la carte en faisceau** : un rai qui dépasse du cadre fait tache
*(verdict sur l'eau, 22/09)*. **Et un effet naît de la carte** — du cadre, de l'illustration —,
jamais du vide autour *(verdict sur le feu, 22/09)*.
Dans Godot : un `GPUParticles2D` par comportement, et un shader pour le holo. Le moteur de la
maquette (`window.FX`, dans la page publiée) sert de référence.

🗣️ **Ouvert :**
- **La roue « qui bat qui »** — à dessiner.
- **Nian est peint en rouge et or** (le Nouvel An) : le type Glace jure avec son illustration.
  Feu ?
- **Nature ou Terre ?** Wukong naît d'un œuf de pierre ; les korrigans hantent les dolmens. « Terre »
  couvrirait la pierre **et** la nature — l'effet deviendrait poussière et cailloux plutôt que feuilles.
- **Saint Georges n'entre dans aucun des six.** Argument pour un septième type (Lumière ?).

### Ce qui habille la carte *(maquette du 22/09/2026, v3 — la v6 du 27/09 a retiré le ruban, les médaillons de stats et la gemme)*

- **Des filigranes aux quatre coins**, dans la matière de la variante (laiton, or, violet, irisé…).
- **Une gravure fine** (guilloché croisé) sur tout le cadre — elle attrape la lumière.
- **Une plaque** pour le nom, en relief, et **un médaillon de type** avec son icône.
- **Des rivets** aux coins de l'illustration, et **un ruban** pour le rôle et l'origine, posé à
  cheval sur l'image.
- **Des médaillons de stats** : un écu pour les PV, un losange pour l'ATT.
- **Une gemme** qui marque la variante : pierre mate, topaze, améthyste, couleur du type, opale,
  diamant.
- **Des effets de cadre** : une étincelle qui fait le tour (or), une brume qui dérive (ombre),
  l'effet du type en particules (élémentaire), un chrome irisé et un holo qui balaie
  l'illustration (prismatique), un arc-en-ciel qui tourne (full art).
- **Un dos de carte** commun à toutes : rosace guillochée et étoile à huit branches. On retourne la
  carte d'un tap — c'est aussi le geste de la future révélation au tirage.

### Le premier casting proposé *(à trier par Maxim)*

| Personnage | Origine | Stades | Type proposé | L'arc |
|---|---|---|---|---|
| **Sun Wukong** | Chine — *Voyage vers l'Ouest* | 3 | Nature *(ou Terre)* | singe de pierre → Roi des Singes → Grand Sage égal du Ciel |
| **Thor** | nordique | 3 | Foudre | bambin au marteau trop lourd → guerrier → dieu du tonnerre |
| **Loki** | nordique | 3 | Esprit | gamin farceur → métamorphe → Loki du Ragnarök |
| **Kitsune** | Japon | 3 | Esprit | renard à une queue → trois queues → neuf queues |
| **Bahamut** | mythe arabe | 3 | Eau | alevin → poisson des abysses → poisson-monde qui porte la Terre |
| **Le Dragon du Doudou** | Mons | 3 | Feu | dragonnet → dragon de procession → Dragon du Lumeçon |
| **La Tarasque** | Tarascon | 3 | Eau | bébé tarasque → bête du Rhône → Tarasque de la fête |
| **Nian** | Chine — bête du Nouvel An | 3 | Glace | petit monstre qui a peur du rouge → bête des montagnes → Nian du réveillon |
| **Saint Georges** | Mons | 1 | *aucun des six* | le chevalier du Lumeçon — déjà au sommet |
| **Ifrit** | folklore arabe | 1 | Feu | le djinn de feu |
| **Anansi** | Afrique de l'Ouest (Akan) | 1 | Nature | l'araignée conteuse |
| **Le Korrigan** | Bretagne | 1 | Nature *(ou Terre)* | le lutin des landes |

**Les onze nouveaux** *(illustrés par Maxim le 23/09, pas encore dans le jeu — types et rôles :
propositions de Claude, à trier)* :

| Personnage | Pays | Type proposé | Rôle proposé | Ce que montrent les trois stades |
|---|---|---|---|---|
| **Cerbère** | Grèce | Feu | Garde | chiot des enfers → deux têtes → trois têtes, dans la lave |
| **Le Golem** | Tchéquie | Nature | Garde | petit golem de glaise → colosse → géant au-dessus du pont Charles |
| **Fenrir** | Scandinavie | Glace | Frappeur | louveteau enchaîné → loup → loup géant qui brise ses chaînes |
| **Le Roc** | Arabie | Foudre | Frappeur | oisillon au nid → aigle d'orage → oiseau géant doré |
| **Quetzalcoatl** | Mexique | Foudre | Appui | serpent à plumes → en vol → géant du ciel |
| **Le Kelpie** | Écosse | Eau | Frappeur | cheval d'eau → au galop dans le loch → cabré dans la vague |
| **La Banshee** | Irlande | Eau | Appui | *(trois stades très proches)* |
| **Le Mothman** | États-Unis | Esprit | Appui | petite créature → ailes à demi ouvertes → ailes déployées |
| **Le Chevalier sans tête** | Irlande | Esprit | Frappeur | *(trois stades très proches)* |
| **Baba Yaga** | Russie | Esprit | Appui | *(trois stades très proches)* |
| **Le Wendigo** | Canada | Glace | Frappeur | *(trois stades proches)* |
| *Saint Georges passe à trois stades* | Belgique | *aucun* | Garde | chevalier → au combat → il terrasse le dragon |

⚠️ **Quatre évoluent à peine** d'un stade à l'autre (Baba Yaga, Banshee, Chevalier sans tête,
Wendigo) : en évoluant, le joueur ne verrait presque rien — un stade 1 « mignon » à regénérer ?
⚠️ **Le Wendigo** vient de croyances **vivantes** de peuples autochtones : la même prudence que pour
les divinités de religions vivantes (verrou **e**) ? *À Maxim de trancher.*
📎 *Trois noms de fichier à corriger à l'import (`Banshe2`, `cerbere1`, `Wendingo1`) : Claude
s'en charge.*

📌 *Le Doudou et la Tarasque sont inscrits ENSEMBLE au patrimoine immatériel de l'UNESCO depuis
2005 (« Géants et dragons processionnels de Belgique et de France »). Deux cartes-dragons
cousines : de quoi une synergie un jour.*

---

## ⑦ LE VRAI COIN PUSHER — ça se superpose *(✅ dans le jeu depuis le 25/09)*

> ✅ **Étape 2 livrée le 25/09** (CHANGELOG) : `pusher_screen.gd` réécrit sur la physique de l'essai.
> **L'équilibre mesuré au banc : ~335 pièces**, 70 à 90 % rendus ; plafond 360, machine neuve à 300.
> 📏 *La mesure* : le compteur d'images du téléphone, machine pleine (≥ 55 ?) — **à relire dès le
> premier essai de Maxim**. Si ça ne tient pas : un plateau moins profond (moins de pièces à
> l'équilibre), pas un plafond plus bas (il bloque la machine).
>
> ✅ **24/09 — *« La poussette est géniale comme ça, on prend ça »*** (Maxim). Les objets restent
> au-dessus du tas (revu le 23/09 à 21 h 19, test T3 : 0 objet couvert sur 3). **Étape 2** : la
> machine 3D dans le jeu, puis ses objets deviennent ceux de l'univers (⑭). ⚠️ La ligne « Mesure »
> du téléphone n'a jamais été envoyée : à relire pendant l'étape 2 (il faut ~260 pièces).
>
> **Étape 1, livrée le 23/09 au soir, revue après l'essai de Maxim** : `essais/essai_3d.gd`, servi
> sur https://192.168.0.17:18443/essai/.
> · **Les réglages qui font « vraie machine »** : gravité ×5 · le bloc en bielle (il ralentit en bout
>   de course) · frottement 0,35 entre pièces, plateau poli 0,15, dessus du bloc 0,8 · pièces de
>   12 px d'épaisseur · lâchées d'assez bas pour ne jamais en traverser une.
> · **Testé** (`-- tests`) : pièce lâchée sur une autre **12/12** · glissement sur le bloc **0 px** ·
>   objets enfouis **3/3** · trois minutes de jeu propres · pleine, **elle rend ce qu'on lui donne**.
> · ⚠️ **Il faut ~260 pièces** pour que la machine 3D déborde (2 à 3 couches), contre ~90 en 2D.
>   Sur le PC : **1,05 / 1,63 / 2,22 ms par image à 100 / 150 / 200 pièces**. **Reste le téléphone** :
>   la page se mesure seule à l'ouverture — elle décide de l'étape 2 (et du nombre de pièces).

**Le besoin** *(Maxim, 23/09)* : *« je dois pouvoir la mettre et que les pièces se superposent,
aussi bien sur le poussoir que sur le plateau ; les objets doivent être superposés et tomber en
même temps que les pièces, comme un vrai coin pusher »*.

**La reco de Claude : la physique passe en 3D, le dessin reste le nôtre.** Chaque pièce devient un
disque 3D posé sur de vraies surfaces (le bloc, le plateau, le bord) : **le poids, la gravité et le
frottement font tout ce qu'on imite aujourd'hui à la main** — les pièces s'empilent, le bloc les
porte, le mur les retient, elles basculent au bord quand leur centre le passe. Le dessin actuel est
gardé : une pièce plus haute se dessine un peu plus grande et plus haut, avec son ombre décalée,
penchée quand elle repose sur une autre. **Jolt**, le moteur 3D qui empile bien, est dans le
gabarit web de Godot 4.7 *(vérifié dans le `.wasm` le 23/09)*.
- ❌ *Écarté* : **simuler des étages en 2D** — chaque cas (une pièce sur deux autres, une pile qui
  s'effondre, un lot sous des pièces) deviendrait une règle écrite à la main, et ça se verrait.
- ~~❌ *Écarté* : le rendu en 3D~~ — 🔄 **renversé le 25/09** : les pièces et les objets SONT rendus en
  3D, dans la même perspective oblique (DECISIONS) — plus net, et 30 fois moins cher que le dessin 2D.

🔴 **Le risque : le coût sur le téléphone.** En 3D, une pièce empilée a plus de contacts. Mesuré en
2D : 145 corps = 60 images/s, falaise vers 180. **Inconnu en 3D** → d'abord **un essai mesuré**
(½ session), servi à une adresse à part : 100, 150, 200 pièces, Maxim lit le compteur.
**On ne continue que si ≥ 55 images/s à 150 pièces.** Puis la machine (2 sessions) : dessin,
lâcher qui tombe SUR les autres, lots enfouis, gain au bord, sauvegarde (le tas repart à zéro une
fois), banc adapté.

## ⑧ L'ÉCONOMIE — des pièces qui se méritent *(🗣️ posé par Maxim le 23/09)*

*« Les pièces, faut pas que ça se recharge auto ; y a des missions hebdo et journalières pour avoir
des pièces et des tickets, et le mode histoire aussi en donne ; faut pas que les gens puissent
ouvrir des paquets à l'infini, ça doit être dur d'avoir une invocation ×10 »* ; *« le jeu est
extrêmement simple et rapide, aucun intérêt de payer pour avoir plus de pièces »* (Maxim).
- **Plus de recharge automatique** (aujourd'hui : +1 pièce toutes les 3 s jusqu'à 150).
- **Des missions quotidiennes et hebdomadaires** qui donnent pièces et tickets ; le mode histoire
  aussi.
- ⚠️ **La règle des deux jours** tient si **les missions du jour donnent toujours de quoi jouer** :
  un joueur sans pièce n'attend jamais plus d'une journée.
- 🔗 Emporte ③ (la main limitée) et le plafond `MAX_CORPS`.

> ✅ **Lot A en ligne le 28/09/2026, 16 h 40** : plus de recharge ; les défis du jour et de la semaine (les Présages) ; le
> plateau du jour connu d'avance, la vraie limite. **Les chiffres** (le banc du 28/09) : avant, ~48 étoiles par heure ;
> vider le plateau coûte 123 à 175 pièces nettes ; une journée donne 2 étoiles (le cadeau, le plateau), 4 pierres (le
> plateau, le bonus), ~660 poussières, 205 pièces ; la semaine, +3 étoiles. 🗓️ **Lot B** : ci-dessus, ligne 8.

## ⑨ L'ÉVOLUTION REND PLUS FORT, ET COÛTE PLUS *(🗣️ posé par Maxim le 23/09)*

*« L'évolution sert juste au look, faut améliorer leur compétence quand ils évoluent, faut aussi
augmenter la difficulté de les évoluer »* (Maxim). Aujourd'hui : niveau 3 × stade et **un** éclat ;
un niveau coûte 40 XP × le niveau, sans plafond.
- Chaque stade **renforce l'ultime** (et les chiffres) ; évoluer demande **plus d'éclats et de
  niveaux**.
- ⚠️ **Le verrou c** (« même niveau final, chemin différent ») : un héros à un seul stade doit
  valoir un héros à trois stades une fois au bout — à réconcilier.
- 🔗 Dépend de ② : une compétence ne sert qu'en combat.

## ⑩ LA PAGE DES INVOCATIONS — des portails *(✅ l'Astrolabe, en ligne le 28/09/2026, 22 h 27)*

> ✅ **Livré le 28/09** (CHANGELOG, DECISIONS). **L'état** : l'onglet **Astrolabe** ; on y choisit son **ciel** (le mot
> « portail » ne se dit pas dans le jeu). **Le Grand Ciel** : permanent, les chances de toujours, le premier pack s'y ouvre.
> **Le Ciel du Peintre** : Full art 0,2 % (au lieu de 0,1), toujours un Héros, un Mythe ou une Légende qui ne l'a pas ; la
> **centième invocation sans Full art en donne un d'office** ; refermé pour de bon au premier Full art ; **sa première
> ×10 est offerte** (elle compte dans les 100 ; un ×1 se paie). Le compteur en gros (« FULL ART GARANTI DANS 63 », en or à 10 de la
> fin). **« Mes decks »** en haut de l'Atlas. Au banc : la garantie, c'est ~6 semaines de jeu ; 18 % l'ont avant.
> Le code : `portails.gd` (les règles, l'état dans `GS.voyage["portails"]`), `GS.tirer` / `invoquer_multi` par ciel,
> `astrolabe_ecran.gd` (la page), `collection_screen.gd` (révèle ; `invoquer_dans`, `montrer_probas`).
> 📏 **La mesure** : le 12/10, chez le cousin et sa femme — la ×10 offerte prise ? le compteur ? le Peintre refermé ?
> *Pour plus tard* : **des ciels à thème** (une terre, un type, un héros mis en avant) — il suffit d'une fiche dans
> `Portails.LISTE` ; ils attendent le calendrier des événements (④).

*« Faudra faire une page spéciale pour les invocations, des portails d'invocation différents »*
(Maxim, 23/09). Un portail permanent, et des portails à thème (une terre, un type, un héros mis en avant).
*L'animation du portail existe déjà (23/09, `rituel.gd`) : reste la page et ses portails.*
🔗 Dépend de ⑧ : un portail n'a de sens qu'avec des tickets rares.

## ⑪ LES LANGUES — l'anglais d'abord *(🗣️ posé par Maxim le 23/09)*

*« Préparer le jeu pour l'avoir en plusieurs langues, surtout en anglais »* (Maxim).
- **Tous les textes sortent du code** vers une table (français = la source, anglais à côté) ; les
  noms des héros, des formes et des ultimes aussi.
- Castoro couvre les langues latines ; le chinois ou le japonais demanderaient une autre police.
- 🔴 **Plus tôt c'est fait, moins ça coûte** : chaque écran ajouté ajoute du texte à reprendre.

## ⑫ LE MÉDAILLON DU TYPE *(🗣️ posé par Maxim le 23/09)*

*« Le logo élémentaire sur les cartes ne fit plus avec la DA, faut l'adapter »* (Maxim). Piste de
Claude : le refaire **dans la matière des objets rendus** (une gemme ou une pièce frappée par type,
en relief, comme l'XP, le ticket et l'éclat), **montrée sur le canevas avant d'entrer dans le jeu**.

**24/09** : les pierres élémentaires de ⑭ (une par type) pourraient **donner leur matière au
médaillon** — à dessiner ensemble.

## ⑫ bis LES TYPES DU COMBAT — ajouter la Roche *(🗣️ posé par Maxim le 25/09)*

*« Il faut revoir les éléments pour le mode combat de carte ; en l'occurrence, il faudrait rajouter
Roche en élément, et il y aurait Wukong, le Golem… »* (Maxim). **À faire avec la roue « qui bat
qui » (②)** : la liste des types, qui bat qui, et le type de chaque héros. Candidats à la Roche :
**Sun Wukong** (né d'un rocher), **le Golem**, **le Troll** (troll de pierre), peut-être **le Minotaure**.
Ça touche : `GS.TYPES`, la variante élémentaire (sa couleur), le médaillon (⑫), les pierres (⑭ :
une septième pierre élémentaire).

## ⑬ LE RITUEL DES CONSTELLATIONS *(✅ dans le jeu depuis le 25/09)*

> ✅ **Livré le 25/09** (CHANGELOG). Deux retouches de Maxim par rapport à la ligne D : **pas d'ovale**
> qui relie les constellations, et **les constellations éparpillées sur tout l'écran** (pas en cercle).
> 📏 *La mesure* : Maxim invoque-t-il pour voir le rituel ? Le passe-t-il (toucher) ? À relire après une semaine.

> **La maquette** : https://claude.ai/artifact/PqeP9uQQGBcQs2AdT2nbrF, **ligne D** (Base, Or, Prisma,
> Full art, ×10). Les lignes A, B, C sont les trois propositions du 23/09.

**Le besoin** *(Maxim, 24/09)* : *« la B, pour la prisma et la full art, tous les traits qui se
relient, ça fait n'importe quoi ; la C, je préfère que la carte apparaisse de dos et se retourne ;
l'animation de la B en corrigeant full art et prisma + les constellations qui se rejoignent tout
autour, plus il y a de constellations mieux est le drop (faut penser au multi drop aussi) »*.

**Ce que je compte faire** : réécrire `rituel.gd` sur la ligne D, et y brancher les trois moments
de `collection_screen.gd` (`_ouvrir_portail`, `montrer_revelation`, `montrer_multi`).
· L'**astrolabe** : l'anneau de huit étoiles et le cadran tournent en sens contraires, ralentissent,
  se verrouillent avec un petit clic ; au verrou, l'étoile à huit branches. **Rien d'autre ne se croise.**
· Tout autour, **les constellations** se rejoignent le long d'une ellipse : **Base 2 · Or 3 ·
  Ombre 4 · Élémentaire 5 · Prisma 7 · Full art 9**. Leurs étoiles se posent sur le cadran,
  l'astrolabe se resserre **en l'emblème du dos**, la carte **se retourne**.
· **×10** : une constellation par carte, **de la couleur de sa rareté** ; chacune file vers sa place
  (la grille 3-2-3-2), les cartes se retournent Base d'abord, la plus rare en dernier ; un full
  art vient toujours au centre, en grand.
· Des **étoiles nettes** (branches fines, cœur blanc) et des traits tracés à la plume : **ni halo, ni
  pilier, ni fissure, ni éclair blanc** — tout cela sort du jeu.
· Dans le jeu, plus court que la maquette (qui garde la carte trois secondes et tourne en boucle) ;
  **toucher l'écran passe tout**, comme aujourd'hui.
- ❌ *Écarté* : alléger le portail actuel — *« un peu mort »*, le halo *« horrible »*, les
  fissures *« très moches »* (Maxim, 23/09).
- ❌ *Écarté* : une animation pré-rendue (vidéo, planche d'images) — lourde, floue sur les grands
  écrans, et elle ne varierait pas avec la rareté.

**Fichiers** : `rituel.gd` (réécrit) · `collection_screen.gd` (les trois moments, `_eclat_rare`,
`_banniere`) · `tests/capture_cartes.gd`. **Effort : 1,5 session.** **Migration : non.**
**Ce que ça impacte** — *crash* : faible, c'est du dessin. *Valeur fausse silencieuse* : le tirage
n'est pas touché (il est fait avant, le rituel l'annonce) ; le vrai risque est **d'annoncer une
autre rareté que celle tirée** → une capture par variante, et le test vérifie que le nombre de
constellations suit la meilleure carte. Ne touche pas : taux, tirage, sauvegarde, collection.
**Les tests après** *(téléphone)* : une invocation de chaque variante (appui long sur l'onglet →
Prisma, Full art) · un ×10 · toucher pour passer · fluidité.

## ⑭ LES OBJETS DE L'UNIVERS *(🗣️ posé par Maxim le 24/09)*

> ✅ **Clos le 26/09** *(CHANGELOG : cinq entrées, du 25/09 23 h 58 au 26/09 16 h 09)*. **L'état final** :
> l'étoile d'invocation est une **bille mauve** (la nébuleuse, l'étoile d'or au centre), la poussière
> d'étoile une **bille bleu nuit** (un tourbillon d'or au centre) — de vraies sphères, le voile qui tourne
> comme une planète ; les **sept pierres** (six types + la lune ; la roche dessinée, pas encore dans le
> jeu) sont des volumes taillés, sertis d'or (d'argent pour la lune). Une pièce tombée va dans la
> réserve (+1). L'évolution : **une pierre de son type, sinon de lune** (le coût définitif : ⑱).
> 📏 *La mesure* : Maxim fait-il évoluer ses cartes ? garde-t-il des pierres de lune ? → à relire à ⑱.

> **Le canevas (avec ⑮)** : https://claude.ai/artifact/ScGX7aLFGUqn9g49SQAUJj *(25/09, soir)* — les dix objets
> rendus par `design/objets/render_objets.py --univers` (dans `design/objets/univers/`), le gain qui
> s'envole, la barre à cinq, les trois jeux de noms, les gestes.
>
> 🗣️ **Maxim, 25/09, nuit — validé, avec ces retouches** :
> · **les objets en 3D dans la machine**, même principe que les pièces ; **les pièces ont toujours trop
>   de reflets clairs** → à baisser ; **l'étoile d'invocation en couleurs de galaxie**, avec des petites
>   étoiles dedans (en or sur les pièces en or, on ne la voyait pas) ;
> · **une pièce tombée ne donne plus de poussière** : elle va dans la réserve (+1) ;
> · les noms **Céleste**, la machine s'appelle **Nébuleuse** : Nébuleuse · Astrolabe · Atlas · Voyage · Présages ;
> · **la barre du bas est à retravailler** : *« trop sobre pour un jeu vidéo… il sera sur toutes les pages,
>   on bosse fort là-dessus, fais plusieurs propositions »* ;
> · le cadre « Dernier gain » part ; la réserve est refaite, plus propre ; à sa place, **le plateau du
>   jour** (le nombre de gains restants aujourd'hui) — *« limiter le nombre de gains possibles, mais tu
>   peux acheter des resets, qui te permettent de gagner un plateau de gains en plus »* : on prépare le
>   terrain (compté et affiché ; le blocage, le nombre et l'achat avec ⑱). **Sous la réserve : la place
>   des packs promo**, plus tard ;
> · **des boutons marquants**, de jeu vidéo ; au niveau, **« LVL » en or** (*« c'est international »*) ;
> · **l'évolution refaite** : la pierre plus grosse se pose 2 s sur la carte, vibre, se brise en
>   poussière qui entre dans la carte ; la carte devient blanche, étoiles filantes et constellations en
>   or, puis une éclosion révèle le nouveau stade.
>
> 🗣️ **Maxim, 26/09 (canevas v2)** — **le bandeau : D « Constellations » ; la barre : A « Médaillons »**,
> l'onglet actif un peu plus petit (*« peur que ça encombre les petits écrans »*). **L'étoile d'invocation
> « fait peu »** → une **ceinture d'astéroïdes noire** autour. **Monter de niveau** : *« plus la carte demande
> de poussière d'étoile, plus il y en a qui rentre dans la carte »*. **L'évolution** : *« juste géniale »* ;
> retirer l'étoile qui apparaît au dévoilement, et **le blanc s'évapore en poussière d'or** pour dévoiler la carte.

**Le besoin** *(Maxim)* : *« il faut absolument améliorer les pièces et les objets, quelque chose
en rapport avec notre univers : on ne fait pas des tickets d'invocation mais des étoiles
d'invocation ; pour l'XP, de la poussière d'étoile ; pour upgrader la carte, des pierres — pierre
de lune, pierre de X, pierre de Y — en gros des pierres élémentaires pour évoluer les cartes par
élément, ça pousse le farm plus loin »*.

**La proposition** *(les noms sont à Maxim)* :

| Aujourd'hui | Demain | Sert à |
|---|---|---|
| Ticket d'invocation | **Étoile d'invocation** | invoquer (1 → ×1, 10 → ×10) |
| XP | **Poussière d'étoile** | faire monter le niveau d'une carte (comme l'XP aujourd'hui) |
| Éclat d'évolution | **Six pierres élémentaires**, une par type (feu, foudre, eau, glace, nature, esprit) · **la pierre de lune**, rare, qui remplace n'importe laquelle | faire évoluer une carte : **des pierres de SON type** |

· **Aujourd'hui une évolution coûte UN éclat**, quel que soit le héros — d'où *« le jeu est
  extrêmement simple »*. Avec les pierres, **le coût monte avec le stade** (à fixer avec ⑨) et il
  faut farmer le bon élément. Saint Georges, sans type : pierres de lune.
· **Dans la machine** : les pierres tombent comme lots, chaque type à parts égales, la pierre de
  lune plus rare. Les pièces restent des pièces (le principe du coin pusher), redessinées.
· **Le dessin** : rendus en relief par `design/objets/render_objets.py`, **en 512 px au lieu de
  128** — nets sur le téléphone — et vivants dans le jeu (un reflet qui passe, des scintillements).
  **Montrés sur un canevas avant d'entrer dans le jeu**, avec ⑮.
- ❌ *Écarté* : une seule pierre d'évolution pour tous — c'est l'éclat d'aujourd'hui, sans farm.

> 🗣️ **Maxim, 25/09, soir** : **la Roche est dessinée dès maintenant** (*« on pourrait en avoir
> d'autres »*) — une septième pierre sur le canevas ; elle entre dans le jeu avec la roue des types
> (② / ⑫ bis). **Le coût d'une évolution n'est pas fixé ici** : *« on regarde pas à ça maintenant »*
> → § ⑱. D'ici là, **une pierre de son type** (ou de lune), comme l'éclat aujourd'hui, réglable.

**Migration : oui** — tickets → étoiles (1 pour 1), XP → poussière (1 pour 1), **éclats → pierres
de lune (1 pour 1)** : personne ne perd rien. **Effort** : 1 session de dessin (avec ⑮), 1 de code.
**Ce que ça impacte** — *valeur fausse silencieuse* : la migration de la sauvegarde et les coûts
d'évolution (une carte qui n'évolue plus, ou gratuitement) → tests sur une copie de sauvegarde.
*Crash* : charger une vieille sauvegarde → testé.

## ⑮ L'INTERFACE VIVANTE *(🗣️ posé par Maxim le 24/09)*

> ✅ **Clos le 26/09** *(CHANGELOG)*. **L'état final** : le **bandeau « Constellations »** (étoiles,
> poussière, pierres ; la bourse au toucher) ; la **barre « Médaillons »** — **Nébuleuse · Astrolabe ·
> Atlas · Voyage · Présages**, trois scellés *(tous ouverts depuis le 28/09 : l'Astrolabe, le dernier)* ; **plus de fenêtre « Gagné »** (les objets s'envolent vers
> leur compteur) ; la réserve et son anneau, le **plateau du jour** (compté, pas bloquant : ⑱) ; des
> boutons de jeu vidéo ; **« LVL »** ; l'**évolution en plein écran** ; le bloc **mauve étoilé**.

**Le besoin** *(Maxim)* : *« l'écriture, les logos de l'XP, des tickets, des éclats, tout a l'air
d'être un jpg en 120p collé là, faut le rendre plus vivant, gaming ; pareil pour le menu en bas :
il n'y a que 2 menus mais il y en aura plus, et faut le faire plus beau ; d'ailleurs les noms ne
sont pas fous pour notre univers »*.

**Le constat** : les icônes sont des images de **128 à 192 px affichées jusqu'à 150 px** sur un
écran de 1080 — agrandies, donc floues (`objets/*.png`).

**La proposition** :
· **Le bandeau** : les objets de ⑭, nets et animés ; des chiffres dignes d'un jeu (or, contour
  sombre) ; **un gain file de la machine jusqu'à son compteur**, qui roule jusqu'au nouveau total.
· **La barre du bas, pour cinq** : la machine · les portails (⑩) · la collection · l'aventure
  (② ④) · les quêtes (⑧). L'onglet actif s'allume d'une étoile nette, sans halo.
· **Les noms** : trois jeux de noms dans l'univers, sur le canevas — Maxim choisit.
· **Une animation à chaque geste** *(Maxim, 24/09 : « quand on fait monter de niveau la carte, quand
  on l'évolue, quand on appuie sur un bouton en général — c'est un jeu, pas un site HTML »)* : un
  bouton s'enfonce et rebondit ; monter de niveau fait monter les chiffres et scintiller la carte ;
  évoluer la fait se retourner vers son nouveau stade, dans les étoiles du rituel.
> 🗣️ **Maxim, 25/09, soir** — *« les objets qu'on gagne dans la poussette : plus de pop-up, on les
> voit s'envoler jusqu'au menu en haut pour aller augmenter les stats »*. La machine ne s'arrête
> plus : l'objet tombé s'envole vers son compteur, qui compte jusqu'au nouveau total. Les menus
> pas encore construits sont **visibles mais scellés**. Les trois jeux de noms : d'accord.

**Effort** : le dessin avec ⑭ (1 session), **1,5 session** de code. **Migration : non.**
**Ce que ça impacte** : de l'affichage seulement ; les outils de test (D1) restent sous un appui long.

## ⑯ LES COMPTES, ET L'ACCÈS DES COUSINS *(🗣️ posé par Maxim le 24/09)*

> ✅ **27/09 — l'accès par un CODE, sans comptes, en ligne à 19 h 21** (Maxim : *« il faut juste mettre un code que je
> donnerai à mes cousins… faut bien blinder »*) : `jeu.naspoizot.synology.me`, le portier (`portier/`, INFRA § Le jeu
> PUBLIC). Un code de 5 mots pour tous ; chaque cousin a sa partie dans son navigateur. **Les comptes et la
> sauvegarde partagée (ci-dessous) restent à faire**, quand on voudra des parties qui suivent d'un téléphone à l'autre.

**Le besoin** *(Maxim)* : *« il faudrait que je le mette sur mon NAS et que j'ouvre l'accès à mes
cousins, ils veulent jouer ; faut aussi gérer les comptes ; on a déjà fait le sign in with Google
dans l'autre projet »* (familyos : bouton Google natif → `POST /auth/google` → le serveur vérifie
le jeton, crée ou lie le compte, rend un JWT).

> 🔄 **Revu le 25/09** : Maxim n'a pas de domaine chez Cloudflare, mais **son NAS est déjà ouvert** :
> `naspoizot.synology.me`, port 443 ouvert sur la box, et **les sous-domaines répondent**
> (`jeu.naspoizot.synology.me` → le NAS, vérifié). **La nouvelle reco** : une règle du reverse
> proxy du NAS (DSM) `jeu.naspoizot.synology.me` → le jeu, un certificat Let's Encrypt pour le
> sous-domaine (fait par DSM), et **oauth2-proxy** (un conteneur) qui met la connexion Google devant
> tout le jeu — seuls les e-mails invités entrent — et transmet l'e-mail au service de sauvegarde.
> Le secret du client Google vit dans le `.env` du NAS, hors du dépôt. *Alternative* : le bouton
> Google dans le jeu, comme familyos — plus de code, et le jeu lui-même resterait public.

**La reco du 24/09 (remplacée) : Cloudflare devant le NAS, et un petit service de sauvegarde.**
· **Un tunnel Cloudflare** (`cloudflared`, un conteneur sur le NAS) : **aucun port ouvert** sur la
  box, **un vrai certificat** (plus d'avertissement), une adresse du genre `jeu.<domaine>`.
· **Cloudflare Access** met **une connexion Google devant le jeu** : seuls les e-mails invités
  entrent (gratuit jusqu'à 50 personnes). **Aucun code de connexion dans le jeu, aucun secret dans
  le dépôt.**
· **Un service de sauvegarde** (un petit conteneur, SQLite) : le jeu reprend sa sauvegarde au
  démarrage et l'envoie à chaque enregistrement, rangée sous l'e-mail que Cloudflare certifie. **Un
  numéro de version refuse qu'une vieille sauvegarde écrase une plus récente** (deux téléphones).
- ❌ *Écarté* : **la méthode de familyos** (bouton Google dans le jeu, `/auth/google`, JWT) — plus
  de code pour le même résultat, et il faudrait quand même ouvrir le NAS. Elle servira pour l'app
  du Play Store (connexion native).
- ❌ *Écarté* : **ouvrir un port sur la box** — le NAS directement sur internet.
- ❌ *Écarté* : **Tailscale** — chaque cousin installe une app de VPN.

**Avant d'ouvrir** : les outils de test (D1, D4) disparaissent, ou restent réservés à l'e-mail de
Maxim ; l'économie est encore « open bar » (⑧ pas fait) — à savoir.
**La part de Maxim** : un domaine géré par Cloudflare (ou un sous-domaine d'un domaine qu'il a),
un compte Cloudflare Zero Trust (gratuit), les adresses Gmail des cousins.
**Secrets** : le jeton du tunnel, seul, dans le `.env` du NAS, hors du dépôt. **Légal** : on garde
l'e-mail et la sauvegarde de chaque cousin, rien d'autre ; effacés sur demande.
**Effort** : ½ session avec Maxim (tunnel et Access), 1 session (service, synchro du jeu, migration
de sa sauvegarde). **Migration : oui** — la sauvegarde locale de Maxim monte au premier lancement.
**Ce que ça impacte** — *crash* : si le service ne répond pas, **le jeu démarre quand même** sur la
sauvegarde locale. *Valeur fausse silencieuse* : deux téléphones qui s'écrasent (la version) ; une
sauvegarde vide qui écraserait une pleine (jamais : on ne remplace qu'une sauvegarde plus ancienne).
**Les tests après** : en 4G (pas en Wi-Fi) — le lien s'ouvre, connexion Google, un e-mail non invité
est refusé, on joue, un autre téléphone retrouve la même partie.

## ⑱ LE JEU LUI-MÊME : LE GAMEPLAY, SA DIFFICULTÉ, OÙ ON VA *(🗣️ posé par Maxim le 25/09)*

> 🎬 **LE LOT EN COURS.** Le combat est tranché (le Carré des astres) ; son étape 1 est dans le jeu depuis le
> 27/09 (ligne 2). L'état détaillé est dans START_HERE § LE LOT EN COURS ; les réglages provisoires à
> trancher, dans START_HERE § LES DETTES (D11).

**Le besoin** *(Maxim)* : *« on fait une session pour discuter du jeu lui-même ; là on a seulement
fait l'aspect collection de cartes, mais faut surtout penser au gameplay, à sa difficulté et vers
quoi on veut aller »*. **Une session de discussion, pas de code**, juste après ⑭ + ⑮.

**Ce qu'elle tranche** : à quoi servent les cartes (le combat ②, le mode histoire ④) · la boucle
d'une journée de jeu · la difficulté et sa courbe · l'économie (⑧ : ce que coûte une invocation,
**une évolution** — reporté ici depuis ⑭ —, ce que rapporte la machine) · la direction à six mois.
**Ce que Claude apporte** : les points ouverts de ②, ④, ⑧, ⑨, les chiffres d'aujourd'hui (ce que
rapporte une minute de machine), deux ou trois directions comparées.

---

# 💡 LE VIVIER — idées non triées

> Une ligne chacune. **Elles ne sautent pas la file.**

- **Le tourniquet** : la même figurine générée sous 5-6 angles, on glisse le doigt pour la faire
  tourner. **80 % de la sensation 3D, zéro pipeline 3D.** *(Recommandé quand on y reviendra.)*
- Vrai 3D *(Meshy, Tripo, Rodin)* — payant par modèle, et le rig de 50 unités est hors de portée.
- Les douze archétypes d'unités *(Lesté, Cumulard, En-Équilibre, Doublon, Pile-ou-Face,
  Rembourseur, Grippe-sou, Renverseur, Contagieux, Dernier, Coinceur, Passeur)* — à reprendre
  quand on écrira les cartes. **On en garderait 6 à 8 pour la v1, pas douze.**
- L'écosystème à l'équilibre *(peupler un terrarium, une saison se déroule seule)* — écarté sur
  la lisibilité. 🔓 Se rouvre si La Poussée s'avère trop convenue à l'usage.
- Le profil public avec vitrine de cartes — dépend du backend.

---

# ⛔ ÉCARTÉ — pour ne pas re-discuter ce qui est tranché

| Quoi | Quand | Pourquoi | 🔓 Condition de réouverture |
|---|---|---|---|
| **Le dégagement** *(gratter une gangue)* | 20/09/2026 | Testé sur téléphone : mort dans la main. Aucune des quatre propriétés d'un bon mini-jeu | Aucune |
| **Le plinko** | 20/09/2026 | Le choix du joueur y est une illusion : la trajectoire est randomisée dès le 3ᵉ rebond | Aucune |
| **Deux poussoirs / deux étages** | 21/09/2026 | Trop compliqué, et les jetons se téléportaient visuellement | Aucune |
| **Tower defense sur voies** | 20/09/2026 | C'est le jeu de Clash of Critters. On serait comparé point par point, et on perdrait | Aucune |
| **PvP temps réel** | 20/09/2026 | Double la taille du projet + un coût d'exploitation permanent | Une communauté qui le réclame **et** un revenu qui le paie |
| **Vendre de la puissance** | 20/09/2026 | Casse la règle des 2 jours et assèche le PvP de ses spectateurs | Aucune |
| **Les raretés de puissance** *(commune / rare / légendaire)* | 22/09/2026 | *« Pas 40 raretés, toutes les cartes sont au même niveau »* (Maxim). Seules les variantes sont rares | Aucune |
| **Le halo, le pilier, les fissures et l'éclair des invocations** | 24/09/2026 | *« Le halo de lumière est horrible et la fissure des cartes est très moche »* (Maxim) | Aucune |
| **Les rituels A (une constellation par héros) et C seule (la carte qui se remplit)** | 24/09/2026 | Maxim a choisi l'astrolabe entouré de constellations (§ ⑬) | Aucune |
| **La Poussée, les combats « TCG » et « stratégie avant le combat »** | 26/09/2026 | 27 démos jouées : La Poussée incomprise ; *« je veux un jeu rapide, pas tout planifier pendant des heures »*. Le Carré des astres est retenu | Le Carré qui ne tient pas après une semaine de jeu |
| **Le détourage automatique** | 21/09/2026 | 5 tentatives, 5 échecs. À régler par le prompt, pas par du code | Si une bibliothèque dédiée devient disponible |
