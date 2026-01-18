---
trigger: always_on
---

**📅 18 janvier 2026 — ⏰ 11:42 (UTC)**

Parfait. Là on parle **sérieusement**.
Tu ne veux pas “un petit projet”, tu veux **les fondations d’un futur géant**. Un **éditeur visuel type Canva / PowerPoint**, extensible vers l’animation, le design, l’éducation, le business, etc. Donc on va raisonner **comme une vraie équipe produit + technique**.

👉 Stack validé : **B) Flutter (UI) + C++ (moteur)**
C’est **très bon choix**, professionnel, scalable, et compatible avec tes ambitions long terme (perf, contrôle, export, formats, IA plus tard).

---

# 🧠 HISTOIRE DU LOGICIEL — VISION PRODUIT

### 🎯 Nom de code (provisoire)

> **KoudaStudio Engine** (tu renommeras plus tard)

### 🎯 Objectif

Créer un **éditeur visuel universel** permettant de :

* Créer des présentations (type PowerPoint)
* Créer des designs (type Canva)
* Plus tard : animation 2D, vidéos, contenus éducatifs, export vers d’autres plateformes

👉 **Un seul moteur**, plusieurs usages.

---

# 🧱 ARCHITECTURE GLOBALE

## 🟦 Flutter — Frontend (Interface)

Responsable de :

* Fenêtres
* Boutons
* Menus
* Panneaux d’outils
* Timeline plus tard
* Gestion souris / clavier
* UX fluide

Flutter ne dessine PAS les objets finaux, il **envoie des commandes** au moteur.

---

## 🟥 C++ — Core Engine (Cerveau)

Responsable de :

* Canvas
* Rendu graphique
* Objets (textes, images, formes…)
* Sélection
* Déplacement
* Zoom
* Layers
* Import / Export
* Formats fichiers
* Plus tard : animation, vidéo, IA

👉 C’est ici que vit la vraie puissance.

---

## 🔗 Communication Flutter ⇄ C++

Via :

* **FFI (Foreign Function Interface)**
* Flutter appelle des fonctions C++
* C++ renvoie états et données

Schéma :

```
Utilisateur clique
→ Flutter capte
→ Flutter appelle C++
→ C++ modifie la scène
→ Flutter rafraîchit l’affichage
```

---

# 🧭 WORKFLOW UTILISATEUR (COMMENT ON UTILISE LE LOGICIEL)

## 🟢 Démarrage

Écran d’accueil :

* Nouveau projet
* Ouvrir projet
* Importer PowerPoint

---

## 🟢 Nouveau projet

Choix :

* Format (16:9, A4, carré…)
* Fond blanc

Puis ouverture de :

## 👉 Workspace principal

Zones :

```
┌──────── Menu ────────┐
│ Fichier  Edition ... │
├─Tools─┬── Canvas ────┤
│ Text  │              │
│ Shape │   🎨 ZONE    │
│ Image │   DE TRAVAIL │
│ ...   │              │
├───────┴─ Properties ─┤
│ Taille | Couleur ... │
└──────────────────────┘
```

---

## 🟢 Ajout d’objet

Ex : Rectangle

1. Clic outil Rectangle (Flutter)
2. Flutter → `engine_add_shape(type=RECT)`
3. C++ crée un objet Shape
4. Ajout dans Scene Graph
5. Canvas se redessine

---

## 🟢 Sélection

1. Clic sur objet
2. Flutter → `engine_pick(x,y)`
3. C++ détecte objet
4. Retour ID objet
5. Flutter affiche cadres de sélection

---

## 🟢 Déplacement

1. Drag souris
2. Flutter → `engine_move(id, dx, dy)`
3. C++ met à jour position
4. Redraw

---

## 🟢 Propriétés

Quand tu modifies couleur, taille, police :

Flutter → C++ → modification de l’objet

---

# 🧠 ARCHITECTURE INTERNE C++ (TRÈS IMPORTANT)

## 🎯 Scene Graph

Structure :

```
Scene
 ├── Layer
 │    ├── Object
 │    │     ├── Transform
 │    │     ├── Style
 │    │     └── Geometry
```

Chaque objet :

* Position
* Rotation
* Scale
* Z-index
* Type (texte, image, forme…)

---

## 🎯 Types d’objets

Classe de base :

```cpp
class Drawable {
 public:
   virtual void draw();
   Transform transform;
};
```

Héritage :

* Shape
* Text
* Image
* Group

👉 Comme dans Blender, After Effects, etc.

---

## 🎯 Rendu graphique

Options :

### 🔥 Option PRO (recommandée)

* Skia (moteur graphique de Chrome & Flutter)
* Ultra rapide
* Vectoriel parfait

### Autres

* OpenGL / Vulkan → plus complexe

👉 Skia = très bon compromis.

---

# 📂 FORMATS DE FICHIERS

## 🟢 Format interne

Ton propre format :

```json
{
  "slides": [
    {
      "objects": [
        { "type": "rect", "x":10, "y":20, "w":100 }
      ]
    }
  ]
}
```

Simple → rapide → contrôlable.

---

## 🟢 Import PowerPoint

⚠️ Vérité crue :
PowerPoint est **un format compliqué**.

Méthode :

1. PPTX = ZIP
2. XML internes
3. Parser :

   * textes
   * images
   * positions

👉 Tu ne reproduis PAS 100% PowerPoint au début.
Tu fais :

* textes
* images
* rectangles
* positions

Déjà énorme travail.

---

## 🟢 Export

Vers :

* PDF
* Images
* PPTX simplifié plus tard

---

# 🧠 POURQUOI FLUTTER + C++ EST STRATÉGIQUE

### Flutter

✔ UI rapide
✔ Multiplateforme
✔ Animations fluides
✔ Déploiement futur web/mobile

---

### C++

✔ Performance
✔ Accès GPU
✔ Algorithmes lourds
✔ IA plus tard
✔ Moteur réutilisable

👉 Tu construis un **vrai moteur graphique**, pas juste une app.

---

# 🧩 PHASES DE DÉVELOPPEMENT (RÉALISTES)

## 🔹 Phase 1 — Base graphique

* Fenêtre
* Canvas
* Zoom / Pan
* Affichage objets

🎯 Objectif : voir des formes

---

## 🔹 Phase 2 — Objets

* Rectangle
* Cercle
* Texte
* Image

🎯 Objectif : mini PowerPoint

---

## 🔹 Phase 3 — Interaction

* Sélection
* Drag
* Resize
* Layers

🎯 Objectif : vrai éditeur

---

## 🔹 Phase 4 — Slides

* Plusieurs pages
* Navigation

🎯 Objectif : présentations

---

## 🔹 Phase 5 — Import/Export

* JSON
* PDF
* PPTX partiel

🎯 Objectif : utile en vrai

---

## 🔹 Phase 6 — Extensions

* Animation
* Vidéo
* Templates
* IA

🎯 Objectif : plateforme

---

# ⚠️ RÉALITÉ TECHNIQUE (JE NE TE MENTIRAI PAS)

Je vais être très clair, sans sucre :

* ❌ Ce n’est PAS un projet facile
* ❌ Ce n’est PAS rapide
* ❌ Ce n’est PAS un projet solo “week-end”

MAIS :

* ✔ C’est EXACTEMENT le genre de projet qui te fait passer du niveau étudiant → ingénieur produit
* ✔ C’est une base pour toute ta vision IA / animation / éducation
* ✔ C’est monéta­risable

👉 Ce que tu veux faire, c’est **ce que font des équipes de 30–100 ingénieurs**.
Toi tu commences **petit, mais avec une architecture de grand**.

---

# 🎯 CE QUE JE TE PROPOSE MAINTENANT (TRÈS CONCRET)

Prochaine étape logique :

## ✅ 1. Cahier des charges officiel (document)

Avec :

* Objectifs
* Fonctionnalités v1
* Architecture
* Choix techniques
* Planning

👉 Document que tu peux donner à ton coéquipier Gravity.

---

## ✅ 2. Architecture technique détaillée

Je te fais :

* Diagrammes modules
* API Flutter ⇄ C++
* Organisation dossiers

---

## ✅ 3. Roadmap d’apprentissage

Parce que pour ça tu dois maîtriser :

* C++ intermédiaire
* Graphisme 2D
* Architecture logicielle

---
