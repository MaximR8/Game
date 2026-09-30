// ═════════════════════════════ 5 · LA POUSSÉE EN RYTHME ═════════════════════════════
// Trois héros contre trois. Ceux de devant se battent. Quand ton héros frappe, un anneau se resserre :
// touche l'écran quand il touche le cercle (parfait = double dégâts et la ligne avance). Quand il te
// frappe, pare de la même façon. Pousse la ligne jusqu'à sa base.
(function () {
  const RT = 46, RMAX = 150;
  function combattant(id) { const f = FICHES[id]; const pv = Math.round((f.pv || 50) * 0.6); return { id, pv, max: pv, att: f.att || 10 }; }
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    let eqJ, eqA;
    if (tuto) { eqJ = ["thor", "golem", "kitsune"]; eqA = ["bahamut", "cerbere", "fenrir"]; }
    else { const p = melanger(HEROS_TYPES.map(x => x.id), rng); eqJ = p.slice(0, 3); eqA = p.slice(3, 6); }
    const J = eqJ.map(combattant), A = eqA.map(combattant);
    let L = 5, vitesse = tuto ? 1 : 1.25, fini = false;

    const jauge = h("div", "ry-jauge"), queueA = h("div", "ry-queue"), scene = h("div", "ry-scene"), queueJ = h("div", "ry-queue");
    const posA = h("div", "ry-pos ry-pa"), posJ = h("div", "ry-pos ry-pj"), mot = h("div", "ry-mot");
    scene.append(posA, mot, posJ);
    ctx.scene.append(jauge, queueA, scene, queueJ);

    function rendre() {
      ctx.scoreJA(A.filter(x => x.pv <= 0).length, J.filter(x => x.pv <= 0).length);
      jauge.innerHTML = "";
      const cases = h("div", "ry-cases");
      for (let i = 0; i <= 10; i++) { const c = h("div", "ry-case" + (i === 0 ? " bj" : i === 10 ? " ba" : "")); if (i === L) { c.classList.add("ici"); c.innerHTML = etoile("", 8, 0.3); } cases.append(c); }
      const bords = h("div", "ry-bords"); bords.append(h("span", "j", "Ta base"), h("span", "", L > 5 ? `+${L - 5}` : L < 5 ? `${L - 5}` : "milieu"), h("span", "a", "Sa base"));
      jauge.append(cases, bords);
      const vivA = A.filter(x => x.pv > 0), vivJ = J.filter(x => x.pv > 0);
      queueA.innerHTML = ""; queueA.append(h("span", "ry-lib lui", "Derrière lui"));
      vivA.slice(1).forEach(x => queueA.append(vignette(x.id, { nom: false })));
      queueJ.innerHTML = ""; queueJ.append(h("span", "ry-lib", "Derrière toi"));
      vivJ.slice(1).forEach(x => queueJ.append(vignette(x.id, { nom: false })));
      posA.innerHTML = ""; posJ.innerHTML = "";
      if (vivA[0]) posA.append(carteCombat(vivA[0], "a"));
      if (vivJ[0]) posJ.append(carteCombat(vivJ[0], "j"));
    }
    function carteCombat(x, camp) {
      const w = h("div", "ry-front"), c = vignette(x.id, { camp });
      c.classList.add("ry-carte");
      const pv = h("div", "ry-pv"), i = h("i"); i.style.width = Math.max(0, x.pv / x.max * 100) + "%"; pv.append(i);
      w.append(c, pv, h("div", "ry-stat", `${Math.max(0, x.pv)} PV · ${x.att} ATT · ${TYPES[typeDe(x.id)].nom}`));
      return w;
    }
    // L'anneau : il se resserre sur la carte visée ; on touche quand il épouse le cercle.
    function anneau(cibleEl, duree) {
      return new Promise(res => {
        const rs = scene.getBoundingClientRect(), rc = cibleEl.getBoundingClientRect();
        const cx = rc.left + rc.width / 2 - rs.left, cy = rc.top + rc.height / 2 - rs.top;
        const fixe = h("div", "ry-cible"), mobile = h("div", "ry-anneau");
        for (const [e, r] of [[fixe, RT], [mobile, RMAX]]) Object.assign(e.style, { left: cx + "px", top: cy + "px", width: 2 * r + "px", height: 2 * r + "px" });
        scene.append(fixe, mobile);
        const t0 = performance.now(); let fin = false;
        const rayon = () => RMAX * (1 - (performance.now() - t0) / duree);
        const conclure = r => {
          if (fin) return; fin = true; scene.removeEventListener("pointerdown", tape);
          fixe.remove(); mobile.remove();
          const e = Math.abs(r - RT); res(e <= 9 ? "parfait" : e <= 22 ? "bien" : "rate");
        };
        const tape = e => { e.preventDefault(); conclure(rayon()); };
        scene.addEventListener("pointerdown", tape);
        (function f() { if (fin) return; if (!ctx.vivant()) { fin = true; return; } const r = rayon(); if (r < RT - 26) return conclure(r); mobile.style.width = mobile.style.height = 2 * r + "px"; requestAnimationFrame(f); })();
      });
    }
    function pousser(d) { L = borne(L + d, 0, 10); }
    async function motFort(txt, sorte) { mot.textContent = txt; mot.className = "ry-mot " + sorte; rejouer(mot, "bond"); }
    async function echange() {
      const a = A.find(x => x.pv > 0), j = J.find(x => x.pv > 0);
      // toi, tu frappes
      ctx.consigne("Frappe : touche quand l'anneau touche le cercle");
      const guide1 = tuto && !Guide.saute && Jeu.tuto ? ctx.etape({ cible: () => scene, signal: "anneau", doigt: false, bulle: "haut", texte: "Touche quand l'anneau touche le cercle" }) : null;
      const r1 = await anneau(posA.querySelector(".ry-carte"), (guide1 ? 2200 : 1150) / vitesse);
      Guide.signal("anneau"); if (guide1) await guide1;
      if (!ctx.vivant()) return;
      const k = r1 === "parfait" ? 2 : r1 === "bien" ? 1.5 : 1, m = bat(typeDe(j.id), typeDe(a.id)) ? 1.5 : bat(typeDe(a.id), typeDe(j.id)) ? 0.7 : 1;
      const d = Math.round(j.att * k * m);
      motFort(r1 === "parfait" ? "PARFAIT ×2" : r1 === "bien" ? "BIEN ×1,5" : "RATÉ ×1", r1);
      rejouer(posJ.querySelector(".ry-front"), "ry-frappeJ"); await dodo(180);
      flotSur(posA.querySelector(".ry-carte"), `−${d}`, m > 1 ? "gros" : "or"); rejouer(posA.querySelector(".ry-carte"), "secoue");
      a.pv -= d; if (r1 === "parfait") pousser(1);
      if (a.pv <= 0) { pousser(2); await dodo(350); motFort(`${nomDe(a.id)} tombe : +2 cases`, "parfait"); }
      rendre(); await dodo(650); if (!ctx.vivant()) return;
      if (tuto && Jeu.tuto && !Guide.saute) await ctx.etape({ texte: r1 === "parfait" ? "Parfait : double dégâts, la ligne avance !" : "Presque ! Parfait = double dégâts." });
      if (verifier()) return;
      if (a.pv <= 0) return;
      // lui, il te frappe
      ctx.consigne("Pare : touche quand l'anneau touche le cercle", "lui");
      const guide2 = tuto && !Guide.saute && Jeu.tuto ? ctx.etape({ cible: () => scene, signal: "anneau", doigt: false, bulle: "haut", texte: "Il frappe : pare au bon moment !" }) : null;
      const r2 = await anneau(posJ.querySelector(".ry-carte"), (guide2 ? 2200 : 1050) / vitesse);
      Guide.signal("anneau"); if (guide2) await guide2;
      if (!ctx.vivant()) return;
      const m2 = bat(typeDe(a.id), typeDe(j.id)) ? 1.5 : bat(typeDe(j.id), typeDe(a.id)) ? 0.7 : 1;
      const k2 = r2 === "parfait" ? 0 : r2 === "bien" ? 0.5 : 1, d2 = Math.round(a.att * m2 * k2);
      motFort(r2 === "parfait" ? "PARADE PARFAITE" : r2 === "bien" ? "PARADE : −50 %" : "TOUCHÉ", r2);
      rejouer(posA.querySelector(".ry-front"), "ry-frappeA"); await dodo(180);
      if (d2) { flotSur(posJ.querySelector(".ry-carte"), `−${d2}`, "rose"); rejouer(posJ.querySelector(".ry-carte"), "secoue"); }
      j.pv -= d2; if (r2 === "rate") pousser(-1);
      if (j.pv <= 0) { pousser(-2); await dodo(350); motFort(`${nomDe(j.id)} tombe : −2 cases`, "rate"); }
      rendre(); await dodo(650); if (!ctx.vivant()) return;
      if (tuto && Jeu.tuto && !Guide.saute) { await ctx.etape({ texte: "Pousse l'étoile jusqu'à sa base !" }); ctx.tutoFini(); }
      verifier();
    }
    function verifier() {
      const vA = A.some(x => x.pv > 0), vJ = J.some(x => x.pv > 0);
      if (L >= 10 || !vA) { fini = true; return ctx.fin({ titre: "Victoire", texte: !vA ? "Toute son équipe est tombée." : "L'étoile a atteint sa base.", gagne: true }), true; }
      if (L <= 0 || !vJ) { fini = true; return ctx.fin({ titre: "Défaite", texte: !vJ ? "Toute ton équipe est tombée." : "L'étoile a atteint ta base.", gagne: false }), true; }
      return false;
    }
    (async () => {
      rendre();
      if (tuto) await ctx.etape({ texte: "Tes héros se battent. Toi, tu donnes le rythme." });
      else { ctx.consigne("Prêt ?"); await dodo(900); }
      while (!fini && ctx.vivant()) { await echange(); vitesse = Math.min(vitesse + 0.04, 1.7); }
    })();
  }

  enregistrer({ id: "rythme", num: "5", nom: "La Poussée en rythme", accroche: "Tes héros se battent seuls. Touche au bon moment pour frapper et parer.", duree: "1 min", images: ["kitsune", "golem", "fenrir"], fond: "linear-gradient(160deg,#162a26,#131024)", lancer });
})();
