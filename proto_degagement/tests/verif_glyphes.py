# -*- coding: utf-8 -*-
"""Le contrôle des glyphes (28/09) : chaque caractère des textes entre guillemets des scripts donnés doit exister dans
les trois Castoro (ou dans la police de secours de l'étoile). Sur le téléphone, un glyphe absent sort en BOÎTE, et le PC,
lui, le rattrapait : les captures ne voyaient rien (START_HERE § L'écran). Vu le 28/09 : « → » en boîte.

    python proto_degagement/tests/verif_glyphes.py proto_degagement/carre/*.gd proto_degagement/*.gd

Attendu : « absents des polices : aucun ». Le témoin : un fichier qui contient « → » doit le signaler."""
import re, sys, os
from fontTools.ttLib import TTFont

ICI = os.path.dirname(os.path.abspath(__file__))
POLICES = os.path.join(ICI, "..", "polices")
cmaps = [TTFont(os.path.join(POLICES, f)).getBestCmap() for f in ["Castoro.ttf", "Castoro-Italic.ttf", "CastoroTitling-Regular.ttf"]]
etoile = TTFont(os.path.join(POLICES, "Etoile.ttf")).getBestCmap()
manque = {}
n = 0
for f in sys.argv[1:]:
    for i, l in enumerate(open(f, encoding="utf-8"), 1):
        if l.strip().startswith("#"):
            continue
        for s in re.findall('"([^"]*)"', l):
            for ch in s:
                n += 1
                if ord(ch) > 127 and not all(ord(ch) in c for c in cmaps) and ord(ch) not in etoile:
                    manque.setdefault(ch, []).append("%s:%d" % (f, i))
print(n, "caractères lus ; absents des polices :", {k: (hex(ord(k)), v[:3]) for k, v in manque.items()} or "aucun")
sys.exit(1 if manque else 0)
