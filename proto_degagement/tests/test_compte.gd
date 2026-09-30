extends Node

# Le test du compte (29/09, ⑥) — CONTRE LE VRAI SERVEUR (https://lapoussette.duckdns.org) : un compte d'appareil neuf,
# une partie envoyée puis relue à l'identique, la même partie retrouvée par une seconde connexion ; le compte lié à un mail
# (29/09), retrouvé sur un « autre téléphone » avec sa partie ; les refus (mot de passe court, mail pris, faux, inconnu) ;
# puis les comptes EFFACÉS (rien ne reste). Sans réseau : ÉCHEC (c'est ce qu'on veut savoir).
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --path ./proto_degagement res://tests/test_compte.tscn

var erreurs := 0
var verifs := 0


func _ok(quoi: String, vrai: bool) -> void:
	verifs += 1
	print("%s : %s" % [quoi, "OK" if vrai else "ÉCHEC"])
	if not vrai:
		erreurs += 1


func _appareil() -> Compte:
	var x := Compte.new()
	x.actif = false
	add_child(x)
	x.appareil = "essai-" + Crypto.new().generate_random_bytes(12).hex_encode()
	return x


func _ready() -> void:
	GS.sauvegarde_active = false          # le vrai fichier de partie n'est jamais touché
	GS.etoiles = 7
	GS.poussiere = 1234
	GS.main_pieces = 42
	var c := Compte.new()
	c.actif = false                       # pas de compte.cfg écrit, pas d'envoi automatique…
	add_child(c)
	c.appareil = "essai-" + Crypto.new().generate_random_bytes(12).hex_encode()   # … un appareil d'essai, neuf
	var t0 := Time.get_ticks_msec()
	_ok("un compte d'appareil créé", await c.connecter() and c.utilisateur != "")
	print("  (réponse en %d ms)" % (Time.get_ticks_msec() - t0))
	_ok("la partie envoyée", await c.envoyer())
	var lu := await c.lire()
	_ok("relue à l'identique (%s)" % str([lu.get("etoiles"), lu.get("poussiere"), lu.get("main_pieces")]),
		int(lu.get("etoiles", -1)) == 7 and int(lu.get("poussiere", -1)) == 1234 and int(lu.get("main_pieces", -1)) == 42
		and int(lu.get("maj", 0)) > 0)
	var u := c.utilisateur
	c.jeton = ""
	_ok("le même appareil retrouve le même compte", await c.connecter() and c.utilisateur == u)
	GS.etoiles = 8
	_ok("une nouvelle version remplace l'ancienne", await c.envoyer() and int((await c.lire()).get("etoiles", -1)) == 8)
	# ── lier par mail (29/09) : retrouver sa partie sur un autre téléphone
	var adresse := "essai-%s@lapoussette.test" % Crypto.new().generate_random_bytes(5).hex_encode()
	var mdp := "essai-" + Crypto.new().generate_random_bytes(6).hex_encode()
	_ok("lier le compte à un mail", await c.lier_mail(adresse, mdp) == "" and c.mail == adresse)
	var autre := _appareil()
	await autre.connecter()
	_ok("un mot de passe trop court : refusé (%s)" % await autre.lier_mail("x" + adresse, "court"), await autre.lier_mail("y" + adresse, "court") == "mdp_court")
	_ok("un mail qui a déjà un compte : refusé", await autre.lier_mail(adresse, mdp) == "pris")
	var neuf := _appareil()
	await neuf.connecter()
	_ok("un mauvais mot de passe : refusé", str((await neuf.retrouver(adresse, "mauvais-mdp")).get("erreur")) == "mdp")
	_ok("un mail sans compte : refusé", str((await neuf.retrouver("personne-" + adresse, mdp)).get("erreur")) == "inconnu")
	var t := await neuf.retrouver(adresse, mdp)
	_ok("le bon mail : la partie retrouvée (★ %s)" % str((t.get("partie", {}) as Dictionary).get("etoiles")), str(t.get("erreur")) == "" and int((t["partie"] as Dictionary).get("etoiles", -1)) == 8)
	_ok("le nouveau téléphone rejoint le compte", await neuf.adopter(t) and neuf.utilisateur == u and neuf.mail == adresse)
	neuf.jeton = ""
	_ok("… et le retrouve tout seul au lancement suivant", await neuf.connecter() and neuf.utilisateur == u and neuf.mail == adresse)
	_ok("les comptes d'essai effacés", await neuf.effacer() and await autre.effacer())
	print("%d vérifications" % verifs)
	print("RESULTAT: %s" % ("OK" if erreurs == 0 else "ECHEC (%d)" % erreurs))
	get_tree().quit(0 if erreurs == 0 else 1)
