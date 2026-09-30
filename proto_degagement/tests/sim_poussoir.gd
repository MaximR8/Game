extends Node

# Joue la poussette 3D sans écran, en accéléré : un « joueur » lâche une pièce sur
# le bloc toutes les RYTHME secondes pendant DUREE secondes de jeu, et empoche
# chaque objet gagné une demi-seconde plus tard. On vérifie ce qui compte :
#   · rien ne s'envole ni ne sort de la machine (ni NaN) ;
#   · une fois la machine pleine, elle rend au moins la moitié de ce qu'on lui donne ;
#   · les pièces s'empilent ; les objets restent au-dessus du tas ;
#   · un objet gagné revient sur le tas, et la sauvegarde recharge le même tas.
#
#   Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path ./proto_degagement res://tests/sim_poussoir.tscn
#
# Après « -- », en option : rythme=<secondes> (0,5 par défaut). Ne sauvegarde rien.

var DUREE := 180.0               # duree=<secondes> pour changer (28/09 : le rendement de la machine, ⑧)

var p: PusherScreen
var rythme := 0.5
var graine := 20260925
var deux_jours := false          # deux_jours : le plateau vidé, le jour suivant commence sur la même machine
var jour2_a := -1.0
var jour2_nettes := 0
var jour2_fin := -1.0
var pieces_gagnees := 0
var lots_gagnes := 0
var instants: Array = []         # (29/09) l'instant de chaque pièce gagnée : les PAQUETS (tombées ensemble, à 0,25 s près)
var t_jeu := 0.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("rythme="):
			rythme = maxf(0.05, a.trim_prefix("rythme=").to_float())
		if a.begins_with("duree="):
			DUREE = maxf(10.0, a.trim_prefix("duree=").to_float())
		if a == "deux_jours":
			deux_jours = true
		if a.begins_with("graine="):               # (29/09) une autre partie, pour mesurer l'écart d'une partie à l'autre
			graine = a.trim_prefix("graine=").to_int()
		if a.begins_with("fente="):                # (29/09) la largeur des fentes à essayer
			PusherScreen.fente = a.trim_prefix("fente=").to_float()
		if a.begins_with("plateau="):              # (29/09) le frottement du plateau à essayer
			PusherScreen.frottement_plateau = a.trim_prefix("plateau=").to_float()
	GS.sauvegarde_active = false
	GS.tas_geo = 0
	GS.main_pieces = 150
	GS.poussiere = 0          # le bilan par sorte part de zéro (la sauvegarde du PC a pu en charger)
	GS.etoiles = 0
	GS.pierres = {}
	GS.voyage = {}            # un plateau du jour neuf (plateau.gd), des défis neufs
	Plateau.date_test = "2026-09-28"
	seed(graine)
	p = PusherScreen.new()
	p.size = Vector2(1080, 2400)
	add_child(p)
	p.tombe.connect(func(g: String):
		if g == "lot":
			lots_gagnes += 1
		else:
			pieces_gagnees += 1
			instants.append(t_jeu))
	_jouer()


func _jouer() -> void:
	var ok := true
	print("Départ : %d pièces, %d objets · joueur : une pièce toutes les %.2f s" % [p.pieces.size(), p.lots.size(), rythme])
	var lachees := 0
	var hors := 0
	var max_pieces := 0
	var t_semis := 0.0
	var gagnees_avant := 0
	var lachees_min := 0
	var rendement := 0.0
	var ms_somme := 0.0
	var ms_n := 0
	var avant := Time.get_ticks_usec()
	var vide_a := -1.0             # quand le plateau du jour a été vidé (⑧, 28/09), et ce qu'il a coûté en pièces
	var nettes_vide := 0
	for k in int(DUREE * 60.0):
		await get_tree().physics_frame
		t_jeu = (k + 1) / 60.0
		var maintenant := Time.get_ticks_usec()
		ms_somme += (maintenant - avant) / 1000.0
		ms_n += 1
		avant = maintenant
		t_semis += 1.0 / 60.0
		if vide_a < 0.0 and Plateau.restants() == 0:
			vide_a = (k + 1) / 60.0
			nettes_vide = lachees - pieces_gagnees
			if deux_jours:                       # (29/09) le lendemain, sur la MÊME machine : c'est le cas de tous les jours
				Plateau.date_test = "2026-09-29"
				jour2_a = vide_a
				jour2_nettes = nettes_vide
		if deux_jours and jour2_a > 0.0 and jour2_fin < 0.0 and Plateau.aujourdhui() == "2026-09-29" and Plateau.restants() == 0:
			jour2_fin = (k + 1) / 60.0
			print("Le lendemain, sur la même machine : vidé en %d s, pour %d pièces nettes" % [roundi(jour2_fin - jour2_a),
				(lachees - pieces_gagnees) - jour2_nettes])
		if t_semis >= rythme:
			t_semis = 0.0
			GS.main_pieces = 150
			var n0 := p.pieces.size()
			p.dernier_semis = Vector2(-9999, -9999)
			p._semer(Vector2(randf_range(80.0, 1000.0), randf_range(540.0, 700.0)))
			if p.pieces.size() > n0:
				lachees += 1
				lachees_min += 1
		max_pieces = maxi(max_pieces, p.pieces.size())
		if k % 3600 == 3599:
			rendement = float(pieces_gagnees - gagnees_avant) / maxf(1.0, lachees_min)
			print("  minute %d : %d lâchées, %d gagnées au bord (%d %%), %d objets gagnés, %d pièces · %.2f ms par image" % [
				(k + 1) / 3600, lachees_min, pieces_gagnees - gagnees_avant, roundi(rendement * 100.0), lots_gagnes,
				p.pieces.size(), ms_somme / ms_n])
			gagnees_avant = pieces_gagnees
			print("    dont script de physique %.2f ms · mise à jour du rendu %.2f ms" % [p.us_script / 1000.0, p.rendu.us_maj / 1000.0])
			lachees_min = 0
			ms_somme = 0.0
			ms_n = 0
		if k % 60 == 0 and k >= 120:
			for arr in [p.pieces, p.lots]:
				for b in arr:
					var q: Vector3 = b.position
					if is_nan(q.x) or is_nan(q.y) or q.x < p.X0 - 0.3 or q.x > p.X1 + 0.3 or q.y > 3.0:
						hors += 1
						print("    hors jeu : (%.2f, %.2f, %.2f) %s" % [q.x, q.y, q.z, "objet" if b.has_meta("lot") else "pièce"])
	var empilees := 0
	for b in p.pieces:
		var sol := p.H_BLOC if (b.position.z < p.face_z and b.position.z > p.MUR - 0.5) else 0.0
		if b.position.y > sol + p.EP_PIECE * 1.3:
			empilees += 1
	var couverts := 0
	for l in p.lots:
		var ep: float = l.get_meta("ep")
		for q in p.pieces:
			var dy: float = q.position.y - l.position.y
			if Vector2(q.position.x - l.position.x, q.position.z - l.position.z).length() < float(l.get_meta("r")) \
					and dy > ep * 0.4 and dy < ep * 0.5 + p.EP_PIECE * 2.0:
				couverts += 1
				break
	print("Bilan : %d lâchées · %d pièces et %d objets gagnés · %d pièces au plus · %d hors jeu · %d empilées · %d objet(s) couvert(s) · %d objets sur le tas" % [
		lachees, pieces_gagnees, lots_gagnes, max_pieces, hors, empilees, couverts, p.lots.size()])
	var sur_tas: Array = []
	for l in p.lots:
		sur_tas.append("%s%s" % [l.get_meta("lot"), " (gagné)" if l.get_meta("gagne", false) else ""])
	print("Objets : sur le tas %s · en retour %s" % [str(sur_tas), str(p.a_rendre)])
	# ce que la machine a rapporté, par sorte (⑧, 28/09) : GS part de zéro, la poussière vient par 60
	var n_pierres := 0
	for t in GS.pierres:
		n_pierres += int(GS.pierres[t])
	print("Rapporté en %d s : %d poussières (%d objets) · %d étoiles · %d pierres (dont %d lune) · plateau du jour : %d gagnés" % [
		int(DUREE), GS.poussiere, GS.poussiere / 60, GS.etoiles, n_pierres, int(GS.pierres.get("lune", 0)), Plateau.total() - Plateau.restants()])
	if vide_a > 0.0:
		print("Plateau du jour vidé en %d s, pour %d pièces nettes (lâchées moins rendues)" % [roundi(vide_a), nettes_vide])
	else:
		print("Plateau du jour PAS vidé en %d s (%d objets sur %d)" % [int(DUREE), Plateau.total() - Plateau.restants(), Plateau.total()])
	# deux objets ne se chevauchent jamais (26/09 : deux billes dessinées l'une dans l'autre)
	var chevauchent := 0
	for i in p.lots.size():
		for j in range(i + 1, p.lots.size()):
			var a1: RigidBody3D = p.lots[i]
			var a2: RigidBody3D = p.lots[j]
			var dh := Vector2(a1.position.x - a2.position.x, a1.position.z - a2.position.z).length()
			var dv := absf(a1.position.y - a2.position.y)
			if dh < (float(a1.get_meta("r")) + float(a2.get_meta("r"))) * 0.8 and dv < (float(a1.get_meta("ep")) + float(a2.get_meta("ep"))) * 0.4:
				chevauchent += 1
	print("Objets qui se chevauchent : %d" % chevauchent)
	# les paquets (29/09 — Maxim : « la satisfaction, c'est quand un gros paquet tombe d'un coup ») : les pièces gagnées
	# à moins de 0,25 s l'une de l'autre forment un paquet ; leur taille, et la part des pièces tombées en paquets de 4 et plus
	var paquets: Array = []
	var n_paq := 0
	for i in instants.size():
		if i == 0 or float(instants[i]) - float(instants[i - 1]) > 0.25:
			if n_paq > 0:
				paquets.append(n_paq)
			n_paq = 0
		n_paq += 1
	if n_paq > 0:
		paquets.append(n_paq)
	var gros := 0
	var dans_gros := 0
	var plus_gros := 0
	for n in paquets:
		plus_gros = maxi(plus_gros, n)
		if n >= 4:
			gros += 1
			dans_gros += n
	print("Tombées DEVANT sans être comptées : %d (gagnées : %d)" % [p.ratees_au_bord, pieces_gagnees])
	print("Supernovas : %d (%s) · cœurs d'étoile gagnés : %d" % [p.supernovas, ("une toutes les %.1f min" % (DUREE / 60.0 / p.supernovas)) if p.supernovas > 0 else "aucune", GS.coeurs])
	print("Entrechocs : %d (%.1f par minute)" % [p.entrechocs, p.entrechocs / (DUREE / 60.0)])
	print("Fentes : %d pièces perdues (%d %% de ce qui a quitté le plateau)" % [p.perdues, roundi(100.0 * p.perdues / maxf(1.0, p.perdues + pieces_gagnees))])
	print("Paquets : %d chutes · %.1f pièces par chute · %d paquets de 4 et plus (%d %% des pièces) · le plus gros : %d" % [
		paquets.size(), float(instants.size()) / maxf(1.0, paquets.size()), gros, roundi(100.0 * dans_gros / maxf(1.0, instants.size())), plus_gros])
	if chevauchent > 0:
		ok = false
	# (29/09) TOUT le plateau du jour est posé : autant d'objets sur le tas qu'il en reste à gagner aujourd'hui
	var attendus := Plateau.a_poser().size()
	var coeurs_sur_tas := 0                # (30/09) un cœur d'étoile (la Supernova) n'est pas du plateau du jour
	for l in p.lots:
		if str(l.get_meta("lot")) == "coeur-etoile":
			coeurs_sur_tas += 1
	print("Objets attendus sur le tas : %d (tout ce qu'il reste à gagner aujourd'hui)" % attendus)
	# (30/09) le rendement sur TOUTE la partie : avec les fentes (~30 % sur les côtés), une minute creuse peut passer sous la
	# moitié sans que la machine aille mal
	var rendement_total := float(pieces_gagnees) / maxf(1.0, lachees)
	print("Rendement sur la partie : %d %%" % roundi(rendement_total * 100.0))
	if hors > 0 or rendement_total < 0.5 or empilees == 0 or couverts > 1 or p.lots.size() - coeurs_sur_tas + p.a_rendre.size() != attendus:
		ok = false
	# la sauvegarde : le même tas revient
	p._sauver()
	var n_avant := p.pieces.size()
	var p2 := PusherScreen.new()
	p2.size = Vector2(1080, 2400)
	add_child(p2)
	print("Rechargé : %d pièces (sauvées : %d), %d objets" % [p2.pieces.size(), n_avant, p2.lots.size()])
	if absi(p2.pieces.size() - n_avant) > 2 or p2.lots.size() - coeurs_sur_tas != attendus:
		ok = false
	print("RESULTAT: " + ("OK" if ok else "ECHEC"))
	get_tree().quit(0 if ok else 1)


func _diag() -> void:
	var zones := {"bloc": 0, "avant": 0, "milieu": 0, "bord": 0}
	var h := {}
	for b in p.pieces:
		var z: float = b.position.z
		var k := "bloc" if z < p.face_z else ("avant" if z < 10.5 else ("milieu" if z < 12.5 else "bord"))
		zones[k] += 1
		var e := int(b.position.y / p.EP_PIECE)
		h[e] = int(h.get(e, 0)) + 1
	print("    diag · %s · étages %s · bloc en %.2f" % [zones, h, p.face_z])
