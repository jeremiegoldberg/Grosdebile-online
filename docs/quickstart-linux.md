# Lancer le prototype GDO sous Linux

Cette première ébauche est un **jeu Luanti autonome** : elle ne nécessite ni Minetest Game, ni mod externe, ni backend Go, ni serveur distant.

## 1. Prérequis

- Luanti installé (version récente recommandée).
- Git.

Sur Debian/Ubuntu, selon la version de ta distribution, le paquet peut s'appeler `luanti` ou `minetest`. Sur Debian, les dépôts peuvent fournir une version ancienne ; Flatpak ou le paquet officiel peut alors être préférable.

## 2. Récupérer le projet

Depuis un terminal :

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

## 5. Première quête

- Tu apparais dans une petite clairière.
- Gérard le Magnifique se trouve près de l'allée centrale.
- Fais un **clic droit** sur Gérard pour accepter sa quête.
- Le jardin avec les trois navets se trouve à l'ouest (sur ta gauche en regardant Gérard depuis le point d'apparition).
- Fais un **clic droit** sur chaque navet pour le récolter.
- Retourne voir Gérard et fais un nouveau clic droit.
- Tu reçois le Badge officiel du Nawak.

La commande `/gdo` rappelle l'objectif.

## 6. Touches utiles

Les touches sont celles configurées dans Luanti :
- ZQSD ou WASD : déplacement (selon la configuration).
- Espace : sauter.
- Souris : regarder autour de soi.
- Clic droit : interagir / parler / récolter.
- E : inventaire.
- Échap : menu.

## 7. Limites connues de cette ébauche

- C'est une démo locale mono-monde, pas encore un MMORPG.
- Le personnage de Gérard et les blocs utilisent des textures de remplacement intégrées au moteur ; les modèles et graphismes originaux viendront ensuite.
- La quête est volontairement simple et son état est conservé dans les métadonnées du joueur.
- Pas encore de compte web, classes, combat, sauvegarde centralisée, multijoueur public ou fédération ActivityPub.
- Le prototype n'a pas encore été exécuté sur une machine de test dans le cadre de ce commit.

## Dépannage

Si le jeu n'apparaît pas dans la liste :
- vérifie que le chemin est exactement `~/.minetest/games/gdo/game.conf` ;
- ferme puis relance Luanti ;
- vérifie que le dossier `gdo` n'est pas imbriqué dans un second dossier `gdo`.

En cas d'erreur Lua, consulte `debug.txt` dans le répertoire de données Luanti et joins les lignes autour de l'erreur.
