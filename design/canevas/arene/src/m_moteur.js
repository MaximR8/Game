// ═════════════════════════════ Le moteur des créatures (concepts n1 → n8) ═════════════════════════════
// Une créature a un stade (1 → 3), des PV, une ATT, un pouvoir à elle, et des statuts.
// Chaque concept fournit son « match » M : log, fx, hooks, et qui est à portée (adversaires / alliés).
const STADE_PV = [1, 1.35, 1.8], STADE_ATT = [1, 1.3, 1.7];
const KITS = {
  thor: { role: "Frappeur", pv: 38, att: 9, pouvoir: "Mjöllnir", txt: "Frappe ×1,5, et un 2e adversaire ×0,5. Double sur un Mouillé.", cible: "ennemi" },
  golem: { role: "Tank", pv: 60, att: 5, pouvoir: "Rempart vivant", txt: "+5 armure par stade, et les adversaires doivent le viser.", cible: "soi" },
  bahamut: { role: "Soutien", pv: 42, att: 5, pouvoir: "Grande marée", txt: "Soigne les alliés (5 par stade) et Mouille les adversaires.", cible: "aucune" },
  kitsune: { role: "Rusée", pv: 34, att: 8, pouvoir: "Feu de renard", txt: "Marque la cible (prochain coup ×1,5) et esquive le prochain coup.", cible: "ennemi" },
  yeti: { role: "Contrôle", pv: 50, att: 6, pouvoir: "Avalanche", txt: "Petits dégâts et Gèle la cible : elle saute son prochain tour.", cible: "ennemi" },
  anubis: { role: "Nécromancien", pv: 40, att: 6, pouvoir: "Pesée des âmes", txt: "Ranime un allié tombé (40 % PV), une fois. Sinon, draine.", cible: "aucune" },
  fenrir: { role: "Bête", pv: 42, att: 8, pouvoir: "Gleipnir brisé", txt: "Frappe et fait Saigner (3 par stade, 3 tours). ×1,5 sur un Gelé.", cible: "ennemi" },
  babayaga: { role: "Sorcière", pv: 36, att: 6, pouvoir: "Malédiction", txt: "La cible perd 3 PV par stade chaque tour, et ne peut plus être soignée.", cible: "ennemi" },
  wukong: { role: "Virtuose", pv: 38, att: 8, pouvoir: "Mille singes", txt: "Trois coups à ×0,45 sur la cible.", cible: "ennemi" },
  banshee: { role: "Hurleuse", pv: 36, att: 6, pouvoir: "Le cri", txt: "Tous les adversaires Affaiblis (−30 % de dégâts) pendant 2 tours.", cible: "aucune" },
  minotaure: { role: "Charge", pv: 46, att: 9, pouvoir: "Charge du labyrinthe", txt: "Frappe ×2,2, mais perd 15 % de ses PV.", cible: "ennemi" },
  quetzalcoatl: { role: "Chef", pv: 38, att: 6, pouvoir: "Souffle du vent", txt: "Toute l'équipe +3 ATT par stade pendant 2 tours.", cible: "aucune" },
  doudou: { role: "Protecteur", pv: 54, att: 6, pouvoir: "Crin porte-bonheur", txt: "Protège un allié : les coups qu'il reçoit vont sur El Biète (−30 %).", cible: "allie" },
  cerbere: { role: "Gardien", pv: 52, att: 7, pouvoir: "Trois têtes", txt: "Contre-attaque chaque coup reçu (×0,6) pendant 2 tours, +3 armure par stade.", cible: "soi" },
};
const ROSTER = Object.keys(KITS);
const STATUTS = { mouille: "Mouillé", marque: "Marqué", esquive: "Esquive", gele: "Gelé", saigne: "Saigne", malediction: "Maudit", provoque: "Provoque", affaibli: "Affaibli", buff: "Galvanisé", protege: "Protégé", contre: "Contre" };
let UID = 0;
function creer(id, camp) { const c = { uid: ++UID, id, camp, stade: 1, pv: 0, max: 0, att: 0, armure: 0, defend: false, st: {}, recharge: 0, ko: false, bonusAtt: 0, bonusPv: 0 }; recalc(c); c.pv = c.max; return c; }
function recalc(c) { const k = KITS[c.id]; c.max = Math.round(k.pv * STADE_PV[c.stade - 1]) + c.bonusPv; c.att = Math.round(k.att * STADE_ATT[c.stade - 1]) + c.bonusAtt; }
const forme = c => (FICHES[c.id].formes || [])[c.stade - 1] || nomDe(c.id);
const attaqueDe = c => c.att + (c.st.buff ? c.st.buff.v : 0);
const vivants = l => l.filter(c => !c.ko);
function evoluer(M, c) {
  if (c.stade >= 3 || c.ko) return false;
  c.stade++; recalc(c); c.pv = Math.min(c.max, c.pv + Math.round(c.max * 0.35));
  M.log(`${nomDe(c.id)} évolue : ${forme(c)} !`); M.fx(c, `stade ${["I", "II", "III"][c.stade - 1]}`, "gros");
  M.hook && M.hook("evolution", c);
  return true;
}
function typeMult(a, b) { const ta = typeDe(a.id), tb = typeDe(b.id); return bat(ta, tb) ? 1.5 : bat(tb, ta) ? 0.7 : 1; }
function frapper(M, src, cible, k = 1, o = {}) {
  if (!cible || cible.ko) return 0;
  if (cible.st.protege && !o.contre) { const p = M.tous().find(x => x.uid === cible.st.protege.par && !x.ko); if (p && p !== cible) { M.log(`${nomDe(p.id)} protège ${nomDe(cible.id)}`); cible = p; k *= 0.7; } }
  if (cible.st.esquive) { delete cible.st.esquive; M.fx(cible, "esquive !", "mot"); M.log(`${nomDe(cible.id)} esquive`); return 0; }
  let m = k * typeMult(src, cible);
  if (cible.st.mouille && typeDe(src.id) === "foudre") m *= 2;
  if (cible.st.marque) { m *= 1.5; delete cible.st.marque; }
  if (src.st.affaibli) m *= 0.7;
  if (cible.defend) m *= 0.5;
  if (cible.fragile) m *= cible.fragile;
  let d = Math.max(1, Math.round(attaqueDe(src) * m));
  const a = Math.min(cible.armure, d); cible.armure -= a; d -= a;
  cible.pv -= d;
  M.fx(cible, a && !d ? "bloqué" : `−${d}`, m >= 1.5 ? "or" : "rose");
  M.hook && M.hook("degats", src, cible, d);
  if (cible.pv <= 0) ko(M, cible, src);
  else if (cible.st.contre && !o.contre && !src.ko) frapper(M, cible, src, 0.6, { contre: true });
  return d;
}
function blesser(M, c, n, par) { if (c.ko) return; c.pv -= n; M.fx(c, `−${n}`, "rose"); M.hook && M.hook("degats", par || null, c, n); if (c.pv <= 0) ko(M, c, par || null); }
function soigner(M, c, n) {
  if (c.ko || n <= 0) return 0;
  if (c.st.malediction) { M.fx(c, "maudit : pas de soin", "mot"); return 0; }
  const s = Math.min(n, c.max - c.pv); c.pv += s; if (s) { M.fx(c, `+${s}`, "vert"); M.hook && M.hook("soin", c, s); }
  return s;
}
function ko(M, c, par) {
  c.pv = 0; c.ko = true; c.st = {}; c.armure = 0; c.defend = false;
  M.fx(c, "K.O.", "mot"); M.log(`${nomDe(c.id)} tombe`);
  M.hook && M.hook("ko", par, c);
}
function ciblesValides(liste) { const v = vivants(liste), p = v.filter(x => x.st.provoque); return p.length ? p : v; }
// Début du tour d'un camp : dégâts qui durent, statuts qui s'usent, recharge des pouvoirs.
function debutTour(M, camp) {
  for (const c of M.tous().filter(x => x.camp === camp && !x.ko)) {
    c.defend = false;
    if (c.st.saigne) { blesser(M, c, c.st.saigne.v, null); if (c.ko) continue; if (--c.st.saigne.n <= 0) delete c.st.saigne; }
    if (c.st.malediction) { blesser(M, c, c.st.malediction.v, null); if (c.ko) continue; if (--c.st.malediction.n <= 0) delete c.st.malediction; }
    for (const k of ["mouille", "provoque", "affaibli", "contre"]) if (typeof c.st[k] === "number" && --c.st[k] <= 0) delete c.st[k];
    for (const k of ["buff", "protege"]) if (c.st[k] && --c.st[k].n <= 0) delete c.st[k];
    if (c.recharge > 0) c.recharge--;
  }
}
// Le pouvoir de chaque créature. cible : la créature visée (ennemi ou allié), selon KITS[id].cible.
function pouvoir(M, c, cible) {
  const s = c.stade, adv = () => vivants(M.adversaires(c)), all = () => vivants(M.allies(c));
  M.log(`${nomDe(c.id)} : ${KITS[c.id].pouvoir}`); M.fx(c, KITS[c.id].pouvoir, "mot");
  switch (c.id) {
    case "thor": { frapper(M, c, cible, 1.5); const autre_ = adv().filter(x => x !== cible)[0]; if (autre_) frapper(M, c, autre_, 0.5); break; }
    case "golem": c.armure += 5 * s; c.st.provoque = 2; break;
    case "bahamut": for (const a of all()) soigner(M, a, 5 * s); for (const e of adv()) e.st.mouille = 3; break;
    case "kitsune": if (cible) cible.st.marque = true; c.st.esquive = true; break;
    case "yeti": frapper(M, c, cible, 0.6); if (!cible.ko) cible.st.gele = true; break;
    case "anubis": {
      const mort = M.allies(c).find(x => x.ko && !x.ranime);
      if (mort && !c.aRanime) { c.aRanime = true; mort.ranime = true; mort.ko = false; mort.pv = Math.round(mort.max * 0.4); M.fx(mort, "revient !", "gros"); M.log(`${nomDe(mort.id)} revient d'entre les morts`); M.hook && M.hook("ranime", mort); }
      else { const e = cible || adv()[0]; if (e) { const d = frapper(M, c, e, 1); soigner(M, c, d); } }
      break;
    }
    case "fenrir": frapper(M, c, cible, cible.st.gele ? 1.5 : 1); if (!cible.ko) cible.st.saigne = { v: 3 * s, n: 3 }; break;
    case "babayaga": cible.st.malediction = { v: 3 * s, n: 3 }; M.fx(cible, "maudit", "mot"); break;
    case "wukong": for (let i = 0; i < 3 && !cible.ko; i++) frapper(M, c, cible, 0.45); break;
    case "banshee": for (const e of adv()) e.st.affaibli = 2; break;
    case "minotaure": frapper(M, c, cible, 2.2); blesser(M, c, Math.round(c.max * 0.15), null); break;
    case "quetzalcoatl": for (const a of all()) a.st.buff = { v: 3 * s, n: 2 }; break;
    case "doudou": if (cible) cible.st.protege = { par: c.uid, n: 2 }; break;
    case "cerbere": c.st.contre = 2; c.armure += 3 * s; break;
  }
  c.recharge = M.recharge != null ? M.recharge : 2;
  M.hook && M.hook("pouvoir", c, cible);
}
// L'IA : ce que vaut un pouvoir maintenant (grossier, mais lisible).
function valeurPouvoir(M, c) {
  const adv = vivants(M.adversaires(c)), all = vivants(M.allies(c));
  switch (c.id) {
    case "anubis": return M.allies(c).some(x => x.ko && !x.ranime) && !c.aRanime ? 9 : 3;
    case "bahamut": return all.reduce((s, a) => s + Math.min(5 * c.stade, a.max - a.pv), 0) / 4 + adv.length;
    case "golem": case "cerbere": return c.pv < c.max * 0.7 ? 5 : 2;
    case "banshee": case "quetzalcoatl": return adv.length + 2;
    case "doudou": return all.some(a => a !== c && a.pv < a.max * 0.5) ? 5 : 1;
    default: return adv.length ? 6 : 0;
  }
}

// ——— L'interface commune ———
const Choix = { cands: null, res: null };
document.addEventListener("click", e => {
  if (!Choix.cands) return;
  const el = e.target.closest("[data-cible]");
  if (el && Choix.cands.has(el.dataset.cible)) { const r = Choix.res; Choix.cands = null; Choix.res = null; document.querySelectorAll(".ciblable").forEach(x => x.classList.remove("ciblable")); r(el.dataset.cible); }
});
function marquerCibles() { if (!Choix.cands) return; document.querySelectorAll("[data-cible]").forEach(x => x.classList.toggle("ciblable", Choix.cands.has(x.dataset.cible))); }
function choisir(cands) { return new Promise(r => { Choix.cands = new Set(cands.map(String)); Choix.res = r; marquerCibles(); }); }
function annulerChoix() { if (Choix.res) { const r = Choix.res; Choix.cands = null; Choix.res = null; document.querySelectorAll(".ciblable").forEach(x => x.classList.remove("ciblable")); r(null); } }
function elCreature(c, o = {}) {
  const w = h("div", `cr2 ${c.camp}${c.ko ? " ko" : ""}${o.sel ? " sel" : ""}${o.petit ? " petit" : ""}`);
  w.dataset.cible = c.uid; w.dataset.uid = c.uid;
  const v = vignette(c.id, { stade: c.stade, nom: false }); w.append(v);
  v.append(h("span", "cr2-stade", ["I", "II", "III"][c.stade - 1]));
  if (o.plan) v.append(h("span", "cr2-plan", o.plan));
  const pv = h("div", "cr2-pv"), b = h("i"); b.style.width = Math.max(0, c.pv / c.max * 100) + "%"; pv.append(b);
  w.append(h("div", "cr2-nom", nomDe(c.id)), pv, h("div", "cr2-chiffres", c.ko ? "tombé" : `${Math.max(0, c.pv)} PV · ${attaqueDe(c)} ATT${c.armure ? ` · ${c.armure} arm.` : ""}`));
  const st = Object.keys(c.st).filter(k => STATUTS[k]).map(k => STATUTS[k]);
  if (c.defend) st.unshift("Défend");
  if (st.length) w.append(h("div", "cr2-statuts", st.join(" · ")));
  if (o.extra) w.append(o.extra);
  if (o.onclick) w.addEventListener("click", () => { if (!Choix.cands) o.onclick(); });
  return w;
}
function panneau(el, titre, actions, annuler) {
  el.innerHTML = "";
  if (titre) el.append(h("div", "pn-titre", titre));
  const g = h("div", "pn-actions");
  for (const a of actions) {
    const b = h("button", "pn-btn" + (a.cls ? " " + a.cls : ""));
    b.append(h("b", "", a.nom)); if (a.txt) b.append(h("span", "", a.txt));
    b.disabled = a.dispo === false; b.onclick = () => a.f();
    g.append(b);
  }
  el.append(g);
  if (annuler) { const b = h("button", "pn-annuler", "Annuler"); b.onclick = annuler; el.append(b); }
}
// Un match minimal : il suffit de fournir tous(), adversaires(c), allies(c) et, si besoin, hook().
function matchDe(ctx, zLog, o) {
  const M = {
    log(t) { if (zLog) zLog.textContent = t; },
    fx(c, t, k) { const e = document.querySelector(`.cr2[data-uid="${c.uid}"]`); if (e) flotSur(e, t, k || "", 0.35); },
    ...o,
  };
  return M;
}
