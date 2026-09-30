# 🃏 ANALYSE — les jeux de cartes, ce que les joueurs veulent, et huit façons de se battre

> **Écrit le 26/09/2026 pour le lot ⑱** (le jeu lui-même). Maxim, après deux démos incomprises :
> *« analyse ce qui se fait dans tous les jeux TCG, analyse la demande des joueurs, définis un style
> qui rentre avec ce qu'on cherche et qui soit addictif ; fais-moi toutes les démos, je tranche après »*.
> **Les démos** : https://claude.ai/artifact/2VwvtbPRojqsHKTvwjE3Ny · la source : `design/canevas/arene/`
> (`python build.py` refait la page à partir de `src/`).

## 1. Ce que le marché montre

| Le jeu | Le chiffre | La leçon |
|---|---|---|
| **Pokémon TCG Pocket** (2024) | ~1,3 Md$ la 1re année, 150 M de téléchargements, 18 Md de paquets ouverts | **La collection se suffit** : ouvrir, montrer (490 M de vitrines partagées). Les combats sont simples et courts. |
| Pocket, la critique | pile ou face des cartes, désavantage de jouer en premier, paquets moins généreux | **Le hasard APRÈS la décision rend fou.** Et l'économie serrée use la confiance. |
| **Marvel Snap** (2022) | 3 min, 6 tours, 3 lieux ; −75 % de revenus en 2025 | Le format court et intense marche ; **la monétisation poussée fait fuir**. |
| **Balatro** (2024) | 5 M de ventes, n°1 payant sur mobile | Des combinaisons et des **nombres qui explosent** : « encore une partie ». |
| **Legends of Runeterra** | son mode PvE roguelike (Path of Champions) a porté le jeu | Les joueurs de cartes veulent **du solo qui progresse**, pas que du PvP. |
| **Hearthstone Battlegrounds** | devenu un pilier du jeu | Un mode **auto-battler** (on recrute, ça se bat seul) attire plus large que le jeu de cartes classique. |

Sources : [Pocket 1re année](https://gonintendo.com/contents/54418-pokemon-tcg-pocket-reaches-1-3-billion-in-revenue-2-billion-battles-and-490-million) ·
[Pocket 1,6 Md$](https://www.pocketgamer.biz/pokemon-tcg-pocket-makes-16bn-in-15-years/) ·
[le pile ou face de Pocket](https://www.thegamer.com/pokemon-tcg-pocket-coin-flip-problem/) ·
[les paquets de Pocket](https://www.sportskeeda.com/pokemon/pokemon-tcg-pocket-players-discuss-issues-current-state-pack-points) ·
[Snap et sa monétisation](https://www.gamemakers.com/p/why-marvel-snap-players-hated-their) ·
[Balatro sur mobile](https://www.gamesradar.com/games/roguelike/balatro-creator-in-disbelief-as-the-roguelike-hit-tops-mobile-sales-charts-beating-minecraft-and-stardew-valley-despite-one-pesky-issue/) ·
[Path of Champions](https://massivelyop.com/2022/06/09/riot-says-legends-of-runeterras-pivot-from-pve-to-pvp-is-about-scope-and-studio-balance-not-underperformance/) ·
[Battlegrounds](https://hearthstone.fandom.com/wiki/Battlegrounds)

## 2. Ce que les joueurs demandent — les règles qu'on en tire

1. **Court** : une partie en 1 à 3 minutes.
2. 🔴 **Pas de hasard après la décision.** Le hasard *avant* (on voit sa main, puis on choisit) est
   accepté et même aimé (Balatro, Slay the Spire). Le hasard *après* (pile ou face) est détesté.
   Et c'est exactement la frustration de Maxim sur Pokémon.
3. 🆕 **Le tirage en miroir** pour le PvP : les deux joueurs reçoivent les mêmes tirages (la même
   graine). Le hasard existe, mais il ne départage personne. *Personne ne le fait en grand sur mobile.*
4. **Lisible sans lire** : un seul nombre dit qui gagne, et chaque effet se voit (cause → effet).
5. **Un solo qui progresse**, avec beaucoup de stages générés.
6. **Des grands moments** : la chaîne de retournements, le score qui explose, la remontée.
7. **Une économie généreuse** : c'est ce qui a coûté le plus cher à Snap et à Pocket.
8. **Aucune carte inutile** : la rareté dit la fréquence de tirage, pas la force (tranché le 26/09).

## 3. Les huit démos

Chaque démo **s'apprend en jouant** : une première partie guidée, où une main montre quoi toucher
(mémoire `maxim-joue-sans-lire`). Tout est à l'essai : les chiffres sont posés à l'œil, et la roue des
types est provisoire (⑫ bis).

| | Le style | Ce qu'on fait | Ce qu'il invente | Hasard | Stages et PvP | Effort dans Godot |
|---|---|---|---|---|---|---|
| **1** | **Le Carré des astres** (grille, type *Triple Triad*) | poser une carte à côté des siennes ; le plus grand chiffre la retourne | **les retournements en chaîne** ; des cases de terre (+1 à un type) | aucun | stages : ses 5 cartes + les cases ; PvP : parfait | 2-3 sessions |
| **2** | **Le Palet des légendes** (adresse) | tirer un héros-palet au doigt vers 3 cercles, cogner les siens | **un jeu de cartes d'adresse** : le geste du pouce (doctrine « le geste avant le thème ») | aucun, c'est l'adresse | stages : cercles et obstacles ; PvP : lancers alternés | 3-4 sessions |
| **3** | **Les Constellations** (type *Balatro*) | choisir jusqu'à 4 cartes qui forment une combinaison (même type, trio de rôles, même terre), le score frappe le boss | **le folklore devient la combinaison** (« Voyage vers le Nord ») ; des astres qui modifient les coups ; le tirage en miroir | avant la décision, en miroir | stages : le PV du boss, gratuit ; PvP : course au score, même tirage | 3-4 sessions |
| **4** | **Le Duel des ombres** (bluff) | une carte chacun en secret, on retourne, la plus forte marque ; 3 points | tout est visible sauf le choix ; **doubler la mise** une fois | aucun | stages : ses mains ; PvP : parfait | 1-2 sessions |
| **5** | **La Poussée en rythme** (timing) | tes héros se battent seuls, tu touches au bon moment pour frapper et parer | **la Poussée gardée, avec l'adresse du pouce** | aucun | stages : équipes paramétrées ; PvP : moins naturel | 2-3 sessions |
| **6** | **La Caravane** (auto-battler) | recruter un héros parmi 3, ranger l'équipe, la regarder se battre ; 5 victoires | **la collection devient la réserve de recrues** ; doublon = niveau | dans les offres, avant la décision | stages : la course ; PvP : les équipes enregistrées des autres, natif | 3-4 sessions |
| **7** | **Le Siège** (puzzle, type *Slay the Spire*) | le boss annonce son coup, tu réponds avec les gestes de tes 3 héros | **pas de pioche** : les gestes des héros sont les cartes | aucun | stages : le motif du boss, idéal pour les boss ; PvP : faible | 3-4 sessions |
| **8** | **Les Trois Terres** (type *Marvel Snap*, refait avec son tuto) | poser en secret sur 3 terres, tout se retourne, 2 terres gagnent | **pas de pioche** ; les cartes Zone de Maxim au cœur du jeu | aucun | stages : terres + deck ; PvP : parfait | 4-5 sessions |

**La mesure** : les compteurs de chaque tuile (parties, victoires), et surtout **celle que Maxim relance
sans y penser**.

## 4. Les idées non démontrées

- **La Nébuleuse de combat** (un coin pusher à deux, où les héros tombent chez l'autre) : la physique
  du tas est chaotique, donc c'est du hasard après la décision. L'idée du geste est reprise par le Palet.
- **Le défi du jour** : le même stage pour tout le monde, avec un classement. C'est un ingrédient, qui
  s'ajoute à n'importe lequel des huit.
- **La mise** (façon *Snap*) : un ingrédient, testé dans le Duel.
- **Un mode d'un autre style** : Hearthstone a son Battlegrounds. Le jeu peut avoir un cœur et un
  mode à côté, plus tard.

## 5. L'avis de Claude, à relire après les parties de Maxim

**Les Constellations**, et **le Palet** en second.

- **Les Constellations** : la boucle la plus addictive qui existe aujourd'hui (Balatro). Chaque héros
  compte par son type, sa terre et son rôle, donc la collection a enfin un usage. Les stages coûtent zéro
  contenu. Le PvP se fait en miroir, sans adversaire à programmer. Et c'est le moins cher à tenir seul.
- **Le Palet** : le plus original, et le seul qui prolonge la Nébuleuse (le pouce, la physique).
  Personne ne fait ça.

⛔ Rien n'est tranché : c'est Maxim qui choisit, après avoir joué.
