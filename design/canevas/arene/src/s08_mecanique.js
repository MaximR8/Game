// ═════════════════════════════ S8 · LA MÉCANIQUE CÉLESTE ═════════════════════════════
// Tu construis une machine sur une grille 3×3. Chaque héros « écoute » un voisin (la flèche) :
// quand ce voisin agit, il réagit à son tour. Un seul coup d'envoi par tour, puis la cascade.
// Chaque camp a 120 PV. 5 tours chacun. Le Yéti adverse gèle la case en miroir : ce maillon ne réagira pas.
(function () {
  const DIRS = [[0, -1], [1, 0], [0, 1], [-1, 0]], FL = ["↑", "→", "↓", "←"], PV0 = 120, TOURS = 5;
  const REAC = {
    golem: "frappe 6", thor: "frappe 10", wukong: "3 coups de 3", kitsune: "frappe 6, double à partir du 4e maillon", fenrir: "5, +2 par maillon avant lui",
    bahamut: "soigne ton camp de 8", yeti: "frappe 4 et gèle le maillon adverse en miroir", anubis: "frappe 4 et relance le coup d'envoi (une fois)", minotaure: "frappe 14, ton camp perd 3",
    quetzalcoatl: "+3 à toutes les frappes suivantes", cerbere: "3 coups de 4", banshee: "frappe 4 ; sa prochaine cascade −30 %", babayaga: "frappe 3 et maudit (il perd 4 à chaque tour, sans cumul)", doudou: "absorbe 10 dégâts de sa prochaine cascade",
  };
  const ETAPES = [
    { nom: "La petite machine", pv: 90, desc: "Golem lance ; Thor l'écoute ; Wukong écoute Thor.", m: { golem: [1, 1, 0], thor: [1, 0, 2], wukong: [0, 0, 1] }, envoi: "golem", reserve: ["golem", "thor", "fenrir", "kitsune", "quetzalcoatl", "bahamut", "cerbere"] },
    { nom: "Les briseurs de chaîne", pv: 110, desc: "Son Yéti lance et gèle ta case du centre. La Banshee affaiblit ta prochaine cascade.", m: { yeti: [1, 1, 0], banshee: [1, 0, 2], fenrir: [2, 1, 3], babayaga: [2, 2, 0] }, envoi: "yeti", reserve: ["golem", "thor", "wukong", "kitsune", "fenrir", "anubis", "minotaure"] },
    { nom: "Boss : l'horloge du Minotaure", desc: "Une machine de 6 maillons, 150 PV. Les cases marquées ✕ sur ta grille sont piégées : un héros placé là frappe ton propre camp.", pv: 150, pieges: [[0, 0], [2, 2]], m: { minotaure: [1, 1, 0], cerbere: [1, 0, 2], fenrir: [0, 1, 1], thor: [2, 1, 3], quetzalcoatl: [1, 2, 0], wukong: [0, 2, 1] }, envoi: "quetzalcoatl", reserve: ["golem", "thor", "wukong", "kitsune", "fenrir", "anubis", "bahamut", "yeti", "doudou"] },
  ];
  // Une cascade : renvoie la liste des maillons, et applique les effets
  function cascade(mach, envoi, etat, camp, fxs) {
    const units = Object.entries(mach).map(([id, [x, y, d]]) => ({ id, x, y, d }));
    const at = (x, y) => units.find(u => u.x === x && u.y === y);
    const q = [envoi], vus = new Set(), maillons = [];
    let bonus = 0, relance = false;
    const adv = autre(camp), mult = etat.affaibli[camp] ? 0.7 : 1;
    while (q.length) {
      const id = q.shift(); if (vus.has(id)) continue;
      const u = units.find(v => v.id === id); if (!u) continue;
      if (etat.gel[camp].some(([x, y]) => x === u.x && y === u.y)) { maillons.push({ id, txt: "gelé", n: 0 }); vus.add(id); continue; }
      vus.add(id);
      const k = maillons.filter(m => m.n >= 0).length;
      let n = 0, soin = 0, txt = "";
      const f = v => Math.round((v + bonus) * mult);
      switch (id) {
        case "golem": n = f(6); break; case "thor": n = f(10); break; case "wukong": n = f(3) * 3; break;
        case "kitsune": n = f(k >= 3 ? 12 : 6); break; case "fenrir": n = f(5 + 2 * k); break;
        case "bahamut": soin = 8; break; case "yeti": n = f(4); etat.gelProchain[adv].push([u.x, u.y]); txt = "gèle"; break;
        case "anubis": n = f(4); if (!relance) { relance = true; vus.delete(envoi); q.push(envoi); txt = "relance !"; } break;
        case "minotaure": n = f(14); etat.pv[camp] -= 3; break; case "quetzalcoatl": bonus += 3; txt = "+3"; break;
        case "cerbere": n = f(4) * 3; break; case "banshee": n = f(4); etat.affaibliProchain[adv] = true; break;
        case "babayaga": n = f(3); etat.maudit[adv] = Math.max(etat.maudit[adv], 4); break; case "doudou": etat.bouclier[camp] += 10; txt = "bouclier"; break;
      }
      const piege = etat.pieges && camp === "j" && etat.pieges.some(([x, y]) => x === u.x && y === u.y);
      if (n) {
        if (piege) { etat.pv[camp] -= n; txt = "piège : contre toi !"; }
        else { const b = Math.min(etat.bouclier[adv], n); etat.bouclier[adv] -= b; etat.pv[adv] -= n - b; if (b) txt = `${b} absorbés`; }
      }
      if (soin) etat.pv[camp] = Math.min(etat.max[camp], etat.pv[camp] + soin);
      maillons.push({ id, n, soin, txt, piege });
      for (const v of units.filter(w => { const [dx, dy] = DIRS[w.d]; return w.x + dx === u.x && w.y + dy === u.y; }).sort((a, b) => a.y - b.y || a.x - b.x)) q.push(v.id);
    }
    return maillons;
  }
  function etatNeuf(et) { return { pv: { j: PV0, a: et.pv || PV0 }, max: { j: PV0, a: et.pv || PV0 }, gel: { j: [], a: [] }, gelProchain: { j: [], a: [] }, affaibli: { j: false, a: false }, affaibliProchain: { j: false, a: false }, maudit: { j: 0, a: 0 }, bouclier: { j: 0, a: 0 }, pieges: et.pieges || [] }; }
  function apercu(mach, envoi, et, camp = "j") { const e = etatNeuf(et); if (!envoi || !mach[envoi]) return { l: 0, n: 0 }; const adv = autre(camp), m = cascade(mach, envoi, e, camp); return { l: m.length, n: e.max[adv] - e.pv[adv] }; }
  function simuler(prep, et) {
    const J = Journal(), e = etatNeuf(et);
    const mj = prep.m, ma = et.m;
    let tour = 0, actif = null;
    const vue = (camp, ids) => ({ mj, ma, envoiJ: prep.envoi, envoiA: et.envoi, pv: { ...e.pv }, max: e.max, gel: { j: e.gel.j.slice(), a: e.gel.a.slice() }, actif: camp, allumes: ids || [], tour, pieges: e.pieges });
    J.pas_(vue(), "Deux machines face à face", [], 900);
    for (tour = 1; tour <= TOURS; tour++) {
      for (const camp of ["j", "a"]) {
        const adv = autre(camp);
        if (e.maudit[camp]) { e.pv[camp] -= e.maudit[camp]; J.pas_(vue(camp), `La malédiction : ${camp === "j" ? "ton" : "son"} camp perd ${e.maudit[camp]}`, [], 500); }
        e.affaibli[camp] = e.affaibliProchain[camp]; e.affaibliProchain[camp] = false;
        e.gel[camp] = e.gelProchain[camp]; e.gelProchain[camp] = [];
        const avant = { ...e.pv };
        const ms = cascade(camp === "j" ? mj : ma, camp === "j" ? prep.envoi : et.envoi, e, camp);
        let total = 0; const allumes = [];
        for (const m of ms) {
          allumes.push(m.id); total += m.n || 0;
          const who = camp === "j" ? "Ta" : "Sa";
          J.pas_(vue(camp, allumes.slice()), `${who} cascade : ${nomDe(m.id)} ${m.txt === "gelé" ? "est gelé, la chaîne s'arrête ici" : (m.n ? `+${m.n}` : m.soin ? `soigne ${m.soin}` : "") + (m.txt && m.txt !== "gelé" ? ` (${m.txt})` : "")} · total ${total}`, [], 420);
          if (m.txt === "gelé") J.fait({ uid: camp + m.id, id: m.id, camp }, "gele");
        }
        J.fait({ uid: camp + "machine", id: (camp === "j" ? prep.envoi : et.envoi), camp }, "inflige", Math.max(0, avant[adv] - e.pv[adv]));
        J.pas_(vue(camp), `${camp === "j" ? "Ta" : "Sa"} chaîne : ${ms.filter(m => m.txt !== "gelé").length} maillons, ${avant[adv] - e.pv[adv]} dégâts`, [], 900);
        if (e.pv.j <= 0 || e.pv.a <= 0) break;
      }
      if (e.pv.j <= 0 || e.pv.a <= 0) break;
    }
    const g = e.pv.a <= 0 || (e.pv.j > 0 && e.pv.j > e.pv.a);
    const plus = [`PV des camps : toi ${Math.max(0, e.pv.j)}, lui ${Math.max(0, e.pv.a)}.`];
    if (Object.values(J.faits).some(f => f.u.camp === "j" && f.gele)) plus.push("Un de tes maillons a été gelé : la chaîne s'est coupée. Prévois un chemin de secours.");
    return { pas: J.pas, gagne: g, recit: plus.slice(0, 3) };
  }
  function grille(mach, envoi, camp, o = {}) {
    const g = h("div", "sp-grille me-grille"); g.style.gridTemplateColumns = "repeat(3,1fr)";
    for (let y = 0; y < 3; y++) for (let x = 0; x < 3; x++) {
      const c = h("button", "sp-cell " + camp); c.dataset.cible = `${camp}${x}-${y}`;
      if (o.pieges && o.pieges.some(p => p[0] === x && p[1] === y)) { c.classList.add("me-piege"); c.append(h("span", "me-x", "✕")); }
      if (o.gel && o.gel.some(p => p[0] === x && p[1] === y)) c.classList.add("me-gel");
      const e = Object.entries(mach).find(([, p]) => p[0] === x && p[1] === y);
      if (e) {
        const [id, [, , d]] = e;
        c.append(pion({ uid: camp + id, id, camp, pv: 1, max: 1, stade: 1 }, { tag: FL[d] + (envoi === id ? "★" : "") }));
        if (o.allumes && o.allumes.includes(id)) c.classList.add("me-on");
        if (o.sel === id) c.classList.add("ok");
      }
      if (o.onCell) c.onclick = () => o.onCell(x, y, e && e[0]);
      g.append(c);
    }
    return g;
  }
  const barre = (pv, max, camp) => { const b = h("div", "me-pv " + camp), i = h("i"); i.style.width = Math.max(0, pv / max * 100) + "%"; b.append(i, h("span", "", `${Math.max(0, pv)} / ${max}`)); return b; };
  function rendreVue(z, v) {
    z.append(barre(v.pv.a, v.max.a, "a"), grille(v.ma, v.envoiA, "a", { allumes: v.actif === "a" ? v.allumes : [], gel: v.gel.a }), h("div", "sp-vs", `tour ${v.tour}`), grille(v.mj, v.envoiJ, "j", { allumes: v.actif === "j" ? v.allumes : [], gel: v.gel.j, pieges: v.pieges }), barre(v.pv.j, v.max.j, "j"));
  }
  function rendrePrep(z, prep, et, maj) {
    const aA = apercu(et.m, et.envoi, et, "a"), aJ = apercu(prep.m, prep.envoi, et);
    z.append(h("div", "sp-leg", `Sa machine : ${aA.l} maillons, ${aA.n} dégâts par tour (★ = coup d'envoi)`), grille(et.m, et.envoi, "a"));
    z.append(h("div", "sp-vs", "contre"), grille(prep.m, prep.envoi, "j", { sel: prep._sel, pieges: et.pieges, onCell: (x, y, id) => {
      if (id) { prep._sel = prep._sel === id ? null : id; return maj(); }
      if (prep._sel) { prep.m[prep._sel] = [x, y, prep.m[prep._sel][2]]; maj(); }
    } }));
    z.append(h("div", "sp-leg me-apercu", `Ta machine : ${aJ.l} maillons, ${aJ.n} dégâts par tour (sans gel)`));
    const r = h("div", "rangee");
    const bt = h("button", "btn sec", "Tourner la flèche"); bt.disabled = !prep._sel; bt.onclick = () => { const p = prep.m[prep._sel]; p[2] = (p[2] + 1) % 4; maj(); };
    const be = h("button", "btn mauve", "Coup d'envoi ★"); be.disabled = !prep._sel; be.onclick = () => { prep.envoi = prep._sel; maj(); };
    r.append(bt, be); z.append(r, h("div", "sp-leg", prep._sel ? `${nomDe(prep._sel)} : ${REAC[prep._sel]}. Il réagit quand le voisin montré par sa flèche agit.` : "Touche un de tes héros pour le déplacer, tourner sa flèche ou en faire le coup d'envoi."));
    const box = h("div", "sp-bloc"); box.append(h("div", "sp-tit", `Tes maillons · ${Object.keys(prep.m).length}/5`));
    const g = h("div", "sp-reserve");
    for (const id of et.reserve) {
      const b = h("button", "sp-hero" + (prep.m[id] ? " pris" : "")); b.append(vignette(id, { stade: 1, nom: false }), h("b", "", nomDe(id)), h("span", "", REAC[id]));
      b.onclick = () => {
        if (prep.m[id]) { delete prep.m[id]; if (prep.envoi === id) prep.envoi = Object.keys(prep.m)[0]; if (prep._sel === id) prep._sel = null; }
        else if (Object.keys(prep.m).length < 5) { outer: for (let y = 0; y < 3; y++) for (let x = 0; x < 3; x++) if (!Object.values(prep.m).some(p => p[0] === x && p[1] === y)) { prep.m[id] = [x, y, 0]; break outer; } if (!prep.envoi) prep.envoi = id; }
        maj();
      };
      g.append(b);
    }
    box.append(g); z.append(box);
  }
  enregistrer({ groupe: "strategie", id: "s-mecanique", num: "8", nom: "La Mécanique céleste", accroche: "Construis une machine à réactions en chaîne. Regarde la cascade.", duree: "40 s", images: ["thor-1", "wukong-1", "kitsune-1"], fond: "linear-gradient(160deg,#2b1f4a,#16112a)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => { const ids = tirerN(R, et.reserve, 2 + Math.floor(R() * 4)), cells = tirerN(R, [...Array(9).keys()], ids.length), m = {}; ids.forEach((id, i) => m[id] = [cells[i] % 3, Math.floor(cells[i] / 3), Math.floor(R() * 4)]); return { m, envoi: tirer(R, ids) }; }, initPrep: et => { const r = et.reserve; return { m: { [r[0]]: [1, 1, 0], [r[1]]: [1, 0, 2], [r[2]]: [0, 1, 1] }, envoi: r[0], _sel: null }; },
      pret: p => p.envoi && p.m[p.envoi] ? true : "choisis un coup d'envoi", simuler, rendreVue, rendrePrep,
      tuto: ["Construis une machine : chaque flèche montre qui ce héros écoute.", "Quand le voisin agit, il réagit. Un coup d'envoi, puis la cascade.", "Plus la chaîne est longue, plus ça frappe."] }) });
})();
