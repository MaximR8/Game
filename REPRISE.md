# 🔁 À REPRENDRE — avec ton compte Claude perso *(écrit le 01/10/2026, au soir)*

> ✅ **Repris le 02/10 avec le compte perso** : Maxim a généré sept décors (`Machine/`) ; l'essai de la machine dedans est au
> CHANGELOG (🧪 02/10) et sur le canevas *Les décors de la machine*. Ce fichier reste pour mémoire (les prompts, les traces).

> **Pourquoi ce fichier.** Le soir du 01/10, la session tournait sur le **compte Claude du travail** (par erreur). Maxim ne
> veut **aucune trace de La Poussette sur ce compte** : le canevas publié là a été supprimé (par Maxim), et la suite se fera
> avec son compte perso. Tout ce qu'il faut pour reprendre est ici et dans le dépôt.
>
> **Pour reprendre** : dans Claude Code, `/logout` puis `/login` avec le compte perso → « Lis START_HERE et REPRISE.md ».

---

## 1. Les traces sur le compte du travail — vérifié le 01/10, 21 h 55

- **Les artifacts** du compte (« les miens » et « partagés ») : il ne reste que des documents de travail de Maxim, rien de La
  Poussette. Le canevas « Machine Base céleste » et ses 9 fichiers (7 images, le film, son affiche) sont partis avec lui.
- **Aucun document Claude Docs** créé ; aucun autre artifact publié depuis le changement de compte.
- **Le projet et la mémoire** : l'adresse du compte du travail n'est écrite nulle part. Les commits portent
  `Maxim Poizot <maxim.poizot@gmail.com>` (le dernier : `58de9e3`).
- ⚠️ **Ce qui ne s'efface pas d'ici** :
  - la consommation de cette session (et deux recherches web, deux lectures de pages : la décision d'Anvers, les principes
    européens des monnaies de jeu) est comptée sur le compte du travail ; selon l'offre, l'organisation peut voir des
    statistiques d'usage de Claude Code par personne ;
  - si la session apparaît dans claude.ai (Code, sessions) sur le compte du travail, la supprimer là.

---

## 2. Où on en est

1. **Les décisions du 01/10** (`docs/reviews/DECISIONS.md`, l'entrée du 01/10 et la doctrine), **toutes confirmées** :
   - « On ne vend ni la chance ni la victoire » ;
   - la monnaie payante s'appelle **les Comètes** et n'achète que du connu (le pass de 3 mois, les styles, les thèmes de
     machine, le cosmétique) : jamais de cartes, ni de pièces, ni d'étoiles ;
   - jamais de pièces vendues, nulle part ;
   - ~150 cartes au lancement, puis des **styles** (un style = **un stade III alternatif** ; une animation propre à chaque
     carte spéciale) ;
   - les étapes de progression d'un joueur gratuit (semaine 1, mois 1, mois 3, 6-9 mois) ;
   - l'ordre (START_HERE ⓪bis) : la Nouvelle machine → la série de 7 jours → la machine cosmique → les Trésors → …
2. **Le prototype** (commit `58de9e3`, rien dans le jeu) :
   - la machine en perspective dans un meuble 3D construit en volumes simples (`proto_degagement/meuble/`, la scène
     `tests/capture_meuble.tscn`) ;
   - le tapis céleste du Carré, rendu par la fabrique (`design/objets/render_carre.py --celeste`,
     `tests/capture_tapis.tscn`). Détails : CHANGELOG, l'entrée 🧪 du 01/10.
3. **Le verdict de Maxim sur la machine** (01/10, au soir) :
   > *« Ça fait vieille 3D. Regarde l'image que je t'ai envoyée : c'est plus travaillé, l'écran est bien rempli. Peut-être qu'il
   > faut mettre un décor fixe derrière, mais bien HD, propre, et rajouter des petites animations dessus, un peu comme les
   > cartes. »*

   La référence : `design/references/machine/base-celeste-recadree.png` (sa maquette, recadrée). Les cinq machines de
   ChatGPT : `maquette-5-machines-chatgpt.png`. Les styles de Wukong : `styles-wukong-chatgpt.png`.
   - **La perspective** (le long plateau) n'a pas été rejetée : la critique porte sur le meuble.
   - **Le tapis céleste** : pas encore commenté.

---

## 3. La suite pour la machine (la direction de Maxim)

- **Un décor fixe, HD, peint**, qui remplit l'écran. Maxim le génère dans ChatGPT avec les prompts ci-dessous, en joignant sa
  maquette comme référence de style.
- **Le plateau reste le vrai** : la physique, les pièces et les objets du jeu, en 3D. On cale la caméra du jeu sur le
  plateau **peint** (et non l'inverse), puis le plateau 3D se pose dans le creux du décor.
- **Les petites animations, par-dessus**, comme sur les cartes :
  - des étoiles nettes qui scintillent, les flammes qui vacillent, un reflet qui glisse sur l'or ;
  - les 9 lunes de la jauge, dans les alvéoles de l'arche (les nôtres : `meuble/lune.gdshader`) ;
  - l'astrolabe en calques qui tournent, si Maxim génère les trois calques ;
  - la Supernova : les rayons, le flash, les anneaux qui s'emballent puis se verrouillent, les lunes qui battent.
- **Les règles qui restent** : ni les pièces ni les objets recolorés ; pas de halo flou ; pas de titre.
- **La netteté** : ChatGPT sort au plus 1024 × 1536. Pour un rendu net sur un écran de 1080 de large, prévoir un
  agrandissement ×2 (un upscaler, par exemple Real-ESRGAN), à essayer à la reprise.
- **Le format** : une image en 2:3 couvre l'écran du jeu de son bord haut jusqu'à ~1 620 px (sur 2 400), c'est-à-dire
  derrière le bandeau, toute la machine et le panneau Réserve.
- **À mesurer sur le téléphone** (D13).

---

## 4. Les prompts pour ChatGPT (à coller tels quels ; joindre la maquette « Base céleste » en référence)

### Prompt 1 — le décor (l'image principale)

```
Using the attached image as a style reference (the "Base céleste" machine), create the background art for a mobile game coin pusher machine. Portrait format 2:3 (1024×1536), highest quality.

The machine fills the whole image edge to edge, with no empty background around it. Perfectly symmetrical. Front view, seen slightly from above (camera about 35° down), so the coin tray looks long and deep in perspective.

From top to bottom:
- Top 10%: a calm dark night sky with a few small crisp stars (a game interface will sit on top: keep it simple and dark).
- A grand golden arch with fine engraved filigree and a row of small gold beads along both edges. Along the arch, nine small EMPTY round sockets with gold rims and dark navy insides, evenly spaced.
- Inside the arch: a deep navy starry sky with a subtle nebula and two thin gold constellation lines. In its center, a large golden astrolabe: concentric rings with fine engraved tick marks and an eight-pointed gold compass star on a navy enamel disk.
- Left and right: two navy-blue enamel columns with gold rings, each topped by a golden armillary sphere with a small bright star at its core, and a small candle with a warm flame on each capital.
- Under the arch: the back shelf of the pusher (a sliding block with a mauve starry top and a gold front edge).
- Bottom half: the coin tray, completely EMPTY (no coins, no objects): a dark polished navy floor with faint tiny stars, framed by gold rails on both sides, receding toward the arch.
- Bottom 15%: the front of the cabinet, an ornate navy and gold base panel, calm and not busy (a game panel will sit on top).

Style: high-end mobile game art, clean, crisp, HD, rich gold and deep navy, warm gold highlights and cool blue shadows, only small sharp four-pointed sparkles. No blurry glow, no haze, no bloom, no cracks, no rainbow light beams, no Japanese motifs, no medieval parchment look. No coins, no text, no letters, no logo, no UI.
```

### Prompt 2 — si des pièces apparaissent dans le plateau (à envoyer à la suite, dans la même conversation)

```
Same image, change nothing else: remove every coin and object from the tray, keep the tray empty with its dark starry floor.
```

### Prompt 3 — pour faire des essais (à la suite)

```
Keep exactly the same composition, framing and perspective. Only change: [ce que tu veux changer].
```

### Prompts 4 à 6 — l'astrolabe en trois calques (facultatif : pour que ses anneaux tournent et se verrouillent)

```
Same style as the previous image. Square 1024×1024, transparent background. Only the outer ring of the astrolabe: an ornate golden ring with fine engraved tick marks every 5 degrees (longer every 30 degrees). Perfectly front-facing and centered, flat (no perspective). Nothing else. Crisp, HD, no glow, no text.
```

```
Same style, same size, same center, transparent background. Only the middle ring: a thinner golden ring with eight small gold beads evenly spaced and a thin gold bar across its diameter. Nothing else.
```

```
Same style, same size, same center, transparent background. Only the center piece: a navy enamel disk with an eight-pointed gold compass star in relief (four long points, four short ones). Nothing else.
```

**Conseils** : en générer plusieurs et garder la meilleure ; rester dans la même conversation (pour que le style tienne) ;
télécharger en PNG pleine taille ; les déposer dans `design/references/machine/` pour la reprise.

---

## 5. Refaire les captures du prototype (si besoin)

```
./Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_meuble.tscn -- <dossier> [avant] [cam=x,y,z,vx,vy,vz,fov]
./Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 --write-movie <dossier>/machine.avi --fixed-fps 30 res://tests/capture_meuble.tscn -- <dossier> film
python design/objets/render_carre.py --celeste
./Godot_v4.7.2-stable_win64_console.exe --path ./proto_degagement --rendering-driver opengl3_angle --resolution 720x1600 --position -3000,0 res://tests/capture_tapis.tscn -- <dossier>
```

(Le film : ffmpeg d'imageio_ffmpeg, `crop=1080:1785:0:0,scale=720:1190`, en H.264 — docs/ops/INFRA.md.)

---

## 6. Pas encore envoyé sur GitHub

Ce fichier, les trois images de `design/references/machine/`, et deux phrases corrigées dans CHANGELOG et START_HERE (le
canevas retiré). À committer à la reprise.
