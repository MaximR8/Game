# 🎨 LES HÉROS — gabarit de génération et fiches

> **Ce fichier répond à une question : comment générer un héros pour qu'il ressemble au reste.**
> Claude écrit la structure et les prompts ; Maxim génère les images.
>
> 🔴 **On valide la méthode sur UN héros (le pilote) avant d'écrire les onze autres.** C'est ce qui
> a marché pour les six figurines du 21/09 : un gabarit rigide, testé une fois, puis réutilisé.

---

> 🔄 **23/09/2026 — Maxim a changé de style.** Les héros sont générés en **illustrations
> peintes** (décor complet, rubans rouges en fil conducteur), pas en figurines photographiées :
> 25 images, 11 héros, dans `Cartes/Illustration/` — **puis 36 de plus le 23/09** : onze nouveaux
> personnages et les trois stades de Saint Georges, **dans le jeu depuis le 23/09 à 21 h 24** (tableau
> en bas). **Le gabarit
> « figurine » ci-dessous n'a pas servi.** Si le style peint est confirmé, on le réécrit à partir de ces images, pour que la
> Tarasque et les héros suivants leur ressemblent.
>
> 📐 **Le cadrage** : la carte normale ne montre que 68 % de la hauteur d'une image en 4:5, et dans
> ces peintures la tête est haut (10 à 20 %). Chaque image a donc son cadrage dans la maquette
> (`cadrage`, dans la liste des héros). Pour les prochaines : **garder de l'air au-dessus de la
> tête** — elle ne doit pas toucher les 10 % du haut.
>
> 🖼️ **Le full art est une illustration à part** *(décidé le 23/09)* : plus spectaculaire, dans un
> autre style, et pas pour tous les héros. Son gabarit reste à écrire.

## Les règles qui ne bougent pas

- **La matière monte avec le stade** *(verrou d, validé le 22/09)* : vinyle au stade 1, résine
  peinte au stade 2, statue de collection au stade 3. **Toujours un objet photographié** — c'est ce
  qui garde la direction artistique cohérente du mignon au badass.
- **Une seule illustration par stade.** Les six variantes (or, ombre, prismatique…) sont du code :
  **ne jamais générer une image « version dorée »**.
- **Le mythe est libre, l'iconographie des œuvres ne l'est pas.** Pas de design *Final Fantasy*,
  *Marvel*, *Donjons & Dragons*. Voir `docs/reviews/DECISIONS.md` § limites.
- ⚠️ **Le filigrane en étoile** de ton générateur actuel est ajouté par l'outil, pas par le prompt :
  aucune formulation ne l'enlèvera. À régler côté outil.

---

## Le gabarit — à coller en entier, à chaque fois

⚠️ **Il dépend de la proposition (f)** *(générer au format carte, avec décor)*, **pas encore
validée**. Si Maxim préfère le fond neutre, remplacer la ligne `{DÉCOR}` par
`neutral warm-grey seamless backdrop` et `vertical 5:7` par `square`. **Le pilote sert aussi à
trancher (f)** : si le décor plaît, elle est validée. ❌ *(f) écartée le 23/09 : le full art sera
une illustration à part.*

**① Le socle commun — identique pour tous les héros et tous les stades :**

```
collectible figure photographed as a premium product shot, standing on a small sculpted
diorama base, {DÉCOR}, soft diffused key light from upper left, subtle rim light, shallow
depth of field, vertical 5:7 card composition, figure centred in the middle of the frame
with empty space above its head, full figure visible with the whole base, the diorama floor
filling the bottom third, desaturated muted palette with a single accent colour,
adult collector aesthetic, no text, no logo, no frame, no border
```

> 📐 **Pourquoi « au milieu »** : la carte normale ne montre que la bande du milieu de l'image
> (≈ 20 % → 80 % de la hauteur), et le full art cache le haut sous le nom, le bas sous l'ultime.
> La figurine doit vivre dans cette bande ; le décor, lui, peut déborder. *(Corrigé le 22/09 : on
> demandait « les deux tiers du haut », ce qui aurait coupé les têtes.)*

**② La matière — selon le stade :**

| Stade | Registre | À ajouter |
|---|---|---|
| **1** | mignon | `soft matte vinyl art toy, chibi proportions with an oversized head, half-lidded ambiguous expression, never smiling, visible mould seam line` |
| **2** | sérieux | `hand-painted resin figure, balanced proportions, serious focused expression, fine brushed paint details, slight wear on the edges` |
| **3** | badass | `premium polystone collector statue, heroic proportions, dynamic powerful pose, intense expression, highly detailed sculpt, metallic and patina accents` |

**③ Le sujet — propre à chaque héros et à chaque stade** *(voir les fiches)*.

**Ordre d'assemblage :** `③ le sujet` + `②  la matière` + `① le socle commun`, en remplaçant
`{DÉCOR}` par le décor du héros.

---

## 🧪 LE PILOTE — El Biète, le dragon du Doudou *(Mons, 3 stades)*

> **Son nom en jeu : El Biète** — le nom montois du dragon, donné par Maxim le 23/09/2026.
> Le Lumeçon a d'autres personnages, si on veut d'autres héros un jour.

> ⚠️ **C'est ton folklore, pas le mien.** Les détails ci-dessous (la queue à crins, la place pavée)
> sont ce que j'en sais. **Corrige-les avant de générer** — un détail faux sur le Doudou, un
> Montois le verra tout de suite.

**Le décor, commun aux trois stades :**
`miniature cobblestone old-town square at festival time, scattered confetti`

**Stade 1 — Dragonnet** *(mignon, vinyle)*
```
a baby dragon from the folk procession of Mons in Belgium, round plump body, tiny stubby
wings, short snout, a long tail ending in a tuft of horsehair,
soft matte vinyl art toy, chibi proportions with an oversized head, half-lidded ambiguous
expression, never smiling, visible mould seam line,
collectible figure photographed as a premium product shot, standing on a small sculpted
diorama base, miniature cobblestone old-town square at festival time, scattered confetti,
soft diffused key light from upper left, subtle rim light, shallow depth of field, vertical
5:7 card composition, figure centred in the middle of the frame with empty space above its
head, full figure visible with the whole base, the diorama floor filling the bottom third,
desaturated muted palette with a single accent colour, adult collector
aesthetic, no text, no logo, no frame, no border
```

**Stade 2 — Dragon de procession** *(sérieux, résine peinte)*
```
a young processional dragon effigy come alive, elongated body, scales painted like a
festival float, folded wings, a long tail ending in a tuft of horsehair,
hand-painted resin figure, balanced proportions, serious focused expression, fine brushed
paint details, slight wear on the edges,
collectible figure photographed as a premium product shot, standing on a small sculpted
diorama base, miniature cobblestone old-town square at festival time, scattered confetti,
soft diffused key light from upper left, subtle rim light, shallow depth of field, vertical
5:7 card composition, figure centred in the middle of the frame with empty space above its
head, full figure visible with the whole base, the diorama floor filling the bottom third,
desaturated muted palette with a single accent colour, adult collector
aesthetic, no text, no logo, no frame, no border
```

**Stade 3 — Dragon du Lumeçon** *(badass, statue)*
```
the great dragon of the Lumeçon combat, massive body rearing up, open jaws, wings spread,
a long whipping tail ending in a flowing tuft of horsehair, festival ribbons caught on its
scales,
premium polystone collector statue, heroic proportions, dynamic powerful pose, intense
expression, highly detailed sculpt, metallic and patina accents,
collectible figure photographed as a premium product shot, standing on a small sculpted
diorama base, miniature cobblestone old-town square at festival time, scattered confetti,
soft diffused key light from upper left, subtle rim light, shallow depth of field, vertical
5:7 card composition, figure centred in the middle of the frame with empty space above its
head, full figure visible with the whole base, the diorama floor filling the bottom third,
desaturated muted palette with a single accent colour, adult collector
aesthetic, no text, no logo, no frame, no border
```

**Où sont les images** : `Cartes/Illustration/`, un fichier par stade (`Thor1.png`, `Thor2.png`…,
`Korrigan.png` pour un héros à un seul stade). Claude les monte dans la maquette des cartes.

### Ce qu'on vérifie sur les trois images du pilote

- [ ] **On reconnaît le MÊME dragon** aux trois stades — la couleur, la queue, la tête
- [ ] **La matière monte** : vinyle mat → résine peinte → statue. On le voit sans lire la légende
- [ ] **L'arc mignon → sérieux → badass** tient
- [ ] **Le format 5:7** : la figurine est au milieu, de l'air au-dessus de la tête, le socle entier
  est visible
- [ ] **Le recadrage de la carte normale** garde la figurine lisible *(je le vérifie à l'intégration)*
- [ ] **La même lumière et la même palette** que les six figurines du 21/09

**Si les trois cases du haut passent, le gabarit est bon** et on écrit les onze autres héros.

---

## Les onze autres — à écrire après validation du pilote

| Personnage | Origine | Stades |
|---|---|---|
| Sun Wukong | Chine — *Voyage vers l'Ouest* | 3 |
| Thor | nordique | 3 |
| Loki | nordique | 3 |
| Kitsune | Japon | 3 |
| Bahamut *(le poisson du mythe, pas le dragon de D&D)* | mythe arabe | 3 |
| La Tarasque | Tarascon | 3 |
| Nian | Chine | 3 |
| Saint Georges | Mons | 1 |
| Ifrit | folklore arabe | 1 |
| Anansi | Afrique de l'Ouest (Akan) | 1 |
| Le Korrigan | Bretagne | 1 |

**Total pour les douze : 28 illustrations** (8 héros × 3 stades + 4 × 1), **plus une par full art**
— le full art est une illustration à part, et pas pour tous les héros *(décidé le 23/09)*.

---

## Les onze du 23/09 — dans le jeu *(types, rôles, formes, ultimes et chiffres : propositions de Claude)*

> Les illustrations de Maxim, `Cartes/Illustration/<Nom>1..3.png` → `proto_degagement/cartes/<id>-1..3.jpg`.
> ⚠️ **Tout ce tableau se corrige librement** : il est dans `game_state.gd` § `HEROS`.

| Héros | Type | Rôle | Pays | Les trois stades | Ultime | PV / ATT |
|---|---|---|---|---|---|---|
| **Cerbère** | feu | Garde | Grèce | Chiot des Enfers · Molosse à deux têtes · Gardien des Enfers | *Nul ne passe* — gagne le double d'armure à chaque coup encaissé | 115 / 12 |
| **Golem** | nature | Garde | Tchéquie | Petit golem d'argile · Golem de Prague · Colosse du pont Charles | *Le nom sacré* — revient une fois à la vie, avec la moitié de ses PV | 125 / 8 |
| **Fenrir** | glace | Frappeur | Scandinavie | Louveteau enchaîné · Loup des neiges · Fenrir déchaîné | *Gleipnir brisé* — chaque ennemi tombé ajoute 5 à son ATT | 62 / 24 |
| **Roc** | foudre | Frappeur | Arabie | Oisillon du Roc · Aigle d'orage · Roc des tempêtes | *Serres du ciel* — emporte l'ennemi de devant au bout de sa colonne | 60 / 25 |
| **Quetzalcoatl** | foudre | Appui | Mexique | Serpenteau à plumes · Serpent des nuées · Serpent du soleil levant | *Souffle du vent* — soigne toute sa colonne de 8 PV à chaque manche | 66 / 10 |
| **Kelpie** | eau | Frappeur | Écosse | Poulain du loch · Cheval des brumes · Kelpie des tempêtes | *Crinière d'algues* — l'ennemi qu'il frappe ne peut plus être soigné | 60 / 23 |
| **Banshee** | eau | Appui | Irlande | Pleureuse des falaises · Dame blanche · Messagère du trépas | *Le cri* — à sa première action, l'ennemi le plus faible perd 20 PV | 58 / 14 |
| **Mothman** | esprit | Appui | États-Unis | Petite phalène · Homme-phalène · Présage aux yeux rouges | *Présage* — ses alliés esquivent le premier coup du combat | 62 / 12 |
| **Chevalier sans tête** | esprit | Frappeur | Irlande | Cavalier des brumes · Dullahan · Chevalier sans tête | *Chevauchée funeste* — frappe en premier au premier tour, où qu'il soit | 64 / 23 |
| **Baba Yaga** | esprit | Appui | Russie | Vieille de la forêt · Sorcière au mortier · Dame de l'isba | *Malédiction* — les coups de l'ennemi de devant font 30 % de moins | 60 / 12 |
| **Wendigo** | glace | Frappeur | Canada | Rôdeur des neiges · Wendigo affamé · Wendigo de l'hiver | *Faim sans fin* — se soigne de la moitié des dégâts qu'il inflige | 62 / 22 |

**Saint Georges** passe à trois stades : Chevalier du Lumeçon · Saint Georges en armes · Vainqueur du Dragon.

## Les neuf du 25/09 — dans le jeu *(propositions de Claude, à corriger dans `game_state.gd` § `HEROS`)*

| Héros | Type | Rôle | Pays | Les trois stades | Ultime | PV / ATT |
|---|---|---|---|---|---|---|
| **Minotaure** | feu | Frappeur | Grèce | Veau du labyrinthe · Minotaure · Seigneur du Labyrinthe | *Charge du labyrinthe* — frappe deux fois l'ennemi de devant au premier tour | 70 / 22 |
| **Cuélebre** | eau | Garde | Espagne | Serpenteau des grottes · Cuélebre ailé · Gardien des trésors | *Écailles d'airain* — les deux premiers coups reçus ne font rien | 110 / 11 |
| **Oiseau-Tonnerre** | foudre | Frappeur | Amérique du Nord | Oisillon d'orage · Oiseau-Tonnerre · Seigneur des tempêtes | *Coup de tonnerre* — frappe toute la colonne ennemie pour la moitié de son ATT | 60 / 24 |
| **Anubis** | esprit | Appui | Égypte | Chacal des sables · Gardien des tombeaux · Peseur des âmes | *La pesée des âmes* — un allié tombé revient avec 30 % de ses PV | 64 / 12 |
| **Yéti** | glace | Garde | Népal | Petit yéti · Yéti des cimes · Colosse de l'Himalaya | *Avalanche* — l'ennemi de devant passe son prochain tour | 120 / 10 |
| **Chupacabra** | nature | Frappeur | Mexique | Chiot épineux · Chupacabra · Chupacabra affamé | *Épines dorsales* — renvoie 25 % des dégâts reçus | 60 / 23 |
| **Tikbalang** | nature | Appui | Philippines | Poulain des bambous · Tikbalang · Seigneur des sentiers | *Égarement* — une fois, l'ennemi de devant frappe un de ses alliés | 62 / 13 |
| **Bunyip** | eau | Garde | Australie | Petit bunyip · Bunyip des marais · Bunyip des billabongs | *Cri du marais* — les ennemis perdent 10 % de leur ATT | 112 / 11 |
| **Troll** | nature | Garde | Norvège | Trollet des bois · Troll des montagnes · Troll de pierre | *Peau de pierre* — moitié moins de dégâts tant qu'il a plus de la moitié de ses PV | 130 / 9 |

⚠️ *Le Troll, le Golem et Sun Wukong sont candidats au futur type **Roche** (FEATURES § ⑫ bis).*
