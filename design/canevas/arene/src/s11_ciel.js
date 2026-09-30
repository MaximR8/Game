// ═════════════════════════════ S11 · LA CARTE DU CIEL (hybride) ═════════════════════════════
// L'Échiquier en plus simple (grille 5×5, chacun avance d'une case vers son but), plus UN lien
// (la Figure céleste en plus simple), plus UNE consigne par héros (les Consignes en plus simple).
// Un autel au centre : le tenir 6 pas (au total) gagne, ou éliminer l'équipe adverse.
(function () {
  const N = 5, AUTEL = [2, 2], TENIR = 6, MAXT = 40;
  const CONS = [["autel", "va tenir l'autel"], ["protege", "protège l'allié le plus faible"], ["chasse", "chasse le plus faible"], ["soigneur", "chasse son soigneur"], ["tenir", "tient sa case"]];
  const typeLien = id => ["bahamut", "anubis", "quetzalcoatl"].includes(id) ? "soin" : ["golem", "cerbere", "doudou", "yeti"].includes(id) ? "garde" : "force";
  const TXT_LIEN = { soin: "soigne son lié de 3 par pas", garde: "son lié prend −25 %", force: "son lié +2 ATT" };
  const ETAPES = [
    { nom: "La garde de l'autel", desc: "Golem et Bahamut, liés, tiennent l'autel. Fenrir chasse ton plus faible.", force: 1.5, eq: [["golem", 2, 1, "autel"], ["bahamut", 1, 0, "protege"], ["fenrir", 3, 1, "chasse"]], lien: ["golem", "bahamut"], reserve: ["thor", "kitsune", "yeti", "cerbere", "minotaure", "anubis"] },
    { nom: "Les chasseurs de soigneurs", desc: "Kitsune chasse ton soigneur, Minotaure ton plus faible ; Cerbère, lié à Kitsune, tient l'autel.", eq: [["kitsune", 1, 1, "soigneur"], ["minotaure", 3, 1, "chasse"], ["cerbere", 2, 0, "autel"]], lien: ["cerbere", "kitsune"], reserve: ["golem", "bahamut", "doudou", "thor", "wukong", "yeti"] },
  ];
  const cheb = (a, b) => Math.max(Math.abs(a.x - b.x), Math.abs(a.y - b.y));
  function simuler(prep, et) {
    const J = Journal();
    const U = [];
    for (const id of prep.eq) { const [x, y] = prep.pos[id]; U.push(Object.assign(unite(id, "j", { pv: Math.round(KITS[id].pv * 1.4) }), { x, y, cons: prep.cons[id] })); }
    for (const [id, x, y, c] of et.eq) U.push(Object.assign(unite(id, "a", { pv: Math.round(KITS[id].pv * 1.4 * (et.force || 1)) }), { x, y, cons: c }));
    const lier = (camp, [a, b]) => { const A = U.find(u => u.camp === camp && u.id === a), B = U.find(u => u.camp === camp && u.id === b); if (A && B) { A.lie = B; B.lie = A; for (const [p, q] of [[A, B], [B, A]]) if (typeLien(p.id) === "force") q.att += 2; } };
    if (prep.lien && prep.lien[0] && prep.lien[1]) lier("j", prep.lien); lier("a", et.lien);
    const tenue = { j: 0, a: 0 };
    let t = 0, maitre = null;
    const at = (x, y) => U.find(u => !u.ko && u.x === x && u.y === y);
    const vue = () => ({ u: U.map(u => ({ ...copieU(u), lie: u.lie && u.lie.uid })), tenue: { ...tenue }, maitre, t });
    J.pas_(vue(), "Chacun connaît sa consigne", [], 800);
    for (t = 1; t <= MAXT; t++) {
      const fx = [];
      for (const u of U.filter(v => !v.ko).sort((a, b) => b.vit - a.vit || (a.camp === b.camp ? 0 : a.camp === "j" ? -1 : 1) || a.uid - b.uid)) {
        if (u.ko) continue;
        const adv = U.filter(v => !v.ko && v.camp !== u.camp), all = U.filter(v => !v.ko && v.camp === u.camp && v !== u);
        if (!adv.length) break;
        let but = null, cible = null;
        if (u.cons === "autel") but = AUTEL;
        if (u.cons === "protege") { const p = all.sort((a, b) => a.pv / a.max - b.pv / b.max)[0]; if (p) { but = [p.x, p.y]; cible = adv.filter(v => cheb(v, p) <= 1)[0]; } }
        if (u.cons === "chasse") cible = adv.slice().sort((a, b) => a.pv - b.pv || a.uid - b.uid)[0];
        if (u.cons === "soigneur") cible = adv.find(v => ["Soutien", "Nécromancien", "Chef"].includes(KITS[v.id].role)) || adv.slice().sort((a, b) => a.pv - b.pv)[0];
        const portee = u.id === "thor" ? 2 : 1;
        const aPortee = adv.filter(v => cheb(u, v) <= portee).sort((a, b) => (a === cible ? -1 : b === cible ? 1 : 0) || a.pv - b.pv);
        if (aPortee.length) {
          const v = aPortee[0]; let k = 0.7;
          if (v.lie && !v.lie.ko && typeLien(v.lie.id) === "garde") k *= 0.75;
          coup(J, u, v, k, fx); continue;
        }
        if (u.cons === "tenir") continue;
        if (!but && cible) but = [cible.x, cible.y];
        if (!but) { const e = adv.slice().sort((a, b) => cheb(u, a) - cheb(u, b))[0]; but = [e.x, e.y]; }
        let best = null;
        for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) {
          const x = u.x + dx, y = u.y + dy; if ((!dx && !dy) || x < 0 || y < 0 || x >= N || y >= N || at(x, y)) continue;
          const d = Math.max(Math.abs(x - but[0]), Math.abs(y - but[1])) * 10 + Math.abs(x - but[0]) + Math.abs(y - but[1]);
          if (!best || d < best.d) best = { x, y, d };
        }
        const dNow = Math.max(Math.abs(u.x - but[0]), Math.abs(u.y - but[1])) * 10 + Math.abs(u.x - but[0]) + Math.abs(u.y - but[1]);
        if (best && best.d < dNow) { u.x = best.x; u.y = best.y; }
      }
      for (const u of U.filter(v => !v.ko && v.lie && !v.lie.ko && typeLien(v.id) === "soin")) guerir(J, u.lie, 3, fx);
      const pres = c => U.some(u => !u.ko && u.camp === c && cheb(u, { x: AUTEL[0], y: AUTEL[1] }) <= 1);
      const pj = pres("j"), pa = pres("a"); maitre = pj && !pa ? "j" : pa && !pj ? "a" : null;
      if (maitre) tenue[maitre]++;
      J.pas_(vue(), `Pas ${t} · autel : ${maitre === "j" ? "à toi" : maitre === "a" ? "à lui" : "disputé"} (toi ${tenue.j}/${TENIR}, lui ${tenue.a}/${TENIR})`, fx, 520);
      if (tenue.j >= TENIR || tenue.a >= TENIR || !U.some(u => u.camp === "j" && !u.ko) || !U.some(u => u.camp === "a" && !u.ko)) break;
    }
    const kj = !U.some(u => u.camp === "j" && !u.ko), ka = !U.some(u => u.camp === "a" && !u.ko);
    const g = !kj && (ka || tenue.j >= TENIR || (tenue.a < TENIR && tenue.j > tenue.a));
    const plus = [`Autel : ${tenue.j} pas pour toi, ${tenue.a} pour lui.`];
    if (!prep.eq.some(id => prep.cons[id] === "autel")) plus.push("Aucun de tes héros n'avait la consigne « va tenir l'autel ».");
    return { pas: J.pas, gagne: g, recit: J.recit(plus) };
  }
  function grille(us, o = {}) {
    const g = h("div", "sp-grille cc-grille"); g.style.gridTemplateColumns = `repeat(${N},1fr)`;
    for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
      const c = h("button", "sp-cell " + (y >= 3 ? "j" : y <= 1 ? "a" : ""));
      if (x === AUTEL[0] && y === AUTEL[1]) { c.classList.add("or-autel"); c.innerHTML = etoile("or-etoile", 8, 0.3); if (o.maitre) c.classList.add("m" + o.maitre); }
      const u = us.find(v => v.x === x && v.y === y && !v.ko);
      if (u) c.append(pion(u, { tag: u.lie ? "lien" : "" }));
      if (o.sel && u && u.id === o.sel && u.camp === "j") c.classList.add("ok");
      if (o.onCell) c.onclick = () => o.onCell(x, y, u);
      g.append(c);
    }
    return g;
  }
  function rendreVue(z, v) { z.append(h("div", "sp-leg", `autel : toi ${v.tenue.j}/${TENIR} · lui ${v.tenue.a}/${TENIR}`), grille(v.u, { maitre: v.maitre })); }
  function rendrePrep(z, prep, et, maj) {
    const us = et.eq.map(([id, x, y], i) => ({ uid: "a" + i, id, camp: "a", x, y, pv: 1, max: 1, lie: et.lien.includes(id) }));
    for (const id of prep.eq) us.push({ uid: "j" + id, id, camp: "j", x: prep.pos[id][0], y: prep.pos[id][1], pv: 1, max: 1, lie: prep.lien.includes(id) });
    z.append(grille(us, { sel: prep._sel, onCell: (x, y, u) => { if (u && u.camp === "j") { prep._sel = prep._sel === u.id ? null : u.id; return maj(); } if (prep._sel && y >= 3 && !u) { prep.pos[prep._sel] = [x, y]; prep._sel = null; maj(); } } }));
    const eb = h("div", "sp-bloc"); eb.append(h("div", "sp-tit", `Lui · lien ${nomDe(et.lien[0])} — ${nomDe(et.lien[1])}`));
    for (const [id, , , c] of et.eq) eb.append(h("div", "sp-leg", `${nomDe(id)} : ${CONS.find(x => x[0] === c)[1]}`));
    z.append(eb);
    choixHeros(z, et.reserve, prep.eq, 3, () => {
      for (const id of prep.eq) { if (!prep.cons[id]) prep.cons[id] = "autel"; if (!prep.pos[id]) { outer: for (let y = 3; y < N; y++) for (let x = 0; x < N; x++) if (!prep.eq.some(k => prep.pos[k] && prep.pos[k][0] === x && prep.pos[k][1] === y)) { prep.pos[id] = [x, y]; break outer; } } }
      prep.lien = prep.lien.filter(id => prep.eq.includes(id)); maj();
    });
    const b = h("div", "sp-bloc"); b.append(h("div", "sp-tit", "Une consigne chacun, et un lien"));
    for (const id of prep.eq) { const l = h("div", "sp-ligne"); l.append(vignette(id, { stade: 1, nom: false }), h("b", "", nomDe(id)), selecteur(CONS, prep.cons[id], v => { prep.cons[id] = v; }), h("span", "sp-leg", `lien : ${TXT_LIEN[typeLien(id)]}`)); b.append(l); }
    const opts = []; for (let i = 0; i < prep.eq.length; i++) for (let k = i + 1; k < prep.eq.length; k++) opts.push([`${prep.eq[i]}|${prep.eq[k]}`, `${nomDe(prep.eq[i])} — ${nomDe(prep.eq[k])}`]);
    if (opts.length) { const l = h("div", "sp-ligne"); l.append(h("b", "", "Le lien"), selecteur(opts, prep.lien.join("|"), v => { prep.lien = v.split("|"); maj(); })); b.append(l); }
    z.append(b);
  }
  enregistrer({ groupe: "strategie", id: "s-ciel", num: "11", nom: "La Carte du ciel", accroche: "L'hybride : placement, un lien, une consigne. Tiens l'autel.", duree: "40 s", images: ["golem-1", "bahamut-1", "fenrir-1"], fond: "linear-gradient(160deg,#28183a,#141022)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => { const eq = tirerN(R, et.reserve, 3), cells = tirerN(R, [...Array(10).keys()], 3), pos = {}, cons = {}; eq.forEach((id, i) => { pos[id] = [cells[i] % 5, 3 + Math.floor(cells[i] / 5)]; cons[id] = tirer(R, CONS)[0]; }); return { eq, pos, cons, lien: tirerN(R, eq, 2) }; }, initPrep: et => { const eq = et.reserve.slice(0, 3), pos = {}, cons = {}; eq.forEach((id, i) => { pos[id] = [1 + i, 3]; cons[id] = ["autel", "chasse", "protege"][i]; }); return { eq, pos, cons, lien: [eq[0], eq[1]], _sel: null }; },
      pret: p => p.eq.length === 3 ? true : "choisis 3 héros", simuler, rendreVue, rendrePrep,
      tuto: ["Place 3 héros en bas, donne à chacun une consigne.", "Lie deux d'entre eux : ils s'entraident.", "Tiens l'autel du centre 6 pas, ou élimine tout."] }) });
})();
