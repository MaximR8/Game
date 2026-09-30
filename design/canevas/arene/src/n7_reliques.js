// ═════════════════════════════ N7 · CONQUÊTE DE RELIQUES ═════════════════════════════
// Trois reliques apparaissent au centre (L'Autel) ; chaque équipe part de son côté. Ramasse-les : le porteur devient bien plus fort,
// mais il encaisse +25 % et tout le monde le vise. Porteur vaincu : la relique tombe, n'importe qui la reprend.
// Victoire : tenir 2 reliques à la fin de 3 de tes tours d'affilée, ou éliminer l'équipe adverse.
(function () {
  const TENIR = 3;
  const RELIQUES = [
    { id: "mjolnir", nom: "Mjölnir", txt: "+5 ATT" },
    { id: "masque", nom: "Masque spirituel", txt: "revient une fois après la mort" },
    { id: "orbe", nom: "Orbe", txt: "Éveil ×2 : évolue deux fois plus vite" },
  ];
  const TERRES = ["Le Gué", "L'Autel", "Le Tertre"];
  const SEUILS = [3, 6];
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const ids = tuto ? [["thor", "kitsune", "golem"], ["fenrir", "cerbere", "banshee"]] : (() => { const p = melanger([...ROSTER], rng); return [p.slice(0, 3), p.slice(3, 6)]; })();
    const J = ids[0].map(id => creer(id, "j")), A = ids[1].map(id => creer(id, "a"));
    [...J, ...A].forEach(c => { c.terr = c.camp === "j" ? 0 : 2; c.eveil = 0; c.agi = false; c.relique = null; });
    const R = RELIQUES.map((r, i) => ({ ...r, terr: 1, porteur: null }));
    const tenue = { j: 0, a: 0 };
    let tour = 1, sel = null, occupe = false, fini = false;
    const zT = h("div", "cols3 ri-terres"), zRel = h("div", "rq-rel"), zLog = h("div", "jl"), zPn = h("div", "pn");
    ctx.scene.append(zRel, zT, zLog, zPn);
    const tous = () => [...J, ...A];
    const porteurDe = r => r.porteur ? tous().find(x => x.uid === r.porteur) : null;
    const nb = camp => R.filter(r => { const p = porteurDe(r); return p && p.camp === camp; }).length;
    const M = matchDe(ctx, zLog, {
      tous, adversaires: c => (c.camp === "j" ? A : J).filter(x => x.terr === c.terr), allies: c => c.camp === "j" ? J : A,
      hook(t, a, b) {
        if (t === "ko") {
          const r = b.relique && R.find(x => x.id === b.relique);
          if (r && r.id === "masque" && !b.masqueUse) { b.masqueUse = true; b.ko = false; b.pv = Math.round(b.max / 2); M.log(`Le Masque spirituel ramène ${nomDe(b.id)}… puis tombe`); M.fx(b, "revient !", "gros"); }
          if (r) lacher(b, r);
        }
      },
    });
    function prendre(c, r) { r.porteur = c.uid; r.terr = null; c.relique = r.id; c.fragile = 1.25; if (r.id === "mjolnir") { c.bonusAtt += 5; recalc(c); } M.log(`${nomDe(c.id)} prend ${r.nom} !`); M.fx(c, r.nom, "gros"); }
    function lacher(c, r) { r.porteur = null; r.terr = c.terr; c.relique = null; c.fragile = 0; if (r.id === "mjolnir") { c.bonusAtt -= 5; recalc(c); } M.log(`${r.nom} tombe à ${TERRES[c.terr]}`); }
    function rendre() {
      ctx.score.innerHTML = `<span class="sep">reliques</span><span class="j">${nb("j")}</span><span class="sep">contre</span><span class="a">${nb("a")}</span>`;
      zRel.innerHTML = "";
      for (const r of R) {
        const p = porteurDe(r), e = h("div", "rq-une " + (p ? p.camp : ""));
        e.innerHTML = etoile("", 8, 0.3); e.append(h("b", "", r.nom), h("span", "", r.txt), h("em", "", p ? `${p.camp === "j" ? "à toi" : "à lui"} : ${nomDe(p.id)}` : `au sol : ${TERRES[r.terr]}`));
        zRel.append(e);
      }
      const t2 = h("div", "rq-tenir");
      t2.textContent = `2 reliques tenues : toi ${tenue.j}/${TENIR} · lui ${tenue.a}/${TENIR}`;
      zRel.append(t2);
      zT.innerHTML = "";
      TERRES.forEach((nom, t) => {
        const col = h("div", "ch-terre"), cA = h("div", "ch-camp"), cJ = h("div", "ch-camp");
        const badge = c => { if (!c.relique) return null; const e = h("div", "rq-porte", R.find(x => x.id === c.relique).nom); return e; };
        for (const c of vivants(A).filter(x => x.terr === t)) cA.append(elCreature(c, { petit: true, extra: badge(c) }));
        for (const c of vivants(J).filter(x => x.terr === t)) cJ.append(elCreature(c, { petit: true, sel: sel === c, plan: c.agi ? "a agi" : "", extra: badge(c), onclick: () => { if (!occupe && !c.agi) { sel = sel === c ? null : c; rendre(); } } }));
        const tete = h("div", "ch-nom"); tete.dataset.cible = "t" + t;
        const sol = R.filter(r => r.terr === t);
        tete.append(h("b", "", nom), h("span", sol.length ? "a" : "", sol.length ? sol.map(r => r.nom).join(", ") + " au sol" : "—"));
        col.append(cA, tete, cJ); zT.append(col);
      });
      if (fini) zPn.innerHTML = "";
      else if (occupe) { zPn.innerHTML = ""; ctx.consigne("Son tour…", "lui"); }
      else if (sel) actions(sel);
      else { panneau(zPn, `Touche une créature (${vivants(J).filter(c => !c.agi).length} peuvent agir)`, [{ nom: "Fin du tour", txt: "il joue ensuite", cls: "or", f: finTour }]); ctx.consigne(`Tour ${tour}`); }
      marquerCibles();
    }
    function actions(c) {
      const k = KITS[c.id], en = ciblesValides(A.filter(x => x.terr === c.terr)), sol = R.find(r => r.terr === c.terr);
      const seuil = SEUILS[c.stade - 1];
      panneau(zPn, `${nomDe(c.id)} · Éveil ${c.eveil}${c.stade < 3 ? "/" + seuil : ""}${c.relique ? " · porte " + R.find(x => x.id === c.relique).nom : ""}`, [
        { nom: "Ramasser", txt: sol ? (c.relique ? "tu portes déjà une relique" : sol.nom) : "rien au sol ici", dispo: !!sol && !c.relique, cls: sol && !c.relique ? "or" : "", f: () => agir(c, "ramasser") },
        { nom: "Attaquer", txt: en.length ? "sur ce territoire" : "personne ici", dispo: en.length > 0, f: async () => { const u = await cib(en.map(x => x.uid)); if (u) agir(c, "attaque", +u); } },
        { nom: "Se déplacer", txt: "vers un territoire voisin", f: async () => { const u = await cib([c.terr - 1, c.terr + 1].filter(t => t >= 0 && t < 3).map(t => "t" + t)); if (u) agir(c, "deplacer", +u.slice(1)); } },
        { nom: "Défendre", txt: "dégâts ÷2", f: () => agir(c, "defense") },
        { nom: k.pouvoir, txt: c.recharge ? `recharge ${c.recharge}` : k.txt, dispo: !c.recharge && (k.cible !== "ennemi" || en.length > 0), f: async () => {
          let u = null;
          if (k.cible === "ennemi") { u = await cib(en.map(x => x.uid)); if (!u) return; }
          if (k.cible === "allie") { u = await cib(vivants(J).filter(x => x !== c).map(x => x.uid)); if (!u) return; }
          agir(c, "pouvoir", u ? +u : null);
        } },
        { nom: "Évoluer", txt: c.stade >= 3 ? "forme ultime" : `Éveil ${c.eveil}/${seuil}`, dispo: c.stade < 3 && c.eveil >= seuil, f: () => agir(c, "evoluer") },
      ], () => { sel = null; rendre(); });
    }
    function cib(cands) { ctx.consigne("Touche la cible"); const p = choisir(cands); zPn.querySelector(".pn-annuler").onclick = () => annulerChoix(); return p; }
    function executer(c, t, u) {
      c.agi = true;
      if (c.st.gele) { delete c.st.gele; M.fx(c, "gelé", "mot"); return; }
      const cible = u != null ? tous().find(x => x.uid === u) : null;
      if (t === "ramasser") { const r = R.find(x => x.terr === c.terr); if (r && !c.relique) prendre(c, r); }
      if (t === "attaque") frapper(M, c, cible, 1);
      if (t === "deplacer") c.terr = u;
      if (t === "defense") { c.defend = true; M.fx(c, "en garde", "mot"); }
      if (t === "pouvoir") pouvoir(M, c, cible);
      if (t === "evoluer") { c.eveil -= SEUILS[c.stade - 1]; evoluer(M, c); }
      if (t !== "evoluer") c.eveil += c.relique === "orbe" ? 2 : 1;
    }
    function agir(c, t, u) { if (occupe) return; executer(c, t, u); sel = null; rendre(); fin(); }
    function compter(camp) { tenue[camp] = nb(camp) >= 2 ? tenue[camp] + 1 : 0; }
    async function finTour() {
      if (occupe) return; occupe = true; sel = null;
      compter("j"); rendre(); if (fin()) return;
      debutTour(M, "a"); for (const c of A) c.agi = false;
      await dodo(450); if (!ctx.vivant()) return;
      for (const c of vivants(A)) {
        if (c.ko) continue;
        const [t, u] = planIA(c); executer(c, t, u); rendre();
        await dodo(750); if (!ctx.vivant() || fin()) return;
      }
      compter("a"); rendre(); if (fin()) return;
      debutTour(M, "j"); for (const c of J) c.agi = false;
      tour++; occupe = false; rendre();
    }
    function planIA(c) {
      const ici = ciblesValides(J.filter(x => x.terr === c.terr));
      const sol = R.find(r => r.terr === c.terr);
      if (sol && !c.relique && !(ici.length && ici.some(x => x.pv > c.pv) && rng() < 0.3)) return ["ramasser"];
      if (c.stade < 3 && c.eveil >= SEUILS[c.stade - 1] && rng() < 0.7) return ["evoluer"];
      const porteur = ici.find(x => x.relique);
      if (porteur) return ["attaque", porteur.uid];
      const k = KITS[c.id];
      if (!c.recharge && (k.cible !== "ennemi" || ici.length) && valeurPouvoir(M, c) >= 5) return ["pouvoir", k.cible === "ennemi" ? ici[0].uid : k.cible === "allie" ? (vivants(A).filter(x => x !== c)[0] || c).uid : null];
      if (ici.length) return ["attaque", ici.sort((a, b) => a.pv - b.pv)[0].uid];
      // aller vers une relique au sol, ou vers un porteur ennemi
      const but = R.find(r => r.terr != null && Math.abs(r.terr - c.terr) === 1) || R.map(porteurDe).find(p => p && p.camp === "j" && Math.abs(p.terr - c.terr) === 1);
      if (but) return ["deplacer", but.terr];
      const cible = R.find(r => r.terr != null) || R.map(porteurDe).find(p => p && p.camp === "j");
      if (cible && cible.terr !== c.terr) return ["deplacer", c.terr + Math.sign(cible.terr - c.terr)];
      return ["defense"];
    }
    function fin() {
      if (fini) return true;
      let g = null, txt = "";
      if (tenue.j >= TENIR || !vivants(A).length) { g = true; txt = tenue.j >= TENIR ? `Tu as tenu 2 reliques pendant ${TENIR} tours.` : "Son équipe est tombée."; }
      else if (tenue.a >= TENIR || !vivants(J).length) { g = false; txt = tenue.a >= TENIR ? `Il a tenu 2 reliques pendant ${TENIR} tours.` : "Ton équipe est tombée."; }
      if (g === null) return false;
      fini = true; occupe = true; rendre(); ctx.fin({ titre: g ? "Victoire" : "Défaite", texte: txt, gagne: g });
      return true;
    }
    rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Trois reliques au centre. Cours les ramasser !" });
      await ctx.etape({ texte: "Le porteur devient fort… et tout le monde le vise." });
      await ctx.etape({ texte: "Tiens 2 reliques pendant 3 tours pour gagner." });
      ctx.tutoFini();
    })();
  }
  enregistrer({ groupe: "nouveaux", id: "reliques", num: "7", nom: "Conquête de reliques", accroche: "Mjölnir, le Masque, l'Orbe : prends-les, garde-les, vole les siennes.", duree: "5 min", images: ["thor-3", "kitsune-2", "cerbere-1"], fond: "linear-gradient(160deg,#2a2440,#141022)", lancer });
})();
