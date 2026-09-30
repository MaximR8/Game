// ═════════════════════════════ S3 · LA FIGURE CÉLESTE ═════════════════════════════
// Place 4 étoiles (tes héros) sur ta carte du ciel (4×3, la rangée du haut est devant).
// Trace jusqu'à 4 liens. La forme dessinée donne une FIGURE, et chaque lien active l'effet de ses deux héros.
// Chacun frappe l'ennemi le plus en avant de sa colonne (sinon la colonne la plus proche).
(function () {
  const W = 4, H = 3, MAXL = 4;
  const LIEN = {
    bahamut: "soigne ses liés de 4 par manche", thor: "+3 ATT par lien (la foudre rebondit)", golem: "prend la moitié des coups de ses liés", anubis: "ramène le 1er lié qui tombe (40 %)",
    kitsune: "ses liés frappent ×1,2", yeti: "chaque coup de ses liés retire 1 ATT à la cible", fenrir: "+2 ATT par lien", cerbere: "ses liés ripostent à 20 %",
    banshee: "les coups contre ses liés −20 %", babayaga: "les coups de ses liés maudissent (2 par manche)", wukong: "ses liés frappent une 2e fois (×0,35)", minotaure: "le 1er coup de ses liés compte double",
    quetzalcoatl: "+2 ATT à ses liés", doudou: "ses liés prennent −25 %",
  };
  const FIG = { triangle: "Triangle : chaque membre soigne les autres (3 par manche)", etoile: "Cœur : le centre prend −50 %, ses liés +2 ATT", cercle: "Cercle : les coups reçus sont partagés entre les membres", ligne: "Ligne : la tête de ligne (la plus en avant) +3 ATT par étoile" };
  function figure(liens, pos) {
    const adj = {}; for (const [a, b] of liens) { (adj[a] = adj[a] || new Set()).add(b); (adj[b] = adj[b] || new Set()).add(a); }
    const n = Object.keys(adj);
    for (const a of n) for (const b of adj[a]) for (const c of adj[b]) if (c !== a && adj[c].has(a)) return { f: "triangle", membres: [a, b, c] };
    const centre = n.find(a => adj[a].size >= 3); if (centre) return { f: "etoile", centre, membres: [centre, ...adj[centre]] };
    if (n.length === 4 && liens.length === 4 && n.every(a => adj[a].size === 2)) return { f: "cercle", membres: n };
    // la plus longue chaîne
    let meil = null;
    for (const a of n.filter(x => adj[x].size === 1)) { const ch = [a]; let prec = null, cur = a; while (true) { const nx = [...adj[cur]].find(x => x !== prec && !ch.includes(x)); if (!nx) break; ch.push(nx); prec = cur; cur = nx; } if (!meil || ch.length > meil.length) meil = ch; }
    if (meil && meil.length >= 3) { const tete = meil[0] === undefined ? null : [meil[0], meil[meil.length - 1]].sort((x, y) => pos[x][1] - pos[y][1])[0]; return { f: "ligne", tete, membres: meil }; }
    return null;
  }
  const ETAPES = [
    { nom: "La Ligne du Nord", desc: "Une Ligne de 4 menée par Yéti. Sa tête frappe fort.", pos: { yeti: [1, 0], fenrir: [1, 1], thor: [2, 1], cerbere: [2, 2] }, liens: [["yeti", "fenrir"], ["fenrir", "thor"], ["thor", "cerbere"]], reserve: ["golem", "kitsune", "bahamut", "minotaure", "anubis", "wukong"] },
    { nom: "Le Triangle des eaux", desc: "Un Triangle qui se soigne, et une Banshee liée à Bahamut.", force: 1.4, pos: { golem: [1, 0], kitsune: [2, 0], bahamut: [1, 1], banshee: [2, 2] }, liens: [["golem", "kitsune"], ["kitsune", "bahamut"], ["bahamut", "golem"], ["banshee", "bahamut"]], reserve: ["thor", "fenrir", "yeti", "babayaga", "minotaure", "quetzalcoatl"] },
    { nom: "Boss : le Dragon du Lumeçon", desc: "Son souffle frappe toute une colonne. Toutes les 3 manches, il brise ton premier lien.", boss: true, pos: { doudou: [1, 0], golem: [0, 0], minotaure: [3, 0] }, liens: [], reserve: ["golem", "kitsune", "bahamut", "anubis", "thor", "doudou", "yeti", "quetzalcoatl"] },
  ];
  function equipe(camp, pos, liens, boss, force = 1) {
    const us = Object.entries(pos).map(([id, [x, y]]) => Object.assign(unite(id, camp, boss && id === "doudou" ? { pv: 260, att: 10, stade: 3 } : { pv: Math.round(KITS[id].pv * 1.5 * (camp === "a" ? force : 1)) }), { x, y, boss: boss && id === "doudou" }));
    const by = id => us.find(u => u.id === id);
    for (const u of us) u.lies = liens.filter(l => l.includes(u.id)).map(l => by(l[0] === u.id ? l[1] : l[0])).filter(Boolean);
    const fg = figure(liens, pos);
    for (const u of us) {
      if (u.id === "thor") u.att += 3 * u.lies.length;
      if (u.id === "fenrir") u.att += 2 * u.lies.length;
      if (u.lies.some(l => l.id === "quetzalcoatl")) u.att += 2;
    }
    if (fg && fg.f === "etoile") { const c = by(fg.centre); c.centre = true; for (const l of c.lies) l.att += 2; }
    if (fg && fg.f === "ligne") { const t = by(fg.tete); if (t) t.att += 3 * fg.membres.length; }
    if (fg) for (const id of fg.membres) { const u = by(id); if (u) u.fig = fg.f; }
    return { us, fg };
  }
  function simuler(prep, et) {
    const Jr = Journal();
    const EJ = equipe("j", prep.pos, prep.liens), EA = equipe("a", et.pos, et.liens, et.boss, et.force);
    const J = EJ.us, A = EA.us, tous = [...J, ...A];
    let manche = 0, liensJ = prep.liens.slice();
    const vue = () => ({ j: J.map(u => ({ ...copieU(u), x: u.x, y: u.y })), a: A.map(u => ({ ...copieU(u), x: u.x, y: u.y })), lj: liensJ.slice(), la: et.liens, fj: EJ.fg && EJ.fg.f, fa: EA.fg && EA.fg.f, manche });
    const cibleDe = u => {
      const adv = (u.camp === "j" ? A : J).filter(x => !x.ko); if (!adv.length) return null;
      return adv.sort((a, b) => Math.abs(a.x - u.x) - Math.abs(b.x - u.x) || a.y - b.y || a.x - b.x)[0];
    };
    function toucher(src, cible, k, fx) {
      if (cible.ko) return;
      if (src.lies.some(l => l.id === "kitsune" && !l.ko)) k *= 1.2;
      if (cible.lies.some(l => l.id === "banshee" && !l.ko)) k *= 0.8;
      if (cible.lies.some(l => l.id === "doudou" && !l.ko)) k *= 0.75;
      if (cible.centre) k *= 0.5;
      if (src.lies.some(l => l.id === "minotaure") && !src.premier) { src.premier = true; k *= 2; }
      const golem = cible.lies.find(l => l.id === "golem" && !l.ko);
      const cercle = cible.fig === "cercle" ? (cible.camp === "j" ? J : A).filter(x => x.fig === "cercle" && !x.ko) : null;
      if (cercle && cercle.length > 1) { const d0 = Math.round(src.att * k * typeMult(src, cible) / cercle.length); for (const m of cercle) { m.pv -= d0; Jr.fait(src, "inflige", d0); Jr.fait(m, "recu", d0); fx.push([m.uid, `−${d0}`, "rose"]); if (m.pv <= 0) { m.ko = true; m.pv = 0; Jr.tomber(m); } } }
      else if (golem) { coup(Jr, src, cible, k * 0.5, fx); coup(Jr, src, golem, k * 0.5, fx); }
      else coup(Jr, src, cible, k, fx);
      if (src.lies.some(l => l.id === "yeti" && !l.ko)) cible.att = Math.max(Math.round(cible.att0 / 2), cible.att - 1);
      if (src.lies.some(l => l.id === "babayaga" && !l.ko)) cible.maudit = 2;
      if (cible.lies.some(l => l.id === "cerbere" && !l.ko) && !cible.ko) coup(Jr, cible, src, 0.2, fx);
      for (const l of cible.lies) if (cible.ko && l.id === "anubis" && !l.ko && !l.aRamene) { l.aRamene = true; cible.ko = false; cible.pv = Math.round(cible.max * 0.4); fx.push([cible.uid, "revient !", "gros"]); }
    }
    for (const u of tous) u.att0 = u.att;
    Jr.pas_(vue(), `Ta figure : ${EJ.fg ? FIG[EJ.fg.f].split(" :")[0] : "aucune"} · la sienne : ${EA.fg ? FIG[EA.fg.f].split(" :")[0] : "aucune"}`, [], 1300);
    while (manche < 20 && J.some(u => !u.ko) && A.some(u => !u.ko)) {
      manche++;
      if (et.boss && manche % 3 === 0 && liensJ.length) { const [a, b] = liensJ.shift(); const ua = J.find(u => u.id === a), ub = J.find(u => u.id === b); ua.lies = ua.lies.filter(x => x !== ub); ub.lies = ub.lies.filter(x => x !== ua); Jr.pas_(vue(), `Le dragon brise le lien ${nomDe(a)} — ${nomDe(b)} !`, [[ua.uid, "lien brisé", "mot"]], 1000); }
      for (const u of tous.filter(x => !x.ko).sort((a, b) => b.vit - a.vit || (a.camp === b.camp ? 0 : a.camp === "j" ? -1 : 1) || a.uid - b.uid)) {
        if (u.ko) continue;
        const c = cibleDe(u); if (!c) break;
        const fx = [];
        if (u.boss) { const col = J.filter(x => !x.ko && x.x === c.x); for (const x of col) coup(Jr, u, x, 1, fx); Jr.pas_(vue(), `Le dragon souffle sur toute la colonne ${c.x + 1}`, fx, 700); continue; }
        toucher(u, c, 1, fx);
        if (u.lies.some(l => l.id === "wukong" && !l.ko) && !c.ko) toucher(u, c, 0.35, fx);
        Jr.pas_(vue(), `${nomDe(u.id)} frappe ${nomDe(c.id)}`, fx, 380);
      }
      const fx = [];
      for (const u of tous.filter(x => !x.ko)) {
        if (u.maudit) { u.pv -= 2; fx.push([u.uid, "−2", "rose"]); if (u.pv <= 0) { u.ko = true; u.pv = 0; Jr.tomber(u); } }
        for (const l of u.lies) if (l.id === "bahamut" && !l.ko) guerir(Jr, u, 4, fx);
        if (u.fig === "triangle") guerir(Jr, u, 3 * ((u.camp === "j" ? J : A).filter(x => x.fig === "triangle" && !x.ko && x !== u).length), fx);
      }
      if (fx.length) Jr.pas_(vue(), "Fin de manche : soins et malédictions", fx, 500);
    }
    const g = A.every(u => u.ko);
    const plus = []; if (!EJ.fg) plus.push("Tu n'avais aucune figure : il faut au moins 3 étoiles liées.");
    const seul = J.find(u => !u.lies.length && Jr.faits[u.uid] && Jr.faits[u.uid].tombe != null); if (seul) plus.push(`${nomDe(seul.id)} n'était lié à personne, et il est tombé.`);
    return { pas: Jr.pas, gagne: g, recit: Jr.recit(plus) };
  }
  // ——— dessin ———
  function grille(pos, liens, camp, inverse, o = {}) {
    const g = h("div", "sp-grille fg-grille"); g.style.gridTemplateColumns = `repeat(${W},1fr)`;
    const cells = {};
    for (let r = 0; r < H; r++) for (let x = 0; x < W; x++) {
      const y = inverse ? H - 1 - r : r;
      const c = h("button", "sp-cell " + camp); c.dataset.cible = `${camp}${x}-${y}`; cells[`${x}-${y}`] = c;
      if (o.onCell) c.onclick = () => o.onCell(x, y);
      g.append(c);
    }
    for (const u of pos) { const c = cells[`${u.x}-${u.y}`]; if (c) { c.append(pion(u, { tag: o.tag && o.tag(u) })); if (o.onPion) c.onclick = () => o.onPion(u); if (o.sel === u.id) c.classList.add("ok"); } }
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg"); svg.setAttribute("viewBox", `0 0 ${W} ${H}`); svg.setAttribute("preserveAspectRatio", "none"); svg.classList.add("fg-liens");
    const at = id => pos.find(u => u.id === id);
    for (const [a, b] of liens) { const A = at(a), B = at(b); if (!A || !B) continue; const yA = inverse ? H - 1 - A.y : A.y, yB = inverse ? H - 1 - B.y : B.y; svg.insertAdjacentHTML("beforeend", `<line x1="${A.x + .5}" y1="${yA + .5}" x2="${B.x + .5}" y2="${yB + .5}"/>`); }
    g.append(svg);
    return g;
  }
  function rendreVue(z, v) {
    z.append(h("div", "sp-leg", `sa figure : ${v.fa ? FIG[v.fa] : "aucune"}`), grille(v.a, v.la, "a", true), h("div", "sp-vs", `manche ${v.manche}`), grille(v.j, v.lj, "j", false), h("div", "sp-leg", `ta figure : ${v.fj ? FIG[v.fj] : "aucune"}`));
  }
  function rendrePrep(z, prep, et, maj) {
    const eA = Object.entries(et.pos).map(([id, [x, y]]) => ({ uid: "a" + id, id, camp: "a", x, y, pv: 1, max: 1, stade: et.boss && id === "doudou" ? 3 : 1 }));
    const fA = figure(et.liens, et.pos);
    z.append(h("div", "sp-leg", `Sa figure : ${fA ? FIG[fA.f] : "aucune"}`), grille(eA, et.liens, "a", true));
    const ids = Object.keys(prep.pos);
    const eJ = ids.map(id => ({ uid: "j" + id, id, camp: "j", x: prep.pos[id][0], y: prep.pos[id][1], pv: 1, max: 1 }));
    const fJ = figure(prep.liens, prep.pos);
    const outils = h("div", "rangee");
    for (const [m, t] of [["placer", "Placer"], ["lier", `Lier (${prep.liens.length}/${MAXL})`]]) { const b = h("button", "btn " + (prep._mode === m ? "mauve" : "sec"), t); b.onclick = () => { prep._mode = m; prep._sel = null; maj(); }; outils.append(b); }
    z.append(h("div", "sp-vs", "contre"), grille(eJ, prep.liens, "j", false, {
      sel: prep._sel,
      onCell: (x, y) => { if (prep._mode === "placer" && prep._sel) { prep.pos[prep._sel] = [x, y]; prep._sel = null; maj(); } },
      onPion: u => {
        if (prep._mode === "lier") {
          if (!prep._sel) { prep._sel = u.id; return maj(); }
          if (prep._sel !== u.id) { const i = prep.liens.findIndex(l => l.includes(prep._sel) && l.includes(u.id)); if (i >= 0) prep.liens.splice(i, 1); else if (prep.liens.length < MAXL) prep.liens.push([prep._sel, u.id]); }
          prep._sel = null; return maj();
        }
        prep._sel = prep._sel === u.id ? null : u.id; maj();
      },
    }), h("div", "sp-leg fg-fig", `Ta figure : ${fJ ? FIG[fJ.f] : "aucune (lie au moins 3 étoiles)"}`), outils);
    z.append(h("div", "sp-leg", prep._mode === "lier" ? "Touche deux de tes étoiles pour les lier (ou délier)." : prep._sel ? `Touche une case pour y mettre ${nomDe(prep._sel)}` : "Touche une étoile pour la déplacer, ou un héros ci-dessous."));
    const box = h("div", "sp-bloc"); box.append(h("div", "sp-tit", `Tes étoiles · ${ids.length}/4`));
    const g = h("div", "sp-reserve");
    for (const id of et.reserve) {
      const b = h("button", "sp-hero" + (prep.pos[id] ? " pris" : "")); b.append(vignette(id, { stade: 1, nom: false }), h("b", "", nomDe(id)), h("span", "", LIEN[id] || ""));
      b.onclick = () => {
        if (prep.pos[id]) { delete prep.pos[id]; prep.liens = prep.liens.filter(l => !l.includes(id)); }
        else if (ids.length < 4) { const libre = []; for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (!Object.values(prep.pos).some(p => p[0] === x && p[1] === y)) libre.push([x, y]); prep.pos[id] = libre[0]; }
        maj();
      };
      g.append(b);
    }
    box.append(g); z.append(box);
  }
  enregistrer({ groupe: "strategie", id: "s-figure", num: "3", nom: "La Figure céleste", accroche: "Place tes étoiles, trace les liens : la forme dessinée fait la force.", duree: "35 s", images: ["bahamut-1", "thor-1", "golem-1"], fond: "linear-gradient(160deg,#1f2a4a,#141024)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => { const ids = tirerN(R, et.reserve, 4), cells = tirerN(R, [...Array(W * H).keys()], 4), pos = {}; ids.forEach((id, i) => pos[id] = [cells[i] % W, Math.floor(cells[i] / W)]); const paires = []; for (let i = 0; i < 4; i++) for (let k = i + 1; k < 4; k++) paires.push([ids[i], ids[k]]); return { pos, liens: tirerN(R, paires, Math.floor(R() * 5)) }; }, initPrep: et => { const r = et.reserve; return { pos: { [r[0]]: [1, 0], [r[1]]: [2, 0], [r[2]]: [1, 1], [r[3]]: [2, 1] }, liens: [[r[0], r[2]], [r[2], r[3]]], _mode: "placer", _sel: null }; },
      pret: p => Object.keys(p.pos).length === 4 ? true : "place 4 étoiles", simuler, rendreVue, rendrePrep,
      tuto: ["Place 4 étoiles. La rangée du haut est devant.", "Trace des liens : la forme donne ta figure.", "Chaque lien active l'effet de ses deux héros."] }) });
})();
