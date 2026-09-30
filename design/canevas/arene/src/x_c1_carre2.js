// ═════════════════════════════ C1 · LE CARRÉ DES ASTRES — prototype v1 ═════════════════════════════
// Décidé par Maxim le 26/09/2026 : le Carré est le combat du jeu. La v1 :
// · plateau 4×4 (ou 3×3 pour comparer) · deck de 10 cartes, mains visibles, pas de pioche
// · les chaînes de retournements · les terres (+1 au type) — les types ne servent qu'aux terres
// · un pouvoir pour 10 héros · le stade monte les chiffres (+3 au II, +3 au III) et renforce le pouvoir
// · le poids du deck : sbire 1, stade I 2, II 3, III 4 (un héros à une seule forme pèse 4) ; 28 au plus.
(function () {
  const OPP = [2, 3, 0, 1];                       // côté d'en face : haut↔bas, droite↔gauche
  const MODELES = { frappeur: [9, 6, 4, 3], garde: [6, 6, 6, 5], appui: [8, 5, 5, 4], sbire: [5, 4, 3, 2] };
  const POIDS_MAX = 28, TAILLE_DECK = 10;
  const POUV = {
    thor: { nom: "Foudre", txt: s => `À la pose : ses côtés qui touchent une carte adverse +${s === 3 ? 3 : 2}.` },
    kitsune: { nom: "Esquive", txt: s => s === 3 ? "Jamais retournée par une chaîne, ni au tour qui suit sa pose." : "Jamais retournée par une chaîne." },
    golem: { nom: "Rempart", txt: s => s === 3 ? "Impossible à retourner pendant les 2 tours adverses qui suivent sa pose." : "Impossible à retourner au tour adverse qui suit sa pose." },
    bahamut: { nom: "Marée", txt: s => `Tant qu'il est posé : tes cartes qui le touchent +${s === 3 ? 2 : 1} partout.` },
    yeti: { nom: "Gel", txt: s => s === 3 ? "Les cartes adverses autour de lui (diagonales comprises) ne retournent plus rien." : "Les cartes adverses qui le touchent ne retournent plus rien." },
    loki: { nom: "Métamorphose", txt: s => s === 3 ? "À la pose : garde, côté par côté, le plus fort entre ses chiffres et ceux de la carte voisine la plus forte." : "À la pose : prend les chiffres de la carte voisine la plus forte." },
    anubis: { nom: "Pesée des âmes", txt: s => `Quand il est retourné : tu reprends ${s === 3 ? "les 2 cartes adverses voisines les plus faibles" : "la carte adverse voisine la plus faible"} (une fois).` },
    fenrir: { nom: "Faim", txt: () => "Chaque carte qu'il retourne lui donne +1 partout." },
    cerbere: { nom: "Trois têtes", txt: s => `Attaque aussi en diagonale, avec ${s === 3 ? "le plus grand" : "le plus petit"} de ses deux chiffres de ce coin.` },
    babayaga: { nom: "Malédiction", txt: s => `À la pose : les cartes adverses qui la touchent −${s === 3 ? 2 : 1} partout.` },
  };
  const unSeul = id => !FICHES[id].sbire && FICHES[id].stades === 1;
  const stadeEff = (id, s) => FICHES[id].sbire ? 1 : unSeul(id) ? 3 : s;
  const poids = (id, s) => FICHES[id].sbire ? 1 : unSeul(id) ? 4 : s + 1;
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
    if (!POUV[id]) r[r.indexOf(Math.max(...r))]++;          // sans pouvoir : un point de plus
    const idx = [0, 1, 2, 3];
    if (st >= 2) for (const i of idx.slice().sort((x, y) => r[y] - r[x] || x - y).slice(0, 3)) r[i]++;
    if (st >= 3) for (const i of idx.slice().sort((x, y) => r[x] - r[y] || x - y).slice(0, 3)) r[i]++;
    return r.map(v => Math.min(10, v));
  }
  const aff = v => v >= 10 ? "A" : v;

  // ——— les règles, sur un plateau n×n ———
  function orth(n, i) { const l = Math.floor(i / n), c = i % n, v = []; if (l > 0) v.push([i - n, 0]); if (c < n - 1) v.push([i + 1, 1]); if (l < n - 1) v.push([i + n, 2]); if (c > 0) v.push([i - 1, 3]); return v; }
  function diag(n, i) { const l = Math.floor(i / n), c = i % n, v = []; for (const [dl, dc, sv, sh] of [[-1, 1, 0, 1], [1, 1, 2, 1], [1, -1, 2, 3], [-1, -1, 0, 3]]) { const L = l + dl, C = c + dc; if (L >= 0 && C >= 0 && L < n && C < n) v.push([L * n + C, sv, sh]); } return v; }
  function valeurs(st, i) {
    const c = st.cases[i], v = c.ch.slice();
    for (const [k] of orth(st.n, i)) { const b = st.cases[k]; if (b && b.camp === c.camp && b.id === "bahamut") for (let s = 0; s < 4; s++) v[s] += b.s === 3 ? 2 : 1; }
    return v.map(x => Math.min(10, x));
  }
  function gelee(st, i) {
    const c = st.cases[i];
    for (const [k] of orth(st.n, i)) { const y = st.cases[k]; if (y && y.camp !== c.camp && y.id === "yeti") return true; }
    for (const [k] of diag(st.n, i)) { const y = st.cases[k]; if (y && y.camp !== c.camp && y.id === "yeti" && y.s === 3) return true; }
    return false;
  }
  function protegee(st, i, parChaine) {
    const c = st.cases[i];
    if (c.id === "kitsune" && (parChaine || (c.s === 3 && st.tour <= c.pose + 1))) return true;
    if (c.id === "golem" && st.tour <= c.pose + (c.s === 3 ? 3 : 1)) return true;
    return false;
  }
  // Pose une carte et joue tout : pouvoirs, retournements en chaîne. Renvoie les événements, dans l'ordre.
  function poser(st, camp, carte, i) {
    st.tour++;
    const c = { uid: ++st.uid, id: carte.id, s: stadeEff(carte.id, carte.s), camp, ch: chiffresDe(carte.id, carte.s), pose: st.tour, terre: false };
    if (st.terres[i] && st.terres[i] === typeDe(c.id)) { c.ch = c.ch.map(x => Math.min(10, x + 1)); c.terre = true; }
    st.cases[i] = c;
    const ev = [];
    const ennemisOrth = () => orth(st.n, i).filter(([k]) => st.cases[k] && st.cases[k].camp !== camp);
    if (c.id === "thor") { const k = c.s === 3 ? 3 : 2; const e = ennemisOrth(); for (const [, s] of e) c.ch[s] = Math.min(10, c.ch[s] + k); if (e.length) ev.push({ t: "pouvoir", i, txt: `Foudre +${k}` }); }
    if (c.id === "loki") {
      const v = orth(st.n, i).filter(([k]) => st.cases[k]).map(([k]) => valeurs(st, k)).sort((a, b) => b.reduce((x, y) => x + y) - a.reduce((x, y) => x + y))[0];
      if (v) { c.ch = c.s === 3 ? c.ch.map((x, s) => Math.max(x, v[s])) : v.slice(); ev.push({ t: "pouvoir", i, txt: "Métamorphose" }); }
    }
    if (c.id === "babayaga") { const k = c.s === 3 ? 2 : 1; const e = ennemisOrth(); for (const [n] of e) st.cases[n].ch = st.cases[n].ch.map(x => Math.max(1, x - k)); if (e.length) ev.push({ t: "pouvoir", i, txt: `Malédiction −${k}`, cibles: e.map(x => x[0]) }); }
    const file = [i];
    while (file.length) {
      const k = file.shift(), a = st.cases[k], campA = a.camp;
      if (gelee(st, k)) { if (k === i || orth(st.n, k).some(([m]) => st.cases[m] && st.cases[m].camp !== campA)) ev.push({ t: "gel", i: k }); continue; }
      const cibles = orth(st.n, k).map(([m, s]) => ({ m, va: () => valeurs(st, k)[s], vd: () => valeurs(st, m)[OPP[s]] }));
      if (a.id === "cerbere") for (const [m, sv, sh] of diag(st.n, k)) cibles.push({ m, diag: true, va: () => { const v = valeurs(st, k); return a.s === 3 ? Math.max(v[sv], v[sh]) : Math.min(v[sv], v[sh]); }, vd: () => { const v = valeurs(st, m); return Math.min(v[OPP[sv]], v[OPP[sh]]); } });
      for (const cb of cibles) {
        if (st.cases[k].camp !== campA) break;
        const d = st.cases[cb.m]; if (!d || d.camp === campA) continue;
        const x = cb.va(), y = cb.vd();
        if (x > y && !protegee(st, cb.m, k !== i)) {
          const ancien = d.camp; d.camp = campA;
          ev.push({ t: "flip", de: k, vers: cb.m, a: x, b: y, chaine: k !== i, diag: !!cb.diag, prev: ancien, camp: campA });
          file.push(cb.m);
          if (a.id === "fenrir") { a.ch = a.ch.map(v => Math.min(10, v + 1)); ev.push({ t: "pouvoir", i: k, txt: "Faim +1" }); }
          if (d.id === "anubis" && !d.useAnubis) {
            d.useAnubis = true;
            const pris = orth(st.n, cb.m).map(([m]) => m).filter(m => st.cases[m] && st.cases[m].camp === campA).sort((p, q) => valeurs(st, p).reduce((u, w) => u + w) - valeurs(st, q).reduce((u, w) => u + w)).slice(0, d.s === 3 ? 2 : 1);
            for (const m of pris) { st.cases[m].camp = ancien; ev.push({ t: "anubis", de: cb.m, vers: m, prev: campA }); }
          }
        } else if (x > y) ev.push({ t: "protege", i: cb.m });
      }
    }
    return ev;
  }
  const compte = (st, camp) => st.cases.filter(c => c && c.camp === camp).length;
  const cloner = st => ({ ...st, cases: st.cases.map(c => c && { ...c, ch: c.ch.slice() }), main: { j: st.main.j.slice(), a: st.main.a.slice() } });
  function coups(st, camp) { const libres = st.cases.map((c, i) => c || (st.bloc && st.bloc.includes(i)) ? -1 : i).filter(i => i >= 0), vus = new Set(), l = []; st.main[camp].forEach((c, h) => { const cle = c.id + c.s; if (vus.has(cle)) return; vus.add(cle); for (const i of libres) l.push([h, i]); }); return l; }
  function jouerCoup(st, camp, [h, i]) { const c = st.main[camp][h]; st.main[camp] = st.main[camp].filter((_, k) => k !== h); return poser(st, camp, c, i); }
  function coupIA(st, rng, moi = "a") {
    const lui = autre(moi);
    const cand = coups(st, moi).map(m => { const s = cloner(st); jouerCoup(s, moi, m); return { m, s, v: compte(s, moi) - compte(s, lui) }; }).sort((a, b) => b.v - a.v).slice(0, 10);
    let best = null;
    for (const c of cand) {
      let pire = c.v;
      if (c.s.cases.some((x, q) => !x && !(c.s.bloc && c.s.bloc.includes(q))) && c.s.main[lui].length) for (const r of coups(c.s, lui)) { const s2 = cloner(c.s); jouerCoup(s2, lui, r); pire = Math.min(pire, compte(s2, moi) - compte(s2, lui)); }
      const v = pire + rng() * 0.5;
      if (!best || v > best.v) best = { v, m: c.m };
    }
    return best.m;
  }

  // ——— adversaires et deck ———
  const ADVERSAIRES = [
    { nom: "Les gardiens du Nord", desc: "Thor et le Yéti, qui gèle tes cartes autour de lui.", deck: [["thor", 3], ["fenrir", 2], ["yeti", 2], ["loki", 1], ["golem", 1], ["wendigo", 1], ["troll", 1], ["draugr", 1], ["raiju", 1], ["nian", 1]] },
    { nom: "Les eaux dormantes", desc: "Bahamut renforce ses voisins, Kitsune esquive les chaînes.", deck: [["bahamut", 3], ["kelpie", 2], ["banshee", 2], ["kitsune", 2], ["cuelebre", 2], ["bunyip", 1], ["anubis", 2], ["mothman", 1], ["ondine", 1], ["follet", 1]] },
    { nom: "Les Enfers", desc: "Cerbère frappe en diagonale, Baba Yaga maudit, Anubis reprend ce qu'on lui vole.", deck: [["cerbere", 3], ["babayaga", 3], ["anubis", 2], ["minotaure", 2], ["ifrit", 1], ["doudou", 2], ["fenrir", 1], ["golem", 2], ["oni", 1], ["follet", 1]] },
  ].map(a => ({ ...a, deck: a.deck.map(([id, s]) => ({ id, s })) }));
  const DECK_DEPART = [["thor", 2], ["golem", 1], ["bahamut", 2], ["yeti", 1], ["kitsune", 2], ["loki", 1], ["anubis", 1], ["fenrir", 1], ["draugr", 1], ["farfadet", 1]].map(([id, s]) => ({ id, s }));
  const poidsDeck = d => d.reduce((x, c) => x + poids(c.id, c.s), 0);
  const CLE = "carre-v1";
  function lireReglages() { try { const r = JSON.parse(localStorage.getItem(CLE)); if (r && r.deck && r.deck.length) return r; } catch (e) {} return { deck: DECK_DEPART.map(c => ({ ...c })), n: 4, adv: 0 }; }
  function sauver(r) { try { localStorage.setItem(CLE, JSON.stringify(r)); } catch (e) {} }

  // ——— une carte à l'écran ———
  function carteEl(id, s, o = {}) {
    const st = stadeEff(id, s), e = vignette(id, { stade: FICHES[id].sbire ? 0 : Math.min(st, FICHES[id].stades), nom: o.nom !== false });
    e.classList.add("c2-carte");
    const ch = o.ch || chiffresDe(id, s);
    ["h", "d", "b", "g"].forEach((k, i) => e.append(h("span", "cr-n cr-" + k + (o.plus && o.plus[i] ? " plus" : "") + (o.moins && o.moins[i] ? " moins" : ""), aff(ch[i]))));
    if (POUV[id]) e.append(h("span", "c2-pouv", "✦"));
    if (!FICHES[id].sbire && !unSeul(id) && o.stade !== false) e.append(h("span", "c2-st", ["I", "II", "III"][st - 1]));
    if (o.poids) e.append(h("span", "c2-poids", poids(id, s)));
    return e;
  }
  const txtCarte = (id, s) => { const st = stadeEff(id, s), p = POUV[id]; return `${nomDe(id)}${FICHES[id].sbire ? " (sbire)" : ` · ${(FICHES[id].formes || [])[Math.min(st, FICHES[id].stades) - 1] || ""}`} · poids ${poids(id, s)}${p ? ` — ✦ ${p.nom} : ${p.txt(st)}` : " — pas de pouvoir"}`; };

  function lancer(ctx) {
    const R = lireReglages();
    let ecran = "prep", infoId = null;
    function prep() {
      ctx.scene.innerHTML = ""; ctx.score.innerHTML = "";
      ctx.consigne("Prépare ton deck, puis joue");
      const z = h("div", "c2-prep");
      // plateau
      const t = h("div", "sp-bloc"); t.append(h("div", "sp-tit", "Le plateau"));
      const r1 = h("div", "rangee"); for (const n of [3, 4]) { const b = h("button", "btn " + (R.n === n ? "mauve" : "sec"), `${n} × ${n}`); b.onclick = () => { R.n = n; sauver(R); prep(); }; r1.append(b); }
      t.append(r1, h("div", "sp-leg", R.n === 4 ? "16 cases dont 1 gouffre : 8 et 7 cartes posées, 3 terres." : "9 cases : 5 et 4 cartes posées, 2 terres."));
      // adversaire
      const a = h("div", "sp-bloc"); a.append(h("div", "sp-tit", "L'adversaire"));
      ADVERSAIRES.forEach((ad, k) => {
        const b = h("button", "c2-adv" + (R.adv === k ? " sel" : "")); b.append(h("b", "", ad.nom), h("span", "", `${ad.desc} · poids ${poidsDeck(ad.deck)}`));
        b.onclick = () => { R.adv = k; sauver(R); prep(); }; a.append(b);
      });
      const md = h("div", "c2-rang petit"); for (const c of ADVERSAIRES[R.adv].deck) md.append(carteEl(c.id, c.s, { nom: false })); a.append(md);
      // deck
      const pd = poidsDeck(R.deck), ok = R.deck.length === TAILLE_DECK && pd <= POIDS_MAX;
      const d = h("div", "sp-bloc"); const tt = h("div", "sp-tit"); tt.append(`Ton deck · ${R.deck.length}/${TAILLE_DECK}`, h("span", pd > POIDS_MAX ? "c2-trop" : "c2-ok", `poids ${pd}/${POIDS_MAX}`)); d.append(tt);
      d.append(h("div", "sp-leg", "Touche une carte de ton deck pour changer son stade (I → II → III). Poids : sbire 1, stade I 2, II 3, III 4."));
      const rd = h("div", "c2-rang");
      R.deck.forEach((c, k) => { const e = carteEl(c.id, c.s, { nom: false, poids: true }); e.onclick = () => { infoId = null; if (FICHES[c.id].sbire || unSeul(c.id)) return; c.s = c.s % 3 + 1; sauver(R); const y = ctx.scene.querySelector(".c2-prep").scrollTop; prep(); ctx.scene.querySelector(".c2-prep").scrollTop = y; }; rd.append(e); });
      d.append(rd);
      const info = h("div", "sp-leg c2-info", infoId ? txtCarte(infoId, 1) : "Touche une carte de la collection pour l'ajouter ou la retirer.");
      const col = h("div", "c2-col");
      for (const f of [...HEROS, ...SBIRES]) {
        const dans = R.deck.findIndex(c => c.id === f.id);
        const e = carteEl(f.id, 1, { nom: true, stade: false }); if (dans >= 0) e.classList.add("choisie");
        e.onclick = () => { infoId = f.id; if (dans >= 0) R.deck.splice(dans, 1); else if (R.deck.length < TAILLE_DECK) R.deck.push({ id: f.id, s: 1 }); else { info.textContent = "Ton deck a déjà 10 cartes : retires-en une."; return; } sauver(R); const y = ctx.scene.querySelector(".c2-prep").scrollTop; prep(); ctx.scene.querySelector(".c2-prep").scrollTop = y; };
        col.append(e);
      }
      d.append(info, col);
      z.append(t, a, d);
      ctx.scene.append(z);
      const go = h("button", "btn or c2-go", ok ? "Jouer" : R.deck.length !== TAILLE_DECK ? `Il faut 10 cartes (${R.deck.length})` : `Deck trop lourd (${pd}/${POIDS_MAX})`);
      go.disabled = !ok; go.onclick = partie; ctx.scene.append(go);
    }
    function partie() {
      ecran = "partie";
      const n = R.n, rng = rngDe(Date.now() % 1e9), ad = ADVERSAIRES[R.adv];
      const terres = {}, cs = melanger([...Array(n * n).keys()], rng), ty = melanger(Object.keys(ADV), rng);
      const nt = n === 4 ? 3 : 2;
      for (let k = 0; k < nt; k++) terres[cs[k]] = ty[k];
      // 4×4 : un gouffre, pour un nombre impair de cases (mesuré au banc : 1er joueur 52 %, sinon 20 %)
      const bloc = n === 4 ? [cs[nt]] : [];
      const st = { n, cases: Array(n * n).fill(null), terres, bloc, tour: 0, uid: 0, main: { j: R.deck.map(c => ({ ...c })), a: ad.deck.map(c => ({ ...c })) } };
      const premier = statsDe("carre-v1").p % 2 ? "a" : "j";
      let tour = premier, sel = null, occupe = false, dernier = "";
      ctx.scene.innerHTML = "";
      const zA = h("div", "c2-rang main-a"), plateau = h("div", "cr-plateau c2-plateau"), zInfo = h("div", "c2-bande"), zJ = h("div", "c2-rang main-j");
      plateau.style.gridTemplateColumns = `repeat(${n},1fr)`; if (n === 4) plateau.classList.add("n4");
      ctx.scene.append(zA, plateau, zInfo, zJ);
      function rendre(anim = {}) {
        ctx.scoreJA(compte(st, "j"), compte(st, "a"));
        zA.innerHTML = ""; st.main.a.forEach(c => zA.append(carteEl(c.id, c.s, { nom: false })));
        plateau.innerHTML = "";
        st.cases.forEach((c, i) => {
          const cell = h("button", "cr-case"); cell.dataset.i = i;
          if (c) {
            const v = valeurs(st, i), b = chiffresDe(c.id, c.s);
            const e = carteEl(c.id, c.s, { nom: false, ch: v, plus: v.map((x, k) => x > b[k]), moins: v.map((x, k) => x < b[k]) });
            e.classList.add("c" + c.camp);
            if (gelee(st, i)) e.classList.add("c2-gele");
            if (protegee(st, i, false)) e.classList.add("c2-prot");
            if (anim.pose === i) e.classList.add("cr-pose");
            if (anim.retour === i) e.classList.add("retourne");
            e.onclick = () => { zInfo.textContent = txtCarte(c.id, c.s); };
            cell.append(e);
          } else if (st.bloc.includes(i)) { cell.classList.add("c2-gouffre"); cell.append(h("span", "", "gouffre")); }
          else {
            if (st.terres[i]) { const t = TYPES[st.terres[i]]; cell.classList.add("cr-terre"); cell.style.setProperty("--t", t.c); cell.innerHTML = etoile("", 8, 0.3); cell.append(h("span", "", `${t.nom} +1`)); }
            if (sel != null && tour === "j") cell.classList.add("cr-libre");
            cell.onclick = () => jouerJ(i);
          }
          plateau.append(cell);
        });
        zJ.innerHTML = "";
        st.main.j.forEach((c, k) => {
          const e = carteEl(c.id, c.s, { nom: true }); e.dataset.k = k;
          if (sel === k) e.classList.add("choisie");
          e.onclick = () => { if (tour !== "j" || occupe) return; sel = sel === k ? null : k; zInfo.textContent = sel != null ? txtCarte(c.id, c.s) : dernier; rendre(); ctx.consigne(sel != null ? "Touche une case vide" : "À toi : choisis une carte"); };
          zJ.append(e);
        });
        if (sel == null && !anim.garde) zInfo.textContent = dernier || "Touche une carte pour lire son pouvoir ✦.";
      }
      async function animer(camp, ev, i) {
        // on montre la pose, puis chaque retournement l'un après l'autre
        const flips = ev.filter(e => e.t === "flip" || e.t === "anubis");
        for (const f of flips.slice().reverse()) st.cases[f.vers].camp = f.prev;
        rendre({ pose: i, garde: true });
        await dodo(380); if (!ctx.vivant()) return false;
        const celluleCentre = k => plateau.children[k];
        for (const e of ev) {
          if (e.t === "pouvoir") flotSur(celluleCentre(e.i), e.txt, "mot", 0.2);
          if (e.t === "gel") flotSur(celluleCentre(e.i), "gelée", "mot", 0.2);
          if (e.t === "protege") flotSur(celluleCentre(e.i), "protégée", "mot", 0.2);
          if (e.t === "flip" || e.t === "anubis") {
            if (e.t === "flip") { const A = celluleCentre(e.de).getBoundingClientRect(), B = celluleCentre(e.vers).getBoundingClientRect(); flotXY((A.left + A.right + B.left + B.right) / 4, (A.top + A.bottom + B.top + B.bottom) / 4, `${aff(e.a)} › ${aff(e.b)}`, "or"); }
            await dodo(220); if (!ctx.vivant()) return false;
            st.cases[e.vers].camp = e.t === "flip" ? e.camp : (e.prev === "j" ? "a" : "j");
            rendre({ retour: e.vers, garde: true });
            if (e.t === "anubis") flotSur(celluleCentre(e.vers), "reprise par Anubis", "mot", 0.1);
            else if (e.chaine) flotSur(celluleCentre(e.vers), e.diag ? "en diagonale !" : "en chaîne !", "mot", 0.1);
            await dodo(330); if (!ctx.vivant()) return false;
          } else await dodo(160);
        }
        const nf = ev.filter(e => e.t === "flip").length;
        dernier = `${camp === "j" ? "Tu retournes" : "Il retourne"} ${nf} carte${nf > 1 ? "s" : ""}.`;
        rendre(); return true;
      }
      async function jouerJ(i) {
        if (sel == null || tour !== "j" || occupe || st.cases[i]) return;
        occupe = true; const k = sel; sel = null;
        const ev = jouerCoup(st, "j", [k, i]);
        if (!(await animer("j", ev, i))) return;
        occupe = false; suite("j");
      }
      async function tourIA() {
        tour = "a"; occupe = true; ctx.consigne("Il réfléchit…", "lui"); rendre();
        await dodo(500); if (!ctx.vivant()) return;
        const m = coupIA(st, rng);
        const ev = jouerCoup(st, "a", m);
        if (!(await animer("a", ev, m[1]))) return;
        occupe = false; suite("a");
      }
      // qui vient de jouer : "j" ou "a"
      function suite(qui) {
        const plein = st.cases.every((c, i) => c || st.bloc.includes(i)) || (!st.main.j.length && !st.main.a.length);
        if (plein) {
          const j = compte(st, "j"), a = compte(st, "a");
          rendre(); ctx.consigne(j > a ? "Gagné !" : j < a ? "Perdu" : "Égalité", j >= a ? "" : "lui");
          return setTimeout(() => ctx.fin({ titre: j > a ? "Victoire" : j < a ? "Défaite" : "Égalité", texte: `${j} cartes à toi, ${a} à lui, sur un plateau ${n}×${n} contre ${ad.nom}.`, gagne: j > a }), 900);
        }
        if (qui === "j") tourIA();
        else { tour = "j"; ctx.consigne("À toi : choisis une carte"); rendre(); }
      }
      // qui commence
      rendre();
      if (premier === "a") tourIA();
      else ctx.consigne("À toi : choisis une carte");
      if (Jeu.tuto) (async () => {
        await ctx.etape({ texte: "Pose une carte à côté des siennes : le plus grand chiffre la retourne." });
        await ctx.etape({ texte: "Les ✦ ont un pouvoir : touche une carte pour le lire." });
        await ctx.etape({ texte: "Plateau plein : le plus de cartes à ta couleur gagne." });
        ctx.tutoFini();
      })();
    }
    // le jeu s'ouvre sur la préparation ; « Rejouer » y revient avec le même deck
    prep();
  }
  enregistrer({ groupe: "carre", id: "carre-v1", num: "v1", nom: "Le Carré des astres", accroche: "4×4, ton deck de 10, des pouvoirs, des terres. Le combat retenu.", duree: "3 min", images: ["thor-2", "yeti-1", "bahamut-3"], fond: "linear-gradient(160deg,#2a2150,#171229)", lancer, moteur: { plein: st => st.cases.every((c, i) => c || (st.bloc && st.bloc.includes(i))), poser, jouerCoup, coups, coupIA, compte, cloner, chiffresDe, ADVERSAIRES, DECK_DEPART, poidsDeck, ADV_TYPES: Object.keys(ADV) } });
})();
