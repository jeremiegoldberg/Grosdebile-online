# Portage NLite vers Luanti — plan et inventaire

## Objectif

Faire évoluer Gros Débile Online en un MMORPG Luanti qui retrouve les grandes boucles de jeu de NLite : personnage typé, progression, équipement, combat actif, magie, bestiaire, quêtes et montures. Le portage est une réimplémentation native Lua : il ne charge ni Forge, ni Java, ni les JAR Minecraft.

La priorité est la sensation de jeu et la richesse des systèmes, pas la reproduction à l'identique de chaque écran ou de chaque bloc Minecraft. Les systèmes doivent rester légers, server-authoritative et compatibles PC/Android.

## Source examinée

Archive analysée : `NLite-16.0.zip`.

- Modpack CurseForge Minecraft 1.20.1, Forge 47.4.26.
- 199 références de mods dans `manifest.json` ; les JAR sont des dépendances référencées, pas des sources Lua directement réutilisables.
- La configuration embarque `CustomMobs`, `custom_races`, `CustomNpcs`, Mine and Slash, Epic Fight et Iron's Spells.
- `custom_races/races.json` contient 10 races : Centaur, Blazeborn, Enderian, Feline, Golem, Arachnid, Merling, Dwarf, Dragonkin et Elf.
- `CustomMobs/Mobs/Unpacked` contient 1 144 dossiers de créatures, 1 135 fichiers `.geo.json`, 1 122 fichiers `.animation.json` et 1 145 PNG.
- Six configurations `mount.json` et deux configurations `mob.json` ont été trouvées dans le dossier d'assets.
- `CustomMobs/abilities.json` fournit un catalogue d'aptitudes avec temps de recharge, puissance, durée et caractère passif/actif.

Les fichiers de configuration sont utiles comme inventaire fonctionnel, mais ne prouvent pas à eux seuls que les modèles, textures, animations, sons et codes des mods peuvent être redistribués.

## Correspondance des systèmes

| Expérience NLite | Implémentation GDO | Stratégie Luanti |
|---|---|---|
| Custom Races | `gdo_rpg` | 10 races, bonus de caractéristiques et une capacité active |
| Mine and Slash | `gdo_rpg`, `gdo_combat` | XP, niveaux, statistiques, butin et équipement évolutifs |
| Epic Fight | `gdo_combat` | Dégâts serveur, armes différenciées ; animations dédiées plus tard |
| Iron's Spells | `gdo_magic` | Sorts natifs avec coût de mana, ciblage et effets |
| CustomMobs | `gdo_bestiary` | Entités Lua, IA légère, combat, butin et XP |
| CustomNPCs | `gdo_npcs` | Registre de quêtes et interactions par formspec ; dialogues complets à étendre |
| Mounts | `gdo_mounts` | Montures pilotables au sol et en vol, persistance à finaliser |
| Économie | `gdo_economy` | Portefeuille local et transferts entre joueurs |

## Première tranche livrée dans le dépôt

- Création de personnage par formulaire, choix d'une race et d'une classe.
- 10 races et 3 classes : Guerrier, Mage et Rôdeur.
- Progression XP/niveaux centralisée, en réutilisant les clés `gdo_level` et `gdo_xp` déjà présentes dans GDO.
- Régénération de mana et d'endurance, bonus de statistiques et capacité raciale avec recharge.
- Quatre sorts : trait de feu, soin, nova de givre et décharge arcanique.
- Armes de départ, bandage, trois créatures hostiles et œufs d'apparition.
- Une quête de chasse aux gobelins, monnaie locale et transferts.
- Apparition naturelle limitée à cinq créatures autour d'un joueur, toutes les 25 secondes au maximum, hors zone du château ; désactivation possible par réglage serveur.
- Cheval terrestre et drake volant pilotables.

Les entités et icônes temporaires utilisent des textures simples générées par l'engine. C'est volontaire : les visuels ne sont pas encore au niveau de NLite.

## Nouvelle région ajoutée après le premier portage RPG

La région urbaine de départ est une reconstruction de Sommières, et non une cité NLite. Le centre historique est modélisé autour du Vidourle, du pont romain habité, des rues médiévales, des arcades, des quais et du château. Voir la fiche de Sommières dans world/sommieres.md.

## Ce qui reste à porter

1. Prototyper puis valider un convertisseur des géométries Bedrock/GeckoLib vers glTF/GLB ; reconstruire ou simplifier les squelettes et animations lorsque la conversion directe n'est pas possible.
2. Vérifier la provenance et les licences de chaque modèle, texture, son et animation avant import ou redistribution.
3. Importer le bestiaire par lots et définir les familles, niveaux, élites, résistances et comportements.
4. Développer le butin par rareté, affixes d'objets, équipement, inventaire spécialisé et statistiques détaillées.
5. Étendre les arbres de compétences, sorts, synergies et effets d'état.
6. Construire les dialogues, marchands, factions, quêtes à étapes, boss et donjons.
7. Finaliser les montures : selles, inventaire cargo, endurance, lien, évolutions, combat et animations.
8. Affiner le spawn sauvage déjà limité : budgets par région, types de créatures selon les biomes et réglages de difficulté.
9. Ajouter tests automatisés, équilibrage multi-joueur et sauvegarde/export de personnage.

## Contraintes de légèreté

- Pas de dépendance obligatoire à un framework de mobs externe.
- IA cadencée, pas de recherche de cible à chaque frame.
- Pas de scan global des assets à chaque démarrage.
- Spawn naturel plafonné, uniquement autour des joueurs présents dans les terres sauvages ; aucun remplissage global de carte.
- Données joueur compactes dans les métadonnées Luanti ; migration backend séparée.
- Modèles et textures chargés à la demande et optimisés pour mobile.
- Mesurer le temps serveur, le nombre d'entités et le trafic média avant d'augmenter le bestiaire.

## Commandes ajoutées

| Commande | Utilité |
|---|---|
| `/gdo_character` | Créer ou consulter son personnage |
| `/gdo_stats` | Voir niveau, XP, PV, mana, endurance et bonus |
| `/gdo_ability` | Déclencher la capacité de sa race |
| `/gdo_spells` | Lister les sorts |
| `/gdo_spell <nom>` | Lancer un sort |
| `/gdo_bestiary` | Afficher les créatures de test |
| `/gdo_quests` | Consulter et gérer la prime aux gobelins |
| `/gdo_wallet` | Voir son portefeuille |
| `/gdo_pay <joueur> <montant>` | Transférer des pièces |
| `/gdo_mount <horse|dragon>` | Faire apparaître une monture (privilège serveur) |

## Notes de compatibilité

Cible : Luanti 5.17 ou supérieur ; Luanti 5.18 recommandé. Le dépôt conserve la compatibilité historique avec `minetest.*`, alias encore supporté par Luanti. Les formulaires, raycasts, entités, contrôles de joueur et modifications de PV utilisent l'API Lua native.
