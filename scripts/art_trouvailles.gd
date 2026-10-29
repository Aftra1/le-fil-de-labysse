class_name ArtTrouvailles
extends RefCounted
## Pixel art des trouvailles rares (carnet, annonces) et de leur éclat en plongée.
## Chaque trouvaille est un motif de 10 pixels de large (lettres = couleurs de la palette, voir COULEURS),
## avec un contour sombre. En plongée, on ne voit qu'un éclat scintillant de la couleur lumineuse de la
## zone (cyan, corail, or : jamais assombrie par l'obscurité) ; la trouvaille se révèle quand on la ramasse.

const COULEURS := {
	"w": "nuage.4", "n": "nuage.3", "g": "nuage.2",
	"o": "or.3", "O": "or.4", "y": "or.5", "d": "or.1", "e": "or.2",
	"c": "cyan.2", "C": "cyan.3", "l": "lagon.3", "L": "lagon.4",
	"p": "corail.2", "P": "corail.3", "q": "corail.4",
	"r": "roche.2", "R": "roche.3", "s": "roche.4",
	"k": "abysse.1", "K": "abysse.2", "m": "metal.2", "M": "metal.3",
	"t": "terre.2", "T": "terre.1", "b": "ciel.3", "B": "ciel.4",
}
const CONTOUR := "abysse.1"
## Couleur de l'éclat de chaque zone en plongée (les trois lueurs que l'obscurité ne touche pas).
const LUEURS := {"lagon": "cyan.3", "coraux": "corail.4", "faille": "or.5"}

const MOTIFS := {
	# --- Perles du Lagon ---------------------------------------------------------------
	"perle_aube": [
		"...nnnn...",
		"..nwwwwn..",
		".nwwyyOwn.",
		".nwyOOOon.",
		".nwyOOoon.",
		".nwwOoogn.",
		"..nwoogn..",
		"...nggn...",
		"..........",
	],
	"perles_jumelles": [
		"..........",
		".pPPPPPPp.",
		"pPqnnPnnqP",
		"PqnwwnwwnP",
		"PqnwgnwgnP",
		"pPqnnPnnqp",
		".pPPPPPPp.",
		"..pppppp..",
		"..........",
	],
	"perle_noire": [
		"...KKKK...",
		"..KMmKKK..",
		".KMmKKKKK.",
		".KmKKKKKK.",
		".KKKKKKkK.",
		".KKKKKkkK.",
		"..KKKkkK..",
		"...KkkK...",
		"..........",
	],
	"perle_lune": [
		"...cccc...",
		"..cCwwCc..",
		".cCwwwCCc.",
		".cwwCCCCc.",
		".cCwCCCcl.",
		".cCCCCccl.",
		"..cCCccl..",
		"...clll...",
		"..........",
	],
	"perle_larme": [
		"....nn....",
		"....wn....",
		"...nwwn...",
		"..nwwwwn..",
		".nwwLwwgn.",
		".nwLLwwgn.",
		".nwwwwggn.",
		"..nwgggn..",
		"...nnnn...",
	],
	"perle_vent": [
		"B..nnnn...",
		".Bnwwwwn..",
		"BBwwkwwwn.",
		".nwwkkwwn.",
		".nwwwkwwn.",
		".nwwwwwgn.",
		"..nwwwgnB.",
		"...nggn.BB",
		"........B.",
	],
	# --- Fossiles des Coraux ------------------------------------------------------------
	"ammonite": [
		"...ssss...",
		"..sRRRRs..",
		".sRrrrrRs.",
		".sRrssrRs.",
		".sRrsRrRs.",
		".sRrRRrRs.",
		".sRrrrrRs.",
		"..sRRRRs..",
		"...ssss...",
	],
	"dent_abysse": [
		".wwwwwwww.",
		".wnnwwnnw.",
		"..wnnnnw..",
		"..wnnnnw..",
		"...wnng...",
		"...wnng...",
		"....wg....",
		"....wg....",
		"....g.....",
	],
	"coquille_ailee": [
		"s........s",
		"Rs......sR",
		"RRs.ss.sRR",
		"rRRsRRsRRr",
		".rRRrrRRr.",
		"..rRRRRr..",
		"...rRRr...",
		"....rr....",
		"..........",
	],
	"feuille_pierre": [
		"......sss.",
		"....ssRRs.",
		"...sRRrRs.",
		"..sRRrRRs.",
		".sRRrRRs..",
		".sRrRRs...",
		".srRRs....",
		"rr.ss.....",
		"r.........",
	],
	"arete_passeur": [
		"..........",
		"n.n.n.n.w.",
		"w.w.w.w.ww",
		"nwwwwwwwwk",
		"w.w.w.w.ww",
		"n.n.n.n.w.",
		"..........",
		"..........",
		"..........",
	],
	"oeuf_corail": [
		"...pppp...",
		"..pPPPPp..",
		".pPqPPPPp.",
		".pPPPPqPp.",
		".pPqPPPPp.",
		".pPPPPPqp.",
		".pPPqPPPp.",
		"..pPPPPp..",
		"...pppp...",
	],
	# --- Reliques de la Faille ------------------------------------------------------------
	"cle_braise": [
		"..ooo.....",
		".oyyOo....",
		".oy.yO....",
		".oOyOo....",
		"..oOo.....",
		"...Oo.....",
		"...Ooo....",
		"...Oo.....",
		"...Ooo....",
	],
	"medaillon_fil": [
		"o.......o.",
		".o.....o..",
		"..o...o...",
		"...oOo....",
		"..oCCCo...",
		"..OCwCO...",
		"..oCCco...",
		"...oOo....",
		"..........",
	],
	"couronne_brisee": [
		"..........",
		"y...y.....",
		"Oo.oOo....",
		"OOoOOOo...",
		"OCOOPOOo..",
		"OOOOOOOOo.",
		"oooooooo..",
		"..........",
		"..........",
	],
	"cloche_ancienne": [
		"....ee....",
		"...eooe...",
		"..eoOOoe..",
		"..eoOOoe..",
		"..eoOOoe..",
		".eoOOOOoe.",
		"eeeeeeeeee",
		"....dd....",
		"..........",
	],
	"lampe_profondeurs": [
		"...mMMm...",
		"....MM....",
		"..mMMMMm..",
		"..MCCCCM..",
		"..MCwwCM..",
		"..MCCCCM..",
		"..mMMMMm..",
		"...mmmm...",
		"..........",
	],
	"tablette_gravee": [
		".ssssssss.",
		".sRRRRRRs.",
		".sRrrRrRs.",
		".sRRRRRRs.",
		".sRrRrrRs.",
		".sRRRRRRs.",
		".sRrrRRRs.",
		".sRRRRRRs.",
		".ssssssss.",
	],
}


## Image de la trouvaille (carnet, annonce). Inconnue : la silhouette sombre du même motif.
static func icone(id: String, decouverte: bool = true) -> Texture2D:
	if not MOTIFS.has(id):
		return Pixel.disque(3, Palette.couleur("roche.3"))
	var lignes := PackedStringArray(MOTIFS[id])
	if decouverte:
		return Pixel.motif(lignes, COULEURS, CONTOUR)
	var ombre := {}
	for lettre: String in COULEURS:
		ombre[lettre] = "roche.1"
	return Pixel.motif(lignes, ombre, "roche.2")


## Éclat d'une trouvaille en plongée : une étoile à quatre branches qui scintille (phase 0 à 3).
static func dessiner_eclat(toile: CanvasItem, centre: Vector2, zone: String, phase: int) -> void:
	var lueur := Palette.couleur(str(LUEURS.get(zone, "cyan.3")))
	var blanc := Palette.couleur("cyan.3")
	var longueur := 2 + (phase % 2)
	toile.draw_rect(Rect2(centre - Vector2(1, 1), Vector2(3, 3)), lueur)
	toile.draw_rect(Rect2(centre, Vector2.ONE), blanc)
	for d in range(2, 2 + longueur):
		for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			toile.draw_rect(Rect2(centre + direction * d, Vector2.ONE), lueur)
	if phase >= 2:
		for direction: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			toile.draw_rect(Rect2(centre + direction * 2, Vector2.ONE), lueur)
