// ═════════════════════════════ N4 · LE RITUEL ═════════════════════════════
// Chaque créature a son rituel : deux conditions pour le stade II, deux autres pour le III.
// L'adversaire voit tout, et essaie de t'arrêter. Sceaux : II = 1, III = 2. Premier à 5 sceaux gagne
// (ou élimine l'équipe adverse). La forme III est très forte, mais elle ne suffit pas seule.
(function () {
  const SCEAUX = 5, TOURS_MAX = 16;
  const ARCH = { thor: "F", minotaure: "F", wukong: "F", fenrir: "F", kitsune: "F", golem: "T", cerbere: "T", doudou: "T", yeti: "T", bahamut: "S", quetzalcoatl: "S", anubis: "S", banshee: "S", babayaga: "S" };
  const RITES = {
    F: [[{ k: "degats", n: 12, t: "Infliger 12 dégâts" }, { k: "controle", n: 1, t: "Tenir un territoire" }], [{ k: "kos", n: 1, t: "Vaincre une créature" }, { k: "essence", n: 4, t: "Réunir 4 Essence" }]],
    T: [[{ k: "subis", n: 12, t: "Encaisser 12 dégâts" }, { k: "defenses", n: 2, t: "Défendre 2 fois" }], [{ k: "controle", n: 2, t: "Tenir 2 tours de suite" }, { k: "essence", n: 4, t: "Réunir 4 Essence" }]],
    S: [[{ k: "pouvoirs", n: 2, t: "Pouvoir 2 fois" }, { k: "essence", n: 3, t: "Réunir 3 Essence" }], [{ k: "pouvoirs", n: 2, t: "Pouvoir 2 fois de plus" }, { k: "controle", n: 2, t: "Tenir 2 tours de suite" }]],
  };
  const TERRES = ["Le Cercle de pierres", "L'Autel", "La Source"];
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const ids = tuto ? [["thor", "golem", "bahamut"], ["fenrir", "cerbere", "babayaga"]] : (() => { const p = melanger([...ROSTER], rng); return [p.slice(0, 3), p.slice(3, 6)]; })();
    const J = ids[0].map(id => creer(id, "j")), A = ids[1].map(id => creer(id, "a"));
    [...J, ...A].forEach((c, i) => { c.terr = i % 3; c.essence = 0; c.suite = 0; c.suivi = { degats: 0, subis: 0, defenses: 0, pouvoirs: 0, kos: 0 }; c.agi = false; });
    const sceaux = { j: 0, a: 0 };
    let tour = 1, sel = null, occupe = false, fini = false;
    const zRA = h("div", "ri-rites"), zT = h("div", "cols3 ri-terres"), zRJ = h("div", "ri-rites"), zLog = h("div", "jl"), zPn = h("div", "pn");
    ctx.scene.append(zRA, zT, zRJ, zLog, zPn);
    const tous = () => [...J, ...A];
    const M = matchDe(ctx, zLog, {
      tous, adversaires: c => (c.camp === "j" ? A : J).filter(x => x.terr === c.terr), allies: c => c.camp === "j" ? J : A,
      hook(t, a, b, n) {
        if (t === "degats") { if (a && a.suivi) a.suivi.degats += n; if (b && b.suivi) b.suivi.subis += n; }
        if (t === "ko" && a && a.suivi) a.suivi.kos++;
        if (t === "pouvoir") a.suivi.pouvoirs++;
      },
    });
    const rite = c => c.stade < 3 ? RITES[ARCH[c.id]][c.stade - 1] : null;
    const val = (c, cd) => cd.k === "essence" ? c.essence : cd.k === "controle" ? c.suite : c.suivi[cd.k];
    const avance = c => { const r = rite(c); return r ? r.reduce((s, cd) => s + Math.min(1, val(c, cd) / cd.n), 0) / r.length : 1; };
    function verifier() {
      for (const c of tous()) {
        const r = rite(c); if (!r || c.ko) continue;
        if (r.every(cd => val(c, cd) >= cd.n)) {
          for (const cd of r) if (cd.k === "essence") c.essence -= cd.n;
          c.suivi = { degats: 0, subis: 0, defenses: 0, pouvoirs: 0, kos: 0 };
          evoluer(M, c);
          if (c.stade === 3) { c.bonusAtt += 4; recalc(c); M.log(`${nomDe(c.id)} atteint sa forme légendaire !`); }
          sceaux[c.camp] += c.stade === 3 ? 2 : 1;
        }
      }
    }
    function blocRite(c, camp) {
      const b = h("div", "ri-bloc " + camp + (c.ko ? " ko" : "")); b.dataset.cible = c.uid;
      const t = h("div", "ri-tete"); t.append(vignette(c.id, { stade: c.stade, nom: false }), h("b", "", `${nomDe(c.id)} ${["I", "II", "III"][c.stade - 1]}`));
      b.append(t);
      const r = rite(c);
      if (c.ko) b.append(h("div", "ri-cd", "tombé"));
      else if (!r) b.append(h("div", "ri-cd fait", "Forme légendaire"));
      else for (const cd of r) {
        const v = Math.min(val(c, cd), cd.n), l = h("div", "ri-cd" + (v >= cd.n ? " fait" : ""));
        const barre = h("i"); barre.style.width = v / cd.n * 100 + "%";
        const bar = h("span", "ri-bar"); bar.append(barre);
        l.append(h("span", "", `${cd.t}`), h("em", "", `${v}/${cd.n}`), bar);
        b.append(l);
      }
      b.append(h("div", "ri-ess", `Essence ${c.essence}`));
      return b;
    }
    function rendre() {
      ctx.score.innerHTML = `<span class="sep">sceaux</span><span class="j">${sceaux.j}</span><span class="sep">contre</span><span class="a">${sceaux.a}</span>`;
      zRA.innerHTML = ""; A.forEach(c => zRA.append(blocRite(c, "a")));
      zRJ.innerHTML = ""; J.forEach(c => zRJ.append(blocRite(c, "j")));
      zT.innerHTML = "";
      TERRES.forEach((nom, t) => {
        const col = h("div", "ch-terre"), cA = h("div", "ch-camp"), cJ = h("div", "ch-camp");
        for (const c of vivants(A).filter(x => x.terr === t)) cA.append(elCreature(c, { petit: true }));
        for (const c of vivants(J).filter(x => x.terr === t)) cJ.append(elCreature(c, { petit: true, sel: sel === c, plan: c.agi ? "a agi" : "", onclick: () => { if (!occupe && !c.agi) { sel = sel === c ? null : c; rendre(); } } }));
        const nj = vivants(J).filter(x => x.terr === t).length, na = vivants(A).filter(x => x.terr === t).length;
        const tete = h("div", "ch-nom"); tete.dataset.cible = "t" + t; tete.append(h("b", "", nom), h("span", nj > na ? "j" : na > nj ? "a" : "", nj > na ? "à toi" : na > nj ? "à lui" : "disputé"));
        col.append(cA, tete, cJ); zT.append(col);
      });
      if (fini) zPn.innerHTML = "";
      else if (occupe) { zPn.innerHTML = ""; ctx.consigne("Son tour…", "lui"); }
      else if (sel) actions(sel);
      else { const n = vivants(J).filter(c => !c.agi).length; panneau(zPn, n ? `${n} créature(s) peuvent encore agir` : "Tout le monde a agi", [{ nom: "Fin du tour", txt: "il joue ensuite", cls: "or", f: finTour }]); ctx.consigne(`Tour ${tour} · premier à ${SCEAUX} sceaux`); }
      marquerCibles();
    }
    function actions(c) {
      const k = KITS[c.id], en = ciblesValides(A.filter(x => x.terr === c.terr)), seul = !A.some(x => !x.ko && x.terr === c.terr);
      panneau(zPn, `${nomDe(c.id)} · ${forme(c)}`, [
        { nom: "Attaquer", txt: en.length ? "sur ce territoire" : "personne ici", dispo: en.length > 0, f: async () => { const u = await cib(en.map(x => x.uid)); if (u) agir(c, "attaque", +u); } },
        { nom: "Canaliser", txt: seul ? "+2 Essence (personne en face)" : "+1 Essence", f: () => agir(c, "canal") },
        { nom: "Défendre", txt: "dégâts ÷2", f: () => agir(c, "defense") },
        { nom: "Se déplacer", txt: "vers un territoire voisin", f: async () => { const u = await cib([c.terr - 1, c.terr + 1].filter(t => t >= 0 && t < 3).map(t => "t" + t)); if (u) agir(c, "deplacer", +u.slice(1)); } },
        { nom: k.pouvoir, txt: c.recharge ? `recharge ${c.recharge}` : k.txt, dispo: !c.recharge && (k.cible !== "ennemi" || en.length > 0), f: async () => {
          let u = null;
          if (k.cible === "ennemi") { u = await cib(en.map(x => x.uid)); if (!u) return; }
          if (k.cible === "allie") { u = await cib(vivants(J).filter(x => x !== c).map(x => x.uid)); if (!u) return; }
          agir(c, "pouvoir", u ? +u : null);
        } },
      ], () => { sel = null; rendre(); });
    }
    function cib(cands) { ctx.consigne("Touche la cible"); const p = choisir(cands); zPn.querySelector(".pn-annuler").onclick = () => annulerChoix(); return p; }
    function executer(c, t, u) {
      c.agi = true;
      if (c.st.gele) { delete c.st.gele; M.fx(c, "gelé", "mot"); return; }
      const cible = u != null ? tous().find(x => x.uid === u) : null;
      if (t === "attaque") frapper(M, c, cible, 1);
      if (t === "canal") { const g = A.concat(J).some(x => !x.ko && x.camp !== c.camp && x.terr === c.terr) ? 1 : 2; c.essence += g; M.fx(c, `+${g} Essence`, "vert"); }
      if (t === "defense") { c.defend = true; c.suivi.defenses++; M.fx(c, "en garde", "mot"); }
      if (t === "deplacer") c.terr = u;
      if (t === "pouvoir") { pouvoir(M, c, cible); if (c.stade === 3) c.recharge = 0; }
      verifier();
    }
    function agir(c, t, u) { if (occupe) return; executer(c, t, u); sel = null; rendre(); fin(); }
    function controle(camp) {
      for (const c of vivants(camp === "j" ? J : A)) {
        const nm = vivants(camp === "j" ? J : A).filter(x => x.terr === c.terr).length, ne = vivants(camp === "j" ? A : J).filter(x => x.terr === c.terr).length;
        c.suite = nm > ne ? c.suite + 1 : 0;
      }
      verifier();
    }
    async function finTour() {
      if (occupe) return; occupe = true; sel = null;
      controle("j"); rendre(); if (fin()) return;
      debutTour(M, "a"); for (const c of A) c.agi = false;
      await dodo(500); if (!ctx.vivant()) return;
      for (const c of vivants(A)) {
        if (c.ko) continue;
        const [t, u] = planIA(c); executer(c, t, u); rendre();
        await dodo(750); if (!ctx.vivant() || fin()) return;
      }
      controle("a"); rendre(); if (fin()) return;
      debutTour(M, "j"); for (const c of J) c.agi = false;
      tour++; occupe = false; rendre(); fin();
    }
    // L'IA avance son rituel, et freine le tien : elle vise la créature la plus proche d'évoluer.
    function planIA(c) {
      const r = rite(c) || [], manque = k => r.some(cd => cd.k === k && val(c, cd) < cd.n);
      const ici = ciblesValides(J.filter(x => x.terr === c.terr));
      const menace = vivants(J).sort((a, b) => avance(b) - avance(a))[0];
      const opts = [];
      if (ici.length) { const t = ici.slice().sort((a, b) => avance(b) - avance(a) || a.pv - b.pv)[0]; opts.push([["attaque", t.uid], 4 + (manque("degats") || manque("kos") ? 3 : 0) + avance(t) * 4]); }
      if (manque("essence")) opts.push([["canal"], ici.length ? 3 : 6]);
      if (manque("defenses")) opts.push([["defense"], 5]);
      if (manque("controle") && ici.length) opts.push([["defense"], 3]);
      const k = KITS[c.id];
      if (!c.recharge && (k.cible !== "ennemi" || ici.length)) opts.push([["pouvoir", k.cible === "ennemi" ? ici[0].uid : k.cible === "allie" ? (vivants(A).filter(x => x !== c)[0] || c).uid : null], (manque("pouvoirs") ? 6 : 2) + valeurPouvoir(M, c) * 0.4]);
      if (menace && menace.terr !== c.terr && Math.abs(menace.terr - c.terr) === 1 && avance(menace) > 0.5) opts.push([["deplacer", menace.terr], 5]);
      if (!ici.length && !manque("essence")) { const t = [c.terr - 1, c.terr + 1].filter(x => x >= 0 && x < 3); opts.push([["deplacer", t[Math.floor(rng() * t.length)]], 2]); }
      opts.push([["canal"], 1]);
      const tot = opts.reduce((s, o) => s + o[1], 0); let x = rng() * tot;
      for (const [o, w] of opts) { x -= w; if (x <= 0) return o; }
      return opts[0][0];
    }
    function fin() {
      if (fini) return true;
      let g = null, txt = "";
      if (sceaux.j >= SCEAUX || !vivants(A).length) { g = true; txt = sceaux.j >= SCEAUX ? `Ton rituel est accompli : ${sceaux.j} sceaux.` : "Son équipe est tombée."; }
      else if (sceaux.a >= SCEAUX || !vivants(J).length) { g = false; txt = sceaux.a >= SCEAUX ? `Son rituel est accompli : ${sceaux.a} sceaux.` : "Ton équipe est tombée."; }
      else if (tour > TOURS_MAX) { g = sceaux.j > sceaux.a; txt = `Au bout de ${TOURS_MAX} tours : ${sceaux.j} sceaux contre ${sceaux.a}.`; }
      if (g === null) return false;
      fini = true; occupe = true; rendre();
      ctx.fin({ titre: g ? "Victoire" : "Défaite", texte: txt, gagne: g });
      return true;
    }
    rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Remplis les conditions : ta créature évolue." });
      await ctx.etape({ texte: "Stade II = 1 sceau, III = 2. Premier à 5 sceaux gagne." });
      await ctx.etape({ texte: "Tu vois son rituel en haut. Empêche-le !" });
      ctx.tutoFini();
    })();
  }
  enregistrer({ groupe: "nouveaux", id: "rituel", num: "4", nom: "Le Rituel", accroche: "Remplis les conditions pour évoluer. Empêche les siennes.", duree: "7 min", images: ["golem-1", "golem-2", "golem-3"], fond: "linear-gradient(160deg,#28183a,#141022)", lancer });
})();
