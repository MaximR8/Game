// ═════════════════════════════ N3 · GUERRE DES ROYAUMES ═════════════════════════════
// 3 voies de 5 cases. On pose ses créatures sur sa première rangée, elles avancent, se battent,
// et frappent le sanctuaire adverse une fois arrivées au bout. Chaque action coûte 1 énergie.
(function () {
  const RANGS = 5, SANCT = 14;
  const CLASSE = { kitsune: "rapide", wukong: "rapide", fenrir: "rapide", minotaure: "rapide", golem: "tank", cerbere: "tank", doudou: "tank", thor: "distance", banshee: "distance", yeti: "controle", babayaga: "controle", bahamut: "support", quetzalcoatl: "support", anubis: "support" };
  const CL = {
    rapide: { nom: "Rapide", cout: 2, capa: "Percée", txt: "avance de 2 et frappe" },
    tank: { nom: "Tank", cout: 3, capa: "Bastion", txt: "+8 armure" },
    distance: { nom: "Distance", cout: 3, capa: "Tir lointain", txt: "frappe jusqu'à 3 cases" },
    controle: { nom: "Contrôle", cout: 2, capa: "Repousser", txt: "l'ennemi en face recule d'une case et gèle" },
    support: { nom: "Soutien", cout: 2, capa: "Soin", txt: "+12 PV à un allié tout proche" },
  };
  const portee = c => CLASSE[c.id] === "distance" ? 2 : 1;
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const parClasse = cl => ROSTER.filter(id => CLASSE[id] === cl);
    const deck = () => { const d = Object.keys(CL).map(cl => melanger(parClasse(cl), rng)[0]); const r = melanger(ROSTER.filter(x => CLASSE[x] && !d.includes(x)), rng)[0]; return [...d, r]; };
    const main = { j: tuto ? ["golem", "kitsune", "thor", "yeti", "bahamut", "fenrir"] : deck(), a: deck() };
    const sanct = { j: SANCT, a: SANCT }, en = { j: 0, a: 0 };
    let tour = 1, plateau = [], sel = null, selMain = null, occupe = false;
    const zSA = h("div", "gr-sanct a"), zGrille = h("div", "gr-grille"), zSJ = h("div", "gr-sanct j"), zLog = h("div", "jl"), zMain = h("div", "gr-main"), zPn = h("div", "pn");
    ctx.scene.append(zSA, zGrille, zSJ, zLog, zMain, zPn);
    const M = matchDe(ctx, zLog, {
      tous: () => plateau, adversaires: c => plateau.filter(x => x.camp !== c.camp && x.voie === c.voie), allies: c => plateau.filter(x => x.camp === c.camp && Math.abs(x.voie - c.voie) <= 1),
      hook(t, a, b) { if (t === "ko") plateau = plateau.filter(x => x !== b); },
    });
    const energieTour = () => Math.min(2 + tour, 6);
    const dir = c => c.camp === "j" ? 1 : -1;
    const bout = c => c.camp === "j" ? RANGS - 1 : 0;
    const en_ = (v, r) => plateau.find(x => x.voie === v && x.rang === r && !x.ko);
    function ennemisAPortee(c) {
      const res = [];
      for (let d = 1; d <= portee(c); d++) for (const s of [1, -1]) { const x = en_(c.voie, c.rang + s * d); if (x && x.camp !== c.camp) res.push(x); }
      return ciblesValides(res);
    }
    function rendre() {
      ctx.score.innerHTML = `<span class="sep">sanctuaires</span><span class="j">${sanct.j}</span><span class="sep">contre</span><span class="a">${sanct.a}</span>`;
      const barre = (z, camp) => { z.innerHTML = ""; const b = h("div", "gr-pv"), i = h("i"); i.style.width = sanct[camp] / SANCT * 100 + "%"; b.append(i); z.append(h("b", "", camp === "a" ? "Son sanctuaire" : "Ton sanctuaire"), b, h("span", "", `${sanct[camp]} / ${SANCT}`)); if (camp === "a") z.append(h("span", "gr-mainA", `${main.a.length} cartes · ${en.a} énergie`)); };
      barre(zSA, "a"); barre(zSJ, "j");
      zGrille.innerHTML = "";
      for (let r = RANGS - 1; r >= 0; r--) for (let v = 0; v < 3; v++) {
        const cell = h("div", "gr-case" + (r === 0 ? " maisonJ" : r === RANGS - 1 ? " maisonA" : "")); cell.dataset.cible = `c${v}-${r}`;
        const c = en_(v, r);
        if (c) {
          const e = elCreature(c, { petit: true, sel: sel === c, plan: CL[CLASSE[c.id]].nom + (c.agi ? " ✓" : ""), onclick: c.camp === "j" ? () => { if (!occupe) { sel = sel === c ? null : c; selMain = null; rendre(); } } : null });
          cell.append(e);
        }
        zGrille.append(cell);
      }
      zMain.innerHTML = "";
      main.j.forEach(id => {
        const cl = CL[CLASSE[id]], e = vignette(id, { stade: 1, cout: cl.cout, nom: false }); e.dataset.id = id;
        e.append(h("span", "gr-cl", cl.nom));
        if (cl.cout > en.j) e.classList.add("eteinte");
        if (selMain === id) e.classList.add("choisie");
        e.onclick = () => { if (occupe || Choix.cands) return; selMain = selMain === id ? null : id; sel = null; rendre(); if (selMain) poser(id); };
        zMain.append(e);
      });
      if (occupe) { zPn.innerHTML = ""; ctx.consigne("Son tour…", "lui"); }
      else if (sel) actions(sel);
      else if (!selMain) { panneau(zPn, `${en.j} énergie · pose une carte ou touche une créature`, [{ nom: "Fin du tour", txt: "il joue ensuite", cls: "or", f: finTour }]); ctx.consigne(`Tour ${tour}`); }
      marquerCibles();
    }
    async function poser(id) {
      const cl = CL[CLASSE[id]];
      if (cl.cout > en.j) { M.log(`${nomDe(id)} coûte ${cl.cout} énergie`); selMain = null; return rendre(); }
      const libres = [0, 1, 2].filter(v => !en_(v, 0)).map(v => `c${v}-0`);
      if (!libres.length) { M.log("Ta première rangée est pleine"); selMain = null; return rendre(); }
      panneau(zPn, `Pose ${nomDe(id)} : touche une case de ta première rangée`, [], () => annulerChoix());
      ctx.consigne("Touche une case en bas");
      const u = await choisir(libres); selMain = null;
      if (u) { const c = creer(id, "j"); c.voie = +u[1]; c.rang = 0; c.agi = true; c.neuf = true; plateau.push(c); en.j -= cl.cout; main.j.splice(main.j.indexOf(id), 1); M.log(`${nomDe(id)} arrive sur la voie`); }
      rendre();
    }
    function actions(c) {
      const cl = CL[CLASSE[c.id]], dispo = !c.agi && en.j >= 1, cibles = ennemisAPortee(c);
      const auBout = c.rang === bout(c);
      const devant = !en_(c.voie, c.rang + dir(c)) && !auBout;
      panneau(zPn, `${nomDe(c.id)} · ${cl.nom}${c.agi ? " · a déjà agi" : ""} · ${en.j} énergie`, [
        { nom: auBout ? "Frapper le sanctuaire" : "Avancer", txt: auBout ? `${2 + c.stade} dégâts` : devant ? "d'une case" : "la case est prise", dispo: dispo && (auBout || devant), cls: auBout ? "or" : "", f: () => agir(c, auBout ? "sanct" : "avancer") },
        { nom: "Attaquer", txt: cibles.length ? `portée ${portee(c)}` : "personne à portée", dispo: dispo && cibles.length > 0, f: async () => { const u = await cib(cibles.map(x => x.uid)); if (u) agir(c, "attaque", +u); } },
        { nom: "Défendre", txt: "dégâts ÷2", dispo, f: () => agir(c, "defense") },
        { nom: cl.capa, txt: c.recharge ? `recharge ${c.recharge}` : cl.txt, dispo: dispo && !c.recharge, f: async () => {
          let u = null;
          if (CLASSE[c.id] === "support") { const al = plateau.filter(x => x.camp === "j" && Math.abs(x.voie - c.voie) + Math.abs(x.rang - c.rang) <= 1); u = await cib(al.map(x => x.uid)); if (!u) return; }
          agir(c, "capa", u ? +u : null);
        } },
        { nom: "Évoluer", txt: c.stade >= 3 ? "forme ultime" : c.neuf ? "au prochain tour" : "3 énergie", dispo: !c.agi && !c.neuf && c.stade < 3 && en.j >= 3, f: () => agir(c, "evoluer") },
      ], () => { sel = null; rendre(); });
    }
    function cib(cands) { ctx.consigne("Touche la cible"); const p = choisir(cands); zPn.querySelector(".pn-annuler").onclick = () => annulerChoix(); return p; }
    function executer(c, t, u) {
      const camp = c.camp;
      if (c.st.gele) { delete c.st.gele; c.agi = true; M.fx(c, "gelé", "mot"); return; }
      en[camp] -= t === "evoluer" ? 3 : 1; c.agi = true;
      if (t === "avancer") c.rang += dir(c);
      if (t === "sanct") { const d = 2 + c.stade; sanct[autre(camp)] -= d; flotSur(camp === "j" ? zSA : zSJ, `−${d}`, "gros", 0.5); M.log(`${nomDe(c.id)} frappe le sanctuaire : −${d}`); }
      if (t === "attaque") frapper(M, c, plateau.find(x => x.uid === u), 1);
      if (t === "defense") c.defend = true;
      if (t === "evoluer") evoluer(M, c);
      if (t === "capa") {
        const cl = CLASSE[c.id]; c.recharge = 2; M.fx(c, CL[cl].capa, "mot");
        if (cl === "rapide") { for (let k = 0; k < 2; k++) { const r = c.rang + dir(c); if (r >= 0 && r < RANGS && !en_(c.voie, r)) c.rang = r; } const e = ennemisAPortee(c)[0]; if (e) frapper(M, c, e, 1); }
        if (cl === "tank") c.armure += 8;
        if (cl === "distance") { let e = null; for (let d = 1; d <= 3 && !e; d++) { const x = en_(c.voie, c.rang + dir(c) * d); if (x && x.camp !== camp) e = x; } if (e) frapper(M, c, e, 1.2); else M.log("Personne à 3 cases"); }
        if (cl === "controle") { const e = en_(c.voie, c.rang + dir(c)); if (e && e.camp !== camp) { const r = e.rang + dir(c); if (r >= 0 && r < RANGS && !en_(e.voie, r)) e.rang = r; e.st.gele = true; M.fx(e, "repoussé, gelé", "mot"); } }
        if (cl === "support") { const x = plateau.find(y => y.uid === u); if (x) soigner(M, x, 12); }
      }
    }
    function agir(c, t, u) { if (occupe) return; executer(c, t, u); sel = null; rendre(); fin(); }
    function debut(camp) { debutTour(M, camp); for (const c of plateau.filter(x => x.camp === camp)) { c.agi = false; c.neuf = false; } en[camp] = energieTour(); }
    async function finTour() {
      if (occupe) return; occupe = true; sel = null; rendre();
      debut("a"); await dodo(500); if (!ctx.vivant()) return;
      await tourIA(); if (!ctx.vivant() || fin()) return;
      tour++; debut("j"); occupe = false; rendre();
    }
    async function tourIA() {
      const pas = async () => { rendre(); await dodo(550); return ctx.vivant(); };
      // 1. poser, sur la voie la plus menacée
      const pression = v => plateau.filter(x => x.camp === "j" && x.voie === v).reduce((s, x) => s + x.rang + 1, 0);
      for (let essai = 0; essai < 3; essai++) {
        const abord = main.a.filter(id => CL[CLASSE[id]].cout <= en.a - 1).sort((x, y) => CL[CLASSE[y]].cout - CL[CLASSE[x]].cout);
        const voies = [0, 1, 2].filter(v => !en_(v, RANGS - 1)).sort((x, y) => pression(y) - pression(x) + (rng() - 0.5));
        if (!abord.length || !voies.length || (plateau.filter(x => x.camp === "a").length >= 3 && rng() < 0.5)) break;
        const id = pression(voies[0]) > 0 && abord.find(x => CLASSE[x] === "tank") ? abord.find(x => CLASSE[x] === "tank") : abord[0];
        const c = creer(id, "a"); c.voie = voies[0]; c.rang = RANGS - 1; c.agi = true; c.neuf = true; plateau.push(c); en.a -= CL[CLASSE[id]].cout; main.a.splice(main.a.indexOf(id), 1);
        M.log(`Il pose ${nomDe(id)}`); if (!(await pas())) return;
      }
      // 2. agir, les plus avancés d'abord
      for (const c of plateau.filter(x => x.camp === "a" && !x.agi).sort((x, y) => x.rang - y.rang)) {
        if (en.a < 1 || c.ko) break;
        if (c.st.gele) { executer(c, "attaque"); continue; }
        const cibles = ennemisAPortee(c).sort((x, y) => x.pv - y.pv);
        if (c.rang === 0) executer(c, "sanct");
        else if (!c.neuf && c.stade < 3 && en.a >= 4 && rng() < 0.35) executer(c, "evoluer");
        else if (!c.recharge && CLASSE[c.id] !== "support" && (cibles.length || CLASSE[c.id] === "rapide") && rng() < 0.4) executer(c, "capa");
        else if (cibles.length) executer(c, "attaque", cibles[0].uid);
        else if (!en_(c.voie, c.rang - 1)) executer(c, "avancer");
        else executer(c, "defense");
        if (!(await pas()) || fin()) return;
      }
    }
    function fin() {
      if (sanct.a <= 0) { occupe = true; ctx.fin({ titre: "Victoire", texte: `Son sanctuaire tombe au tour ${tour}.`, gagne: true }); return true; }
      if (sanct.j <= 0) { occupe = true; ctx.fin({ titre: "Défaite", texte: `Ton sanctuaire tombe au tour ${tour}.`, gagne: false }); return true; }
      return false;
    }
    debut("j"); rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Pose tes créatures sur ta rangée du bas." });
      await ctx.etape({ texte: "Elles avancent, se battent, puis frappent son sanctuaire." });
      await ctx.etape({ texte: "Chaque action coûte 1 énergie. Détruis son sanctuaire !" });
      ctx.tutoFini();
    })();
  }
  enregistrer({ groupe: "nouveaux", id: "royaumes", num: "3", nom: "Guerre des Royaumes", accroche: "Trois voies, des créatures qui avancent. Prends son sanctuaire.", duree: "6 min", images: ["golem-1", "kitsune-2", "thor-1"], fond: "linear-gradient(160deg,#2a2716,#131022)", lancer });
})();
