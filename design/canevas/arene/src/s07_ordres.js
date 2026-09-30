// ═════════════════════════════ S7 · LES ORDRES DE BATAILLE ═════════════════════════════
// Une petite carte : collines (portée +1), forêts (on n'y est touché qu'au contact), rivière (on y avance
// deux fois moins vite), 3 autels. Tu places tes héros en bas et donnes à chacun un ORDRE.
// Victoire : tenir 2 autels pendant 12 pas (au total), ou éliminer l'équipe adverse.
(function () {
  const CARTE = ["...F...", ".......", ".C...C.", "F..R..F", "A.RAR.A", "F..R..F", ".C...C.", ".......", "...F..."];
  const LW = 7, LH = 9, TENIR = 12, MAXPAS = 70;
  const AUTELS = [[0, 4], [3, 4], [6, 4]], NOMS_A = ["l'autel ouest", "l'autel du centre", "l'autel est"];
  const terrain = (x, y) => CARTE[y] ? CARTE[y][x] : "#";
  const PORTEE = { thor: 3, banshee: 2, bahamut: 2 };
  const ETAPES = [
    { nom: "La prise des autels", desc: "Fenrir et Cerbère foncent au centre, Thor tient la colline ouest, Bahamut va à l'est.", eq: [["fenrir", 2, 1, "autel:1"], ["cerbere", 4, 1, "autel:1"], ["thor", 1, 0, "autel:0"], ["bahamut", 5, 0, "autel:2"]], reserve: ["golem", "kitsune", "yeti", "minotaure", "wukong", "anubis"] },
    { nom: "Les chasseurs", desc: "Kitsune et Minotaure chassent ton plus faible. Golem et Yéti tiennent le centre.", force: 1.5, eq: [["kitsune", 1, 1, "chasse:faible"], ["minotaure", 5, 1, "chasse:faible"], ["golem", 3, 1, "autel:1"], ["yeti", 3, 0, "autel:1"]], reserve: ["thor", "cerbere", "bahamut", "fenrir", "doudou", "banshee"] },
  ];
  const ORDRES = [["autel:0", "prendre l'autel ouest"], ["autel:1", "prendre l'autel du centre"], ["autel:2", "prendre l'autel est"], ["chasse:faible", "chasser le plus faible"], ["protege", "protéger l'allié le plus faible"], ["tenir", "tenir sa position"]];
  function simuler(prep, et) {
    const J = Journal();
    const U = [];
    for (const id of prep.eq) { const [x, y] = prep.pos[id]; U.push(Object.assign(unite(id, "j", { pv: Math.round(KITS[id].pv * 1.5) }), { x, y, ordre: prep.ordres[id], lent: 0 })); }
    for (const [id, x, y, o] of et.eq) U.push(Object.assign(unite(id, "a", { pv: Math.round(KITS[id].pv * 1.5 * (et.force || 1)) }), { x, y, ordre: o, lent: 0 }));
    const tenue = { j: 0, a: 0 };
    let pas = 0, maitres = [null, null, null];
    const vue = () => ({ u: U.map(copieU), maitres: maitres.slice(), tenue: { ...tenue }, pas });
    const at = (x, y) => U.find(u => !u.ko && u.x === x && u.y === y);
    const dist = (a, b) => Math.max(Math.abs(a.x - b.x), Math.abs(a.y - b.y));
    function portee(u) { return (PORTEE[u.id] || 1) + (terrain(u.x, u.y) === "C" ? 1 : 0); }
    function visible(u, v) { return !(terrain(v.x, v.y) === "F" && dist(u, v) > 1) && !(v.id === "kitsune" && terrain(v.x, v.y) === "F"); }
    function pasVers(u, cx, cy) {
      // un pas qui rapproche (4 directions), en évitant les cases prises ; ordre fixe pour départager
      let best = null;
      for (const [dx, dy] of [[0, u.camp === "j" ? -1 : 1], [-1, 0], [1, 0], [0, u.camp === "j" ? 1 : -1]]) {
        const x = u.x + dx, y = u.y + dy; if (x < 0 || y < 0 || x >= LW || y >= LH || at(x, y)) continue;
        const d = Math.abs(x - cx) + Math.abs(y - cy);
        if (!best || d < best.d) best = { x, y, d };
      }
      if (best && best.d < Math.abs(u.x - cx) + Math.abs(u.y - cy)) { u.x = best.x; u.y = best.y; if (terrain(u.x, u.y) === "R") u.lent = 1; }
    }
    J.pas_(vue(), "Les ordres sont donnés", [], 900);
    while (pas < MAXPAS) {
      pas++;
      const fx = []; const faits = [];
      for (const u of U.filter(x => !x.ko).sort((a, b) => b.vit - a.vit || (a.camp === b.camp ? 0 : a.camp === "j" ? -1 : 1) || a.uid - b.uid)) {
        if (u.ko) continue;
        if (u.st.gele) { delete u.st.gele; J.fait(u, "gele"); fx.push([u.uid, "gelé", "mot"]); continue; }
        const adv = U.filter(v => !v.ko && v.camp !== u.camp && visible(u, v));
        const [o, arg] = u.ordre.split(":");
        let cible = null;
        if (o === "chasse") cible = U.filter(v => !v.ko && v.camp !== u.camp).sort((a, b) => a.pv - b.pv || a.uid - b.uid)[0];
        if (o === "protege") { const p = U.filter(v => !v.ko && v.camp === u.camp && v !== u).sort((a, b) => a.pv / a.max - b.pv / b.max)[0]; const menace = p && adv.filter(v => dist(v, p) <= 2).sort((a, b) => dist(a, u) - dist(b, u))[0]; cible = menace || null; if (!cible && p && dist(u, p) > 1) { if (u.lent) u.lent = 0; else pasVers(u, p.x, p.y); continue; } }
        // frapper si quelqu'un est à portée
        const aPortee = adv.filter(v => dist(u, v) <= portee(u)).sort((a, b) => (cible && a === cible ? -1 : cible && b === cible ? 1 : 0) || a.pv - b.pv || a.uid - b.uid);
        if (aPortee.length) {
          const v = aPortee[0]; coup(J, u, v, 0.6, fx);
          if (u.id === "yeti" && !v.ko && pas % 3 === 0) v.st.gele = true;
          if (u.id === "bahamut" && terrain(u.x, u.y) === "R") for (const a of U.filter(w => !w.ko && w.camp === u.camp && dist(w, u) <= 1)) guerir(J, a, 4, fx);
          continue;
        }
        if (u.lent) { u.lent = 0; continue; }
        if (o === "tenir") continue;
        let but = null;
        if (o === "autel") but = AUTELS[+arg];
        else if (cible) but = [cible.x, cible.y];
        else { const e = U.filter(v => !v.ko && v.camp !== u.camp).sort((a, b) => dist(u, a) - dist(u, b))[0]; if (e) but = [e.x, e.y]; }
        if (but && !(o === "autel" && u.x === but[0] && u.y === but[1])) { pasVers(u, but[0], but[1]); if (u.id === "fenrir" && o === "chasse" && !u.lent) pasVers(u, but[0], but[1]); }
      }
      // les autels
      maitres = AUTELS.map(([x, y]) => {
        const pres = c => U.some(u => !u.ko && u.camp === c && Math.abs(u.x - x) + Math.abs(u.y - y) <= 1);
        const j = pres("j"), a = pres("a"); return j && !a ? "j" : a && !j ? "a" : null;
      });
      for (const c of ["j", "a"]) if (maitres.filter(m => m === c).length >= 2) tenue[c]++;
      J.pas_(vue(), `Pas ${pas} · autels : ${maitres.map(m => m === "j" ? "à toi" : m === "a" ? "à lui" : "libre").join(", ")}`, fx, 380);
      if (tenue.j >= TENIR || tenue.a >= TENIR || !U.some(u => u.camp === "j" && !u.ko) || !U.some(u => u.camp === "a" && !u.ko)) break;
    }
    const kj = !U.some(u => u.camp === "j" && !u.ko), ka = !U.some(u => u.camp === "a" && !u.ko);
    const g = !kj && (ka || tenue.j >= TENIR || (tenue.a < TENIR && tenue.j > tenue.a));
    const plus = [`Autels tenus : ${tenue.j} pas pour toi, ${tenue.a} pour lui (il en faut ${TENIR}).`];
    const vide = AUTELS.findIndex((_, i) => !U.some(u => u.camp === "j" && u.ordre === `autel:${i}`));
    if (!g && vide >= 0) plus.push(`Personne n'avait l'ordre de prendre ${NOMS_A[vide]}.`);
    return { pas: J.pas, gagne: g, recit: J.recit(plus) };
  }
  function carte(us, o = {}) {
    const g = h("div", "sp-grille or-carte"); g.style.gridTemplateColumns = `repeat(${LW},1fr)`;
    for (let y = 0; y < LH; y++) for (let x = 0; x < LW; x++) {
      const t = terrain(x, y), c = h("button", "sp-cell or-" + ({ F: "foret", C: "colline", R: "riviere", A: "autel", ".": "plaine" }[t]) + (y >= LH - 2 ? " depart" : ""));
      const ai = AUTELS.findIndex(a => a[0] === x && a[1] === y);
      if (ai >= 0) { c.innerHTML = etoile("or-etoile", 8, 0.3); if (o.maitres && o.maitres[ai]) c.classList.add("m" + o.maitres[ai]); }
      const u = us.find(v => v.x === x && v.y === y && !v.ko);
      if (u) c.append(pion(u, { tag: o.tag && o.tag(u) }));
      if (o.sel && u && u.id === o.sel && u.camp === "j") c.classList.add("ok");
      if (o.onCell) c.onclick = () => o.onCell(x, y, u);
      g.append(c);
    }
    return g;
  }
  function rendreVue(z, v) { z.append(h("div", "sp-leg", `tenue des autels : toi ${v.tenue.j}/${TENIR} · lui ${v.tenue.a}/${TENIR}`), carte(v.u, { maitres: v.maitres })); }
  function rendrePrep(z, prep, et, maj) {
    const ennemis = et.eq.map(([id, x, y], i) => ({ uid: "a" + i, id, camp: "a", x, y, pv: 1, max: 1 }));
    const miens = prep.eq.map(id => ({ uid: "j" + id, id, camp: "j", x: prep.pos[id][0], y: prep.pos[id][1], pv: 1, max: 1 }));
    z.append(h("div", "sp-leg", "Colline : portée +1 · Forêt : on n'y est touché qu'au contact · Rivière : on y avance 2 fois moins vite · Étoile : autel"));
    z.append(carte([...ennemis, ...miens], { sel: prep._sel, onCell: (x, y, u) => { if (u && u.camp === "j") { prep._sel = prep._sel === u.id ? null : u.id; return maj(); } if (prep._sel && y >= LH - 2 && !u) { prep.pos[prep._sel] = [x, y]; prep._sel = null; maj(); } } }));
    const eb = h("div", "sp-bloc"); eb.append(h("div", "sp-tit", "Ses ordres"));
    for (const [id, , , o] of et.eq) eb.append(h("div", "sp-leg", `${nomDe(id)} : ${ORDRES.find(x => x[0] === o)[1]}`));
    z.append(eb);
    choixHeros(z, et.reserve, prep.eq, 4, () => {
      for (const id of prep.eq) { if (!prep.ordres[id]) prep.ordres[id] = "autel:1"; if (!prep.pos[id]) { outer: for (let y = LH - 1; y >= LH - 2; y--) for (let x = 0; x < LW; x++) if (!prep.eq.some(k => prep.pos[k] && prep.pos[k][0] === x && prep.pos[k][1] === y)) { prep.pos[id] = [x, y]; break outer; } } }
      maj();
    });
    const b = h("div", "sp-bloc"); b.append(h("div", "sp-tit", "Tes ordres"));
    for (const id of prep.eq) { const l = h("div", "sp-ligne"); l.append(vignette(id, { stade: 1, nom: false }), h("b", "", nomDe(id)), selecteur(ORDRES, prep.ordres[id], v => { prep.ordres[id] = v; })); b.append(l); }
    z.append(b);
  }
  enregistrer({ groupe: "strategie", id: "s-ordres", num: "7", nom: "Les Ordres de bataille", accroche: "Une carte, trois autels, du terrain. Donne un ordre à chacun.", duree: "50 s", images: ["thor-1", "fenrir-1", "bahamut-1"], fond: "linear-gradient(160deg,#1a2a1c,#131022)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => { const eq = tirerN(R, et.reserve, 4), cells = tirerN(R, [...Array(14).keys()], 4), pos = {}, ordres = {}; eq.forEach((id, i) => { pos[id] = [cells[i] % 7, 7 + Math.floor(cells[i] / 7)]; ordres[id] = tirer(R, ORDRES)[0]; }); return { eq, pos, ordres }; }, initPrep: et => { const eq = et.reserve.slice(0, 4), pos = {}, ordres = {}; eq.forEach((id, i) => { pos[id] = [[1, 7], [3, 7], [5, 7], [3, 8]][i]; ordres[id] = ["autel:0", "autel:1", "autel:2", "autel:1"][i]; }); return { eq, pos, ordres, _sel: null }; },
      pret: p => p.eq.length === 4 ? true : "choisis 4 héros", simuler, rendreVue, rendrePrep,
      tuto: ["Place tes héros en bas et donne un ordre à chacun.", "Tenir 2 autels pendant 12 pas, ou tout éliminer.", "Le terrain compte : colline, forêt, rivière."] }) });
})();
