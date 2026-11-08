# Gros Débile Online

**Un MMORPG voxel libre, fédéré et multiplateforme — bienvenue au Royaume du Nawak !**

> Le monde a besoin de héros. On fait avec ce qu'on a.

Gros Débile Online (GDO) est un projet communautaire de MMORPG fantasy humoristique construit autour de [Luanti](https://www.luanti.org/). Son univers, ses règles et ses outils sont conçus pour être modifiables, auto-hébergeables et réutilisables.

## Vision

- **Un vrai MMORPG** : monde ouvert, exploration, classes, quêtes, donjons, boss, guildes et progression.
- **Un humour familial et parodique** : fantasy épique, personnages improbables et situations absurdes.
- **Open source** : code, monde, quêtes, cartes et assets originaux publiés sous des licences libres clairement identifiées.
- **Fédéré** : intégration progressive d'ActivityPub pour les profils, guildes, actualités et événements.
- **Multiplateforme** : PC et Android en priorité ; compatibilité VR Meta Quest via un portage Luanti/OpenXR à valider.
- **Auto-hébergeable** : chacun doit pouvoir lancer son propre serveur et créer sa variante du Royaume du Nawak.

## État du projet

**Prototype 0.5 — les quatre maisons du Château des Brumes.** Le démonstrateur comprend désormais une grande salle de banquet, une bibliothèque à rayonnages et passerelle, une salle de cours, un bureau des quêtes, une galerie des trophées, quatre pavillons avec salles communes et blasons interactifs, ainsi qu’un système d’affectation des joueurs à une maison. Le château conserve son donjon, ses remparts, ses tours et sa cour.

Les quatre maisons sont les **Bras Cassés** (courage avant compétence), les **Mages du Dimanche** (magie et effets secondaires), les **Rats de Bibliothèque** (érudition et phobie du grand air) et les **Seigneurs du Navet** (noblesse agricole). Le joueur choisit sa maison en cliquant sur son blason ; son choix est conservé dans ses métadonnées. Les commandes `/maisons` et `/maison` présentent les maisons et son affectation.\n\nL’identité humoristique est volontairement intégrée au décor : le banquet est plus grand que le budget nourriture, les grimoires sont classés selon des critères douteux, et toute aventure nécessite plusieurs formulaires. L'ensemble reste une architecture fantasy originale, sans reproduire un bâtiment existant.

> **À savoir :** la construction est procédurale et utilise encore des textures provisoires. Le prototype doit être lancé et vérifié dans Luanti ; il ne s'agit pas encore d'une démo graphiquement finalisée ni d'un MMORPG complet.

## Démarrage rapide sous Linux

Voir [docs/quickstart-linux.md](docs/quickstart-linux.md).

```bash
git clone https://github.com/jeremiegoldberg/Grosdebile-online.git
cd Grosdebile-online
mkdir -p ~/.minetest/games
cp -a game/gdo ~/.minetest/games/gdo
luanti
```

Dans Luanti, crée un monde et sélectionne **Gros Débile Online** comme jeu.

## Architecture cible

| Composant | Responsabilité |
|---|---|
| Client/serveur Luanti | Monde voxel, rendu, interactions et simulation de jeu |
| Game Lua `gdo` | Classes, combat, objets, PNJ, quêtes, progression et règles |
| Backend Go | Comptes web, personnages, services de guildes et API |
| PostgreSQL | Données persistantes métier |
| Service Fediverse | Identités ActivityPub, abonnements et publications |
| Kubernetes/Docker | Déploiement reproductible et exploitation |

Le serveur Luanti reste autoritaire pour les actions de gameplay. Le service Fediverse est indépendant : une panne de fédération ne doit jamais empêcher de jouer.

## Arborescence

```text
.
├── game/gdo/             # Jeu Luanti autonome et mods Lua
├── backend/              # API Go (à construire)
├── federation/           # Service ActivityPub (à construire)
├── database/             # Migrations SQL (à construire)
├── world/                # Données et définitions du monde
├── assets/               # Assets originaux et métadonnées de licence
├── deploy/               # Docker, Kubernetes et configuration
├── docs/                 # Architecture, lore, contribution et décisions
└── .github/              # CI et modèles de contribution
```

## Limites actuelles

- Démo locale, sans comptes web ni persistance centralisée.
- Une zone de départ et un château monumental ; une seule quête pour le moment.
- Textures de remplacement et mobilier en blocs ; modèles 3D, textures et éclairage artistiques à produire.
- Pas encore de classes, combat, économie, guildes, donjons, multijoueur public ou fédération ActivityPub.
- Génération et parcours du château à valider en conditions réelles sur plusieurs machines.

## Licences

- Code : **GNU AGPL v3.0 ou ultérieure** (`AGPL-3.0-or-later`).
- Monde, documentation et assets originaux : **Creative Commons Attribution-ShareAlike 4.0 International** (`CC-BY-SA-4.0`), sauf mention contraire dans leur répertoire.
- Les marques, noms et logos « Gros Débile Online » et « Royaume du Nawak » ne sont pas concédés par ces licences.

Les textes complets des licences et les notices de provenance doivent être ajoutés/vérifiés avant toute distribution publique d'une version logicielle ou d'un pack d'assets. Les dépendances et contenus tiers conservent leurs licences propres.

## Participer

Les contributions sont bienvenues : code, cartes, quêtes, traductions, tests, documentation et idées. Lire [CONTRIBUTING.md](CONTRIBUTING.md) avant de proposer une contribution.

---
Maintenu par la communauté de **Netasgard**. Le projet est indépendant de l'équipe Luanti et n'est pas affilié au projet officiel Luanti.
