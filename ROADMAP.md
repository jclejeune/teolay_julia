Voici un résumé propre + une roadmap réaliste de **Teolay** basé sur ce que tu es en train de construire.

---

# 🧠 Teolay — résumé du projet

Teolay est une **application de visualisation / traitement d’images** basée sur Julia + GTK, orientée :

* ouverture de fichiers image
* affichage dans une UI desktop
* futur traitement / édition légère
* gestion de formats variés (y compris RAW via outils externes)

### 🔥 Philosophie implicite

* simple côté utilisateur
* robuste côté entrée (ne jamais casser sur un fichier inattendu)
* délégation aux outils spécialisés (RawTherapee / darktable)
* Teolay = interface + orchestration, pas moteur de développement RAW

---

# 🧱 Architecture actuelle (ou en cours)

### 1. UI

* GTK (canvas + fenêtre)
* bouton / file chooser
* trigger load image

### 2. Loader image

* `FileIO.load(path)`
* dépend de packages Julia (ImageIO, etc.)

### 3. Problème actuel

* tout fichier “image-like” passe dans `load`
* formats non supportés → crash brutal (WAV, RAW sans libs, etc.)

---

# 🚨 Problèmes identifiés

### 1. Absence de validation en entrée

* pas de filtre MIME
* pas de filtre extension fiable
* pipeline naïf

### 2. Gestion RAW inexistante

* NEF / RAF / CR2 etc.
* dépend de libs externes non installées → crash

### 3. UX d’erreur mauvaise

* stacktrace brute Julia
* aucune récupération UI

---

# 🧭 Vision cible

Teolay devient un **hub d’images intelligent** :

```
        INPUT FILE
            ↓
   ┌───────────────────┐
   │ Detection layer    │
   │ MIME + extension   │
   └───────────────────┘
        ↓          ↓
   Raster        RAW
    ↓             ↓
 direct load   external engine
 PNG/JPEG      RawTherapee / darktable
 WEBP/AVIF         ↓
                  TIFF 16-bit
                     ↓
               back into Teolay
```

---

# 🛣️ Roadmap proposée

## 🟢 Phase 1 — stabilisation (URGENT)

### Objectif : ne plus jamais crash sur un fichier

* [ ] filtre MIME (`image/*`)
* [ ] whitelist extensions raster
* [ ] try/catch global loader
* [ ] UI error dialog propre
* [ ] suppression stacktrace utilisateur

---

## 🟡 Phase 2 — support RAW externe

### Objectif : RAW utilisable sans crash

* [ ] détection RAW (NEF, CR2, RAF…)
* [ ] détection outils installés :

  * RawTherapee
  * darktable
* [ ] popup “ouvrir avec…”
* [ ] export TIFF 16-bit temporaire
* [ ] re-import dans Teolay

---

## 🔵 Phase 3 — pipeline propre

### Objectif : architecture stable

* [ ] abstraction “ImageSource”

  * raster file
  * raw file
  * external processed file
* [ ] cache des images développées
* [ ] mapping original → dérivé

---

## 🟣 Phase 4 — UX avancée

* [ ] drag & drop fichiers
* [ ] historique d’images ouvertes
* [ ] preview rapide RAW (thumbnail)
* [ ] sélection moteur RAW par défaut
* [ ] configuration persistée (TOML)

---

## 🟠 Phase 5 — outils image

(selon ton objectif final)

* zoom performant
* histogramme
* niveaux / courbes simples
* annotations
* export

---

# 🧠 Point clé stratégique

Teolay doit rester :

> un **orchestrateur d’images**, pas un développeur RAW.

Sinon tu retombes dans :

* explosion de dépendances
* bugs système (comme ton WAV + FileIO)
* maintenance ingérable

---

# ⚡ Résumé ultra simple

Teolay =

* UI GTK
* viewer d’images robuste
* pipeline de détection MIME
* RAW externalisé (RawTherapee / darktable)
* UX propre (pas de crash brut)

---

Si tu veux, prochaine étape logique je peux te faire :
👉 une **architecture de code Julia propre (modules + structure de projet + API interne)** pour éviter que ça devienne un “legacy GTK spaghetti” comme ton propre exemple 😄
