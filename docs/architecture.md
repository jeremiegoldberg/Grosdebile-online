# Architecture cible

## Principes

1. **Serveur autoritaire** : le serveur Luanti valide déplacements, combats, butin et progression en jeu.
2. **Séparation des responsabilités** : le moteur ne devient pas le backend métier ni le serveur ActivityPub.
3. **Indépendance de la fédération** : le jeu reste jouable si le service social est indisponible.
4. **Données privées séparées** : identifiants, e-mails et données personnelles ne sont jamais exposés dans les profils publics.
5. **Interopérabilité** : protocoles documentés, API versionnées et formats exportables.
6. **Multiplateforme** : UI et contrôles adaptés au PC, au tactile et aux contrôleurs VR.

## Composants

### Luanti et jeu Lua

Le serveur Luanti héberge le monde et exécute les règles de jeu. Le jeu `gdo` est composé de modules autonomes :

| Module | Responsabilité |
|---|---|
| `gdo_core` | Monde de départ, objets fondamentaux et premier PNJ |
| `gdo_rpg` | Races, classes, statistiques, XP, niveaux, mana, endurance et capacités |
| `gdo_combat` | Armes, dégâts et consommables de combat |
| `gdo_magic` | Sorts et effets magiques |
| `gdo_bestiary` | Créatures, IA, butin et récompenses |
| `gdo_npcs` | Quêtes, interactions et dialogues à étendre |
| `gdo_mounts` | Montures terrestres et aériennes |
| `gdo_economy` | Portefeuille local et transferts |
| `gdo_society` | Maisons, guildes, villages et parcelles |
| `gdo_zones` / `gdo_castle` | Protection et génération du Château des Brumes |
| `gdo_city` | Région indépendante de la Cité des Canaux et point d'apparition |

Les modules RPG sont natifs Lua, sans framework de mobs obligatoire. Les régions sont générées séparément et disposent de leur propre emprise/version : reconstruire une région ne doit pas réinitialiser les autres. La caméra troisième personne est l'expérience de référence sur PC/mobile. Une expérience VR immersive reste une cible expérimentale qui devra être testée sur un portage Luanti compatible OpenXR.

### Données et progression

Les valeurs de personnage sont conservées dans les métadonnées Luanti, côté serveur. Les clés de niveau et d'expérience `gdo_level` et `gdo_xp` déjà utilisées par GDO restent la source de vérité pour éviter une migration destructive. Le backend Go pourra ensuite fournir une synchronisation transactionnelle, sans devenir nécessaire pour jouer en local.

### Monde et régions

La Cité des Canaux utilise un module autonome `gdo_city`, qui dépend des matériaux/helpers du château mais possède son propre stockage/version et une emprise dédiée (X -58..58, Z 780..920). Son terrain est échantillonné après l'émergence des chunks, aplani sur une altitude locale, puis reconstruit uniquement dans cette emprise.

Le Château des Brumes continue d'utiliser l'architecture par zones dans `gdo_castle/architecture/`. Les villages de guildes restent gérés par `gdo_society`. Les trois systèmes coexistent dans le même monde ; la nouvelle ville n'écrase ni la forteresse ni les villages de guilde.

Les nouveaux joueurs apparaissent dans la Cité des Canaux. La pierre de passage et les commandes `/gdo_city` et `/gdo_castle` maintiennent une liaison simple entre la ville et le Château des Brumes.

### Backend Go

Le backend gère les comptes web, les profils, les personnages persistants, les guildes et les opérations qui ne doivent pas être confiées au client. L'intégration avec l'authentification native Luanti devra faire l'objet d'une décision technique et d'un prototype avant de promettre un compte unique.

### PostgreSQL

PostgreSQL conserve les données métier. Les données du monde restent dans le stockage natif Luanti, sauf décision ultérieure justifiée. Les secrets sont fournis au runtime par le gestionnaire de secrets de l'environnement, jamais versionnés.

### Fédération ActivityPub

Un service indépendant gère les acteurs, WebFinger, boîtes de réception/sortie, abonnements, signatures HTTP, livraisons asynchrones et modération. Les événements de jeu sont transformés en publications publiques après validation côté serveur.

ActivityPub ne synchronise pas le gameplay : inventaires, positions, combats et transferts de personnages nécessiteraient un protocole distinct et des règles de confiance entre serveurs.

### Déploiement

Docker pour les images ; Kubernetes pour les environnements persistants. Le serveur de jeu expose son trafic UDP directement via LoadBalancer/MetalLB ou une solution réseau adaptée, pas via un Ingress HTTP classique. PostgreSQL doit utiliser des volumes persistants et des sauvegardes testées.

## Cibles clients

- PC Linux/Windows : client Luanti standard.
- Android : client Luanti Android ; interfaces tactiles à concevoir.
- Meta Quest : portage Luanti VR/OpenXR externe à qualifier, avec tests de compatibilité des mods, performances et confort.
- iOS : non engagé à ce stade.

## Décisions à formaliser

Les choix structurants seront consignés dans `docs/decisions/` sous forme d'ADR : authentification, stockage, versionnement du monde, fédération, licences, transferts interserveurs et modèle de modération.
