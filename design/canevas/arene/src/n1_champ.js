// ═════════════════════════════ N1 · CHAMP DES LÉGENDES ═════════════════════════════
// 3 contre 3 sur 3 territoires. Chaque tour, un ordre SECRET par créature, révélés en même temps.
// Une attaque ne touche que si la cible est encore sur le même territoire (elle a pu partir !).
// Défendre : dégâts ÷2 et riposte. Évoluer : +points, mais on encaisse ×1,5 ce tour-là.
// Points de Légende : territoire tenu +1 · créature vaincue +2 · évolution +1 (II) / +2 (III) · présage du tour.
(function () {
  const BUT = 10;
  const TERRES = ["Valhalla", "Brocéliande", "Mont Huaguo"];
  const PRESAGES = [
    { id: "centre", txt: "Présage : Brocéliande vaut 2 points ce tour" },
    { id: "sang", txt: "Présage : chaque créature vaincue vaut 1 point de plus" },
    { id: "eveil", txt: "Présage : chaque évolution vaut 1 point de plus" },
    { id: "deux", txt: "Présage : tenir 2 territoires rapporte 1 point de plus" },
  ];
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const ids = tuto ? [["thor", "golem", "kitsune"], ["yeti", "fenrir", "bahamut"]] : (() => { const p = melanger([...ROSTER], rng); return [p.slice(0, 3), p.slice(3, 6)]; })();
    const J = ids[0].map(id => creer(id, "j")), A = ids[1].map(id => creer(id, "a"));
    [...J, ...A].forEach((c, i) => { c.terr = i % 3; c.maison = i % 3; c.eveil = 0; });
    const pts = { j: 0, a: 0 };
    let tour = 1, plans = {}, sel = null, phase = "plan", presage = PRESAGES[Math.floor(rng() * PRESAGES.length)], revele = false;

    const zPres = h("div", "ch-pres"), zTerres = h("div", "cols3 ch-terres"), zLog = h("div", "jl"), zPn = h("div", "pn");
    ctx.scene.append(zPres, zTerres, zLog, zPn);
    const tous = () => [...J, ...A];
    const M = matchDe(ctx, zLog, {
      tous, adversaires: c => (c.camp === "j" ? A : J).filter(x => x.terr === c.terr), allies: c => c.camp === "j" ? J : A,
      hook(t, a, b, n) {
        if (t === "ko" && a) { const g = presage.id === "sang" ? 3 : 2; pts[a.camp] += g; M.fx(b, `+${g} Légende`, "or"); }
        if (t === "degats" && a && n > 0) a.eveil = (a.eveil || 0) + 1;
      },
    });
    const txtPlan = p => !p ? "" : p.t === "attaque" ? `Attaque ${nomDe(tous().find(x => x.uid === p.c).id)}` : p.t === "defense" ? "Défend" : p.t === "deplacer" ? `→ ${TERRES[p.c]}` : p.t === "pouvoir" ? KITS[p.u.id].pouvoir : "Évolue";
    function rendre() {
      ctx.scoreJA(pts.j, pts.a);
      zPres.textContent = presage.txt + ` · premier à ${BUT}`;
      zTerres.innerHTML = "";
      TERRES.forEach((nom, t) => {
        const col = h("div", "ch-terre"); const cA = h("div", "ch-camp"), cJ = h("div", "ch-camp");
        for (const c of A.filter(x => x.terr === t)) cA.append(elCreature(c, { petit: true, plan: revele && plans[c.uid] ? txtPlan(plans[c.uid]) : (phase === "plan" && !c.ko ? "?" : "") }));
        for (const c of J.filter(x => x.terr === t)) cJ.append(elCreature(c, { petit: true, sel: sel === c, plan: plans[c.uid] ? txtPlan(plans[c.uid]) : "", onclick: () => choisirCreature(c) }));
        const tete = h("div", "ch-nom"); tete.dataset.cible = "t" + t;
        const nj = J.filter(x => x.terr === t && !x.ko).length, na = A.filter(x => x.terr === t && !x.ko).length;
        tete.append(h("b", "", nom), h("span", nj > na ? "j" : na > nj ? "a" : "", nj > na ? "à toi" : na > nj ? "à lui" : "disputé"));
        col.append(cA, tete, cJ); zTerres.append(col);
      });
      if (phase === "plan") {
        if (sel) actions(sel);
        else {
          const n = J.filter(c => !c.ko && plans[c.uid]).length, tot = J.filter(c => !c.ko).length;
          panneau(zPn, `Ordres donnés : ${n} / ${tot} — touche une de tes créatures`, [{ nom: "Révéler", txt: n < tot ? "sans ordre, elles défendent" : "on retourne tout", cls: "or", f: reveler }]);
        }
        ctx.consigne(`Tour ${tour} : ordres secrets`);
      }
      marquerCibles();
    }
    function choisirCreature(c) { if (phase !== "plan" || c.ko) return; sel = sel === c ? null : c; rendre(); }
    function actions(c) {
      const ennemis = ciblesValides(A.filter(x => x.terr === c.terr));
      const k = KITS[c.id];
      panneau(zPn, `${nomDe(c.id)} · ${forme(c)} · Éveil ${c.eveil}/3`, [
        { nom: "Attaquer", txt: ennemis.length ? "un ennemi sur ce territoire" : "personne ici", dispo: ennemis.length > 0, f: async () => { const u = await choixCible(ennemis.map(x => x.uid)); if (u) poserPlan(c, { t: "attaque", c: +u }); } },
        { nom: "Défendre", txt: "dégâts ÷2, riposte", f: () => poserPlan(c, { t: "defense" }) },
        { nom: "Se déplacer", txt: "vers un autre territoire", f: async () => { const u = await choixCible([0, 1, 2].filter(t => t !== c.terr).map(t => "t" + t)); if (u) poserPlan(c, { t: "deplacer", c: +u.slice(1) }); } },
        { nom: k.pouvoir, txt: c.recharge ? `recharge : ${c.recharge} tour(s)` : k.txt, dispo: !c.recharge && (k.cible !== "ennemi" || ennemis.length > 0), f: async () => {
          let u = null;
          if (k.cible === "ennemi") { u = await choixCible(ennemis.map(x => x.uid)); if (!u) return; }
          if (k.cible === "allie") { u = await choixCible(J.filter(x => !x.ko && x !== c).map(x => x.uid)); if (!u) return; }
          poserPlan(c, { t: "pouvoir", c: u ? +u : null, u: c });
        } },
        { nom: "Évoluer", txt: c.stade >= 3 ? "forme ultime" : c.eveil >= 3 ? "+points, mais ×1,5 dégâts reçus ce tour" : `Éveil ${c.eveil}/3`, dispo: c.stade < 3 && c.eveil >= 3, f: () => poserPlan(c, { t: "evoluer" }) },
      ], () => { sel = null; rendre(); });
    }
    function choixCible(cands) { ctx.consigne("Touche la cible"); const p = choisir(cands); marquerCibles(); zPn.querySelector(".pn-annuler").onclick = () => annulerChoix(); return p; }
    function poserPlan(c, p) { p.u = c; plans[c.uid] = p; sel = J.find(x => !x.ko && !plans[x.uid]) || null; rendre(); }
    // L'IA : elle voit le plateau d'avant le tour, pas tes ordres.
    function planIA() {
      for (const c of A.filter(x => !x.ko)) {
        const en = ciblesValides(J.filter(x => x.terr === c.terr)), opts = [];
        const faible = en.slice().sort((a, b) => a.pv - b.pv)[0];
        if (faible) opts.push([{ t: "attaque", c: faible.uid }, 4 + (faible.pv < attaqueDe(c) * 1.5 ? 4 : 0)]);
        opts.push([{ t: "defense" }, en.length ? 2.5 : 0.5]);
        if (c.stade < 3 && c.eveil >= 3) opts.push([{ t: "evoluer" }, en.length ? 2.5 : 6]);
        const k = KITS[c.id];
        if (!c.recharge && (k.cible !== "ennemi" || faible)) opts.push([{ t: "pouvoir", c: k.cible === "ennemi" ? faible.uid : k.cible === "allie" ? (A.filter(x => !x.ko && x !== c).sort((a, b) => a.pv / a.max - b.pv / b.max)[0] || c).uid : null }, valeurPouvoir(M, c) * 0.8]);
        for (let t = 0; t < 3; t++) if (t !== c.terr) { const na = A.filter(x => x.terr === t && !x.ko).length, nj = J.filter(x => x.terr === t && !x.ko).length; opts.push([{ t: "deplacer", c: t }, nj >= na ? 1.5 + (presage.id === "centre" && t === 1 ? 2 : 0) : 0.4]); }
        const tot = opts.reduce((s, o) => s + o[1], 0); let r = rng() * tot, choix = opts[0][0];
        for (const [o, w] of opts) { r -= w; if (r <= 0) { choix = o; break; } }
        choix.u = c; plans[c.uid] = choix;
      }
    }
    async function reveler() {
      phase = "resolution"; sel = null;
      for (const c of J) if (!c.ko && !plans[c.uid]) plans[c.uid] = { t: "defense", u: c };
      planIA(); revele = true;
      ctx.consigne("On révèle !", "calme"); zPn.innerHTML = ""; rendre();
      await dodo(1400); if (!ctx.vivant()) return;
      const ps = Object.values(plans);
      for (const p of ps) if (p.u.st.gele) { p.gele = true; delete p.u.st.gele; M.fx(p.u, "gelé : il ne fait rien", "mot"); }
      const de = t => ps.filter(p => p.t === t && !p.u.ko && !p.gele);
      for (const p of de("deplacer")) { p.u.terr = p.c; } if (de("deplacer").length) { M.log("Les déplacements"); rendre(); await dodo(700); }
      for (const p of de("defense")) p.u.defend = true;
      for (const p of de("evoluer")) p.u.vulnerable = true;
      for (const p of ps.filter(p => p.t === "pouvoir")) {
        if (p.u.ko || p.gele) continue;
        const cible = p.c != null ? tous().find(x => x.uid === p.c) : null;
        if (KITS[p.u.id].cible === "ennemi" && (!cible || cible.ko || cible.terr !== p.u.terr)) { M.log(`${nomDe(p.u.id)} : sa cible est partie`); M.fx(p.u, "raté !", "mot"); await dodo(700); continue; }
        pouvoir(M, p.u, cible); rendre(); await dodo(900); if (!ctx.vivant()) return;
      }
      for (const p of de("attaque")) {
        const cible = tous().find(x => x.uid === p.c);
        if (!cible || cible.ko || cible.terr !== p.u.terr) { M.log(`${nomDe(p.u.id)} frappe dans le vide : ${cible ? nomDe(cible.id) + " est parti" : "plus personne"}`); M.fx(p.u, "dans le vide !", "mot"); rendre(); await dodo(900); continue; }
        const k = cible.vulnerable ? 1.5 : 1;
        frapper(M, p.u, cible, k);
        if (cible.defend && !cible.ko && !p.u.ko) { blesser(M, p.u, 3, cible); M.log(`${nomDe(cible.id)} défendait : riposte`); }
        rendre(); await dodo(850); if (!ctx.vivant()) return;
      }
      for (const p of de("evoluer")) { if (evoluer(M, p.u)) { const g = (p.u.stade === 3 ? 2 : 1) + (presage.id === "eveil" ? 1 : 0); p.u.eveil = 0; pts[p.u.camp] += g; M.fx(p.u, `+${g} Légende`, "or"); rendre(); await dodo(800); } }
      // contrôle
      let tj = 0, ta = 0;
      for (let t = 0; t < 3; t++) {
        const nj = J.filter(x => x.terr === t && !x.ko).length, na = A.filter(x => x.terr === t && !x.ko).length, v = presage.id === "centre" && t === 1 ? 2 : 1;
        if (nj > na) { pts.j += v; tj++; } else if (na > nj) { pts.a += v; ta++; }
      }
      if (presage.id === "deux") { if (tj >= 2) pts.j++; if (ta >= 2) pts.a++; }
      M.log(`Territoires : ${tj} à toi, ${ta} à lui`);
      // fin de tour : les vaincus reviennent chez eux, au stade I
      for (const c of tous()) {
        c.vulnerable = false; c.eveil = (c.eveil || 0) + 1;
        if (c.ko) { const n = creer(c.id, c.camp); Object.assign(c, { ...n, uid: c.uid, terr: c.maison, maison: c.maison, eveil: 0 }); }
      }
      debutTour(M, "j"); debutTour(M, "a");
      plans = {}; revele = false; rendre();
      if (pts.j >= BUT || pts.a >= BUT) {
        if (pts.j !== pts.a) return ctx.fin({ titre: pts.j > pts.a ? "Victoire" : "Défaite", texte: `${pts.j} points de Légende contre ${pts.a}, en ${tour} tours.`, gagne: pts.j > pts.a });
      }
      tour++; presage = PRESAGES[Math.floor(rng() * PRESAGES.length)]; phase = "plan"; rendre();
    }
    rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Donne un ordre secret à chacune de tes 3 créatures." });
      await ctx.etape({ texte: "Il fait pareil. Tout se révèle en même temps." });
      await ctx.etape({ texte: "Attaquer ? S'il part, tu frappes dans le vide. Bluffe !" });
      await ctx.etape({ texte: "Tiens les territoires : premier à 10 points." });
      ctx.tutoFini();
    })();
  }
  enregistrer({ groupe: "nouveaux", id: "champ", num: "1", nom: "Champ des Légendes", accroche: "Ordres secrets, révélés en même temps. Bluffe pour tenir les territoires.", duree: "5 min", images: ["thor-1", "yeti-1", "kitsune-1"], fond: "linear-gradient(160deg,#1f2a4a,#141024)", lancer });
})();
