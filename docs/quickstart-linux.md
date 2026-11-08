# Lancer le prototype GDO sous Linux

Cette première ébauche est un **jeu Luanti autonome** : elle ne nécessite ni Minetest Game, ni mod externe, ni backend Go, ni serveur distant.

## 1. Prérequis

- Luanti installé (version récente recommandée).
- Git.

Sur Debian/Ubuntu, selon la version de ta distribution, le paquet peut s'appeler `luanti` ou `minetest`. Sur Debian, les dépôts peuvent fournir une version ancienne ; Flatpak ou le paquet officiel peut alors être préférable.

## 2. Récupérer le projet

```bash
git clone https://github.com/jeremiegoldberg/Grosdebile-online.git
cd Grosdebile-online
```

## 3. Installer le jeu dans Luanti

Le répertoire utilisateur Linux de Luanti est généralement `~/.minetest`.

```bash
mkdir -p ~/.minetest/games
rm -rf ~/.minetest/games/gdo
cp -a game/gdo ~/.minetest/games/gdo
```

Si ton installation utilise un répertoire de données personnalisé, ouvre Luanti puis **À propos → Ouvrir le répertoire de données** et adapte le chemin.

## 4. Démarrer

```bash
luanti
```

Dans le menu :
1. Ouvre **Jouer**.
2. Crée un nouveau monde.
3. Sélectionne **Gros Débile Online** comme jeu.
4. Choisis le monde et clique sur **Jouer**.

Si la commande `luanti` n'existe pas, essaie `minetest` selon le nom du paquet installé.

## 5. Visite guidée du Château des Brumes

- Tu apparais devant le château. Avance vers la grande porte et traverse le pont.
- Explore la cour intérieure et repère les tours du donjon.
- Entre dans l'aile gauche pour découvrir la grande salle : tables de banquet, estrade et lustres.
- Visite l'aile droite : la bibliothèque possède des rayonnages sur plusieurs niveaux, une passerelle et des tables de lecture.
- Rejoins le donjon central pour voir l'escalier monumental, la salle du conseil et la salle de cours.
- Gérard le Magnifique t'attend près de l'entrée de la cour.
- Fais un **clic droit** sur Gérard pour accepter sa quête.
- Récolte les trois navets du jardin près de la grande porte avec un clic droit, puis retourne voir Gérard.
- Tu reçois le Badge officiel du Nawak.

La commande `/gdo` rappelle l'objectif et `/chateau` affiche la présentation du château.

## 6. Touches utiles

Les touches sont celles configurées dans Luanti :
- ZQSD ou WASD : déplacement (selon la configuration).
- Espace : sauter.
- Souris : regarder autour de soi.
- Clic droit : interagir / parler / récolter.
- E : inventaire.
- Échap : menu.

## 7. Mise à jour du prototype

Pour mettre à jour une installation existante :

```bash
cd Grosdebile-online
git pull
rm -rf ~/.minetest/games/gdo
cp -a game/gdo ~/.minetest/games/gdo
```

La version actuelle du module reconstruit automatiquement le château une fois au prochain chargement d'un monde existant. La génération réécrit les blocs de la zone du château (environ x=-52..52, z=-58..52) : évite d'y construire tes propres bâtiments avant la mise à jour. Fais une sauvegarde du monde au préalable.

## 8. Limites connues

- C'est une démo locale mono-monde, pas encore un MMORPG.
- Le château est généré en blocs procéduraux ; le mobilier est volontairement stylisé et les textures sont provisoires.
- Le personnage de Gérard et les blocs utilisent des textures de remplacement ; les modèles et graphismes originaux viendront ensuite.
- Pas encore de compte web, classes, combat, sauvegarde centralisée, multijoueur public ou fédération ActivityPub.
- Le code n'a pas encore été validé par un lancement automatisé de Luanti sur une machine de test indépendante.

## Dépannage

Si le jeu n'apparaît pas dans la liste :
- vérifie que le chemin est exactement `~/.minetest/games/gdo/game.conf` ;
- ferme puis relance Luanti ;
- vérifie que le dossier `gdo` n'est pas imbriqué dans un second dossier `gdo`.

En cas d'erreur Lua, consulte `debug.txt` dans le répertoire de données Luanti et joins les lignes autour de l'erreur.
