"""
LE PORTIER du jeu public (⑯, 27/09) — l'accès des cousins par un code.

Internet → la box (443) → le reverse proxy de DSM → jeu.naspoizot.synology.me → nginx (le jeu)
→ ICI, pour deux choses seulement :
  · GET  /verifier  : nginx demande, à chaque requête, si le cookie est bon (204) ou non (401) ;
  · GET  /entree    : la page du code ;
  · POST /entrer    : le code tapé. Juste : un cookie signé (90 jours), et l'on entre. Faux : on
                      le dit. Trop d'essais : bloqué.

🔴 Le code n'est écrit nulle part en clair : seule son empreinte (PBKDF2-SHA256, salée) est dans
   secret/portier.json, avec la clé qui signe les cookies. Changer le code (nouveau_code.py)
   change aussi la clé : tous les cookies tombent, tout le monde retape le nouveau code.
🔴 Contre qui devine : 10 échecs en une heure pour une adresse → bloquée une heure ; 50 échecs en
   une heure en tout → plus aucun essai accepté, pour personne, jusqu'à ce que l'heure passe.
   (nginx ajoute 5 essais par minute et par adresse.) Le code : 5 mots au hasard.
🔴 Aucune dépendance : la bibliothèque standard de Python, rien à installer, rien à mettre à jour.
   Écrit pour Python 3.12 (l'image du NAS). Testé par tests/test_portier.py.
"""

import hashlib
import hmac
import html
import json
import os
import sys
import threading
import time
import unicodedata
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

SECRET = os.environ.get("PORTIER_SECRET", "/secret/portier.json")
PORT = int(os.environ.get("PORTIER_PORT", "8081"))
COOKIE = "portier"
DUREE_COOKIE = 90 * 24 * 3600
FENETRE = 3600                  # une heure
ECHECS_PAR_ADRESSE = 10
ECHECS_EN_TOUT = 50
TAILLE_MAX = 512                # le corps d'un POST : un code, rien de plus


# ─────────────────────────────────────────────────────────────
# Le secret, le code, le cookie
# ─────────────────────────────────────────────────────────────

class Secret:
    """secret/portier.json : {sel, empreinte, iterations, cle} (hex). Relu s'il change."""

    def __init__(self, chemin):
        self.chemin = chemin
        self._mtime = None
        self.donnees = None

    def lire(self):
        m = os.stat(self.chemin).st_mtime
        if m != self._mtime:
            with open(self.chemin, encoding="utf-8") as f:
                d = json.load(f)
            self.donnees = {
                "sel": bytes.fromhex(d["sel"]),
                "empreinte": bytes.fromhex(d["empreinte"]),
                "iterations": int(d["iterations"]),
                "cle": bytes.fromhex(d["cle"]),
            }
            self._mtime = m
        return self.donnees


def normaliser(code):
    """« Lune-Dragon  sel mons_brume » → « lune dragon sel mons brume » : ni la casse, ni les accents,
    ni les tirets, ni les espaces en trop ne comptent (un code tapé sur un téléphone)."""
    s = unicodedata.normalize("NFKD", str(code)).encode("ascii", "ignore").decode("ascii").lower()
    for c in "-_.,;:/+":
        s = s.replace(c, " ")
    return " ".join(s.split())


def empreinte(code, sel, iterations):
    return hashlib.pbkdf2_hmac("sha256", normaliser(code).encode("utf-8"), sel, iterations)


def code_juste(code, secret):
    if not isinstance(code, str) or len(code) > 200:
        return False
    return hmac.compare_digest(empreinte(code, secret["sel"], secret["iterations"]), secret["empreinte"])


def signer(expire, cle):
    return hmac.new(cle, str(expire).encode("ascii"), hashlib.sha256).hexdigest()


def cookie_neuf(cle, maintenant=None):
    expire = int((maintenant or time.time()) + DUREE_COOKIE)
    return "%d.%s" % (expire, signer(expire, cle))


def cookie_valide(valeur, cle, maintenant=None):
    try:
        expire_txt, sig = valeur.split(".", 1)
        expire = int(expire_txt)
    except (ValueError, AttributeError):
        return False
    if expire < (maintenant or time.time()):
        return False
    return hmac.compare_digest(sig, signer(expire, cle))


def lire_cookie(entete):
    for morceau in (entete or "").split(";"):
        nom, _, valeur = morceau.strip().partition("=")
        if nom == COOKIE:
            return valeur
    return ""


# ─────────────────────────────────────────────────────────────
# Qui essaie de deviner
# ─────────────────────────────────────────────────────────────

class Garde:
    """Les échecs de la dernière heure, par adresse et en tout (en mémoire : un redémarrage
    efface tout, et c'est voulu — pas de fichier à garder, pas de donnée qui traîne)."""

    def __init__(self):
        self.echecs = {}        # adresse → [instants]
        self.tous = []          # instants
        self._verrou = threading.Lock()     # le serveur répond à plusieurs requêtes à la fois

    def _nettoyer(self, maintenant):
        limite = maintenant - FENETRE
        self.tous = [t for t in self.tous if t > limite]
        for a in list(self.echecs):
            self.echecs[a] = [t for t in self.echecs[a] if t > limite]
            if not self.echecs[a]:
                del self.echecs[a]

    def refuse(self, adresse, maintenant=None):
        """Pourquoi on n'écoute même pas le code ('' : on l'écoute)."""
        maintenant = maintenant or time.time()
        with self._verrou:
            self._nettoyer(maintenant)
            if len(self.tous) >= ECHECS_EN_TOUT:
                return "ferme"
            if len(self.echecs.get(adresse, [])) >= ECHECS_PAR_ADRESSE:
                return "bloque"
            return ""

    def echec(self, adresse, maintenant=None):
        maintenant = maintenant or time.time()
        with self._verrou:
            self.echecs.setdefault(adresse, []).append(maintenant)
            self.tous.append(maintenant)


# ─────────────────────────────────────────────────────────────
# La page du code
# ─────────────────────────────────────────────────────────────

MESSAGES = {
    "code": "Ce n'est pas le bon code.",
    "bloque": "Trop d'essais : réessaie dans une heure.",
    "ferme": "L'entrée est fermée pour un moment : réessaie plus tard.",
}

PAGE = """<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Entrée</title>
<style>
:root { color-scheme: dark; }
html, body { margin: 0; height: 100%%; background: #0c0f0e; color: #efe9dc;
  font-family: Georgia, "Times New Roman", serif; }
main { min-height: 100%%; display: flex; flex-direction: column; align-items: center; justify-content: center;
  padding: 24px 16px; box-sizing: border-box; text-align: center; }
.etoile { font-size: 44px; color: #f1d28a; line-height: 1; }
h1 { font-weight: normal; font-style: italic; font-size: 34px; margin: 14px 0 6px; }
p { color: #a9b4ae; font-size: 17px; margin: 0 0 22px; max-width: 26em; }
form { width: 100%%; max-width: 360px; display: flex; flex-direction: column; gap: 14px; }
input { font: inherit; font-size: 20px; padding: 14px 16px; border-radius: 14px; border: 2px solid #caa968;
  background: #141a18; color: #efe9dc; text-align: center; }
button { font: inherit; font-size: 21px; padding: 14px; border-radius: 14px; border: 0;
  background: linear-gradient(#f1d28a, #caa968); color: #2b1b06; }
.erreur { color: #ec8f9a; min-height: 1.4em; margin: 0; }
small { color: #7d8a84; font-size: 14px; margin-top: 28px; max-width: 28em; line-height: 1.45; }
</style>
</head>
<body>
<main>
<div class="etoile">&#10022;</div>
<h1>Le code, s'il te plaît</h1>
<p>Tape le code que Maxim t'a donné.</p>
<form method="post" action="/entrer" autocomplete="off">
<input name="code" type="text" inputmode="text" autocapitalize="none" autocorrect="off" spellcheck="false"
  aria-label="Le code" required maxlength="120">
<p class="erreur" role="alert">%(erreur)s</p>
<button type="submit">Entrer</button>
</form>
<small>Ta partie reste sur ce téléphone, dans ce navigateur. Elle se perd si tu effaces les données du
navigateur, ou en navigation privée. Sur iPhone, ajoute le jeu à l'écran d'accueil (Partager → Sur l'écran
d'accueil) : sinon Safari l'efface au bout de 7 jours sans jouer.</small>
</main>
</body>
</html>
"""


def page(erreur=""):
    return (PAGE % {"erreur": html.escape(MESSAGES.get(erreur, ""))}).encode("utf-8")


# ─────────────────────────────────────────────────────────────
# Le serveur
# ─────────────────────────────────────────────────────────────

def fabriquer(secret, garde, journal=None):
    ecrire = journal or (lambda texte: print(texte, file=sys.stderr, flush=True))

    class Portier(BaseHTTPRequestHandler):
        server_version = "portier"
        sys_version = ""

        def log_message(self, fmt, *args):      # pas de journal de chaque requête : seulement les essais
            pass

        def _adresse(self):
            # nginx la met dans X-Real-IP (celle que DSM lui transmet) ; le portier n'écoute que nginx
            return (self.headers.get("X-Real-IP") or self.client_address[0]).strip()[:64]

        def _repondre(self, code, corps=b"", entetes=()):
            self.send_response(code)
            for k, v in entetes:
                self.send_header(k, v)
            if corps:
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(corps)))
            self.end_headers()
            if corps and self.command != "HEAD":
                self.wfile.write(corps)

        def do_GET(self):
            chemin = urlsplit(self.path)
            if chemin.path == "/verifier":
                ok = cookie_valide(lire_cookie(self.headers.get("Cookie")), secret.lire()["cle"])
                return self._repondre(204 if ok else 401)
            if chemin.path == "/entree":
                erreur = parse_qs(chemin.query).get("e", [""])[0]
                return self._repondre(200, page(erreur))
            return self._repondre(404)

        do_HEAD = do_GET

        def do_POST(self):
            if urlsplit(self.path).path != "/entrer":
                return self._repondre(404)
            adresse = self._adresse()
            try:
                taille = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                taille = -1
            if taille < 0 or taille > TAILLE_MAX:
                return self._repondre(413)
            corps = self.rfile.read(taille).decode("utf-8", "replace")
            raison = garde.refuse(adresse)
            if raison:
                ecrire("refusé (%s) : %s" % (raison, adresse))
                return self._repondre(303, entetes=[("Location", "/entree?e=" + raison)])
            code = parse_qs(corps).get("code", [""])[0]
            s = secret.lire()
            if not code_juste(code, s):
                garde.echec(adresse)
                ecrire("code faux : %s (%d en une heure, %d en tout)" % (adresse, len(garde.echecs.get(adresse, [])), len(garde.tous)))
                return self._repondre(303, entetes=[("Location", "/entree?e=code")])
            ecrire("entrée : %s" % adresse)
            valeur = cookie_neuf(s["cle"])
            return self._repondre(303, entetes=[
                ("Location", "/"),
                ("Set-Cookie", "%s=%s; Max-Age=%d; Path=/; Secure; HttpOnly; SameSite=Lax" % (COOKIE, valeur, DUREE_COOKIE)),
            ])

    return Portier


def main():
    secret = Secret(SECRET)
    secret.lire()                       # pas de secret : on s'arrête tout de suite (échec fermé)
    serveur = ThreadingHTTPServer(("0.0.0.0", PORT), fabriquer(secret, Garde()))
    print("portier : à l'écoute sur %d" % PORT, file=sys.stderr, flush=True)
    serveur.serve_forever()


if __name__ == "__main__":
    main()
