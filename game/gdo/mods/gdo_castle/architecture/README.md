# Architecture du Château des Brumes

La carte est générée par zones indépendantes. Le code actuellement intégré au bootstrap construit les zones 00, 10, 20, 30, 40 et la première tranche de la zone 70. Toutes ces zones doivent encore être parcourues et validées en jeu.

## Règles générales

- Chaque zone possède son fichier sous `zones/`, sa version stockée et une commande de reconstruction ciblée.
- Les coordonnées passées aux helpers de `common.lua` sont des coordonnées absolues du monde ; aucun décalage Y implicite n'est appliqué.
- Une zone ne nettoie que le volume dont elle est propriétaire. Les recouvrements avec une autre zone doivent être volontaires, commentés et reconstruits dans un ordre connu.
- Le sol du plateau est à `base_y`. Un joueur debout dessus a les pieds autour de `base_y + 1`.
- La jouabilité passe avant la décoration : portes traversantes, sols continus, hauteurs libres, escaliers praticables et parcours testable dans les deux sens.
- Un escalier utilise `gdo_castle:refit_stair`. Aucun cube plein ne doit être ajouté sous ou devant une marche pour simuler un escalier.

## Direction architecturale

La citadelle adopte désormais une inspiration gothique sombre, monumentale et verticale, à partir de [Brukenthal — Team Lyrah](https://www.minecraft-france.fr/map-brukenthal-dark-castle/) et de sa [présentation originale](https://www.planetminecraft.com/project/minecraft-timelapse-project-brukenthal-a-dark-castle/).

À adapter au Château des Brumes, sans reproduire la carte source bloc pour bloc :
- un grand donjon qui domine nettement les bâtiments voisins ;
- un profil irrégulier, composé de tours et tourelles de hauteurs différentes ;
- des toitures en ardoise très pentues, des pignons et des faîtages élancés ;
- de grands volumes en pierre, des ailes habitées, des galeries et cours intérieures ;
- des intérieurs riches en colonnes, salles spécialisées et embranchements ;
- une lumière chaude et ponctuelle, avec des zones d'ombre assumées ;
- à terme, une approche dans un relief rocheux, un lac, des conifères et un bourg étagé en contrebas.

L'objectif est une forteresse cohérente et explorable, pas une simple façade décorative.

## Découpage des zones

| Zone | Fichier | Responsabilité | État |
|---|---|---|---|
| 00 — Site | `00_site.lua` | Relevé du terrain, plateau du château, terrasse du village, altitude de référence | Implémentée ; validation en jeu requise |
| 10 — Enceinte | `10_enclosure.lua` | Courtines, chemins de ronde et créneaux | Implémentée ; validation en jeu requise |
| 20 — Châtelet | `20_gatehouse.lua` | Tours de porte, portail, herse, galerie haute et pont-levis | Implémentée ; validation en jeu requise |
| 30 — Tours d'angle | `30_towers.lua` | Quatre tours chanfreinées, raccords aux courtines | Implémentée ; validation en jeu requise |
| 40 — Citadelle | `40_keep.lua` | Donjon monumental, huit tours, ailes habitées et cour intérieure | Refaite dans le style Brukenthal ; validation en jeu requise |
| 50 — Résidence / bourg | `50_residential.lua` | Bâtiments habités et éventuel bourg étagé | Prototype non intégré au bootstrap ; à repositionner |
| 60 — Bâtiments de cour | `60_courtyard_buildings.lua` | Chapelle, ateliers, école, bâtiments de service | À construire |
| 70 — Escaliers | `70_stairs.lua` | Escaliers du châtelet puis circulations verticales de la citadelle | Partiellement implémentée |
| 80 — Cour | `80_courtyard.lua` | Pavage, puits, jardins, mobilier et accessoires | À construire |
| 90 — Village | `90_village.lua` | Bourg, rues, maisons, auberge, commerces et ateliers | À construire |
| 95 — Paysage | `95_landscape.lua` | Falaises, affleurements rocheux, lac, conifères et chemins | À construire |
| 99 — Connexions | `99_connections.lua` | Liaisons finales entre zones, portes et parcours | À construire |

Le prototype `50_residential.lua` n'est pas chargé par `architecture/init.lua`. Ne pas l'activer tel quel : ses anciennes coordonnées de maisons se superposent à la citadelle nouvellement élargie. Le repositionner lorsque le plan du bourg étagé sera défini.

## Zone 00 — Site

Emprises actuelles :
- Plateau du château : X -43 à 43, Z -54 à 75.
- Terrasse du village : X -43 à 43, Z 80 à 128.

Les deux plateaux ont des altitudes naturelles médianes indépendantes, conservées dans le stockage du mod. La zone aplatit ses emprises et pose les sols. Le niveau du château devient le `base_y` commun.

Attention : `/gdo_site` reconstruit largement les deux plateaux ; cette commande peut effacer les bâtiments situés dans leur emprise. Ne pas l'utiliser pour corriger une seule construction.

Le point d'apparition actuel est `(0, base_y + 1, 68)`, sur le parvis extérieur, au-delà du pont-levis.

## Zone 10 — Enceinte

Emprise : X -39 à 39, Z -41 à 39.

Courtines actuelles :
- Nord : autour de Z -40, de X -36 à 36.
- Ouest : autour de X -38, de Z -38 à 38.
- Est : autour de X 38, de Z -38 à 38.
- Sud : autour de Z 38, en deux tronçons X -36 à -6 et X 6 à 36, laissant l'ouverture du châtelet.

Le corps du mur monte à +9 ; le chemin de ronde est à +10 et les créneaux montent jusqu'à +12.

## Zone 20 — Châtelet et pont-levis

Emprise : X -18 à 18, Z 24 à 61.

- Passage central de sept blocs de large, X -3 à 3.
- Tours jumelles : X -17 à -7 et X 7 à 17, Z 25 à 43.
- Entrées basses de trois blocs de large côté cour.
- Piliers aux X -18 et 18 raccordant le châtelet aux courtines sud.
- Portail aux environs de Z 32 et 41 ; herse levée autour de Z 37.
- Galerie défensive haute aux niveaux +15 à +26.
- Pont-levis plat, X -3 à 3, Z 42 à 58, au même niveau que le chemin.
- Fossés latéraux aux X -17 à -4 et 4 à 17, Z 49 à 55.

Le parcours doit rester continu entre cour, passage, tablier et parvis, sans seuil surélevé ni obstacle dans les sept blocs de passage.

## Zone 30 — Tours d'angle

Tours centrées en (-37,-39), (37,-39), (-37,37) et (37,37). Elles remplacent les noyaux d'angle de la zone 10 et absorbent l'extrémité des courtines qui s'y rencontrent.

- Les portes basses donnent sur la cour.
- Les ouvertures au niveau +10 raccordent les deux chemins de ronde qui arrivent à chaque angle.
- Les faces extérieures restent fermées.
- Les tours sont chanfreinées, creuses, éclairées et coiffées de parapets crénelés.

## Zone 40 — Citadelle gothique

Emprise : X -27 à 27, Z -38 à -3 ; les éléments les plus hauts culminent vers `base_y + 47`.

Composition actuelle :
- Donjon central : X -10 à 10, Z -36 à -19, trois planchers supérieurs à +8, +16 et +24.
- Toiture principale en ardoise, à deux pans très pentus, avec pignons et faîtage.
- Deux ailes habitées, ouest et est, de deux niveaux, avec façades hautes en enduit et colombages.
- Passage d'entrée sud, qui donne sur une cour intérieure ouverte au ciel.
- Cour intérieure entre le donjon et le bâtiment d'entrée, avec fontaine.
- Huit tours de hauteurs différentes : quatre tourelles du donjon et quatre tours sur les ailes.
- Les portes latérales relient le donjon aux ailes ; des passages au sol relient les ailes à la cour.
- Le rez-de-chaussée est meublé avec un grand hall, une salle de banquet, une bibliothèque/map room et un poste de garde, avec éclairage ponctuel.

Les pièces et circulations des étages ne sont pas encore entièrement jouables. Les escaliers internes du donjon et des ailes restent à construire dans la zone 70. Les appartements, la chapelle, les salles spécialisées et le mobilier détaillé restent à développer.

Commande : `/gdo_zone40` reconstruit la citadelle ; `/gdo_zone40_info` en affiche la version et l'état.

## Zone 70 — Escaliers

La première tranche construit deux volées de deux blocs de large dans les tours du châtelet :
- Tour ouest : X -15 à -14.
- Tour est : X 14 à 15.
- Montée vers Z positif, de Z 27 à 35, jusqu'au plancher à +9.

Seul le nœud `gdo_castle:refit_stair` constitue les marches. Aucun bloc plein de soutien n'est posé sous les marches.

Les escaliers du donjon, des ailes, des tours et les accès aux chemins de ronde restent à construire.

## Dépendances et ordre de génération

Ordre actuel :
1. Zone 00 : terrain et altitude de référence.
2. Zone 10 : enceinte.
3. Zone 20 : châtelet et pont-levis.
4. Zone 30 : tours d'angle.
5. Zone 40 : citadelle centrale.
6. Zone 70 : escaliers actuels du châtelet.

Les zones 10 et 20 se recouvrent volontairement au sud. La zone 30 remplace les noyaux d'angle de la zone 10. Après une reconstruction de la zone 10, le bootstrap reconstruit les zones dépendantes dans le bon ordre.

Commandes :
| Commande | Effet |
|---|---|
| `/gdo_site` | Reconstruit le site puis enchaîne les zones dépendantes |
| `/gdo_site_info` | Affiche les altitudes sauvegardées |
| `/gdo_zone10` | Reconstruit l'enceinte et les zones dépendantes |
| `/gdo_zone10_info` | État de la zone 10 |
| `/gdo_zone20` | Reconstruit le châtelet et les escaliers associés |
| `/gdo_zone20_info` | État de la zone 20 |
| `/gdo_zone30` | Reconstruit les quatre tours d'angle |
| `/gdo_zone30_info` | État de la zone 30 |
| `/gdo_zone40` | Reconstruit la citadelle centrale |
| `/gdo_zone40_info` | État de la zone 40 |
| `/gdo_stairs` | Reconstruit les escaliers du premier étage du châtelet |
| `/gdo_stairs_info` | État de la tranche actuelle de la zone 70 |

## Contrôle qualité obligatoire

Une zone n'est pas terminée simplement parce que son code s'exécute. Il faut vérifier en jeu :
- raccord physique avec murs et bâtiments voisins ;
- accès traversables, sols continus, hauteurs libres et portes réellement ouvertes ;
- circulation dans les deux sens et accès aux pièces annoncées ;
- planchers, escaliers, plafonds et collisions ;
- visibilité extérieure, silhouette, lumière et détails ;
- reconstruction ciblée sans destruction des autres zones.

Ne jamais annoncer une validation visuelle si Luanti n'a pas été lancé et parcouru.
