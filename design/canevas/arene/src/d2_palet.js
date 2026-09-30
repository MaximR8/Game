// ═════════════════════════════ 2 · LE PALET DES LÉGENDES ═════════════════════════════
// Chaque héros est un palet. On le tire vers soi, on vise, on lâche : il glisse vers trois cercles.
// Les palets se cognent. À la fin, dans chaque cercle, la plus grosse force l'emporte : 2 cercles sur 3.
(function () {
  const W = 360, H = 560, R = 22, FROT = 0.982, VMAX = 11, LX = 180, LY = 505, LIGNE = 452;
  const MASSE = { garde: 1.8, appui: 1.1, frappeur: 0.9, sbire: 1.2 };
  const FORCE = { garde: 3, appui: 3, frappeur: 4, sbire: 2 };
  const LANCERS = 4;

  function palet(id, camp) { const r = FICHES[id].role; return { id, camp, x: LX, y: LY, vx: 0, vy: 0, m: MASSE[r] || 1, f: FORCE[r] || 3, dehors: false }; }
  function pas(ps) {
    for (let s = 0; s < 2; s++) {
      for (const p of ps) { if (p.dehors) continue; p.x += p.vx / 2; p.y += p.vy / 2;
        if (p.x < R) { p.x = R; p.vx = -p.vx * 0.75; } if (p.x > W - R) { p.x = W - R; p.vx = -p.vx * 0.75; }
        if (p.y > H - R) { p.y = H - R; p.vy = -p.vy * 0.75; }
        if (p.y < -R) { p.dehors = true; p.vx = p.vy = 0; }
      }
      for (let i = 0; i < ps.length; i++) for (let k = i + 1; k < ps.length; k++) {
        const a = ps[i], b = ps[k]; if (a.dehors || b.dehors) continue;
        const dx = b.x - a.x, dy = b.y - a.y, d = Math.hypot(dx, dy);
        if (d >= 2 * R || d === 0) continue;
        const nx = dx / d, ny = dy / d, rec = 2 * R - d, ia = 1 / a.m, ib = 1 / b.m;
        a.x -= nx * rec * ia / (ia + ib); a.y -= ny * rec * ia / (ia + ib); b.x += nx * rec * ib / (ia + ib); b.y += ny * rec * ib / (ia + ib);
        const vn = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
        if (vn < 0) { const j = -(1 + 0.9) * vn / (ia + ib); a.vx -= j * ia * nx; a.vy -= j * ia * ny; b.vx += j * ib * nx; b.vy += j * ib * ny; }
      }
    }
    let bouge = false;
    for (const p of ps) { p.vx *= FROT; p.vy *= FROT; if (Math.hypot(p.vx, p.vy) < 0.04) p.vx = p.vy = 0; else bouge = true; }
    return bouge;
  }
  function simuler(ps) { for (let i = 0; i < 1500 && pas(ps); i++); }
  function comptes(ps, terres) {
    return terres.map(t => {
      const s = { j: 0, a: 0 };
      for (const p of ps) if (!p.dehors && Math.hypot(p.x - t.x, p.y - t.y) <= t.r) s[p.camp] += p.f + (typeDe(p.id) === t.type ? 2 : 0);
      return s;
    });
  }
  const gagnes = (cs, camp) => cs.filter(s => s[camp] > s[autre(camp)]).length;
  const distance = v0 => v0 * FROT / (1 - FROT);

  function lancer(ctx) {
    const rng = rngDe(Date.now() % 1e9), tuto = Jeu.tuto;
    const types = melanger(Object.keys(ADV), rng);
    const terres = [{ x: 180, y: 112, r: 58 }, { x: 88, y: 282, r: 60 }, { x: 272, y: 282, r: 60 }];
    terres.forEach((t, i) => t.type = tuto ? ["nature", "feu", "eau"][i] : types[i]);
    let equipeJ, equipeA;
    if (tuto) { equipeJ = ["thor", "golem", "kitsune", "bahamut"]; equipeA = ["fenrir", "cerbere", "oni", "banshee"]; }
    else { const pool = melanger(HEROS_TYPES.map(x => x.id), rng); equipeJ = pool.slice(0, LANCERS); equipeA = pool.slice(LANCERS, 2 * LANCERS - 1).concat([SBIRES[Math.floor(rng() * 6)].id]); melanger(equipeA, rng); }
    const reste = { j: [...equipeJ], a: [...equipeA] };
    const plateau = [];
    let courant = null, etat = "attente", vise = null, viseJ = false, finLancer = null, premier = tuto ? "j" : (statsDe("palet").p % 2 ? "a" : "j");

    const hautRang = h("div", "pl-rang pl-a"), cadre = h("div", "pl-cadre"), cv = h("canvas", "pl-canvas"), basRang = h("div", "pl-rang pl-j");
    cadre.append(cv); ctx.scene.append(hautRang, cadre, basRang);
    const cx = cv.getContext("2d");
    let ech = 1;
    function dimensionner() {
      const r = cadre.getBoundingClientRect(), dpr = window.devicePixelRatio || 1;
      ech = Math.min(r.width / W, r.height / H) || 1;
      cv.style.width = W * ech + "px"; cv.style.height = H * ech + "px";
      cv.width = W * ech * dpr; cv.height = H * ech * dpr; cx.setTransform(ech * dpr, 0, 0, ech * dpr, 0, 0);
    }
    const ro = new ResizeObserver(dimensionner); ro.observe(cadre); dimensionner();
    const versEcran = (x, y) => { const r = cv.getBoundingClientRect(); return { x: r.left + x * ech, y: r.top + y * ech }; };
    const versPlateau = e => { const r = cv.getBoundingClientRect(); return { x: (e.clientX - r.left) / ech, y: (e.clientY - r.top) / ech }; };
    for (const id of [...equipeJ, ...equipeA]) if (!FICHES[id].sbire) image(id);

    function rangs() {
      hautRang.innerHTML = ""; basRang.innerHTML = "";
      hautRang.append(h("span", "pl-lib lui", `Ses palets : ${reste.a.length}`));
      reste.a.forEach(id => hautRang.append(vignette(id, { nom: false })));
      basRang.append(h("span", "pl-lib", `Tes palets : ${reste.j.length}`));
      reste.j.forEach(id => basRang.append(vignette(id, { nom: false })));
      const cs = comptes(plateau, terres);
      ctx.scoreJA(gagnes(cs, "j"), gagnes(cs, "a"));
    }
    // ——— le dessin ———
    function dessinerPalet(p, fantome) {
      cx.save(); cx.globalAlpha = fantome ? 0.35 : 1;
      cx.beginPath(); cx.arc(p.x, p.y, R, 0, Math.PI * 2); cx.closePath();
      const f = FICHES[p.id];
      if (f.sbire) { cx.fillStyle = TYPES[f.type].c; cx.fill(); }
      else { cx.save(); cx.clip(); const im = image(p.id); if (im.complete && im.naturalWidth) cx.drawImage(im, p.x - R, p.y - R * 1.3 - (f.cad - .3) * 20, 2 * R, 2.5 * R); else { cx.fillStyle = "#333"; cx.fill(); } cx.restore(); }
      cx.lineWidth = 3.5; cx.strokeStyle = p.camp === "j" ? "#7fd0b0" : "#e59a8a"; cx.stroke();
      cx.beginPath(); cx.arc(p.x + 15, p.y - 15, 9, 0, Math.PI * 2); cx.fillStyle = "#f1d28a"; cx.fill();
      cx.fillStyle = "#2b1b06"; cx.font = "700 12px Fraunces, Georgia, serif"; cx.textAlign = "center"; cx.textBaseline = "middle"; cx.fillText(p.f, p.x + 15, p.y - 14.5);
      cx.restore();
    }
    function dessiner() {
      cx.clearRect(0, 0, W, H);
      cx.fillStyle = "rgba(24,20,40,.78)"; cx.strokeStyle = "rgba(202,169,104,.55)"; cx.lineWidth = 1.5;
      cx.beginPath(); cx.roundRect(1, 1, W - 2, H - 2, 16); cx.fill(); cx.stroke();
      const cs = comptes(plateau, terres);
      terres.forEach((t, i) => {
        const c = TYPES[t.type].c, s = cs[i];
        cx.beginPath(); cx.arc(t.x, t.y, t.r, 0, Math.PI * 2);
        cx.fillStyle = c + "26"; cx.fill(); cx.lineWidth = 2; cx.strokeStyle = c; cx.stroke();
        cx.beginPath(); cx.arc(t.x, t.y, t.r * 0.5, 0, Math.PI * 2); cx.lineWidth = 1; cx.strokeStyle = c + "66"; cx.stroke();
        cx.textAlign = "center"; cx.textBaseline = "middle";
        cx.font = "600 12px 'Barlow Semi Condensed', Arial, sans-serif"; cx.fillStyle = c;
        cx.fillText(`${TYPES[t.type].nom} +2`, t.x, t.y - t.r - 9);
        cx.font = "700 19px Fraunces, Georgia, serif";
        const yS = t.y + t.r + 13;
        cx.fillStyle = "#7fd0b0"; cx.fillText(s.j, t.x - 18, yS);
        cx.fillStyle = "#6f6886"; cx.font = "500 11px 'Barlow Semi Condensed', Arial"; cx.fillText("contre", t.x, yS + 1);
        cx.font = "700 19px Fraunces, Georgia, serif"; cx.fillStyle = "#e59a8a"; cx.fillText(s.a, t.x + 18, yS);
        if (s.j !== s.a) { cx.strokeStyle = s.j > s.a ? "#7fd0b0" : "#e59a8a"; cx.lineWidth = 3; cx.beginPath(); cx.arc(t.x, t.y, t.r + 3, 0, Math.PI * 2); cx.stroke(); }
      });
      cx.setLineDash([6, 6]); cx.strokeStyle = "rgba(202,169,104,.5)"; cx.lineWidth = 1.5;
      cx.beginPath(); cx.moveTo(14, LIGNE); cx.lineTo(W - 14, LIGNE); cx.stroke(); cx.setLineDash([]);
      for (const p of plateau) if (!p.dehors) dessinerPalet(p);
      if (courant) {
        if (vise) {
          const dx = courant.x - vise.x, dy = courant.y - vise.y, L = Math.hypot(dx, dy);
          if (L > 8) {
            const pw = Math.min(L / 140, 1), ux = dx / L, uy = dy / L, d = distance(pw * VMAX);
            cx.strokeStyle = "rgba(239,233,220,.35)"; cx.lineWidth = 2; cx.beginPath(); cx.moveTo(courant.x, courant.y); cx.lineTo(vise.x, vise.y); cx.stroke();
            cx.setLineDash([3, 7]); cx.strokeStyle = "#f1d28a"; cx.lineWidth = 2.5; cx.beginPath(); cx.moveTo(courant.x, courant.y);
            const ex = courant.x + ux * d, ey = courant.y + uy * d; cx.lineTo(ex, ey); cx.stroke(); cx.setLineDash([]);
            if (ey > -R) dessinerPalet({ ...courant, x: ex, y: ey }, true);
            cx.fillStyle = "#f1d28a"; cx.font = "700 13px 'Barlow Semi Condensed', Arial"; cx.textAlign = "center";
            cx.fillText(ey < 0 ? "trop fort : dehors" : `force du lancer ${Math.round(pw * 100)} %`, W / 2, LIGNE + 16);
          }
        }
        dessinerPalet(courant);
      }
    }
    let boucle = 0;
    function image_() {
      if (!ctx.vivant()) { ro.disconnect(); return; }
      if (etat === "roule") { const b = pas(plateau); if (!b) { etat = "repos"; if (finLancer) { const f = finLancer; finLancer = null; f(); } } }
      dessiner(); boucle = requestAnimationFrame(image_);
    }
    boucle = requestAnimationFrame(image_);

    // ——— le geste ———
    cv.addEventListener("pointerdown", e => {
      if (etat !== "vise" || !courant || courant.camp !== "j") return;
      const p = versPlateau(e);
      if (Math.hypot(p.x - courant.x, p.y - courant.y) > 80) return;
      vise = p; viseJ = true; try { cv.setPointerCapture(e.pointerId); } catch (_) {}
    });
    cv.addEventListener("pointermove", e => { if (viseJ) vise = versPlateau(e); });
    const lacher = e => {
      if (!viseJ || !vise || !courant) return;
      viseJ = false;
      const dx = courant.x - vise.x, dy = courant.y - vise.y, L = Math.hypot(dx, dy);
      vise = null;
      if (L < 14) return;
      tirer(dx / L, dy / L, Math.min(L / 140, 1));
    };
    cv.addEventListener("pointerup", lacher); cv.addEventListener("pointercancel", () => { if (viseJ) { viseJ = false; vise = null; } });
    function tirer(ux, uy, pw) {
      courant.vx = ux * pw * VMAX; courant.vy = uy * pw * VMAX;
      plateau.push(courant); courant = null; etat = "roule";
      Guide.signal("lancer"); rangs();
    }
    function attendreRepos() { return new Promise(r => { finLancer = r; }); }
    async function tourJ() {
      courant = palet(reste.j.shift(), "j"); rangs();
      ctx.consigne(`À toi : tire ${nomDe(courant.id)} vers le bas, vise, lâche`);
      etat = "vise";
      await new Promise(r => { const t = setInterval(() => { if (etat === "roule" || !ctx.vivant()) { clearInterval(t); r(); } }, 50); });
      await attendreRepos();
    }
    function choisirTir(p) {
      const cands = [];
      for (let k = 0; k < 60; k++) cands.push([-Math.PI / 2 + (rng() * 2 - 1) * 1.0, 0.3 + rng() * 0.7]);
      for (const t of terres) { const dx = t.x - LX, dy = t.y - LY, d = Math.hypot(dx, dy); for (const e of [-6, 0, 6]) cands.push([Math.atan2(dy, dx), Math.min(1, (d + e) / distance(VMAX))]); }
      for (const q of plateau) if (!q.dehors && q.camp === "j") { const a = Math.atan2(q.y - LY, q.x - LX); cands.push([a, 0.85], [a, 1]); }
      let best = null;
      for (const [a, pw] of cands) {
        const s = plateau.map(q => ({ ...q })), c = { ...p, vx: Math.cos(a) * pw * VMAX, vy: Math.sin(a) * pw * VMAX };
        s.push(c); simuler(s);
        const cs = comptes(s, terres);
        const v = cs.reduce((x, t) => x + Math.tanh((t.a - t.j) / 3), 0) + rng() * 0.15;
        if (!best || v > best.v) best = { v, a, pw };
      }
      return best;
    }
    async function tourA() {
      courant = palet(reste.a.shift(), "a"); rangs();
      ctx.consigne(`Il lance ${nomDe(courant.id)}…`, "lui"); etat = "attente";
      await dodo(350); if (!ctx.vivant()) return;
      const t = choisirTir(courant);
      const a = t.a + (rng() - 0.5) * 0.05, pw = borne(t.pw * (1 + (rng() - 0.5) * 0.06), 0.2, 1);
      for (let k = 1; k <= 12; k++) { vise = { x: courant.x - Math.cos(a) * pw * 140 * k / 12, y: courant.y - Math.sin(a) * pw * 140 * k / 12 }; await dodo(45); }
      await dodo(250); vise = null; if (!ctx.vivant()) return;
      tirer(Math.cos(a), Math.sin(a), pw);
      await attendreRepos();
    }
    async function partie() {
      rangs();
      if (tuto) {
        await ctx.etape({ texte: "Lance tes palets dans les cercles." });
        if (!ctx.vivant()) return;
        courant = palet(reste.j.shift(), "j"); rangs(); etat = "vise";
        ctx.consigne("Tire Thor vers le bas, vise, lâche");
        await ctx.etape({ cible: () => cadre, point: () => versEcran(LX, LY), doigt: "tire", signal: "lancer", bulle: "haut", texte: "Tire le palet vers toi, puis lâche" });
        if (!ctx.vivant()) return;
        if (etat === "vise") await new Promise(r => { const t = setInterval(() => { if (etat === "roule" || !ctx.vivant()) { clearInterval(t); r(); } }, 50); });
        await attendreRepos(); if (!ctx.vivant()) return;
        const dedans = terres.some(t => { const p = plateau[0]; return !p.dehors && Math.hypot(p.x - t.x, p.y - t.y) <= t.r; });
        await ctx.etape({ texte: dedans ? "Dans le cercle : il compte pour toi !" : "Raté ! Vise l'intérieur d'un cercle." });
        await tourA(); if (!ctx.vivant()) return;
        await ctx.etape({ texte: "Cogne ses palets pour les sortir des cercles !" });
        await ctx.etape({ texte: "2 cercles sur 3 : tu gagnes." });
        ctx.tutoFini();
      }
      const ordre = premier === "j" ? ["j", "a"] : ["a", "j"];
      while (reste.j.length || reste.a.length) {
        for (const c of ordre) { if (!reste[c].length) continue; if (c === "j") await tourJ(); else await tourA(); if (!ctx.vivant()) return; rangs(); }
      }
      const cs = comptes(plateau, terres), j = gagnes(cs, "j"), a = gagnes(cs, "a");
      const tj = cs.reduce((x, s) => x + s.j, 0), ta = cs.reduce((x, s) => x + s.a, 0);
      const gagne = j > a || (j === a && tj > ta), nul = j === a && tj === ta;
      ctx.consigne(nul ? "Égalité" : gagne ? "Gagné !" : "Perdu", gagne ? "" : "lui");
      await dodo(900);
      ctx.fin({ titre: nul ? "Égalité" : gagne ? "Victoire" : "Défaite", texte: `Cercles : ${j} pour toi, ${a} pour lui.${j === a && !nul ? ` Force totale : ${tj} contre ${ta}.` : ""}`, gagne: gagne && !nul });
    }
    partie();
  }

  enregistrer({ id: "palet", num: "2", nom: "Le Palet des légendes", accroche: "Lance tes héros au doigt. Cogne les siens hors des cercles.", duree: "2 min", images: ["golem", "thor", "cerbere"], fond: "linear-gradient(160deg,#1c2a3e,#141126)", lancer });
})();
