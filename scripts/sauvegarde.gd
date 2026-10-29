class_name Sauvegarde
extends RefCounted
## Sauvegarde locale de la partie : un fichier JSON dans user:// (dossier « Le Fil de l'Abysse »,
## voir project.godot : %APPDATA%\Le Fil de l'Abysse sous Windows).
##
## Contenu : { "version", "horodatage" (secondes Unix), "inventaire" { id: nombre },
## "ameliorations" { id: niveau }, "ilots" [ids reliés], "ile" { état des sources },
## "reglages" { "musique", "effets" : volumes de 0 à 1 } }.
## Ce module ne connaît que le fichier : la validation des identifiants et des valeurs est faite
## par ceux qui chargent (Inventaire, Atelier, Ile, Son), qui ignorent ou bornent ce qui est faux.
##
## Écriture sûre : le fichier est écrit à côté (.tmp), l'ancien devient la copie de secours (.bak),
## puis le nouveau prend sa place. Un fichier illisible est mis de côté (.corrompue.json) et la copie
## de secours est reprise si elle est saine. Un fichier d'une version plus récente n'est jamais écrasé.

enum Statut { ABSENTE, OK, RECUPEREE, CORROMPUE, TROP_RECENTE }

const VERSION := 1

## Chemin du fichier ; les tests le redirigent pour ne jamais toucher la vraie sauvegarde.
static var chemin := "user://sauvegarde.json"


static func chemin_secours() -> String:
	return chemin.get_basename() + ".bak"


static func chemin_temporaire() -> String:
	return chemin.get_basename() + ".tmp"


static func chemin_corrompue() -> String:
	return chemin.get_basename() + ".corrompue.json"


static func existe() -> bool:
	return FileAccess.file_exists(chemin) or FileAccess.file_exists(chemin_secours())


## Écrit la partie { inventaire, ameliorations, ilots, ile } ; renvoie faux en cas d'échec.
static func ecrire(partie: Dictionary, horodatage: float = Time.get_unix_time_from_system()) -> bool:
	var donnees := partie.duplicate(true)
	donnees["version"] = VERSION
	donnees["horodatage"] = horodatage
	var temporaire := chemin_temporaire()
	var fichier := FileAccess.open(temporaire, FileAccess.WRITE)
	if fichier == null:
		push_warning("Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return false
	fichier.store_string(JSON.stringify(donnees, "\t"))
	fichier.close()
	# Le fichier écrit doit se relire avant de remplacer quoi que ce soit.
	if _analyser(_lire_texte(temporaire)).is_empty():
		DirAccess.remove_absolute(temporaire)
		return false
	if FileAccess.file_exists(chemin):
		_remplacer(chemin, chemin_secours())
	return _remplacer(temporaire, chemin)


## Lit la sauvegarde : { "statut": Statut, "partie": Dictionary (vide si rien d'utilisable),
## "message": texte à afficher à l'écran titre (vide si tout va bien) }.
static func lire() -> Dictionary:
	if not FileAccess.file_exists(chemin):
		if not FileAccess.file_exists(chemin_secours()):
			return _resultat(Statut.ABSENTE)
		# Écriture interrompue entre deux étapes : la copie de secours est la dernière partie complète.
		var secours := _analyser(_lire_texte(chemin_secours()))
		if secours.is_empty() or _est_trop_recente(secours):
			return _resultat(Statut.ABSENTE)
		return _resultat(Statut.RECUPEREE, migrer(secours), "Sauvegarde incomplète : la copie de secours a été reprise.")
	var donnees := _analyser(_lire_texte(chemin))
	if not donnees.is_empty():
		if _est_trop_recente(donnees):
			return _resultat(Statut.TROP_RECENTE, {},
				"Sauvegarde d'une version plus récente du jeu : elle ne sera pas modifiée.")
		return _resultat(Statut.OK, migrer(donnees))
	# Fichier illisible : on le garde de côté (jamais supprimé), puis on essaie la copie de secours.
	_remplacer(chemin, chemin_corrompue())
	var secours := _analyser(_lire_texte(chemin_secours()))
	if not secours.is_empty() and not _est_trop_recente(secours):
		return _resultat(Statut.RECUPEREE, migrer(secours),
			"Sauvegarde abîmée : la copie de secours a été reprise.")
	return _resultat(Statut.CORROMPUE, {},
		"Sauvegarde illisible, mise de côté : commence une nouvelle partie.")


## Met de côté une sauvegarde d'une version plus récente avant une nouvelle partie (jamais écrasée).
static func mettre_de_cote_version_recente() -> void:
	var donnees := _analyser(_lire_texte(chemin))
	if not donnees.is_empty() and _est_trop_recente(donnees):
		_remplacer(chemin, chemin.get_basename() + ".version-%d.json" % int(donnees["version"]))


## Met à jour les données d'une version plus ancienne vers VERSION, étape par étape.
## Version 0 : premier format, sans numéro de version, sans îlots ni état de l'île.
static func migrer(donnees: Dictionary) -> Dictionary:
	var resultat := donnees.duplicate(true)
	var version := int(resultat.get("version", 0))
	if version < 1:
		if not resultat.get("ilots") is Array:
			resultat["ilots"] = []
		if not resultat.get("ile") is Dictionary:
			resultat["ile"] = {}
		version = 1
	resultat["version"] = version
	# Types attendus : tout champ d'un mauvais type est remplacé par une valeur vide.
	for cle: String in ["inventaire", "ameliorations", "ile", "reglages"]:
		if not resultat.get(cle) is Dictionary:
			resultat[cle] = {}
	if not resultat.get("ilots") is Array:
		resultat["ilots"] = []
	var horodatage = resultat.get("horodatage", 0.0)
	resultat["horodatage"] = float(horodatage) if (horodatage is float or horodatage is int) else 0.0
	return resultat


## Secondes écoulées depuis la sauvegarde (jamais négatif, même si l'horloge a reculé).
static func secondes_depuis(partie: Dictionary, maintenant: float = Time.get_unix_time_from_system()) -> float:
	var horodatage := float(partie.get("horodatage", 0.0))
	if horodatage <= 0.0:
		return 0.0
	return maxf(maintenant - horodatage, 0.0)


# --- Outils -----------------------------------------------------------------------------

static func _resultat(statut: Statut, partie: Dictionary = {}, message: String = "") -> Dictionary:
	return {"statut": statut, "partie": partie, "message": message}


static func _lire_texte(fichier_chemin: String) -> String:
	if not FileAccess.file_exists(fichier_chemin):
		return ""
	var fichier := FileAccess.open(fichier_chemin, FileAccess.READ)
	if fichier == null:
		return ""
	var texte := fichier.get_as_text()
	fichier.close()
	return texte


## Analyse le texte ; renvoie un dictionnaire vide s'il n'est pas une sauvegarde reconnaissable.
static func _analyser(texte: String) -> Dictionary:
	if texte.strip_edges() == "":
		return {}
	var json := JSON.new()
	if json.parse(texte) != OK or not json.data is Dictionary:
		return {}
	var donnees: Dictionary = json.data
	var version = donnees.get("version", 0)
	if not (version is float or version is int) or float(version) < 0.0:
		return {}
	return donnees


static func _est_trop_recente(donnees: Dictionary) -> bool:
	return int(donnees.get("version", 0)) > VERSION


## Renomme source en cible, en remplaçant la cible si elle existe.
static func _remplacer(source: String, cible: String) -> bool:
	if FileAccess.file_exists(cible):
		DirAccess.remove_absolute(cible)
	return DirAccess.rename_absolute(source, cible) == OK
