# Port elfique — reconstruction NLite

## Référence et objectif

Cette région ne doit pas être interprétée comme une ville simplement « inspirée » d'une ambiance médiévale. Elle reconstruit les éléments visibles des deux captures du pack NLite :

- `elven.png` : panorama général du port, maisons mitoyennes serrées, toitures rouges et bleu ardoise, quais, navires, bassins, silhouettes de tours et fortifications.
- `praiaelven.png` : canal bordé de bâtiments, pont qui franchit l'eau, petits quais, bateaux, plage en escalier et arbre clair au bord du rivage.

L'archive ne contient pas de sauvegarde de monde Minecraft ni de fichier de structure exportable. La reconstruction est donc une carte procédurale originale à partir des vues disponibles : les façades, les volumes et les éléments visibles sont repris, tandis que les parties masquées par la caméra ne peuvent pas être reproduites au bloc près.

## Composition spatiale

La carte est conçue autour d'un axe d'eau lisible, pas d'une pelouse centrale :

1. **Bassin du port à l'ouest** — bassin ouvert, pontons en bois, grues, marchandises et trois navires à coque, mât et voiles.
2. **Canal principal est-ouest** — eau encaissée dans un lit de pierre, deux fronts de maisons mitoyennes, façades et portes dirigées vers les quais.
3. **Ponts** — trois traversées du canal principal avec voûtes sous la chaussée, plus un passage sur le bras latéral.
4. **Quartier portuaire** — échoppes, maisons hautes, quais et lanternes autour du bassin.
5. **Silhouette monumentale** — cathédrale à nef, contreforts, fenêtres hautes, toiture en pente et flèches ; rempart arrière ponctué de tours et d'une porte.
6. **Rive orientale** — petite place de débarquement, fontaine basse, étals et plage en escalier ; arbres et bancs en retrait.

Les matériaux réutilisent les blocs du jeu : pierre, enduit clair, colombages en bois, ardoise, tuiles rouges, verre et éléments de quai.

## Implantation et sécurité du terrain

Le port ne possède plus de coordonnées de départ supposées. Au lancement, le générateur teste plusieurs emplacements séparés du château et des villages de guilde :

- émergence préalable des chunks ;
- contrôle de neuf points pour éliminer rapidement les zones immergées ou trop pentues ;
- échantillonnage de l'emprise entière ;
- rejet si plus de 1,5 % des points de contrôle sont sous l'eau ou si le relief dépasse le seuil admis.

Aucune plateforme n'est construite si aucun emplacement continental valable n'est trouvé. Dans ce cas, les joueurs restent au Château des Brumes et le serveur réessaie plus tard. L'emplacement validé, son altitude et ses coordonnées sont conservés en stockage pour éviter tout déplacement au redémarrage.

L'emprise est de 193 × 193 blocs autour du centre validé. Elle est séparée des régions du Château des Brumes et des quatre villages fondateurs. Le module `gdo_bestiary` récupère les bornes réelles de cette emprise pour exclure le spawn naturel des créatures dans le port.

## Arrivée et déplacements

- Les nouveaux joueurs apparaissent sur la place de débarquement, à l'est du canal.
- `/gdo_city` rejoint le port elfique.
- `/gdo_castle` rejoint le Château des Brumes.
- La pierre de passage située près de la petite place permet également de rejoindre le château.

Si aucun site continental n'est disponible, l'arrivée reste au château : le système ne téléporte pas les joueurs sur l'ancien fond marin.

## Migration depuis la première ébauche

La version 2 reconnaît la première emprise fixe (`X -58..58, Z 780..920`). Sur les mondes où cette ancienne ville avait été générée, elle nettoie uniquement cette emprise et la transforme en petite lagune au niveau d'eau local. Elle ne modifie ni le château, ni les villages, ni les parcelles de guilde. Sur un monde neuf, cette migration est ignorée.

Faire une sauvegarde du monde avant une mise à jour majeure reste recommandé.

## Commandes d'administration

- `/gdo_city_info` — version, état, coordonnées et altitude du site sélectionné.
- `/gdo_city_rebuild` — reconstruit uniquement l'emprise du port au site déjà validé.

La reconstruction n'effectue pas une nouvelle recherche d'emplacement et ne déplace pas la carte. Pour une validation visuelle, tester les accès, les voûtes des ponts, la hauteur des mâts, les intérieurs et les transitions vers l'eau dans Luanti.

## État de validation

La génération procédurale et la migration sont implémentées dans le dépôt. La carte doit encore être parcourue en jeu sur une vraie instance Luanti ; aucune capture d'une exécution de la version 2 n'est disponible pour l'instant.
