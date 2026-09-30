// ═════════════════════════════ 4 · LE DUEL DES OMBRES ═════════════════════════════
// Cinq cartes chacun, toutes visibles. À chaque manche, une terre donne +2 à un type.
// Vous choisissez une carte en même temps, en secret, et on retourne. La plus forte gagne la manche.
// Un type qui bat l'autre : +3. Une fois par partie, tu peux doubler une manche. 3 points gagnent.
(function () {
  const FORCES = [3, 5, 6, 7, 9];
  function puissance(id, f, terre, contre) {
    const t = typeDe(id), l = [[f, "force"]];
    if (t === terre) l.push([2, "terre"]);
    if (contre && bat(t, typeDe(contre))) l.push([3, "avantage"]);
    return { total: l.reduce((s, x) => s + x[0], 0), lignes: l };
  }
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    let mainJ, mainA, terres;
    const types = Object.keys(ADV);
    function main(ids) { const f = melanger([...FORCES], rng); return ids.map((id, i) => ({ id, f: f[i] })); }
    if (tuto) {
      mainJ = [{ id: "thor", f: 7 }, { id: "golem", f: 5 }, { id: "ifrit", f: 9 }, { id: "kitsune", f: 6 }, { id: "yeti", f: 3 }];
      mainA = [{ id: "bahamut", f: 6 }, { id: "fenrir", f: 9 }, { id: "anansi", f: 5 }, { id: "cerbere", f: 7 }, { id: "loki", f: 3 }];
      terres = ["foudre", "glace", "feu", "nature", "esprit"];
    } else {
      const pool = melanger(HEROS_TYPES.map(x => x.id), rng);
      mainJ = main(pool.slice(0, 5)); mainA = main(pool.slice(5, 10));
      terres = [0, 1, 2, 3, 4].map(() => types[Math.floor(rng() * types.length)]);
    }
    const pts = { j: 0, a: 0 }, double = { j: false, a: false };
    let manche = 0, sel = null, doubler = false, occupe = false, resultat = null;

    const zTerres = h("div", "du-terres"), zA = h("div", "du-main du-a"), arene = h("div", "du-arene"), zJ = h("div", "du-main du-j");
    const bDouble = h("button", "btn mauve", "Doubler ×2"), bOk = h("button", "btn or", "Valider"), zBtn = h("div", "rangee");
    zBtn.append(bDouble, bOk);
    ctx.scene.append(zTerres, zA, arene, zJ, zBtn);

    function rendre() {
      ctx.scoreJA(pts.j, pts.a);
      zTerres.innerHTML = "";
      terres.forEach((t, i) => {
        const e = h("div", "du-terre" + (i === manche ? " ici" : i < manche ? " passee" : ""));
        e.style.setProperty("--t", TYPES[t].c); e.append(h("b", "", `Manche ${i + 1}`), h("span", "", `${TYPES[t].nom} +2`));
        zTerres.append(e);
      });
      const terre = terres[Math.min(manche, terres.length - 1)];
      zA.innerHTML = "";
      mainA.forEach(c => {
        const e = vignette(c.id, { force: c.f, nom: false }); e.dataset.id = c.id;
        if (sel) { const s = mainJ.find(x => x.id === sel); if (bat(typeDe(s.id), typeDe(c.id))) e.append(h("span", "du-fl vert", "tu bats")); else if (bat(typeDe(c.id), typeDe(s.id))) e.append(h("span", "du-fl rose", "te bat")); }
        if (typeDe(c.id) === terre) e.append(h("span", "du-bonus", "+2"));
        zA.append(e);
      });
      zJ.innerHTML = "";
      mainJ.forEach(c => {
        const e = vignette(c.id, { force: c.f }); e.dataset.id = c.id;
        if (typeDe(c.id) === terre) e.append(h("span", "du-bonus", "+2"));
        if (sel === c.id) e.classList.add("choisie");
        e.onclick = () => { if (occupe) return; sel = sel === c.id ? null : c.id; rendre(); };
        zJ.append(e);
      });
      if (!resultat) {
        arene.innerHTML = "";
        arene.append(h("div", "du-vide", sel ? "Valide : il choisit en même temps que toi" : "Choisis ta carte pour cette manche"));
      }
      bOk.disabled = !sel || occupe;
      bDouble.disabled = double.j || occupe;
      bDouble.classList.toggle("actif", doubler);
      bDouble.textContent = double.j && !doubler ? "Double utilisé" : doubler ? "Manche doublée" : "Doubler ×2";
      if (manche < terres.length) ctx.consigne(occupe ? "On retourne…" : `Manche ${manche + 1} : ${TYPES[terre].nom} +2`, occupe ? "calme" : "");
    }
    function choixIA(terre) {
      let best = null;
      for (const c of mainA) {
        let v = 0;
        for (const p of mainJ) { const a = puissance(c.id, c.f, terre, p.id).total, j = puissance(p.id, p.f, terre, c.id).total; v += a > j ? 1 : a < j ? -1 : 0; }
        v = v / mainJ.length - c.f * 0.03 + rng() * 0.35;
        if (!best || v > best.v) best = { v, c };
      }
      return { c: best.c, double: !double.a && best.v > 0.55 && rng() < 0.7 };
    }
    async function valider(force) {
      if (!sel || occupe) return;
      occupe = true;
      const terre = terres[manche], cj = mainJ.find(x => x.id === sel);
      const ia = force || choixIA(terre), ca = ia.c;
      if (ia.double) double.a = true;
      if (doubler) double.j = true;
      rendre();
      arene.innerHTML = "";
      const slotA = h("div", "du-slot"), slotJ = h("div", "du-slot");
      slotA.append(dos()); slotJ.append(vignette(cj.id, { force: cj.f }));
      const mil = h("div", "du-mil", "contre");
      arene.append(slotA, mil, slotJ);
      await dodo(650); if (!ctx.vivant()) return;
      slotA.innerHTML = ""; const ea = vignette(ca.id, { force: ca.f }); ea.classList.add("retourne"); slotA.append(ea);
      await dodo(500); if (!ctx.vivant()) return;
      const pj = puissance(cj.id, cj.f, terre, ca.id), pa = puissance(ca.id, ca.f, terre, cj.id);
      const detail = p => p.lignes.map(([n, k]) => k === "force" ? `${n}` : `+${n} ${k}`).join(" ") + ` = ${p.total}`;
      slotA.append(h("div", "du-calc lui", detail(pa))); slotJ.append(h("div", "du-calc", detail(pj)));
      const mise = (doubler ? 2 : 1) * (ia.double ? 2 : 1);
      let txt;
      if (pj.total > pa.total) { pts.j += mise; txt = `Manche pour toi${mise > 1 ? ` : +${mise}` : ""}`; rejouer(slotJ, "bond"); }
      else if (pa.total > pj.total) { pts.a += mise; txt = `Manche pour lui${mise > 1 ? ` : +${mise}` : ""}`; rejouer(slotA, "bond"); }
      else txt = "Égalité : personne ne marque";
      mil.textContent = txt; if (pj.total !== pa.total) mil.classList.add(pj.total > pa.total ? "vert" : "rose");
      if (ia.double) arene.append(h("div", "du-note", "Il avait doublé la manche !"));
      mainJ = mainJ.filter(x => x !== cj); mainA = mainA.filter(x => x !== ca);
      sel = null; doubler = false; resultat = true;
      ctx.scoreJA(pts.j, pts.a);
      await dodo(1500); if (!ctx.vivant()) return;
      resultat = null; manche++; occupe = false;
      if (pts.j >= 3 || pts.a >= 3 || !mainJ.length) {
        rendre();
        const g = pts.j > pts.a, nul = pts.j === pts.a;
        return ctx.fin({ titre: nul ? "Égalité" : g ? "Victoire" : "Défaite", texte: `${pts.j} points pour toi, ${pts.a} pour lui.`, gagne: g });
      }
      rendre();
    }
    bOk.onclick = () => valider();
    bDouble.onclick = () => { if (double.j || occupe) return; doubler = !doubler; rendre(); };
    rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Choisis une carte. Lui aussi, en secret." });
      if (!ctx.vivant()) return;
      await ctx.etape({ cible: () => zJ.querySelector('[data-id="thor"]'), texte: "Touche Thor : Foudre +2 ici" });
      if (!ctx.vivant()) return;
      if (sel !== "thor") { sel = "thor"; rendre(); }
      const ok = ctx.etape({ cible: () => bOk, texte: "Valide" });
      bOk.onclick = null;
      await ok; if (!ctx.vivant()) return;
      bOk.onclick = () => valider();
      await valider({ c: mainA.find(x => x.id === "bahamut"), double: false });
      if (!ctx.vivant()) return;
      await ctx.etape({ texte: "Foudre bat Eau : +3. Le plus fort marque." });
      await ctx.etape({ texte: "3 points : tu gagnes le duel." });
      ctx.tutoFini();
    })();
  }

  enregistrer({ id: "duel", num: "4", nom: "Le Duel des ombres", accroche: "Une carte chacun, en secret. On retourne. Le plus fort marque.", duree: "1 min", images: ["ifrit", "fenrir", "bahamut"], fond: "linear-gradient(160deg,#321c2a,#15101f)", lancer });
})();
