"use strict";
// ═════════════════════════════ Le socle commun ═════════════════════════════
const $ = (s, r = document) => r.querySelector(s);
const h = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; };
const dodo = ms => new Promise(r => setTimeout(r, ms));
const autre = c => c === "j" ? "a" : "j";
const borne = (x, a, b) => Math.max(a, Math.min(b, x));
function rngDe(seed) { return function () { seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
function hacher(s) { let x = 2166136261; for (const c of s) { x ^= c.charCodeAt(0); x = Math.imul(x, 16777619); } return x >>> 0; }
function melanger(a, rng) { for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rng() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; }
function etoile(cls = "", branches = 8, creux = 0.3) {
  const pts = [];
  for (let i = 0; i < branches * 2; i++) {
    const r = i % 2 ? creux : 1, a = Math.PI * i / branches - Math.PI / 2;
    pts.push((50 + 48 * r * Math.cos(a)).toFixed(1) + "," + (50 + 48 * r * Math.sin(a)).toFixed(1));
  }
  return `<svg class="${cls}" viewBox="0 0 100 100" aria-hidden="true"><polygon points="${pts.join(" ")}"/></svg>`;
}

// Le ciel : des étoiles nettes, sans halo.
(function ciel() {
  const cv = $("#ciel"), cx = cv.getContext("2d");
  function peindre() {
    const r = window.devicePixelRatio || 1, W = innerWidth, H = innerHeight;
    cv.width = W * r; cv.height = H * r; cx.setTransform(r, 0, 0, r, 0, 0);
    const g = cx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, "#130f20"); g.addColorStop(1, "#0b0912");
    cx.fillStyle = g; cx.fillRect(0, 0, W, H);
    const rnd = rngDe(7);
    for (let i = 0; i < W * H / 2600; i++) {
      const x = rnd() * W, y = rnd() * H, k = rnd();
      cx.fillStyle = k > .92 ? "rgba(241,210,138,.9)" : `rgba(230,225,245,${.25 + k * .5})`;
      if (k > .965) { const s = 3 + rnd() * 2; cx.fillRect(x - s, y - .5, s * 2, 1); cx.fillRect(x - .5, y - s, 1, s * 2); cx.fillRect(x - 1, y - 1, 2, 2); }
      else cx.fillRect(x, y, k > .7 ? 1.5 : 1, k > .7 ? 1.5 : 1);
    }
  }
  peindre(); addEventListener("resize", peindre);
})();

// ─────────────────────────── Les héros (tirés de game_state.gd) ───────────────────────────
const TYPES = {
  feu: { nom: "Feu", c: "#e0743a" }, foudre: { nom: "Foudre", c: "#6f8fff" }, eau: { nom: "Eau", c: "#2f95ad" },
  glace: { nom: "Glace", c: "#8fc3de" }, nature: { nom: "Nature", c: "#6f9a4c" }, esprit: { nom: "Esprit", c: "#9a7de0" },
  aucun: { nom: "Sans type", c: "#8e8a82" },
};
const HEROS = /*HEROS*/[];
const SBIRES = [
  { id: "draugr", nom: "Draugr", type: "glace", role: "sbire", pays: "Scandinavie", sbire: true },
  { id: "farfadet", nom: "Farfadet", type: "nature", role: "sbire", pays: "France", sbire: true },
  { id: "oni", nom: "Oni", type: "feu", role: "sbire", pays: "Japon", sbire: true },
  { id: "ondine", nom: "Ondine", type: "eau", role: "sbire", pays: "Allemagne", sbire: true },
  { id: "follet", nom: "Feu follet", type: "esprit", role: "sbire", pays: "Irlande", sbire: true },
  { id: "raiju", nom: "Raijū", type: "foudre", role: "sbire", pays: "Japon", sbire: true },
];
const FICHES = {};
for (const x of [...HEROS, ...SBIRES]) FICHES[x.id] = x;
const fiche = id => FICHES[id];
const nomDe = id => FICHES[id].nom;
const typeDe = id => FICHES[id].type;
const HEROS_TYPES = HEROS.filter(x => x.type !== "aucun");
// La roue des types — provisoire (FEATURES ⑫ bis) : la même dans toutes les démos.
const ADV = { feu: ["glace", "nature"], glace: ["nature"], nature: ["eau"], eau: ["feu"], foudre: ["eau"], esprit: ["foudre"] };
const bat = (t1, t2) => (ADV[t1] || []).includes(t2);
const REGIONS = {
  Scandinavie: "le Nord", "Norvège": "le Nord", Chine: "l'Asie", Japon: "l'Asie", "Népal": "l'Asie", Philippines: "l'Asie",
  Arabie: "l'Orient", "Égypte": "l'Orient", Ghana: "l'Afrique", Irlande: "les Celtes", "Écosse": "les Celtes", France: "les Celtes",
  "Grèce": "la Méditerranée", Espagne: "la Méditerranée", Belgique: "l'Europe", "Tchéquie": "l'Europe", Russie: "l'Europe", Allemagne: "l'Europe",
  Mexique: "les Amériques", "États-Unis": "les Amériques", Canada: "les Amériques", "Amérique du Nord": "les Amériques", Australie: "l'Océanie",
};
const regionDe = id => REGIONS[FICHES[id].pays] || "le monde";

const ETOILE_DOS = etoile("", 8, 0.26);
const EMBLEME = etoile("", 4, 0.22);
function vignette(id, o = {}) {
  const f = FICHES[id], e = h("div", "carte");
  e.style.setProperty("--t", TYPES[f.type].c);
  if (f.sbire) { e.classList.add("sbire"); const em = h("div", "embleme"); em.innerHTML = EMBLEME; e.append(em); }
  else {
    const st = o.stade && f.stades >= o.stade ? o.stade : 0, im = h("img");
    im.src = st ? `img/${id}-${st}.jpg` : `img/${id}.jpg`; im.alt = ""; im.draggable = false;
    im.style.objectPosition = `50% ${(st && f.cads ? f.cads[st - 1] : f.cad) * 100}%`; e.append(im);
  }
  if (o.nom !== false) e.append(h("div", "nom", f.nom));
  if (o.force != null) e.append(h("div", "force", o.force));
  if (o.cout != null) e.append(h("div", "gem", o.cout));
  if (o.camp) e.classList.add(o.camp);
  return e;
}
function dos() { const e = h("div", "carte dos"); e.innerHTML = ETOILE_DOS; return e; }
const IMAGES = {};
function image(id) { if (!IMAGES[id]) { const im = new Image(); im.src = `img/${id}.jpg`; IMAGES[id] = im; } return IMAGES[id]; }

// ─────────────────────────── Effets ───────────────────────────
function rejouer(el, cls) { if (!el) return; el.classList.remove(cls); void el.offsetWidth; el.classList.add(cls); }
function flotXY(x, y, txt, sorte = "") { const f = h("div", "flot " + sorte, txt); f.style.left = x + "px"; f.style.top = y + "px"; $("#flots").append(f); setTimeout(() => f.remove(), 1000); }
function flotSur(el, txt, sorte = "", dy = 0.4) { if (!el) return; const r = el.getBoundingClientRect(); flotXY(r.left + r.width / 2, r.top + r.height * dy, txt, sorte); }

// ─────────────────────────── Le guide : il montre quoi toucher ───────────────────────────
const Guide = (() => {
  let conf = null, fin = null, raf = 0, saute = false;
  const racine = $("#guide");
  const murs = [0, 1, 2, 3].map(() => h("div", "mur"));
  const anneau = h("div", "anneau"), doigt = h("div", "doigt"), bulle = h("div", "bulle"), passer = h("button", "passer", "Passer le tuto");
  doigt.innerHTML = `<svg viewBox="0 0 44 44"><circle cx="22" cy="22" r="9" fill="#f1d28a"/><circle cx="22" cy="22" r="16" fill="none" stroke="#f1d28a" stroke-width="2" opacity=".6"/></svg>`;
  racine.append(...murs, anneau, doigt, bulle, passer);
  const sansCible = () => conf && !conf.cible;
  for (const m of murs) m.addEventListener("click", () => { if (sansCible()) finir(); else rejouer(bulle, "secoue"); });
  bulle.addEventListener("click", () => { if (sansCible()) finir(); });
  passer.addEventListener("click", () => { saute = true; finir(); });
  document.addEventListener("click", e => {
    if (!conf || !conf.cible || conf.signal) return;
    const c = conf.cible();
    if (c && c.contains(e.target)) setTimeout(finir, 0);
  }, true);
  function poser(el, x, y, w, hgt) { Object.assign(el.style, { left: x + "px", top: y + "px", width: Math.max(0, w) + "px", height: Math.max(0, hgt) + "px" }); }
  function boucle() {
    if (!conf) return;
    const W = innerWidth, H = innerHeight;
    const c = conf.cible ? conf.cible() : null;
    let r = c ? c.getBoundingClientRect() : null;
    if (r && (r.width === 0 || r.height === 0)) r = null;
    if (r) {
      const p = 6, x0 = r.left - p, y0 = r.top - p, x1 = r.right + p, y1 = r.bottom + p;
      poser(murs[0], 0, 0, W, y0); poser(murs[1], 0, y1, W, H - y1); poser(murs[2], 0, y0, x0, y1 - y0); poser(murs[3], x1, y0, W - x1, y1 - y0);
      anneau.hidden = false; poser(anneau, x0, y0, x1 - x0, y1 - y0);
      doigt.hidden = conf.doigt === false;
      const pt = conf.point ? conf.point() : { x: r.left + r.width / 2, y: r.top + r.height / 2 };
      doigt.style.left = (pt.x - 14) + "px"; doigt.style.top = (pt.y - 18) + "px";
      const auDessus = conf.bulle === "haut" || (conf.bulle !== "bas" && (r.top + r.bottom) / 2 > H * 0.52);
      if (auDessus) { bulle.style.top = ""; bulle.style.bottom = (H - y0 + 14) + "px"; }
      else { bulle.style.bottom = ""; bulle.style.top = (y1 + 14) + "px"; }
    } else {
      poser(murs[0], 0, 0, W, H); for (let i = 1; i < 4; i++) poser(murs[i], 0, 0, 0, 0);
      anneau.hidden = true; doigt.hidden = true;
      bulle.style.bottom = ""; bulle.style.top = (H * 0.38) + "px";
    }
    raf = requestAnimationFrame(boucle);
  }
  function finir() {
    if (!conf) return;
    conf = null; cancelAnimationFrame(raf); racine.hidden = true;
    const f = fin; fin = null; if (f) f();
  }
  return {
    // o : { cible: () => Element, texte, signal: "clé" (fini par Guide.signal), doigt: false | "tire", bulle: "haut" | "bas" }
    etape(o) {
      if (saute || !Jeu.tuto) return Promise.resolve();
      conf = o; racine.hidden = false;
      bulle.innerHTML = ""; bulle.append(h("span", "", o.texte));
      if (!o.cible) bulle.append(h("small", "", "Touche pour continuer"));
      doigt.className = "doigt" + (o.doigt === "tire" ? " tire" : "");
      cancelAnimationFrame(raf); boucle();
      return new Promise(r => { fin = r; });
    },
    signal(cle) { if (conf && conf.signal === cle) finir(); },
    cibleCourante() { return conf && conf.cible ? conf.cible() : null; },
    actif(cle) { return !!conf && (!cle || conf.signal === cle); },
    arreter() { saute = false; finir(); },
    get saute() { return saute; },
  };
})();

// ─────────────────────────── Les écrans ───────────────────────────
const Jeu = { demos: [], gen: 0, tuto: false, courante: null };
const CLE_STATS = "arene2-stats";
function lireStats() { try { return JSON.parse(localStorage.getItem(CLE_STATS)) || {}; } catch (e) { return {}; } }
function statsDe(id) { const s = lireStats()[id]; return s && typeof s.p === "number" ? s : { p: 0, v: 0 }; }
function noter(id, gagne) {
  const s = lireStats(), x = statsDe(id); x.p++; if (gagne) x.v++; s[id] = x;
  try { localStorage.setItem(CLE_STATS, JSON.stringify(s)); } catch (e) {}
  return x;
}
const libParties = x => `${x.p} partie${x.p > 1 ? "s" : ""}${x.p ? ` · ${x.v} gagnée${x.v > 1 ? "s" : ""}` : ""}`;
function tutoVu(id) { try { return localStorage.getItem("arene2-tuto-" + id) === "1"; } catch (e) { return false; } }
function marquerTuto(id) { try { localStorage.setItem("arene2-tuto-" + id, "1"); } catch (e) {} }

function enregistrer(demo) { Jeu.demos.push(demo); }

function montrerMenu() {
  Jeu.gen++; Guide.arreter(); $("#fin").hidden = true; Jeu.courante = null;
  try { localStorage.setItem("arene2-ecran", "menu"); } catch (e) {}
  const app = $("#app"); app.innerHTML = "";
  const m = h("div", "menu");
  const t = h("h1"); t.innerHTML = etoile("", 8, 0.28); t.append("Arène d'essai");
  m.append(t, h("p", "sous", "Chaque jeu t'apprend à jouer en quelques secondes. Joue, puis dis-moi lequel tu relances."));
  const GROUPES = [["carre", "Le combat retenu", "Le Carré des astres, prototype v2 : 3×3, tes decks, des pouvoirs visibles, trois niveaux d'ordinateur, et un événement 4×4.", false], ["strategie", "Stratégie avant le combat", "Onze façons de gagner par la préparation.", true], ["nouveaux", "Les huit concepts d'avant", "Évolutions, bluff, territoires, boss, reliques.", true], ["premiers", "Les premiers essais", "Les huit toutes premières démos.", true]];
  for (const [gid, gtitre, gsous, replie] of GROUPES) {
  const liste = Jeu.demos.filter(d => (d.groupe || "premiers") === gid);
  if (!liste.length) continue;
  let cible = m;
  if (replie) { const det = h("details", "groupe-replie"); det.append(h("summary", "", `${gtitre} (${liste.length})`)); m.append(det); cible = det; cible.append(h("p", "sous", gsous)); }
  else m.append(h("h2", "groupe", gtitre), h("p", "sous", gsous));
  const mm = m; { const m = cible;
  const g = h("div", "tuiles");
  for (const d of liste) {
    const b = h("button", "tuile");
    const vis = h("div", "vis");
    vis.style.background = d.fond || "#1d1732";
    vis.append(h("span", "num", d.num));
    d.images.slice(0, 3).forEach((id, i) => {
      const [hid, hst] = id.split("-"), im = h("img"); im.src = `img/${id}.jpg`; im.alt = "";
      im.style.left = (14 + i * 34) + "%"; im.style.top = (8 + (i % 2) * 10) + "px"; im.style.transform = `rotate(${(i - 1) * 8}deg)`;
      im.style.objectPosition = `50% ${(hst && FICHES[hid].cads ? FICHES[hid].cads[hst - 1] : FICHES[hid].cad) * 100}%`;
      vis.append(im);
    });
    const c = h("div", "corps");
    c.append(h("b", "", d.nom), h("span", "acc", d.accroche));
    const meta = h("div", "meta"); const s = statsDe(d.id);
    meta.append(h("span", "", d.duree), h("span", s.p ? "jouee" : "", libParties(s)));
    c.append(meta);
    b.append(vis, c);
    b.onclick = () => ouvrir(d);
    g.append(b);
  }
  m.append(g);
  } }
  m.append(h("p", "pied", "Les parties sont comptées dans ce navigateur."));
  app.append(m);
  scrollTo(0, 0);
}

function ouvrir(d) {
  Jeu.gen++; Guide.arreter(); $("#fin").hidden = true;
  const gen = Jeu.gen; Jeu.courante = d;
  Jeu.tuto = !tutoVu(d.id);
  try { localStorage.setItem("arene2-ecran", d.id); } catch (e) {}
  const app = $("#app"); app.innerHTML = "";
  const e = h("div", "ecran");
  const tete = h("div", "tete");
  const ret = h("button", "retour"); ret.setAttribute("aria-label", "Retour au menu");
  ret.innerHTML = `<svg viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7"/></svg>`;
  ret.onclick = montrerMenu;
  const score = h("div", "score");
  const rec = h("button", "retour"); rec.setAttribute("aria-label", "Recommencer"); rec.title = "Recommencer";
  rec.innerHTML = `<svg viewBox="0 0 24 24"><path d="M4 12a8 8 0 1 0 2.4-5.7M4 4v5h5"/></svg>`;
  rec.onclick = () => ouvrir(d);
  tete.append(ret, h("div", "nomdemo", d.nom), score, rec);
  const consigne = h("div", "consigne");
  const scene = h("div", "scene");
  e.append(tete, consigne, scene); app.append(e);
  scrollTo(0, 0);
  const ctx = {
    scene, score, gen,
    vivant: () => Jeu.gen === gen,
    // une étape du tuto : si on a quitté cette démo entre-temps, le tuto s'arrête là (la promesse ne se résout jamais)
    etape: o => Jeu.gen === gen ? Guide.etape(o).then(() => Jeu.gen === gen ? undefined : new Promise(() => {})) : new Promise(() => {}),
    consigne(txt, sorte = "") { consigne.textContent = txt; consigne.className = "consigne " + sorte; },
    scoreJA(j, a) { score.innerHTML = `<span class="j">${j}</span><span class="sep">contre</span><span class="a">${a}</span>`; },
    tutoFini() { if (Jeu.tuto) { Jeu.tuto = false; marquerTuto(d.id); } },
    fin(o) { if (Jeu.gen === gen) finPartie(d, o); },
    rejouer() { ouvrir(d); },
  };
  d.lancer(ctx);
}

function finPartie(d, { titre, texte, gagne }) {
  const x = noter(d.id, gagne);
  const fin = $("#fin"); fin.innerHTML = "";
  const b = h("div", "fin-boite"); b.setAttribute("role", "dialog");
  b.insertAdjacentHTML("beforeend", etoile("", 8, gagne ? 0.28 : 0.55));
  b.append(h("h2", "", titre), h("p", "", texte), h("p", "compte", `${d.nom} : ${libParties(x)}`));
  const b1 = h("button", "btn or", "Rejouer"); b1.onclick = () => { fin.hidden = true; ouvrir(d); };
  const b2 = h("button", "btn sec", "Voir le plateau"); b2.onclick = () => { fin.hidden = true; };
  const b3 = h("button", "btn sec", "Essayer un autre jeu"); b3.onclick = montrerMenu;
  b.append(b1, b2, b3); fin.append(b); fin.hidden = false; b1.focus();
}
