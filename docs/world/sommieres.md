# Sommières — reconstruction du centre historique

## Référence géographique

Sommières est organisée autour du Vidourle. Le fleuve suit un axe nord-sud ; le pont romain le franchit est-ouest. Le pont mesure environ 189 mètres et comporte 21 arches, dont sept sont encore visibles au-dessus du lit du fleuve. Les autres ont été absorbées par le tissu urbain médiéval et servent notamment de caves, ateliers ou locaux au niveau bas. La ville s'est développée au pied du château et jusque dans l'ancien lit du Vidourle. Source : mairie de Sommières, Le Pont Romain.

La partie basse du centre ancien présente une trame de rues en damier, pensée pour faciliter l'écoulement des crues vers la place du marché. Les maisons s'appuient sur des arcades et des niveaux bas adaptés aux inondations. Les quais Frédéric-Gaussorgues et Cléon-Griolet sont accompagnés d'alignements de platanes. Source : mairie de Sommières, Les rues et les places.

Le repérage des voies du centre ancien s'appuie sur l'index Street View de Sommières et les noms de rues documentés : rue Antonin-Paris (ancienne Grand-Rue), rue Marx-Dormoy, place des Docteurs-Dax, quai Frédéric-Gaussorgues, quai Cléon-Griolet, place Jean-Jaurès, place de la République, place Saussine et montée du Château.

## Orientation dans la carte Luanti

Le générateur utilise un repère local centré sur le site terrestre choisi :

- X : axe est-ouest ; le pont romain suit cet axe.
- Z : axe nord-sud ; le Vidourle suit cet axe.
- Y : altitude ; la chaussée du pont est surélevée par rapport au lit du fleuve.

Le Vidourle occupe approximativement X=-40..40 et Z=680..1015 dans le repère local. La chaussée du pont romain s'étend de X=-98 à X=98. Les sept arches centrales restent ouvertes au-dessus de l'eau ; les autres arcs sont intégrés aux bâtiments et niveaux bas du pont habité.

L'emprise protégée est un carré de 361 × 361 blocs autour du centre validé. Les coordonnées absolues sont enregistrées par le stockage du mod, afin que la ville garde la même position aux redémarrages.

## Bâtiments reconstruits individuellement

Chaque bâtiment principal possède un constructeur nommé dans le catalogue sommieres.lua. Les maisons utilisent un générateur de volume commun, mais leurs dimensions, hauteurs, matériaux, orientation, ouvertures, balcons et toitures sont définis bâtiment par bâtiment.

### Pont et faubourg

- 21 arches du pont romain, avec sept arches ouvertes sur le chenal.
- Maisons et locaux intégrés aux approches du pont.
- Quatre maisons du faubourg et un atelier du côté rive droite.
- Maison consulaire de la rue Marx-Dormoy, avec son relief de façade.

### Centre ancien

- Huit maisons individualisées sur la rue Antonin-Paris / Grand-Rue.
- Arcades de la place des Docteurs-Dax et place du marché.
- Maisons de la place Jean-Jaurès.
- Maison à mascaron de la place Saussine.
- Immeubles de la place de la République.
- Porte du Bourguet et montée vers le château.
- Tour de l'Horloge / beffroi-porte.
- Église Saint-Pons.
- Château sur son éperon rocheux, avec tour carrée et fragments de remparts.

### Quais et paysage

- Berges maçonnées, escaliers vers l'eau et galets.
- Quais pavés, platanes, bancs et lanternes.
- Tuiles canal, façades ocre et rosées, pierre calcaire, volets colorés et ferronnerie.

## Textures

Le mod utilise un atlas original de 16 textures 16×16 : calcaire blond, enduit ocre, pierre de taille, colombage, tuile canal, tuile patinée, maçonnerie, pavage, volets verts et bleu-gris, ferronnerie, porte, claveaux d'arcade, pierre de pont, galets et enduit rose. Ces textures sont propres au projet ; elles ne recopient pas de photographies Street View.

## Implantation et altitude

La recherche de terrain se fait avant toute construction. Le générateur vérifie que l'emprise est sèche et suffisamment plane, puis conserve l'altitude médiane du sol comme niveau de rue. Le lit du Vidourle est creusé sous ce niveau ; les quais, le pont et les maisons sont construits à partir de ce même repère.

Si aucun terrain continental assez grand n'est trouvé, la ville n'est pas générée et les joueurs restent au Château des Brumes. Il vaut mieux reporter la construction que fabriquer une ville flottante ou sous-marine.

## Arrivée et commandes

- Spawn sur la place du marché, à proximité de la place des Docteurs-Dax.
- /gdo_city : revenir à Sommières.
- /gdo_castle : rejoindre le Château des Brumes.
- La pierre de passage de la place du marché permet de rejoindre le château.
- /gdo_city_info : voir version, statut et coordonnées du site.
- /gdo_city_rebuild : reconstruire l'emprise enregistrée de Sommières.

## Validation

La génération et le catalogue de bâtiments sont présents dans le dépôt. Il reste à vérifier dans Luanti la circulation sur le pont, le passage sous les arches, les raccords des rues, l'accès au château, l'altitude et les façades en vue de rue. Le rendu final ne doit pas être déclaré validé avant un test en jeu.
