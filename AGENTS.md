# Instructions pour les agents du dépôt

## Génération de la carte du Château des Brumes

Avant toute modification de terrain, de bâtiment, de muraille, de châtelet, de circulation, d'escalier ou de village, lire et appliquer la skill :

`.agents/skills/gdo-castle-map/SKILL.md`

Cette skill est la référence du projet pour :
- le découpage de la carte en zones indépendantes ;
- les repères X/Y/Z et le niveau `base_y` ;
- les emprises et raccords entre zones ;
- l'ordre de génération et les versions stockées ;
- la construction de volumes praticables dans Luanti ;
- les tests de circulation et la validation en jeu.

Utiliser l'architecture modulaire sous `game/gdo/mods/gdo_castle/architecture/` comme source de vérité. Ne pas réactiver les anciens constructeurs monolithiques présents dans `gdo_castle/init.lua` ou `dourdan.lua`, sauf demande explicite.

Toute nouvelle zone doit être intégrée au bootstrap, disposer de sa version de génération, préserver les autres zones et être documentée. Une zone doit être praticable et raccordée avant d'être considérée comme terminée.
