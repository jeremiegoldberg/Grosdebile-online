---
name: gdo-castle-map
description: Conçoit, construit, corrige et étend la carte modulaire du Château des Brumes dans Luanti. À utiliser pour toute modification du terrain, du château, des courtines, du châtelet, des salles, des escaliers, de la cour, du village ou du générateur de carte.
---

# Skill — Construire la carte du Château des Brumes

## Mission

Faire évoluer la carte du Château des Brumes comme un ensemble architectural cohérent, explorable et praticable dans Luanti. Le château ne doit pas être une collection de volumes indépendants : les murs, tours, portes, chemins, sols, escaliers et bâtiments doivent se raccorder physiquement et permettre au joueur de circuler.

Cette skill est la procédure de référence pour toute intervention sur la génération de la carte.

## Source de vérité et périmètre

La génération modulaire actuelle se trouve dans :

```text
game/gdo/mods/gdo_castle/
├── init.lua
└── architecture/
    ├── common.lua
    ├── init.lua
    ├── README.md
    └── zones/
        ├── 00_site.lua
        ├── 10_enclosure.lua
        └── 20_gatehouse.lua
```

- Le point d'entrée actif de l'architecture modulaire est `architecture/init.lua`, appelé depuis `gdo_castle/init.lua`.
- Les anciennes fonctions de génération présentes dans `gdo_castle/init.lua` et l'ancien constructeur `dourdan.lua` sont des références historiques. Ne pas les réactiver ni les modifier pour construire la nouvelle carte, sauf demande explicite de migration.
- Les zones 00, 10, 20, 30 et la première tranche de la zone 70 (escaliers du châtelet) sont implémentées. Les autres éléments de 40 à 99 restent à construire.
- Toujours relire le code courant et le README avant de modifier une zone. Les coordonnées et versions du code priment sur une ancienne note.

## Repère spatial et niveau de référence

L'architecture utilise les coordonnées absolues du monde Luanti. Les helpers de `common.lua` n'ajoutent aucun décalage implicite.

Repère logique actuel :
- X négatif : côté ouest du plan ; X positif : côté est.
- Z négatif : côté nord de l'enceinte.
- Z positif : côté entrée sud, châtelet, pont-levis et parvis extérieur.
- La cour se trouve principalement du côté des Z négatifs par rapport au châtelet.
- Le pont-levis s'étend vers les Z positifs.

Le niveau de référence est `base_y`, égal à la surface supérieure du plateau du château :
- Le sol praticable du plateau est généralement posé à `base_y`.
- Un joueur debout sur ce sol se trouve autour de `base_y + 1`.
- Les murs commencent généralement à `base_y + 1`.
- Les niveaux de plancher supérieurs sont exprimés en décalages positifs depuis `base_y`.

Ne jamais confondre l'altitude du bloc de sol (`base_y`) et la position des pieds du joueur (`base_y + 1`).

## Découpage de la carte

Les limites sont des emprises de travail. Elles doivent être vérifiées dans le code de chaque zone avant tout changement.

| Zone | Fichier | Responsabilité | État |
|---|---|---|---|
| 00 — Site | `zones/00_site.lua` | Échantillonnage du terrain, plateau du château, terrasse du village, parvis et altitude de référence | Implémentée |
| 10 — Enceinte | `zones/10_enclosure.lua` | Courtines, courtines sud interrompues, chemins de ronde et créneaux | Implémentée |
| 20 — Châtelet | `zones/20_gatehouse.lua` | Deux tours de porte, portail, herse, galerie haute, passage et pont-levis | Implémentée |
| 30 — Tours | `zones/30_towers.lua` | Quatre tours d'angle chanfreinées, raccordées aux courtines et chemins de ronde | Implémentée ; validation en jeu requise |
| 40 — Donjon | `zones/40_keep.lua` | Donjon principal, niveaux, salles, toiture et circulations | À construire |
| 50 — Résidence | `zones/50_residential.lua` | Grande salle, appartements et espaces de réception | À construire |
| 60 — Bâtiments de cour | `zones/60_courtyard_buildings.lua` | Chapelle, ateliers, école et bâtiments de service | À construire |
| 70 — Escaliers | `zones/70_stairs.lua` | Deux volées de deux blocs de large dans le châtelet, du rez-de-chaussée au plancher +9 ; autres escaliers à venir | Partiellement implémentée ; validation en jeu requise |
| 80 — Cour | `zones/80_courtyard.lua` | Pavage, puits, jardins, mobilier et petits éléments | À construire |
| 90 — Village | `zones/90_village.lua` | Rues, maisons, auberge, commerces et ateliers | À construire |
| 95 — Paysage | `zones/95_landscape.lua` | Raccordement du terrain, arbres, champs, mares et chemins | À construire |
| 99 — Connexions | `zones/99_connections.lua` | Liaisons finales entre zones, portes, chemins et ponts secondaires | À construire |

Ne pas inventer les emprises des zones 30 à 99 avant d'avoir établi un plan de coordonnées qui tient compte des bâtiments et connexions déjà présents.

### Zone 00 — Site

Emprises actuelles :
- Plateau du château : X -43 à 43, Z -54 à 75.
- Terrasse du village : X -43 à 43, Z 80 à 128.

Les deux plateaux ont des altitudes naturelles médianes indépendantes, conservées dans le stockage du mod. La zone aplatit les colonnes et pose la surface. Le niveau du château devient le `base_y` commun aux autres zones.

Attention : `/gdo_site` reconstruit le terrain et les deux plateaux. C'est une opération large et potentiellement destructive pour les constructions situées dans ces emprises. Ne pas la lancer pour corriger un bâtiment isolé.

Le point d'apparition défini actuellement est `(0, base_y + 1, 68)`, sur le parvis extérieur au-delà du tablier du pont-levis. Ne pas le déplacer sans vérifier le parcours d'arrivée et le scénario d'accueil.

### Zone 10 — Enceinte

Emprise : X -39 à 39, Z -41 à 39.

Courtines actuelles :
- Nord : autour de Z -40, de X -36 à 36.
- Ouest : autour de X -38, de Z -38 à 38.
- Est : autour de X 38, de Z -38 à 38.
- Sud : autour de Z 38, en deux tronçons X -36 à -6 et X 6 à 36.
- L'ouverture sud centrale est réservée au châtelet.

La courtine comporte un corps de mur, un chemin de ronde autour de `base_y + 10` et des créneaux jusqu'à `base_y + 12`.

### Zone 20 — Châtelet et pont-levis

Emprise : X -18 à 18, Z 24 à 61.

Éléments actuels :
- Tours jumelles : X -17 à -7 et X 7 à 17, Z 25 à 43.
- Entrées de plain-pied de trois blocs de large, orientées vers la cour, dans chaque tour.
- Piers de raccordement aux courtines : X -18 et X 18, Z 36 à 38.
- Passage central : X -3 à 3, traversant le portail.
- Faces du portail : autour de Z 32 et Z 41.
- Herse levée : autour de Z 37, au-dessus de la hauteur de passage.
- Galerie défensive haute : niveaux `base_y + 15` à `base_y + 26`.
- Pont-levis : X -3 à 3, Z 42 à 58, tablier au même niveau que le sol du château.
- Fossés latéraux : X -17 à -4 et X 4 à 17, Z 49 à 55.

La circulation au sol doit rester continue entre la cour, le passage, le pont et le parvis. Ne pas poser de seuil surélevé, de bloc décoratif dans le couloir, de chaîne ou de poteau dans la largeur marchable.

#### Recouvrement volontaire entre zones 10 et 20

Les emprises de zones 10 et 20 se recouvrent volontairement au sud. La zone 10 construit d'abord les courtines ; la zone 20 efface ensuite son volume propriétaire et reconstruit les parties de mur nécessaires autour des tours et du passage.

Conséquences :
1. La génération initiale doit respecter l'ordre zone 10 puis zone 20.
2. Après une reconstruction manuelle de la zone 10, reconstruire également la zone 20 avec `/gdo_zone20`, sinon la courtine peut reboucher ou perturber des éléments du châtelet.
3. Si la géométrie de la zone 10 est changée dans cette zone de recouvrement, vérifier si la version de la zone 20 doit aussi être incrémentée.
4. Ne pas déplacer les piliers de raccordement sans vérifier la continuité complète des courtines, du chemin de ronde et des tours.

### Zone 30 — Tours d'angle

Quatre tours sont centrées en (-37,-39), (37,-39), (-37,37) et (37,37). Chacune remplace le noyau d'angle de la zone 10 et absorbe l'extrémité des deux courtines qui s'y rencontrent.

- Les portes basses sont orientées vers la cour.
- Deux ouvertures hautes raccordent les deux chemins de ronde qui arrivent réellement à l'angle ; les faces extérieures restent fermées.
- Les sols de raccord à `base_y + 10` doivent être continus entre la courtine et l'intérieur de la tour.
- Les tours sont chanfreinées, creuses, éclairées et terminées par un parapet crénelé.
- Commandes : `/gdo_zone30` et `/gdo_zone30_info`.

### Zone 70 — Escaliers du châtelet

La première tranche de cette zone construit un escalier dans chacune des deux tours de la zone 20.

- Chaque volée fait deux blocs de large.
- Tour ouest : X -15 à -14 ; tour est : X 14 à 15.
- Les volées montent vers Z positif, de Z 27 à 35, et débouchent sur le premier plancher à `base_y + 9`.
- Seul le nœud `gdo_castle:refit_stair` constitue les marches. Aucun cube plein de soutien n'est ajouté sous les marches.
- Le module ne nettoie que ses colonnes d'escalier et le petit palier.
- La reconstruction de la zone 20 invalide la version stockée de la zone 70, puis reconstruit les escaliers.
- Commandes : `/gdo_stairs` et `/gdo_stairs_info`.

## Règles impératives de construction

### 1. Une zone, une responsabilité

Chaque nouvelle zone doit :
- être un module indépendant dans `architecture/zones/` ;
- retourner une table de zone via le patron `return function(A) ... return Z end` ;
- définir une constante `Z.VERSION` ;
- documenter ses limites `Z.bounds` ;
- fournir une fonction `Z.build(base_y)` ;
- refuser de construire si `base_y` est absent ;
- ne modifier que son volume déclaré et les interfaces de connexion explicitement documentées.

Les recouvrements entre zones sont possibles uniquement s'ils sont volontaires, documentés et reconstruits dans un ordre défini.

### 2. Génération déterministe et nettoyage limité

- Définir précisément le volume que la zone possède et ce qu'elle doit préserver.
- Nettoyer uniquement les blocs nécessaires à la reconstruction de cette zone.
- Ne jamais faire de nettoyage global du château ou du monde.
- Ne jamais effacer le sol de référence sans raison documentée.
- Reconstruire les zones dans un ordre stable, pour que relancer la génération donne le même résultat.
- Ne pas supposer qu'un redémarrage répare une zone si son numéro de version n'a pas changé.

### 3. Coordonnées et helpers communs

Utiliser les fonctions de `architecture/common.lua` :
- `A.put(x, y, z, node, param2)` : poser un bloc.
- `A.fill(x1, y1, z1, x2, y2, z2, node)` : remplir un volume inclusif.
- `A.clear(x1, y1, z1, x2, y2, z2)` : vider un volume limité.
- `A.deck(...)` : poser une surface horizontale.
- `A.lamp(x, y, z)` : poser une lanterne.
- `A.fix_light(bounds)` : recalculer la lumière.
- `A.flatten_rect`, `A.inspect_column`, `A.median_surface` : outils de terrain de la zone 00.

Les coordonnées sont absolues. Les boucles de `A.fill` incluent leurs deux extrémités. Vérifier les limites en comptant les blocs, en particulier pour les couloirs, portes et jonctions.

Les matériaux sont centralisés dans `A.materials`. Réutiliser ces identifiants plutôt que créer des noms de nœuds ad hoc. Toute nouvelle texture ou tout nouveau nœud doit être enregistré proprement dans `common.lua` avec une texture présente dans le mod.

### 4. Jouabilité avant décoration

Construire dans cet ordre :
1. Sol et terrain de fondation.
2. Volumes structurels : murs, tours, bâtiments et plafonds.
3. Ouvertures réelles : portes, fenêtres, arches, passages et accès.
4. Planchers, escaliers et liaisons verticales.
5. Éclairage et repères de navigation.
6. Décoration, mobilier et détails esthétiques.

Pour chaque espace accessible, vérifier qu'il existe un chemin continu depuis l'extérieur jusqu'à sa porte et jusqu'à ses pièces. Les portes doivent traverser réellement le mur et déboucher dans un espace libre, pas derrière une autre paroi.

Préserver les dégagements de circulation : largeur annoncée du passage, hauteur libre suffisante, sol continu et absence de collisions avec les décorations. Tester les deux sens de circulation.

Ne jamais simuler un escalier par une pile de blocs pleins. Utiliser le nœud `gdo_castle:refit_stair` et vérifier son orientation et sa collision en jeu. Les différents types d'escaliers doivent rester dans la zone 70 afin d'être testés isolément.

Les rampes, seuils, chaînes, poteaux, herses et décorations doivent être placés hors de la largeur utile ou au-dessus du dégagement du joueur.

### 5. Intégration au bootstrap

Pour ajouter une zone :
1. Créer son module dans `architecture/zones/`.
2. Le charger explicitement dans `architecture/init.lua`.
3. Ajouter une clé de stockage dédiée, par exemple `architecture_zone30_version`.
4. Ajouter une fonction de construction qui vérifie les prérequis et l'état de génération.
5. Ajouter une commande d'administration de reconstruction ciblée et, si utile, une commande d'état.
6. Définir l'ordre d'exécution et les dépendances avec les zones voisines.
7. Mettre à jour `architecture/README.md` et ce plan si le découpage change.

Lors d'une correction géométrique d'une zone déjà construite, incrémenter `Z.VERSION`. Le bootstrap compare cette version au numéro stocké et reconstruit la zone si nécessaire. Si le changement impacte une zone voisine qui ne sera pas automatiquement reconstruite, prévoir sa reconstruction dans le bootstrap ou documenter et exécuter explicitement la commande correspondante.

Ne pas utiliser le numéro de version pour masquer une erreur de génération : il doit correspondre à une évolution réelle et relue du module.

## Ordre de construction recommandé

1. Stabiliser le terrain et le niveau de référence (00).
2. Construire les courtines (10).
3. Construire le châtelet et les raccords au sud (20).
4. Ajouter les tours et vérifier leur jonction avec les murs (30).
5. Construire le donjon et ses circulations intérieures (40).
6. Construire la résidence et les grandes salles (50).
7. Ajouter les bâtiments de service (60).
8. Créer et tester les escaliers (70).
9. Aménager la cour sans réduire les chemins (80).
10. Construire le village et ses rues (90).
11. Raccorder le paysage et les chemins (95).
12. Terminer les connexions inter-zones et faire une passe globale (99).

Ne pas générer toutes les zones futures d'un seul coup. Construire un lot limité, l'ouvrir dans Luanti, le parcourir, corriger, puis seulement passer au lot suivant.

## Procédure de travail pour chaque évolution

### Avant de coder
- Lire le module ciblé, `common.lua`, le bootstrap et les modules adjacents.
- Vérifier les versions stockées, les commandes disponibles et l'ordre réel de construction.
- Identifier les volumes qui se recouvrent et les blocs que la zone voisine pose dans cette emprise.
- Établir les coordonnées de la nouvelle ouverture, du sol et des liaisons.
- Pour une construction visible, demander ou examiner des captures du jeu si elles sont disponibles ; ne pas déduire l'état visuel uniquement du code.

### Pendant la construction
- Créer d'abord une géométrie simple, cohérente et praticable.
- Garder les détails décoratifs dans le même module que l'élément qu'ils décorent, sauf responsabilité dédiée.
- Préserver les matériaux, l'échelle et le style du Château des Brumes.
- Ne pas déplacer silencieusement les coordonnées de zones existantes.
- Ajouter des commentaires expliquant les raccords complexes et les choix de propriété des blocs.

### Après le code
- Relire le diff ou le fichier complet pour repérer les erreurs de coordonnées, les volumes inversés et les ouvertures bouchées.
- Exécuter un contrôle de syntaxe Lua si un interpréteur ou un validateur est disponible.
- Vérifier en jeu le parcours réel : approche, entrée, sortie, portes, étages, escaliers, collisions et éclairage.
- Si le jeu n'a pas été lancé, le dire explicitement. Ne jamais prétendre qu'une construction a été validée visuellement.
- Incrémenter les versions nécessaires, mettre à jour le README, puis vérifier les fichiers publiés sur la branche principale.

## Commandes actuelles

| Commande | Effet |
|---|---|
| `/gdo_site` | Reconstruit la zone 00 et enchaîne les zones 10 et 20 selon leurs versions |
| `/gdo_site_info` | Affiche la version du site et les altitudes sauvegardées |
| `/gdo_zone10` | Force la reconstruction de l'enceinte uniquement |
| `/gdo_zone10_info` | Affiche l'état de la zone 10 |
| `/gdo_zone20` | Force la reconstruction du châtelet uniquement |
| `/gdo_zone20_info` | Affiche l'état de la zone 20 |
| `/gdo_zone30` | Reconstruit les quatre tours d'angle |
| `/gdo_zone30_info` | Affiche l'état de la zone 30 |
| `/gdo_stairs` | Reconstruit les escaliers du premier étage du châtelet |
| `/gdo_stairs_info` | Affiche l'état de la zone 70 (escaliers du châtelet) |

Les commandes de reconstruction doivent être utilisées dans le bon ordre lorsque des zones se recouvrent. `/gdo_zone10` reconstruit en cascade les zones 10, 20, 30 et 70. `/gdo_zone20` reconstruit le châtelet puis ses escaliers. Après une reconstruction des tours seules, `/gdo_zone30` suffit.

## Critères d'acceptation d'une zone

Une zone n'est pas terminée parce que le générateur ne plante pas. Elle est prête à être validée uniquement lorsque :
- son volume extérieur est cohérent avec le plan ;
- elle touche correctement les bâtiments et murs adjacents ;
- toutes les ouvertures annoncées sont réellement traversables ;
- le joueur peut entrer, ressortir et atteindre les pièces annoncées ;
- le sol ne comporte pas de marche involontaire ni de bloc de soutien qui bloque le déplacement ;
- les escaliers ont des marches et collisions correctes ;
- les plafonds ne bloquent pas les passages et ne créent pas de faux planchers ;
- les espaces sont suffisamment éclairés ;
- la reconstruction ciblée ne détruit pas les autres zones ;
- les versions, commandes et documents correspondent au code livré.

En cas de défaut, corriger la zone et faire rejouer ses dépendances avant de considérer le raccord comme terminé.
