// ═════════════════════════════ S1 · LE RELAIS DES LÉGENDES ═════════════════════════════
// Un seul héros de chaque camp en scène. Tu prépares l'ordre d'entrée et QUAND chacun cède sa place.
// Chaque héros a un effet d'entrée, une tenue (tant qu'il est en scène) et un effet de sortie.
(function () {
  const COND = [["fin", "Reste jusqu'au bout"], ["pv30", "Sort sous 30 % PV"], ["coups3", "Sort après 3 coups"], ["desav", "Sort s'il est désavantagé"]];
  const ID = {
    thor: { e: "frappe dès l'entrée", t: "double sur un Mouillé" },
    minotaure: { e: "charge ×2 dès l'entrée" },
    bahamut: { e: "Mouille l'adversaire", s: "soigne 12 toute la coulisse" },
    kitsune: { e: "esquive le 1er coup reçu" },
    yeti: { e: "gèle l'adversaire : il saute son coup" },
    banshee: { e: "adversaire −30 % de dégâts (3 manches)" },
    golem: { t: "+3 armure en réserve par coup reçu", s: "donne sa réserve d'armure au suivant" },
    fenrir: { t: "+3 ATT à chaque coup donné" },
    wukong: { t: "frappe 2 fois (×0,6)" },
    doudou: { t: "−30 % de dégâts reçus", s: "le suivant ignore 1 coup" },
    cerbere: { t: "riposte 40 % à chaque coup reçu" },
    anubis: { s: "le suivant regagne 30 % PV" },
    babayaga: { s: "maudit l'adversaire (4 par manche)" },
    quetzalcoatl: { s: "le suivant +4 ATT" },
  };
  const txtId = id => { const x = ID[id] || {}; return [x.e && "Entrée : " + x.e, x.t && "Tenue : " + x.t, x.s && "Sortie : " + x.s].filter(Boolean).join(" · ") || "Aucun effet spécial"; };
  const ETAPES = [
    { nom: "Les gardiens du Nord", desc: "Il entre dans cet ordre : Cerbère, Thor, Bahamut (sort sous 30 %), Fenrir.", eq: [["cerbere", "fin"], ["thor", "fin"], ["bahamut", "pv30"], ["fenrir", "fin"]], reserve: ["golem", "kitsune", "yeti", "bahamut", "minotaure", "anubis"] },
    { nom: "Le cercle des sorcières", desc: "Banshee (sort si désavantagée), Baba Yaga (sous 30 %), Kitsune, Minotaure.", eq: [["banshee", "desav"], ["babayaga", "pv30"], ["kitsune", "fin"], ["minotaure", "fin"]], reserve: ["thor", "golem", "doudou", "wukong", "quetzalcoatl", "fenrir"] },
    { nom: "Boss : le Minotaure en furie", desc: "Il ne sort jamais. 220 PV. Sous 50 %, il entre en furie : +60 % d'ATT.", eq: [["minotaure", "fin"]], boss: true, reserve: ["golem", "kitsune", "bahamut", "anubis", "yeti", "thor", "doudou", "cerbere"] },
  ];
  function simuler(prep, et) {
    const J = Journal();
    const eqJ = prep.ordre.map(([id, c]) => Object.assign(unite(id, "j", { pv: Math.round(KITS[id].pv * 1.3) }), { cond: c }));
    const eqA = et.eq.map(([id, c]) => Object.assign(unite(id, "a", et.boss ? { pv: 220, att: 11 } : { pv: Math.round(KITS[id].pv * 1.3) }), { cond: c, boss: !!et.boss }));
    const eq = { j: eqJ, a: eqA }, scene = { j: null, a: null }, repos = {};
    let manche = 0;
    const vue = () => ({ eq: { j: eqJ.map(copieU), a: eqA.map(copieU) }, scene: { j: scene.j && scene.j.uid, a: scene.a && scene.a.uid }, manche });
    const snap = (msg, fx = [], duree) => J.pas_(vue(), msg, fx, duree);
    function entrer(camp, sauf, fx, bonus) {
      const cand = eq[camp].filter(u => !u.ko && u !== sauf && !(repos[u.uid] > manche));
      const u = cand[0] || (sauf && !sauf.ko ? sauf : null);
      scene[camp] = u; if (!u) return;
      u.coups = 0; u.esquive = u.id === "kitsune";
      if (bonus) bonus(u);
      const adv = scene[autre(camp)], x = ID[u.id] || {};
      let m = `${nomDe(u.id)} entre en scène`;
      if (x.e && adv && !adv.ko) {
        if (u.id === "thor") coup(J, u, adv, adv.st.mouille ? 2 : 1, fx);
        if (u.id === "minotaure") coup(J, u, adv, 2, fx);
        if (u.id === "bahamut") adv.st.mouille = 1;
        if (u.id === "yeti") { adv.st.gele = 1; J.fait(adv, "gele"); }
        if (u.id === "banshee") adv.st.affaibli = 3;
        m += ` — ${x.e}`;
      }
      fx.push([u.uid, "entre", "mot"]); return m;
    }
    function sortir(u, fx) {
      const camp = u.camp, x = ID[u.id] || {}; repos[u.uid] = manche + 2;
      let bonus = null, m = `${nomDe(u.id)} cède sa place`;
      if (x.s) {
        m += ` — ${x.s}`;
        if (u.id === "bahamut") for (const v of eq[camp]) if (v !== u && !v.ko) guerir(J, v, 12, fx);
        if (u.id === "babayaga" && scene[autre(camp)]) scene[autre(camp)].st.maudit = 4;
        const res = u.reserve || 0;
        bonus = v => {
          if (u.id === "golem") v.armure += res;
          if (u.id === "anubis") guerir(J, v, Math.round(v.max * 0.3), fx);
          if (u.id === "quetzalcoatl") v.att += 4;
          if (u.id === "doudou") v.bouclier = true;
        };
        u.reserve = 0;
      }
      const m2 = entrer(camp, u, fx, bonus);
      return m + (m2 ? ". " + m2 : "");
    }
    let fx0 = [];
    entrer("j", null, fx0); entrer("a", null, fx0);
    snap("Les deux premiers entrent", fx0, 900);
    while (manche < 60 && eqJ.some(u => !u.ko) && eqA.some(u => !u.ko)) {
      manche++;
      const ordre = [scene.j, scene.a].filter(Boolean).sort((a, b) => b.vit - a.vit || (a.camp === "j" ? -1 : 1));
      for (const u of ordre) {
        const cible = scene[autre(u.camp)];
        if (u.ko || !cible || cible.ko || scene[u.camp] !== u) continue;
        const fx = [];
        if (u.st.gele) { delete u.st.gele; fx.push([u.uid, "gelé", "mot"]); snap(`${nomDe(u.id)} est gelé : il ne frappe pas`, fx); continue; }
        if (u.boss && u.pv < u.max / 2 && !u.furie) { u.furie = true; u.att = Math.round(u.att * 1.6); fx.push([u.uid, "FURIE", "gros"]); }
        const frappes = u.id === "wukong" ? [0.6, 0.6] : [1];
        for (const k of frappes) {
          if (cible.ko) break;
          if (cible.esquive) { cible.esquive = false; fx.push([cible.uid, "esquive", "mot"]); continue; }
          if (cible.bouclier) { cible.bouclier = false; fx.push([cible.uid, "protégé", "mot"]); continue; }
          let kk = k * (u.id === "thor" && cible.st.mouille ? 2 : 1) * (cible.id === "doudou" ? 0.7 : 1);
          const d = coup(J, u, cible, kk, fx);
          if (cible.id === "golem") cible.reserve = (cible.reserve || 0) + 3;
          if (cible.id === "cerbere" && !cible.ko) coup(J, cible, u, 0.4, fx);
          if (u.id === "fenrir") u.att += 3;
        }
        u.coups++; J.fait(u, "actions");
        snap(`${nomDe(u.id)} frappe ${nomDe(cible.id)}`, fx);
        if (cible.ko) { const f2 = []; const m = entrer(cible.camp, cible, f2); snap(`${nomDe(cible.id)} tombe. ${m || ""}`, f2, 800); }
      }
      // fin de manche : malédictions, effets qui s'usent, relèves
      const fx = []; let msg = "";
      for (const c of ["j", "a"]) {
        const u = scene[c]; if (!u || u.ko) continue;
        if (u.st.maudit) { u.pv -= 4; fx.push([u.uid, "−4", "rose"]); J.fait(u, "recu", 4); if (u.pv <= 0) { u.ko = true; u.pv = 0; J.tomber(u); } }
        if (u.st.affaibli && --u.st.affaibli <= 0) delete u.st.affaibli;
      }
      for (const c of ["j", "a"]) {
        const u = scene[c]; if (!u) continue;
        if (u.ko) { msg += (entrer(c, u, fx) || "") + ". "; continue; }
        const adv = scene[autre(c)];
        const sort = u.cond === "pv30" ? u.pv < u.max * 0.3 : u.cond === "coups3" ? u.coups >= 3 : u.cond === "desav" ? adv && !adv.ko && bat(typeDe(adv.id), typeDe(u.id)) : false;
        if (sort && eq[c].some(v => v !== u && !v.ko && !(repos[v.uid] > manche))) msg += sortir(u, fx) + ". ";
      }
      if (msg) snap(msg, fx, 1000);
    }
    const g = eqA.every(u => u.ko);
    const plus = [];
    if (et.boss && !g) plus.push(`Il restait ${Math.max(0, Math.round(eqA[0].pv))} PV au Minotaure.`);
    const desav = eqJ.find(u => J.faits[u.uid] && J.faits[u.uid].tombe != null && eqA.some(a => bat(typeDe(a.id), typeDe(u.id))));
    if (!g && desav) plus.push(`${nomDe(desav.id)} a combattu en désavantage de type : essaie « Sort s'il est désavantagé ».`);
    return { pas: J.pas, gagne: g, recit: J.recit(plus) };
  }
  function rendreVue(z, v) {
    const bloc = camp => {
      const w = h("div", "rl-camp " + camp), q = h("div", "rl-file");
      for (const u of v.eq[camp]) { const e = vignette(u.id, { stade: 1, nom: false }); e.classList.add("rl-mini"); if (u.ko) e.classList.add("eteinte"); if (u.uid === v.scene[camp]) e.classList.add("ici"); q.append(e); }
      const s = v.eq[camp].find(u => u.uid === v.scene[camp]);
      const scene = h("div", "rl-scene"); if (s) scene.append(elCreature(s));
      w.append(camp === "a" ? q : scene, camp === "a" ? scene : q); return w;
    };
    z.append(bloc("a"), h("div", "sp-vs", `manche ${v.manche}`), bloc("j"));
  }
  function rendrePrep(z, prep, et, maj) {
    const box = h("div", "sp-bloc"); box.append(h("div", "sp-tit", "Son ordre d'entrée"));
    for (const [id, c] of et.eq) { const l = h("div", "sp-ligne"); l.append(vignette(id, { stade: 1, nom: false }), h("b", "", nomDe(id)), h("span", "sp-leg", `${COND.find(x => x[0] === c)[1]} · ${txtId(id)}`)); box.append(l); }
    z.append(box);
    const ids = prep.ordre.map(x => x[0]);
    choixHeros(z, et.reserve, ids, 4, () => { prep.ordre = ids.map(id => prep.ordre.find(x => x[0] === id) || [id, "fin"]); maj(); }, "Ton ordre d'entrée (touche dans l'ordre)");
    const b2 = h("div", "sp-bloc"); b2.append(h("div", "sp-tit", "Quand chacun cède sa place"));
    prep.ordre.forEach((x, i) => {
      const l = h("div", "sp-ligne"); l.append(h("em", "rl-n", i + 1), vignette(x[0], { stade: 1, nom: false }), h("b", "", nomDe(x[0])), selecteur(COND, x[1], v => { x[1] = v; }));
      l.append(h("span", "sp-leg", txtId(x[0]))); b2.append(l);
    });
    z.append(b2);
  }
  enregistrer({ groupe: "strategie", id: "s-relais", num: "1", nom: "Le Relais des légendes", accroche: "Un duel à la fois. Prépare l'ordre et le moment des relèves.", duree: "40 s", images: ["golem-1", "kitsune-1", "thor-1"], fond: "linear-gradient(160deg,#2a2150,#171229)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => ({ ordre: tirerN(R, et.reserve, 4).map(id => [id, tirer(R, COND)[0]]) }), initPrep: et => ({ ordre: et.reserve.slice(0, 4).map(id => [id, "fin"]) }), pret: p => p.ordre.length === 4 ? true : "choisis 4 héros", simuler, rendreVue, rendrePrep,
      tuto: ["Un seul héros de chaque camp se bat à la fois.", "Choisis l'ordre d'entrée, et quand chacun cède sa place.", "Puis regarde. Perdu ? Change une chose et relance."] }) });
})();
