// ═════════════════════════════ S10 · LE REPAIRE ═════════════════════════════
// Tu attaques le repaire d'un autre (en PvP, il l'aurait aménagé lui-même). Trois voies montent vers le cœur.
// Tu vois ses gardiens et ses pièges. Pour chaque héros : sa voie et son moment de départ.
// Un héros ne passe pas un gardien vivant ; au bout de sa voie, il frappe le cœur.
(function () {
  const LW = 5, LH = 8, VOIES = [0, 2, 4], NV = ["gauche", "centre", "droite"], MAXT = 40;
  const PIEGE = { gel: "piège de glace : bloqué 2 pas", feu: "piège de feu : 15 dégâts", filet: "filet : bloqué 1 pas" };
  const QUALITE = { kitsune: "passe les pièges sans les déclencher", golem: "déclenche les pièges pour les autres, et n'en souffre qu'à moitié", thor: "frappe le gardien 2 cases avant le contact", bahamut: "soigne le héros juste devant lui (6 par pas)", yeti: "gèle le gardien au premier contact", minotaure: "son premier coup compte triple", fenrir: "frappe 2 fois le gardien", cerbere: "riposte à chaque coup reçu" };
  const ETAPES = [
    { nom: "L'isba de Baba Yaga", desc: "Baba Yaga garde le centre, un Golem à gauche, Cerbère à droite. Trois pièges. Cœur : 120 PV.", coeur: 120, gardes: [["babayaga", 2, 2], ["golem", 0, 3], ["cerbere", 4, 4]], pieges: [[0, 5, "gel"], [2, 5, "feu"], [4, 6, "filet"]], reserve: ["kitsune", "golem", "thor", "bahamut", "minotaure", "fenrir"] },
    { nom: "Le labyrinthe du Minotaure", desc: "Le Minotaure (150 PV) garde la sortie du centre. Fenrir et le Yéti gardent les côtés. Cœur : 110 PV.", coeur: 110, gardes: [["minotaure", 2, 1, 150], ["fenrir", 0, 2], ["yeti", 4, 2]], pieges: [[2, 4, "feu"], [2, 6, "gel"], [0, 5, "feu"], [4, 5, "gel"]], reserve: ["kitsune", "golem", "thor", "bahamut", "yeti", "cerbere", "minotaure"] },
  ];
  const bout = x => x === 2 ? 1 : 0;
  function simuler(prep, et) {
    const J = Journal();
    const H = prep.eq.map(id => Object.assign(unite(id, "j", { pv: Math.round(KITS[id].pv * 1.1) }), { voie: VOIES[prep.voie[id]], depart: prep.depart[id], x: VOIES[prep.voie[id]], y: LH, bloque: 0, premier: true }));
    const G = et.gardes.map(([id, x, y, pv]) => Object.assign(unite(id, "a", { pv: pv || Math.round(KITS[id].pv * 2.4) }), { x, y }));
    const P = et.pieges.map(([x, y, t]) => ({ x, y, t, actif: true }));
    let coeur = et.coeur, t = 0;
    const vue = () => ({ h: H.map(copieU), g: G.map(copieU), p: P.map(p => ({ ...p })), coeur, max: et.coeur, t });
    const garde = (x, y) => G.find(g => !g.ko && g.x === x && g.y === y);
    const heros = (x, y) => H.find(u => !u.ko && u.y === y && u.x === x);
    J.pas_(vue(), "L'expédition attend ton signal", [], 800);
    for (t = 0; t < MAXT && coeur > 0 && H.some(u => !u.ko); t++) {
      const fx = [], msgs = [];
      for (const u of H.filter(v => !v.ko).sort((a, b) => a.y - b.y || a.uid - b.uid)) {
        if (t < u.depart) continue;
        if (u.y === LH) { if (!heros(u.x, LH - 1) && !garde(u.x, LH - 1)) { u.y = LH - 1; msgs.push(`${nomDe(u.id)} entre par la ${NV[VOIES.indexOf(u.x)]}`); } continue; }
        if (u.bloque > 0) { u.bloque--; J.fait(u, "gele"); fx.push([u.uid, "bloqué", "mot"]); continue; }
        if (u.y === bout(u.x)) { coeur -= u.att; J.fait(u, "inflige", u.att); fx.push(["coeur", `−${u.att}`, "or"]); msgs.push(`${nomDe(u.id)} frappe le cœur`); continue; }
        const ny = u.y - 1, g = garde(u.x, ny);
        if (u.id === "thor" && !g) { const g2 = garde(u.x, u.y - 2); if (g2) { coup(J, u, g2, 1, fx); } }
        if (g) {
          let k = 1; if (u.id === "minotaure" && u.premier) { k = 3; u.premier = false; }
          if (u.id === "yeti" && u.premier) { u.premier = false; g.st.gele = true; fx.push([g.uid, "gelé", "mot"]); }
          coup(J, u, g, k, fx); if (u.id === "fenrir" && !g.ko) coup(J, u, g, 1, fx);
          continue;
        }
        const devant = heros(u.x, ny);
        if (devant) { if (u.id === "bahamut") guerir(J, devant, 6, fx); continue; }
        u.y = ny;
        const p = P.find(q => q.actif && q.x === u.x && q.y === u.y);
        if (p && u.id !== "kitsune") {
          p.actif = false; const k = u.id === "golem" ? 0.5 : 1;
          if (p.t === "feu") { const d = Math.round(15 * k); u.pv -= d; J.fait(u, "recu", d); fx.push([u.uid, `−${d} piège`, "rose"]); if (u.pv <= 0) { u.pv = 0; u.ko = true; J.tomber(u); } }
          if (p.t === "gel" && u.id !== "golem") u.bloque = 2;
          if (p.t === "filet" && u.id !== "golem") u.bloque = 1;
          msgs.push(`${nomDe(u.id)} déclenche un ${PIEGE[p.t].split(" :")[0]}`);
        } else if (p && u.id === "kitsune") fx.push([u.uid, "évite le piège", "mot"]);
      }
      // les gardiens frappent le héros en contact (juste en dessous d'eux)
      for (const g of G.filter(v => !v.ko)) {
        if (g.st.gele) { delete g.st.gele; continue; }
        const u = heros(g.x, g.y + 1); if (!u) continue;
        coup(J, g, u, 1, fx);
        if (u.id === "cerbere" && !u.ko) coup(J, u, g, 0.5, fx);
      }
      J.pas_(vue(), `Pas ${t + 1}${msgs.length ? " : " + msgs.join(" · ") : ""}`, fx, 520);
    }
    const g = coeur <= 0;
    const plus = [`Cœur du repaire : ${Math.max(0, coeur)} / ${et.coeur} PV.`];
    const pr = H.filter(u => J.faits[u.uid] && J.faits[u.uid].gele >= 2); if (pr.length) plus.push(`${nomDe(pr[0].id)} a été bloqué ${J.faits[pr[0].uid].gele} pas par les pièges.`);
    return { pas: J.pas, gagne: g, recit: J.recit(plus) };
  }
  function carte(v, o = {}) {
    const g = h("div", "sp-grille rp-carte"); g.style.gridTemplateColumns = `repeat(${LW},1fr)`;
    for (let y = 0; y < LH; y++) for (let x = 0; x < LW; x++) {
      const voie = VOIES.includes(x), c = h("div", "sp-cell " + (voie ? "rp-voie" : "rp-mur"));
      if (x === 2 && y === 0) { c.className = "sp-cell rp-coeur"; c.dataset.uid = "coeur"; c.innerHTML = etoile("", 8, 0.3); const b = h("div", "sp-pv a"), i = h("i"); i.style.width = Math.max(0, v.coeur / v.max * 100) + "%"; b.append(i); c.append(b); }
      const p = v.p.find(q => q.x === x && q.y === y && q.actif); if (p) c.append(h("span", "rp-piege " + p.t, p.t === "gel" ? "❄" : p.t === "feu" ? "▲" : "#"));
      const u = [...v.g, ...v.h].find(w => w.x === x && w.y === y && !w.ko); if (u) c.append(pion(u));
      g.append(c);
    }
    return g;
  }
  function rendreVue(z, v) {
    const attente = v.h.filter(u => u.y === LH && !u.ko);
    z.append(carte(v));
    if (attente.length) { const r = h("div", "sp-rang"); r.append(h("span", "sp-leg", "en attente :")); for (const u of attente) { const e = vignette(u.id, { stade: 1, nom: false }); e.style.width = "30px"; e.dataset.uid = u.uid; r.append(e); } z.append(r); }
  }
  function rendrePrep(z, prep, et, maj) {
    z.append(carte({ h: [], g: et.gardes.map(([id, x, y, pv], i) => ({ uid: "g" + i, id, camp: "a", x, y, pv: 1, max: 1 })), p: et.pieges.map(([x, y, t]) => ({ x, y, t, actif: true })), coeur: et.coeur, max: et.coeur }));
    z.append(h("div", "sp-leg", "❄ glace (bloqué 2 pas) · ▲ feu (15 dégâts) · # filet (bloqué 1 pas). Les gardiens frappent le héros juste en dessous d'eux."));
    choixHeros(z, et.reserve, prep.eq, 4, () => { for (const id of prep.eq) { if (prep.voie[id] == null) prep.voie[id] = 1; if (prep.depart[id] == null) prep.depart[id] = 0; } maj(); }, "Ton expédition");
    const b = h("div", "sp-bloc"); b.append(h("div", "sp-tit", "Voie et départ de chacun"));
    for (const id of prep.eq) { const l = h("div", "sp-ligne"); l.append(vignette(id, { stade: 1, nom: false }), h("b", "", nomDe(id)), selecteur(NV.map((n, i) => [i, "voie " + n]), prep.voie[id], v => { prep.voie[id] = +v; }), selecteur([[0, "part tout de suite"], [2, "part au pas 3"], [4, "part au pas 5"], [6, "part au pas 7"]], prep.depart[id], v => { prep.depart[id] = +v; }), h("span", "sp-leg", QUALITE[id] || "")); b.append(l); }
    z.append(b);
  }
  enregistrer({ groupe: "strategie", id: "s-repaire", num: "10", nom: "Le Repaire", accroche: "Raide son repaire : choisis la voie et le moment de chaque héros.", duree: "50 s", images: ["babayaga-1", "kitsune-1", "golem-1"], fond: "linear-gradient(160deg,#2c2416,#141020)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => { const eq = tirerN(R, et.reserve, 4), voie = {}, depart = {}; for (const id of eq) { voie[id] = Math.floor(R() * 3); depart[id] = tirer(R, [0, 2, 4, 6]); } return { eq, voie, depart }; }, initPrep: et => { const eq = et.reserve.slice(0, 4), voie = {}, depart = {}; eq.forEach((id, i) => { voie[id] = [1, 0, 2, 1][i]; depart[id] = [0, 0, 0, 2][i]; }); return { eq, voie, depart }; },
      pret: p => p.eq.length === 4 ? true : "choisis 4 héros", simuler, rendreVue, rendrePrep,
      tuto: ["Tu raides son repaire. Tu vois ses gardiens et ses pièges.", "Pour chaque héros : sa voie, et quand il part.", "Au bout d'une voie, on frappe le cœur. Détruis-le !"] }) });
})();
