// ═════════════════════════════ Le socle « stratégie avant le combat » (s01 → s11) ═════════════════════════════
// Chaque concept fournit : ses adversaires (étapes), sa préparation, sa simulation DÉTERMINISTE, et sa vue.
// Le socle fait le reste : préparer → lancer → regarder → récit de la défaite → modifier → relancer.
// Aucun hasard dans les simulations : même préparation, même adversaire, même résultat.
const VIT = { Frappeur: 6, Tank: 3, Soutien: 4, "Rusée": 8, "Contrôle": 4, "Nécromancien": 4, "Bête": 7, "Sorcière": 5, Virtuose: 7, Hurleuse: 5, Charge: 5, Chef: 5, Protecteur: 3, Gardien: 3 };
const vitDe = id => VIT[KITS[id].role] || 5;
function unite(id, camp, o = {}) {
  const k = KITS[id];
  return { uid: ++UID, id, camp, stade: o.stade || 1, pv: o.pv || k.pv, max: o.pv || k.pv, att: o.att || k.att, vit: vitDe(id), armure: 0, st: {}, ko: false, defend: false, ...o.plus };
}
// Une copie légère pour la vue (les cartes n'ont besoin que de ces champs)
const copieU = u => ({ uid: u.uid, id: u.id, camp: u.camp, stade: u.stade, pv: Math.max(0, Math.round(u.pv)), max: u.max, att: u.att, armure: Math.round(u.armure || 0), st: { ...u.st }, ko: u.ko, defend: u.defend, x: u.x, y: u.y, extra: u.extra });
// Le journal d'une simulation : des pas (vue + message + effets), et les faits pour le récit.
function Journal() {
  const J = { pas: [], faits: {}, n: 0 };
  J.fait = (u, k, v = 1) => { const f = J.faits[u.uid] || (J.faits[u.uid] = { u, inflige: 0, recu: 0, gele: 0, actions: 0, tombe: null }); f[k] = (f[k] || 0) + v; };
  J.pas_ = (vue, msg, fx = [], duree) => { J.n++; J.pas.push({ vue, msg, fx, duree }); };
  J.tomber = u => { const f = J.faits[u.uid] || (J.faits[u.uid] = { u, inflige: 0, recu: 0, gele: 0, actions: 0, tombe: null }); if (f.tombe == null) f.tombe = J.n; };
  // Trois lignes qui expliquent le combat, du point de vue du joueur
  J.recit = (plus = []) => {
    const fs = Object.values(J.faits), miens = fs.filter(f => f.u.camp === "j"), siens = fs.filter(f => f.u.camp === "a");
    const l = [...plus];
    const premier = miens.filter(f => f.tombe != null).sort((a, b) => a.tombe - b.tombe)[0];
    if (premier) l.push(`${nomDe(premier.u.id)} est tombé en premier (au pas ${premier.tombe}).`);
    const inactif = miens.filter(f => f.gele >= 2).sort((a, b) => b.gele - a.gele)[0];
    if (inactif) l.push(`${nomDe(inactif.u.id)} a été bloqué ${inactif.gele} fois.`);
    const star = siens.sort((a, b) => b.inflige - a.inflige)[0];
    if (star && star.inflige) l.push(`Son ${nomDe(star.u.id)} t'a infligé ${Math.round(star.inflige)} dégâts.`);
    const toi = miens.sort((a, b) => b.inflige - a.inflige)[0];
    if (toi && toi.inflige) l.push(`Ton meilleur : ${nomDe(toi.u.id)}, ${Math.round(toi.inflige)} dégâts.`);
    return l.slice(0, 3);
  };
  return J;
}
// Des coups simples et prévisibles : dégâts = ATT × multiplicateurs − armure, jamais de hasard.
function coup(J, src, cible, k = 1, fx) {
  if (!cible || cible.ko) return 0;
  let m = k * typeMult(src, cible);
  if (cible.defend) m *= 0.5;
  if (src.st && src.st.affaibli) m *= 0.7;
  let d = Math.max(1, Math.round(src.att * m));
  const a = Math.min(cible.armure || 0, d); cible.armure -= a; d -= a;
  cible.pv -= d;
  J.fait(src, "inflige", d); J.fait(cible, "recu", d);
  if (fx) fx.push([cible.uid, a && !d ? "bloqué" : `−${d}`, m > 1.2 ? "or" : "rose"]);
  if (cible.pv <= 0 && !cible.ko) { cible.pv = 0; cible.ko = true; J.tomber(cible); if (fx) fx.push([cible.uid, "K.O.", "mot"]); }
  return d;
}
function guerir(J, u, n, fx) { if (u.ko || n <= 0) return 0; const s = Math.min(n, u.max - u.pv); u.pv += s; if (s && fx) fx.push([u.uid, `+${s}`, "vert"]); return s; }

// ——— Le déroulé commun ———
function proto(cfg) {
  const memo = {};
  const lancer = function (ctx) {
    let etapeI = 0, essais = 0, prep = null, lecture = null;
    const zHaut = h("div", "sp-haut"), zCorps = h("div", "sp-corps"), zBas = h("div", "sp-bas");
    ctx.scene.append(zHaut, zCorps, zBas);
    const etape = () => cfg.etapes[etapeI];
    function entete() { ctx.score.innerHTML = `<span class="sep">adversaire</span><span class="a">${etapeI + 1}/${cfg.etapes.length}</span>`; }
    function preparer() {
      lecture = null; entete();
      if (!memo[etapeI]) memo[etapeI] = cfg.initPrep(etape(), etapeI);
      prep = memo[etapeI];
      ctx.consigne(`Prépare ta stratégie · ${etape().nom}`);
      zHaut.innerHTML = ""; zHaut.append(h("div", "sp-adv", etape().desc || ""));
      const maj = () => { zCorps.innerHTML = ""; cfg.rendrePrep(zCorps, prep, etape(), maj); marquerCibles(); const v = cfg.pret ? cfg.pret(prep, etape()) : true; b.disabled = v !== true; b.querySelector("span").textContent = v === true ? `essai n° ${essais + 1}` : v; };
      zBas.innerHTML = "";
      const b = h("button", "pn-btn or sp-go"); b.append(h("b", "", "Lancer le combat"), h("span", "", ""));
      b.onclick = combattre; zBas.append(b);
      maj();
    }
    async function combattre() {
      essais++;
      const res = cfg.simuler(JSON.parse(JSON.stringify(prep)), etape());
      noterLocal(res.gagne);
      jouer(res);
    }
    function noterLocal(g) { noter(Jeu.courante.id, g); }
    async function jouer(res) {
      const jeton = {}; lecture = jeton;
      let vitesse = 1, passer = false, pause = false;
      zHaut.innerHTML = ""; const msg = h("div", "sp-msg"); zHaut.append(msg);
      zBas.innerHTML = "";
      const bp = h("button", "btn sec", "Pause"), bv = h("button", "btn sec", "×2"), bs = h("button", "btn sec", "Passer");
      bp.onclick = () => { pause = !pause; bp.textContent = pause ? "Reprendre" : "Pause"; };
      bv.onclick = () => { vitesse = vitesse === 1 ? 2.5 : 1; bv.textContent = vitesse === 1 ? "×2" : "×1"; };
      bs.onclick = () => { passer = true; };
      const r = h("div", "rangee"); r.append(bp, bv, bs); zBas.append(r);
      ctx.consigne("Le combat se joue tout seul", "calme");
      for (let i = 0; i < res.pas.length; i++) {
        if (lecture !== jeton || !ctx.vivant()) return;
        const p = res.pas[i];
        if (passer && i < res.pas.length - 1) continue;
        zCorps.innerHTML = ""; cfg.rendreVue(zCorps, p.vue, etape());
        msg.textContent = p.msg || "";
        for (const [uid, t, k] of p.fx || []) flotSur(zCorps.querySelector(`[data-uid="${uid}"]`), t, k);
        await dodo((p.duree || 650) / vitesse);
        while (pause && lecture === jeton && ctx.vivant()) await dodo(150);
      }
      if (lecture !== jeton || !ctx.vivant()) return;
      resultat(res);
    }
    function resultat(res) {
      const boite = h("div", "sp-res " + (res.gagne ? "gagne" : "perdu"));
      boite.append(h("h3", "", res.titre || (res.gagne ? "Victoire" : "Défaite")));
      const ul = h("ul", "sp-recit"); for (const l of res.recit || []) ul.append(h("li", "", l)); boite.append(ul);
      zBas.innerHTML = "";
      const r = h("div", "sp-choix");
      const b1 = h("button", "pn-btn or"); b1.append(h("b", "", res.gagne ? "Adversaire suivant" : "Modifier ma stratégie"), h("span", "", res.gagne ? (etapeI + 1 < cfg.etapes.length ? cfg.etapes[etapeI + 1].nom : "recommencer au premier") : "tes choix sont gardés"));
      b1.onclick = () => { if (res.gagne) { etapeI = (etapeI + 1) % cfg.etapes.length; essais = 0; } preparer(); };
      const b2 = h("button", "pn-btn"); b2.append(h("b", "", "Revoir"), h("span", "", "le même combat"));
      b2.onclick = () => jouer(res);
      const b3 = h("button", "pn-btn"); b3.append(h("b", "", res.gagne ? "Modifier" : "Relancer tel quel"), h("span", "", res.gagne ? "rejouer ce combat autrement" : "même résultat : c'est déterministe"));
      b3.onclick = () => res.gagne ? preparer() : combattre();
      r.append(b1, b2, b3); zBas.append(boite, r);
      ctx.consigne(res.gagne ? `Gagné en ${essais} essai${essais > 1 ? "s" : ""}` : "Perdu : change quelque chose", res.gagne ? "" : "lui");
    }
    preparer();
    if (Jeu.tuto && cfg.tuto) (async () => { for (const t of cfg.tuto) await ctx.etape({ texte: t }); ctx.tutoFini(); })();
  };
  lancer.cfg = cfg;
  return lancer;
}
const tirer = (R, l) => l[Math.floor(R() * l.length)];
const tirerN = (R, l, n) => { const c = [...l]; const out = []; while (out.length < n && c.length) out.push(c.splice(Math.floor(R() * c.length), 1)[0]); return out; };
// ——— Petits outils de préparation ———
// Choisir N héros parmi une réserve (l'ordre de sélection compte)
function choixHeros(z, reserve, choisis, max, maj, titre) {
  const box = h("div", "sp-bloc"); box.append(h("div", "sp-tit", `${titre || "Ton équipe"} · ${choisis.length}/${max}`));
  const g = h("div", "sp-reserve");
  for (const id of reserve) {
    const i = choisis.indexOf(id), b = h("button", "sp-hero" + (i >= 0 ? " pris" : ""));
    b.append(vignette(id, { stade: 1, nom: false }), h("b", "", nomDe(id)), h("span", "", KITS[id].role));
    if (i >= 0) b.append(h("em", "", i + 1));
    b.onclick = () => { if (i >= 0) choisis.splice(i, 1); else if (choisis.length < max) choisis.push(id); maj(); };
    g.append(b);
  }
  box.append(g); z.append(box);
}
function selecteur(options, valeur, onChange, cls = "") {
  const s = h("select", "sp-sel " + cls);
  for (const [v, t] of options) { const o = h("option", "", t); o.value = v; if (String(v) === String(valeur)) o.selected = true; s.append(o); }
  s.onchange = () => onChange(s.value);
  return s;
}
// Un pion rond (vue de dessus) pour les grilles
function pion(u, o = {}) {
  const w = h("div", "sp-pion " + u.camp + (u.ko ? " ko" : "") + (o.chef ? " chef" : "")); w.dataset.uid = u.uid;
  const f = FICHES[u.id], im = h("img"); im.src = `img/${u.id}-${Math.min(u.stade || 1, f.stades || 1)}.jpg`; im.alt = ""; im.style.objectPosition = `50% ${((f.cads || [f.cad])[0]) * 100}%`;
  w.append(im);
  const frag = document.createDocumentFragment(); frag.append(w);
  if (!u.ko) { const pv = h("div", "sp-pv " + u.camp), i = h("i"); i.style.width = Math.max(0, u.pv / u.max * 100) + "%"; pv.append(i); frag.append(pv); }
  if (o.tag) frag.append(h("span", "sp-tag", o.tag));
  return frag;
}
