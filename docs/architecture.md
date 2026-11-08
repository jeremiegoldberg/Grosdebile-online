# Architecture cible

## Principes

1. **Serveur autoritaire** : le serveur Luanti valide déplacements, combats, butin et progression en jeu.
2. **Séparation des responsabilités** : le moteur ne devient pas le backend métier ni le serveur ActivityPub.
3. **Indépendance de la fédération** : le jeu reste jouable si le service social est indisponible.
4. **Données privées séparées** : identifiants, e-mails et données personnelles ne sont jamais exposés dans les profils publics.
5. **Interopérabilité** : protocoles documentés, API versionnées et formats exportables.
6. **Multiplateforme** : UI et contrôles adaptés au PC, au tactile et aux contrôleurs VR.

## Composants

### Luanti et game Lua

Le serveur Luanti héberge le monde et exécute les règles de jeu. Le jeu `gdo` regroupe les mods propres au projet : noyau, personnages, combat, entités, objets, quêtes, progression, monde et interface.

La caméra troisième personne est l'expérience de référence sur PC/mobile. Une expérience VR immersive est une cible expérimentale qui devra être testée sur un portage Luanti compatible OpenXR ; elle ne doit pas être considérée comme acquise par le seul fait que le serveur est Luanti.

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
