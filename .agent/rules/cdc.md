---
trigger: always_on
---

# 📑 CAHIER DES CHARGES : KARROLLE ECOSYSTEM

**Projet :** Karrolle (Plateforme de Présentation Dynamique & Interactive)
**Version du document :** 1.0
**Identifiant :** `com.koudatek.karrolle`
**Cible :** Conférenciers, Enseignants, Journalistes, Commerciaux High-Level.

---

## I. VISION & OBJECTIFS

### 1.1 Le Concept

Karrolle est une suite logicielle de création et de diffusion de présentations. Contrairement à PowerPoint (linéaire) ou Canva (statique), Karrolle se concentre sur **l'interaction dynamique**.
L'écosystème repose sur une synergie totale entre un **Écran Principal** (PC/Projecteur) et une **Surface de Contrôle** (Smartphone/Tablette).

### 1.2 La Proposition de Valeur

* **"France 24 Experience" :** L'orateur manipule ses données en direct (zoom, déplacement) sans toucher au PC.
* **Format Propriétaire (`.karr`) :** Un format de fichier optimisé pour l'interactivité et la navigation non-linéaire.
* **Agnostique :** Capable d'importer l'existant (PowerPoint, PDF) pour ne pas perdre l'utilisateur, mais capable de l'enrichir.

---

## II. SPÉCIFICATIONS FONCTIONNELLES (Vision Globale)

Le projet se divise en 3 modules interconnectés au sein d'une même application Flutter.

### MODULE A : KARROLLE STUDIO (L'Éditeur PC)

C'est le "Canva" local. Il permet de créer ou d'assembler la présentation.

1. **Import Intelligent :**
* Import natif de fichiers `.pptx` (via conversion interne).
* Import de PDF et Images.


2. **Éditeur de "Scènes" (Pas de Slides) :**
* Système de **Canvas Infini** ou de Scènes.
* Ajout d'éléments : Textes, Images, Formes, Vidéos.


3. **Système de "Hotspots" (Interactivité) :**
* Création de zones invisibles cliquables.
* Définition d'actions : "Au clic ici -> Zoomer sur l'élément X", "Aller à la scène Y", "Afficher une pop-up".


4. **Export :** Sauvegarde en `.karr` (Package compressé JSON + Assets).

### MODULE B : KARROLLE PLAYER (Le Moteur de Rendu PC)

C'est le logiciel qui tourne pendant la présentation.

1. **Rendering Engine :** Moteur graphique haute performance (Flutter/Impeller) pour afficher les `.karr` en 60 FPS constants.
2. **Serveur Local :** Création automatique d'un réseau local (WebSocket) pour la télécommande.
3. **Mode "Spectacle" :** Transition fluide, animations de caméras (Pan & Zoom) pilotées par les données.

### MODULE C : KARROLLE REMOTE (L'Application Mobile)

C'est la régie de poche.

1. **Appairage Instantané :** Scan de QR Code (Zéro config IP).
2. **Retour Visuel (Visual Feedback) :** L'utilisateur voit la slide actuelle sur son téléphone.
3. **Mode "Trackpad Absolu" :**
* Toucher un élément sur le téléphone le déclenche sur le PC.
* Pinch-to-zoom sur le téléphone zoome le PC.


4. **Outils Présentateur :** Notes orateur, Timer, Pointeur Laser virtuel (le doigt sur le téléphone bouge un point rouge sur l'écran géant).

---

## III. ARCHITECTURE TECHNIQUE (La "Solid Stack")

Nous utilisons une approche hybride pour garantir la vitesse de dév (Flutter) et la puissance (C++ si besoin).

### 1. Le Cœur (Dart + FFI)

* **Langage Principal :** Dart (Flutter).
* **Pattern :** Clean Architecture + Riverpod.
* **Parsing Lourd :** Si le parsing `.pptx` en Dart est trop lent, nous utiliserons une librairie C++ via `dart:ffi`.

### 2. Le Format de Données (`.karr`)

C'est un fichier Archive (ZIP renommé) contenant :

* `manifest.json` : Méta-données (Auteur, Version).
* `structure.json` : L'arbre des scènes et des interactions.
* `/assets` : Dossier contenant les images et polices extraites.

### 3. Connectivité (Offline First)

* Protocole : **WebSockets** (TCP) pour les commandes fiables.
* Discovery : **mDNS** ou Scan QR Code.
* Sécurité : Chiffrement simple des commandes pour éviter qu'un spectateur ne prenne le contrôle.

---

## IV. ROADMAP & DÉCOUPAGE (Du MVP à la V1)

C'est ici que nous définissons ce que nous allons coder *maintenant*.

### PHASE 1 : LE MVP (Minimum Viable Product) - Objectif : 2 semaines

*Le but est de valider la chaîne "Import -> Affichage -> Contrôle Mobile".*

* **Périmètre Import :**
* Ne supporte pas la création depuis zéro.
* Supporte l'import d'un PPTX simple (Texte + Images) OU d'un dossier d'images.
* Convertit cela en une structure `.karr` basique en mémoire.


* **Périmètre Éditeur :**
* Inexistant. On affiche juste ce qu'on a importé.


* **Périmètre Player :**
* Affiche les "Scènes".
* Gère le Zoom et le Déplacement global.


* **Périmètre Remote :**
* Se connecte au PC.
* Affiche l'image de la scène actuelle.
* Gestes : Swipe (Suivant/Précédent), Pinch (Zoom PC), Pan (Déplacer PC).



### PHASE 2 : L'INTERACTIVITÉ (V0.5)

* Ajout de l'Éditeur basique : Possibilité de dessiner des rectangles "Hotspots" sur les slides importées.
* Implémentation du clic sur mobile qui déclenche le zoom sur PC.

### PHASE 3 : LE STUDIO (V1.0 - Lancement Commercial)

* Éditeur complet (Drag & Drop).
* Sauvegarde fichiers `.karr`.
* Licence payante pour l'app Remote (Freemium).

---

