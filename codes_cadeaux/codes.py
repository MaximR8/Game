# -*- coding: utf-8 -*-
"""Les codes cadeaux du jeu (29/09/2026) — Maxim les crée ici ; le jeu les lit sur le NAS, sans réexport.

    python codes_cadeaux/codes.py ajouter NOEL2026 --etoiles 10 --fin 2026-12-31
    python codes_cadeaux/codes.py ajouter --etoiles 5 --poussiere 300          # un code tiré au hasard, qui s'affiche
    python codes_cadeaux/codes.py ajouter BIENVENUE --pierre lune=2 --eclats 50
    python codes_cadeaux/codes.py liste
    python codes_cadeaux/codes.py retirer NOEL2026
    python codes_cadeaux/codes.py publier                                       # remettre la table sur le serveur

Deux fichiers, et le serveur :
  · codes_cadeaux/registre.json — le PRIVÉ : les codes en clair, pour s'en souvenir. Jamais servi (hors de web/). Il garde
                                  aussi l'identifiant SECRET de « l'administrateur des codes » (un compte du serveur).
  · web/codes/codes.json        — le PUBLIC, lu par le jeu web du NAS (le secours) : seulement l'empreinte de chaque code
                                  (SHA-256 du sel et du code normalisé), sa récompense, sa date de fin. Le lire ne donne
                                  aucun code.
  · le SERVEUR (01/10 — l'app n'a pas de site à côté d'elle : « il me dit que je suis pas en ligne ») : la même table,
    posée sur Nakama (https://lapoussette.duckdns.org) par l'administrateur des codes, lisible par tout joueur connecté
    (collection « config », clé « codes ») — le jeu la lit là d'abord (Codes.lire_table).
Récompenses : --etoiles, --poussiere, --pieces, --eclats, --pierre <type>=<n> (feu, foudre, eau, glace, nature, esprit, lune).
Un code vaut une fois par partie (le jeu retient ceux qu'il a pris). Normalisé : majuscules, sans espace ni tiret.
"""
import argparse, base64, hashlib, json, os, secrets, sys, urllib.request

SERVEUR = "https://lapoussette.duckdns.org"
CLE_JEU = "a384cd768c354b22ec3ed13dc738b741"        # la clé du jeu (elle est dans tout client : pas un secret)

ICI = os.path.dirname(os.path.abspath(__file__))
REGISTRE = os.path.join(ICI, "registre.json")
PUBLIC = os.path.join(ICI, "..", "web", "codes", "codes.json")
PIERRES = ["feu", "foudre", "eau", "glace", "nature", "esprit", "lune"]
LETTRES = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"        # sans I, O, 0, 1 : rien à confondre en le recopiant


def normaliser(code):
    return "".join(c for c in code.upper() if c.isascii() and c.isalnum())


def empreinte(code, sel):
    return hashlib.sha256((sel + normaliser(code)).encode("utf-8")).hexdigest()


def ecrire(chemin, donnees):
    """Dans un .tmp, puis on renomme (une écriture coupée ne laisse jamais un fichier vide)."""
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    tmp = chemin + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=1)
    if os.path.getsize(tmp) == 0:
        sys.exit("écriture vide : rien n'est remplacé")
    os.replace(tmp, chemin)


def lire_registre():
    if os.path.exists(REGISTRE):
        with open(REGISTRE, encoding="utf-8") as f:
            return json.load(f)
    return {"sel": secrets.token_hex(16), "codes": {}}


def _demander(methode, chemin, corps, jeton=None):
    entetes = {"Content-Type": "application/json"}
    if jeton:
        entetes["Authorization"] = "Bearer " + jeton
    else:
        entetes["Authorization"] = "Basic " + base64.b64encode((CLE_JEU + ":").encode()).decode()
    r = urllib.request.Request(SERVEUR + chemin, data=None if corps is None else json.dumps(corps).encode(),
                               headers=entetes, method=methode)
    with urllib.request.urlopen(r, timeout=20) as rep:
        return json.loads(rep.read().decode() or "{}")


def publier_serveur(pub, reg):
    """La table sur le serveur : l'administrateur des codes (un compte d'appareil, son identifiant secret dans le registre)
    y pose l'objet « config/codes », lisible par tous (permission_read 2), modifiable par lui seul."""
    if "admin_appareil" not in reg:
        reg["admin_appareil"] = "admin-codes-" + secrets.token_hex(24)
    jeton = _demander("POST", "/v2/account/authenticate/device?create=true", {"id": reg["admin_appareil"]})["token"]
    compte = _demander("GET", "/v2/account", None, jeton)
    reg["admin_id"] = compte["user"]["id"]
    _demander("PUT", "/v2/storage", {"objects": [{"collection": "config", "key": "codes", "value": json.dumps(pub),
                                                   "permission_read": 2, "permission_write": 1}]}, jeton)
    return reg["admin_id"]


def publier(reg):
    pub = {"v": 1, "sel": reg["sel"], "codes": {}}
    for code, e in reg["codes"].items():
        pub["codes"][empreinte(code, reg["sel"])] = {"recompense": e["recompense"], "fin": e.get("fin", "")}
    ecrire(PUBLIC, pub)
    try:
        admin = publier_serveur(pub, reg)
        print("sur le serveur (l'app, le web) : OK — administrateur des codes %s" % admin)
    except Exception as e:
        print("⚠️ le serveur n'a pas pu être mis à jour (%s) : relance « python codes_cadeaux/codes.py publier »" % e)
    ecrire(REGISTRE, reg)


def main(argv=None):
    # la console de Windows (cp1252) ne sait pas écrire « → » ni certains accents : on lui parle en UTF-8
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
    ap = argparse.ArgumentParser(description="Les codes cadeaux du jeu")
    sous = ap.add_subparsers(dest="action", required=True)
    a = sous.add_parser("ajouter")
    a.add_argument("code", nargs="?", default="")
    for cle in ["etoiles", "poussiere", "pieces", "eclats"]:
        a.add_argument("--" + cle, type=int, default=0)
    a.add_argument("--pierre", action="append", default=[], help="type=nombre, ex. lune=2")
    a.add_argument("--fin", default="", help="dernier jour, AAAA-MM-JJ (vide : jamais)")
    a.add_argument("--note", default="", help="pour toi seul (registre privé)")
    sous.add_parser("liste")
    sous.add_parser("publier")
    r = sous.add_parser("retirer")
    r.add_argument("code")
    args = ap.parse_args(argv)

    reg = lire_registre()
    if args.action == "publier":
        publier(reg)
        return 0
    if args.action == "liste":
        if not reg["codes"]:
            print("aucun code")
        for code, e in sorted(reg["codes"].items()):
            print("%-14s %-40s fin %-10s %s" % (code, json.dumps(e["recompense"], ensure_ascii=False), e.get("fin") or "jamais", e.get("note", "")))
        return 0
    if args.action == "retirer":
        code = normaliser(args.code)
        if code not in reg["codes"]:
            sys.exit("%s : pas dans le registre" % code)
        del reg["codes"][code]
        publier(reg)
        print("retiré : %s" % code)
        return 0

    code = normaliser(args.code) or "".join(secrets.choice(LETTRES) for _ in range(8))
    if len(code) < 4:
        sys.exit("un code fait au moins 4 lettres ou chiffres")
    if code in reg["codes"]:
        sys.exit("%s existe déjà (retire-le d'abord)" % code)
    rec = {cle: getattr(args, cle) for cle in ["etoiles", "poussiere", "pieces", "eclats"] if getattr(args, cle) > 0}
    pierres = {}
    for p in args.pierre:
        t, _, n = p.partition("=")
        if t not in PIERRES or not n.isdigit() or int(n) <= 0:
            sys.exit("--pierre %s : attendu type=nombre, type parmi %s" % (p, ", ".join(PIERRES)))
        pierres[t] = int(n)
    if pierres:
        rec["pierres"] = pierres
    if not rec:
        sys.exit("un code donne quelque chose : --etoiles, --poussiere, --pieces, --eclats ou --pierre")
    if args.fin and (len(args.fin) != 10 or args.fin[4] != "-" or args.fin[7] != "-"):
        sys.exit("--fin : AAAA-MM-JJ")
    reg["codes"][code] = {"recompense": rec, "fin": args.fin, "note": args.note}
    publier(reg)
    print("CODE : %s  →  %s%s" % (code, json.dumps(rec, ensure_ascii=False), ("  (jusqu'au %s)" % args.fin) if args.fin else ""))
    print("en ligne tout de suite — dans l'app (le serveur) et sur le web (web/codes/codes.json)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
