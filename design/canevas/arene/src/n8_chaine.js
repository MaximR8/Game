// ═════════════════════════════ N8 · CHAÎNE D'ÉVOLUTION ═════════════════════════════
// Chaque créature gagne de l'XP : attaque qui touche +1 · défense +1 · pouvoir +2 · K.O. +3.
// Le dilemme : dépenser tout de suite (Affûter +2 ATT, Endurcir +8 PV, 2 XP chacun)
// ou économiser pour évoluer (stade II : 6 XP, stade III : 10 XP). Les améliorations restent après l'évolution.
(function () {
  const EVO = [6, 10], AMEL = 2;
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const ids = tuto ? [["thor", "golem", "kitsune"], ["fenrir", "yeti", "minotaure"]] : (() => { const p = melanger([...ROSTER], rng); return [p.slice(0, 3), p.slice(3, 6)]; })();
    const J = ids[0].map(id => creer(id, "j")), A = ids[1].map(id => creer(id, "a"));
    [...J, ...A].forEach(c => { c.xp = 0; c.agi = false; });
    const style = rng() < 0.5 ? "patient" : "pressé";
    let tour = 1, sel = null, occupe = false, fini = false;
    const zA = h("div", "de-eq"), zLog = h("div", "jl"), zJ = h("div", "de-eq"), zPn = h("div", "pn");
    zLog.style.flex = "1"; zLog.style.display = "flex"; zLog.style.alignItems = "center"; zLog.style.justifyContent = "center";
    ctx.scene.append(h("div", "ce-style", `Son style : ${style === "patient" ? "il économise pour évoluer" : "il s'améliore tout de suite"}`), zA, zLog, zJ, zPn);
    const tous = () => [...J, ...A];
    const M = matchDe(ctx, zLog, {
      tous, adversaires: c => c.camp === "j" ? A : J, allies: c => c.camp === "j" ? J : A,
      hook(t, a, b, n) { if (t === "ko" && a && a.xp != null) { a.xp += 3; M.fx(a, "+3 XP", "or"); } },
    });
    const xpBloc = c => {
      const e = h("div", "ce-xp"), b = h("div", "ce-bar"), s = c.stade < 3 ? EVO[c.stade - 1] : 0;
      const i = h("i"); i.style.width = s ? Math.min(100, c.xp / s * 100) + "%" : "100%"; b.append(i);
      e.append(h("span", "", `${c.xp} XP${s ? ` · évolution à ${s}` : " · forme ultime"}`), b);
      if (c.bonusAtt || c.bonusPv) e.append(h("em", "", `améliorée : +${c.bonusAtt} ATT, +${c.bonusPv} PV`));
      return e;
    };
    function rendre() {
      ctx.scoreJA(vivants(J).length, vivants(A).length);
      zA.innerHTML = ""; A.forEach(c => zA.append(elCreature(c, { petit: true, extra: xpBloc(c) })));
      zJ.innerHTML = ""; J.forEach(c => zJ.append(elCreature(c, { petit: true, sel: sel === c, plan: c.agi ? "a agi" : "", extra: xpBloc(c), onclick: () => { if (!occupe && !c.ko) { sel = sel === c ? null : c; rendre(); } } })));
      if (fini) zPn.innerHTML = "";
      else if (occupe) { zPn.innerHTML = ""; ctx.consigne("Son tour…", "lui"); }
      else if (sel) actions(sel);
      else { panneau(zPn, `Touche une créature (${vivants(J).filter(c => !c.agi).length} peuvent agir)`, [{ nom: "Fin du tour", txt: "il joue ensuite", cls: "or", f: finTour }]); ctx.consigne(`Tour ${tour}`); }
      marquerCibles();
    }
    function apercu(c) { const x = { ...c, stade: c.stade + 1 }; recalc(x); return `ATT ${c.att}→${x.att}, PV ${c.max}→${x.max}`; }
    function actions(c) {
      const k = KITS[c.id], seuil = c.stade < 3 ? EVO[c.stade - 1] : 0, peut = !c.agi;
      panneau(zPn, `${nomDe(c.id)} · ${c.xp} XP${c.agi ? " · a déjà agi (tu peux encore dépenser)" : ""}`, [
        { nom: "Attaquer", txt: "+1 XP si ça touche", dispo: peut, f: async () => { const u = await cib(ciblesValides(A).map(x => x.uid)); if (u) agir(c, "attaque", +u); } },
        { nom: "Défendre", txt: "dégâts ÷2 · +1 XP", dispo: peut, f: () => agir(c, "defense") },
        { nom: k.pouvoir, txt: c.recharge ? `recharge ${c.recharge}` : `${k.txt} · +2 XP`, dispo: peut && !c.recharge, f: async () => {
          let u = null;
          if (k.cible === "ennemi") { u = await cib(ciblesValides(A).map(x => x.uid)); if (!u) return; }
          if (k.cible === "allie") { u = await cib(vivants(J).filter(x => x !== c).map(x => x.uid)); if (!u) return; }
          agir(c, "pouvoir", u ? +u : null);
        } },
        { nom: "Affûter", txt: `+2 ATT · ${AMEL} XP`, dispo: c.xp >= AMEL, f: () => depenser(c, "att") },
        { nom: "Endurcir", txt: `+8 PV · ${AMEL} XP`, dispo: c.xp >= AMEL, f: () => depenser(c, "pv") },
        { nom: "Évoluer", txt: c.stade >= 3 ? "forme ultime" : `${seuil} XP · ${apercu(c)}`, dispo: c.stade < 3 && c.xp >= seuil, cls: c.stade < 3 && c.xp >= seuil ? "or" : "", f: () => depenser(c, "evo") },
      ], () => { sel = null; rendre(); });
    }
    function cib(cands) { ctx.consigne("Touche la cible"); const p = choisir(cands); zPn.querySelector(".pn-annuler").onclick = () => annulerChoix(); return p; }
    // Dépenser l'XP ne coûte pas l'action.
    function depenser(c, t) {
      if (t === "att" && c.xp >= AMEL) { c.xp -= AMEL; c.bonusAtt += 2; recalc(c); M.fx(c, "+2 ATT", "vert"); }
      if (t === "pv" && c.xp >= AMEL) { c.xp -= AMEL; c.bonusPv += 8; recalc(c); c.pv = Math.min(c.max, c.pv + 8); M.fx(c, "+8 PV", "vert"); }
      if (t === "evo" && c.stade < 3 && c.xp >= EVO[c.stade - 1]) { c.xp -= EVO[c.stade - 1]; evoluer(M, c); }
      rendre();
    }
    function executer(c, t, u) {
      c.agi = true;
      if (c.st.gele) { delete c.st.gele; M.fx(c, "gelé", "mot"); return; }
      const cible = u != null ? tous().find(x => x.uid === u) : null;
      if (t === "attaque") { const d = frapper(M, c, cible, 1); if (d > 0) c.xp += 1; }
      if (t === "defense") { c.defend = true; c.xp += 1; M.fx(c, "en garde", "mot"); }
      if (t === "pouvoir") { pouvoir(M, c, cible); c.xp += 2; }
    }
    function agir(c, t, u) { if (occupe) return; executer(c, t, u); rendre(); fin(); }
    async function finTour() {
      if (occupe) return; occupe = true; sel = null; rendre();
      debutTour(M, "a"); for (const c of A) c.agi = false;
      await dodo(450); if (!ctx.vivant()) return;
      for (const c of vivants(A)) {
        if (c.ko) continue;
        depenseIA(c);
        const cibles = ciblesValides(J).sort((a, b) => a.pv - b.pv), k = KITS[c.id];
        if (!cibles.length) break;
        if (!c.recharge && (k.cible !== "ennemi" || cibles.length) && valeurPouvoir(M, c) >= 4) executer(c, "pouvoir", k.cible === "ennemi" ? cibles[0].uid : k.cible === "allie" ? (vivants(A).filter(x => x !== c)[0] || c).uid : null);
        else if (c.pv < c.max * 0.3 && rng() < 0.4) executer(c, "defense");
        else executer(c, "attaque", cibles[0].uid);
        depenseIA(c); rendre();
        await dodo(750); if (!ctx.vivant() || fin()) return;
      }
      debutTour(M, "j"); for (const c of J) c.agi = false;
      tour++; occupe = false; rendre(); fin();
    }
    function depenseIA(c) {
      if (c.ko) return;
      if (c.stade < 3 && c.xp >= EVO[c.stade - 1]) { c.xp -= EVO[c.stade - 1]; evoluer(M, c); return; }
      if (style === "pressé" || c.pv < c.max * 0.35) while (c.xp >= AMEL) { if (c.pv < c.max * 0.5) { c.xp -= AMEL; c.bonusPv += 8; recalc(c); c.pv = Math.min(c.max, c.pv + 8); } else { c.xp -= AMEL; c.bonusAtt += 2; recalc(c); } }
    }
    function fin() {
      if (fini) return true;
      if (!vivants(A).length || !vivants(J).length) {
        fini = true; occupe = true; rendre(); const g = !vivants(A).length;
        ctx.fin({ titre: g ? "Victoire" : "Défaite", texte: `${g ? "Son" : "Ton"} équipe tombe au tour ${tour}.`, gagne: g });
        return true;
      }
      return false;
    }
    rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Tes créatures gagnent de l'XP en se battant." });
      await ctx.etape({ texte: "Dépenser tout de suite, ou économiser pour évoluer ?" });
      await ctx.etape({ texte: "Dépenser l'XP ne coûte pas ton action." });
      ctx.tutoFini();
    })();
  }
  enregistrer({ groupe: "nouveaux", id: "chaine", num: "8", nom: "Chaîne d'évolution", accroche: "Plus fort maintenant, ou économiser pour évoluer ?", duree: "5 min", images: ["kitsune-1", "kitsune-2", "kitsune-3"], fond: "linear-gradient(160deg,#1c2a2a,#131022)", lancer });
})();
