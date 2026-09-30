// ═════════════════════════════ S2 · LES TROIS TEMPS ═════════════════════════════
// Ouverture, Mêlée, Final : une posture d'équipe par temps. Assaut bat Ruse, Ruse bat Rempart,
// Rempart bat Assaut. Siège ne gagne rien, mais double le temps suivant.
// Le porte-étendard dans sa posture préférée donne en plus son effet.
(function () {
  const P = { assaut: "Assaut", rempart: "Rempart", ruse: "Ruse", siege: "Siège" };
  const BAT = { assaut: "ruse", ruse: "rempart", rempart: "assaut" };
  const AFF = { Frappeur: "assaut", Charge: "assaut", "Bête": "assaut", Virtuose: "assaut", Tank: "rempart", Gardien: "rempart", Protecteur: "rempart", "Contrôle": "rempart", "Rusée": "ruse", "Sorcière": "ruse", Hurleuse: "ruse", Soutien: "siege", Chef: "siege", "Nécromancien": "siege" };
  const EFF = { assaut: "ses coups ignorent le Rempart adverse", rempart: "renvoie 50 % des coups qu'il reçoit", ruse: "annule le bonus de posture adverse", siege: "soigne l'équipe de 6 à chaque manche" };
  const aff = id => KITS[id] ? AFF[KITS[id].role] || "assaut" : "rempart";
  const TEMPS = ["Ouverture", "Mêlée", "Final"];
  const ETAPES = [
    { nom: "La meute de Fenrir", desc: "Présage : il ouvre toujours en Assaut. Il finit en Rempart. Et au milieu ?", eq: ["fenrir", "minotaure", "cerbere"], plan: ["assaut", "ruse", "rempart"], vu: [true, false, true], chefs: [0, 1, 2], reserve: ["golem", "kitsune", "thor", "bahamut", "yeti"] },
    { nom: "La cour de Baba Yaga", desc: "Présage : les sorcières aiment la Ruse. Son Final est un secret.", eq: ["babayaga", "banshee", "kitsune"], plan: ["ruse", "siege", "ruse"], vu: [true, true, false], chefs: [0, 0, 2], reserve: ["golem", "minotaure", "cerbere", "thor", "anubis"] },
    { nom: "Boss : le Troll de pierre", desc: "Le boss joue Rempart tant qu'il a plus de 50 % PV, puis Colère (bat Rempart et Ruse, perd contre Siège).", eq: ["golem", "doudou", "cerbere"], boss: true, plan: ["rempart", "rempart", "colere"], vu: [true, true, true], chefs: [0, 0, 0], reserve: ["thor", "kitsune", "minotaure", "bahamut", "quetzalcoatl", "wukong"] },
  ];
  function simuler(prep, et) {
    const J = Journal();
    const eqJ = prep.eq.map(id => unite(id, "j", { pv: Math.round(KITS[id].pv * 1.4) }));
    const eqA = et.eq.map((id, i) => unite(id, "a", et.boss && i === 0 ? { pv: 120, att: 8 } : { pv: Math.round(KITS[id].pv * (et.boss ? 0.9 : 1.4)) }));
    if (et.boss) eqA[0].id = "troll";
    const tous = [...eqJ, ...eqA];
    let charge = { j: 1, a: 1 }, t = 0, postures = null, bandeau = "";
    const vue = () => ({ j: eqJ.map(copieU), a: eqA.map(copieU), t, postures, bandeau });
    for (t = 0; t < 3; t++) {
      const pj = prep.plan[t], pa = et.boss ? (eqA[0].pv > eqA[0].max / 2 ? "rempart" : "colere") : et.plan[t];
      const chefJ = eqJ[prep.chefs[t]], chefA = eqA[et.chefs[t]];
      postures = { j: pj, a: pa };
      // qui gagne la confrontation ?
      const gagne = (x, y) => (x === "colere" && (y === "rempart" || y === "ruse")) || (y === "colere" && x === "siege") || BAT[x] === y;
      let gj = gagne(pj, pa), ga = gagne(pa, pj);
      const ruseJ = chefJ && !chefJ.ko && pj === "ruse" && aff(chefJ.id) === "ruse", ruseA = chefA && !chefA.ko && pa === "ruse" && aff(chefA.id) === "ruse";
      if (ruseJ && ga) ga = false; if (ruseA && gj) gj = false;
      bandeau = `${TEMPS[t]} : ta posture ${P[pj]} contre ${pa === "colere" ? "Colère" : P[pa]}. ` + (gj ? "Tu l'emportes !" : ga ? "Il l'emporte." : "Personne ne l'emporte.");
      const mods = { j: { dealt: charge.j, taken: 1 }, a: { dealt: charge.a, taken: 1 } };
      for (const [c, p, g] of [["j", pj, gj], ["a", pa, ga]]) {
        if (p === "assaut") mods[c].dealt *= 1.2;
        if (p === "rempart") mods[c].taken *= 0.8;
        if (p === "ruse") { mods[c].dealt *= 1.1; mods[c].taken *= 0.9; }
        if (p === "siege") mods[c].dealt *= 0.8;
        if (p === "colere") mods[c].dealt *= 1.3;
        if (g) { mods[c].dealt *= 1.3; mods[c].taken *= 0.8; }
      }
      charge = { j: pj === "siege" ? 1.6 : 1, a: pa === "siege" ? 1.6 : 1 };
      J.pas_(vue(), bandeau, [], 1500);
      for (let m = 0; m < 4; m++) {
        const ordre = tous.filter(u => !u.ko).sort((a, b) => b.vit - a.vit || (a.camp === b.camp ? 0 : a.camp === "j" ? -1 : 1) || a.uid - b.uid);
        for (const u of ordre) {
          if (u.ko) continue;
          const adv = (u.camp === "j" ? eqA : eqJ).filter(x => !x.ko); if (!adv.length) break;
          const cible = adv.slice().sort((a, b) => a.pv - b.pv || a.uid - b.uid)[0];
          const chef = u.camp === "j" ? chefJ : chefA, pc = u.camp === "j" ? pj : pa, pAdv = u.camp === "j" ? pa : pj;
          const estChef = u === chef && aff(u.id) === pc;
          let k = mods[u.camp].dealt * (estChef ? 1.4 : 1);
          let taken = mods[cible.camp].taken;
          if (estChef && pc === "assaut" && pAdv === "rempart") taken = Math.max(taken, 1);
          const fx = [];
          const d = coup(J, u, cible, k * taken, fx);
          const cChef = cible.camp === "j" ? chefJ : chefA, pCible = cible.camp === "j" ? pj : pa;
          if (cible === cChef && pCible === "rempart" && aff(cible.id) === "rempart" && !u.ko) { u.pv -= Math.round(d * 0.5); fx.push([u.uid, `−${Math.round(d * 0.5)}`, "rose"]); if (u.pv <= 0) { u.ko = true; u.pv = 0; J.tomber(u); } }
          J.pas_(vue(), `${bandeau} — ${nomDe(u.id)} frappe ${nomDe(cible.id)}`, fx, 420);
        }
        for (const [c, chef, p] of [["j", chefJ, pj], ["a", chefA, pa]]) if (chef && !chef.ko && p === "siege" && aff(chef.id) === "siege") { const fx = []; for (const u of (c === "j" ? eqJ : eqA)) guerir(J, u, 6, fx); J.pas_(vue(), `${nomDe(chef.id)} soigne son équipe`, fx, 500); }
        if (eqJ.every(u => u.ko) || eqA.every(u => u.ko)) break;
      }
      if (eqJ.every(u => u.ko) || eqA.every(u => u.ko)) break;
    }
    const pct = eq => eq.reduce((s, u) => s + Math.max(0, u.pv), 0) / eq.reduce((s, u) => s + u.max, 0);
    const g = eqA.every(u => u.ko) || (!eqJ.every(u => u.ko) && pct(eqJ) > pct(eqA));
    const plus = [];
    if (!et.boss) { const cache = et.plan.findIndex((p, i) => !et.vu[i]); if (cache >= 0) plus.push(`Son ${TEMPS[cache]} caché était : ${P[et.plan[cache]]}.`); }
    plus.push(`Fin : ${Math.round(pct(eqJ) * 100)} % de PV pour toi, ${Math.round(pct(eqA) * 100)} % pour lui.`);
    return { pas: J.pas, gagne: g, recit: J.recit(plus) };
  }
  function rendreVue(z, v) {
    const r = eq => { const w = h("div", "sp-rang"); for (const u of eq) w.append(elCreature(u, { petit: true })); return w; };
    const b = h("div", "tt3-bandeau"); b.textContent = v.bandeau;
    if (v.postures) { const p = h("div", "tt3-post"); p.append(h("span", "a", v.postures.a === "colere" ? "Colère" : P[v.postures.a]), h("b", "", TEMPS[Math.min(v.t, 2)]), h("span", "j", P[v.postures.j])); z.append(r(v.a), p, r(v.j)); }
    else z.append(r(v.a), r(v.j));
  }
  function rendrePrep(z, prep, et, maj) {
    const box = h("div", "sp-bloc"); box.append(h("div", "sp-tit", "Son équipe et son plan"));
    const l = h("div", "sp-ligne"); for (const id of et.eq) l.append(vignette(id, { stade: 1, nom: false }), h("span", "sp-leg", `${nomDe(et.boss && id === et.eq[0] ? "troll" : id)} (aime ${P[aff(id)]})`)); box.append(l);
    const pl = h("div", "tt3-plan"); TEMPS.forEach((t, i) => pl.append(h("div", "", `${t} : ${et.vu[i] ? (et.plan[i] === "colere" ? "Colère" : P[et.plan[i]]) : "?"}`))); box.append(pl);
    z.append(box);
    choixHeros(z, et.reserve, prep.eq, 3, () => { prep.chefs = prep.chefs.map(c => Math.min(c, Math.max(0, prep.eq.length - 1))); maj(); });
    const b2 = h("div", "sp-bloc"); b2.append(h("div", "sp-tit", "Ton plan de bataille"), h("div", "sp-leg", "Assaut bat Ruse · Ruse bat Rempart · Rempart bat Assaut · Siège ne gagne rien mais double le temps suivant"));
    TEMPS.forEach((t, i) => {
      const li = h("div", "sp-ligne"); li.append(h("b", "", t), selecteur(Object.entries(P), prep.plan[i], v => { prep.plan[i] = v; maj(); }));
      if (prep.eq.length) li.append(h("span", "sp-leg", "mené par"), selecteur(prep.eq.map((id, k) => [k, nomDe(id)]), prep.chefs[i], v => { prep.chefs[i] = +v; maj(); }));
      const chef = prep.eq[prep.chefs[i]];
      if (chef) li.append(h("span", "sp-leg", aff(chef) === prep.plan[i] ? `✓ ${nomDe(chef)} aime ${P[prep.plan[i]]} : ${EFF[prep.plan[i]]}` : `${nomDe(chef)} préfère ${P[aff(chef)]}`));
      b2.append(li);
    });
    z.append(b2);
  }
  enregistrer({ groupe: "strategie", id: "s-temps", num: "2", nom: "Les Trois Temps", accroche: "Un plan de bataille en 3 postures. Lis le sien, contre-le.", duree: "45 s", images: ["fenrir-1", "golem-1", "kitsune-1"], fond: "linear-gradient(160deg,#321c2a,#15101f)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => ({ eq: tirerN(R, et.reserve, 3), plan: [0, 1, 2].map(() => tirer(R, Object.keys(P))), chefs: [0, 1, 2].map(() => Math.floor(R() * 3)) }), initPrep: et => ({ eq: et.reserve.slice(0, 3), plan: ["assaut", "assaut", "assaut"], chefs: [0, 1, 2] }), pret: p => p.eq.length === 3 ? true : "choisis 3 héros", simuler, rendreVue, rendrePrep,
      tuto: ["Trois temps. Pour chacun, une posture d'équipe.", "Assaut bat Ruse, Ruse bat Rempart, Rempart bat Assaut.", "Lis son plan, trouve le tien, lance."] }) });
})();
