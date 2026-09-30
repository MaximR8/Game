// ═════════════════════════════ N6 · CHASSE AU MONSTRE ═════════════════════════════
// Trois créatures contre le Dragon du Lumeçon, en trois parties :
// la Tête (son souffle frappe toute l'équipe) · la Queue (coup qui étourdit ; tant qu'elle bat, le Corps est protégé)
// · le Corps (les vrais PV). À 66 % puis 33 % du Corps, il change de phase. Il annonce ses coups.
// Pensé pour la coop : en ligne, chaque joueur jouerait une créature.
(function () {
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const ids = tuto ? ["thor", "bahamut", "yeti"] : melanger(ROSTER.filter(x => x !== "doudou"), rng).slice(0, 3);
    const H = ids.map(id => { const c = creer(id, "j"); c.courage = 0; c.agi = false; return c; });
    const partie = (p, nom, pv, txt) => ({ uid: ++UID, id: "doudou", camp: "a", partie: p, nomP: nom, txt, pv, max: pv, att: 0, armure: 0, st: {}, ko: false, stade: 3, bonusAtt: 0, bonusPv: 0 });
    const T = partie("tete", "Tête", 36, "Souffle de feu sur toute l'équipe"), C = partie("corps", "Corps", 130, "Les vrais PV du dragon"), Q = partie("queue", "Queue", 30, "Coup de queue qui étourdit ; protège le Corps");
    const P = [T, C, Q];
    let tour = 1, sel = null, occupe = false, fini = false, intentions = [], compteur = 0, crin = false;
    const zBoss = h("div", "ca-boss"), zInt = h("div", "ca-int"), zLog = h("div", "jl"), zH = h("div", "de-eq"), zPn = h("div", "pn");
    zLog.style.flex = "1";
    ctx.scene.append(zBoss, zInt, zLog, zH, zPn);
    const phase = () => C.pv > C.max * 0.66 ? 1 : C.pv > C.max * 0.33 ? 2 : 3;
    const M = matchDe(ctx, zLog, {
      tous: () => [...H, ...P], adversaires: c => c.camp === "j" ? P.filter(x => !x.ko) : H, allies: c => c.camp === "j" ? H : P,
      hook(t, a, b, n) {
        if (t === "degats" && a && a.courage != null) a.courage++;
        if (t === "degats" && b && b.courage != null && n > 0) b.courage++;
        if (t === "ko" && b.partie === "tete") M.log("La Tête est brisée : plus de souffle de feu !");
        if (t === "ko" && b.partie === "queue" && !crin) { crin = true; M.log("La Queue tombe : le crin porte-bonheur ! Ton équipe +15 PV et +2 ATT"); for (const x of vivants(H)) { x.bonusAtt += 2; recalc(x); soigner(M, x, 15); } }
      },
    });
    M.fx = (c, t, k) => { const e = document.querySelector(`[data-uid="${c.uid}"]`); if (e) flotSur(e, t, k || "", 0.35); };
    function prevoir() {
      const ph = phase(), n = ph === 1 ? 1 : 2, l = [];
      compteur++;
      if (ph === 3 && compteur % 3 === 0) l.push({ t: "charge", txt: "Charge du Lumeçon : 13 à toute l'équipe" });
      while (l.length < n) {
        const pool = [];
        if (!T.ko) pool.push({ t: "souffle", txt: `Souffle de feu : ${T.pv < T.max / 2 ? 3 : 6} à toute l'équipe` });
        if (!Q.ko) pool.push({ t: "queue", txt: "Coup de queue : 10 et étourdit" });
        pool.push({ t: "griffe", txt: "Griffes : 11 sur le plus faible" });
        l.push(pool[Math.floor(rng() * pool.length)]);
      }
      intentions = l;
    }
    function rendre() {
      ctx.score.innerHTML = `<span class="sep">phase</span><span class="a">${phase()}</span>`;
      zBoss.innerHTML = "";
      const img = vignette("doudou", { stade: 3, nom: false }); img.classList.add("ca-img");
      const parts = h("div", "ca-parts");
      for (const p of P) {
        const b = h("div", "ca-part" + (p.ko ? " ko" : "")); b.dataset.cible = p.uid; b.dataset.uid = p.uid;
        const bar = h("div", "cr2-pv"), i = h("i"); i.style.width = Math.max(0, p.pv / p.max * 100) + "%"; bar.append(i);
        const st = Object.keys(p.st).filter(k => STATUTS[k]).map(k => STATUTS[k]);
        b.append(h("b", "", p.nomP + (p.ko ? " — brisée" : ` ${Math.max(0, p.pv)}/${p.max}`)), bar, h("span", "", p.partie === "corps" && !Q.ko ? "protégé par la Queue (−30 %)" : p.txt));
        if (st.length) b.append(h("em", "", st.join(" · ")));
        parts.append(b);
      }
      zBoss.append(img, parts);
      zInt.innerHTML = ""; zInt.append(h("b", "", `Le dragon va faire${intentions.length > 1 ? ` (${intentions.length} actions)` : ""} :`));
      for (const it of intentions) zInt.append(h("span", "", it.txt));
      zH.innerHTML = "";
      H.forEach(c => { const ex = h("div", "my-eveil"), b = h("i"); b.style.width = Math.min(100, c.courage / (c.stade === 1 ? 3 : 6) * 100) + "%"; ex.append(b); zH.append(elCreature(c, { petit: true, sel: sel === c, plan: c.agi ? "a agi" : "", extra: c.stade < 3 ? ex : null, onclick: () => { if (!occupe && !c.agi && !c.ko) { sel = sel === c ? null : c; rendre(); } } })); });
      if (fini) zPn.innerHTML = "";
      else if (occupe) { zPn.innerHTML = ""; ctx.consigne("Le dragon attaque…", "lui"); }
      else if (sel) actions(sel);
      else { panneau(zPn, "Touche une créature, puis vise une partie du dragon", [{ nom: "Fin du tour", txt: "le dragon agit", cls: "or", f: finTour }]); ctx.consigne(`Tour ${tour}`); }
      marquerCibles();
    }
    function actions(c) {
      const k = KITS[c.id], seuil = c.stade === 1 ? 3 : 6, parts = P.filter(p => !p.ko).map(p => p.uid);
      panneau(zPn, `${nomDe(c.id)} · Courage ${c.courage}${c.stade < 3 ? "/" + seuil : ""}`, [
        { nom: "Attaquer", txt: "une partie du dragon", f: async () => { const u = await cib(parts); if (u) agir(c, "attaque", +u); } },
        { nom: "Défendre", txt: "dégâts ÷2", f: () => agir(c, "defense") },
        { nom: k.pouvoir, txt: c.recharge ? `recharge ${c.recharge}` : k.txt, dispo: !c.recharge, f: async () => {
          let u = null;
          if (k.cible === "ennemi") { u = await cib(parts); if (!u) return; }
          if (k.cible === "allie") { u = await cib(vivants(H).filter(x => x !== c).map(x => x.uid)); if (!u) return; }
          agir(c, "pouvoir", u ? +u : null);
        } },
        { nom: "Évoluer", txt: c.stade >= 3 ? "forme ultime" : `Courage ${c.courage}/${seuil}`, dispo: c.stade < 3 && c.courage >= seuil, cls: c.stade < 3 && c.courage >= seuil ? "or" : "", f: () => agir(c, "evoluer") },
      ], () => { sel = null; rendre(); });
    }
    function cib(cands) { ctx.consigne("Touche la cible"); const p = choisir(cands); zPn.querySelector(".pn-annuler").onclick = () => annulerChoix(); return p; }
    function agir(c, t, u) {
      if (occupe) return;
      c.agi = true; sel = null;
      if (c.st.gele) { delete c.st.gele; M.fx(c, "étourdi", "mot"); }
      else {
        const cible = u != null ? [...H, ...P].find(x => x.uid === u) : null;
        const prot = cible === C && !Q.ko ? 0.7 : 1;
        if (t === "attaque") frapper(M, c, cible, prot);
        if (t === "defense") { c.defend = true; M.fx(c, "en garde", "mot"); }
        if (t === "pouvoir") pouvoir(M, c, cible);
        if (t === "evoluer") { c.courage -= c.stade === 1 ? 3 : 6; evoluer(M, c); }
      }
      rendre(); fin();
    }
    function coup(c, n, src) {
      if (c.ko) return;
      if (c.st.esquive) { delete c.st.esquive; M.fx(c, "esquive !", "mot"); return; }
      let d = n * (c.defend ? 0.5 : 1) * (src && src.st.affaibli ? 0.7 : 1);
      if (c.st.protege) { const p = H.find(x => x.uid === c.st.protege.par && !x.ko); if (p && p !== c) { c = p; d *= 0.7; } }
      d = Math.round(d); const a = Math.min(c.armure, d); c.armure -= a; d -= a;
      c.pv -= d; c.courage++; M.fx(c, `−${d}`, "rose");
      if (c.pv <= 0) ko(M, c, null);
      else if (c.st.contre && src && !src.ko) frapper(M, c, src, 0.6, { contre: true });
    }
    async function finTour() {
      if (occupe) return; occupe = true; sel = null; rendre();
      debutTour(M, "a");
      await dodo(500); if (!ctx.vivant()) return;
      for (const it of intentions) {
        if (C.ko) break;
        if (C.st.gele) { delete C.st.gele; M.log("Le Corps est gelé : le dragon perd une action"); M.fx(C, "gelé", "mot"); rendre(); await dodo(700); continue; }
        const v = vivants(H); if (!v.length) break;
        if (it.t === "souffle") { if (T.ko) M.log("Plus de tête, plus de souffle"); else if (T.st.gele) { delete T.st.gele; M.log("La Tête est gelée : pas de souffle"); } else { M.log("Souffle de feu !"); for (const c of v) coup(c, T.pv < T.max / 2 ? 3 : 6, T); } }
        if (it.t === "queue") { if (Q.ko) M.log("La queue est tombée"); else if (Q.st.gele) { delete Q.st.gele; M.log("La Queue est gelée"); } else { const c = v[Math.floor(rng() * v.length)]; M.log(`Coup de queue sur ${nomDe(c.id)}`); coup(c, 10, Q); if (!c.ko) c.st.gele = true; } }
        if (it.t === "griffe") { const c = v.sort((a, b) => a.pv - b.pv)[0]; M.log(`Griffes sur ${nomDe(c.id)}`); coup(c, 11, C); }
        if (it.t === "charge") { M.log("La Charge du Lumeçon !"); for (const c of v) coup(c, 13, C); }
        rendre(); await dodo(900); if (!ctx.vivant() || fin()) return;
      }
      debutTour(M, "j"); for (const c of H) c.agi = false;
      tour++; prevoir(); occupe = false; rendre(); fin();
    }
    function fin() {
      if (fini) return true;
      if (C.ko || !vivants(H).length) {
        fini = true; occupe = true; rendre(); const g = C.ko;
        ctx.fin({ titre: g ? "Le dragon tombe" : "Défaite", texte: g ? `Vaincu en ${tour} tours${crin ? ", avec le crin porte-bonheur" : ""}.` : `Il lui restait ${C.pv} PV au Corps.`, gagne: g });
        return true;
      }
      return false;
    }
    prevoir(); rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Le dragon a 3 parties. Seul le Corps compte pour le tuer." });
      await ctx.etape({ texte: "Brise la Tête : plus de souffle. La Queue : un bonus." });
      await ctx.etape({ texte: "Il annonce ses coups. À 66 % et 33 %, il s'énerve." });
      ctx.tutoFini();
    })();
  }
  enregistrer({ groupe: "nouveaux", id: "chasse", num: "6", nom: "Chasse au monstre", accroche: "Trois créatures contre le Dragon du Lumeçon : tête, corps, queue.", duree: "6 min", images: ["doudou-3", "thor-2", "yeti-1"], fond: "linear-gradient(160deg,#3a1c14,#141022)", lancer });
})();
