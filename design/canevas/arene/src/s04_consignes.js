// ═════════════════════════════ S4 · LES CONSIGNES ═════════════════════════════
// Chaque héros suit 3 consignes « Si… alors… », lues de haut en bas : la première vraie s'applique.
// On voit les consignes de l'adversaire (son « cerveau »). Les coups au corps à corps ne touchent
// que ceux de devant ; les pouvoirs touchent n'importe qui.
(function () {
  const CONDS = [["toujours", "Toujours"], ["allie40", "Si un allié est sous 40 %"], ["moi50", "Si je suis sous 50 %"], ["mouille", "Si un ennemi est Mouillé"], ["gele", "Si un ennemi est Gelé"], ["achever", "Si un ennemi peut tomber d'un coup"], ["charge", "Si l'ennemi prépare un gros coup"]];
  const ACTS = [["faible", "frapper le plus faible"], ["devant", "frapper celui de devant"], ["pouvoir", "utiliser mon pouvoir"], ["defendre", "me défendre"], ["proteger", "protéger le plus blessé"]];
  const tC = k => CONDS.find(x => x[0] === k)[1], tA = k => ACTS.find(x => x[0] === k)[1];
  const defaut = id => {
    const r = KITS[id].role;
    if (["Soutien", "Nécromancien", "Chef"].includes(r)) return [["allie40", "pouvoir"], ["toujours", "faible"], ["toujours", "defendre"]];
    if (["Tank", "Gardien", "Protecteur"].includes(r)) return [["charge", "defendre"], ["toujours", "pouvoir"], ["toujours", "devant"]];
    return [["achever", "faible"], ["toujours", "pouvoir"], ["toujours", "faible"]];
  };
  const ETAPES = [
    { nom: "Les chasseurs", desc: "Fenrir devant ; Thor et Bahamut derrière. Bahamut Mouille, Thor frappe double les Mouillés.", eq: [["fenrir", "avant", [["achever", "faible"], ["toujours", "faible"]]], ["thor", "arriere", [["mouille", "pouvoir"], ["toujours", "faible"]]], ["bahamut", "arriere", [["toujours", "pouvoir"], ["toujours", "faible"]]]], reserve: ["golem", "kitsune", "yeti", "babayaga", "minotaure"] },
    { nom: "Le mur", desc: "Golem et Cerbère devant, la Banshee derrière qui affaiblit tout le monde.", eq: [["golem", "avant", [["toujours", "pouvoir"], ["toujours", "devant"]]], ["cerbere", "avant", [["moi50", "pouvoir"], ["toujours", "faible"]]], ["banshee", "arriere", [["toujours", "pouvoir"], ["toujours", "faible"]]]], reserve: ["thor", "bahamut", "kitsune", "anubis", "wukong", "fenrir"] },
    { nom: "Boss : le Minotaure", desc: "Toutes les 3 manches, il annonce puis lance une Charge (26) sur celui de devant. Il souffle (14) sur un héros seul derrière.", boss: true, eq: [["minotaure", "avant", [["charge", "faible"], ["toujours", "faible"]]]], reserve: ["golem", "bahamut", "kitsune", "yeti", "fenrir", "anubis", "doudou"] },
  ];
  function simuler(prep, et) {
    const J = Journal();
    const mk = (id, camp, pos, cons, boss) => { const u = creer(id, camp); u.max = boss ? 240 : Math.round(u.max * 1.6); u.pv = u.max; if (boss) u.att = 10; Object.assign(u, { pos, cons, vit: vitDe(id), boss }); return u; };
    const EJ = prep.eq.map(id => mk(id, "j", prep.pos[id], prep.cons[id]));
    const EA = et.eq.map(([id, pos, cons]) => mk(id, "a", pos, cons, et.boss));
    const eqs = { j: EJ, a: EA }, tous = [...EJ, ...EA];
    let fx = [], manche = 0;
    const M = { log() {}, fx(c, t, k) { fx.push([c.uid, t, k]); }, tous: () => tous, adversaires: c => eqs[autre(c.camp)], allies: c => eqs[c.camp], recharge: 3,
      hook(t, a, b, n) { if (t === "degats") { if (a) J.fait(a, "inflige", n); if (b) J.fait(b, "recu", n); } if (t === "ko") J.tomber(b); } };
    const vue = () => ({ j: EJ.map(u => ({ ...copieU(u), pos: u.pos })), a: EA.map(u => ({ ...copieU(u), pos: u.pos })), manche });
    const devant = eq => { const v = vivants(eq), d = v.filter(u => u.pos === "avant"); return ciblesValides(d.length ? d : v); };
    function vrai(u, c) {
      const adv = vivants(eqs[autre(u.camp)]), all = vivants(eqs[u.camp]);
      if (c === "toujours") return true;
      if (c === "allie40") return all.some(x => x !== u && x.pv < x.max * 0.4);
      if (c === "moi50") return u.pv < u.max * 0.5;
      if (c === "mouille") return adv.some(x => x.st.mouille);
      if (c === "gele") return adv.some(x => x.st.gele);
      if (c === "achever") return devant(eqs[autre(u.camp)]).some(x => x.pv <= attaqueDe(u));
      if (c === "charge") return adv.some(x => x.chargeAnnoncee);
      return false;
    }
    function faire(u, a) {
      const adv = eqs[autre(u.camp)];
      if (a === "pouvoir") {
        if (u.recharge) return false;
        const k = KITS[u.id];
        const cible = k.cible === "ennemi" ? ciblesValides(adv).sort((x, y) => x.pv - y.pv)[0] : k.cible === "allie" ? vivants(eqs[u.camp]).filter(x => x !== u).sort((x, y) => x.pv / x.max - y.pv / y.max)[0] : null;
        if (k.cible === "ennemi" && !cible) return false;
        pouvoir(M, u, cible); return KITS[u.id].pouvoir;
      }
      if (a === "faible") { const c = devant(adv).sort((x, y) => x.pv - y.pv)[0]; if (!c) return false; frapper(M, u, c, 1); return `frappe ${nomDe(c.id)}`; }
      if (a === "devant") { const c = devant(adv)[0]; if (!c) return false; frapper(M, u, c, 1); return `frappe ${nomDe(c.id)}`; }
      if (a === "defendre") { u.defend = true; fx.push([u.uid, "en garde", "mot"]); return "se défend"; }
      if (a === "proteger") { const x = vivants(eqs[u.camp]).filter(y => y !== u).sort((p, q) => p.pv / p.max - q.pv / q.max)[0]; if (!x) return false; x.st.protege = { par: u.uid, n: 2 }; fx.push([x.uid, "protégé", "mot"]); return `protège ${nomDe(x.id)}`; }
      return false;
    }
    J.pas_(vue(), "Chacun suit ses consignes", [], 900);
    while (manche < 30 && vivants(EJ).length && vivants(EA).length) {
      manche++;
      debutTour(M, "j"); debutTour(M, "a");
      for (const u of tous.filter(x => !x.ko).sort((a, b) => b.vit - a.vit || (a.camp === b.camp ? 0 : a.camp === "j" ? -1 : 1) || a.uid - b.uid)) {
        if (u.ko || !vivants(EJ).length || !vivants(EA).length) continue;
        fx = [];
        if (u.st.gele) { delete u.st.gele; J.fait(u, "gele"); fx.push([u.uid, "gelé", "mot"]); J.pas_(vue(), `${nomDe(u.id)} est gelé`, fx, 450); continue; }
        if (u.boss) {
          let m;
          if (u.chargeAnnoncee) { u.chargeAnnoncee = false; const c = devant(EJ)[0]; frapper(M, u, c, 2.6); m = `CHARGE sur ${nomDe(c.id)} !`; }
          else if (manche % 3 === 2) { u.chargeAnnoncee = true; fx.push([u.uid, "prépare sa charge", "mot"]); m = "Le Minotaure gratte le sol : charge au prochain tour"; }
          else { const seuls = vivants(EJ).filter(x => x.pos === "arriere"); if (seuls.length === 1 && vivants(EJ).length > 1) { blesser(M, seuls[0], 14, u); m = `Souffle sur ${nomDe(seuls[0].id)}, seul derrière`; } else { const c = devant(EJ).sort((x, y) => x.pv - y.pv)[0]; frapper(M, u, c, 1); m = `frappe ${nomDe(c.id)}`; } }
          J.pas_(vue(), `Minotaure : ${m}`, fx, 750); continue;
        }
        let fait = null, ligne = null;
        for (const [c, a] of u.cons) { if (vrai(u, c)) { const r = faire(u, a); if (r) { fait = r; ligne = `« ${tC(c)} → ${tA(a)} »`; break; } } }
        if (!fait) { const c = devant(eqs[autre(u.camp)])[0]; if (c) frapper(M, u, c, 1); fait = "frappe (aucune consigne)"; ligne = ""; }
        J.fait(u, "actions");
        J.pas_(vue(), `${nomDe(u.id)} ${ligne} : ${fait}`, fx, 600);
      }
    }
    const g = !vivants(EA).length;
    const plus = [];
    if (et.boss && !g) plus.push(`Il restait ${Math.max(0, EA[0].pv)} PV au Minotaure.`);
    if (!g && vivants(EJ).length) plus.push("Temps écoulé : personne n'est tombé à temps.");
    return { pas: J.pas, gagne: g, recit: J.recit(plus) };
  }
  function rendreVue(z, v) {
    const rang = (eq, camp) => {
      const w = h("div", "cs4-eq");
      for (const pos of camp === "a" ? ["arriere", "avant"] : ["avant", "arriere"]) {
        const r = h("div", "sp-rang"); r.append(h("span", "sp-leg cs4-lib", pos === "avant" ? "devant" : "derrière"));
        for (const u of eq.filter(x => x.pos === pos)) r.append(elCreature(u, { petit: true }));
        w.append(r);
      }
      return w;
    };
    z.append(rang(v.a, "a"), h("div", "sp-vs", `manche ${v.manche}`), rang(v.j, "j"));
  }
  function rendrePrep(z, prep, et, maj) {
    const box = h("div", "sp-bloc"); box.append(h("div", "sp-tit", "Son cerveau (ses consignes)"));
    for (const [id, pos, cons] of et.eq) { const l = h("div", "sp-ligne"); l.append(vignette(id, { stade: 1, nom: false }), h("b", "", `${nomDe(id)} · ${pos === "avant" ? "devant" : "derrière"}`)); const ul = h("div", "cs4-cons"); for (const [c, a] of cons) ul.append(h("div", "", `${tC(c)} → ${tA(a)}`)); l.append(ul); box.append(l); }
    z.append(box);
    choixHeros(z, et.reserve, prep.eq, 3, () => { for (const id of prep.eq) { if (!prep.cons[id]) prep.cons[id] = defaut(id); if (!prep.pos[id]) prep.pos[id] = ["Tank", "Gardien", "Protecteur", "Frappeur", "Charge", "Bête", "Virtuose"].includes(KITS[id].role) ? "avant" : "arriere"; } maj(); });
    for (const id of prep.eq) {
      const b = h("div", "sp-bloc"); const t = h("div", "sp-tit"); t.append(vignette(id, { stade: 1, nom: false }), `${nomDe(id)}`, selecteur([["avant", "devant"], ["arriere", "derrière"]], prep.pos[id], v => { prep.pos[id] = v; }), h("small", "", `${KITS[id].pouvoir} : ${KITS[id].txt}`));
      t.querySelector(".carte").style.width = "28px"; b.append(t);
      prep.cons[id].forEach((ln, i) => { const l = h("div", "sp-ligne"); l.append(h("em", "rl-n", i + 1), selecteur(CONDS, ln[0], v => { ln[0] = v; }), h("span", "sp-leg", "→"), selecteur(ACTS, ln[1], v => { ln[1] = v; })); b.append(l); });
      z.append(b);
    }
  }
  enregistrer({ groupe: "strategie", id: "s-consignes", num: "4", nom: "Les Consignes", accroche: "Écris 3 règles « Si… alors… » par héros. Lis les siennes.", duree: "50 s", images: ["bahamut-1", "golem-1", "thor-1"], fond: "linear-gradient(160deg,#1c2640,#131022)",
    lancer: proto({ etapes: ETAPES, aleatoire: (et, R) => { const eq = tirerN(R, et.reserve, 3), cons = {}, pos = {}; for (const id of eq) { pos[id] = tirer(R, ["avant", "arriere"]); cons[id] = [0, 1, 2].map(() => [tirer(R, CONDS)[0], tirer(R, ACTS)[0]]); } if (!eq.some(id => pos[id] === "avant")) pos[eq[0]] = "avant"; return { eq, cons, pos }; }, initPrep: et => { const eq = et.reserve.slice(0, 3), cons = {}, pos = {}; for (const id of eq) { cons[id] = defaut(id); pos[id] = ["Tank", "Gardien", "Protecteur", "Frappeur", "Charge", "Bête", "Virtuose"].includes(KITS[id].role) ? "avant" : "arriere"; } return { eq, cons, pos }; },
      pret: p => p.eq.length === 3 ? true : "choisis 3 héros", simuler, rendreVue, rendrePrep,
      tuto: ["Chaque héros suit 3 consignes, de haut en bas.", "Tu lis aussi les siennes : programme contre lui.", "Le combat t'affiche la consigne qui s'applique."] }) });
})();
