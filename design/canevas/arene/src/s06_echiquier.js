// ═════════════════════════════ S6 · L'ÉCHIQUIER DES LÉGENDES ═════════════════════════════
// Plateau 6×6 : tes 3 rangées en bas. Chaque héros se déplace et frappe selon un MOTIF fixe.
// Un de tes héros est ton Chef : s'il tombe, tu perds. Chaque pièce vise sa cible prioritaire.
(function () {
  const N = 6;
  const MOTIF = {
    kitsune: { dep: "cavalier", atk: "adj", txt: "saute en L, frappe autour d'elle" },
    thor: { dep: "roi", atk: "ligne", txt: "frappe en ligne droite, de loin, le premier qu'il voit" },
    golem: { dep: "fixe", atk: "adj", txt: "ne bouge jamais, frappe autour, prend −30 %" },
    yeti: { dep: "roi", atk: "croix", txt: "frappe les 4 cases en croix et les gèle" },
    minotaure: { dep: "charge", atk: "adj", txt: "charge en ligne droite jusqu'à heurter, ×1,5" },
    fenrir: { dep: "roi2", atk: "adj", txt: "court de 2 cases, frappe autour" },
    bahamut: { dep: "roi", atk: "soin", txt: "soigne ses voisins (10), sinon frappe" },
    wukong: { dep: "tour", atk: "adj", txt: "file en ligne jusqu'à 3 cases, frappe autour" },
    anubis: { dep: "fou", atk: "adj", txt: "diagonale jusqu'à 3 cases ; relève un voisin tombé (une fois)" },
    cerbere: { dep: "roi", atk: "avant3", txt: "frappe les 3 cases devant lui" },
    doudou: { dep: "roi", atk: "adj", txt: "ses voisins prennent −30 %" },
    babayaga: { dep: "fou", atk: "adj", txt: "diagonale ; ses coups maudissent (3 par tour)" },
  };
  const PRIO = [["proche", "le plus proche"], ["faible", "le plus faible"], ["chef", "son Chef"]];
  const ETAPES = [
    { nom: "La garde du Nord", desc: "Son Chef : Bahamut, au fond, derrière un Golem. Thor tire de loin.", eq: [["golem", 2, 1, "proche"], ["bahamut", 2, 0, "proche", true], ["thor", 4, 0, "faible"], ["fenrir", 1, 2, "chef"], ["cerbere", 4, 2, "proche"]], reserve: ["kitsune", "minotaure", "yeti", "golem", "bahamut", "wukong", "anubis"] },
    { nom: "Les bondisseurs", desc: "Kitsune et Wukong visent ton Chef. Son Chef : Anubis.", eq: [["kitsune", 1, 1, "chef"], ["wukong", 4, 1, "chef"], ["anubis", 3, 0, "proche", true], ["yeti", 2, 1, "proche"], ["babayaga", 3, 2, "faible"]], reserve: ["golem", "doudou", "thor", "cerbere", "fenrir", "bahamut", "minotaure"] },
    { nom: "Boss : le Troll de pierre", desc: "Une pièce géante (260 PV) qui balaie toute une rangée. C'est lui, le Chef.", boss: true, eq: [["golem", 2, 0, "proche", true], ["cerbere", 1, 1, "proche"], ["cerbere2", 4, 1, "proche"]], reserve: ["kitsune", "thor", "minotaure", "yeti", "bahamut", "fenrir", "anubis", "wukong"] },
  ];
  const cheb = (a, b) => Math.max(Math.abs(a.x - b.x), Math.abs(a.y - b.y));
  function simuler(prep, et) {
    const J = Journal();
    const U = [];
    for (const id of prep.eq) { const [x, y] = prep.pos[id]; U.push(Object.assign(unite(id, "j", { pv: Math.round(KITS[id].pv * 1.4) }), { x, y, prio: prep.prio[id], chef: prep.chef === id, dir: -1 })); }
    for (const [id0, x, y, prio, chef] of et.eq) { const id = id0 === "cerbere2" ? "cerbere" : id0; const boss = et.boss && chef; U.push(Object.assign(unite(id, "a", boss ? { pv: 260, att: 12, stade: 3 } : { pv: Math.round(KITS[id].pv * 1.9) }), { x, y, prio, chef: !!chef, dir: 1, boss, idVue: boss ? "troll" : id })); }
    const at = (x, y) => U.find(u => !u.ko && u.x === x && u.y === y);
    const dans = (x, y) => x >= 0 && y >= 0 && x < N && y < N;
    let tour = 0;
    const vue = () => ({ u: U.map(u => ({ ...copieU(u), id: u.idVue || u.id, chef: u.chef })), tour });
    function cibleDe(u) {
      const adv = U.filter(v => !v.ko && v.camp !== u.camp); if (!adv.length) return null;
      if (u.prio === "chef") { const c = adv.find(v => v.chef); if (c) return c; }
      return adv.sort((a, b) => (u.prio === "faible" ? a.pv - b.pv : cheb(u, a) - cheb(u, b)) || cheb(u, a) - cheb(u, b) || a.uid - b.uid)[0];
    }
    function attaquables(u) {
      const m = MOTIF[u.id] || MOTIF.golem, res = [];
      if (u.boss) { for (let x = 0; x < N; x++) { const v = at(x, u.y + 1); if (v && v.camp !== u.camp) res.push(v); } for (const [dx, dy] of [[-1, 0], [1, 0], [0, 1], [-1, 1], [1, 1]]) { const v = at(u.x + dx, u.y + dy); if (v && v.camp !== u.camp && !res.includes(v)) res.push(v); } return res; }
      if (m.atk === "ligne") { for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) for (let k = 1; k < N; k++) { const v = at(u.x + dx * k, u.y + dy * k); if (v) { if (v.camp !== u.camp) res.push(v); break; } } return res; }
      if (m.atk === "croix") { for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const v = at(u.x + dx, u.y + dy); if (v && v.camp !== u.camp) res.push(v); } return res; }
      if (m.atk === "avant3") { for (const dx of [-1, 0, 1]) { const v = at(u.x + dx, u.y + u.dir); if (v && v.camp !== u.camp) res.push(v); } return res; }
      for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) { if (!dx && !dy) continue; const v = at(u.x + dx, u.y + dy); if (v && v.camp !== u.camp) res.push(v); }
      return res;
    }
    function deplacements(u) {
      const m = MOTIF[u.id] || MOTIF.golem, res = [];
      const libre = (x, y) => dans(x, y) && !at(x, y);
      if (u.boss || m.dep === "fixe") return res;
      if (m.dep === "roi" || m.dep === "roi2") for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) if ((dx || dy) && libre(u.x + dx, u.y + dy)) res.push([u.x + dx, u.y + dy]);
      if (m.dep === "cavalier") for (const [dx, dy] of [[1, 2], [2, 1], [-1, 2], [-2, 1], [1, -2], [2, -1], [-1, -2], [-2, -1]]) if (libre(u.x + dx, u.y + dy)) res.push([u.x + dx, u.y + dy]);
      const glisse = (dirs, max) => { for (const [dx, dy] of dirs) for (let k = 1; k <= max; k++) { if (!libre(u.x + dx * k, u.y + dy * k)) break; res.push([u.x + dx * k, u.y + dy * k]); } };
      if (m.dep === "tour") glisse([[1, 0], [-1, 0], [0, 1], [0, -1]], 3);
      if (m.dep === "fou") glisse([[1, 1], [-1, 1], [1, -1], [-1, -1]], 3);
      return res;
    }
    function frapper_(u, v, k, fx) {
      if (U.some(d => !d.ko && d.id === "doudou" && d.camp === v.camp && d !== v && cheb(d, v) === 1)) k *= 0.7;
      if (v.id === "golem" && !v.boss) k *= 0.7;
      coup(J, u, v, k, fx);
      if (u.id === "babayaga" && !v.ko) v.maudit = 3;
      if (v.ko) for (const a of U) if (!a.ko && a.id === "anubis" && a.camp === v.camp && !a.releve && cheb(a, v) === 1) { a.releve = true; v.ko = false; v.pv = Math.round(v.max * 0.4); fx.push([v.uid, "relevé !", "gros"]); }
    }
    J.pas_(vue(), "Les pièces sont en place", [], 900);
    while (tour < 30) {
      tour++;
      for (const u of U.filter(x => !x.ko).sort((a, b) => b.vit - a.vit || (a.camp === b.camp ? 0 : a.camp === "j" ? -1 : 1) || a.uid - b.uid)) {
        if (u.ko) continue;
        const fx = []; let msg = "";
        if (u.st.gele) { delete u.st.gele; J.fait(u, "gele"); fx.push([u.uid, "gelé", "mot"]); J.pas_(vue(), `${nomDe(u.id)} est gelé`, fx, 350); continue; }
        if (u.maudit) { u.pv -= 3; fx.push([u.uid, "−3", "rose"]); if (u.pv <= 0) { u.ko = true; u.pv = 0; J.tomber(u); } if (u.ko) continue; }
        const c = cibleDe(u); if (!c) break;
        const m = MOTIF[u.id] || MOTIF.golem;
        if (m.atk === "soin") { const bl = U.filter(v => !v.ko && v.camp === u.camp && v !== u && cheb(u, v) === 1 && v.pv < v.max * 0.8); if (bl.length) { for (const v of bl) guerir(J, v, 10, fx); J.pas_(vue(), `${nomDe(u.id)} soigne ses voisins`, fx, 450); continue; } }
        let cibles = attaquables(u);
        if (!cibles.length) {
          if (m.dep === "charge") {
            const dirs = [[0, u.dir], [1, 0], [-1, 0], [0, -u.dir]].sort((p, q) => cheb({ x: u.x + p[0], y: u.y + p[1] }, c) - cheb({ x: u.x + q[0], y: u.y + q[1] }, c));
            const [dx, dy] = dirs[0]; let k = 0; while (dans(u.x + dx, u.y + dy) && !at(u.x + dx, u.y + dy) && k < 5) { u.x += dx; u.y += dy; k++; }
            const v = at(u.x + dx, u.y + dy); if (v && v.camp !== u.camp) { frapper_(u, v, 1.5, fx); msg = `${nomDe(u.id)} charge et heurte ${nomDe(v.id)}`; } else msg = `${nomDe(u.id)} charge`;
            J.pas_(vue(), msg, fx, 500); continue;
          }
          const pas = u.id === "fenrir" ? 2 : 1;
          for (let s = 0; s < pas; s++) {
            const opts = deplacements(u); if (!opts.length) break;
            opts.sort((p, q) => cheb({ x: p[0], y: p[1] }, c) - cheb({ x: q[0], y: q[1] }, c) || (Math.abs(p[0] - c.x) + Math.abs(p[1] - c.y)) - (Math.abs(q[0] - c.x) + Math.abs(q[1] - c.y)) || p[1] - q[1] || p[0] - q[0]);
            if (cheb({ x: opts[0][0], y: opts[0][1] }, c) >= cheb(u, c) && s > 0) break;
            [u.x, u.y] = opts[0];
            if (attaquables(u).length) break;
          }
          cibles = attaquables(u);
          msg = `${nomDe(u.id)} se déplace`;
        }
        if (cibles.length) {
          const v = cibles.includes(c) ? c : cibles.sort((a, b) => a.pv - b.pv)[0];
          if (u.boss) { for (const w of cibles) frapper_(u, w, 1, fx); msg = "Le Troll balaie toute la rangée !"; }
          else if (m.atk === "croix" || m.atk === "avant3") { for (const w of cibles) { frapper_(u, w, m.atk === "croix" ? 0.7 : 1, fx); if (m.atk === "croix" && !w.ko) w.st.gele = true; } msg = `${nomDe(u.id)} frappe ${cibles.length} pièce${cibles.length > 1 ? "s" : ""}`; }
          else { frapper_(u, v, 1, fx); msg = `${nomDe(u.id)} frappe ${nomDe(v.id)}`; }
        }
        J.pas_(vue(), msg, fx, 480);
        const chefJ = U.find(v => v.camp === "j" && v.chef), chefA = U.find(v => v.camp === "a" && v.chef);
        if (chefJ.ko || chefA.ko) break;
      }
      const chefJ = U.find(v => v.camp === "j" && v.chef), chefA = U.find(v => v.camp === "a" && v.chef);
      if (chefJ.ko || chefA.ko) break;
    }
    const chefJ = U.find(v => v.camp === "j" && v.chef), chefA = U.find(v => v.camp === "a" && v.chef);
    const g = chefA.ko && !chefJ.ko;
    const plus = [];
    if (chefJ.ko) plus.push(`Ton Chef (${nomDe(chefJ.id)}) est tombé au tour ${tour}.`);
    if (!chefJ.ko && !chefA.ko) plus.push("Personne n'a atteint le Chef adverse en 30 tours.");
    return { pas: J.pas, gagne: g, recit: J.recit(plus) };
  }
  function plateau(us, o = {}) {
    const g = h("div", "sp-grille ec-grille"); g.style.gridTemplateColumns = `repeat(${N},1fr)`;
    for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
      const c = h("button", "sp-cell " + (y >= 3 ? "j" : "a")); c.dataset.cible = `c${x}-${y}`;
      const u = us.find(v => v.x === x && v.y === y && !v.ko) || us.find(v => v.x === x && v.y === y);
      if (u) c.append(pion(u, { chef: u.chef, tag: u.chef ? "Chef" : o.tag && o.tag(u) }));
      if (o.sel && u && o.sel === u.id && u.camp === "j") c.classList.add("ok");
      if (o.onCell) c.onclick = () => o.onCell(x, y, u);
      g.append(c);
    }
    return g;
  }
  function rendreVue(z, v) { z.append(plateau(v.u), h("div", "sp-leg", `tour ${v.tour}`)); }
  function rendrePrep(z, prep, et, maj) {
    const ennemis = et.eq.map(([id0, x, y, prio, chef], i) => ({ uid: "a" + i, id: et.boss && chef ? "troll" : id0 === "cerbere2" ? "cerbere" : id0, camp: "a", x, y, pv: 1, max: 1, chef: !!chef, stade: et.boss && chef ? 3 : 1 }));
    const miens = prep.eq.map(id => ({ uid: "j" + id, id, camp: "j", x: prep.pos[id][0], y: prep.pos[id][1], pv: 1, max: 1, chef: prep.chef === id }));
    z.append(plateau([...ennemis, ...miens], {
      sel: prep._sel,
      onCell: (x, y, u) => {
        if (u && u.camp === "j") { prep._sel = prep._sel === u.id ? null : u.id; return maj(); }
        if (prep._sel && y >= 3 && !u) { prep.pos[prep._sel] = [x, y]; prep._sel = null; maj(); }
      },
    }));
    z.append(h("div", "sp-leg", prep._sel ? `Touche une case de tes 3 rangées pour ${nomDe(prep._sel)}` : "Touche une de tes pièces pour la déplacer."));
    choixHeros(z, et.reserve, prep.eq, 5, () => {
      for (const id of prep.eq) if (!prep.pos[id]) { outer: for (let y = 3; y < N; y++) for (let x = 0; x < N; x++) if (!Object.entries(prep.pos).some(([k, p]) => prep.eq.includes(k) && p[0] === x && p[1] === y)) { prep.pos[id] = [x, y]; break outer; } }
      for (const k of Object.keys(prep.pos)) if (!prep.eq.includes(k)) delete prep.pos[k];
      if (!prep.eq.includes(prep.chef)) prep.chef = prep.eq[0];
      maj();
    }, "Tes pièces");
    const b = h("div", "sp-bloc"); b.append(h("div", "sp-tit", "Motifs, Chef et cibles"));
    for (const id of prep.eq) {
      const l = h("div", "sp-ligne"); l.append(vignette(id, { stade: 1, nom: false }), h("b", "", nomDe(id)));
      const chef = h("button", "btn " + (prep.chef === id ? "mauve" : "sec"), prep.chef === id ? "Chef" : "faire Chef"); chef.style.padding = "4px 8px"; chef.onclick = () => { prep.chef = id; maj(); };
      l.append(chef, selecteur(PRIO, prep.prio[id] || "proche", v => { prep.prio[id] = v; }), h("span", "sp-leg", MOTIF[id] ? MOTIF[id].txt : ""));
      b.append(l);
    }
    z.append(b);
  }
  enregistrer({ groupe: "strategie", id: "s-echiquier", num: "6", nom: "L'Échiquier des légendes", accroche: "Chaque héros a son motif, comme aux échecs. Protège ton Chef.", duree: "45 s", images: ["kitsune-1", "golem-1", "thor-1"], fond: "linear-gradient(160deg,#1c2a2a,#131022)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => { const eq = tirerN(R, et.reserve, 5), cells = tirerN(R, [...Array(18).keys()], 5), pos = {}, prio = {}; eq.forEach((id, i) => { pos[id] = [cells[i] % 6, 3 + Math.floor(cells[i] / 6)]; prio[id] = tirer(R, PRIO)[0]; }); return { eq, pos, prio, chef: tirer(R, eq) }; }, initPrep: et => { const eq = et.reserve.slice(0, 5), pos = {}, prio = {}; eq.forEach((id, i) => { pos[id] = [i + (i > 2 ? 0 : 1), i < 3 ? 3 : 4]; prio[id] = "proche"; }); return { eq, pos, prio, chef: eq[2], _sel: null }; },
      pret: p => p.eq.length === 5 ? true : "choisis 5 pièces", simuler, rendreVue, rendrePrep,
      tuto: ["Place 5 pièces sur tes 3 rangées du bas.", "Chacune bouge et frappe selon son motif.", "Protège ton Chef : s'il tombe, tu perds."] }) });
})();
