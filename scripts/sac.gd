class_name Sac
extends RefCounted
## Le sac de la cloche : une unité de minerai = un emplacement.
## 8 places au départ ; l'amélioration « Sac de plongée » en donne 12.

const CAPACITE := 8

var capacite := CAPACITE
var _unites: Array[String] = []


func nombre() -> int:
	return _unites.size()


func est_plein() -> bool:
	return _unites.size() >= capacite


func ajouter(minerai: String) -> bool:
	if est_plein():
		return false
	_unites.append(minerai)
	return true


## Nombre d'unités par minerai : { "cristal": 3, "corail": 1 }
func compter() -> Dictionary:
	var comptes := {}
	for minerai in _unites:
		comptes[minerai] = int(comptes.get(minerai, 0)) + 1
	return comptes


## Vide le sac et renvoie son contenu.
func vider() -> Dictionary:
	var contenu := compter()
	_unites.clear()
	return contenu


## Perd une fraction des unités, tirées au hasard (arrondi à l'inférieur).
## Renvoie ce qui a été perdu.
func perdre(fraction: float, hasard: RandomNumberGenerator) -> Dictionary:
	var nb_perdues := int(floor(_unites.size() * fraction + 0.000001))
	var perdues := {}
	for i in nb_perdues:
		var index := hasard.randi_range(0, _unites.size() - 1)
		var minerai := _unites[index]
		_unites.remove_at(index)
		perdues[minerai] = int(perdues.get(minerai, 0)) + 1
	return perdues
