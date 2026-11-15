# Sommières géoréférencée — GDO

Le renderer GIS conserve les géométries mesurées des bâtiments, routes, terrains, cours d'eau, arbres et points d'intérêt. Le dépôt contient un noyau compact pour permettre un premier démarrage sans le ZIP source complet.

## Charger la ville haute résolution

Le noyau compact seul ne représente qu'une fraction du relevé d'origine : 815 bâtiments, 226 tronçons routiers et 454 arbres. Pour retrouver le niveau de détail du visualiseur 3D fourni (4 500 bâtiments, 1 187 routes, 26 144 arbres et 394 points d'intérêt), il faut générer le paquet complet à partir de l'archive source :

```bash
python3 tools/build_sommieres_gis.py /chemin/vers/sommieres3d.zip
```

Le script écrit directement :
`game/gdo/mods/gdo_city/data/sommieres_full_gis.b64`

Relance ensuite Luanti. Au démarrage, le journal doit afficher :

```
[GDO][SOMMIERES] SIG haute résolution chargé : 4500 bâtiments, 1187 routes, 26144 arbres, 394 POI.
```

Si le paquet n'est pas présent, le jeu démarre sur le noyau compact et signale explicitement ce mode dans le journal.

## Mise à jour

**Sauvegarde le monde avant la mise à jour.** La version 23 reconstruit l'emprise de Sommières afin d'appliquer les nouvelles géométries. Les arbres dont le tronc ou la couronne empiète sur une route, un chemin ou un pont sont automatiquement exclus. Les façades du centre ancien sont orientées vers les rues, les ouvertures suivent les niveaux mesurés, les pignons des toits à deux pans sont fermés et les ornements sont réservés aux bâtiments qui les justifient. Aucun climatiseur ni équipement de ventilation contemporain n'est ajouté. Le référentiel vertical est NGF : le zéro marin est calé sur le paramètre Luanti `water_level` (Y=1 par défaut), le centre du Pont Tibère est placé environ 25,2 blocs au-dessus de ce niveau et le Vidourle suit ses altitudes mesurées. La hauteur du terrain de destination n'est plus utilisée comme origine. Les façades du centre ancien utilisent un enduit à la chaux teinté selon le relevé, les fenêtres et leurs volets sont des panneaux minces orientés sur les rues, les voies du centre historique sont pavées en calade plutôt qu'en asphalte générique, les pignons et les pans de toit sont refermés selon les formes mesurées et les débords de toit sont conservés. Les bandes de gazon artificielles dans les ruelles anciennes sont remplacées par du pavage.

Commandes : `/gdo_city`, `/gdo_castle`, `/gdo_city_info`, `/gdo_city_rebuild`.

## Sources et redistribution

Le relevé fourni référence notamment IGN BD TOPO / RGE ALTI, OpenStreetMap et une extraction MNS pour la végétation. Vérifie les conditions de redistribution de chaque jeu de données avant de publier le paquet complet dans un dépôt public.


## Style architectural des maisons (version 23)

Les empreintes cadastrales des parcelles et le tracé du Vidourle sont conservés. Tous les bâtiments ordinaires sont stylisés en maisons de village et limités à trois niveaux ; les monuments, églises, tours et fortifications gardent leurs gabarits patrimoniaux. Les toitures sont plus épaisses et pentues. Un raccord topographique de 384 m relie le relief IGN du cœur urbain au terrain naturel du monde, sans mur de bordure ; le corridor du Vidourle continue d'utiliser son DEM étendu.
