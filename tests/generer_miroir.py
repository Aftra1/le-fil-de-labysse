#!/usr/bin/env python3
"""Miroir Python des scripts GDScript, pour les outils d'analyse qui ne lisent pas le GDScript (Graphify).

Lit tous les fichiers .gd du dépôt (scripts/ et tests/) et génère :
- docs/miroir/ : un fichier .py par script, avec la même arborescence. On y retrouve les classes
  (avec leur héritage), les constantes, les énumérations, les signaux, les variables membres typées et
  les fonctions (paramètres, type de retour, commentaire « ## »). Le corps de chaque fonction ne
  contient que ses appels (fonctions du même script, des scripts parents, des autres scripts,
  constructeurs, signaux), sans la logique du jeu ;
- docs/architecture.md : la liste des scripts avec leur rôle, leurs fonctions principales et leurs
  dépendances.

Godot n'est pas concerné : docs/ contient un fichier .gdignore, Godot n'y regarde jamais.

L'analyse est textuelle (pas de dépendance) : les types viennent des annotations (var x: Sac,
paramètres, retours), des inférences simples (var x := Sac.new(), as Sac, preload / load d'un
script ou d'une scène) et des affectations. Un appel dont la cible n'a pas de type connu (Node,
Variant…) n'apparaît pas.

Usage :
    python3 tests/generer_miroir.py              régénère docs/miroir/ et docs/architecture.md
    python3 tests/generer_miroir.py --verifier   vérifie qu'ils sont à jour (code 1 sinon)
"""

from __future__ import annotations

import keyword
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
DOSSIER_MIROIR = RACINE / "docs" / "miroir"
FICHIER_ARCHITECTURE = RACINE / "docs" / "architecture.md"
DOSSIERS_SOURCES = ("scripts", "tests")
ENTETE = "Fichier généré automatiquement, ne pas modifier."
COMMANDE = "python3 tests/generer_miroir.py"
MAX_FONCTIONS_ARCHI = 20

IDENT = r"[A-Za-z_]\w*"


# --- Modèle ------------------------------------------------------------------------------

@dataclass
class Fonction:
    nom: str
    statique: bool
    params: list[tuple[str, str]]          # (nom, type GDScript ou "")
    retour: str
    doc: list[str]
    lignes: list[str]                      # corps, nettoyé (sans chaînes ni commentaires)
    appels: list[tuple[str, str, str]] = field(default_factory=list)   # (genre, classe, nom)


@dataclass
class Script:
    chemin: str                            # relatif au dépôt, ex. scripts/sac.gd
    classe: str                            # class_name, nom d'autoload ou nom tiré du fichier
    nommee: bool                           # vraie si la classe est accessible par son nom en GDScript
    parent: str
    doc: list[str]
    constantes: list[tuple[str, str]] = field(default_factory=list)          # (nom, valeur brute)
    enums: list[tuple[str, list[tuple[str, str]]]] = field(default_factory=list)
    signaux: list[tuple[str, str]] = field(default_factory=list)             # (nom, paramètres)
    membres: dict[str, str] = field(default_factory=dict)                    # nom -> type
    membres_expr: dict[str, str] = field(default_factory=dict)               # nom -> expression := …
    statiques: set[str] = field(default_factory=set)
    fonctions: list[Fonction] = field(default_factory=list)
    lignes_classe: list[str] = field(default_factory=list)                   # code hors fonctions
    references: set[str] = field(default_factory=set)                        # classes citées

    def fonction(self, nom: str) -> Fonction | None:
        for f in self.fonctions:
            if f.nom == nom:
                return f
        return None

    @property
    def module(self) -> str:
        return self.chemin[:-3].replace("/", ".")


# --- Lecture du GDScript -----------------------------------------------------------------

RE_RESSOURCE = re.compile(r'\b(?:pre)?load\(\s*"(res://[^"]+)"\s*\)|"(res://[^"]+\.(?:gd|tscn))"')


def nettoyer(ligne: str, ressources: list[str]) -> str:
    """Retire chaînes et commentaires ; load("res://…") devient l'identifiant __RES_n__."""
    def remplacer(m: re.Match) -> str:
        ressources.append(m.group(1) or m.group(2))
        return f"__RES_{len(ressources) - 1}__"
    ligne = RE_RESSOURCE.sub(remplacer, ligne)
    sortie = []
    i = 0
    while i < len(ligne):
        c = ligne[i]
        if c == "#":
            break
        if c in "\"'":
            fin = i + 1
            while fin < len(ligne) and ligne[fin] != c:
                fin += 2 if ligne[fin] == "\\" else 1
            sortie.append('""')
            i = fin + 1
            continue
        sortie.append(c)
        i += 1
    return "".join(sortie).rstrip()


def indentation(ligne: str) -> int:
    return len(ligne) - len(ligne.lstrip("\t "))


def separer_params(texte: str) -> list[str]:
    """Découpe « a: int, b := Vector2(1, 2) » au niveau zéro des parenthèses."""
    morceaux, profondeur, courant = [], 0, ""
    for c in texte:
        if c in "([{":
            profondeur += 1
        elif c in ")]}":
            profondeur -= 1
        if c == "," and profondeur == 0:
            morceaux.append(courant)
            courant = ""
        else:
            courant += c
    if courant.strip():
        morceaux.append(courant)
    return [m.strip() for m in morceaux if m.strip()]


def lire_script(chemin: Path, autoloads: dict[str, str]) -> tuple[Script, list[str]]:
    rel = chemin.relative_to(RACINE).as_posix()
    brutes = chemin.read_text(encoding="utf-8").splitlines()
    ressources: list[str] = []
    propres = [nettoyer(l, ressources) for l in brutes]

    classe, parent = "", ""
    for l in propres:
        if m := re.match(rf"class_name\s+({IDENT})", l):
            classe = m.group(1)
        if m := re.match(rf"extends\s+({IDENT})", l):
            parent = m.group(1)
    nommee = bool(classe)
    if not classe:
        autoload = next((nom for nom, p in autoloads.items() if p == rel), "")
        nommee = bool(autoload)
        classe = autoload or "".join(mot.capitalize() for mot in chemin.stem.split("_"))

    # Commentaire de tête : les lignes « ## » qui suivent class_name / extends.
    doc: list[str] = []
    for l in brutes:
        if l.startswith(("class_name", "extends")):
            continue
        if l.startswith("##"):
            doc.append(l[2:].strip())
        else:
            break

    script = Script(rel, classe, nommee, parent, doc)
    i = 0
    doc_attente: list[str] = []
    while i < len(brutes):
        brute, propre = brutes[i], propres[i]
        if brute.startswith("##"):
            doc_attente.append(brute[2:].strip())
            i += 1
            continue
        if indentation(brute) > 0 or not propre.strip():
            if propre.strip():
                script.lignes_classe.append(propre)
            if not propre.strip() and not brute.strip():
                doc_attente = []
            i += 1
            continue

        # Déclaration au niveau de la classe (peut tenir sur plusieurs lignes).
        decl = propre
        while decl.count("(") + decl.count("[") + decl.count("{") > \
                decl.count(")") + decl.count("]") + decl.count("}") and i + 1 < len(brutes):
            i += 1
            decl += " " + propres[i].strip()
        decl = re.sub(r"^@\w+(\([^)]*\))?\s+", "", decl)

        if m := re.match(rf"(static\s+)?func\s+({IDENT})\s*\((.*)\)\s*(->\s*([^:]+))?:", decl):
            params = []
            for p in separer_params(m.group(3)):
                pm = re.match(rf"({IDENT})\s*(?::\s*([^=]+?))?\s*(:?=.*)?$", p)
                if pm:
                    params.append((pm.group(1), (pm.group(2) or "").strip()))
            corps = []
            j = i + 1
            while j < len(brutes) and (not brutes[j].strip() or indentation(brutes[j]) > 0
                                       or brutes[j].lstrip().startswith("#") and indentation(brutes[j]) > 0):
                if propres[j].strip():
                    corps.append(propres[j])
                j += 1
            script.fonctions.append(Fonction(m.group(2), bool(m.group(1)), params,
                                             (m.group(5) or "").strip(), doc_attente, corps))
            doc_attente = []
            i = j
            continue
        if m := re.match(rf"signal\s+({IDENT})\s*(?:\((.*)\))?", decl):
            script.signaux.append((m.group(1), (m.group(2) or "").strip()))
        elif m := re.match(rf"enum\s+({IDENT})\s*\{{(.*)\}}", decl):
            valeurs = []
            for v in separer_params(m.group(2)):
                vm = re.match(rf"({IDENT})\s*(?:=\s*(.+))?", v)
                if vm:
                    valeurs.append((vm.group(1), (vm.group(2) or "").strip()))
            script.enums.append((m.group(1), valeurs))
        elif m := re.match(rf"const\s+({IDENT})\s*(?::\s*([^=]+?))?\s*:?=\s*(.+)$", decl):
            chaine = re.match(r'const\s+\w+[^=]*=\s*("[^"\\]*")\s*(#.*)?$', brute)
            script.constantes.append((m.group(1), chaine.group(1) if chaine and "__RES_" not in decl
                                      else m.group(3).strip()))
            if (m.group(2) or "").strip():
                script.membres[m.group(1)] = m.group(2).strip()
            else:
                script.membres_expr[m.group(1)] = m.group(3).strip()
        elif m := re.match(rf"(static\s+)?var\s+({IDENT})\s*(?::\s*([^=:]+?))?\s*(?:(:?=)\s*(.+?))?:?\s*$", decl):
            nom = m.group(2)
            script.membres[nom] = (m.group(3) or "").strip()
            if m.group(5) and not script.membres[nom]:
                script.membres_expr[nom] = m.group(5).strip()
            if m.group(1):
                script.statiques.add(nom)
        if propre.strip() and not propre.startswith(("class_name", "extends")):
            script.lignes_classe.append(propre)
        doc_attente = []
        i += 1
    return script, ressources


def lire_autoloads() -> dict[str, str]:
    autoloads: dict[str, str] = {}
    dans_section = False
    for l in (RACINE / "project.godot").read_text(encoding="utf-8").splitlines():
        if l.startswith("["):
            dans_section = l.strip() == "[autoload]"
        elif dans_section and (m := re.match(r'(\w+)="\*?res://([^"]+)"', l)):
            autoloads[m.group(1)] = m.group(2)
    return autoloads


def lire_scenes() -> dict[str, tuple[str, list[str]]]:
    """Scène (chemin relatif) -> (script de la racine, scripts et scènes des autres nœuds)."""
    scenes: dict[str, tuple[str, list[str]]] = {}
    for chemin in sorted(RACINE.glob("scenes/**/*.tscn")):
        texte = chemin.read_text(encoding="utf-8")
        ids = {m.group(2): m.group(1) for m in
               re.finditer(r'\[ext_resource[^\]]*path="res://([^"]+)"[^\]]*id="([^"]+)"', texte)}
        racine, autres = "", []
        for bloc in re.split(r"\n(?=\[node )", texte)[1:]:
            entete = bloc.splitlines()[0]
            cibles = re.findall(r'(?:script|instance)\s*=\s*ExtResource\("([^"]+)"\)', bloc)
            for cible in cibles:
                if cible not in ids:
                    continue
                if "parent=" not in entete and ids[cible].endswith(".gd"):
                    racine = ids[cible]
                else:
                    autres.append(ids[cible])
        scenes[chemin.relative_to(RACINE).as_posix()] = (racine, sorted(set(autres)))
    return scenes


# --- Résolution des types et des appels --------------------------------------------------

class Projet:
    def __init__(self) -> None:
        self.autoloads = lire_autoloads()
        self.scenes = lire_scenes()
        self.scripts: list[Script] = []
        self.ressources: dict[str, list[str]] = {}
        sources = sorted(p for d in DOSSIERS_SOURCES for p in (RACINE / d).rglob("*.gd"))
        for chemin in sources:
            script, ressources = lire_script(chemin, self.autoloads)
            self.scripts.append(script)
            self.ressources[script.chemin] = ressources
        self.par_classe = {s.classe: s for s in self.scripts}
        self.par_chemin = {s.chemin: s for s in self.scripts}
        self.noms = {s.classe for s in self.scripts if s.nommee}

    # Types : « Sac » (instance), « classe:Sac » (la classe elle-même), « scene:Dive »,
    # « Array[Sac] », ou un type Godot sans intérêt ici.

    def type_ressource(self, script: Script, ident: str) -> str:
        m = re.fullmatch(r"__RES_(\d+)__", ident)
        if not m:
            return ""
        chemin = self.ressources[script.chemin][int(m.group(1))][len("res://"):]
        if chemin in self.par_chemin:
            return "classe:" + self.par_chemin[chemin].classe
        if chemin in self.scenes and self.scenes[chemin][0] in self.par_chemin:
            return "scene:" + self.par_chemin[self.scenes[chemin][0]].classe
        return ""

    def ancetres(self, classe: str) -> list[Script]:
        chaine = []
        while classe in self.par_classe and len(chaine) < 20:
            chaine.append(self.par_classe[classe])
            classe = self.par_classe[classe].parent
        return chaine

    def trouver(self, classe: str, nom: str) -> tuple[Script | None, str, str]:
        """Cherche nom dans la classe et ses parents : (script, genre, type)."""
        for s in self.ancetres(classe):
            if f := s.fonction(nom):
                return s, "fonction", f.retour
            if any(n == nom for n, _ in s.signaux):
                return s, "signal", "signal"
            if nom in s.membres:
                return s, "membre", s.membres[nom]
            if any(n == nom for n, _ in s.enums):
                return s, "enum", ""
        return None, "", ""

    @staticmethod
    def element(type_: str) -> str:
        if m := re.fullmatch(r"Array\[(\w+)\]", type_):
            return m.group(1)
        if m := re.fullmatch(r"Dictionary\[\w+,\s*(\w+)\]", type_):
            return m.group(1)
        return ""

    @staticmethod
    def classe_de(type_: str) -> str:
        return type_.split(":", 1)[-1] if type_ else ""

    def parcourir_chaines(self, texte: str):
        """Repère les chaînes « a.b(…)[…].c » : (début, fin, segments), segment = (nom, appel, index)."""
        n = len(texte)
        i = 0
        while i < n:
            m = re.compile(IDENT).match(texte, i)
            if not m or (i > 0 and (texte[i - 1].isalnum() or texte[i - 1] in "_.$%")):
                i += 1
                continue
            segments = []
            debut = pos = m.start()
            suite = m.end()     # on reprend après le premier nom : les arguments sont analysés aussi
            while True:
                m = re.compile(IDENT).match(texte, pos)
                if not m:
                    break
                nom, pos, appel, index = m.group(0), m.end(), False, False
                while pos < n and texte[pos] in "([":
                    ouvrant = texte[pos]
                    fermant = ")" if ouvrant == "(" else "]"
                    profondeur, k = 0, pos
                    while k < n:
                        if texte[k] in "([{":
                            profondeur += 1
                        elif texte[k] in ")]}":
                            profondeur -= 1
                            if profondeur == 0:
                                break
                        k += 1
                    if ouvrant == "(":
                        appel = True
                    else:
                        index = True
                    pos = k + 1
                segments.append((nom, appel, index))
                if pos < n and texte[pos] == "." and pos + 1 < n and re.match(IDENT, texte[pos + 1:]):
                    pos += 1
                    continue
                break
            yield debut, pos, segments
            i = suite

    def resoudre(self, script: Script, portee: dict[str, str], segments, appels=None) -> str:
        """Type de la chaîne ; ajoute les appels trouvés dans « appels »."""
        def noter(genre: str, classe: str, nom: str) -> None:
            if appels is not None and classe and (genre, classe, nom) not in appels:
                appels.append((genre, classe, nom))

        nom, appel, index = segments[0]
        type_ = ""
        if m := re.fullmatch(r"__AS_(\w+)__", nom):
            type_ = m.group(1)
        elif nom.startswith("__RES_"):
            type_ = self.type_ressource(script, nom)
        elif nom == "self":
            type_ = script.classe
        elif nom == "super":
            parent = self.par_classe.get(script.parent)
            if parent and appel:
                noter("parent", parent.classe, "_init")
            type_ = script.parent if parent else ""
        elif appel:
            proprietaire, genre, retour = self.trouver(script.classe, nom)
            if genre == "fonction":
                noter("parent" if proprietaire is not script else "interne", proprietaire.classe, nom)
                type_ = retour
        elif nom in portee:
            type_ = portee[nom]
        elif nom in self.noms:
            type_ = "classe:" + nom
        else:
            proprietaire, genre, t = self.trouver(script.classe, nom)
            if genre in ("membre", "signal"):
                type_ = t
                if genre == "signal" and len(segments) > 1:
                    noter("signal" if proprietaire is not script else "signal_interne",
                          proprietaire.classe, nom + "." + segments[1][0])
            elif genre == "fonction":
                # Fonction passée comme Callable (connect, tween_callback…) : elle sera appelée plus tard.
                noter("callable", proprietaire.classe, nom)
            elif genre == "enum":
                type_ = ""
        if index:
            type_ = self.element(type_)

        precedent = type_
        for k, (nom, appel, index) in enumerate(segments[1:], start=1):
            classe = self.classe_de(precedent)
            if precedent.startswith("scene:") and nom == "instantiate" and appel:
                noter("nouveau", classe, "instantiate")
                type_ = classe
            elif classe in self.par_classe and nom == "new" and appel:
                noter("nouveau", classe, "new")
                type_ = classe
            elif classe in self.par_classe:
                proprietaire, genre, t = self.trouver(classe, nom)
                interne = proprietaire is script and segments[0][0] in ("self", script.classe)
                if genre == "fonction" and appel:
                    noter("interne" if interne else "appel", proprietaire.classe, nom)
                    type_ = t
                elif genre == "signal":
                    suite = segments[k + 1][0] if k + 1 < len(segments) else ""
                    if interne and suite:
                        noter("signal_interne", proprietaire.classe, nom + "." + suite)
                    else:
                        noter("signal", proprietaire.classe, nom + ("." + suite if suite else ""))
                    type_ = "signal"
                elif genre == "membre":
                    type_ = t
                else:
                    type_ = ""
            else:
                type_ = ""
            if index:
                type_ = self.element(type_)
            precedent = type_
        return type_

    def type_expression(self, script: Script, portee: dict[str, str], expr: str, appels=None) -> str:
        expr = expr.strip()
        if litteral := type_litteral(expr):
            return litteral
        if m := re.fullmatch(rf"({IDENT})\.{IDENT}", expr):
            if any(n == m.group(1) for n, _ in script.enums):
                return m.group(1)
        if m := re.search(rf"\bas\s+({IDENT})\s*$", expr):
            return m.group(1)
        type_ = ""
        for debut, fin, segments in self.parcourir_chaines(expr):
            t = self.resoudre(script, portee, segments, appels)
            if debut == 0 and fin == len(expr):    # l'expression est une seule chaîne
                type_ = t
        return type_

    @staticmethod
    def remplacer_as(ligne: str, noms: set[str]) -> str:
        """« (x as Sac).f() » -> « __AS_Sac__.f() »."""
        def remplacer(m: re.Match) -> str:
            return f"__AS_{m.group(1)}__" if m.group(1) in noms else m.group(0)
        return re.sub(rf"\((?:[^()]|\([^()]*\))*?\bas\s+({IDENT})\s*\)", remplacer, ligne)

    def analyser_fonction(self, script: Script, f: Fonction, appels=None) -> dict[str, str]:
        portee = {nom: t for nom, t in f.params}
        for ligne in f.lignes:
            ligne = self.remplacer_as(ligne, self.noms)
            texte = ligne.strip()
            if m := re.match(rf"var\s+({IDENT})\s*(?::\s*([^=]+?))?\s*(?::?=\s*(.+))?$", texte):
                nom, annonce, valeur = m.group(1), (m.group(2) or "").strip(), m.group(3) or ""
                t = self.type_expression(script, portee, valeur, appels) if valeur else ""
                portee[nom] = annonce or t
                continue
            if m := re.match(rf"for\s+({IDENT})\s*(?::\s*(\w+))?\s+in\s+(.+):$", texte):
                t = self.type_expression(script, portee, m.group(3), appels)
                portee[m.group(1)] = m.group(2) or self.element(t)
                continue
            if m := re.match(rf"({IDENT})\s*=\s*([^=].*)$", texte):
                t = self.type_expression(script, portee, m.group(2), appels)
                cible = m.group(1)
                if t and cible not in portee and self.classe_de(t) in self.par_classe:
                    declare = script.membres.get(cible)
                    if declare is not None and self.classe_de(declare) not in self.par_classe:
                        script.membres[cible] = t
                continue
            for _, _, segments in self.parcourir_chaines(texte):
                self.resoudre(script, portee, segments, appels)
        return portee

    def analyser(self) -> None:
        # Types des membres déclarés par « := » puis affinés par les affectations (deux passes).
        for _ in range(3):
            for s in self.scripts:
                for nom, expr in s.membres_expr.items():
                    t = self.type_expression(s, {}, expr)
                    if t:
                        s.membres[nom] = t
                for f in s.fonctions:
                    self.analyser_fonction(s, f)
        for s in self.scripts:
            for f in s.fonctions:
                f.appels = []
                self.analyser_fonction(s, f, f.appels)
            # Classes citées partout dans le fichier (types, appels, code de classe).
            texte = "\n".join(s.lignes_classe + [l for f in s.fonctions for l in f.lignes])
            texte += "\n" + "\n".join(t for _, t in s.membres.items())
            texte += "\n" + "\n".join(t for f in s.fonctions for _, t in f.params) + \
                     "\n" + "\n".join(f.retour for f in s.fonctions)
            for nom in self.noms:
                if nom != s.classe and re.search(rf"(?<![\w.]){nom}\b", texte):
                    s.references.add(nom)
            for i in range(len(self.ressources[s.chemin])):
                t = self.type_ressource(s, f"__RES_{i}__")
                if t and self.classe_de(t) != s.classe:
                    s.references.add(self.classe_de(t))
            for f in s.fonctions:
                for _, classe, _ in f.appels:
                    if classe != s.classe:
                        s.references.add(classe)
            if s.parent in self.par_classe:
                s.references.add(s.parent)


# --- Écriture du miroir -------------------------------------------------------------------

def type_litteral(expr: str) -> str:
    if re.fullmatch(r"-?\d+\.\d*(e-?\d+)?", expr):
        return "float"
    if re.fullmatch(r"-?\d+", expr):
        return "int"
    if expr in ("true", "false"):
        return "bool"
    if expr == '""':
        return "String"
    if m := re.fullmatch(rf"(Vector2i?|Color|Rect2|Array|Dictionary|PackedStringArray)\(.*\)", expr):
        return m.group(1)
    if m := re.fullmatch(rf"([A-Z]\w*)\.new\(.*\)", expr):
        return m.group(1)
    if m := re.fullmatch(rf"([A-Z]\w*)\.[A-Z_0-9]+", expr):
        return m.group(1)
    if expr.startswith("["):
        return "Array"
    if expr.startswith("{"):
        return "Dictionary"
    return ""


def nom_python(nom: str) -> str:
    return nom + "_" if keyword.iskeyword(nom) or nom in ("None", "True", "False") else nom


def valeur_python(brute: str) -> str:
    brute = brute.strip()
    if re.fullmatch(r'-?\d+(\.\d+)?(e-?\d+)?|"[^"\\]*"', brute):
        return brute
    if brute in ("true", "false"):
        return brute.capitalize()
    if brute == "null":
        return "None"
    return "..."


def chemin_miroir(script: Script) -> Path:
    return DOSSIER_MIROIR / (script.chemin[:-3] + ".py")


def import_relatif(depuis: str, vers_module: str) -> str:
    """Module relatif de vers_module (« scripts.sac ») vu depuis le fichier depuis (« tests/x.gd »)."""
    profondeur = depuis.count("/")
    return "." * (profondeur + 1) + vers_module


def annotation(projet: Projet, type_: str) -> str:
    classe = projet.classe_de(type_)
    if classe in projet.par_classe and not type_.startswith("Array"):
        return classe
    return repr(type_) if type_ else ""


def miroir(projet: Projet, s: Script, ressources: list[str]) -> str:
    sortie: list[str] = [f"# {ENTETE}", f"# Source : {s.chemin} (le jeu n'utilise que le GDScript).",
                         f"# Régénérer : {COMMANDE}"]
    doc = "\n".join(s.doc).strip()
    if doc:
        sortie.append('"""' + doc.replace("\\", "\\\\").replace('"""', "'''") + '\n"""')
    sortie += ["", "from __future__ import annotations", ""]

    imports: dict[str, set[str]] = {}
    base = "godot"
    if s.parent in projet.par_classe:
        imports.setdefault(projet.par_classe[s.parent].module, set()).add(s.parent)
    elif s.parent:
        imports.setdefault(base, set()).add(s.parent)
    if s.signaux:
        imports.setdefault(base, set()).add("Signal")
    for nom in s.references:
        imports.setdefault(projet.par_classe[nom].module, set()).add(nom)
    if s.enums:
        sortie.append("from enum import IntEnum")
    for module in sorted(imports):
        noms = ", ".join(sorted(imports[module]))
        sortie.append(f"from {import_relatif(s.chemin, module)} import {noms}")
    sortie += ["", ""]

    entete = f"class {s.classe}({s.parent}):" if s.parent else f"class {s.classe}:"
    sortie.append(entete)
    corps: list[str] = []
    for nom, valeurs in s.enums:
        corps.append(f"class {nom}(IntEnum):")
        suivant = 0
        for v, explicite in valeurs:
            if explicite and re.fullmatch(r"-?\d+", explicite):
                suivant = int(explicite)
            corps.append(f"    {nom_python(v)} = {suivant}")
            suivant += 1
        corps.append("")
    for nom, brute in s.constantes:
        t = projet.type_expression(s, {}, brute) if "__RES_" in brute or "preload" in brute else ""
        if not t:
            ressource = re.fullmatch(r"__RES_(\d+)__", brute.strip())
            t = projet.type_ressource(s, brute.strip()) if ressource else ""
        if t:
            corps.append(f"{nom_python(nom)} = {projet.classe_de(t)}")
        else:
            corps.append(f"{nom_python(nom)} = {valeur_python(brute)}")
    for nom, params in s.signaux:
        corps.append(f"{nom_python(nom)} = Signal({params!r})")
    for nom, type_ in s.membres.items():
        if any(nom == c for c, _ in s.constantes):
            continue
        a = annotation(projet, type_)
        corps.append(f"{nom_python(nom)}: {a or repr('Variant')}")
    if corps:
        corps.append("")

    for f in s.fonctions:
        params = [] if f.statique else ["self"]
        for nom, type_ in f.params:
            a = annotation(projet, type_)
            params.append(f"{nom_python(nom)}: {a}" if a else nom_python(nom))
        retour = annotation(projet, f.retour)
        if f.statique:
            corps.append("@staticmethod")
        corps.append(f"def {nom_python(f.nom)}({', '.join(params)})" + (f" -> {retour}" if retour else "") + ":")
        if f.doc:
            texte = "\n    ".join(f.doc).replace("\\", "\\\\").replace('"""', "'''")
            corps.append(f'    """{texte}"""')
        if not f.appels:
            corps.append("    ...")
        for genre, classe, nom in f.appels:
            if genre == "nouveau":
                corps.append(f"    {classe}()" + ("  # instantiate()" if nom == "instantiate" else ""))
            elif genre == "signal":
                signal, _, methode = nom.partition(".")
                corps.append(f"    {classe}.{nom_python(signal)}" + (f".{methode}(...)" if methode else ""))
            elif genre == "signal_interne":
                signal, _, methode = nom.partition(".")
                corps.append(f"    self.{nom_python(signal)}.{methode}(...)")
            elif genre == "interne":
                appele = s.fonction(nom)
                cible = s.classe if appele is not None and appele.statique else "self"
                corps.append(f"    {cible}.{nom_python(nom)}(...)")
            elif genre == "parent":
                corps.append(f"    {classe}.{nom_python(nom)}(self, ...)")
            elif genre == "callable":
                cible = "self" if classe == s.classe else classe
                corps.append(f"    {cible}.{nom_python(nom)}  # passée comme Callable")
            else:
                corps.append(f"    {classe}.{nom_python(nom)}(...)")
        corps.append("")
    while corps and not corps[-1]:
        corps.pop()
    if not corps:
        corps = ["..."]
    sortie += ["    " + l if l else "" for bloc in corps for l in bloc.split("\n")]
    return "\n".join(sortie) + "\n"


def miroir_godot(projet: Projet) -> str:
    bases = sorted({s.parent for s in projet.scripts if s.parent and s.parent not in projet.par_classe})
    sortie = [f"# {ENTETE}", f"# Régénérer : {COMMANDE}",
              '"""Classes de Godot dont héritent les scripts du jeu (noms seulement)."""', "", ""]
    sortie += ["class Signal:", '    """Signal Godot (paramètres en texte)."""', "",
               "    def __init__(self, parametres: str = '') -> None:", "        self.parametres = parametres",
               "", "    def connect(self, *args) -> None:", "        ...", "",
               "    def emit(self, *args) -> None:", "        ...", "", ""]
    for b in bases:
        sortie += [f"class {b}:", "    ...", "", ""]
    return "\n".join(sortie).rstrip() + "\n"


# --- docs/architecture.md ----------------------------------------------------------------

def premier_paragraphe(lignes: list[str]) -> str:
    morceaux = []
    for l in lignes:
        if not l:
            break
        morceaux.append(l)
    return " ".join(morceaux).replace("|", "\\|")


def premiere_phrase(lignes: list[str]) -> str:
    phrase = re.split(r"(?<=[.!?])\s", premier_paragraphe(lignes))[0]
    return phrase if len(phrase) <= 180 else phrase[:179].rstrip() + "…"


def architecture(projet: Projet) -> str:
    utilise_par: dict[str, set[str]] = {s.classe: set() for s in projet.scripts}
    for s in projet.scripts:
        for r in s.references:
            utilise_par[r].add(s.classe)

    sortie = ["# Architecture du code", "",
              f"> {ENTETE} Source : les scripts `.gd` ; régénérer avec `{COMMANDE}`.",
              "> Miroir Python (pour les outils qui ne lisent pas le GDScript) : `docs/miroir/`.", ""]
    sortie += ["## Vue d'ensemble", ""]
    sortie += ["| Script | Classe | Hérite de | Rôle |", "|---|---|---|---|"]
    for s in projet.scripts:
        sortie.append(f"| `{s.chemin}` | {s.classe} | {s.parent} | {premiere_phrase(s.doc)} |")
    sortie += ["", "## Autoloads", ""]
    for nom, chemin in sorted(projet.autoloads.items()):
        sortie.append(f"- **{nom}** : `{chemin}`")
    sortie += ["", "## Scènes", ""]
    for scene, (racine, autres) in projet.scenes.items():
        ligne = f"- `{scene}` : racine `{racine or '—'}`"
        if autres:
            ligne += " ; contient " + ", ".join(f"`{a}`" for a in autres)
        sortie.append(ligne)

    groupes = [("Autoloads", lambda s: s.chemin.startswith("scripts/autoload/")),
               ("Scripts du jeu", lambda s: s.chemin.startswith("scripts/") and "/autoload/" not in s.chemin),
               ("Tests", lambda s: s.chemin.startswith("tests/"))]
    for titre, filtre in groupes:
        sortie += ["", f"## {titre}"]
        for s in filter(filtre, projet.scripts):
            sortie += ["", f"### `{s.chemin}` : {s.classe}", ""]
            if s.doc:
                sortie += [premier_paragraphe(s.doc), ""]
            if s.parent:
                sortie.append(f"- **Hérite de** : {s.parent}")
            if s.signaux:
                sortie.append("- **Signaux** : " + ", ".join(
                    f"`{n}({p})`" if p else f"`{n}`" for n, p in s.signaux))
            publiques = [f for f in s.fonctions if not f.nom.startswith("_")]
            if publiques:
                sortie.append("- **Fonctions principales** :")
                for f in publiques[:MAX_FONCTIONS_ARCHI]:
                    params = ", ".join(n for n, _ in f.params)
                    ligne = f"  - `{f.nom}({params})`"
                    if f.doc:
                        ligne += " : " + premier_paragraphe(f.doc)
                    sortie.append(ligne)
                if len(publiques) > MAX_FONCTIONS_ARCHI:
                    sortie.append(f"  - … et {len(publiques) - MAX_FONCTIONS_ARCHI} autres")
            elif s.fonctions:
                sortie.append("- **Fonctions** : " + ", ".join(f"`{f.nom}`" for f in s.fonctions[:MAX_FONCTIONS_ARCHI]))
            dependances = sorted(s.references)
            sortie.append("- **Dépend de** : " + (", ".join(dependances) if dependances else "aucun script"))
            utilisateurs = sorted(utilise_par[s.classe])
            if utilisateurs:
                sortie.append("- **Utilisé par** : " + ", ".join(utilisateurs))
    return "\n".join(sortie) + "\n"


# --- Programme ----------------------------------------------------------------------------

def fichiers_attendus() -> dict[Path, str]:
    projet = Projet()
    projet.analyser()
    fichiers: dict[Path, str] = {}
    dossiers = {DOSSIER_MIROIR}
    for s in projet.scripts:
        chemin = chemin_miroir(s)
        fichiers[chemin] = miroir(projet, s, projet.ressources[s.chemin])
        d = chemin.parent
        while d != DOSSIER_MIROIR:
            dossiers.add(d)
            d = d.parent
    for d in dossiers:
        fichiers[d / "__init__.py"] = f"# {ENTETE}\n"
    fichiers[DOSSIER_MIROIR / "godot.py"] = miroir_godot(projet)
    fichiers[FICHIER_ARCHITECTURE] = architecture(projet)
    for chemin, texte in fichiers.items():
        if chemin.suffix == ".py":
            compile(texte, str(chemin), "exec")     # le miroir doit rester du Python valide
    return fichiers


def main() -> int:
    verifier = "--verifier" in sys.argv[1:]
    attendus = fichiers_attendus()
    existants = set(DOSSIER_MIROIR.rglob("*.py")) if DOSSIER_MIROIR.exists() else set()
    differents = [c for c, t in attendus.items()
                  if not c.exists() or c.read_text(encoding="utf-8") != t]
    en_trop = sorted(existants - set(attendus))
    if verifier:
        for c in differents:
            print(f"FAIL miroir pas à jour : {c.relative_to(RACINE)}")
        for c in en_trop:
            print(f"FAIL miroir en trop : {c.relative_to(RACINE)}")
        if differents or en_trop:
            print(f"Lancer : {COMMANDE}")
            return 1
        print(f"PASS miroir à jour ({len(attendus)} fichiers)")
        return 0
    for c in en_trop:
        c.unlink()
    for c, texte in attendus.items():
        c.parent.mkdir(parents=True, exist_ok=True)
        if c in differents:
            c.write_text(texte, encoding="utf-8")
    print(f"{len(differents)} fichier(s) écrit(s), {len(en_trop)} supprimé(s), "
          f"{len(attendus)} au total (docs/miroir/, docs/architecture.md).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
