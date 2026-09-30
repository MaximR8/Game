// ═════════════════════════════ 7 · LE SIÈGE ═════════════════════════════
// Un boss, trois héros. Le boss ANNONCE son prochain coup. Tu as 3 d'énergie par tour et chaque héros
// a deux gestes, toujours disponibles : pas de pioche, pas de hasard. Un puzzle de 2 minutes.
(function () {
  const ICONES = {
    frappe: `<svg viewBox="0 0 24 24"><path d="M4 20l9-9M13 11l6-6 1 3-6 6M6 14l4 4M3 21l2-2"/></svg>`,
    zone: `<svg viewBox="0 0 24 24"><path d="M3 9c3-3 6 3 9 0s6 3 9 0M3 15c3-3 6 3 9 0s6 3 9 0"/></svg>`,
    garde: `<svg viewBox="0 0 24 24"><path d="M12 3l7 3v6c0 4-3 7-7 9-4-2-7-5-7-9V6z"/></svg>`,
    charge: `<svg viewBox="0 0 24 24"><path d="M12 3v10M12 17v2"/><circle cx="12" cy="12" r="10"/></svg>`,
  };
  const GESTES = {
    garde: [
      { nom: "Rempart", cout: 1, txt: "+8 armure à tous", f: (s) => { for (const x of s.eq) if (x.pv > 0) x.armure += 8; return "+8 armure"; } },
      { nom: "Coup de bouclier", cout: 1, txt: "6 dégâts", f: (s) => s.frapper(6) },
    ],
    frappeur: [
      { nom: "Frappe", cout: 1, txt: "d12", f: (s, h) => s.frapper(Math.round(h.att / 2)) },
      { nom: "Coup puissant", cout: 2, txt: "d24", f: (s, h) => s.frapper(h.att) },
    ],
    appui: [
      { nom: "Soin", cout: 1, txt: "+12 PV au plus blessé", f: (s) => { const x = s.eq.filter(y => y.pv > 0).sort((a, b) => a.pv / a.max - b.pv / b.max)[0]; if (x) x.pv = Math.min(x.max, x.pv + 12); return "+12 PV"; } },
      { nom: "Entrave", cout: 1, txt: "son prochain coup −50 %", f: (s) => { s.entrave = true; return "entravé"; } },
    ],
  };
  const MOTIF = [{ t: "frappe", n: 14 }, { t: "zone", n: 7 }, { t: "garde", n: 15 }, { t: "charge" }, { t: "frappe", n: 30 }];
  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const pick = r => melanger(HEROS.filter(x => x.role === r && x.type !== "aucun").map(x => x.id), rng)[0];
    const ids = tuto ? ["golem", "thor", "bahamut"] : [pick("garde"), pick("frappeur"), pick("appui")];
    const bossId = tuto ? "minotaure" : melanger(["minotaure", "wendigo", "cuelebre", "troll", "chupacabra"].filter(x => !ids.includes(x)), rng)[0];
    const eq = ids.map(id => { const f = FICHES[id]; const pv = Math.round(f.pv / 2); return { id, pv, max: pv, att: f.att, armure: 0, role: f.role, faits: new Set() }; });
    const boss = { id: bossId, pv: 120, max: 120, armure: 0 };
    let energie = 3, tour = 1, motifI = 0, occupe = false, entrave = false;
    const intention = () => { const m = MOTIF[motifI % MOTIF.length], k = 1 + Math.floor(motifI / MOTIF.length) * 0.25; return { ...m, n: m.n ? Math.round(m.n * k) : 0 }; };
    const devant = () => eq.find(x => x.pv > 0);

    const zBoss = h("div", "sg-boss"), zEq = h("div", "sg-eq"), zBas = h("div", "sg-bas");
    const pipsEl = h("div", "sg-energie"), bFin = h("button", "btn or", "Fin du tour");
    zBas.append(pipsEl, bFin);
    ctx.scene.append(zBoss, zEq, zBas);

    const s = {
      eq, get entrave() { return entrave; }, set entrave(v) { entrave = v; },
      frapper(n) { let d = n; const a = Math.min(boss.armure, d); boss.armure -= a; d -= a; boss.pv -= d; flotSur(zBoss.querySelector(".carte"), a ? `−${d} (${a} bloqués)` : `−${d}`, "or"); rejouer(zBoss.querySelector(".carte"), "secoue"); return null; },
    };
    function texteIntention(it) {
      const c = devant();
      if (it.t === "frappe") return [`Va frapper ${it.n}`, c ? `sur ${nomDe(c.id)}` : ""];
      if (it.t === "zone") return [`Souffle : ${it.n} à tous`, ""];
      if (it.t === "garde") return [`Se protège : +${it.n} armure`, "tes coups seront bloqués"];
      return ["Prend son élan…", "coup terrible au prochain tour"];
    }
    function rendre() {
      ctx.score.innerHTML = `<span class="sep">tour</span><span class="j">${tour}</span>`;
      const it = intention();
      zBoss.innerHTML = "";
      const bc = vignette(boss.id, { nom: false, camp: "a" });
      const inf = h("div", "sg-binfo");
      inf.append(h("div", "sg-bnom", nomDe(boss.id)));
      const pv = h("div", "sg-pv lui"), i = h("i"); i.style.width = Math.max(0, boss.pv / boss.max * 100) + "%"; pv.append(i);
      inf.append(pv, h("div", "sg-pvt", `${Math.max(0, boss.pv)} / ${boss.max} PV${boss.armure ? ` · armure ${boss.armure}` : ""}`));
      const [t1, t2] = texteIntention(it);
      const intent = h("div", "sg-intent " + it.t); intent.innerHTML = ICONES[it.t]; const tx = h("div"); tx.append(h("b", "", t1)); if (t2) tx.append(h("span", "", t2)); intent.append(tx);
      if (entrave && it.n) intent.append(h("em", "", "−50 %"));
      inf.append(intent);
      zBoss.append(bc, inf);
      zEq.innerHTML = "";
      eq.forEach((x, k) => {
        const col = h("div", "sg-h" + (x.pv <= 0 ? " ko" : ""));
        const c = vignette(x.id, { camp: "j" }); c.dataset.k = k;
        let coup = 0;
        if (x.pv > 0) { if (it.t === "frappe" && x === devant()) coup = it.n; if (it.t === "zone") coup = it.n; }
        if (coup) { const reel = Math.max(0, Math.round(coup * (entrave ? 0.5 : 1)) - x.armure); c.append(h("span", "sg-menace", `−${reel}`)); }
        col.append(c);
        const pv = h("div", "sg-pv"), b = h("i"); b.style.width = Math.max(0, x.pv / x.max * 100) + "%"; pv.append(b);
        col.append(pv, h("div", "sg-pvt", `${Math.max(0, x.pv)} PV${x.armure ? ` · armure ${x.armure}` : ""}`));
        GESTES[x.role].forEach((g, gi) => {
          const b2 = h("button", "sg-geste"); b2.dataset.g = `${k}-${gi}`;
          const txt = g.txt.startsWith("d") ? `${g.txt.slice(1)} dégâts` : g.txt;
          b2.innerHTML = `<i>${g.cout}</i><b>${g.nom}</b><span>${g.txt === "d12" ? Math.round(x.att / 2) + " dégâts" : g.txt === "d24" ? x.att + " dégâts" : txt}</span>`;
          b2.disabled = x.pv <= 0 || x.faits.has(gi) || g.cout > energie || occupe;
          if (x.faits.has(gi)) b2.classList.add("fait");
          b2.onclick = () => geste(x, gi);
          col.append(b2);
        });
        zEq.append(col);
      });
      pipsEl.innerHTML = "";
      for (let k = 0; k < 3; k++) pipsEl.append(h("i", k < energie ? "" : "vide"));
      pipsEl.append(h("span", "", `${energie} d'énergie`));
      bFin.disabled = occupe;
      ctx.consigne(occupe ? "Le boss agit…" : energie ? "Utilise ton énergie, puis « Fin du tour »" : "Plus d'énergie : « Fin du tour »", occupe ? "lui" : "");
    }
    function geste(x, gi) {
      const g = GESTES[x.role][gi];
      if (occupe || x.pv <= 0 || x.faits.has(gi) || g.cout > energie) return;
      energie -= g.cout; x.faits.add(gi);
      const m = g.f(s, x);
      rendre();
      if (m) flotSur(zEq.querySelector(`[data-k="${eq.indexOf(x)}"]`), m, "vert");
      if (boss.pv <= 0) { occupe = true; setTimeout(() => ctx.fin({ titre: "Victoire", texte: `${nomDe(boss.id)} tombe au tour ${tour}.`, gagne: true }), 700); }
    }
    async function finTour() {
      if (occupe) return;
      occupe = true; rendre();
      await dodo(450); if (!ctx.vivant()) return;
      const it = intention(), bc = zBoss.querySelector(".carte");
      rejouer(bc, "ry-frappeA");
      boss.armure = 0;
      const k = entrave ? 0.5 : 1;
      const toucher = (x, n) => { const d = Math.max(0, Math.round(n * k) - x.armure); x.pv -= d; const e = zEq.querySelector(`[data-k="${eq.indexOf(x)}"]`); flotSur(e, d ? `−${d}` : "bloqué", d ? "rose" : "mot"); rejouer(e, "secoue"); };
      if (it.t === "frappe") { const c = devant(); if (c) toucher(c, it.n); }
      if (it.t === "zone") for (const x of eq) if (x.pv > 0) toucher(x, it.n);
      if (it.t === "garde") { boss.armure = it.n; flotSur(bc, `+${it.n} armure`, "mot"); }
      if (it.t === "charge") flotSur(bc, "il prend son élan", "mot");
      await dodo(900); if (!ctx.vivant()) return;
      for (const x of eq) { x.armure = 0; x.faits.clear(); }
      if (it.n) entrave = false;
      motifI++; tour++; energie = 3; occupe = false;
      if (!eq.some(x => x.pv > 0)) { rendre(); return ctx.fin({ titre: "Défaite", texte: `Il restait ${boss.pv} PV à ${nomDe(boss.id)}.`, gagne: false }); }
      rendre();
    }
    bFin.onclick = finTour;
    rendre();
    if (tuto) (async () => {
      await ctx.etape({ texte: "Le boss annonce son coup à l'avance." });
      if (!ctx.vivant()) return;
      await ctx.etape({ cible: () => zEq.querySelector('[data-g="0-0"]'), texte: "Protège-toi : touche Rempart" });
      await ctx.etape({ cible: () => zEq.querySelector('[data-g="1-0"]'), texte: "Frappe avec Thor" });
      await ctx.etape({ cible: () => bFin, texte: "Fin du tour" });
      await dodo(1500); if (!ctx.vivant()) return;
      await ctx.etape({ texte: "14 moins 8 d'armure : 6. Tu vois tout : aucun hasard." });
      ctx.tutoFini();
    })();
  }

  enregistrer({ id: "siege", num: "7", nom: "Le Siège", accroche: "Le boss annonce son coup. Tu réponds. Un puzzle sans hasard.", duree: "2 min", images: ["minotaure", "golem", "bahamut"], fond: "linear-gradient(160deg,#2a1818,#141020)", lancer });
})();
