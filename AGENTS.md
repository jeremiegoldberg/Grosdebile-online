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


## Port elfique NLite

Le Port elfique est généré par `game/gdo/mods/gdo_city/`. Avant toute modification, lire `docs/world/cite-des-canaux.md` et conserver comme références les vues `elven.png` et `praiaelven.png` de l'archive NLite. Reproduire leur composition visible : bassin ouest et navires, canal entre des fronts bâtis continus, ponts, cathédrale, remparts et plage en escalier. Ne pas remplacer cette géométrie par une place gazonnée et des maisons isolées. Le site doit être validé comme continental avant toute terraformation. Si aucun site n'est valide, aucune ville ne doit être construite dans l'eau. Ne jamais modifier le Château des Brumes ou les villages de guildes ; la zone et le spawn sont dynamiques et stockés. `/gdo_city_rebuild` ne reconstruit que l'emprise enregistrée.
