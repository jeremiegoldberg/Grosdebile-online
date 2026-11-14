# Sommières — reconstruction géoréférencée (GIS v2)

## Données intégrées

La génération manuelle précédente est remplacée par un renderer géographique utilisant les données fournies avec le patch :

- 815 empreintes de bâtiments ;
- 226 géométries / tronçons routiers ;
- 4 polygones d'eau et 2 lignes hydrographiques ;
- 454 arbres et 4 zones naturelles ;
- 164 points d'intérêt ;
- raster de terrain RGE ALTI interpolé sur une grille de 28 × 29.

Les sources indiquées dans le relevé sont IGN BD TOPO, RGE ALTI, OpenStreetMap et une extraction du MNS pour les arbres. Les licences applicables à la redistribution de ces données agrégées doivent être confirmées avant toute diffusion publique.

## Rendu

Le mod utilise un atlas dédié `textures/sommieres_atlas.png`. Le relevé de base est stocké en fragments Base64 dans `data/`, puis reconstitué et décompressé au chargement. Le renderer et l'importeur sont stockés sous forme de flux DEFLATE dans `renderer.deflate` et `gis_import.deflate`. Ce découpage garde le dépôt lisible et permet de mettre à jour séparément les données et le code.

Le générateur reconstruit le centre ancien et ses voies à partir des géométries et attributs du relevé, plutôt que d'aligner uniquement des maisons standard dessinées à la main.

## Implantation et compatibilité

Le patch remplace la génération manuelle existante de Sommières par la reconstruction GIS v2. Il ne remplace pas les régions du Château des Brumes, les villages de guildes ni les terres sauvages.

**Faire une sauvegarde du monde avant le premier lancement.** La version 6 du générateur reconstruit uniquement l'emprise urbaine de Sommières. Tout bâtiment construit par un joueur dans cette emprise sera supprimé lors de cette reconstruction.

## Commandes

- `/gdo_city` : revenir à Sommières ;
- `/gdo_castle` : rejoindre le Château des Brumes ;
- `/gdo_city_info` : afficher l'état et les informations de la cité ;
- `/gdo_city_rebuild` : reconstruire l'emprise de Sommières (administrateurs).

## Validation

Le code, les fragments de données et l'atlas sont intégrés au dépôt. Le rendu doit encore être contrôlé dans Luanti pour vérifier le placement des bâtiments, les niveaux de terrain, les raccords routiers, les passages et les détails visuels. La validation en jeu n'est pas encore effectuée.
