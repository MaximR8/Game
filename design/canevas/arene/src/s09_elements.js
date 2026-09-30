// ═════════════════════════════ S9 · LES ÉLÉMENTS VIVANTS ═════════════════════════════
// Le terrain combat. Chaque héros suit un TRAJET que tu dessines, et peint son élément en marchant.
// Règles fixes : le feu gagne la forêt voisine et brûle (8) · l'eau éteint le feu · la foudre court dans
// toute l'eau reliée (12 et étourdit) · la glace gèle qui y marche · la roche bloque. Attention à tes propres héros !
(function () {
  const N = 7, PAS = 10, MAXT = 5;
  const ELEM = {
    bahamut: { e: "eau", txt: "inonde sa case et les 4 voisines (éteint le feu)" },
    thor: { e: "foudre", txt: "foudroie : si de l'eau est là, toute la flaque est électrifiée" },
    cerbere: { e: "feu", txt: "met le feu à sa case" },
    kitsune: { e: "feu", txt: "feu follet : met le feu à sa case" },
    yeti: { e: "glace", txt: "gèle sa case et l'eau voisine" },
    golem: { e: "roche", txt: "laisse un mur de roche derrière lui" },
    wukong: { e: "nature", txt: "fait pousser la forêt autour de lui" },
    fenrir: { e: "glace", txt: "laisse un sillage de glace" },
  };
  const ETAPES = [
    { nom: "Le bosquet", force: 2.3, desc: "Son Cerbère met le feu en traversant la forêt. Son Golem mure le centre.", terr: [".......", ".......", "FF.F.FF", "FFFFFFF", "FF.F.FF", ".......", "......."], eq: [["cerbere", [[2, 0], [2, 1], [2, 2], [2, 3], [2, 4]]], ["golem", [[3, 0], [3, 1], [3, 2]]], ["yeti", [[4, 0], [4, 1], [4, 2], [4, 3]]]], reserve: ["bahamut", "thor", "yeti", "golem", "wukong", "fenrir"] },
    { nom: "Le loch", force: 3, desc: "Une grande eau au centre. Son Thor la foudroie depuis la rive : n'y reste pas.", terr: [".......", ".......", "..WWW..", ".WWWWW.", "..WWW..", ".......", "......."], eq: [["thor", [[3, 0], [3, 1]]], ["kitsune", [[1, 0], [1, 1], [1, 2]]], ["yeti", [[5, 0], [5, 1], [5, 2]]]], reserve: ["yeti", "golem", "cerbere", "thor", "fenrir", "wukong"] },
  ];
  function simuler(prep, et) {
    const J = Journal();
    const T = et.terr.map(r => r.split("")), age = T.map(r => r.map(() => 0));
    const U = [];
    for (const id of prep.eq) { const ch = prep.chemins[id]; if (!ch || !ch.length) continue; U.push(Object.assign(unite(id, "j", { pv: Math.round(KITS[id].pv * 1.2) }), { x: ch[0][0], y: ch[0][1], ch: ch.slice(1), i: 0 })); }
    for (const [id, ch] of et.eq) U.push(Object.assign(unite(id, "a", { pv: Math.round(KITS[id].pv * (et.force || 2)) }), { x: ch[0][0], y: ch[0][1], ch: ch.slice(1), i: 0 }));
    const at = (x, y) => U.find(u => !u.ko && u.x === x && u.y === y);
    const ok = (x, y) => x >= 0 && y >= 0 && x < N && y < N;
    const V4 = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    let pas = 0;
    const vue = () => ({ T: T.map(r => r.join("")), u: U.map(copieU), pas });
    J.pas_(vue(), "Le terrain est prêt", [], 900);
    for (pas = 1; pas <= PAS; pas++) {
      const fx = [], msgs = [];
      // 1. chacun avance d'une case sur son trajet
      for (const u of U.filter(v => !v.ko).sort((a, b) => b.vit - a.vit || (a.camp === b.camp ? 0 : a.camp === "j" ? -1 : 1))) {
        u.avant = [u.x, u.y];
        if (u.st.gele) { delete u.st.gele; J.fait(u, "gele"); fx.push([u.uid, "figé", "mot"]); continue; }
        const nx = u.ch[u.i]; if (!nx) continue;
        if (T[nx[1]][nx[0]] === "R" || at(nx[0], nx[1])) continue;
        u.x = nx[0]; u.y = nx[1]; u.i++;
      }
      // 2. chacun peint son élément
      for (const u of U.filter(v => !v.ko)) {
        const e = (ELEM[u.id] || {}).e, [x, y] = [u.x, u.y];
        if (e === "eau") { for (const [dx, dy] of [[0, 0], ...V4]) if (ok(x + dx, y + dy) && T[y + dy][x + dx] !== "R") T[y + dy][x + dx] = "W"; }
        if (e === "feu" && T[y][x] !== "W") { T[y][x] = "X"; age[y][x] = 0; }
        if (e === "glace" && u.id === "yeti") { T[y][x] = "I"; for (const [dx, dy] of V4) if (ok(x + dx, y + dy) && T[y + dy][x + dx] === "W") T[y + dy][x + dx] = "I"; }
        if (u.id === "fenrir" && u.avant && (u.avant[0] !== x || u.avant[1] !== y)) T[u.avant[1]][u.avant[0]] = "I";
        if (e === "roche" && u.avant && (u.avant[0] !== x || u.avant[1] !== y) && !at(u.avant[0], u.avant[1])) T[u.avant[1]][u.avant[0]] = "R";
        if (e === "nature") for (const [dx, dy] of [[0, 0], ...V4]) if (ok(x + dx, y + dy) && T[y + dy][x + dx] === ".") T[y + dy][x + dx] = "F";
        if (e === "foudre") {
          const dep = [[x, y], ...V4.map(([dx, dy]) => [x + dx, y + dy])].find(([a, b]) => ok(a, b) && T[b][a] === "W");
          if (dep) {
            const vus = new Set([dep.join()]), file = [dep];
            while (file.length) { const [a, b] = file.shift(); for (const [dx, dy] of V4) { const k = [a + dx, b + dy]; if (ok(k[0], k[1]) && T[k[1]][k[0]] === "W" && !vus.has(k.join())) { vus.add(k.join()); file.push(k); } } }
            for (const v of U.filter(w => !w.ko && vus.has([w.x, w.y].join()))) { v.pv -= 12; v.st.gele = true; J.fait(u, "inflige", 12); J.fait(v, "recu", 12); fx.push([v.uid, "−12 foudre", v.camp === "j" ? "rose" : "or"]); }
            msgs.push(`${nomDe(u.id)} électrifie ${vus.size} cases d'eau`);
          } else for (const v of U.filter(w => !w.ko && w.camp !== u.camp && Math.max(Math.abs(w.x - x), Math.abs(w.y - y)) === 1)) { v.pv -= 6; J.fait(u, "inflige", 6); J.fait(v, "recu", 6); fx.push([v.uid, "−6", "or"]); }
        }
      }
      // 3. le feu gagne la forêt, puis s'éteint
      const nouv = [];
      for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) if (T[y][x] === "X") { for (const [dx, dy] of V4) if (ok(x + dx, y + dy) && T[y + dy][x + dx] === "F") nouv.push([x + dx, y + dy]); age[y][x]++; if (age[y][x] >= 3) T[y][x] = "."; }
      for (const [x, y] of nouv) { T[y][x] = "X"; age[y][x] = 0; }
      if (nouv.length) msgs.push(`le feu gagne ${nouv.length} case${nouv.length > 1 ? "s" : ""} de forêt`);
      // 4. le terrain agit sur ceux qui s'y trouvent, puis les coups au contact
      for (const u of U.filter(v => !v.ko)) {
        const c = T[u.y][u.x];
        if (c === "X") { u.pv -= 8; J.fait(u, "recu", 8); fx.push([u.uid, "−8 feu", "rose"]); }
        if (c === "I" && !u.st.gele && u.id !== "yeti" && u.id !== "fenrir") { u.st.gele = true; fx.push([u.uid, "glace", "mot"]); }
      }
      for (const u of U.filter(v => !v.ko)) for (const [dx, dy] of V4) { const v = at(u.x + dx, u.y + dy); if (v && v.camp !== u.camp) coup(J, u, v, 0.4, fx); }
      for (const u of U) if (!u.ko && u.pv <= 0) { u.pv = 0; u.ko = true; J.tomber(u); fx.push([u.uid, "K.O.", "mot"]); }
      J.pas_(vue(), `Pas ${pas}${msgs.length ? " : " + msgs.join(" · ") : ""}`, fx, 750);
      if (!U.some(u => u.camp === "j" && !u.ko) || !U.some(u => u.camp === "a" && !u.ko)) break;
    }
    const pct = c => { const l = U.filter(u => u.camp === c); return l.reduce((s, u) => s + Math.max(0, u.pv), 0) / Math.max(1, l.reduce((s, u) => s + u.max, 0)); };
    const g = !U.some(u => u.camp === "a" && !u.ko) || (U.some(u => u.camp === "j" && !u.ko) && pct("j") > pct("a"));
    const brules = U.filter(u => u.camp === "j" && J.faits[u.uid] && J.faits[u.uid].recu >= 16);
    const plus = [`Fin : ${Math.round(pct("j") * 100)} % de PV pour toi, ${Math.round(pct("a") * 100)} % pour lui.`];
    if (brules.length) plus.push(`${brules.map(u => nomDe(u.id)).join(" et ")} ${brules.length > 1 ? "ont" : "a"} beaucoup souffert du terrain : change son trajet.`);
    return { pas: J.pas, gagne: g, recit: J.recit(plus) };
  }
  const CLS = { ".": "", F: "el-foret", W: "el-eau", I: "el-glace", X: "el-feu", R: "el-roche" };
  function grille(T, us, chemins, o = {}) {
    const g = h("div", "sp-grille el-grille"); g.style.gridTemplateColumns = `repeat(${N},1fr)`;
    for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
      const c = h("button", "sp-cell " + CLS[T[y][x]] + (y === N - 1 ? " j" : ""));
      for (const [camp, id, ch] of chemins) { const k = ch.findIndex(p => p[0] === x && p[1] === y); if (k > 0) c.append(h("span", "el-pas " + camp + (o.sel === id ? " sel" : ""), k)); }
      const u = us.find(v => v.x === x && v.y === y && !v.ko);
      if (u) c.append(pion(u));
      if (o.onCell) c.onclick = () => o.onCell(x, y, u);
      g.append(c);
    }
    return g;
  }
  function rendreVue(z, v) { z.append(grille(v.T, v.u, []), h("div", "sp-leg", `pas ${v.pas}/${PAS} · vert forêt · bleu eau · blanc glace · orange feu · gris roche`)); }
  function rendrePrep(z, prep, et, maj) {
    const us = [], ch = [];
    et.eq.forEach(([id, c], i) => { us.push({ uid: "a" + i, id, camp: "a", x: c[0][0], y: c[0][1], pv: 1, max: 1 }); ch.push(["a", id, c]); });
    for (const id of prep.eq) { const c = prep.chemins[id]; if (c && c.length) { us.push({ uid: "j" + id, id, camp: "j", x: c[0][0], y: c[0][1], pv: 1, max: 1 }); ch.push(["j", id, c]); } }
    z.append(grille(et.terr, us, ch, { sel: prep._sel, onCell: (x, y, u) => {
      if (u && u.camp === "j") { prep._sel = u.id; return maj(); }
      const id = prep._sel; if (!id) return;
      const c = prep.chemins[id] = prep.chemins[id] || [];
      if (y === N - 1 && !us.some(v => v.camp === "j" && v.id !== id && v.x === x && v.y === y)) { prep.chemins[id] = [[x, y]]; return maj(); }
      const last = c[c.length - 1];
      if (last && Math.abs(last[0] - x) + Math.abs(last[1] - y) === 1 && c.length <= MAXT) { c.push([x, y]); maj(); }
    } }));
    z.append(h("div", "sp-leg", prep._sel ? `${nomDe(prep._sel)} (${ELEM[prep._sel].txt}) : touche la rangée du bas pour son départ, puis les cases voisines pour son trajet (${MAXT} pas max).` : "Choisis un héros, puis dessine son trajet."));
    const r = h("div", "rangee"); const bx = h("button", "btn sec", "Effacer son trajet"); bx.disabled = !prep._sel; bx.onclick = () => { const c = prep.chemins[prep._sel]; if (c) prep.chemins[prep._sel] = c.slice(0, 1); maj(); }; r.append(bx); z.append(r);
    const box = h("div", "sp-bloc"); box.append(h("div", "sp-tit", `Tes héros · ${prep.eq.length}/3`));
    const g = h("div", "sp-reserve");
    for (const id of et.reserve) {
      const b = h("button", "sp-hero" + (prep.eq.includes(id) ? " pris" : "") + (prep._sel === id ? " sel" : "")); b.append(vignette(id, { stade: 1, nom: false }), h("b", "", nomDe(id)), h("span", "", ELEM[id].txt));
      b.onclick = () => {
        if (prep.eq.includes(id)) { if (prep._sel === id) { prep.eq.splice(prep.eq.indexOf(id), 1); delete prep.chemins[id]; prep._sel = null; } else prep._sel = id; }
        else if (prep.eq.length < 3) { prep.eq.push(id); const libre = [0, 1, 2, 3, 4, 5, 6].find(x => !prep.eq.some(k => prep.chemins[k] && prep.chemins[k][0] && prep.chemins[k][0][0] === x)); prep.chemins[id] = [[libre, N - 1]]; prep._sel = id; }
        maj();
      };
      g.append(b);
    }
    box.append(g, h("div", "sp-leg", "Touche un héros choisi pour dessiner son trajet ; touche-le encore pour le retirer.")); z.append(box);
  }
  enregistrer({ groupe: "strategie", id: "s-elements", num: "9", nom: "Les Éléments vivants", accroche: "Dessine les trajets. Le feu, l'eau, la foudre et la glace font le reste.", duree: "50 s", images: ["bahamut-1", "thor-1", "cerbere-1"], fond: "linear-gradient(160deg,#162a26,#131024)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => { const eq = tirerN(R, et.reserve, 3), xs = tirerN(R, [0, 1, 2, 3, 4, 5, 6], 3), chemins = {}; eq.forEach((id, i) => { const c = [[xs[i], 6]]; for (let k = 0; k < 5; k++) { const [x, y] = c[c.length - 1]; const o = [[x, y - 1], [x - 1, y], [x + 1, y]].filter(([a, b]) => a >= 0 && a < 7 && b >= 0); c.push(tirer(R, o)); } chemins[id] = c; }); return { eq, chemins }; }, initPrep: et => ({ eq: [et.reserve[0], et.reserve[1], et.reserve[2]], chemins: { [et.reserve[0]]: [[1, 6], [1, 5], [1, 4]], [et.reserve[1]]: [[3, 6], [3, 5], [3, 4]], [et.reserve[2]]: [[5, 6], [5, 5], [5, 4]] }, _sel: et.reserve[0] }),
      pret: p => p.eq.length === 3 ? true : "choisis 3 héros", simuler, rendreVue, rendrePrep,
      tuto: ["Chaque héros suit le trajet que tu dessines, et peint son élément.", "Le feu gagne la forêt, la foudre court dans l'eau, la glace fige.", "Le terrain fait les dégâts, même à tes héros !"] }) });
})();
