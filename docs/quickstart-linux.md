# Lancer le prototype GDO sous Linux

Cette première ébauche est un **jeu Luanti autonome** : elle ne nécessite ni Minetest Game, ni mod externe, ni backend Go, ni serveur distant.

## 1. Prérequis

- Luanti installé (version récente recommandée).
- Git.

Sur Debian/Ubuntu, selon la version de ta distribution, le paquet peut s'appeler `luanti` ou `minetest`. Sur Debian, les dépôts peuvent fournir une version ancienne ; Flatpak ou le paquet officiel peut alors être préférable.

## 2. Récupérer et installer

```bash
git clone https://github.com/jeremiegoldberg/Grosdebile-online.git
cd Grosdebile-online
mkdir -p ~/.minetest/games
rm -rf ~/.minetest/games/gdo
cp -a game/gdo ~/.minetest/games/gdo
luanti
```

Si ton installation utilise un répertoire de données personnalisé, ouvre Luanti puis **À propos → Ouvrir le répertoire de données** et adapte le chemin.

Dans le menu, crée un monde et sélectionne **Gros Débile Online** comme jeu. Si la commande `luanti` n'existe pas, essaie `minetest` selon le nom du paquet installé.

## 3. Visite guidée : le Château des Brumes

- Tu apparais devant le château. Traverse le pont et la grande porte.
- Dans la cour, cherche le **Bureau des Quêtes** : les dragons attendront, le formulaire est prioritaire.
- Visite l'aile gauche et sa grande salle de banquet. La table est prévue pour un roi ; le budget, pour trois navets.
- Dans l'aile droite, la bibliothèque possède des rayonnages, une passerelle et des tables de lecture. Certains grimoires sont probablement maudits, mais correctement catalogués.
- Rejoins la salle de cours et la galerie des trophées.
- Clique droit sur les panneaux officiels pour découvrir les décrets absurdes de l’administration royale.\n- Visite les quatre pavillons de la cour : Bras Cassés, Mages du Dimanche, Rats de Bibliothèque et Seigneurs du Navet. Chaque blason est interactif : clique droit pour rejoindre la maison. Le choix est définitif dans cette version.\n- Utilise `/maisons` pour lire les devises et `/maison` pour consulter ton affectation. Si tu n’as pas encore choisi, `/maison` te rappelle comment faire.
- Gérard le Magnifique t'attend près de l'entrée de la cour. Clique droit sur lui pour accepter sa quête.
- Récolte les trois navets héroïques du jardin près de la grande porte, puis retourne voir Gérard.
- Tu reçois le Badge officiel du Nawak. Il ne donne aucun pouvoir, mais il est officiellement officiel.

La commande `/gdo` rappelle l'objectif et `/chateau` affiche la présentation du château.

## 4. Touches utiles

- ZQSD ou WASD : déplacement (selon la configuration).
- Espace : sauter.
- Souris : regarder autour de soi.
- Clic droit : interagir / parler / récolter.
- E : inventaire.
- Échap : menu.

## 5. Mise à jour du prototype

Pour mettre à jour une installation existante :

```bash
cd Grosdebile-online
git pull
rm -rf ~/.minetest/games/gdo
cp -a game/gdo ~/.minetest/games/gdo
```

La version actuelle du module reconstruit automatiquement le château une fois au prochain chargement d'un monde existant. La génération réécrit les blocs de la zone du château (environ x=-52..52, z=-58..52) : évite d'y construire tes propres bâtiments avant la mise à jour. Fais une sauvegarde du monde au préalable.

## 6. Limites connues

- C'est une démo locale mono-monde, pas encore un MMORPG.
- Le château est généré en blocs procéduraux ; le mobilier est stylisé et les textures sont provisoires.
- Le personnage de Gérard et les blocs utilisent des textures de remplacement ; les modèles et graphismes originaux viendront ensuite.
- Pas encore de compte web, classes, combat, sauvegarde centralisée, multijoueur public ou fédération ActivityPub.
- Le code n'a pas encore été validé par un lancement automatisé de Luanti sur une machine de test indépendante.

## Dépannage

Si le jeu n'apparaît pas dans la liste, vérifie que le chemin est exactement `~/.minetest/games/gdo/game.conf`, puis ferme et relance Luanti. En cas d'erreur Lua, consulte `debug.txt` dans le répertoire de données Luanti et joins les lignes autour de l'erreur.
