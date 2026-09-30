"""
Un nouveau code d'accès au jeu public (⑯, 27/09).

    python portier/nouveau_code.py            (depuis _NOUVEAU_PROJET, sur le PC ou sur le NAS)

Tire 5 mots au hasard (le module `secrets`, pas `random`), écrit portier/secret/portier.json :
l'empreinte du code (PBKDF2-SHA256, salée), et une NOUVELLE clé pour signer les cookies — tous
les cookies d'avant tombent : tout le monde doit taper le nouveau code. Le portier relit le fichier
tout seul (pas besoin de le redémarrer).
🔴 Le code s'affiche UNE fois, ici. Il n'est écrit nulle part en clair.
"""

import hashlib
import json
import os
import secrets
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from portier import normaliser  # noqa: E402

ITERATIONS = 200_000
NB_MOTS = 5

# Des mots courts, sans accent (un clavier de téléphone), faciles à dicter.
MOTS = """
abeille ancre anneau arbre argent avion bague baleine balle bambou banane bateau berger biscuit bison
bougie boussole bouton brume bulle cabane cactus camion canard canyon carotte carte castor caverne cerf
cerise chaise chameau chapeau chat chateau cheval chien chouette cigale citron clairiere cloche cobra
colline comete coquille corbeau corde crabe crayon cygne dauphin desert diamant dragon dune eclair
ecureuil elephant eponge fable falaise faucon fenetre flamme fleur flute fontaine foret fougere fourmi
fraise fromage fusee galaxie galet gateau gazelle geant girafe givre glace glacier gomme gorille grenier
griffe grotte guitare hamac harpe herisson hibou horloge iceberg igloo jaguar jardin jonquille kiwi koala
lagon lampe lanterne lapin lavande lezard licorne lilas lion loup loutre lune lutin lynx marmotte marron
meduse melon meteore miel miroir mouette moulin mouton narval nenuphar nuage oasis oiseau olive orage
orange orque ours palmier panda panthere paon papillon parapluie pelican perle phare piano pierre pigeon
pingouin pirate pivoine planete plume poisson pomme pont poulpe prairie puma radis rayon renard requin
riviere robot rocher rose roseau ruban rubis sable safran sapin saphir saule sequoia serpent singe sirene
sorcier source spirale statue tambour tempete tigre tomate tonnerre topaze tortue toucan tournesol tresor
trefle tulipe tunnel vague vallee vanille velours vent verger violon voile volcan yeti zebre zephyr
""".split()


def main():
    assert len(set(MOTS)) == len(MOTS) >= 200, "la liste de mots a des doublons ou est trop courte"
    code = " ".join(secrets.choice(MOTS) for _ in range(NB_MOTS))
    sel = secrets.token_bytes(16)
    donnees = {
        "sel": sel.hex(),
        "empreinte": hashlib.pbkdf2_hmac("sha256", normaliser(code).encode("utf-8"), sel, ITERATIONS).hex(),
        "iterations": ITERATIONS,
        "cle": secrets.token_bytes(32).hex(),
    }
    dossier = os.path.join(os.path.dirname(os.path.abspath(__file__)), "secret")
    os.makedirs(dossier, exist_ok=True)
    cible = os.path.join(dossier, "portier.json")
    with open(cible + ".tmp", "w", encoding="utf-8") as f:
        json.dump(donnees, f)
    os.replace(cible + ".tmp", cible)
    if os.path.getsize(cible) < 100:
        raise SystemExit("ÉCHEC : le secret écrit est vide")
    print("Nouveau code : %s" % code.replace(" ", "-"))
    print("(%d mots parmi %d : %.0f bits ; secret écrit dans %s)" % (NB_MOTS, len(MOTS), NB_MOTS * __import__("math").log2(len(MOTS)), cible))


if __name__ == "__main__":
    main()
