// ═════════════════════════════ 1 · LE CARRÉ DES ASTRES ═════════════════════════════
// Une grille 3×3. Chaque carte a un chiffre par côté. Pose une carte à côté d'une des siennes :
// si ton chiffre est plus grand, sa carte devient à toi — et elle attaque à son tour ses voisines.
(function () {
  const COTES = ["h", "d", "b", "g"];            // haut, droite, bas, gauche
  const OPP = { h: 2, d: 3, b: 0, g: 1 };        // le côté d'en face, en indice
  const MODELES = { frappeur: [9, 6, 4, 3], garde: [6, 6, 6, 5], appui: [8, 5, 5, 4], sbire: [5, 4, 3, 2] };
  function chiffres(id) {
    const rng = rngDe(hacher("carre-" + id)), f = FICHES[id];
    const t = [...(MODELES[f.role] || MODELES.appui)];
    const rot = Math.floor(rng() * 4);
    const r = t.map((_, i) => t[(i + rot) % 4]);
    const a = Math.floor(rng() * 4), b = (a + 1 + Math.floor(rng() * 3)) % 4;
    if (r[a] < 9 && r[b] > 2) { r[a]++; r[b]--; }
    return r;
  }
  function voisins(i) {
    const l = Math.floor(i / 3), c = i % 3, v = [];
    if (l > 0) v.push([i - 3, 0]); if (c < 2) v.push([i + 1, 1]); if (l < 2) v.push([i + 3, 2]); if (c > 0) v.push([i - 1, 3]);
    return v; // [voisin, mon côté]
  }
  function effectifs(st, id, i) { const b = st.terres[i] && st.terres[i] === typeDe(id) ? 1 : 0; return chiffres(id).map(x => Math.min(10, x + b)); }
  function poser(st, camp, id, i) {
    st.cases[i] = { id, camp, ch: effectifs(st, id, i), bonus: st.terres[i] === typeDe(id) };
    const retours = [], file = [i];
    while (file.length) {
      const k = file.shift(), c = st.cases[k];
      for (const [n, s] of voisins(k)) {
        const v = st.cases[n];
        if (!v || v.camp === c.camp) continue;
        if (c.ch[s] > v.ch[OPP[COTES[s]]]) { v.camp = c.camp; retours.push({ de: k, vers: n, a: c.ch[s], b: v.ch[OPP[COTES[s]]], chaine: k !== i }); file.push(n); }
      }
    }
    return retours;
  }
  const compte = (st, camp) => st.cases.filter(c => c && c.camp === camp).length + st.main[camp].length;
  const cloner = st => ({ terres: st.terres, cases: st.cases.map(c => c && { ...c }), main: { j: [...st.main.j], a: [...st.main.a] } });
  function coupIA(st, rng) {
    let best = null;
    const libres = st.cases.map((c, i) => c ? -1 : i).filter(i => i >= 0);
    for (const id of new Set(st.main.a)) for (const i of libres) {
      const s = cloner(st); s.main.a.splice(s.main.a.indexOf(id), 1); poser(s, "a", id, i);
      let pire = compte(s, "a") - compte(s, "j");
      const libres2 = libres.filter(x => x !== i);
      for (const id2 of new Set(s.main.j)) for (const i2 of libres2) {
        const s2 = cloner(s); s2.main.j.splice(s2.main.j.indexOf(id2), 1); poser(s2, "j", id2, i2);
        pire = Math.min(pire, compte(s2, "a") - compte(s2, "j"));
      }
      const v = pire + rng() * 0.6;
      if (!best || v > best.v) best = { v, id, i };
    }
    return best;
  }

  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9);
    const tuto = Jeu.tuto;
    let mainJ, mainA, terres = {};
    if (tuto) {
      mainJ = ["thor", "yeti", "ifrit", "kitsune", "bahamut"]; mainA = ["draugr", "oni", "fenrir", "cerbere", "anansi"];
      terres = { 8: "feu" };
    } else {
      const pool = melanger([...HEROS_TYPES.map(x => x.id)], rng);
      mainJ = pool.slice(0, 5); mainA = pool.slice(5, 9).concat([SBIRES[Math.floor(rng() * SBIRES.length)].id]);
      melanger(mainA, rng);
      const cs = melanger([0, 1, 2, 3, 4, 5, 6, 7, 8], rng);
      const ty = melanger(Object.keys(ADV), rng);
      terres[cs[0]] = ty[0]; terres[cs[1]] = ty[1];
    }
    const st = { cases: Array(9).fill(null), main: { j: mainJ, a: mainA }, terres };
    const premier = tuto ? "a" : (statsDe("carre").p % 2 ? "a" : "j");
    let tour = premier, sel = null, occupe = false;

    const zoneA = h("div", "cr-main cr-a"), plateau = h("div", "cr-plateau"), zoneJ = h("div", "cr-main cr-j");
    ctx.scene.append(zoneA, plateau, zoneJ);

    function elCarte(id, camp, o = {}) {
      const e = vignette(id, { nom: o.nom !== false });
      e.classList.add("cr-carte");
      if (camp) e.classList.add("c" + camp);
      const ch = o.ch || chiffres(id);
      COTES.forEach((s, k) => { const n = h("span", "cr-n cr-" + s, ch[k] === 10 ? "A" : ch[k]); if (o.bonus) n.classList.add("plus"); e.append(n); });
      return e;
    }
    function rendre(anim = {}) {
      ctx.scoreJA(compte(st, "j"), compte(st, "a"));
      zoneA.innerHTML = "";
      st.main.a.forEach(id => zoneA.append(elCarte(id, null, { nom: false })));
      plateau.innerHTML = "";
      st.cases.forEach((c, i) => {
        const cell = h("button", "cr-case"); cell.dataset.i = i;
        if (c) {
          const e = elCarte(c.id, c.camp, { ch: c.ch, bonus: c.bonus, nom: false });
          if (anim.pose === i) e.classList.add("cr-pose");
          if (anim.retour === i) e.classList.add("retourne");
          cell.append(e);
        } else {
          if (st.terres[i]) {
            const t = TYPES[st.terres[i]]; cell.classList.add("cr-terre"); cell.style.setProperty("--t", t.c);
            cell.innerHTML = etoile("", 8, 0.3); cell.append(h("span", "", `${t.nom} +1`));
          }
          if (sel && tour === "j") cell.classList.add("cr-libre");
          cell.onclick = () => jouerJ(i);
        }
        plateau.append(cell);
      });
      zoneJ.innerHTML = "";
      st.main.j.forEach(id => {
        const e = elCarte(id, null); e.dataset.id = id;
        if (sel === id) e.classList.add("choisie");
        e.onclick = () => { if (tour !== "j" || occupe) return; sel = sel === id ? null : id; rendre(); if (sel) ctx.consigne("Touche une case vide"); else ctx.consigne("À toi : touche une carte"); };
        zoneJ.append(e);
      });
    }
    async function jouer(camp, id, i) {
      occupe = true;
      st.main[camp].splice(st.main[camp].indexOf(id), 1);
      const retours = poser(st, camp, id, i);
      // on remet les cartes retournées à leur ancien camp, pour les montrer basculer une à une
      for (const r of retours) st.cases[r.vers].camp = autre(camp);
      rendre({ pose: i });
      await dodo(420); if (!ctx.vivant()) return;
      for (const r of retours) {
        const A = plateau.children[r.de].getBoundingClientRect(), B = plateau.children[r.vers].getBoundingClientRect();
        flotXY((A.left + A.right + B.left + B.right) / 4, (A.top + A.bottom + B.top + B.bottom) / 4, `${r.a} › ${r.b}`, "or");
        await dodo(260); if (!ctx.vivant()) return;
        st.cases[r.vers].camp = camp;
        rendre({ retour: r.vers });
        if (r.chaine) flotSur(plateau.children[r.vers], "en chaîne !", "mot", 0.1);
        await dodo(380); if (!ctx.vivant()) return;
      }
      occupe = false;
      return retours;
    }
    async function jouerJ(i) {
      if (!sel || tour !== "j" || occupe || st.cases[i]) return;
      const id = sel; sel = null;
      const r = await jouer("j", id, i);
      if (!ctx.vivant()) return;
      apres(r);
    }
    async function tourIA(force) {
      tour = "a"; ctx.consigne("Il réfléchit…", "lui"); rendre();
      await dodo(700); if (!ctx.vivant()) return;
      const c = force || coupIA(st, rng);
      await jouer("a", c.id, c.i);
      if (!ctx.vivant()) return;
      apres();
    }
    let finie = false;
    async function apres(r) {
      if (st.cases.every(Boolean)) return terminer();
      if (tour === "j") { if (!tuto || tutoFini) tourIA(); else if (r) suiteTuto(r); }
      else { tour = "j"; ctx.consigne("À toi : touche une carte"); rendre(); }
    }
    function terminer() {
      if (finie) return; finie = true;
      const j = compte(st, "j"), a = compte(st, "a");
      rendre(); ctx.consigne(j > a ? "Gagné !" : j < a ? "Perdu" : "Égalité", j >= a ? "" : "lui");
      setTimeout(() => ctx.fin({ titre: j > a ? "Victoire" : j < a ? "Défaite" : "Égalité", texte: `${j} cartes à ta couleur, ${a} à la sienne.`, gagne: j > a }), 900);
    }

    // ——— le tuto : Jeu.tuto est vrai tant qu'on ne l'a pas fini une fois ———
    let tutoFini = !tuto;
    async function suiteTuto(r) {
      const f = r && r[0];
      if (f) await ctx.etape({ texte: `Ton ${f.a} bat son ${f.b} : sa carte est à toi !` });
      await ctx.etape({ texte: "À la fin, le plus de cartes gagne." });
      const iTerre = Object.keys(st.terres).map(Number).find(i => !st.cases[i]);
      if (iTerre != null) await ctx.etape({ cible: () => plateau.children[iTerre], texte: `Case ${TYPES[st.terres[iTerre]].nom} : +1 à tes cartes ${TYPES[st.terres[iTerre]].nom}.`, doigt: false });
      tutoFini = true; ctx.tutoFini();
      if (ctx.vivant()) tourIA();
    }
    rendre();
    if (tuto) {
      (async () => {
        ctx.consigne("Bienvenue");
        await ctx.etape({ texte: "Pose tes cartes. Retourne les siennes." });
        if (!ctx.vivant()) return;
        await tourIA({ id: "draugr", i: 4 });
        if (!ctx.vivant()) return;
        const ch = chiffres("thor"), s = ch.indexOf(Math.max(...ch));
        const iThor = [7, 3, 1, 5][s];
        await ctx.etape({ cible: () => zoneJ.querySelector('[data-id="thor"]'), texte: "Touche Thor" });
        if (!ctx.vivant()) return;
        if (sel !== "thor") { sel = "thor"; rendre(); }
        await ctx.etape({ cible: () => plateau.children[iThor], texte: "Pose-le ici, à côté de sa carte" });
        // jouerJ(iThor) est lancé par le toucher ; s'il a passé le tuto, on reprend la partie normale
        if (Guide.saute) { tutoFini = true; ctx.tutoFini(); if (!st.cases[iThor] && sel) { /* il joue lui-même */ } }
      })();
    } else if (premier === "a") tourIA();
    else ctx.consigne("À toi : touche une carte");
  }

  enregistrer({ id: "carre", num: "1", nom: "Le Carré des astres", accroche: "Pose tes cartes, retourne les siennes. Aucun hasard.", duree: "1 min", images: ["thor", "yeti", "kitsune"], fond: "linear-gradient(160deg,#2a2150,#171229)", lancer });
})();
