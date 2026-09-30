// LE SON DU JEU WEB, MESURÉ DANS UN VRAI NAVIGATEUR (29/09 — « j'entends pas le son »).
// test_son (Godot, pilote muet) lit ce que le jeu DEMANDE ; ce script mesure ce qui SORT : il ouvre le jeu dans Chrome
// (sans fenêtre), espionne l'API audio du navigateur (les sons démarrés, leurs gains), branche un analyseur sur la sortie,
// lit le niveau seconde par seconde, touche l'écran comme un joueur, et finit par un son témoin (−20 dB attendus).
// Une sortie à −120 dB avec des sons démarrés : le jeu se tait (c'était un bus créé en cours de partie, relié à rien).
//   cd outils/navigateur && npm install puppeteer-core@23      (une fois ; node_modules reste ici, hors du jeu)
//   node son.js https://192.168.0.17:18443/ <dossier des captures>
const puppeteer = require('puppeteer-core');
const URL = process.argv[2] || 'https://192.168.0.17:18443/';
const sortie = process.argv[3] || '.';

(async () => {
  const nav = await puppeteer.launch({
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: 'new',
    args: ['--ignore-certificate-errors', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--window-size=540,1200',
      '--autoplay-policy=user-gesture-required'],
    defaultViewport: { width: 540, height: 1200 },
  });
  const page = await nav.newPage();
  page.on('console', m => { const t = m.text(); if (/audio|son|sound|error|warn/i.test(t)) console.log('[console]', t.slice(0, 300)); });
  page.on('pageerror', e => console.log('[erreur page]', String(e).slice(0, 300)));
  await page.evaluateOnNewDocument(() => {
    const A = window.__audio = { ctx: [], starts: [], worklets: 0, medias: 0 };
    const AC = window.AudioContext;
    window.AudioContext = function (...a) { const c = new AC(...a); A.ctx.push(c); return c; };
    window.AudioContext.prototype = AC.prototype;
    const st = AudioBufferSourceNode.prototype.start;
    AudioBufferSourceNode.prototype.start = function (...a) {
      A.starts.push({ t: Math.round(performance.now()), dur: this.buffer ? +this.buffer.duration.toFixed(2) : null, rate: +this.playbackRate.value.toFixed(3), off: a.length > 1 ? +(+a[1]).toFixed(2) : 0 });
      return st.apply(this, a);
    };
    A.vers_sortie = 0; A.gains = [];
    const conn = AudioNode.prototype.connect;
    AudioNode.prototype.connect = function (dst, ...r) {
      try {
        if (dst instanceof AudioDestinationNode) {
          const c = this.context;
          if (!c.__an) { c.__an = c.createAnalyser(); c.__an.fftSize = 4096; }
          conn.call(this, c.__an); A.vers_sortie++;
        }
      } catch (e) {}
      return conn.call(this, dst, ...r);
    };
    const CG = BaseAudioContext.prototype.createGain;
    BaseAudioContext.prototype.createGain = function (...a) { const g = CG.apply(this, a); A.gains.push(g); return g; };
    window.__niveau = () => {
      const c = A.ctx[0]; if (!c || !c.__an) return null;
      const buf = new Float32Array(c.__an.fftSize); c.__an.getFloatTimeDomainData(buf);
      let s = 0; for (const v of buf) s += v * v; return +(10 * Math.log10(s / buf.length + 1e-12)).toFixed(1);
    };
    const AWN = window.AudioWorkletNode;
    if (AWN) window.AudioWorkletNode = function (...a) { A.worklets++; return new AWN(...a); };
  });
  await page.goto(URL, { waitUntil: 'load', timeout: 60000 });
  const etat = async (quand) => {
    const r = await page.evaluate(() => ({
      ctx: window.__audio.ctx.map(c => ({ etat: c.state, sr: c.sampleRate, t: +c.currentTime.toFixed(2) })),
      starts: window.__audio.starts.length, derniers: window.__audio.starts.slice(-4), worklets: window.__audio.worklets,
      vers_sortie: window.__audio.vers_sortie, niveau_dB: window.__niveau(), gains: window.__audio.gains.map(g => +g.gain.value.toFixed(3)),
    }));
    console.log(quand, JSON.stringify(r));
  };
  const courbe = [];
  for (let k = 0; k < 40; k++) { await new Promise(r => setTimeout(r, 1000)); courbe.push(await page.evaluate(() => window.__niveau())); }
  console.log('la musique, seconde par seconde (dB) :', courbe.join(' '));
  await etat('après le chargement, sans toucher :');
  await page.screenshot({ path: sortie + '/avant.png' });
  // un toucher (le geste qui libère le son), puis quelques-uns sur la machine
  await page.mouse.click(270, 600);
  await new Promise(r => setTimeout(r, 3000));
  await etat('après un toucher :');
  for (let k = 0; k < 6; k++) { await page.mouse.click(120 + k * 50, 160); await new Promise(r => setTimeout(r, 400)); }
  await new Promise(r => setTimeout(r, 4000));
  await etat('après 6 touchers sur la machine :');
  await page.screenshot({ path: sortie + '/apres.png' });
  // le témoin : un son pur branché droit sur la sortie — si l'analyseur l'entend, c'est bien le jeu qui se tait
  await page.evaluate(() => { const c = window.__audio.ctx[0]; const o = c.createOscillator(); const g = c.createGain(); g.gain.value = 0.1; o.connect(g); g.connect(c.destination); o.start(); });
  await new Promise(r => setTimeout(r, 800));
  console.log('témoin (un la à −20 dB, branché sur la sortie) :', await page.evaluate(() => window.__niveau()), 'dB');
  await nav.close();
})().catch(e => { console.error('ÉCHEC', e); process.exit(1); });
