// ═════════════════════════════ N2 · MYTHE CONTRE MYTHE ═════════════════════════════
// On compose son équipe (3 parmi 6), puis un combat façon RPG : à chaque tour, UNE créature, UNE action.
// Avant / arrière : on n'attaque que les créatures de devant (s'il y en a). Derrière, on frappe à ×0,6.
// Évoluer demande de l'Éveil (+1 quand elle agit, +1 quand elle encaisse) : 4 pour le stade II, 8 pour le III.
(function () {
  const SYNERGIES = [
    [["bahamut", "thor"], "Bahamut Mouille, Thor frappe double les Mouillés"],
    [["yeti", "fenrir"], "Yéti Gèle, Fenrir frappe ×1,5 les Gelés"],
    [["kitsune", "minotaure"], "Kitsune Marque, la Charge du Minotaure en profite"],
    [["kitsune", "thor"], "Kitsune Marque, Mjöllnir en profite"],
    [["quetzalcoatl", "wukong"], "Quetzalcoatl donne +ATT, Wukong frappe 3 fois"],
    [["anubis", "minotaure"], "Le Minotaure se blesse, Anubis le ramène"],
    [["doudou", "kitsune"], "El Biète protège la fragile Kitsune"],
    [["golem", "babayaga"], "Le Golem attire les coups, Baba Yaga maudit tranquille"],
    [["cerbere", "banshee"], "Cerbère contre-attaque, la Banshee affaiblit en face"],
    [["banshee", "golem"], "La Banshee affaiblit, le Golem tient"],
  ];
  const SEUILS = [4, 8];
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const offre = tuto ? ["bahamut", "thor", "golem", "yeti", "fenrir", "kitsune"] : melanger([...ROSTER], rng).slice(0, 6);
    let J = [], A = [], phase = "draft", choisis = [], sel = null, tour = 1, occupe = false;
    const zHaut = h("div", "my-eq"), zMil = h("div", "jl"), zBas = h("div", "my-eq"), zPn = h("div", "pn");
    ctx.scene.append(zHaut, zMil, zBas, zPn);
    const tous = () => [...J, ...A];
    const M = matchDe(ctx, zMil, {
      tous, adversaires: c => c.camp === "j" ? A : J, allies: c => c.camp === "j" ? J : A,
      hook(t, a, b, n) { if (t === "degats") { if (a) a.eveil += 1; if (b && !b.ko) b.eveil += 1; } },
    });
    // ——— la composition ———
    function draft() {
      zHaut.innerHTML = ""; zBas.innerHTML = "";
      ctx.consigne(`Compose ton équipe : ${choisis.length} / 3`);
      const g = h("div", "my-draft");
      for (const id of offre) {
        const b = h("button", "my-offre" + (choisis.includes(id) ? " pris" : ""));
        b.append(vignette(id, { stade: 1, nom: false }));
        const t = h("div", "my-otxt"); t.append(h("b", "", `${nomDe(id)} · ${KITS[id].role}`), h("span", "", `${KITS[id].pouvoir} : ${KITS[id].txt}`));
        b.append(t);
        b.onclick = () => { if (choisis.includes(id)) choisis = choisis.filter(x => x !== id); else if (choisis.length < 3) choisis.push(id); draft(); };
        g.append(b);
      }
      zHaut.append(g);
      const syn = SYNERGIES.filter(([p]) => p.every(x => offre.includes(x)));
      const zs = h("div", "my-syn"); zs.append(h("b", "", "Des duos qui marchent ici :"));
      for (const [p, t] of syn) { const e = h("div", p.every(x => choisis.includes(x)) ? "ok" : "", t); zs.append(e); }
      if (!syn.length) zs.append(h("div", "", "À toi de les trouver."));
      zBas.append(zs);
      panneau(zPn, "", [{ nom: "Au combat", txt: choisis.length === 3 ? "ton équipe est prête" : "choisis 3 créatures", cls: "or", dispo: choisis.length === 3, f: commencer }]);
    }
    function commencer() {
      J = choisis.map(id => creer(id, "j"));
      const reste = melanger(ROSTER.filter(x => !choisis.includes(x)), rng);
      const duo = SYNERGIES.find(([p]) => p.every(x => reste.includes(x)));
      const idsA = duo ? [...duo[0], reste.find(x => !duo[0].includes(x))] : reste.slice(0, 3);
      A = idsA.map(id => creer(id, "a"));
      for (const eq of [J, A]) eq.forEach((c, i) => { c.eveil = 0; c.pos = KITS[c.id].role === "Soutien" || KITS[c.id].role === "Sorcière" || KITS[c.id].role === "Nécromancien" || KITS[c.id].role === "Hurleuse" || KITS[c.id].role === "Chef" ? "arriere" : "avant"; });
      for (const eq of [J, A]) if (!eq.some(c => c.pos === "avant")) eq[0].pos = "avant";
      phase = "combat"; rendre();
      if (tuto) (async () => {
        await ctx.etape({ texte: "À chaque tour : UNE créature, UNE action." });
        await ctx.etape({ texte: "On ne frappe que ceux de devant. Derrière, on est à l'abri." });
        await ctx.etape({ texte: "Agis et encaisse pour gagner l'Éveil : 4 pour évoluer." });
        ctx.tutoFini();
      })();
    }
    const devant = eq => { const v = vivants(eq), d = v.filter(c => c.pos === "avant"); return d.length ? d : v; };
    function rendreEq(z, eq, camp) {
      z.innerHTML = "";
      for (const pos of ["arriere", "avant"]) {
        const r = h("div", "my-rang " + pos); r.append(h("span", "my-lib", pos === "avant" ? "devant" : "derrière"));
        const liste = eq.filter(c => c.pos === pos);
        for (const c of liste) {
          const ex = h("div", "my-eveil"); const b = h("i"); b.style.width = Math.min(100, c.eveil / SEUILS[Math.min(c.stade - 1, 1)] * 100) + "%"; ex.append(b); ex.title = "Éveil";
          r.append(elCreature(c, { petit: true, sel: sel === c, extra: c.stade < 3 ? ex : null, onclick: camp === "j" ? () => { if (!occupe) { sel = sel === c ? null : c; rendre(); } } : null }));
        }
        z.append(r);
      }
      if (camp === "j") z.append(z.firstChild); // devant en haut pour toi : face à l'ennemi
    }
    function rendre() {
      if (phase === "draft") return draft();
      ctx.scoreJA(vivants(J).length, vivants(A).length);
      rendreEq(zHaut, A, "a"); rendreEq(zBas, J, "j");
      if (occupe) { zPn.innerHTML = ""; ctx.consigne("Son tour…", "lui"); }
      else if (!sel) { panneau(zPn, "Touche une de tes créatures", []); ctx.consigne(`Tour ${tour} : choisis une créature`); }
      else actions(sel);
      marquerCibles();
    }
    function actions(c) {
      const k = KITS[c.id], seuil = SEUILS[c.stade - 1];
      const cibles = ciblesValides(devant(A));
      panneau(zPn, `${nomDe(c.id)} · ${forme(c)} · Éveil ${c.eveil}${c.stade < 3 ? "/" + seuil : ""}`, [
        { nom: "Attaque", txt: c.pos === "avant" ? "un ennemi de devant" : "à distance, ×0,6", f: async () => { const u = await cible(cibles.map(x => x.uid)); if (u) agir(c, "attaque", +u); } },
        { nom: k.pouvoir, txt: c.recharge ? `recharge ${c.recharge}` : k.txt, dispo: !c.recharge, f: async () => {
          let u = null;
          if (k.cible === "ennemi") { u = await cible(ciblesValides(A).map(x => x.uid)); if (!u) return; }
          if (k.cible === "allie") { u = await cible(vivants(J).filter(x => x !== c).map(x => x.uid)); if (!u) return; }
          agir(c, "pouvoir", u ? +u : null);
        } },
        { nom: "Défense", txt: "dégâts ÷2 jusqu'à ton prochain tour", f: () => agir(c, "defense") },
        { nom: c.pos === "avant" ? "Reculer" : "Avancer", txt: c.pos === "avant" ? "à l'abri, derrière" : "devant, pour frapper fort", f: () => agir(c, "position") },
        { nom: "Évoluer", txt: c.stade >= 3 ? "forme ultime" : `Éveil ${c.eveil}/${seuil}`, dispo: c.stade < 3 && c.eveil >= seuil, cls: c.stade < 3 && c.eveil >= seuil ? "or" : "", f: () => agir(c, "evoluer") },
      ], () => { sel = null; rendre(); });
    }
    function cible(cands) { ctx.consigne("Touche la cible"); const p = choisir(cands); zPn.querySelector(".pn-annuler").onclick = () => annulerChoix(); return p; }
    async function executer(c, t, u) {
      const cib = u != null ? tous().find(x => x.uid === u) : null;
      if (c.st.gele) { delete c.st.gele; M.fx(c, "gelé : tour perdu", "mot"); M.log(`${nomDe(c.id)} est gelé`); return; }
      c.eveil += 1;
      if (t === "attaque") frapper(M, c, cib, c.pos === "avant" ? 1 : 0.6);
      if (t === "pouvoir") pouvoir(M, c, cib);
      if (t === "defense") { c.defend = true; M.fx(c, "en garde", "mot"); }
      if (t === "position") { const eq = c.camp === "j" ? J : A; if (c.pos === "avant" && vivants(eq).filter(x => x.pos === "avant").length <= 1) { M.log("Il faut quelqu'un devant"); } else c.pos = c.pos === "avant" ? "arriere" : "avant"; }
      if (t === "evoluer") { c.eveil -= SEUILS[c.stade - 1]; evoluer(M, c); }
      for (const eq of [J, A]) if (!vivants(eq).some(x => x.pos === "avant") && vivants(eq).length) vivants(eq)[0].pos = "avant";
    }
    async function agir(c, t, u) {
      if (occupe) return;
      occupe = true; sel = null;
      await executer(c, t, u); rendre();
      await dodo(700); if (!ctx.vivant()) return;
      if (fin()) return;
      debutTour(M, "a"); rendre(); await dodo(300);
      const [ca, ta, ua] = planIA();
      if (ca) { M.log(`${nomDe(ca.id)} agit`); await executer(ca, ta, ua); }
      rendre(); await dodo(700); if (!ctx.vivant()) return;
      if (fin()) return;
      debutTour(M, "j"); tour++; occupe = false; rendre();
      if (fin()) return;
    }
    function planIA() {
      let best = null;
      const add = (c, t, u, v) => { v += rng() * 1.5; if (!best || v > best[3]) best = [c, t, u, v]; };
      for (const c of vivants(A)) {
        if (c.st.gele) { add(c, "attaque", null, -5); continue; }
        const cibles = ciblesValides(devant(J)).sort((a, b) => a.pv - b.pv);
        if (cibles[0]) add(c, "attaque", cibles[0].uid, 3 + (cibles[0].pv <= attaqueDe(c) ? 5 : 0) + (typeMult(c, cibles[0]) > 1 ? 2 : 0) - (c.pos === "arriere" ? 1.5 : 0));
        if (c.stade < 3 && c.eveil >= SEUILS[c.stade - 1]) add(c, "evoluer", null, 8);
        const k = KITS[c.id];
        if (!c.recharge) { const cib = k.cible === "ennemi" ? ciblesValides(J).sort((a, b) => a.pv - b.pv)[0] : k.cible === "allie" ? vivants(A).filter(x => x !== c).sort((a, b) => a.pv / a.max - b.pv / b.max)[0] : null; if (k.cible !== "ennemi" || cib) add(c, "pouvoir", cib ? cib.uid : null, valeurPouvoir(M, c)); }
        if (c.pv < c.max * 0.35) add(c, c.pos === "avant" && vivants(A).filter(x => x.pos === "avant").length > 1 ? "position" : "defense", null, 4);
      }
      return best || [];
    }
    function fin() {
      if (!vivants(A).length) { ctx.fin({ titre: "Victoire", texte: `Son équipe est tombée en ${tour} tours.`, gagne: true }); return true; }
      if (!vivants(J).length) { ctx.fin({ titre: "Défaite", texte: `Ton équipe est tombée en ${tour} tours.`, gagne: false }); return true; }
      return false;
    }
    draft();
    if (tuto) ctx.etape({ texte: "Compose une équipe de 3 qui va bien ensemble." });
  }
  enregistrer({ groupe: "nouveaux", id: "mythe", num: "2", nom: "Mythe contre Mythe", accroche: "Compose ton équipe, combine les pouvoirs, fais évoluer en plein combat.", duree: "5 min", images: ["bahamut-1", "thor-2", "yeti-3"], fond: "linear-gradient(160deg,#2a1f45,#141022)", lancer });
})();
