"""
Le test du portier (⑯, 27/09) — un vrai serveur, lancé ici avec un secret de test.

    python portier/test_portier.py            (depuis _NOUVEAU_PROJET)

Chaque règle a ses deux témoins (ce qui passe, ce qui est refusé) :
  · le code : juste (même tapé en majuscules, avec des tirets ou des accents), faux ;
  · le cookie : signé et à jour (entre), expiré, retouché, d'une autre clé, absent (refusés) ;
  · les essais : 10 échecs en une heure → cette adresse est bloquée, même avec le bon code, mais
    une autre adresse entre encore ; 50 échecs en tout → plus personne ; une heure après → rouvert ;
  · un corps trop gros, une autre adresse que /entrer, une méthode inconnue : refusés ;
  · la page du code : ses messages, et rien de ce qu'on tape n'y est recopié.
Attendu : « RESULTAT: OK ».
"""

import hashlib
import http.client
import json
import os
import sys
import tempfile
import threading
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import portier  # noqa: E402

CODE = "lune dragon sel mons brume"
erreurs = 0
verifs = 0


def ok(quoi, vrai):
    global erreurs, verifs
    verifs += 1
    if not vrai:
        erreurs += 1
        print("  ✗ " + quoi)


def secret_de_test(dossier, code, cle=b"k" * 32):
    sel = b"s" * 16
    d = {"sel": sel.hex(), "empreinte": hashlib.pbkdf2_hmac("sha256", portier.normaliser(code).encode(), sel, 1000).hex(),
         "iterations": 1000, "cle": cle.hex()}
    chemin = os.path.join(dossier, "portier.json")
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(d, f)
    return chemin


def requete(port, methode, chemin, corps=None, entetes=None):
    c = http.client.HTTPConnection("127.0.0.1", port, timeout=10)
    h = dict(entetes or {})
    if corps is not None:
        h["Content-Type"] = "application/x-www-form-urlencoded"
    c.request(methode, chemin, body=corps, headers=h)
    r = c.getresponse()
    return r.status, dict(r.getheaders()), r.read().decode("utf-8", "replace")


def main():
    # ─── les pièces, sans serveur ───
    ok("normaliser : casse, tirets, accents, espaces", portier.normaliser("  Lune-Dragon_SEL  mons  Brümé ") == "lune dragon sel mons brume")
    cle = b"x" * 32
    maintenant = 1_800_000_000
    c = portier.cookie_neuf(cle, maintenant)
    ok("un cookie neuf est valide", portier.cookie_valide(c, cle, maintenant + 10))
    ok("expiré après 90 jours", not portier.cookie_valide(c, cle, maintenant + portier.DUREE_COOKIE + 1))
    expire, sig = c.split(".")
    ok("retouché (on repousse l'expiration) : refusé", not portier.cookie_valide("%d.%s" % (int(expire) + 999999, sig), cle, maintenant))
    ok("d'une autre clé (le code a changé) : refusé", not portier.cookie_valide(c, b"y" * 32, maintenant))
    ok("n'importe quoi : refusé", not portier.cookie_valide("abc", cle) and not portier.cookie_valide("", cle)
       and not portier.cookie_valide(None, cle))
    ok("le cookie se lit parmi d'autres", portier.lire_cookie("a=1; portier=zz; b=2") == "zz" and portier.lire_cookie(None) == "")

    g = portier.Garde()
    t0 = 1_000_000.0
    for i in range(portier.ECHECS_PAR_ADRESSE - 1):
        g.echec("1.1.1.1", t0 + i)
    ok("9 échecs : on écoute encore", g.refuse("1.1.1.1", t0 + 20) == "")
    g.echec("1.1.1.1", t0 + 21)
    ok("10 échecs : cette adresse est bloquée", g.refuse("1.1.1.1", t0 + 22) == "bloque")
    ok("…une autre adresse, non", g.refuse("2.2.2.2", t0 + 22) == "")
    ok("une heure après : rouverte", g.refuse("1.1.1.1", t0 + 21 + portier.FENETRE + 1) == "")
    g2 = portier.Garde()
    for i in range(portier.ECHECS_EN_TOUT):
        g2.echec("10.0.0.%d" % (i % 40), t0 + i)
    ok("50 échecs en tout (40 adresses) : fermé pour tous", g2.refuse("9.9.9.9", t0 + 60) == "ferme")

    # ─── un vrai serveur ───
    dossier = tempfile.mkdtemp()
    chemin = secret_de_test(dossier, CODE)
    secret = portier.Secret(chemin)
    garde = portier.Garde()
    lignes = []
    serveur = portier.ThreadingHTTPServer(("127.0.0.1", 0), portier.fabriquer(secret, garde, lignes.append))
    port = serveur.server_address[1]
    threading.Thread(target=serveur.serve_forever, daemon=True).start()

    s, h, _ = requete(port, "GET", "/verifier")
    ok("sans cookie : 401", s == 401)
    s, h, _ = requete(port, "POST", "/entrer", "code=mauvais+code", {"X-Real-IP": "5.5.5.5"})
    ok("code faux : renvoyé vers la page, avec le message", s == 303 and h.get("Location") == "/entree?e=code" and "Set-Cookie" not in h)
    s, h, _ = requete(port, "POST", "/entrer", "code=LUNE-Dragon-sel-MONS-brume", {"X-Real-IP": "5.5.5.5"})
    ok("code juste (majuscules, tirets) : cookie, et vers le jeu", s == 303 and h.get("Location") == "/" and "Set-Cookie" in h)
    cookie = h.get("Set-Cookie", "")
    ok("le cookie : Secure, HttpOnly, SameSite, 90 jours", all(x in cookie for x in ["Secure", "HttpOnly", "SameSite=Lax", "Max-Age=7776000", "Path=/"]))
    valeur = cookie.split(";")[0]
    s, _, _ = requete(port, "GET", "/verifier", entetes={"Cookie": valeur})
    ok("avec ce cookie : 204", s == 204)
    s, _, _ = requete(port, "GET", "/verifier", entetes={"Cookie": valeur[:-1] + ("0" if valeur[-1] != "0" else "1")})
    ok("cookie retouché d'un caractère : 401", s == 401)

    # le code change (nouvelle clé) : l'ancien cookie tombe
    time.sleep(0.05)
    secret_de_test(dossier, "autre code tout neuf ici", cle=b"n" * 32)
    os.utime(chemin, (time.time() + 5, time.time() + 5))
    s, _, _ = requete(port, "GET", "/verifier", entetes={"Cookie": valeur})
    ok("nouveau code : l'ancien cookie ne passe plus", s == 401)
    s, h, _ = requete(port, "POST", "/entrer", "code=" + CODE.replace(" ", "+"), {"X-Real-IP": "5.5.5.5"})
    ok("nouveau code : l'ancien code non plus", h.get("Location") == "/entree?e=code")
    secret_de_test(dossier, CODE)
    os.utime(chemin, (time.time() + 10, time.time() + 10))

    # 10 échecs pour une adresse : bloquée, même avec le bon code
    for i in range(portier.ECHECS_PAR_ADRESSE):
        requete(port, "POST", "/entrer", "code=faux%d" % i, {"X-Real-IP": "6.6.6.6"})
    s, h, _ = requete(port, "POST", "/entrer", "code=" + CODE.replace(" ", "+"), {"X-Real-IP": "6.6.6.6"})
    ok("bloquée : même le bon code est refusé", h.get("Location") == "/entree?e=bloque" and "Set-Cookie" not in h)
    s, h, _ = requete(port, "POST", "/entrer", "code=" + CODE.replace(" ", "+"), {"X-Real-IP": "7.7.7.7"})
    ok("…une autre adresse entre toujours", "Set-Cookie" in h)

    # les refus de forme
    s, _, _ = requete(port, "POST", "/entrer", "code=" + "x" * 600, {"X-Real-IP": "8.8.8.8"})
    ok("un corps trop gros : 413", s == 413)
    s, _, _ = requete(port, "POST", "/verifier", "code=x")
    ok("POST ailleurs que /entrer : 404", s == 404)
    s, _, _ = requete(port, "PUT", "/entrer", "code=x")
    ok("une autre méthode : refusée", s in (400, 405, 501))
    s, _, _ = requete(port, "GET", "/secret/portier.json")
    ok("le secret ne se sert pas", s == 404)

    # la page
    s, h, corps = requete(port, "GET", "/entree?e=bloque")
    ok("la page du code : 200, et le message du blocage", s == 200 and "une heure" in corps and h.get("Cache-Control") == "no-store")
    s, h, corps = requete(port, "GET", "/entree?e=<script>alert(1)</script>")
    ok("la page ne recopie rien de ce qu'on tape", "<script>alert" not in corps)
    ok("le journal : les essais, pas les codes tapés", any("code faux" in l for l in lignes) and not any("faux3" in l or "mauvais" in l for l in lignes))

    # 50 échecs en tout : plus personne
    for i in range(portier.ECHECS_EN_TOUT):
        requete(port, "POST", "/entrer", "code=z", {"X-Real-IP": "20.0.%d.%d" % (i // 9, i % 9)})
    s, h, _ = requete(port, "POST", "/entrer", "code=" + CODE.replace(" ", "+"), {"X-Real-IP": "30.3.3.3"})
    ok("50 échecs en tout : l'entrée est fermée, même au bon code", h.get("Location") == "/entree?e=ferme")

    serveur.shutdown()
    print("%d vérifications" % verifs)
    print("RESULTAT: %s" % ("OK" if erreurs == 0 and verifs > 0 else "ECHEC (%d)" % erreurs))
    sys.exit(0 if erreurs == 0 else 1)


if __name__ == "__main__":
    main()
