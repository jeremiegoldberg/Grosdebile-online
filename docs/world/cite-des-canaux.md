# Cité des Canaux

## Rôle dans le monde

La Cité des Canaux est une nouvelle région indépendante du Royaume du Nawak. Elle est ajoutée **en plus** du Château des Brumes et des quatre villages de guildes. Elle devient le point d'apparition principal des nouveaux joueurs.

La direction visuelle reprend la composition de la capture `elven.png` du diaporama NLite : ville dense au bord de l'eau, canaux navigables, quais en pierre, ponts, maisons à colombages, toitures pentues et tours qui émergent du tissu urbain.

La capture reste une référence de travail fournie dans l'archive, pas un asset du jeu. La région Luanti est une reconstruction procédurale originale, et non un import de monde Minecraft.

## Emprise et coordonnées

| Élément | Coordonnées |
|---|---|
| Emprise protégée | X -58 à 58, Z 780 à 920 |
| Centre de la place | X 0, Z 870 |
| Apparition | X 0, Z 861 |
| Hôtel de ville | X -14 à 14, Z 885 à 909 |
| Canal principal | X -55 à 56, Z 838 à 849 |
| Bassin portuaire | X -57 à -40, Z 827 à 860 |
| Canal secondaire | X 22 à 33, Z 848 à 910 |
| Porte sud | Z 914 à 915 |

L'altitude de base est calculée à partir du terrain naturel après émergence des chunks. La ville a son propre stockage et sa propre version ; sa reconstruction ne touche qu'à son emprise.

## Composition

- **Port ouest** : bassin, deux pontons, marchandises, barils, caisses et lanternes.
- **Canal principal** : axe est-ouest avec quais et trois ponts de pierre.
- **Canal secondaire** : branche au sud-est avec passage transversal.
- **Quartiers nord** : maisons de plusieurs variantes, toits rouges ou ardoise, fenêtres et colombages.
- **Quartiers sud** : maisons de rive, jardins, rue secondaire et entrée fortifiée.
- **Place centrale** : pavage, fontaine et étals de marché.
- **Hôtel de ville** : grand bâtiment en pierre, entrée monumentale et tour d'horloge.
- **Liaison** : pierre de passage vers le Château des Brumes.

## Démarrage et déplacements

Les nouveaux personnages apparaissent sur la partie sud de la place centrale, à l'écart de la fontaine. Si la ville n'a pas fini de se générer lorsque le joueur arrive, le déplacement est mis en attente puis appliqué dès que les chunks et les bâtiments sont prêts.

- `/gdo_city` : rejoindre la ville.
- `/gdo_castle` : rejoindre le Château des Brumes.
- Pierre de passage au centre de la place : retour au château.

La cité est protégée en lecture seule. Le spawn naturel du bestiaire l'exclut également ; les monstres apparaissent dans les terres sauvages.

## Commandes d'administration

- `/gdo_city_info` : version, altitude et état.
- `/gdo_city_rebuild` : reconstruit la seule emprise urbaine.

**Attention :** la reconstruction remplace toute la zone X -58..58, Z 780..920. Faire une sauvegarde du monde avant de l'utiliser si des changements de carte sont intervenus dans cette emprise.

## Améliorations à prévoir

- Ajouter les intérieurs détaillés, commerces, auberges, habitations accessibles et PNJ de quartier.
- Ajouter des bateaux pilotables et une économie portuaire.
- Relier les façades au canal avec escaliers de quai et passerelles secondaires.
- Produire des textures et modèles originaux plus riches après stabilisation de la géométrie.
- Tester les trajets à pied, la navigation, les collisions et la visibilité dans Luanti sur PC et Android.
