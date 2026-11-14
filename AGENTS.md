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


## Sommières

La ville est générée par game/gdo/mods/gdo_city/ et son catalogue bâtiment par bâtiment se trouve dans sommieres.lua. Avant modification, lire docs/world/sommieres.md. Référence à respecter : Vidourle nord-sud, pont romain est-ouest de 189 m et 21 arches (sept visibles au-dessus du fleuve), vieux centre en damier, rues Marx-Dormoy et Antonin-Paris, arcades de la place des Docteurs-Dax, places Jean-Jaurès, Saussine et République, Porte du Bourguet, beffroi, église, quais plantés et château sur son éperon. Ne jamais remplacer cette géométrie par un port ou un village générique. Utiliser l'atlas textures/sommieres_atlas.png pour les matériaux locaux. Le site doit être validé continental avant toute terraformation. Ne jamais modifier le Château des Brumes ou les villages de guildes ; /gdo_city_rebuild ne reconstruit que l'emprise enregistrée.
