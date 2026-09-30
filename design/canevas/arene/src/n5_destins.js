// ═════════════════════════════ N5 · DESTINS CROISÉS ═════════════════════════════
// Pas de mana : une jauge de Destin (0 → 10) par joueur. Chaque action la fait monter de 1 (+1 par K.O.).
// Plus elle est haute, plus on débloque : 4 = pouvoirs · 6 = évolution II (coûte 3) · 7 = Assaut (coûte 2)
// · 10 = évolution III ou Ultime (coûte tout). Chaque créature agit une fois par tour.
(function () {
  const PALIERS = [[0, "attaque, garde"], [4, "pouvoirs"], [6, "évolution II"], [7, "Assaut du Destin"], [10, "évolution III · Ultime"]];
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const ids = tuto ? [["thor", "golem", "bahamut"], ["fenrir", "yeti", "banshee"]] : (() => { const p = melanger([...ROSTER], rng); return [p.slice(0, 3), p.slice(3, 6)]; })();
    const J = ids[0].map(id => creer(id, "j")), A = ids[1].map(id => creer(id, "a"));
    [...J, ...A].forEach(c => c.agi = false);
    const destin = { j: 0, a: 0 };
    let tour = 1, sel = null, occupe = false, fini = false;
    const zGA = h("div", "de-jauge a"), zA = h("div", "de-eq"), zLog = h("div", "jl"), zJ = h("div", "de-eq"), zGJ = h("div", "de-jauge j"), zPn = h("div", "pn");
    zLog.style.flex = "1"; zLog.style.display = "flex"; zLog.style.alignItems = "center"; zLog.style.justifyContent = "center";
    ctx.scene.append(zGA, zA, zLog, zJ, zGJ, zPn);
    const tous = () => [...J, ...A];
    const M = matchDe(ctx, zLog, {
      tous, adversaires: c => c.camp === "j" ? A : J, allies: c => c.camp === "j" ? J : A,
      hook(t, a) { if (t === "ko" && a) gagner(a.camp, 1); },
    });
    function gagner(camp, n) { destin[camp] = Math.min(10, destin[camp] + n); }
    function jauge(z, camp) {
      z.innerHTML = "";
      const d = destin[camp], l = h("div", "de-lig");
      l.append(h("b", "", camp === "j" ? "Ton Destin" : "Son Destin"), h("span", "de-val", `${d} / 10`));
      const pal = PALIERS.filter(p => p[0] <= d).pop();
      l.append(h("span", "de-pal", `débloqué : ${pal[1]}`));
      const g = h("div", "de-cases");
      for (let i = 1; i <= 10; i++) { const c = h("i", i <= d ? "plein" : ""); if (PALIERS.some(p => p[0] === i)) c.classList.add("palier"); g.append(c); }
      z.append(l, g);
    }
    function rendre() {
      ctx.scoreJA(vivants(J).length, vivants(A).length);
      jauge(zGA, "a"); jauge(zGJ, "j");
      zA.innerHTML = ""; A.forEach(c => zA.append(elCreature(c, { petit: true })));
      zJ.innerHTML = ""; J.forEach(c => zJ.append(elCreature(c, { petit: true, sel: sel === c, plan: c.agi ? "a agi" : "", onclick: () => { if (!occupe && !c.agi && !c.ko) { sel = sel === c ? null : c; rendre(); } } })));
      if (fini) zPn.innerHTML = "";
      else if (occupe) { zPn.innerHTML = ""; ctx.consigne("Son tour…", "lui"); }
      else if (sel) actions(sel);
      else { const n = vivants(J).filter(c => !c.agi).length; panneau(zPn, n ? `Touche une créature (${n} peuvent agir)` : "Tout le monde a agi", [{ nom: "Fin du tour", txt: "il joue ensuite", cls: "or", f: finTour }]); ctx.consigne(`Tour ${tour} · Destin ${destin.j}`); }
      marquerCibles();
    }
    const opts = (c, camp) => {
      const d = destin[camp], k = KITS[c.id];
      return [
        { t: "attaque", nom: "Attaque", txt: "+1 Destin", ok: true, cible: "ennemi" },
        { t: "garde", nom: "Garde", txt: "dégâts ÷2 · +1 Destin", ok: true },
        { t: "pouvoir", nom: k.pouvoir, txt: d < 4 ? "Destin 4 requis" : c.recharge ? `recharge ${c.recharge}` : k.txt, ok: d >= 4 && !c.recharge, cible: k.cible },
        { t: "evo2", nom: "Évolution II", txt: c.stade > 1 ? "déjà faite" : d < 6 ? "Destin 6 requis" : "coûte 3 Destin", ok: c.stade === 1 && d >= 6 },
        { t: "assaut", nom: "Assaut du Destin", txt: d < 7 ? "Destin 7 requis" : "frappe ×2,2 · coûte 2", ok: d >= 7, cible: "ennemi" },
        { t: "evo3", nom: "Évolution III", txt: c.stade !== 2 ? "depuis le stade II" : d < 10 ? "Destin 10 requis" : "coûte tout le Destin", ok: c.stade === 2 && d >= 10 },
        { t: "ultime", nom: "Ultime", txt: d < 10 ? "Destin 10 requis" : "frappe toute son équipe ×1,5 · coûte tout", ok: d >= 10 },
      ];
    };
    function actions(c) {
      panneau(zPn, `${nomDe(c.id)} · ${forme(c)}`, opts(c, "j").map(o => ({
        nom: o.nom, txt: o.txt, dispo: o.ok, cls: ["evo2", "evo3", "ultime"].includes(o.t) && o.ok ? "or" : "",
        f: async () => {
          let u = null;
          if (o.cible === "ennemi") { u = await cib(ciblesValides(A).map(x => x.uid)); if (!u) return; }
          if (o.cible === "allie") { u = await cib(vivants(J).filter(x => x !== c).map(x => x.uid)); if (!u) return; }
          agir(c, o.t, u ? +u : null);
        },
      })), () => { sel = null; rendre(); });
    }
    function cib(cands) { ctx.consigne("Touche la cible"); const p = choisir(cands); zPn.querySelector(".pn-annuler").onclick = () => annulerChoix(); return p; }
    function executer(c, t, u) {
      c.agi = true; const camp = c.camp, cible = u != null ? tous().find(x => x.uid === u) : null;
      if (c.st.gele) { delete c.st.gele; M.fx(c, "gelé", "mot"); return; }
      if (t === "attaque") { frapper(M, c, cible, 1); gagner(camp, 1); }
      if (t === "garde") { c.defend = true; M.fx(c, "en garde", "mot"); gagner(camp, 1); }
      if (t === "pouvoir") { pouvoir(M, c, cible); gagner(camp, 1); }
      if (t === "evo2") { destin[camp] -= 3; evoluer(M, c); }
      if (t === "assaut") { destin[camp] -= 2; M.fx(c, "Assaut du Destin", "mot"); frapper(M, c, cible, 2.2); }
      if (t === "evo3") { destin[camp] = 0; evoluer(M, c); }
      if (t === "ultime") { destin[camp] = 0; M.log(`${nomDe(c.id)} déchaîne son Ultime !`); M.fx(c, "ULTIME", "gros"); for (const e of vivants(camp === "j" ? A : J)) frapper(M, c, e, 1.5); }
    }
    function agir(c, t, u) { if (occupe) return; executer(c, t, u); sel = null; rendre(); fin(); }
    async function finTour() {
      if (occupe) return; occupe = true; sel = null; rendre();
      debutTour(M, "a"); for (const c of A) c.agi = false;
      await dodo(450); if (!ctx.vivant()) return;
      for (const c of vivants(A)) {
        if (c.ko) continue;
        const [t, u] = planIA(c); executer(c, t, u); rendre();
        await dodo(750); if (!ctx.vivant() || fin()) return;
      }
      debutTour(M, "j"); for (const c of J) c.agi = false;
      tour++; occupe = false; rendre(); fin();
    }
    function planIA(c) {
      const d = destin.a, o = Object.fromEntries(opts(c, "a").map(x => [x.t, x]));
      const cibles = ciblesValides(J).sort((a, b) => a.pv - b.pv), faible = cibles[0];
      if (o.evo3.ok) return ["evo3"];
      if (o.ultime.ok && vivants(J).length >= 2 && !A.some(x => x.stade === 2 && !x.ko)) return ["ultime"];
      if (o.evo2.ok && rng() < 0.6) return ["evo2"];
      if (o.assaut.ok && faible && faible.pv <= attaqueDe(c) * 2.2 && d < 9) return ["assaut", faible.uid];
      if (o.pouvoir.ok && valeurPouvoir(M, c) >= 4) { const k = KITS[c.id]; return ["pouvoir", k.cible === "ennemi" ? faible.uid : k.cible === "allie" ? (vivants(A).filter(x => x !== c)[0] || c).uid : null]; }
      if (c.pv < c.max * 0.3 && rng() < 0.5) return ["garde"];
      return ["attaque", faible.uid];
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
      await ctx.etape({ texte: "Chaque action fait monter ton Destin." });
      await ctx.etape({ texte: "À 4 : pouvoirs. À 6 : évolution. À 10 : l'Ultime." });
      await ctx.etape({ texte: "Dépenser maintenant, ou monter jusqu'à 10 ?" });
      ctx.tutoFini();
    })();
  }
  enregistrer({ groupe: "nouveaux", id: "destins", num: "5", nom: "Destins croisés", accroche: "Une jauge de Destin qui monte : pouvoirs, évolutions, puis l'Ultime.", duree: "5 min", images: ["thor-1", "thor-2", "thor-3"], fond: "linear-gradient(160deg,#1c2640,#131022)", lancer });
})();
