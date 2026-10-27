class_name Donnees
extends RefCounted
## Lecture des fichiers de données du dossier data/.


static func charger_json(chemin: String) -> Variant:
	var fichier := FileAccess.open(chemin, FileAccess.READ)
	if fichier == null:
		push_error("Impossible d'ouvrir %s" % chemin)
		return null
	var resultat: Variant = JSON.parse_string(fichier.get_as_text())
	if resultat == null:
		push_error("JSON invalide : %s" % chemin)
	return resultat
