// ═════════════════════════════ 3 · LES CONSTELLATIONS ═════════════════════════════
// Une course contre trois boss. Tu as 6 cartes en main : choisis-en jusqu'à 4 qui forment une
// constellation (même type, trio de rôles, même terre…) et lance. Plus elle est rare, plus ça frappe.
// En duel, les deux joueurs reçoivent exactement les mêmes tirages : le hasard ne départage personne.
(function () {
  const MAIN = 6, MAXSEL = 4;
  const BOSS = [{ id: "minotaure", pv: 180 }, { id: "wendigo", pv: 360 }, { id: "troll", pv: 600 }];
  const ASTRES = [
    { id: "odin", nom: "L'œil d'Odin", txt: "+2 au multiplicateur des brelans et plus", f: (c) => { if (c.rang >= 3) c.mult += 2; } },
    { id: "lanterne", nom: "La Lanterne", txt: "Cartes Esprit : +8 force", f: (c) => { c.bonus += 8 * c.cartes.filter(id => typeDe(id) === "esprit").length; } },
    { id: "marteau", nom: "Le Marteau", txt: "Cartes Foudre : +8 force", f: (c) => { c.bonus += 8 * c.cartes.filter(id => typeDe(id) === "foudre").length; } },
    { id: "braise", nom: "La Braise", txt: "Cartes Feu : +8 force", f: (c) => { c.bonus += 8 * c.cartes.filter(id => typeDe(id) === "feu").length; } },
    { id: "boussole", nom: "La Boussole", txt: "Voyage et Trio des rôles : ×2 en plus", f: (c) => { if (c.voyage || c.trio) c.mult += 2; } },
    { id: "rosace", nom: "La Rosace", txt: "+15 à chaque lancer", f: (c) => { c.base += 15; } },
    { id: "lune", nom: "La Pierre de lune", txt: "Dégâts finaux ×1,5", f: (c) => { c.final *= 1.5; } },
  ];
  function force(id) {
    const f = FICHES[id];
    if (f.sbire) return 5;
    if (f.role === "frappeur") return Math.round(f.att / 2);
    if (f.role === "garde") return Math.round(f.pv / 10);
    return Math.round((f.att + f.pv / 5) / 2);
  }
  const TN = t => TYPES[t].nom;
  // La meilleure constellation d'une sélection
  function analyser(sel, astres) {
    if (!sel.length) return null;
    const parType = {}, parRegion = {}, roles = new Set(sel.map(id => FICHES[id].role));
    for (const id of sel) { parType[typeDe(id)] = (parType[typeDe(id)] || 0) + 1; parRegion[regionDe(id)] = (parRegion[regionDe(id)] || 0) + 1; }
    const ts = Object.entries(parType).sort((a, b) => b[1] - a[1]);
    const rg = Object.entries(parRegion).sort((a, b) => b[1] - a[1]);
    const cands = [{ nom: "Carte seule", base: 5, mult: 1, rang: 1 }];
    if (ts[0][1] >= 2) cands.push({ nom: `Paire ${de(ts[0][0])}`, base: 10, mult: 2, rang: 2 });
    if (ts.length >= 2 && ts[0][1] >= 2 && ts[1][1] >= 2) cands.push({ nom: "Double paire", base: 20, mult: 2, rang: 2 });
    if (ts[0][1] >= 3) cands.push({ nom: `Brelan ${de(ts[0][0])}`, base: 30, mult: 3, rang: 3 });
    if (rg[0][1] >= 3) cands.push({ nom: `Voyage vers ${rg[0][0]}`, base: 30, mult: 3, rang: 3, voyage: true });
    if (roles.has("garde") && roles.has("frappeur") && roles.has("appui")) cands.push({ nom: "Trio des rôles", base: 35, mult: 3, rang: 3, trio: true });
    if (sel.length === 4 && ts.length === 4) cands.push({ nom: "Arc-en-ciel", base: 40, mult: 4, rang: 4 });
    if (ts[0][1] >= 4) cands.push({ nom: `Carré ${de(ts[0][0])}`, base: 60, mult: 6, rang: 5 });
    let best = null;
    for (const c of cands) {
      const x = { ...c, cartes: sel, bonus: 0, final: 1, somme: sel.reduce((s, id) => s + force(id), 0) };
      for (const a of astres) a.f(x);
      x.total = Math.round((x.base + x.somme + x.bonus) * x.mult * x.final);
      if (!best || x.total > best.total) best = x;
    }
    return best;
  }
  function de(t) { const n = TN(t); return /^[AEIOUÉ]/.test(n) ? `d'${n}` : `de ${n}`; }

  function lancer(ctx) {
    const tuto = Jeu.tuto, graine = tuto ? 4821 : Math.floor(Date.now() % 9000) + 1000, rng = rngDe(graine);
    let bossI = 0, pv = BOSS[0].pv, lancers = 3, defausses = 2, pioche = [], main = [], sel = [], astres = [], occupe = false;
    function paquet() {
      const types = melanger(Object.keys(ADV), rng).slice(0, 3), p = [];
      for (const t of types) { p.push(...melanger(HEROS.filter(x => x.type === t && !BOSS.some(b => b.id === x.id)).map(x => x.id), rng).slice(0, 4)); p.push(SBIRES.find(s => s.type === t).id); }
      const restants = melanger(HEROS.filter(x => !p.includes(x.id) && !BOSS.some(b => b.id === x.id)).map(x => x.id), rng);
      while (p.length < 18) p.push(restants.shift());
      return melanger(p, rng);
    }
    function piocher() { while (main.length < MAIN && pioche.length) main.push(pioche.shift()); }
    function nouveauBoss() {
      pv = BOSS[bossI].pv; lancers = 3; defausses = 2; sel = []; pioche = paquet(); main = [];
      if (tuto && bossI === 0) { main = ["kitsune", "golem", "loki", "thor", "mothman", "oni"]; pioche = pioche.filter(id => !main.includes(id)); }
      piocher();
    }

    const zBoss = h("div", "cs-boss"), zCalc = h("div", "cs-calc"), zAstres = h("div", "cs-astres"), zMain = h("div", "cs-main"), zBtn = h("div", "rangee");
    const bDef = h("button", "btn sec", "Défausser"), bLan = h("button", "btn or", "Lancer");
    zBtn.append(bDef, bLan);
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg"); svg.classList.add("cs-lignes");
    ctx.scene.append(zBoss, zCalc, zAstres, zMain, zBtn, svg);
    ctx.scene.append(h("div", "cs-graine", `Tirage n° ${graine} — en duel, ton adversaire aurait eu les mêmes cartes.`));

    function rendre() {
      const b = BOSS[bossI];
      ctx.score.innerHTML = `<span class="sep">boss</span><span class="j">${bossI + 1}</span><span class="sep">sur 3</span>`;
      zBoss.innerHTML = "";
      const bc = vignette(b.id, { nom: false }); bc.classList.add("cs-bosscarte");
      const info = h("div", "cs-info");
      info.append(h("div", "cs-bnom", nomDe(b.id)));
      const barre = h("div", "cs-pv"), rem = h("i"); rem.style.width = Math.max(0, pv / b.pv * 100) + "%"; barre.append(rem);
      info.append(barre, h("div", "cs-pvtxt", `${Math.max(0, pv)} / ${b.pv} PV`));
      const cpt = h("div", "cs-cpt"); cpt.innerHTML = `<span><b>${lancers}</b> lancer${lancers > 1 ? "s" : ""}</span><span><b>${defausses}</b> défausse${defausses > 1 ? "s" : ""}</span>`;
      info.append(cpt);
      zBoss.append(bc, info);
      const a = analyser(sel, astres);
      zCalc.innerHTML = "";
      if (a) {
        zCalc.append(h("div", "cs-cnom", a.nom));
        zCalc.append(h("div", "cs-cform", `(${a.base} + ${a.somme + a.bonus}) × ${a.mult}${a.final !== 1 ? ` × ${a.final}` : ""} = ${a.total}`));
      } else zCalc.append(h("div", "cs-vide", "Touche des cartes du même type, ou un garde + un frappeur + un appui"));
      zAstres.innerHTML = "";
      zAstres.hidden = !astres.length;
      for (const s of astres) { const e = h("div", "cs-astre"); e.innerHTML = etoile("", 8, 0.3); e.append(h("span", "", s.nom)); e.title = s.txt; e.onclick = () => ctx.consigne(`${s.nom} : ${s.txt}`, "calme"); zAstres.append(e); }
      zMain.innerHTML = "";
      main.forEach((id, k) => {
        const e = vignette(id, { force: force(id) }); e.dataset.k = k; e.dataset.id = id;
        const t = h("div", "cs-type", TN(typeDe(id))); t.style.color = TYPES[typeDe(id)].c; e.append(t);
        if (sel.includes(id)) e.classList.add("choisie");
        if (tuto && bossI === 0 && Guide.actif("trois") && typeDe(id) === "esprit") e.classList.add("brille");
        e.onclick = () => {
          if (occupe) return;
          if (sel.includes(id)) sel = sel.filter(x => x !== id); else if (sel.length < MAXSEL) sel.push(id);
          rendre();
          if (sel.length === 3 && sel.every(x => typeDe(x) === "esprit")) Guide.signal("trois");
        };
        zMain.append(e);
      });
      bLan.disabled = !sel.length || occupe || !lancers;
      bDef.disabled = !sel.length || occupe || !defausses;
      bLan.textContent = a ? `Lancer · ${a.total}` : "Lancer";
      ctx.consigne(occupe ? "…" : sel.length ? "Lance, ou défausse pour piocher" : "Choisis jusqu'à 4 cartes", occupe ? "calme" : "");
    }
    function relier() {
      svg.innerHTML = "";
      const r0 = ctx.scene.getBoundingClientRect(), pts = [];
      for (const id of sel) { const e = zMain.querySelector(`[data-id="${id}"]`); if (e) { const r = e.getBoundingClientRect(); pts.push([r.left + r.width / 2 - r0.left, r.top + r.height / 2 - r0.top]); } }
      let d = ""; pts.forEach((p, i) => d += (i ? "L" : "M") + p[0] + " " + p[1]);
      const path = document.createElementNS("http://www.w3.org/2000/svg", "path"); path.setAttribute("d", d); path.classList.add("cs-trait"); svg.append(path);
      for (const p of pts) svg.insertAdjacentHTML("beforeend", `<g transform="translate(${p[0] - 11} ${p[1] - 11}) scale(.22)">${etoile("", 8, 0.28).replace(/<\/?svg[^>]*>/g, "")}</g>`);
    }
    async function lancerMain() {
      const a = analyser(sel, astres); if (!a || occupe || !lancers) return;
      occupe = true; rendre(); relier();
      for (const id of sel) rejouer(zMain.querySelector(`[data-id="${id}"]`), "bond");
      await dodo(700); if (!ctx.vivant()) return;
      svg.innerHTML = "";
      flotSur(zBoss.querySelector(".cs-bosscarte"), `−${a.total}`, a.total >= 150 ? "gros" : "or", 0.5);
      rejouer(zBoss.querySelector(".cs-bosscarte"), "secoue");
      pv -= a.total; lancers--;
      main = main.filter(id => !sel.includes(id)); sel = []; piocher();
      await dodo(500); if (!ctx.vivant()) return;
      occupe = false; rendre();
      if (pv <= 0) return bossVaincu();
      if (!lancers) {
        await dodo(400);
        return ctx.fin({ titre: "Défaite", texte: `${nomDe(BOSS[bossI].id)} tient encore, avec ${pv} PV. Tu étais au boss ${bossI + 1} sur 3.`, gagne: false });
      }
    }
    async function bossVaincu() {
      if (bossI === BOSS.length - 1) return ctx.fin({ titre: "Victoire", texte: "Les trois boss sont tombés.", gagne: true });
      ctx.consigne(`${nomDe(BOSS[bossI].id)} est tombé ! Choisis un astre`);
      const deja = new Set(astres.map(a => a.id)), choix = melanger(ASTRES.filter(a => !deja.has(a.id)), rng).slice(0, 2);
      const voile = h("div", "cs-choix");
      voile.append(h("h3", "", "Un astre te rejoint"), h("p", "", "Il agit sur tous tes prochains lancers."));
      for (const c of choix) {
        const b = h("button", "cs-astrechoix"); b.innerHTML = etoile("", 8, 0.3);
        b.append(h("b", "", c.nom), h("span", "", c.txt));
        b.onclick = () => { astres.push(c); voile.remove(); bossI++; nouveauBoss(); rendre(); ctx.consigne(`Boss ${bossI + 1} : ${nomDe(BOSS[bossI].id)}`); };
        voile.append(b);
      }
      ctx.scene.append(voile);
    }
    bLan.onclick = lancerMain;
    bDef.onclick = () => {
      if (!sel.length || !defausses || occupe) return;
      defausses--; main = main.filter(id => !sel.includes(id)); sel = []; piocher(); rendre();
    };
    nouveauBoss(); rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Frappe le boss avec des constellations." });
      if (!ctx.vivant()) return;
      rendre();
      const trois = ctx.etape({ cible: () => zMain, signal: "trois", doigt: false, texte: "Touche les 3 cartes Esprit qui brillent" });
      rendre();
      await trois;
      if (!ctx.vivant()) return;
      rendre();
      await ctx.etape({ texte: "3 cartes du même type : un Brelan !" });
      await ctx.etape({ cible: () => bLan, texte: "Lance !" });
      await dodo(1400);
      await ctx.etape({ texte: "Plus c'est rare, plus ça frappe." });
      ctx.tutoFini();
    })();
  }

  enregistrer({ id: "constellations", num: "3", nom: "Les Constellations", accroche: "Forme des combinaisons de héros, fais exploser le score du boss.", duree: "3 min", images: ["kitsune", "loki", "mothman"], fond: "linear-gradient(160deg,#2b1f4a,#16112a)", lancer });
})();
