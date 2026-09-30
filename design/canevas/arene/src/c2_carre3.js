// ═════════════════════════════ C2 · LE CARRÉ DES ASTRES — prototype v2 ═════════════════════════════
// Retours de Maxim sur la v1 (26/09/2026) :
// · 3×3 par défaut ; le 4×4 devient un ÉVÉNEMENT (le Grand Carré, avec 3 renforts et un gouffre)
// · le Yéti bien trop fort → rééquilibré ; l'ordinateur imbattable → 3 niveaux (Apprenti, Aventurier, Maître)
// · la carte refaite AVEC ses variantes (base, or, ombre, élémentaire, prismatique, full art) et les chiffres
// · un plateau dans la DA · une page pour créer ses decks, et on choisit son deck avant la partie
// · les pouvoirs visibles : une icône sur la carte, une fiche claire quand on la touche
(function () {
  const OPP = [2, 3, 0, 1];
  const MODELES = { frappeur: [9, 6, 4, 3], garde: [6, 6, 6, 5], appui: [8, 5, 5, 4], sbire: [5, 4, 3, 2] };
  const TAILLE = 5, POIDS_MAX = 14;
  const VARIANTES_ID = ["base", "or", "ombre", "elem", "prisme", "full"];
  const NOM_VAR = { base: "Base", or: "Or", ombre: "Ombre", elem: "Élémentaire", prisme: "Prismatique", full: "Full art" };
  const COUL_T = { feu: ["#e0743a", "#ffc38a", "#4a1d0c"], foudre: ["#6f8fff", "#dfe8ff", "#1a1e4d"], eau: ["#2f95ad", "#a8e6f0", "#0c2f3a"], glace: ["#8fc3de", "#f2fbff", "#26404f"], nature: ["#6f9a4c", "#d4e8b0", "#203014"], esprit: ["#9a7de0", "#efe4ff", "#281d44"], aucun: ["#8e8a82", "#e6e0d4", "#2b2926"] };
  // Les pouvoirs : un nom, une icône nette, une phrase, et ce que change le stade III
  const G = {
    foudre: '<path d="M13 2 5 13h6l-2 9 9-12h-6l1-8z"/>',
    esquive: '<path d="M4 16c3-7 9-10 16-9M16 3l4 4-4 4" fill="none"/><path d="M4 20h7" fill="none"/>',
    rempart: '<path d="M12 2 20 5v7c0 5-4 8-8 10-4-2-8-5-8-10V5z"/>',
    maree: '<path d="M2 9c3-3 5 3 8 0s5 3 8 0 3-1 4-1M2 15c3-3 5 3 8 0s5 3 8 0 3-1 4-1" fill="none"/>',
    gel: '<path d="M12 2v20M3.3 7l17.4 10M3.3 17 20.7 7M9 3.5l3 2.5 3-2.5M9 20.5l3-2.5 3 2.5" fill="none"/>',
    meta: '<path d="M4 8h13l-4-4M20 16H7l4 4" fill="none"/>',
    ame: '<path d="M12 11c-3 0-4-2.5-4-4.5S9.8 2 12 2s4 2.5 4 4.5S15 11 12 11zM12 11v11M6 14h12" fill="none"/>',
    faim: '<path d="M6 3c1 6 1 11-1 18M12 3c1 6 1 11-1 18M18 3c1 6 1 11-1 18" fill="none"/>',
    tetes: '<path d="M4 4l6 6M20 4l-6 6M4 20l6-6M20 20l-6-6" fill="none"/><circle cx="12" cy="12" r="2.5"/>',
    maledic: '<path d="M2 12c3-5 7-7 10-7s7 2 10 7c-3 5-7 7-10 7s-7-2-10-7z" fill="none"/><circle cx="12" cy="12" r="3"/>',
  };
  const POUV = {
    thor: { g: "foudre", nom: "Foudre", quand: "à la pose", txt: s => `Ses côtés qui touchent une carte adverse gagnent +${s === 3 ? 2 : 1}.` },
    kitsune: { g: "esquive", nom: "Esquive", quand: "toujours", txt: s => s === 3 ? "Jamais retournée par une chaîne. Et au tour qui suit sa pose, jamais retournée du tout." : "Jamais retournée par une chaîne : seule une carte posée contre elle peut la prendre." },
    golem: { g: "rempart", nom: "Rempart", quand: "après sa pose", txt: s => s === 3 ? "Personne ne peut le retourner pendant les 2 tours adverses qui suivent sa pose." : "Personne ne peut le retourner au tour adverse qui suit sa pose." },
    bahamut: { g: "maree", nom: "Marée", quand: "tant qu'il est posé", txt: s => `Tes cartes qui le touchent gagnent +${s === 3 ? 2 : 1} partout.` },
    yeti: { g: "gel", nom: "Gel", quand: "à la pose", txt: s => s === 3 ? "Les cases vides qui le touchent gèlent : ton adversaire ne peut pas y poser à son prochain tour." : "La case vide face à son côté le plus faible gèle : ton adversaire ne peut pas y poser à son prochain tour." },
    loki: { g: "meta", nom: "Métamorphose", quand: "à la pose", txt: s => s === 3 ? "Garde, côté par côté, le plus fort entre ses chiffres et ceux de la carte voisine la plus forte." : "Prend les chiffres de la carte voisine la plus forte (amie ou ennemie), moins 1." },
    anubis: { g: "ame", nom: "Pesée des âmes", quand: "quand il est retourné", txt: s => `Tu reprends aussitôt ${s === 3 ? "les 2 cartes adverses voisines les plus faibles" : "la carte adverse voisine la plus faible"}. Une fois par partie.` },
    fenrir: { g: "faim", nom: "Faim", quand: "quand il retourne", txt: s => `Chaque carte qu'il retourne lui donne +1 partout (au plus +${s === 3 ? 3 : 2}).` },
    cerbere: { g: "tetes", nom: "Trois têtes", quand: "quand il attaque", txt: s => `Attaque aussi en diagonale, avec ${s === 3 ? "le plus grand" : "le plus petit"} de ses deux chiffres de ce coin.` },
    babayaga: { g: "maledic", nom: "Malédiction", quand: "à la pose", txt: s => `Les cartes adverses qui la touchent perdent ${s === 3 ? 2 : 1} partout.` },
  };
  const glyphe = (k, cls = "") => `<svg class="${cls}" viewBox="0 0 24 24" aria-hidden="true">${G[k]}</svg>`;
  const unSeul = id => !FICHES[id].sbire && FICHES[id].stades === 1;
  const stadeEff = (id, s) => FICHES[id].sbire ? 1 : unSeul(id) ? 3 : s;
  const poids = (id, s) => FICHES[id].sbire ? 1 : unSeul(id) ? 4 : s + 1;
  const aff = v => v >= 10 ? "A" : v;
  function base(id) {
    const rng = rngDe(hacher("carre-" + id)), f = FICHES[id];
    const t = [...(MODELES[f.role] || MODELES.appui)], rot = Math.floor(rng() * 4);
    const r = t.map((_, i) => t[(i + rot) % 4]);
    const a = Math.floor(rng() * 4), b = (a + 1 + Math.floor(rng() * 3)) % 4;
    if (r[a] < 9 && r[b] > 2) { r[a]++; r[b]--; }
    return r;
  }
  function chiffresDe(id, s) {
    const r = base(id), f = FICHES[id];
    if (f.sbire) return r;
    const st = stadeEff(id, s);
    if (!POUV[id] || id === "kitsune" || id === "bahamut") r[r.indexOf(Math.max(...r))]++;   // sans pouvoir, ou pouvoir discret : +1
    const idx = [0, 1, 2, 3];
    if (st >= 2) for (const i of idx.slice().sort((x, y) => r[y] - r[x] || x - y).slice(0, 3)) r[i]++;
    if (st >= 3) for (const i of idx.slice().sort((x, y) => r[x] - r[y] || x - y).slice(0, 3)) r[i]++;
    return r.map(v => Math.min(10, v));
  }

  // ═══ Les règles ═══
  function orth(n, i) { const l = Math.floor(i / n), c = i % n, v = []; if (l > 0) v.push([i - n, 0]); if (c < n - 1) v.push([i + 1, 1]); if (l < n - 1) v.push([i + n, 2]); if (c > 0) v.push([i - 1, 3]); return v; }
  function diag(n, i) { const l = Math.floor(i / n), c = i % n, v = []; for (const [dl, dc, sv, sh] of [[-1, 1, 0, 1], [1, 1, 2, 1], [1, -1, 2, 3], [-1, -1, 0, 3]]) { const L = l + dl, C = c + dc; if (L >= 0 && C >= 0 && L < n && C < n) v.push([L * n + C, sv, sh]); } return v; }
  function valeurs(st, i) {
    const c = st.cases[i], v = c.ch.slice();
    for (const [k] of orth(st.n, i)) { const b = st.cases[k]; if (b && b.camp === c.camp && b.id === "bahamut") for (let s = 0; s < 4; s++) v[s] += b.s === 3 ? 2 : 1; }
    return v.map(x => Math.min(10, x));
  }
  function protegee(st, i, parChaine) {
    const c = st.cases[i];
    if (c.id === "kitsune" && (parChaine || (c.s === 3 && st.tour <= c.pose + 1))) return true;
    if (c.id === "golem" && st.tour <= c.pose + (c.s === 3 ? 3 : 1)) return true;
    return false;
  }
  const libre = (st, i) => !st.cases[i] && !st.bloc.includes(i);
  function poser(st, camp, carte, i) {
    st.tour++;
    const c = { uid: ++st.uid, id: carte.id, s: stadeEff(carte.id, carte.s), v: carte.v, camp, ch: chiffresDe(carte.id, carte.s), pose: st.tour, faim: 0 };
    if (st.terres[i] && st.terres[i] === typeDe(c.id)) { c.ch = c.ch.map(x => Math.min(10, x + 1)); c.terre = true; }
    st.cases[i] = c;
    const ev = [], ennemis = () => orth(st.n, i).filter(([k]) => st.cases[k] && st.cases[k].camp !== camp);
    if (c.id === "thor") { const k = c.s === 3 ? 2 : 1, e = ennemis(); for (const [, s] of e) c.ch[s] = Math.min(10, c.ch[s] + k); if (e.length) ev.push({ t: "pouvoir", i, id: c.id, txt: `Foudre : +${k} face à l'ennemi` }); }
    if (c.id === "loki") { const v = orth(st.n, i).filter(([k]) => st.cases[k]).map(([k]) => valeurs(st, k)).sort((a, b) => b.reduce((x, y) => x + y) - a.reduce((x, y) => x + y))[0]; if (v) { c.ch = c.s === 3 ? c.ch.map((x, s) => Math.max(x, v[s])) : v.map(x => Math.max(1, x - 1)); ev.push({ t: "pouvoir", i, id: c.id, txt: "Métamorphose : il copie la plus forte" }); } }
    if (c.id === "babayaga") { const k = c.s === 3 ? 2 : 1, e = ennemis(); for (const [n] of e) st.cases[n].ch = st.cases[n].ch.map(x => Math.max(1, x - k)); if (e.length) ev.push({ t: "pouvoir", i, id: c.id, txt: `Malédiction : −${k} aux voisines` }); }
    if (c.id === "yeti") {
      const vides = orth(st.n, i).filter(([k]) => libre(st, k));
      const gel = c.s === 3 ? vides : vides.sort((a, b) => c.ch[a[1]] - c.ch[b[1]]).slice(0, 1);
      for (const [k] of gel) st.gel[k] = { contre: autre(camp), jusqua: st.tour + 1 };
      if (gel.length) ev.push({ t: "pouvoir", i, id: c.id, txt: `Gel : ${gel.length > 1 ? gel.length + " cases gelées" : "une case gelée"}` });
    }
    // Une carte reprise par Anubis depuis son entrée dans la file n'attaque plus (27/09 : sinon la chaîne
    // peut tourner sans fin — Cerbère en diagonale, Anubis retourné). Même règle que carre/moteur_carre.gd.
    const file = [[i, camp]];
    while (file.length) {
      const [k, campFile] = file.shift(), a = st.cases[k], campA = a.camp;
      if (campA !== campFile) continue;
      const cibles = orth(st.n, k).map(([m, s]) => ({ m, va: () => valeurs(st, k)[s], vd: () => valeurs(st, m)[OPP[s]] }));
      if (a.id === "cerbere") for (const [m, sv, sh] of diag(st.n, k)) cibles.push({ m, diag: true, va: () => { const v = valeurs(st, k); return a.s === 3 ? Math.max(v[sv], v[sh]) : Math.min(v[sv], v[sh]); }, vd: () => { const v = valeurs(st, m); return Math.min(v[OPP[sv]], v[OPP[sh]]); } });
      for (const cb of cibles) {
        if (st.cases[k].camp !== campA) break;
        const d = st.cases[cb.m]; if (!d || d.camp === campA) continue;
        const x = cb.va(), y = cb.vd();
        if (x > y && !protegee(st, cb.m, k !== i)) {
          const ancien = d.camp; d.camp = campA;
          ev.push({ t: "flip", de: k, vers: cb.m, a: x, b: y, chaine: k !== i, diag: !!cb.diag, prev: ancien, camp: campA });
          file.push([cb.m, campA]);
          if (a.id === "fenrir" && a.faim < (a.s === 3 ? 3 : 2)) { a.faim++; a.ch = a.ch.map(v => Math.min(10, v + 1)); ev.push({ t: "pouvoir", i: k, id: "fenrir", txt: "Faim : +1 partout" }); }
          if (d.id === "anubis" && !d.useAnubis) {
            d.useAnubis = true;
            const pris = orth(st.n, cb.m).map(([m]) => m).filter(m => st.cases[m] && st.cases[m].camp === campA).sort((p, q) => valeurs(st, p).reduce((u, w) => u + w) - valeurs(st, q).reduce((u, w) => u + w)).slice(0, d.s === 3 ? 2 : 1);
            for (const m of pris) { st.cases[m].camp = ancien; ev.push({ t: "anubis", de: cb.m, vers: m, prev: campA, camp: ancien }); }
            if (pris.length) ev.push({ t: "pouvoir", i: cb.m, id: "anubis", txt: "Pesée des âmes : une carte reprise" });
          }
        } else if (x > y) ev.push({ t: "protege", i: cb.m, id: d.id });
      }
    }
    return ev;
  }
  const compte = (st, camp) => st.cases.filter(c => c && c.camp === camp).length;
  const cloner = st => ({ ...st, cases: st.cases.map(c => c && { ...c, ch: c.ch.slice() }), gel: { ...st.gel }, main: { j: st.main.j.slice(), a: st.main.a.slice() } });
  const plein = st => st.cases.every((c, i) => c || st.bloc.includes(i));
  function casesPour(st, camp) {
    const l = st.cases.map((c, i) => i).filter(i => libre(st, i));
    const sansGel = l.filter(i => !(st.gel[i] && st.gel[i].contre === camp && st.gel[i].jusqua >= st.tour + 1));
    return sansGel.length ? sansGel : l;
  }
  function coups(st, camp) { const cs = casesPour(st, camp), vus = new Set(), l = []; st.main[camp].forEach((c, h) => { const cle = c.id + c.s; if (vus.has(cle)) return; vus.add(cle); for (const i of cs) l.push([h, i]); }); return l; }
  function jouerCoup(st, camp, [h, i]) { const c = st.main[camp][h]; st.main[camp] = st.main[camp].filter((_, k) => k !== h); return poser(st, camp, c, i); }
  // L'ordinateur, en trois niveaux
  function coupIA(st, rng, moi, niveau) {
    const lui = autre(moi);
    const tous = coups(st, moi).map(m => { const s = cloner(st); jouerCoup(s, moi, m); return { m, s, v: compte(s, moi) - compte(s, lui) }; });
    if (niveau === "apprenti") {
      if (rng() < 0.55) return tous[Math.floor(rng() * tous.length)].m;
      tous.sort((a, b) => b.v - a.v); return tous[Math.floor(rng() * Math.min(5, tous.length))].m;
    }
    if (niveau === "aventurier") { let b = null; for (const c of tous) { const v = c.v + rng() * 1.2; if (!b || v > b.v) b = { v, m: c.m }; } return b.m; }
    let best = null;
    for (const c of tous.sort((a, b) => b.v - a.v).slice(0, 10)) {
      let pire = c.v;
      if (!plein(c.s) && c.s.main[lui].length) for (const r of coups(c.s, lui)) { const s2 = cloner(c.s); jouerCoup(s2, lui, r); pire = Math.min(pire, compte(s2, moi) - compte(s2, lui)); }
      const v = pire + rng() * 0.5;
      if (!best || v > best.v) best = { v, m: c.m };
    }
    return best.m;
  }

  // ═══ Adversaires, decks ═══
  const NIVEAUX = { apprenti: "Apprenti", aventurier: "Aventurier", maitre: "Maître" };
  const C = (id, s = 1, v = "base") => ({ id, s, v });
  const ADVERSAIRES = [
    { nom: "Le Korrigan des landes", niveau: "apprenti", desc: "Pour commencer : des sbires et des héros tout jeunes.", deck: [C("farfadet"), C("draugr"), C("oni"), C("wukong"), C("nian")] },
    { nom: "Les eaux dormantes", niveau: "aventurier", desc: "Bahamut renforce ses voisins, Kitsune esquive les chaînes.", deck: [C("bahamut", 2, "elem"), C("kitsune", 2), C("kelpie"), C("banshee"), C("ondine")] },
    { nom: "Les gardiens du Nord", niveau: "aventurier", desc: "Thor et le Yéti, qui gèle une case.", deck: [C("thor", 1, "or"), C("yeti", 2), C("fenrir"), C("loki"), C("draugr")] },
    { nom: "Les Enfers", niveau: "maitre", desc: "Cerbère frappe en diagonale, Baba Yaga maudit, Anubis reprend ce qu'on lui vole.", deck: [C("cerbere", 3, "ombre"), C("babayaga", 2), C("anubis", 2), C("oni"), C("follet")] },
    { nom: "Événement : le Grand Carré", niveau: "aventurier", evenement: true, desc: "4×4 avec un gouffre. Chacun reçoit 3 renforts : Golem, Minotaure et Quetzalcoatl.", deck: [C("minotaure", 2), C("troll", 2), C("chupacabra"), C("wendigo"), C("raiju")] },
  ];
  const RENFORTS = [C("golem", 2, "or"), C("minotaure", 2), C("quetzalcoatl", 2, "prisme")];
  const DECK_DEPART = { nom: "Mon premier deck", cartes: [C("thor", 2, "full"), C("golem", 1, "or"), C("bahamut", 1, "elem"), C("kitsune", 1, "prisme"), C("draugr")] };
  const poidsDeck = cs => cs.reduce((x, c) => x + poids(c.id, c.s), 0);
  const deckValide = d => d.cartes.length === TAILLE && poidsDeck(d.cartes) <= POIDS_MAX;
  const CLE = "carre-v2";
  function lire() { try { const r = JSON.parse(localStorage.getItem(CLE)); if (r && r.decks && r.decks.length) return r; } catch (e) {} return { decks: [JSON.parse(JSON.stringify(DECK_DEPART))], actif: 0, adv: 0 }; }
  function sauver(R) { try { localStorage.setItem(CLE, JSON.stringify(R)); } catch (e) {} }

  // ═══ La carte, avec ses variantes ═══
  function carte(c, o = {}) {
    const f = FICHES[c.id], st = stadeEff(c.id, c.s), ty = f.type, [e, ec, es] = COUL_T[ty];
    const v = f.sbire && c.v !== "base" ? c.v : c.v || "base";
    const w = h("div", `cc v-${v}${o.camp ? " camp-" + o.camp : ""}${o.cls ? " " + o.cls : ""}`);
    w.style.setProperty("--e", e); w.style.setProperty("--ec", ec); w.style.setProperty("--es", es);
    if (o.w) w.style.setProperty("--w", o.w + "px");
    w.append(h("div", "cc-cadre"));
    const art = h("div", "cc-art");
    if (f.sbire) { art.classList.add("sbire"); art.innerHTML = etoile("", 4, 0.22); }
    else { const im = h("img"); im.src = `img/hd/${c.id}-${Math.min(st, f.stades)}.jpg`; im.alt = ""; im.draggable = false; im.style.objectPosition = `50% ${((f.cads || [f.cad])[Math.min(st, f.stades) - 1]) * 100}%`; art.append(im); }
    w.append(art);
    const fx = h("div", "cc-fx");
    if (v === "elem") for (let k = 0; k < 7; k++) { const p = h("i"); p.style.left = (8 + k * 13) + "%"; p.style.animationDelay = (-k * 0.73) + "s"; p.style.animationDuration = (2.6 + (k % 3) * 0.7) + "s"; fx.append(p); }
    w.append(fx);
    const ch = o.ch || chiffresDe(c.id, c.s);
    const cr = h("div", "cc-ch");
    ["h", "d", "b", "g"].forEach((k, i) => { const b = h("b", "cc-" + k, aff(ch[i])); if (o.plus && o.plus[i]) b.classList.add("plus"); if (o.moins && o.moins[i]) b.classList.add("moins"); cr.append(b); });
    w.append(cr);
    if (POUV[c.id]) { const p = h("div", "cc-pouv"); p.innerHTML = glyphe(POUV[c.id].g); w.append(p); }
    const nom = h("div", "cc-nom"); nom.append(h("span", "", f.nom));
    if (!f.sbire && !unSeul(c.id)) { const pips = h("i", "cc-st"); for (let k = 1; k <= 3; k++) pips.append(h("u", k <= st ? "on" : "")); nom.append(pips); }
    w.append(nom);
    if (o.poids) w.append(h("div", "cc-poids", poids(c.id, c.s)));
    if (o.etat) w.append(o.etat);
    return w;
  }
  // La fiche : la carte en grand, et son pouvoir en toutes lettres
  function fiche(c, actions = [], extra) {
    const voile = h("div", "cf-voile"), b = h("div", "cf-boite");
    const f = FICHES[c.id], st = stadeEff(c.id, c.s), p = POUV[c.id];
    b.append(carte(c, { w: 170 }));
    const t = h("div", "cf-txt");
    t.append(h("h3", "", f.nom), h("div", "cf-sous", `${f.sbire ? "Sbire" : unSeul(c.id) ? "Forme unique" : ((f.formes || [])[st - 1] || "") + ` · stade ${["I", "II", "III"][st - 1]}`} · ${TYPES[f.type].nom} · ${NOM_VAR[c.v || "base"]} · poids ${poids(c.id, c.s)}`));
    if (p) {
      const pv = h("div", "cf-pouv"); pv.innerHTML = glyphe(p.g);
      const tx = h("div"); tx.append(h("b", "", p.nom), h("em", "", p.quand), h("p", "", p.txt(st)));
      if (st < 3 && !f.sbire && !unSeul(c.id)) tx.append(h("small", "", `Au stade III : ${p.txt(3)}`));
      pv.append(tx); t.append(pv);
    } else t.append(h("p", "cf-sans", f.sbire ? "Un sbire : pas de pouvoir, mais il ne pèse que 1." : "Pas de pouvoir : ses chiffres sont un peu plus hauts."));
    if (extra) t.append(extra);
    const ac = h("div", "cf-ac");
    for (const a of actions) { const bt = h("button", "btn " + (a.cls || "sec"), a.nom); bt.onclick = () => { if (a.garder) a.f(); else { voile.remove(); a.f(); } }; ac.append(bt); }
    const fer = h("button", "btn sec", "Fermer"); fer.onclick = () => voile.remove(); ac.append(fer);
    t.append(ac); b.append(t); voile.append(b);
    voile.onclick = ev => { if (ev.target === voile) voile.remove(); };
    document.body.append(voile);
    return voile;
  }

  function lancer(ctx) {
    const R = lire();
    const scene = ctx.scene;
    // ——— l'accueil : choisir son deck, son adversaire ———
    function accueil() {
      scene.innerHTML = ""; ctx.score.innerHTML = "";
      ctx.consigne("Choisis ton deck et ton adversaire");
      const z = h("div", "c3-page");
      const deck = R.decks[R.actif] || R.decks[0];
      const bd = h("div", "sp-bloc"); const td = h("div", "sp-tit"); td.append("Ton deck", h("small", "", `${deck.nom} · poids ${poidsDeck(deck.cartes)}/${POIDS_MAX}`)); bd.append(td);
      const rd = h("div", "c3-rang"); for (const c of deck.cartes) { const e = carte(c, { w: 62 }); e.onclick = () => fiche(c); rd.append(e); } bd.append(rd);
      const r2 = h("div", "rangee");
      const bch = h("button", "btn sec", R.decks.length > 1 ? "Changer de deck" : "Mes decks"); bch.onclick = pageDecks;
      r2.append(bch); bd.append(r2);
      if (!deckValide(deck)) bd.append(h("div", "c2-trop", "Ce deck n'est pas complet (5 cartes, poids 14 au plus)."));
      const ba = h("div", "sp-bloc"); ba.append(h("div", "sp-tit", "L'adversaire"));
      ADVERSAIRES.forEach((ad, k) => {
        const b = h("button", "c2-adv" + (R.adv === k ? " sel" : "")); const tt = h("b", "", ad.nom); tt.append(h("span", "c3-niv " + ad.niveau, NIVEAUX[ad.niveau]));
        b.append(tt, h("span", "", ad.desc)); b.onclick = () => { R.adv = k; sauver(R); accueil(); }; ba.append(b);
      });
      const ad = ADVERSAIRES[R.adv]; const md = h("div", "c3-rang petit"); for (const c of ad.deck) { const e = carte(c, { w: 44 }); e.onclick = () => fiche(c); md.append(e); } ba.append(md);
      z.append(bd, ba); scene.append(z);
      const go = h("button", "btn or c2-go", deckValide(deck) ? (ad.evenement ? "Jouer l'événement (4×4)" : "Jouer") : "Complète ton deck d'abord");
      go.disabled = !deckValide(deck); go.onclick = () => partie(deck, ad); scene.append(go);
    }
    // ——— mes decks ———
    function pageDecks() {
      scene.innerHTML = ""; ctx.consigne("Mes decks");
      const z = h("div", "c3-page");
      R.decks.forEach((d, k) => {
        const b = h("div", "sp-bloc c3-deck" + (R.actif === k ? " actif" : ""));
        const t = h("div", "sp-tit"); t.append(d.nom, h("small", "", `${d.cartes.length}/${TAILLE} cartes · poids ${poidsDeck(d.cartes)}/${POIDS_MAX}${R.actif === k ? " · choisi" : ""}`)); b.append(t);
        const r = h("div", "c3-rang"); for (const c of d.cartes) r.append(carte(c, { w: 52 })); b.append(r);
        const ac = h("div", "rangee");
        const b1 = h("button", "btn " + (R.actif === k ? "mauve" : "sec"), R.actif === k ? "Choisi" : "Jouer avec"); b1.onclick = () => { R.actif = k; sauver(R); accueil(); };
        const b2 = h("button", "btn sec", "Modifier"); b2.onclick = () => editeur(k);
        const b3 = h("button", "btn sec", "Supprimer"); b3.disabled = R.decks.length < 2; b3.onclick = () => { R.decks.splice(k, 1); R.actif = Math.min(R.actif, R.decks.length - 1); sauver(R); pageDecks(); };
        ac.append(b1, b2, b3); b.append(ac); z.append(b);
      });
      const nv = h("button", "btn mauve", "Nouveau deck"); nv.disabled = R.decks.length >= 6;
      nv.onclick = () => { R.decks.push({ nom: `Deck ${R.decks.length + 1}`, cartes: [] }); sauver(R); editeur(R.decks.length - 1); };
      z.append(nv); scene.append(z);
      const ret = h("button", "btn or c2-go", "Retour"); ret.onclick = accueil; scene.append(ret);
    }
    // ——— l'éditeur de deck ———
    let filtre = "tous";
    function editeur(k) {
      const d = R.decks[k];
      scene.innerHTML = ""; ctx.consigne("Crée ton deck : 5 cartes, poids 14 au plus");
      const z = h("div", "c3-page");
      const tete = h("div", "sp-bloc");
      const nom = h("input", "c3-nomdeck"); nom.value = d.nom; nom.maxLength = 24; nom.oninput = () => { d.nom = nom.value || "Sans nom"; sauver(R); };
      const pd = poidsDeck(d.cartes);
      const jauge = h("div", "c3-jauge"), i = h("i"); i.style.width = Math.min(100, pd / POIDS_MAX * 100) + "%"; if (pd > POIDS_MAX) jauge.classList.add("trop"); jauge.append(i, h("span", "", `poids ${pd}/${POIDS_MAX}`));
      tete.append(nom, jauge, h("div", "sp-leg", "Poids : sbire 1 · stade I 2 · II 3 · III 4. Touche une carte pour la voir, changer son stade ou sa variante."));
      const slots = h("div", "c3-slots");
      for (let s = 0; s < TAILLE; s++) {
        const c = d.cartes[s];
        if (c) { const e = carte(c, { w: 60, poids: true }); e.onclick = () => ficheDeck(k, s); slots.append(e); }
        else slots.append(h("div", "c3-vide", "+"));
      }
      tete.append(slots); z.append(tete);
      const bc = h("div", "sp-bloc"); bc.append(h("div", "sp-tit", "Ta collection"));
      const fl = h("div", "c3-filtres");
      for (const [kf, t] of [["tous", "Tous"], ["pouvoir", "✦ Pouvoir"], ...Object.keys(ADV).map(x => [x, TYPES[x].nom]), ["sbire", "Sbires"]]) { const b = h("button", "c3-chip" + (filtre === kf ? " on" : ""), t); b.onclick = () => { filtre = kf; editeur(k); }; fl.append(b); }
      bc.append(fl);
      const g = h("div", "c3-col");
      for (const f of [...HEROS, ...SBIRES]) {
        if (filtre === "pouvoir" && !POUV[f.id]) continue;
        if (filtre === "sbire" && !f.sbire) continue;
        if (ADV[filtre] && f.type !== filtre) continue;
        const dans = d.cartes.some(c => c.id === f.id);
        const c = { id: f.id, s: 1, v: varDefaut(f.id) };
        const e = carte(c, { w: 64, cls: dans ? "dans" : "" });
        e.onclick = () => fiche(c, dans ? [] : [{ nom: "Ajouter au deck", cls: "or", f: () => { if (d.cartes.length >= TAILLE) return alerte("Ton deck a déjà 5 cartes."); d.cartes.push({ ...c }); sauver(R); editeur(k); } }], dans ? h("p", "cf-sans", "Déjà dans ce deck.") : null);
        g.append(e);
      }
      bc.append(g); z.append(bc); scene.append(z);
      const fin = h("button", "btn or c2-go", "Terminé"); fin.onclick = pageDecks; scene.append(fin);
    }
    function alerte(t) { ctx.consigne(t, "lui"); }
    function ficheDeck(k, s) {
      const d = R.decks[k], c = d.cartes[s], f = FICHES[c.id];
      const reg = h("div", "cf-reg");
      if (!f.sbire && !unSeul(c.id)) { const r = h("div", "cf-ligne"); r.append(h("span", "", "Stade")); for (let x = 1; x <= 3; x++) { const b = h("button", "c3-chip" + (c.s === x ? " on" : ""), ["I", "II", "III"][x - 1]); b.onclick = () => { c.s = x; sauver(R); v.remove(); editeur(k); ficheDeck(k, s); }; r.append(b); } reg.append(r); }
      const r2 = h("div", "cf-ligne"); r2.append(h("span", "", "Variante")); for (const x of VARIANTES_ID) { const b = h("button", "c3-chip" + ((c.v || "base") === x ? " on" : ""), NOM_VAR[x]); b.onclick = () => { c.v = x; sauver(R); v.remove(); editeur(k); ficheDeck(k, s); }; r2.append(b); } reg.append(r2);
      reg.append(h("small", "", "Dans le jeu, tu choisis parmi les variantes que tu possèdes."));
      const v = fiche(c, [{ nom: "Retirer du deck", f: () => { d.cartes.splice(s, 1); sauver(R); editeur(k); } }], reg);
    }
    const varDefaut = id => { const k = hacher("var-" + id) % 10; return k < 5 ? "base" : k < 7 ? "or" : k < 8 ? "ombre" : k < 9 ? "elem" : "prisme"; };

    // ——— la partie ———
    function partie(deck, ad) {
      const ev4 = !!ad.evenement, n = ev4 ? 4 : 3, rng = rngDe(Date.now() % 1e9);
      const terres = {}, cs = melanger([...Array(n * n).keys()], rng), ty = melanger(Object.keys(ADV), rng);
      const nt = n === 4 ? 3 : 2;
      for (let k = 0; k < nt; k++) terres[cs[k]] = ty[k];
      const bloc = n === 4 ? [cs[nt]] : [];
      const mj = deck.cartes.map(c => ({ ...c })), ma = ad.deck.map(c => ({ ...c }));
      if (ev4) { mj.push(...RENFORTS.map(c => ({ ...c }))); ma.push(...RENFORTS.map(c => ({ ...c }))); }
      const st = { n, cases: Array(n * n).fill(null), terres, bloc, gel: {}, tour: 0, uid: 0, main: { j: mj, a: ma } };
      const premier = statsDe("carre-v1").p % 2 ? "a" : "j";
      let tour = premier, sel = null, occupe = false;
      scene.innerHTML = "";
      const zA = h("div", "c3-rang main-a"), cadre = h("div", "c3-plateau n" + n), grille = h("div", "c3-grille"), svg = document.createElementNS("http://www.w3.org/2000/svg", "svg"), zInfo = h("div", "c3-bande"), zJ = h("div", "c3-rang main-j");
      svg.setAttribute("viewBox", `0 0 ${n} ${n}`); svg.setAttribute("preserveAspectRatio", "none"); svg.classList.add("c3-traits");
      grille.style.gridTemplateColumns = `repeat(${n},1fr)`;
      cadre.innerHTML = `<svg class="c3-astrolabe" viewBox="0 0 100 100" aria-hidden="true"><circle cx="50" cy="50" r="47"/><circle cx="50" cy="50" r="38"/><path d="M50 1v98M1 50h98M15 15l70 70M85 15 15 85"/></svg>`;
      cadre.append(grille, svg);
      const scores = h("div", "c3-scores");
      scene.append(zA, cadre, scores, zInfo, zJ);
      function infoCarte(c) {
        zInfo.innerHTML = "";
        const p = POUV[c.id];
        if (p) { const g = h("span", "c3-g"); g.innerHTML = glyphe(p.g); zInfo.append(g); const t = h("div"); t.append(h("b", "", `${nomDe(c.id)} · ${p.nom}`), h("span", "", ` (${p.quand}) ${p.txt(stadeEff(c.id, c.s))}`)); zInfo.append(t); }
        else zInfo.append(h("div", "", `${nomDe(c.id)} : pas de pouvoir.`));
      }
      function message(t, id) {
        zInfo.innerHTML = "";
        if (id && POUV[id]) { const g = h("span", "c3-g"); g.innerHTML = glyphe(POUV[id].g); zInfo.append(g); }
        zInfo.append(h("div", "", t));
      }
      function rendre(anim = {}) {
        ctx.scoreJA(compte(st, "j"), compte(st, "a"));
        scores.innerHTML = `<span class="j">Toi ${compte(st, "j")}</span><span class="sep">${ad.nom} · ${NIVEAUX[ad.niveau]}</span><span class="a">${compte(st, "a")} Lui</span>`;
        zA.innerHTML = ""; st.main.a.forEach(c => { const e = carte(c, { w: n === 4 ? 36 : 44 }); e.onclick = () => fiche(c); zA.append(e); });
        grille.innerHTML = "";
        st.cases.forEach((c, i) => {
          const cell = h("button", "c3-case"); cell.dataset.i = i;
          if (c) {
            const v = valeurs(st, i), b = chiffresDe(c.id, c.s);
            const etat = h("div", "cc-etat");
            if (protegee(st, i, false)) etat.innerHTML = glyphe("rempart", "cc-bouclier");
            const e = carte(c, { camp: c.camp, ch: v, plus: v.map((x, k) => x > b[k]), moins: v.map((x, k) => x < b[k]), etat, cls: (anim.pose === i ? "pose" : "") + (anim.retour === i ? " retourne" : "") });
            e.onclick = () => infoCarte(c);
            cell.append(e);
          } else if (st.bloc.includes(i)) { cell.classList.add("gouffre"); cell.append(h("span", "", "gouffre")); }
          else {
            if (st.terres[i]) { const t = TYPES[st.terres[i]]; cell.classList.add("terre"); cell.style.setProperty("--t", t.c); cell.innerHTML = etoile("", 8, 0.3); cell.append(h("span", "", `${t.nom} +1`)); }
            const g = st.gel[i]; if (g && g.jusqua >= st.tour + 1) { cell.classList.add("gelee"); const s = h("span", "c3-gelee"); s.innerHTML = glyphe("gel"); cell.append(s); }
            if (sel != null && tour === "j" && casesPour(st, "j").includes(i)) cell.classList.add("libre");
            cell.onclick = () => jouerJ(i);
          }
          grille.append(cell);
        });
        zJ.innerHTML = "";
        st.main.j.forEach((c, k) => {
          const e = carte(c, { w: n === 4 ? 56 : 64, cls: sel === k ? "choisie" : "" });
          e.onclick = () => { if (tour !== "j" || occupe) return fiche(c); sel = sel === k ? null : k; rendre(); if (sel != null) { infoCarte(c); ctx.consigne("Touche une case libre"); } else ctx.consigne("À toi : choisis une carte"); };
          zJ.append(e);
        });
      }
      function trait(de, vers) {
        const [l1, c1, l2, c2] = [Math.floor(de / n), de % n, Math.floor(vers / n), vers % n];
        const ln = document.createElementNS("http://www.w3.org/2000/svg", "line");
        ln.setAttribute("x1", c1 + .5); ln.setAttribute("y1", l1 + .5); ln.setAttribute("x2", c2 + .5); ln.setAttribute("y2", l2 + .5);
        svg.append(ln); setTimeout(() => ln.remove(), 2600);
      }
      async function animer(camp, ev, i) {
        const flips = ev.filter(e => e.t === "flip" || e.t === "anubis");
        for (const f of flips.slice().reverse()) st.cases[f.vers].camp = f.prev;
        rendre({ pose: i });
        await dodo(420); if (!ctx.vivant()) return false;
        const cel = k => grille.children[k];
        let nf = 0;
        for (const e of ev) {
          if (e.t === "pouvoir") { message(`✦ ${nomDe(e.id)} — ${e.txt}`, e.id); flotSur(cel(e.i), POUV[e.id].nom, "mot", 0.15); await dodo(650); if (!ctx.vivant()) return false; }
          if (e.t === "protege") { flotSur(cel(e.i), e.id === "kitsune" ? "esquive !" : "Rempart !", "mot", 0.15); await dodo(300); }
          if (e.t === "flip" || e.t === "anubis") {
            if (e.t === "flip") { nf++; const A = cel(e.de).getBoundingClientRect(), B = cel(e.vers).getBoundingClientRect(); flotXY((A.left + A.right + B.left + B.right) / 4, (A.top + A.bottom + B.top + B.bottom) / 4, `${aff(e.a)} › ${aff(e.b)}`, "or"); trait(e.de, e.vers); }
            await dodo(240); if (!ctx.vivant()) return false;
            st.cases[e.vers].camp = e.camp;
            rendre({ retour: e.vers });
            if (e.chaine) flotSur(cel(e.vers), e.diag ? "en diagonale !" : "en chaîne !", "mot", 0.1);
            await dodo(340); if (!ctx.vivant()) return false;
          }
        }
        rendre();
        if (!ev.some(e => e.t === "pouvoir")) message(`${camp === "j" ? "Tu retournes" : "Il retourne"} ${nf} carte${nf > 1 ? "s" : ""}.`);
        return true;
      }
      async function jouerJ(i) {
        if (sel == null || tour !== "j" || occupe || !casesPour(st, "j").includes(i)) return;
        occupe = true; const k = sel; sel = null;
        const ev = jouerCoup(st, "j", [k, i]);
        if (!(await animer("j", ev, i))) return;
        occupe = false; suite("j");
      }
      async function tourIA() {
        tour = "a"; occupe = true; ctx.consigne("Il réfléchit…", "lui"); rendre();
        await dodo(650); if (!ctx.vivant()) return;
        const m = coupIA(st, rng, "a", ad.niveau);
        const ev = jouerCoup(st, "a", m);
        if (!(await animer("a", ev, m[1]))) return;
        occupe = false; suite("a");
      }
      function suite(qui) {
        if (plein(st) || (!st.main.j.length && !st.main.a.length)) {
          const j = compte(st, "j"), a = compte(st, "a");
          rendre(); ctx.consigne(j > a ? "Gagné !" : j < a ? "Perdu" : "Égalité", j >= a ? "" : "lui");
          return setTimeout(() => ctx.fin({ titre: j > a ? "Victoire" : j < a ? "Défaite" : "Égalité", texte: `${j} cartes à toi, ${a} à lui, contre ${ad.nom} (${NIVEAUX[ad.niveau]}).`, gagne: j > a }), 1000);
        }
        if (qui === "j") tourIA();
        else { tour = "j"; ctx.consigne("À toi : choisis une carte"); rendre(); }
      }
      rendre();
      message(ev4 ? "Événement : 4×4 avec un gouffre, et 3 renforts dans chaque main." : "Touche une carte pour voir son pouvoir ✦.");
      if (premier === "a") tourIA(); else ctx.consigne("À toi : choisis une carte");
      if (Jeu.tuto) (async () => {
        await ctx.etape({ texte: "Pose une carte à côté des siennes : le plus grand chiffre la retourne." });
        await ctx.etape({ texte: "L'icône en haut à droite, c'est son pouvoir. Touche la carte pour le lire." });
        await ctx.etape({ texte: "Plateau plein : le plus de cartes à ta couleur gagne." });
        ctx.tutoFini();
      })();
    }
    accueil();
  }
  enregistrer({ groupe: "carre", id: "carre-v1", num: "v2", nom: "Le Carré des astres", accroche: "3×3, tes decks, des pouvoirs, 3 niveaux d'ordinateur, un événement 4×4.", duree: "1 min", images: ["thor-2", "yeti-1", "bahamut-3"], fond: "linear-gradient(160deg,#2a2150,#171229)", lancer,
    moteur: { poser, jouerCoup, coups, coupIA, compte, cloner, chiffresDe, plein, ADVERSAIRES, DECK_DEPART, RENFORTS, poidsDeck, poids, POUV, ADV_TYPES: Object.keys(ADV) } });
})();
