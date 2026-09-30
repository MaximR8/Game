class_name Reglages
extends RefCounted

# ─────────────────────────────────────────────────────────────
# LES RÉGLAGES (29/09 — la page Menu des Présages) : le volume de la musique, celui des effets, les vibrations.
# Ils suivent l'APPAREIL, pas la partie : un fichier à part (user://reglages.cfg), jamais dans la sauvegarde du jeu
# (qui voyagera vers un serveur avec les comptes, alors que « couper le son » vaut pour ce téléphone-ci).
# Le son passe par deux bus, créés au lancement : « Musique » et « Effets » (le volume de chacun, ici).
# 🔴 Toute vibration passe par Reglages.vibrer : couper les vibrations les coupe partout.
# ─────────────────────────────────────────────────────────────

const CHEMIN := "user://reglages.cfg"
const BUS := ["Musique", "Effets"]

static var musique := 0.5          # 29/09, Maxim : « le son général à 50 par défaut »
static var effets := 0.8
static var vibrations := true
static var actif := true            # les tests coupent l'écriture du fichier


static func charger() -> void:
	var c := ConfigFile.new()
	if c.load(CHEMIN) == OK:
		musique = clampf(float(c.get_value("son", "musique", musique)), 0.0, 1.0)
		effets = clampf(float(c.get_value("son", "effets", effets)), 0.0, 1.0)
		vibrations = bool(c.get_value("jeu", "vibrations", vibrations))
	appliquer()


static func sauver() -> void:
	appliquer()
	if not actif:
		return
	var c := ConfigFile.new()
	c.set_value("son", "musique", musique)
	c.set_value("son", "effets", effets)
	c.set_value("jeu", "vibrations", vibrations)
	c.save(CHEMIN)


# Les deux bus existent, à leur volume ; à zéro, muets.
# 🔴 LES BUS SONT DÉCLARÉS DANS LE PROJET (default_bus_layout.tres), PAS CRÉÉS EN COURS DE PARTIE (29/09 — « j'entends pas
#    le son ») : sur le web, les sons sont des échantillons du navigateur, et un bus ajouté par add_bus() n'y était relié
#    à rien — les sons partaient (mesuré dans Chrome : 14 démarrés, aux bons volumes), la sortie restait à −120 dB. La
#    création ici ne reste qu'en secours (un projet sans le fichier).
static func appliquer() -> void:
	for nom in BUS:
		var i := AudioServer.get_bus_index(nom)
		if i < 0:
			AudioServer.add_bus()
			i = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nom)
			AudioServer.set_bus_send(i, "Master")
		var v := musique if nom == "Musique" else effets
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(i, v <= 0.001)


static func vibrer(ms: int) -> void:
	if vibrations:
		Input.vibrate_handheld(ms)
