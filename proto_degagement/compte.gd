class_name Compte
extends Node

# ─────────────────────────────────────────────────────────────
# LE COMPTE (29/09 — ⑥ ; le serveur : docs/ops/INFRA.md § le serveur des comptes, Nakama sur le VPS de Maxim).
#
# Chaque appareil a son compte, créé sans rien demander : un identifiant tiré au hasard la première fois, gardé dans
# user://compte.cfg (comme les Réglages : il suit l'APPAREIL, jamais dans la sauvegarde du jeu). La partie reste écrite sur
# le téléphone comme avant (GS.save_game) ; elle part AUSSI au serveur, en arrière-plan : au plus une fois par ENVOI_S,
# et tout de suite quand l'app passe en arrière-plan.
# 🔴 LE JEU N'ATTEND JAMAIS LE SERVEUR : rien ne bloque, rien ne s'affiche en erreur ; sans réseau, on réessaie plus tard.
# 🔴 L'app ne parle QU'À Nakama, jamais à la base (FEATURES ligne 6) ; la clé ci-dessous est celle du JEU (elle est dans
#    tout client : pas un secret — les vrais secrets restent dans /opt/lapoussette/.env sur le VPS).
# Les tests (GS.sauvegarde_active = false) ne touchent ni au réseau ni au fichier — sauf tests/test_compte.gd.
# La suite : lier le compte par mail, puis Google (retrouver sa partie sur un autre téléphone).
# ─────────────────────────────────────────────────────────────

signal change

const SERVEUR := "https://lapoussette.duckdns.org"
const CLE := "a384cd768c354b22ec3ed13dc738b741"
const CHEMIN := "user://compte.cfg"
const ENVOI_S := 60.0
const RECONNEXION_S := 60.0      # (01/10) hors ligne au lancement : on retente, sans attendre une sauvegarde
const COLLECTION := "partie"
const CLE_PARTIE := "sauvegarde"

static var global: Compte

var appareil := ""           # l'identifiant de cet appareil (créé une fois)
var utilisateur := ""        # l'identifiant du compte sur le serveur
var mail := ""               # le mail lié au compte ("" : pas encore lié)
var jeton := ""              # la session (en mémoire seulement)
var envoye_le := 0           # quand la partie est partie au serveur pour la dernière fois (heure unix)
var en_ligne := false        # la dernière demande au serveur a-t-elle abouti ?
var actif := true            # faux dans les tests : ni réseau, ni fichier
var _a_envoyer := false
var _depuis := 0.0
var _en_cours := false
var _depuis_essai := 0.0
var _essai_en_cours := false


func _ready() -> void:
	actif = actif and GS.sauvegarde_active
	if not actif:
		return
	_charger()
	connecter()


func _charger() -> void:
	var c := ConfigFile.new()
	if c.load(CHEMIN) == OK:
		appareil = str(c.get_value("compte", "appareil", ""))
		envoye_le = int(c.get_value("compte", "envoye_le", 0))
	if appareil.length() < 16:
		appareil = "poussette-" + Crypto.new().generate_random_bytes(16).hex_encode()
		_ecrire()


func _ecrire() -> void:
	if not actif:
		return
	var c := ConfigFile.new()
	c.set_value("compte", "appareil", appareil)
	c.set_value("compte", "envoye_le", envoye_le)
	c.save(CHEMIN)


# Le compte de l'appareil : créé la première fois, retrouvé ensuite (le serveur connaît l'identifiant).
func connecter() -> bool:
	var r := await _demander(HTTPClient.METHOD_POST, "/v2/account/authenticate/device?create=true", {"id": appareil}, true)
	if r["code"] != 200 or str(r["donnees"].get("token", "")) == "":
		en_ligne = false
		change.emit()
		return false
	jeton = str(r["donnees"]["token"])
	var a := await _demander(HTTPClient.METHOD_GET, "/v2/account")
	if a["code"] == 200:
		utilisateur = str((a["donnees"].get("user", {}) as Dictionary).get("id", ""))
		mail = str(a["donnees"].get("email", ""))
	en_ligne = true
	change.emit()
	# en jeu : une partie jamais envoyée (ou en attente) part tout de suite
	if actif and (envoye_le == 0 or _a_envoyer):
		envoyer()
	return true


func _reessayer() -> void:
	_essai_en_cours = true
	await connecter()
	_essai_en_cours = false


# La partie a changé (GS.save_game) : elle partira au serveur au plus tard dans ENVOI_S.
func partie_changee() -> void:
	_a_envoyer = true


func _process(delta: float) -> void:
	if not actif:
		return
	_depuis += delta
	if _a_envoyer and _depuis >= ENVOI_S and not _en_cours:
		envoyer()
	_depuis_essai += delta
	if jeton == "" and not _en_cours and not _essai_en_cours and _depuis_essai >= RECONNEXION_S:
		_depuis_essai = 0.0
		_reessayer()


func _notification(what: int) -> void:
	if not actif:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _a_envoyer and not _en_cours:
			envoyer()


func envoyer() -> bool:
	if _en_cours:
		return false
	_en_cours = true
	_a_envoyer = false
	_depuis = 0.0
	var ok := false
	if jeton == "":
		await connecter()
	if jeton != "":
		var d := GS.donnees_sauvegarde()
		d["maj"] = int(Time.get_unix_time_from_system())
		var corps := {"objects": [{"collection": COLLECTION, "key": CLE_PARTIE, "value": JSON.stringify(d),
			"permission_read": 1, "permission_write": 1}]}
		var r := await _demander(HTTPClient.METHOD_PUT, "/v2/storage", corps)
		if r["code"] == 401:                                   # la session a expiré : une fois de plus
			jeton = ""
			await connecter()
			if jeton != "":
				r = await _demander(HTTPClient.METHOD_PUT, "/v2/storage", corps)
		ok = r["code"] == 200
	if ok:
		envoye_le = int(Time.get_unix_time_from_system())
		_ecrire()
	else:
		_a_envoyer = true                                      # on réessaiera
	en_ligne = ok
	_en_cours = false
	change.emit()
	return ok


# ── LIER LE COMPTE PAR MAIL (29/09) : retrouver sa partie sur un autre téléphone ──
# Sur le téléphone qui a la partie : « Lier mon compte » (lier_mail). Sur l'autre : « J'ai déjà un compte » (retrouver, puis
# adopter — ce téléphone rejoint le compte ; son compte d'appareil, qui n'avait que sa partie à lui, est effacé).
# 🔴 Pas de « mot de passe oublié » : Nakama n'envoie pas de mail ; il viendra avec Google (ou un service d'envoi).
# Les raisons d'un refus : "reseau", "pris" (ce mail a déjà un compte), "mail" (adresse invalide), "mdp_court" (moins de
# 8 caractères), "mdp" (mot de passe faux), "inconnu" (aucun compte pour ce mail), "autre".

func lier_mail(adresse: String, mdp: String) -> String:
	if jeton == "":
		await connecter()
	if jeton == "":
		return "reseau"
	var r := await _demander(HTTPClient.METHOD_POST, "/v2/account/link/email", {"email": adresse.strip_edges(), "password": mdp})
	if r["code"] == 200:
		mail = adresse.strip_edges()
		change.emit()
		return ""
	return _raison(r)


func retrouver(adresse: String, mdp: String) -> Dictionary:
	var r := await _demander(HTTPClient.METHOD_POST, "/v2/account/authenticate/email?create=false",
		{"email": adresse.strip_edges(), "password": mdp}, true)
	if r["code"] != 200 or str(r["donnees"].get("token", "")) == "":
		return {"erreur": _raison(r)}
	var ancien := jeton
	jeton = str(r["donnees"]["token"])
	var a := await _demander(HTTPClient.METHOD_GET, "/v2/account")
	var u := str((a["donnees"].get("user", {}) as Dictionary).get("id", "")) if a["code"] == 200 else ""
	var s := await _demander(HTTPClient.METHOD_POST, "/v2/storage",
		{"object_ids": [{"collection": COLLECTION, "key": CLE_PARTIE, "user_id": u}]})
	var trouve := {"erreur": "", "jeton": jeton, "utilisateur": u, "mail": adresse.strip_edges(), "partie": {}}
	jeton = ancien
	var objets: Array = s["donnees"].get("objects", []) if s["code"] == 200 else []
	if not objets.is_empty():
		var v = JSON.parse_string(str((objets[0] as Dictionary).get("value", "")))
		if typeof(v) == TYPE_DICTIONARY:
			trouve["partie"] = v
	return trouve


# Ce téléphone rejoint le compte retrouvé : son compte d'appareil est effacé (au mieux), un nouvel identifiant d'appareil
# est lié au compte retrouvé — aux prochains lancements, connecter() le retrouve tout seul.
func adopter(trouve: Dictionary) -> bool:
	if jeton != "":
		await _demander(HTTPClient.METHOD_DELETE, "/v2/account")
	jeton = str(trouve.get("jeton", ""))
	var nouvel := "poussette-" + Crypto.new().generate_random_bytes(16).hex_encode()
	var r := await _demander(HTTPClient.METHOD_POST, "/v2/account/link/device", {"id": nouvel})
	if r["code"] != 200:
		jeton = ""
		return false
	appareil = nouvel
	utilisateur = str(trouve.get("utilisateur", ""))
	mail = str(trouve.get("mail", ""))
	envoye_le = int(Time.get_unix_time_from_system())
	en_ligne = true
	_ecrire()
	change.emit()
	return true


func _raison(r: Dictionary) -> String:
	var code := int(r["code"])
	var msg := str(r["donnees"].get("message", "")).to_lower()
	if code == 0:
		return "reseau"
	if code == 409 or msg.contains("in use"):
		return "pris"
	if msg.contains("password"):
		return "mdp_court" if msg.contains("least") or msg.contains("length") or msg.contains("short") else "mdp"
	if msg.contains("email") and code == 400:
		return "mail"
	if code == 401:
		return "mdp"
	if code == 404:
		return "inconnu"
	return "autre"


# « m•••@gmail.com » : le mail lié, sans le montrer en entier
static func masquer(adresse: String) -> String:
	var i := adresse.find("@")
	if i < 1:
		return adresse
	return adresse.substr(0, 1) + "•••" + adresse.substr(i)


# La partie telle que le serveur la garde ({} s'il n'en a pas) — pour retrouver sa partie (la suite : le compte lié).
func lire() -> Dictionary:
	if jeton == "":
		await connecter()
	if jeton == "":
		return {}
	var r := await _demander(HTTPClient.METHOD_POST, "/v2/storage",
		{"object_ids": [{"collection": COLLECTION, "key": CLE_PARTIE, "user_id": utilisateur}]})
	var objets: Array = r["donnees"].get("objects", []) if r["code"] == 200 else []
	if objets.is_empty():
		return {}
	var v = JSON.parse_string(str((objets[0] as Dictionary).get("value", "")))
	return v if typeof(v) == TYPE_DICTIONARY else {}


# Un objet PUBLIC d'un autre compte (01/10 : la table des codes cadeaux, posée par l'administrateur des codes) ; {} sinon.
func lire_public(collection: String, cle: String, proprietaire: String) -> Dictionary:
	if jeton == "":
		await connecter()
	if jeton == "":
		return {}
	var r := await _demander(HTTPClient.METHOD_POST, "/v2/storage",
		{"object_ids": [{"collection": collection, "key": cle, "user_id": proprietaire}]})
	var objets: Array = r["donnees"].get("objects", []) if r["code"] == 200 else []
	if objets.is_empty():
		return {}
	var v = JSON.parse_string(str((objets[0] as Dictionary).get("value", "")))
	return v if typeof(v) == TYPE_DICTIONARY else {}


# Effacer le compte sur le serveur (Apple l'exige ; les tests s'en servent pour ne rien laisser).
func effacer() -> bool:
	if jeton == "":
		await connecter()
	if jeton == "":
		return false
	var r := await _demander(HTTPClient.METHOD_DELETE, "/v2/account")
	if r["code"] == 200:
		jeton = ""
		utilisateur = ""
		en_ligne = false
		change.emit()
		return true
	return false


# Une demande au serveur : {code, donnees}. code 0 : pas de réponse (pas de réseau, serveur éteint).
func _demander(methode: int, chemin: String, corps = null, avec_cle := false) -> Dictionary:
	var h := HTTPRequest.new()
	h.timeout = 15.0
	add_child(h)
	var entetes := PackedStringArray(["Content-Type: application/json", "Accept: application/json",
		"Authorization: " + ("Basic " + Marshalls.utf8_to_base64(CLE + ":") if avec_cle else "Bearer " + jeton)])
	var err := h.request(SERVEUR + chemin, entetes, methode, "" if corps == null else JSON.stringify(corps))
	if err != OK:
		h.queue_free()
		return {"code": 0, "donnees": {}}
	var res: Array = await h.request_completed
	h.queue_free()
	var donnees = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	return {"code": int(res[1]) if int(res[0]) == HTTPRequest.RESULT_SUCCESS else 0,
		"donnees": donnees if typeof(donnees) == TYPE_DICTIONARY else {}}


# « il y a 3 min » : ce que le panneau Compte dit de la dernière sauvegarde en ligne.
static func depuis(t: int) -> String:
	if t <= 0:
		return "jamais"
	var s := int(Time.get_unix_time_from_system()) - t
	if s < 60:
		return "à l'instant"
	if s < 3600:
		return "il y a %d min" % (s / 60)
	if s < 86400:
		return "il y a %d h" % (s / 3600)
	return "il y a %d jours" % (s / 86400)
