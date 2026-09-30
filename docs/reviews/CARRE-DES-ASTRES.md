# ✦ LE CARRÉ DES ASTRES — le potentiel du mode, et ce qu'il change à nos cartes

> **Écrit le 26/09/2026, lot ⑱.** Maxim, après avoir testé toutes les démos : *« aucun [des 11 concepts
> stratégie] ne me plaît, je veux un jeu rapide… Le Carré des astres, j'ai fait pas mal de parties, j'ai
> vraiment accroché, rapide, fun et stratégique. Il me rappelle le Queen's Blood… Je pense que là on
> tient la base. Mais il faut l'améliorer, le rendre plus complet, avec plus de features et d'events,
> peut-être 4 sur 4 ou 5 ? »*
>
> **Rien n'est décidé ici** : c'est l'analyse et une recommandation. Maxim tranche.

---

## 1. Ce qu'est le Carré aujourd'hui (la démo, `design/canevas/arene/src/d1_carre.js`)

- Une grille de 3×3. Chaque joueur a **5 cartes, visibles des deux côtés**. On pose à tour de rôle.
- Chaque carte a **un chiffre par côté** (haut, droite, bas, gauche). Poser une carte contre une carte
  adverse : si **mon chiffre du côté qui la touche est plus grand**, elle passe à ma couleur.
- **Les retournements s'enchaînent** : une carte retournée attaque à son tour ses voisines. C'est notre
  ajout par rapport à Triple Triad (le jeu de cartes de Final Fantasy VIII).
- **2 cases de terre** donnent +1 à tous les chiffres d'une carte de ce type.
- On gagne avec **le plus de cartes à sa couleur** (en comptant la carte restée en main).
- Les chiffres viennent du rôle (frappeur 9-6-4-3, garde 6-6-6-5, appui 8-5-5-4, sbire 5-4-3-2), tournés
  d'un héros à l'autre. **Les héros n'ont encore aucune identité propre dans ce mode.**

## 2. Pourquoi ça accroche

1. **Une minute par partie.** On relance sans y penser.
2. **Zéro hasard pendant la partie.** Tout est visible ; si je perds, je vois le coup qui m'a perdu.
3. **Un seul geste** : poser une carte. Aucune règle à lire, le tuto tient en 3 bulles.
4. **Les retournements en chaîne** : un coup peut tout renverser. C'est là que naît le « waouh ».
5. **Le calcul est court mais réel** : où poser pour ne pas offrir un côté faible.

## 3. Queen's Blood, Triple Triad et nous

*Queen's Blood est dans Final Fantasy VII **Rebirth** (2024), le 2ᵉ épisode, pas dans Remake.*

| | **Triple Triad** (FF8) | **Queen's Blood** (FF7 Rebirth) | **Le Carré** (aujourd'hui) |
|---|---|---|---|
| Plateau | 3×3 | 3 lignes × 5 colonnes | 3×3 |
| Où poser | n'importe où | **seulement sur ses cases**, qu'on étend en posant | n'importe où |
| Une carte | 4 chiffres | un **rang** (son coût), une **puissance**, un **motif** de cases touchées, une **capacité** | 4 chiffres |
| Gagner | le plus de cartes | **ligne par ligne** : la plus grosse puissance gagne la ligne, on additionne | le plus de cartes |
| Deck | 5 cartes | **15 cartes, main de 5, on pioche** | 5 cartes |
| Hasard | règle « aléatoire » en option | la pioche | aucun |
| Durée | 1 min | 5 à 10 min | 1 min |
| Autour | des règles régionales, des cartes à gagner | des adversaires dans tout le monde, des défis, un tournoi, une histoire | rien encore |

**Ce qui rend Queen's Blood « monstrueux »** (et ce qu'on peut en prendre) :
- **Le territoire.** On ne pose pas n'importe où : chaque carte étend son terrain, et les grosses cartes
  demandent un terrain déjà fort. Chaque coup prépare le suivant. → **À prendre, en plus simple.**
- **Les capacités qui se répondent** (« quand un allié est posé… », « quand cette carte est détruite… »).
  Ce sont elles qui font le deckbuilding. → **À prendre : un pouvoir par héros.**
- **Le deck à construire.** 15 cartes, des synergies, des « decks » qu'on invente. → **À prendre, en
  plus petit.**
- **Le score par ligne** : trois petits combats dans un grand. → **Pas pour la v1** : il changerait la
  lecture du plateau. On le garde pour une règle d'événement.
- **Tout ce qu'il y a autour** : des adversaires avec leur style, des défis-énigmes, un tournoi, des
  cartes qu'on gagne en battant quelqu'un. → **À prendre : c'est notre Voyage.**

**Ce qu'on ne prend pas** : la pioche (du hasard), les 5 à 10 minutes (Maxim veut du rapide), les petits
motifs de cases sur la carte (illisibles sur un téléphone).

## 4. La taille du plateau

| | 3×3 | **4×4** | 5×5 |
|---|---|---|---|
| Cases | 9 | 16 | 25 |
| Cartes posées par joueur | 5 et 4 | **8 et 8** : même nombre, plus besoin de compter la main | 13 et 12 |
| Durée d'une partie | 1 min | **2 à 3 min** | 5 min et plus |
| Taille d'une case sur un téléphone | ~100 px | **~80 px : les 4 chiffres restent lisibles** | ~62 px : chiffres minuscules |
| Profondeur | faible, vite « résolu » | **bonne : des coins, des bords, un centre** | forte, mais on se perd |
| L'ordinateur calcule | tout, instantanément | bien, en regardant 2 coups plus loin | lentement |

**Reco : le 4×4 devient le mode principal.** Le 3×3 reste pour le tuto, les parties éclair et les
énigmes du jour. Le 5×5 peut servir à un **boss** ponctuel (le plateau du dragon), pas au quotidien.

⚠️ **À mesurer** : sur 16 cases, le 2ᵉ joueur pose la dernière carte, ce qui pourrait l'avantager. On le
mesure au banc, puis on compense si besoin (le 1ᵉʳ joueur place une terre, par exemple).

## 5. Ce qu'on ajoute — en trois couches, une à la fois

### Couche 1 — le cœur (la v1 à prototyper)
- **Le 4×4**, les mains visibles, les chaînes, les terres.
- **Un deck de 10 cartes, on en pose 8.** Pas de pioche : on voit toute sa main, et celle de l'adversaire.
  Les 2 cartes qu'on garde sont aussi un choix.
- **Un pouvoir par héros** (voir § 6) : une phrase, un moment (à la pose, quand il retourne, quand il est
  retourné, tant qu'il est posé). C'est ce qui rend chaque carte unique.
- **L'avantage de type** (la roue de ⑫ bis) : +1 au côté qui touche une carte que mon type bat. Les types
  deviennent enfin utiles en combat. *À tester : ça peut aussi alourdir la lecture.*

### Couche 2 — le plateau vivant (les « events »)
- **Des cases spéciales**, posées par l'étape ou par l'événement :
  - la **terre** (+1 au type) ;
  - l'**autel** (+1 point à qui tient la case à la fin) ;
  - la **brume** (la carte y reste face cachée jusqu'à la fin) ;
  - le **gouffre** (case interdite) ;
  - le **miroir** (sur cette case, le plus petit chiffre gagne) ;
  - la **source** (une carte posée là ne peut plus être retournée).
- **Des règles de partie**, comme les règles régionales de Triple Triad :
  - **Même** : deux côtés égaux retournent ;
  - **Plus** : deux sommes égales retournent ;
  - **Inversion** : le plus petit gagne ;
  - **Mort subite** : en cas d'égalité, on rejoue avec les cartes gagnées ;
  - **Main cachée** ;
  - **Par lignes** : le score façon Queen's Blood.
- **La carte Terre** (l'idée de Maxim des cartes Zone) : une par deck. Avant la partie, on la pose sur une
  case, qui devient une terre de son type. Le Valhalla donne +1 à la Foudre et à la Glace.

### Couche 3 — ce qu'il y a autour (le méta)
- **Le Voyage** : un chapitre par terre de légendes. Les adversaires ont leur style et leurs règles ; le
  boss a son plateau spécial. **Battre un héros pour la première fois donne sa carte** : on affronte une
  légende avant de l'avoir.
- **Les énigmes** (façon défis de Queen's Blood) : main et plateau imposés, « retourne 6 cartes en un
  coup ». Aucune image à produire, du contenu à l'infini.
- **Le tournoi de la semaine** : 4 adversaires de suite, avec la règle de la semaine.
- **Le PvP asynchrone, tour par tour** : on joue son coup, l'autre reçoit une notification, jusqu'à 8
  coups chacun (comme Wordfeud). **Un jeu de grille est fait pour ça.** Pas besoin qu'une IA joue le deck
  de l'autre.
- **Le Bastion** (l'idée Clash of Critters de « préparer ses lignes pour défendre ») : en PvP, tu
  prépares une défense (2 ou 3 cartes déjà posées, une case spéciale), et les autres viennent la prendre.
  C'est le « setup » que tu cherchais, greffé sur le Carré.

## 6. Des pouvoirs de héros — exemples

Une règle pour tous : **une phrase, un déclencheur, un effet qu'on voit sur le plateau.**

| Héros | Pouvoir |
|---|---|
| **Thor** | À la pose : +2 au côté qui touche une carte adverse. |
| **Kitsune** | À la pose : échange sa place avec une de tes cartes voisines. |
| **Golem** | Ne peut pas être retourné au tour qui suit sa pose. |
| **Bahamut** | Tant qu'il est posé : tes cartes voisines +1. |
| **Yéti** | À la pose : gèle une carte voisine (elle ne retourne rien et n'est pas retournée pendant un tour). |
| **Loki** | À la pose : copie les chiffres de la carte voisine la plus forte. |
| **Anubis** | Quand il est retourné : il reprend aussitôt une carte adverse voisine. |
| **Fenrir** | Chaque carte qu'il retourne en chaîne : +1 à ses chiffres. |
| **Baba Yaga** | À la pose : −1 à tous les chiffres d'une carte adverse voisine. |
| **Minotaure** | À la pose : repousse une carte adverse voisine d'une case. |
| **Wukong** | Ses retournements sautent une case vide. |
| **Cerbère** | Retourne aussi en diagonale. |
| **El Biète** | Tant qu'il est posé : tes cartes voisines ne peuvent pas être retournées par la chaîne. |
| **Quetzalcoatl** | À la pose : les cases vides voisines deviennent des terres de son type. |

## 7. Ce que ça change à nos cartes

- **Ce qui disparaît du combat** : les PV, l'ATT, le rôle et l'ultime, qui servaient à La Poussée. Ils
  sont remplacés par **les 4 chiffres + le pouvoir**.
- **Ce qui ne bouge pas** : les illustrations, les stades, le type, le pays, les variantes (qui restent
  de la pure prestance), et la collection.
- **Le rôle devient la forme des chiffres** : un frappeur a un très gros côté, un garde est équilibré, un
  appui a un pouvoir fort et des chiffres moyens.
- **Le dessin de la carte (⑤) est à revoir** : les 4 chiffres sur les bords, lisibles à 64 px, et le
  pouvoir en une ligne. Les médaillons PV/ATT partent.
- **Les sbires** deviennent les cartes communes : des chiffres bas, mais un coût faible (voir § 8).
  Ils bouchent un trou du deck.

## 8. L'XP, les niveaux, l'évolution — et le PvP juste

Le risque d'un jeu à chiffres : **la carte évoluée écrase tout**, et le PvP devient une course à la
puissance, ce qu'on a écarté le 20/09. La réponse que je propose tient en trois règles.

1. **L'évolution renforce, et coûte au deck.** Chaque carte a un **poids** qui vaut son stade (I = 1,
   II = 2, III = 3 ; un sbire = 1), et **un deck pèse 18 au plus**. Faut-il un héros au stade III, ou deux au
   stade II ? C'est un vrai choix. Et ça respecte le verrou c : « même niveau final, chemin différent ».
2. **L'évolution donne +3 à la somme des chiffres et renforce le pouvoir** (le Yéti III gèle deux cartes).
   Le coût reste celui d'aujourd'hui, en pierres de son type.
3. **Les niveaux (la poussière) ne donnent pas de puissance brute : ils donnent la forme.** Tous les 3
   niveaux, +1 point à placer **sur le côté de ton choix**, jusqu'au plafond du stade (somme max : I = 22,
   II = 25, III = 28). Ton Thor n'est pas celui de ton cousin. C'est l'identité et l'attachement, pas 15 %
   de stats en plus.

En PvP classé, les plafonds bornent tout. En PvE, on peut assouplir.

## 9. Les risques

- **Triple Triad est « résolu »** : sur 3×3, les bons joueurs savent quoi faire. Le 4×4, les pouvoirs et
  les cases spéciales repoussent ce plafond.
- **L'ordinateur doit bien jouer** : sur 4×4 avec 8 cartes, il regarde 2 coups plus loin. Ça tient dans le
  navigateur comme dans Godot ; à mesurer.
- **La lisibilité** : 4 chiffres, un pouvoir et un type sur une carte de 64 px. C'est le point à montrer
  au canevas avant tout.
- **Les pouvoirs à équilibrer** : un par héros, 31 héros. On les teste au banc (des parties simulées),
  comme pour les 11 concepts.
- **La propriété intellectuelle** : les mécaniques sont libres. On n'emprunte ni les noms, ni l'interface.
  Notre signature : **une chaîne de retournements trace une constellation d'or sur le plateau.**

## 10. La recommandation

1. **Le Carré des astres devient le combat du jeu.** ① passe de « version A » à **« le Carré »**, et La
   Poussée, ②, ③ sont écartées (à noter dans DECISIONS).
2. **La v1 à prototyper** (dans l'Arène) : 4×4, deck de 10 (8 posés), mains visibles, chaînes, terres,
   **un pouvoir pour 10 héros**, l'avantage de type en option, le poids du deck. Avec un interrupteur
   **3×3 / 4×4** pour comparer sur le téléphone.
3. **Puis** : les cases spéciales et les règles (couche 2), puis le Voyage et les énigmes (couche 3),
   puis le PvP tour par tour et le Bastion.
