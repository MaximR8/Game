// ═════════════════════════════ S5 · LA PARTITION ═════════════════════════════
// Le combat dure 12 temps. La partition du boss est connue. Tu places la compétence de chaque héros
// sur des temps (nombre d'utilisations limité) ; le reste du temps, il frappe normalement.
// Chaque temps se résout dans l'ordre : défenses, gel, action du boss, coups des héros, soins.
(function () {
  const T = 12;
  const PAST = {
    golem: { nom: "Bouclier", l: 3, n: 2, txt: "l'équipe prend −70 % pendant 3 temps" },
    kitsune: { nom: "Contre", l: 1, n: 3, txt: "si elle est visée : aucun dégât et riposte 20" },
    wukong: { nom: "Rafale", l: 1, n: 3, txt: "3 coups de 7" },
    thor: { nom: "Mjöllnir", l: 3, n: 2, txt: "charge 2 temps, puis 40 (double sur Mouillé)" },
    yeti: { nom: "Gel", l: 1, n: 2, txt: "annule l'action du boss au temps suivant" },
    bahamut: { nom: "Marée", l: 1, n: 2, txt: "soigne 15 à tous, Mouille le boss 3 temps" },
    fenrir: { nom: "Croc", l: 1, n: 3, txt: "16, double si le boss est gelé" },
    anubis: { nom: "Écho", l: 1, n: 1, txt: "ramène le premier héros tombé (50 %)" },
    minotaure: { nom: "Charge", l: 1, n: 2, txt: "30 dégâts, il perd 8 PV" },
    cerbere: { nom: "Trois crocs", l: 1, n: 2, txt: "3 coups de 7" },
    doudou: { nom: "Crin", l: 2, n: 2, txt: "le héros le plus faible ne prend rien pendant 2 temps" },
    quetzalcoatl: { nom: "Vent", l: 2, n: 2, txt: "+5 aux coups de toute l'équipe pendant 2 temps" },
  };
  const ACT = { S: "Souffle : 12 à tous", G: "Griffes : 18 au premier", D: "Faim : 16 au plus faible, il se soigne de 10", B: "Blizzard : 8 à tous, et ils sautent leur prochain temps", C: "Charge : 30 au premier", c: "Coup de corne : 14 au premier" };
  const ETAPES = [
    { nom: "Le Dragon du Lumeçon", boss: "doudou", pv: 330, part: "..S.G.S.G.S.", reserve: ["golem", "kitsune", "thor", "yeti", "bahamut", "fenrir"] },
    { nom: "Le Wendigo affamé", boss: "wendigo", pv: 240, part: ".D.B.D.B.D.B", reserve: ["golem", "bahamut", "yeti", "fenrir", "doudou", "wukong", "anubis"] },
    { nom: "Le Minotaure", boss: "minotaure", pv: 360, part: ".c.C.c.C.c.C", reserve: ["golem", "kitsune", "thor", "minotaure", "cerbere", "quetzalcoatl", "doudou"] },
  ];
  ETAPES.forEach(e => e.desc = `Sa partition est affichée. ${e.pv} PV : il doit tomber avant la fin des 12 temps.`);
  function occupe(pl, id, t) { const p = PAST[id]; return (pl[id] || []).some(s => t >= s && t < s + p.l); }
  function simuler(prep, et) {
    const J = Journal();
    const H = prep.eq.map(id => unite(id, "j", { pv: Math.round(KITS[id].pv * 1.8) }));
    const B = unite(et.boss === "wendigo" ? "fenrir" : et.boss, "a", { pv: et.pv, att: 10 }); B.id = et.boss; B.stade = 3;
    const tous = [...H, B];
    let t = 0, gelB = -1, mouille = 0, ventJusqua = -1;
    const saute = {};
    const vue = () => ({ h: H.map(copieU), b: copieU(B), t, plan: prep.plan, eq: prep.eq, part: et.part });
    J.pas_(vue(), "La partition commence", [], 800);
    for (t = 0; t < T && !B.ko && H.some(x => !x.ko); t++) {
      const fx = []; const msgs = [];
      const actif = (id, k = 0) => (prep.plan[id] || []).some(s => t - k === s);
      const couvre = id => (prep.plan[id] || []).some(s => t >= s && t < s + PAST[id].l);
      // 1. défenses
      const bouclier = H.some(x => !x.ko && x.id === "golem" && couvre("golem"));
      const contre = H.find(x => !x.ko && x.id === "kitsune" && actif("kitsune"));
      const crin = H.some(x => !x.ko && x.id === "doudou" && couvre("doudou")) ? H.filter(x => !x.ko).sort((a, b) => a.pv - b.pv)[0] : null;
      if (bouclier) msgs.push("Bouclier du Golem");
      // 2. le boss agit (sauf s'il est gelé)
      const a = et.part[t];
      const premier = () => H.find(x => !x.ko);
      const subir = (x, n) => {
        if (!x || x.ko) return;
        if (x === contre) { fx.push([x.uid, "contre !", "mot"]); coup(J, x, B, 20 / Math.max(1, x.att), fx); return; }
        if (x === crin) { fx.push([x.uid, "protégé", "mot"]); return; }
        let d = Math.round(n * (bouclier ? 0.3 : 1)); x.pv -= d; J.fait(B, "inflige", d); J.fait(x, "recu", d); fx.push([x.uid, `−${d}`, "rose"]);
        if (x.pv <= 0) { x.pv = 0; x.ko = true; J.tomber(x); fx.push([x.uid, "K.O.", "mot"]); }
      };
      if (a !== ".") {
        if (gelB === t) { msgs.push(`${ACT[a].split(" :")[0]} annulé : le boss est gelé`); fx.push([B.uid, "gelé", "mot"]); }
        else {
          msgs.push(ACT[a].split(" :")[0]);
          if (a === "S") for (const x of H) subir(x, 12);
          if (a === "G") subir(premier(), 18);
          if (a === "C") subir(premier(), 30);
          if (a === "c") subir(premier(), 14);
          if (a === "D") { const x = H.filter(y => !y.ko).sort((p, q) => p.pv - q.pv)[0]; subir(x, 16); guerir(J, B, 10, fx); }
          if (a === "B") for (const x of H) { subir(x, 8); if (!x.ko && x !== crin) { saute[x.uid] = t + 1; J.fait(x, "gele"); } }
        }
      }
      // 3. les héros
      for (const x of H) {
        if (x.ko || B.ko) continue;
        if (saute[x.uid] === t) { fx.push([x.uid, "gelé", "mot"]); continue; }
        const p = PAST[x.id], bonus = t <= ventJusqua ? 5 : 0;
        const frappe = (n, m) => { if (B.ko) return; const d = Math.round(n + bonus); B.pv -= d; J.fait(x, "inflige", d); J.fait(B, "recu", d); fx.push([B.uid, `−${d}`, m || "or"]); if (B.pv <= 0) { B.pv = 0; B.ko = true; } };
        if (x.id === "thor" && couvre("thor")) { if (actif("thor", 2)) { frappe(mouille >= t ? 80 : 40, "gros"); msgs.push("Mjöllnir !"); } else fx.push([x.uid, "charge…", "mot"]); continue; }
        if (p && actif(x.id) && x.id !== "golem" && x.id !== "doudou" && x.id !== "kitsune") {
          if (x.id === "wukong" || x.id === "cerbere") { frappe(7); frappe(7); frappe(7); }
          if (x.id === "yeti") { gelB = t + 1; fx.push([B.uid, "gel au prochain temps", "mot"]); frappe(4); }
          if (x.id === "fenrir") frappe(gelB === t ? 32 : 16);
          if (x.id === "minotaure") { frappe(30); x.pv -= 8; fx.push([x.uid, "−8", "rose"]); if (x.pv <= 0) { x.pv = 0; x.ko = true; J.tomber(x); } }
          if (x.id === "bahamut") { for (const y of H) guerir(J, y, 15, fx); mouille = t + 3; fx.push([B.uid, "Mouillé", "mot"]); }
          if (x.id === "anubis") { const m = H.find(y => y.ko); if (m) { m.ko = false; m.pv = Math.round(m.max * 0.5); fx.push([m.uid, "revient !", "gros"]); } }
          if (x.id === "quetzalcoatl") { ventJusqua = t + 1; frappe(x.att); }
          msgs.push(p.nom);
        } else frappe(x.att, "rose");
      }
      J.pas_(vue(), `Temps ${t + 1} : ${msgs.join(" · ") || "chacun frappe"}`, fx, 850);
    }
    const g = B.ko;
    const plus = [];
    if (!g) plus.push(B.ko ? "" : `Il restait ${Math.round(B.pv)} PV au boss après 12 temps.`);
    const touche = Object.values(J.faits).filter(f => f.u.camp === "j" && f.recu > 0).sort((a, b) => b.recu - a.recu)[0];
    if (touche) plus.push(`${nomDe(touche.u.id)} a encaissé ${touche.recu} : un Bouclier ou un Gel au bon temps ?`);
    return { pas: J.pas, gagne: g, recit: J.recit(plus.filter(Boolean)) };
  }
  function table(v, o = {}) {
    const g = h("div", "pa-table"); g.style.gridTemplateColumns = `64px repeat(${T},1fr)`;
    g.append(h("span", "pa-lib", ""));
    for (let t = 0; t < T; t++) g.append(h("span", "pa-num" + (v.t === t ? " ici" : ""), t + 1));
    g.append(h("span", "pa-lib a", nomDe(v.bossId)));
    for (let t = 0; t < T; t++) { const a = v.part[t]; const c = h("span", "pa-c boss" + (a !== "." ? " act" : "") + (v.t === t ? " ici" : ""), a === "." ? "" : a); if (a !== ".") c.title = ACT[a]; g.append(c); }
    for (const id of v.eq) {
      const nomc = h("button", "pa-lib" + (o.sel === id ? " sel" : ""), nomDe(id)); if (o.onNom) nomc.onclick = () => o.onNom(id); g.append(nomc);
      for (let t = 0; t < T; t++) {
        const p = PAST[id], debut = (v.plan[id] || []).includes(t), dans = occupe(v.plan, id, t);
        const c = h("button", "pa-c" + (dans ? " pris" : "") + (debut ? " debut" : "") + (v.t === t ? " ici" : ""), debut ? p.nom[0] : dans ? "·" : "");
        if (o.onCell) c.onclick = () => o.onCell(id, t);
        g.append(c);
      }
    }
    return g;
  }
  function rendreVue(z, v) {
    const b = h("div", "sp-rang"); b.append(elCreature(v.b, { petit: true }));
    const hs = h("div", "sp-rang"); for (const x of v.h) hs.append(elCreature(x, { petit: true }));
    z.append(b, table({ ...v, bossId: v.b.id }), hs);
  }
  function rendrePrep(z, prep, et, maj) {
    const leg = h("div", "sp-bloc"); leg.append(h("div", "sp-tit", `${nomDe(et.boss)} · ${et.pv} PV · sa partition`));
    for (const k of new Set(et.part.replace(/\./g, ""))) leg.append(h("div", "sp-leg", `${k} = ${ACT[k]}`));
    z.append(leg);
    choixHeros(z, et.reserve, prep.eq, 3, () => { for (const id of Object.keys(prep.plan)) if (!prep.eq.includes(id)) delete prep.plan[id]; if (!prep.eq.includes(prep._sel)) prep._sel = prep.eq[0]; maj(); });
    if (!prep._sel && prep.eq[0]) prep._sel = prep.eq[0];
    const s = prep._sel && PAST[prep._sel];
    if (s) z.append(h("div", "sp-leg pa-aide", `${nomDe(prep._sel)} · ${s.nom} (${s.l > 1 ? s.l + " temps, " : ""}${s.n} fois) : ${s.txt}. Touche une case de sa ligne. Encore ${s.n - (prep.plan[prep._sel] || []).length} utilisation(s).`));
    z.append(table({ t: -1, part: et.part, bossId: et.boss, eq: prep.eq, plan: prep.plan }, {
      sel: prep._sel, onNom: id => { prep._sel = id; maj(); },
      onCell: (id, t) => {
        prep._sel = id; const p = PAST[id], l = prep.plan[id] = prep.plan[id] || [];
        const i = l.findIndex(s0 => t >= s0 && t < s0 + p.l);
        if (i >= 0) l.splice(i, 1);
        else if (l.length < p.n && t + p.l <= T && ![...Array(p.l).keys()].some(k => occupe(prep.plan, id, t + k))) l.push(t);
        maj();
      },
    }));
  }
  enregistrer({ groupe: "strategie", id: "s-partition", num: "5", nom: "La Partition", accroche: "12 temps. Place tes compétences face à la partition du boss.", duree: "30 s", images: ["doudou-3", "golem-1", "yeti-1"], fond: "linear-gradient(160deg,#3a1c14,#141022)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => { const eq = tirerN(R, et.reserve, 3), plan = {}; for (const id of eq) { const p = PAST[id]; plan[id] = []; for (let e = 0; e < 20 && plan[id].length < p.n; e++) { const t = Math.floor(R() * (T - p.l + 1)); if (![...Array(p.l).keys()].some(k => occupe(plan, id, t + k))) plan[id].push(t); } } return { eq, plan }; }, initPrep: et => ({ eq: et.reserve.slice(0, 3), plan: {}, _sel: et.reserve[0] }), pret: p => p.eq.length === 3 ? true : "choisis 3 héros", simuler, rendreVue, rendrePrep,
      tuto: ["Le combat dure 12 temps. La partition du boss est en haut.", "Place les compétences de tes héros sur les bons temps.", "Le reste du temps, ils frappent tout seuls."] }) });
})();
