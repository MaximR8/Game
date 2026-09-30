"""
Le portier vu de DEHORS (⑯, 27/09) : à lancer une fois le reverse proxy de DSM réglé et
`docker compose up -d` fait sur le NAS.

    python portier/verifier_dehors.py <le code>          (depuis _NOUVEAU_PROJET)
    python portier/verifier_dehors.py <le code> --adresse https://jeu.naspoizot.synology.me

Vérifie, par le vrai chemin (Internet → box → DSM → le portier), avec le vrai certificat :
  · sans cookie, AUCUN fichier du jeu ne sort (toutes les adresses renvoient vers /entree) ;
  · la page du code répond, avec les en-têtes de sécurité ;
  · une méthode autre que GET/HEAD/POST est refusée ;
  · un code faux est refusé ; des essais rapprochés sont freinés (429) ;
  · le bon code donne le cookie, et avec lui le jeu est servi.
⚠️ Il fait au plus 6 essais faux : le portier bloque une adresse à 10 (une heure).
Attendu : « RESULTAT: OK ».
"""

import http.client
import ssl
import sys
import time
from urllib.parse import quote_plus, urlsplit

erreurs = 0
verifs = 0


def ok(quoi, vrai, detail=""):
    global erreurs, verifs
    verifs += 1
    print("  %s %s%s" % ("✓" if vrai else "✗", quoi, (" — " + detail) if detail and not vrai else ""))
    if not vrai:
        erreurs += 1


def main():
    if len(sys.argv) < 2:
        raise SystemExit("usage : python portier/verifier_dehors.py <le code> [--adresse https://…]")
    code = sys.argv[1]
    adresse = "https://jeu.naspoizot.synology.me"
    if "--adresse" in sys.argv:
        adresse = sys.argv[sys.argv.index("--adresse") + 1]
    hote = urlsplit(adresse).hostname
    contexte = ssl.create_default_context()        # le vrai certificat, vérifié

    def req(methode, chemin, corps=None, cookie=""):
        c = http.client.HTTPSConnection(hote, 443, timeout=20, context=contexte)
        h = {}
        if corps is not None:
            h["Content-Type"] = "application/x-www-form-urlencoded"
        if cookie:
            h["Cookie"] = cookie
        c.request(methode, chemin, body=corps, headers=h)
        r = c.getresponse()
        corps_r = r.read()
        return r.status, {k.lower(): v for k, v in r.getheaders()}, corps_r

    print("Le portier vu de dehors : %s" % adresse)
    # 1. sans cookie, rien ne sort
    for chemin in ["/", "/index.html", "/index.pck", "/index.wasm", "/index.js", "/index.service.worker.js",
                   "/index.png", "/portier.py", "/secret/portier.json", "/../secret/portier.json", "/.env"]:
        s, h, _ = req("GET", chemin)
        ok("sans cookie, %s ne sort pas" % chemin, s in (302, 400, 404) and (s != 302 or h.get("location", "") in ("/entree", "https://%s/entree" % hote)),
           "%d %s" % (s, h.get("location", "")))
    s, _, _ = req("GET", "/index.manifest.json")
    ok("le manifeste sort sans le code (installer en app)", s == 200, str(s))
    s, _, _ = req("GET", "/index.apple-touch-icon.png")
    ok("l'icône de l'écran d'accueil aussi", s == 200, str(s))
    # 2. la page du code, et les en-têtes
    s, h, corps = req("GET", "/entree")
    ok("la page du code répond", s == 200 and b"Le code" in corps, str(s))
    for e in ["strict-transport-security", "content-security-policy", "x-frame-options", "x-content-type-options", "referrer-policy"]:
        ok("en-tête %s" % e, e in h)
    serveur = h.get("server", "")
    ok("aucune version de logiciel annoncée", not any(ch.isdigit() for ch in serveur), serveur)
    # 3. méthodes
    s, _, _ = req("PUT", "/index.html", "x")
    ok("PUT refusé", s in (403, 405), str(s))
    s, _, _ = req("DELETE", "/")
    ok("DELETE refusé", s in (403, 405), str(s))
    # 4. un code faux, puis des essais rapprochés
    s, h, _ = req("POST", "/entrer", "code=ce+nest+pas+le+code")
    ok("un code faux : refusé", s == 303 and "e=code" in h.get("location", "") and "set-cookie" not in h, "%d %s" % (s, h.get("location", "")))
    freines = 0
    for i in range(5):
        s, _, _ = req("POST", "/entrer", "code=faux%d" % i)
        freines += s == 429
    ok("des essais rapprochés sont freinés (429)", freines >= 1, "%d freinés sur 5" % freines)
    # 5. le bon code
    time.sleep(13)          # laisser passer le frein (5 par minute)
    s, h, _ = req("POST", "/entrer", "code=" + quote_plus(code))
    cookie = h.get("set-cookie", "")
    ok("le bon code : le cookie", s == 303 and h.get("location") == "/" and "portier=" in cookie, "%d %s" % (s, h.get("location", "")))
    if cookie:
        valeur = cookie.split(";")[0]
        for c in ["Secure", "HttpOnly", "SameSite=Lax"]:
            ok("le cookie est %s" % c, c in cookie)
        s, h, corps = req("GET", "/", cookie=valeur)
        ok("avec le cookie, le jeu : index.html", s == 200 and (b"<canvas" in corps.lower() or b"godot" in corps.lower()), str(s))
        s, h, _ = req("HEAD", "/index.pck", cookie=valeur)
        ok("avec le cookie, le jeu : index.pck", s == 200 and int(h.get("content-length", "0")) > 1_000_000, "%d %s" % (s, h.get("content-length")))
        s, _, _ = req("GET", "/secret/portier.json", cookie=valeur)
        ok("même avec le cookie, le secret ne sort pas", s == 404, str(s))
    print("%d vérifications" % verifs)
    print("RESULTAT: %s" % ("OK" if erreurs == 0 else "ECHEC (%d)" % erreurs))
    sys.exit(0 if erreurs == 0 else 1)


if __name__ == "__main__":
    main()
