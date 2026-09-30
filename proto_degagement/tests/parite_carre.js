// Le banc de parité du Carré (FEATURES ②, 27/09) — côté WEB.
//
// Joue N parties ordinateur contre ordinateur avec le moteur du prototype web (lu tel quel dans
// design/canevas/arene/src/c2_carre3.js, jamais recopié), et écrit chaque coup, chaque événement et
// l'état final dans tests/parite_carre.json. tests/test_carre.gd rejoue les mêmes parties avec
// carre/moteur_carre.gd et compare coup par coup.
//
//   node proto_degagement/tests/parite_carre.js [nombre de parties]
"use strict";
const fs = require("fs"), path = require("path");
const ARENE = path.join(__dirname, "..", "..", "design", "canevas", "arene", "src");
const core = fs.readFileSync(path.join(ARENE, "core.js"), "utf8");
const c2 = fs.readFileSync(path.join(ARENE, "c2_carre3.js"), "utf8");

// Du socle web : le hasard, le mélange, les sbires — pris dans le fichier, pas recopiés.
function extraire(debut, fin) {
  const a = core.indexOf(debut);
  if (a < 0) throw new Error("introuvable dans core.js : " + debut);
  const b = fin ? core.indexOf(fin, a) + fin.length : core.indexOf("\n", a);
  return core.slice(a, b);
}
const socle = [
  extraire("const autre ="), extraire("function rngDe("), extraire("function hacher("), extraire("function melanger("),
  extraire("const SBIRES = [", "];"),
].join("\n");
const HEROS = JSON.parse(fs.readFileSync(path.join(ARENE, "heros.json"), "utf8"));
const debut = c2.indexOf("(function () {") + "(function () {".length;
const fin = c2.indexOf("// ═══ La carte, avec ses variantes ═══");
const moteurSrc = c2.slice(debut, fin);
const fabrique = new Function("HEROS", socle + `
  const FICHES = {};
  for (const x of [...HEROS, ...SBIRES]) FICHES[x.id] = x;
  const typeDe = id => FICHES[id].type;
  ` + moteurSrc + `
  return { poser, jouerCoup, coups, coupIA, compte, plein, chiffresDe, POUV, FICHES, rngDe, melanger, hacher, autre };`);
const M = fabrique(HEROS);

const N_PARTIES = parseInt(process.argv[2] || "400", 10);
const ids = Object.keys(M.FICHES);
const avecPouvoir = Object.keys(M.POUV);
const NIV = ["apprenti", "aventurier", "maitre"];
const g = M.rngDe(20260927);
const pioche = a => a[Math.floor(g() * a.length)];

function carteAuHasard() {
  const id = g() < 0.5 ? pioche(avecPouvoir) : pioche(ids);
  const f = M.FICHES[id];
  const s = f.sbire ? 1 : 1 + Math.floor(g() * f.stades);
  return { id, s, v: "base" };
}

const parties = [];
for (let k = 0; k < N_PARTIES; k++) {
  const n = k % 6 === 5 ? 4 : 3;
  const taille = n === 4 ? 8 : 5;
  const mj = [], ma = [];
  for (let i = 0; i < taille; i++) { mj.push(carteAuHasard()); ma.push(carteAuHasard()); }
  const graine = Math.floor(g() * 1e9);
  const niveaux = { j: pioche(NIV), a: pioche(NIV) };
  const premier = k % 2 ? "a" : "j";
  // la mise en place, comme partie() du web
  const rng = M.rngDe(graine);
  const cs = M.melanger([...Array(n * n).keys()], rng), ty = M.melanger(["feu", "glace", "nature", "eau", "foudre", "esprit"], rng);
  const nt = n === 4 ? 3 : 2, terres = {};
  for (let q = 0; q < nt; q++) terres[cs[q]] = ty[q];
  const bloc = n === 4 ? [cs[nt]] : [];
  const st = { n, cases: Array(n * n).fill(null), terres, bloc, gel: {}, tour: 0, uid: 0, main: { j: mj.map(c => ({ ...c })), a: ma.map(c => ({ ...c })) } };
  const coups = [];
  let tour = premier;
  while (!M.plein(st) && (st.main.j.length || st.main.a.length)) {
    if (!st.main[tour].length) { tour = M.autre(tour); continue; }
    const m = M.coupIA(st, rng, tour, niveaux[tour]);
    const ev = M.jouerCoup(st, tour, m);
    coups.push({ camp: tour, m, ev });
    tour = M.autre(tour);
  }
  parties.push({
    n, graine, premier, niveaux, mj, ma, terres, bloc, coups,
    final: st.cases.map(c => c && { id: c.id, camp: c.camp, ch: c.ch }),
    score: { j: M.compte(st, "j"), a: M.compte(st, "a") },
  });
}
// Les chiffres de toutes les cartes, à tous les stades : la base du jeu.
const chiffres = {};
for (const id of ids) for (let s = 1; s <= 3; s++) chiffres[id + s] = M.chiffresDe(id, s);
const sortie = path.join(__dirname, "parite_carre.json");
fs.writeFileSync(sortie + ".tmp", JSON.stringify({ parties, chiffres }));
fs.renameSync(sortie + ".tmp", sortie);
const coupsTotal = parties.reduce((x, p) => x + p.coups.length, 0);
console.log(`${parties.length} parties, ${coupsTotal} coups, ${Object.keys(chiffres).length} chiffres → ${sortie}`);
