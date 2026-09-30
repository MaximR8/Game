// ═════════════════════════════ 8 · LES TROIS TERRES ═════════════════════════════
// Trois terres, six tours. Ton énergie = le numéro du tour. Vous posez vos cartes en même temps,
// face cachée, puis tout se retourne. 2 terres sur 3 gagnent. Pas de pioche : ta main est ton deck.
(function () {
  const C = {
    draugr: { cout: 1, force: 2, txt: "Pas d'effet." },
    farfadet: { cout: 1, force: 1, txt: "Tes autres cartes ici : +1." },
    anansi: { cout: 1, force: 1, txt: "+4 s'il a posé une carte ici ce tour." },
    loki: { cout: 2, force: 1, txt: "Prend la force de sa carte la plus forte ici." },
    kitsune: { cout: 3, force: 4, txt: "+3 si tu as moins de cartes que lui ici." },
    wukong: { cout: 4, force: 5, txt: "En arrivant : +1 à toutes tes autres cartes." },
    thor: { cout: 5, force: 7, txt: "En arrivant : −1 à chacune de ses cartes ici." },
    ifrit: { cout: 6, force: 12, txt: "Tes autres cartes ici : −1." },
    oni: { cout: 2, force: 3, txt: "Pas d'effet." },
    banshee: { cout: 2, force: 2, txt: "En arrivant : −2 à sa carte la plus forte ici." },
    cerbere: { cout: 3, force: 3, txt: "+4 s'il est ta seule carte ici." },
    golem: { cout: 3, force: 4, txt: "Aucun malus ne l'atteint." },
    yeti: { cout: 4, force: 4, txt: "En arrivant : plus personne ne pose ici." },
    georges: { cout: 4, force: 3, txt: "En arrivant : détruit sa carte la plus forte ici, si elle a 6 ou plus." },
    bahamut: { cout: 6, force: 7, txt: "Tes autres cartes ici : +2." },
  };
  const DECKS = [["draugr", "farfadet", "anansi", "loki", "kitsune", "wukong", "thor", "ifrit"], ["draugr", "oni", "banshee", "cerbere", "golem", "yeti", "georges", "bahamut"]];
  const ZONES = [
    { id: "valhalla", nom: "Valhalla", txt: "Foudre et Glace +2", types: ["foudre", "glace"] },
    { id: "enfers", nom: "Les Enfers", txt: "Feu +2", types: ["feu"] },
    { id: "broceliande", nom: "Brocéliande", txt: "Nature +2", types: ["nature"] },
    { id: "loch", nom: "Le Loch", txt: "Eau +2", types: ["eau"] },
    { id: "isba", nom: "L'Isba", txt: "Esprit +2", types: ["esprit"] },
    { id: "labyrinthe", nom: "Le Labyrinthe", txt: "2 cartes au plus par camp" },
    { id: "lumecon", nom: "Le Lumeçon", txt: "Ta 1re carte ici : +3" },
    { id: "huaguo", nom: "Mont Huaguo", txt: "Cartes à 1 énergie : +2" },
  ];
  const cap = z => z.def.id === "labyrinthe" ? 2 : 4;
  const rev = (z, c) => z.k[c].filter(x => x.rv);
  function force(st, c) {
    const d = C[c.id], z = st.z[c.zone], zd = z.def;
    let f = (c.fixe != null ? c.fixe : d.force) + c.bonus, malus = c.malus;
    const miens = rev(z, c.camp), autres = rev(z, autre(c.camp));
    if (zd.types && zd.types.includes(typeDe(c.id))) f += 2;
    if (zd.id === "lumecon" && z.k[c.camp][0] === c) f += 3;
    if (zd.id === "huaguo" && d.cout === 1) f += 2;
    for (const m of miens) { if (m === c) continue; if (m.id === "farfadet") f += 1; if (m.id === "bahamut") f += 2; if (m.id === "ifrit") malus -= 1; }
    if (c.id === "kitsune" && miens.length < autres.length) f += 3;
    if (c.id === "cerbere" && miens.length === 1) f += 4;
    if (c.id !== "golem") f += malus;
    return Math.max(0, f);
  }
  const total = (st, i, camp) => rev(st.z[i], camp).reduce((s, c) => s + force(st, c), 0);
  const enJeu = (st, c) => st.z[c.zone].k[c.camp].includes(c);
  function reveler(st, c) {
    c.rv = true;
    const z = st.z[c.zone], adv = rev(z, autre(c.camp)), eff = [];
    const pf = () => adv.length ? adv.reduce((x, y) => force(st, y) > force(st, x) ? y : x) : null;
    let m = "";
    switch (c.id) {
      case "anansi": if (z.k[autre(c.camp)].some(x => x.t === st.tour)) { c.bonus += 4; eff.push([c.uid, "+4", "vert"]); m = "Anansi l'avait deviné : +4"; } break;
      case "loki": { const p = pf(); if (p) { c.fixe = force(st, p); eff.push([c.uid, `= ${c.fixe}`, "mot"]); m = `Loki copie ${nomDe(p.id)}`; } break; }
      case "wukong": for (const zz of st.z) for (const x of rev(zz, c.camp)) if (x !== c) { x.bonus += 1; eff.push([x.uid, "+1", "vert"]); } m = "Wukong : +1 à ses alliés"; break;
      case "thor": for (const e of adv) { e.malus -= 1; eff.push([e.uid, "−1", "rose"]); } if (adv.length) m = "Thor : −1 à chaque ennemi ici"; break;
      case "banshee": { const p = pf(); if (p) { p.malus -= 2; eff.push([p.uid, "−2", "rose"]); m = `Le cri : −2 à ${nomDe(p.id)}`; } break; }
      case "yeti": z.verrou = true; m = `Avalanche : ${z.def.nom} est fermée`; break;
      case "georges": { const p = pf(); if (p && force(st, p) >= 6) { eff.push([p.uid, "détruit", "or"]); z.k[p.camp].splice(z.k[p.camp].indexOf(p), 1); m = `Saint Georges terrasse ${nomDe(p.id)}`; } break; }
    }
    return { m, eff };
  }
  const cloner = st => ({ tour: st.tour, z: st.z.map(z => ({ def: z.def, verrou: z.verrou, k: { j: z.k.j.map(c => ({ ...c })), a: z.k.a.map(c => ({ ...c })) } })) });
  function planIA(st, main, rng) {
    const n = main.length, E = st.tour, base = cloner(st);
    for (const z of base.z) z.k.j = z.k.j.filter(c => c.rv);
    let best = { s: -1e9, plan: [] };
    for (let m = 1; m < (1 << n); m++) {
      let cout = 0; const ids = [];
      for (let i = 0; i < n; i++) if (m >> i & 1) { cout += C[main[i]].cout; ids.push(main[i]); }
      if (cout > E) continue;
      let max = true; for (let i = 0; i < n; i++) if (!(m >> i & 1) && C[main[i]].cout <= E - cout) { max = false; break; }
      if (!max) continue;
      const plan = [];
      const essai = k => {
        if (k === ids.length) {
          const s = cloner(base); let u = 1e6;
          const nv = plan.map(([id, z]) => { const c = { uid: u++, id, camp: "a", zone: z, t: s.tour, rv: false, bonus: 0, malus: 0, fixe: null }; s.z[z].k.a.push(c); return c; });
          for (const c of nv) if (enJeu(s, c)) reveler(s, c);
          let sc = 0; for (let i = 0; i < 3; i++) sc += Math.tanh((total(s, i, "a") - total(s, i, "j")) / 3);
          sc += rng() * 0.2;
          if (sc > best.s) best = { s: sc, plan: plan.slice() };
          return;
        }
        for (let z = 0; z < 3; z++) { const Z = base.z[z]; if (Z.verrou || Z.k.a.length + plan.filter(p => p[1] === z).length >= cap(Z)) continue; plan.push([ids[k], z]); essai(k + 1); plan.pop(); }
      };
      essai(0);
    }
    return best.plan;
  }

  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const deckJ = tuto || statsDe("terres").p % 2 === 0 ? 0 : 1;
    const pool = melanger([...ZONES], rng);
    const zones = tuto ? [ZONES[0], ZONES[1], ZONES[2]] : pool.slice(0, 3);
    const st = { tour: 1, z: zones.map(def => ({ def, k: { j: [], a: [] }, verrou: false })), uid: 0 };
    const main = { j: [...DECKS[deckJ]], a: [...DECKS[1 - deckJ]] };
    let sel = null, occupe = false, fini = false, info = "";

    const zT = h("div", "tt-terres"), zInfo = h("div", "tt-info"), zMain = h("div", "tt-main"), zBas = h("div", "tt-bas");
    const pips = h("div", "sg-energie"), bFin = h("button", "btn or", "Fin du tour");
    zBas.append(pips, bFin);
    ctx.scene.append(zT, zInfo, zMain, zBas);
    const reste = () => st.tour - st.z.flatMap(z => z.k.j).filter(c => c.t === st.tour && !c.rv).reduce((s, c) => s + C[c.id].cout, 0);

    function rendre() {
      const r = reste();
      let tj = 0, ta = 0;
      st.z.forEach((z, i) => { const a = total(st, i, "j"), b = total(st, i, "a"); if (a > b) tj++; else if (b > a) ta++; });
      ctx.scoreJA(tj, ta);
      zT.innerHTML = "";
      st.z.forEach((z, i) => {
        const t = h("div", "tt-terre"), a = total(st, i, "j"), b = total(st, i, "a");
        const ok = sel && !z.verrou && z.k.j.length < cap(z) && C[sel].cout <= r;
        if (sel) t.classList.add(ok ? "ok" : "non");
        if (ok) t.onclick = () => poser(i);
        t.dataset.i = i;
        const camp = c => {
          const g = h("div", "tt-camp" + (c === "a" ? " haut" : ""));
          const els = z.k[c].map(x => {
            const face = c === "j" || x.rv;
            const e = face ? vignette(x.id, { nom: false, force: x.rv ? force(st, x) : C[x.id].force }) : dos();
            if (face && !x.rv) e.classList.add("tt-attente");
            if (x.flash) e.classList.add("retourne");
            e.dataset.uid = x.uid;
            e.onclick = ev => { ev.stopPropagation(); if (occupe) return; if (c === "j" && !x.rv && !fini) return reprendre(x); if (face) { info = `${nomDe(x.id)} : ${C[x.id].txt}`; rendre(); } };
            return e;
          });
          while (els.length < 4) els.push(h("div", "tt-place" + (els.length >= cap(z) ? " hors" : "")));
          if (c === "a") els.reverse();
          g.append(...els); return g;
        };
        const pl = h("div", "tt-plaque");
        pl.append(h("h3", "", z.def.nom), h("p", "", z.def.txt));
        if (z.verrou) pl.append(h("p", "tt-ferme", "fermée"));
        const sc = h("div", "tt-score");
        const sa = h("span", "a", b), sj = h("span", "j", a);
        if (a > b) sj.classList.add("mene"); else if (b > a) sa.classList.add("mene");
        sc.append(sj, h("i", "", a > b ? "tu mènes" : b > a ? "il mène" : "égalité"), sa);
        pl.append(sc);
        if (a !== b) t.classList.add(a > b ? "pj" : "pa");
        t.append(camp("a"), pl, camp("j"));
        zT.append(t);
      });
      zInfo.textContent = sel ? `${nomDe(sel)} · ${C[sel].cout} énergie · force ${C[sel].force} — ${C[sel].txt}` : info || "Touche une carte, puis une terre.";
      zMain.innerHTML = "";
      [...main.j].sort((x, y) => C[x].cout - C[y].cout).forEach(id => {
        const e = vignette(id, { force: C[id].force, cout: C[id].cout }); e.dataset.id = id;
        if (C[id].cout > r || fini) e.classList.add("eteinte");
        if (sel === id) e.classList.add("choisie");
        e.onclick = () => { if (occupe || fini) return; if (C[id].cout > r) { info = `${nomDe(id)} coûte ${C[id].cout} : il te reste ${r} énergie.`; sel = null; rendre(); return; } sel = sel === id ? null : id; rendre(); };
        zMain.append(e);
      });
      pips.innerHTML = "";
      for (let k = 0; k < st.tour; k++) pips.append(h("i", k < r ? "" : "vide"));
      pips.append(h("span", "", `${r} énergie`));
      bFin.disabled = occupe || fini;
      bFin.textContent = fini ? "Partie finie" : st.tour === 6 ? "Dernier tour : révéler" : "Fin du tour";
      if (!occupe && !fini) ctx.consigne(`Tour ${st.tour} sur 6 · ${sel ? "touche une terre" : "pose tes cartes"}`);
    }
    function poser(i) {
      const z = st.z[i]; if (!sel || z.verrou || z.k.j.length >= cap(z) || C[sel].cout > reste()) return;
      main.j.splice(main.j.indexOf(sel), 1);
      z.k.j.push({ uid: ++st.uid, id: sel, camp: "j", zone: i, t: st.tour, rv: false, bonus: 0, malus: 0, fixe: null });
      info = `${nomDe(sel)} attend face cachée. Touche-la pour la reprendre.`; sel = null; rendre();
    }
    function reprendre(c) { const z = st.z[c.zone]; z.k.j.splice(z.k.j.indexOf(c), 1); main.j.push(c.id); info = ""; rendre(); }
    async function finTour(force_) {
      if (occupe || fini) return;
      occupe = true; sel = null;
      for (const [id, zi] of force_ || planIA(st, main.a, rng)) { main.a.splice(main.a.indexOf(id), 1); st.z[zi].k.a.push({ uid: ++st.uid, id, camp: "a", zone: zi, t: st.tour, rv: false, bonus: 0, malus: 0, fixe: null }); }
      ctx.consigne("On retourne les cartes…", "calme"); rendre();
      await dodo(700); if (!ctx.vivant()) return;
      const prem = st.tour % 2 ? "j" : "a";
      const file = [prem, autre(prem)].flatMap(c => st.z.flatMap(z => z.k[c]).filter(x => !x.rv).sort((a, b) => a.uid - b.uid));
      for (const c of file) {
        if (!enJeu(st, c)) continue;
        const { m, eff } = reveler(st, c);
        c.flash = true; if (m) info = m; rendre();
        for (const [u, t, k] of eff) flotSur(zT.querySelector(`[data-uid="${u}"]`), t, k);
        await dodo(m ? 950 : 520); if (!ctx.vivant()) return;
        c.flash = false;
      }
      occupe = false;
      if (st.tour === 6) { fini = true; rendre(); return terminer(); }
      st.tour++; rendre();
    }
    function terminer() {
      let tj = 0, ta = 0, sj = 0, sa = 0;
      st.z.forEach((z, i) => { const a = total(st, i, "j"), b = total(st, i, "a"); sj += a; sa += b; if (a > b) tj++; else if (b > a) ta++; });
      const g = tj > ta || (tj === ta && sj > sa), nul = tj === ta && sj === sa;
      ctx.consigne(nul ? "Égalité" : g ? "Gagné !" : "Perdu", g ? "" : "lui");
      setTimeout(() => ctx.fin({ titre: nul ? "Égalité" : g ? "Victoire" : "Défaite", texte: `Terres : ${tj} pour toi, ${ta} pour lui.${tj === ta && !nul ? ` Force totale : ${sj} contre ${sa}.` : ""}`, gagne: g && !nul }), 900);
    }
    bFin.onclick = () => finTour();
    rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Gagne 2 terres sur 3, en 6 tours." });
      if (!ctx.vivant()) return;
      await ctx.etape({ cible: () => zMain.querySelector('[data-id="draugr"]'), texte: "Touche Draugr" });
      if (sel !== "draugr") { sel = "draugr"; rendre(); }
      await ctx.etape({ cible: () => zT.children[0], texte: "Pose-le au Valhalla : Glace +2" });
      if (!st.z[0].k.j.length && main.j.includes("draugr")) poser(0);
      bFin.onclick = null;
      await ctx.etape({ cible: () => bFin, texte: "Fin du tour : on retourne tout" });
      bFin.onclick = () => finTour();
      await finTour([["draugr", 1]]);
      if (!ctx.vivant()) return;
      await ctx.etape({ texte: "Tu mènes au Valhalla ! Il a posé aux Enfers." });
      await ctx.etape({ texte: "Chaque tour, 1 énergie de plus." });
      ctx.tutoFini(); rendre();
    })();
  }

  enregistrer({ id: "terres", num: "8", nom: "Les Trois Terres", accroche: "Pose en secret sur 3 terres. On retourne tout. 2 terres gagnent.", duree: "3 min", images: ["wukong", "yeti", "georges"], fond: "linear-gradient(160deg,#1a2a1c,#131022)", lancer });
})();
