// ═════════════════════════════ 6 · LA CARAVANE ═════════════════════════════
// Une course : à chaque étape, recrute un héros parmi trois, range ton équipe, et elle se bat seule
// contre une caravane adverse. Deux fois le même héros : il monte d'un niveau. 5 victoires avant 3 défaites.
// En duel, la caravane adverse serait l'équipe enregistrée d'un autre joueur.
(function () {
  const MAX = 5, VICTOIRES = 5, VIES = 3;
  const MULT = [1, 1.5, 2.25];
  function stats(id, niv) {
    const f = FICHES[id], k = MULT[niv - 1];
    const pv = f.sbire ? 22 : Math.round(f.pv / 2), att = f.sbire ? 8 : Math.round(f.att * 0.8);
    return { pv: Math.round(pv * k), att: Math.max(3, Math.round(att * k)) };
  }
  const membre = (id, niv = 1) => ({ id, niv, ...stats(id, niv) });
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const pool = HEROS_TYPES.map(x => x.id);
    let equipe = tuto ? [membre("golem"), membre("kitsune")] : melanger([...pool], rng).slice(0, 2).map(id => membre(id));
    let victoires = 0, vies = VIES, etape = 1, offres = [], phase = "recrue", attente = null, echange = null, occupe = false;

    const zInfo = h("div", "cv-info"), zAdv = h("div", "cv-rang cv-adv"), zMil = h("div", "cv-mil"), zEq = h("div", "cv-rang cv-eq"), zOff = h("div", "cv-offres"), zBtn = h("div", "rangee");
    const bCombat = h("button", "btn or", "Combattre");
    zBtn.append(bCombat);
    ctx.scene.append(zInfo, zAdv, zMil, zEq, zOff, zBtn);

    function tirerOffres() {
      const o = [];
      while (o.length < 3) {
        const id = rng() < 0.35 && equipe.length ? equipe[Math.floor(rng() * equipe.length)].id : pool[Math.floor(rng() * pool.length)];
        if (!o.includes(id)) o.push(id);
      }
      offres = tuto && etape === 1 ? ["thor", o[1], o[2]] : o;
    }
    function adverse() {
      const n = Math.min(2 + Math.ceil(etape / 1.5), MAX), a = [];
      const niv2 = Math.max(0, etape - 3);
      for (let i = 0; i < n; i++) {
        const id = etape <= 1 && i === n - 1 ? SBIRES[Math.floor(rng() * 6)].id : pool[Math.floor(rng() * pool.length)];
        a.push(membre(id, i < niv2 ? Math.min(3, 1 + (etape > 5 ? 2 : 1)) : 1));
      }
      if (etape === 1) for (const m of a) { m.pv = Math.round(m.pv * 0.75); m.att = Math.round(m.att * 0.8); }
      return a;
    }
    function elMembre(m, camp, i, rangee) {
      const w = h("div", "cv-m" + (i === 0 ? " devant" : "")); w.dataset.i = i;
      const c = vignette(m.id, { nom: false, camp }); w.append(c);
      if (m.niv > 1) c.append(h("span", "cv-niv", "★".repeat(m.niv)));
      const pv = h("div", "cv-pv"), b = h("i"); b.style.width = Math.max(0, m.pv / (m.max || m.pv) * 100) + "%"; pv.append(b);
      w.append(pv, h("div", "cv-st", `${Math.max(0, m.pv)} · ${m.att}`));
      if (rangee === "eq" && phase === "range") w.onclick = () => ranger(i);
      if (rangee === "eq" && attente != null && i === attente) w.classList.add("sel");
      if (rangee === "eq" && phase === "remplace") { w.onclick = () => remplacer(i); w.classList.add("cible"); }
      return w;
    }
    function rendre(adv) {
      ctx.score.innerHTML = `<span class="j">${victoires}</span><span class="sep">victoires · vies</span><span class="a">${vies}</span>`;
      zInfo.innerHTML = "";
      const et = h("div", "cv-etapes");
      for (let i = 0; i < VICTOIRES; i++) { const s = h("span", i < victoires ? "ok" : ""); s.innerHTML = etoile("", 8, 0.3); et.append(s); }
      zInfo.append(h("span", "cv-lib", `Étape ${etape}`), et);
      zAdv.innerHTML = "";
      if (adv) { zAdv.append(h("span", "cv-tit lui", "Caravane adverse")); adv.filter(m => m.pv > 0).forEach((m, i) => zAdv.append(elMembre(m, "a", i, "adv"))); }
      zEq.innerHTML = ""; zEq.append(h("span", "cv-tit", `Ta caravane (${equipe.length}/${MAX})`));
      equipe.filter(m => m.pv > 0).forEach((m, i) => zEq.append(elMembre(m, "j", i, "eq")));
      zOff.innerHTML = "";
      zOff.hidden = phase !== "recrue";
      if (phase === "recrue") {
        zOff.append(h("div", "cv-tit", "Recrute un héros"));
        const g = h("div", "cv-grille");
        offres.forEach((id, k) => {
          const b = h("button", "cv-offre"); b.dataset.k = k;
          const deja = equipe.find(m => m.id === id);
          const c = vignette(id); b.append(c);
          const s = stats(id, deja ? Math.min(3, deja.niv + 1) : 1);
          b.append(h("span", "cv-os", deja ? `Niveau ${Math.min(3, deja.niv + 1)} !` : `${s.pv} PV · ${s.att} ATT`));
          if (deja) b.classList.add("monte");
          b.onclick = () => recruter(id);
          g.append(b);
        });
        zOff.append(g);
      }
      bCombat.hidden = phase !== "range";
      bCombat.disabled = occupe;
    }
    function recruter(id) {
      if (phase !== "recrue") return;
      const deja = equipe.find(m => m.id === id);
      if (deja) { if (deja.niv < 3) Object.assign(deja, membre(id, deja.niv + 1)); phase = "range"; ctx.consigne(`${nomDe(id)} monte au niveau ${deja.niv} !`); flotSur(zEq, "niveau +1", "gros", 0.3); }
      else if (equipe.length < MAX) { equipe.push(membre(id)); phase = "range"; ctx.consigne("Range ton équipe (touche deux héros), puis combats"); }
      else { echange = id; phase = "remplace"; ctx.consigne(`Équipe pleine : touche le héros que ${nomDe(id)} remplace`); }
      rendre(); Guide.signal("recrue");
    }
    function remplacer(i) { equipe[i] = membre(echange); echange = null; phase = "range"; ctx.consigne("Range ton équipe (touche deux héros), puis combats"); rendre(); }
    function ranger(i) {
      if (attente == null) { attente = i; rendre(); return; }
      if (attente !== i) [equipe[attente], equipe[i]] = [equipe[i], equipe[attente]];
      attente = null; rendre();
    }
    async function combattre() {
      if (phase !== "range" || occupe) return;
      occupe = true; phase = "combat"; attente = null;
      const moi = equipe.map(m => ({ ...m, max: m.pv })), lui = adverse().map(m => ({ ...m, max: m.pv }));
      const vivants = l => l.filter(m => m.pv > 0);
      const montrer = () => { equipe_ = moi; rendreCombat(lui, moi); };
      let equipe_ = moi;
      function rendreCombat(a, j) {
        const sauve = equipe; equipe = j; rendre(a); equipe = sauve;
      }
      ctx.consigne("Ceux de devant se frappent", "calme");
      montrer(); await dodo(700);
      let tours = 0;
      while (vivants(moi).length && vivants(lui).length && tours < 30 && ctx.vivant()) {
        tours++;
        const fj = vivants(moi)[0], fa = vivants(lui)[0];
        for (const [eq, f] of [[moi, fj], [lui, fa]]) {
          const ap = vivants(eq).slice(1).find(m => FICHES[m.id].role === "appui");
          if (ap && f.pv < f.max) f.pv = Math.min(f.max, f.pv + 4 * ap.niv);
        }
        const dj = Math.round(fj.att * (bat(typeDe(fj.id), typeDe(fa.id)) ? 1.5 : bat(typeDe(fa.id), typeDe(fj.id)) ? 0.7 : 1) * (FICHES[fa.id].role === "garde" ? 0.7 : 1));
        const da = Math.round(fa.att * (bat(typeDe(fa.id), typeDe(fj.id)) ? 1.5 : bat(typeDe(fj.id), typeDe(fa.id)) ? 0.7 : 1) * (FICHES[fj.id].role === "garde" ? 0.7 : 1));
        const eA = zAdv.querySelector(".cv-m.devant"), eJ = zEq.querySelector(".cv-m.devant");
        rejouer(eA, "cv-coupA"); rejouer(eJ, "cv-coupJ");
        await dodo(150);
        flotSur(eA, `−${dj}`, "or"); flotSur(eJ, `−${da}`, "rose");
        fa.pv -= dj; fj.pv -= da;
        await dodo(200);
        if (fa.pv <= 0) flotSur(eA, "K.O.", "mot"); if (fj.pv <= 0) flotSur(eJ, "K.O.", "mot");
        montrer(); await dodo(fa.pv <= 0 || fj.pv <= 0 ? 480 : 220);
      }
      if (!ctx.vivant()) return;
      const g = vivants(moi).length > 0 && !vivants(lui).length, p = !vivants(moi).length && vivants(lui).length;
      if (g) victoires++; else if (p) vies--;
      ctx.consigne(g ? "Étape gagnée !" : p ? "Étape perdue : une vie en moins" : "Égalité", g ? "" : "lui");
      occupe = false;
      await dodo(1100); if (!ctx.vivant()) return;
      if (tuto && Jeu.tuto && !Guide.saute) {
        await ctx.etape({ texte: "5 victoires gagnent la course. 3 défaites l'arrêtent." });
        await ctx.etape({ texte: "Deux fois le même héros : il monte d'un niveau." });
        ctx.tutoFini();
      }
      if (victoires >= VICTOIRES) return ctx.fin({ titre: "Victoire", texte: `Ta caravane a gagné ${VICTOIRES} étapes.`, gagne: true });
      if (vies <= 0) return ctx.fin({ titre: "Défaite", texte: `${victoires} victoire${victoires > 1 ? "s" : ""} avant la fin de la course.`, gagne: false });
      etape++; phase = "recrue"; tirerOffres(); rendre(); ctx.consigne("Recrute un héros");
    }
    bCombat.onclick = combattre;
    tirerOffres(); rendre(); ctx.consigne("Recrute un héros");
    if (tuto) (async () => {
      await ctx.etape({ texte: "Monte une équipe. Elle se bat toute seule." });
      if (!ctx.vivant()) return;
      await ctx.etape({ cible: () => zOff.querySelector('[data-k="0"]'), signal: "recrue", texte: "Recrute Thor" });
      if (!ctx.vivant()) return;
      await ctx.etape({ texte: "Le premier de la file encaisse les coups." });
      await ctx.etape({ cible: () => bCombat, texte: "Lance le combat" });
    })();
  }

  enregistrer({ id: "caravane", num: "6", nom: "La Caravane", accroche: "Recrute, range ton équipe, regarde-la se battre. 5 victoires.", duree: "3 min", images: ["thor", "anubis", "bunyip"], fond: "linear-gradient(160deg,#2c2416,#141020)", lancer });
})();
