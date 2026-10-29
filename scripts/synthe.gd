class_name Synthe
extends RefCounted
## Sons du jeu, synthétisés en code au démarrage (aucun fichier audio) : chaque son est calculé une fois
## en échantillons, puis rangé dans un AudioStreamWAV (mono, 16 bits). Les ambiances sont des boucles :
## toutes leurs fréquences et modulations font un nombre entier de cycles sur la durée de la boucle,
## et le bruit est rendu circulaire, si bien que la fin raccorde exactement au début.
## Hasard à graine fixe : les sons sont identiques d'une partie à l'autre.

const FREQ := 22050          # échantillons par seconde (effets)
const FREQ_AMBIANCE := 11025 # les ambiances sont graves et douces : la moitié suffit
const DUREE_BOUCLE := 8.0    # secondes
const CRETE := 0.9           # niveau maximal d'un son (marge avant saturation)

const EFFETS := ["clic", "nuage", "vent", "cristal", "bassin", "minage", "unite", "sac_plein",
	"oxygene_bas", "craquement", "remontee_auto", "fabrication", "installation", "construction", "souffle", "machine", "foreuse"]
const AMBIANCES := ["ile", "lagon", "coraux", "faille"]

static var _hasard := RandomNumberGenerator.new()


## Libère le générateur de hasard partagé (fermeture du jeu : aucune fuite signalée).
static func liberer() -> void:
	_hasard = null


## Tous les effets : { id: AudioStreamWAV }.
static func effets() -> Dictionary:
	var resultat := {}
	for id: String in EFFETS:
		resultat[id] = effet(id)
	return resultat


static func effet(id: String) -> AudioStreamWAV:
	_preparer_hasard()
	_hasard.seed = hash(id)
	match id:
		"clic":
			return _wav(_clic(), FREQ)
		"nuage":
			return _wav(_bruit_filtre(0.22, 900.0, 0.02, 0.18, 0.5), FREQ)
		"vent":
			return _wav(_souffle_balaye(0.45, 300.0, 1800.0, 0.6), FREQ)
		"cristal":
			return _wav(_cloche([1318.5, 1975.5, 2637.0], 0.7, 0.45), FREQ)
		"bassin":
			return _wav(_bulle(0.18, 380.0, 820.0, 0.55), FREQ)
		"minage":
			return _wav(_coup(0.06, 260.0, 0.45), FREQ)
		"unite":
			return _wav(_arpege([659.3, 987.8], 0.09, 0.35, 0.45), FREQ)
		"sac_plein":
			return _wav(_arpege([392.0, 293.7], 0.14, 0.3, 0.35), FREQ)
		"oxygene_bas":
			return _wav(_bip(0.14, 880.0, 0.28), FREQ)
		"craquement":
			return _wav(_craquement(0.9, 0.55), FREQ)
		"remontee_auto":
			return _wav(_alarme_douce(1.1, 0.35), FREQ)
		"fabrication":
			return _wav(_cloche([900.0, 1430.0, 2290.0], 0.45, 0.4), FREQ)
		"installation":
			return _wav(_arpege([523.3, 659.3, 784.0, 1046.5], 0.11, 0.5, 0.45), FREQ)
		"construction":
			return _wav(_construction(), FREQ)
		"souffle":
			return _wav(_bruit_filtre(2.2, 500.0, 0.9, 1.1, 0.35), FREQ)
		"machine":
			# Récolte d'une machine : petit claquement de bois, puis deux notes douces qui montent.
			var son := _coup(0.05, 190.0, 0.3)
			son.append_array(_arpege([587.3, 880.0], 0.08, 0.32, 0.4))
			return _wav(son, FREQ)
		"foreuse":
			# Récolte de la foreuse : court grincement de mèche, puis le tintement d'un cristal.
			var meche := _coup(0.07, 140.0, 0.3)
			meche.append_array(_cloche([1174.7, 1760.0], 0.4, 0.35))
			return _wav(meche, FREQ)
	push_warning("Son inconnu : %s" % id)
	return _wav(PackedFloat32Array([0.0]), FREQ)


## Ambiances en boucle : { id: AudioStreamWAV }.
static func ambiances() -> Dictionary:
	var resultat := {}
	for id: String in AMBIANCES:
		resultat[id] = ambiance(id)
	return resultat


## Île : nappe lumineuse (do majeur avec neuvième), vibrato lent et souffle d'air léger.
## Plongée : drone grave étouffé, de plus en plus sombre (Lagon, Coraux, Faille).
static func ambiance(id: String) -> AudioStreamWAV:
	_preparer_hasard()
	_hasard.seed = hash("ambiance:" + id)
	match id:
		"ile":
			return _wav(_nappe([261.6, 329.6, 392.0, 587.3, 784.0], [0.22, 0.16, 0.16, 0.10, 0.05], 0.035, 1600.0, 0.32), FREQ_AMBIANCE, true)
		"lagon":
			return _wav(_drone([110.0, 164.8, 220.0], [0.30, 0.16, 0.06], 0.10, 420.0, 0.30), FREQ_AMBIANCE, true)
		"coraux":
			return _wav(_drone([98.0, 116.5, 146.8], [0.32, 0.16, 0.10], 0.14, 300.0, 0.30), FREQ_AMBIANCE, true)
		"faille":
			return _wav(_drone([73.4, 103.8, 110.0], [0.36, 0.12, 0.08], 0.20, 180.0, 0.30, true), FREQ_AMBIANCE, true)
	push_warning("Ambiance inconnue : %s" % id)
	return _wav(PackedFloat32Array([0.0]), FREQ_AMBIANCE, true)


# --- Recettes ---------------------------------------------------------------------------

static func _clic() -> PackedFloat32Array:
	var n := int(0.03 * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / FREQ
		s[i] = sin(TAU * 1500.0 * t) * exp(-t * 160.0) * 0.18
	return s


## Bruit filtré passe-bas avec attaque et chute : nuage (pouf), souffle de la transition.
static func _bruit_filtre(duree: float, coupure: float, attaque: float, chute: float, volume: float) -> PackedFloat32Array:
	var n := int(duree * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	var a := _coef(coupure, FREQ)
	var y := 0.0
	for i in n:
		y += a * (_hasard.randf_range(-1.0, 1.0) - y)
		s[i] = y * _enveloppe(float(i) / FREQ, duree, attaque, chute)
	return _normaliser(s, volume)


## Souffle dont la coupure monte (vent qu'on vide de l'éolienne).
static func _souffle_balaye(duree: float, debut: float, fin: float, volume: float) -> PackedFloat32Array:
	var n := int(duree * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	var y := 0.0
	var y2 := 0.0
	for i in n:
		var p := float(i) / n
		var a := _coef(lerpf(debut, fin, p), FREQ)
		y += a * (_hasard.randf_range(-1.0, 1.0) - y)
		y2 += a * (y - y2)
		s[i] = (y - y2) * _enveloppe(float(i) / FREQ, duree, 0.08, 0.3)
	return _normaliser(s, volume)


## Cloche douce : partiels qui s'éteignent, les aigus plus vite.
static func _cloche(partiels: Array, duree: float, volume: float) -> PackedFloat32Array:
	var n := int(duree * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / FREQ
		var v := 0.0
		for k in partiels.size():
			v += sin(TAU * float(partiels[k]) * t) * exp(-t * (5.0 + 4.0 * k)) / (1.0 + k)
		s[i] = v * minf(t / 0.004, 1.0)
	return _normaliser(s, volume)


## Bulle : sinus dont la hauteur monte vite (eau du bassin).
static func _bulle(duree: float, debut: float, fin: float, volume: float) -> PackedFloat32Array:
	var n := int(duree * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / FREQ
		var p := float(i) / n
		phase += TAU * lerpf(debut, fin, sqrt(p)) / FREQ
		s[i] = sin(phase) * sin(PI * p)
	return _normaliser(s, volume)


## Coup sourd et bref (pioche de la cloche) : sinus grave + grain de bruit.
static func _coup(duree: float, frequence: float, volume: float) -> PackedFloat32Array:
	var n := int(duree * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / FREQ
		y += 0.3 * (_hasard.randf_range(-1.0, 1.0) - y)
		s[i] = (sin(TAU * frequence * t) * 0.8 + y * 0.5) * exp(-t * 60.0)
	return _normaliser(s, volume)


## Notes successives douces (sinus + octave légère), chacune s'éteint en douceur.
static func _arpege(notes: Array, ecart: float, duree: float, volume: float) -> PackedFloat32Array:
	var total := ecart * (notes.size() - 1) + duree
	var n := int(total * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	for k in notes.size():
		var debut := int(k * ecart * FREQ)
		for i in range(debut, mini(n, debut + int(duree * FREQ))):
			var t := float(i - debut) / FREQ
			var f := float(notes[k])
			s[i] += (sin(TAU * f * t) + 0.25 * sin(TAU * 2.0 * f * t)) * exp(-t * 7.0) * minf(t / 0.005, 1.0)
	return _normaliser(s, volume)


## Bip discret (oxygène bas) : attaque et chute douces, aucune arête.
static func _bip(duree: float, frequence: float, volume: float) -> PackedFloat32Array:
	var n := int(duree * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / FREQ
		s[i] = sin(TAU * frequence * t) * sin(PI * t / duree)
	return _normaliser(s, volume)


## Craquement de coque : grincement grave irrégulier et petits claquements.
static func _craquement(duree: float, volume: float) -> PackedFloat32Array:
	var n := int(duree * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	var y := 0.0
	for i in n:
		var t := float(i) / FREQ
		var f := 70.0 + 25.0 * sin(TAU * 3.0 * t) + _hasard.randf_range(-15.0, 15.0)
		phase += TAU * f / FREQ
		var dent := fposmod(phase, TAU) / TAU * 2.0 - 1.0
		y += 0.08 * (dent - y)
		var clac := _hasard.randf_range(-1.0, 1.0) if _hasard.randf() < 0.002 else 0.0
		s[i] = (y * 2.0 + clac * 0.6) * _enveloppe(t, duree, 0.1, 0.4)
	return _normaliser(s, volume)


## Alarme douce de remontée : trois paires de notes graves qui descendent.
static func _alarme_douce(duree: float, volume: float) -> PackedFloat32Array:
	var n := int(duree * FREQ)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / FREQ
		var pas := int(t / 0.18)
		var f := 440.0 if pas % 2 == 0 else 349.2
		var local := fmod(t, 0.18)
		s[i] = sin(TAU * f * t) * sin(PI * local / 0.18) * (1.0 - t / duree * 0.5)
	return _normaliser(s, volume)


## Construction : deux coups de bois puis l'arpège d'installation.
static func _construction() -> PackedFloat32Array:
	var bois := _coup(0.12, 180.0, 0.5)
	var bois_2 := _coup(0.12, 150.0, 0.5)
	var arpege := _arpege([392.0, 523.3, 659.3, 784.0], 0.1, 0.5, 0.45)
	var s := PackedFloat32Array()
	s.resize(int(0.3 * FREQ) + arpege.size())
	for i in bois.size():
		s[i] += bois[i]
		s[i + int(0.14 * FREQ)] += bois_2[i]
	for i in arpege.size():
		s[i + int(0.3 * FREQ)] += arpege[i]
	return _normaliser(s, 0.5)


## Nappe (île) : accord de sinus légèrement désaccordés deux à deux (chorus), respiration lente,
## et un souffle d'air filtré.
static func _nappe(notes: Array, niveaux: Array, air: float, coupure: float, volume: float) -> PackedFloat32Array:
	var n := int(DUREE_BOUCLE * FREQ_AMBIANCE)
	var s := _bruit_circulaire(n, coupure, air)
	for k in notes.size():
		var f := _accorde(float(notes[k]))
		var f2 := _accorde(float(notes[k]) * 1.003)
		var lente := 1.0 / DUREE_BOUCLE * float(1 + k % 3)   # respiration : 1 à 3 cycles par boucle
		for i in n:
			var t := float(i) / FREQ_AMBIANCE
			var souffle := 0.75 + 0.25 * sin(TAU * lente * t + k)
			s[i] += (sin(TAU * f * t) + sin(TAU * f2 * t)) * 0.5 * float(niveaux[k]) * souffle
	return _normaliser(s, volume)


## Drone sous-marin : notes graves, grondement filtré, lente houle ; « pouls » pour la Faille.
static func _drone(notes: Array, niveaux: Array, grondement: float, coupure: float, volume: float,
		pouls: bool = false) -> PackedFloat32Array:
	var n := int(DUREE_BOUCLE * FREQ_AMBIANCE)
	var s := _bruit_circulaire(n, coupure, grondement)
	for k in notes.size():
		var f := _accorde(float(notes[k]))
		for i in n:
			var t := float(i) / FREQ_AMBIANCE
			var houle := 0.8 + 0.2 * sin(TAU * t / DUREE_BOUCLE * float(k + 1))
			s[i] += sin(TAU * f * t) * float(niveaux[k]) * houle
	if pouls:
		# Battement lent du magma : 8 coups par boucle, comme un cœur très calme.
		for i in n:
			var t := float(i) / FREQ_AMBIANCE
			var local := fmod(t, 1.0)
			s[i] += sin(TAU * _accorde(45.0) * t) * exp(-local * 6.0) * 0.25
	return _normaliser(s, volume)


# --- Outils -----------------------------------------------------------------------------

static func _preparer_hasard() -> void:
	if _hasard == null:
		_hasard = RandomNumberGenerator.new()


## Fréquence arrondie pour faire un nombre entier de cycles sur la boucle (raccord parfait).
static func _accorde(frequence: float) -> float:
	return roundf(frequence * DUREE_BOUCLE) / DUREE_BOUCLE


## Bruit filtré passe-bas, rendu circulaire : le filtre tourne deux fois sur la boucle, l'état de fin
## du premier tour sert de départ au second, si bien que la fin raccorde au début.
static func _bruit_circulaire(n: int, coupure: float, niveau: float) -> PackedFloat32Array:
	var brut := PackedFloat32Array()
	brut.resize(n)
	for i in n:
		brut[i] = _hasard.randf_range(-1.0, 1.0)
	var a := _coef(coupure, FREQ_AMBIANCE)
	var y := 0.0
	var y2 := 0.0
	for passe in 2:
		for i in n:
			y += a * (brut[i] - y)
			y2 += a * (y - y2)
			if passe == 1:
				brut[i] = y2
	var crete := 0.0
	for v in brut:
		crete = maxf(crete, absf(v))
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		s[i] = brut[i] / maxf(crete, 1e-6) * niveau
	return s


## Coefficient d'un filtre passe-bas à un pôle.
static func _coef(coupure: float, frequence: int) -> float:
	return 1.0 - exp(-TAU * coupure / frequence)


## Enveloppe attaque / chute (chute en fin de son).
static func _enveloppe(t: float, duree: float, attaque: float, chute: float) -> float:
	var monte := minf(t / maxf(attaque, 0.001), 1.0)
	var descend := clampf((duree - t) / maxf(chute, 0.001), 0.0, 1.0)
	return monte * descend * descend


## Ramène le son à un niveau de crête donné (jamais au-delà de CRETE).
static func _normaliser(s: PackedFloat32Array, volume: float) -> PackedFloat32Array:
	var crete := 0.0
	for v in s:
		crete = maxf(crete, absf(v))
	if crete <= 0.0:
		return s
	var gain := minf(volume, CRETE) / crete
	for i in s.size():
		s[i] *= gain
	return s


## Échantillons → AudioStreamWAV 16 bits mono (en boucle pour les ambiances).
static func _wav(s: PackedFloat32Array, frequence: int, boucle: bool = false) -> AudioStreamWAV:
	var donnees := PackedByteArray()
	donnees.resize(s.size() * 2)
	for i in s.size():
		donnees.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32767.0))
	var flux := AudioStreamWAV.new()
	flux.format = AudioStreamWAV.FORMAT_16_BITS
	flux.mix_rate = frequence
	flux.stereo = false
	flux.data = donnees
	if boucle:
		flux.loop_mode = AudioStreamWAV.LOOP_FORWARD
		flux.loop_begin = 0
		flux.loop_end = s.size()
	return flux


## Échantillons d'un flux (pour les tests) : valeurs entre -1 et 1.
static func echantillons(flux: AudioStreamWAV) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(flux.data.size() / 2)
	for i in s.size():
		s[i] = flux.data.decode_s16(i * 2) / 32767.0
	return s
