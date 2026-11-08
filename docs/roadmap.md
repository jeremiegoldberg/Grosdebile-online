# Feuille de route

Les étapes sont indicatives. Une fonctionnalité n'est considérée comme livrée qu'après tests et documentation.

## Phase 0 — Fondations
- [x] Dépôt public et identité du projet
- [x] Vision open source et principes de contribution
- [x] Architecture cible et séparation code/contenus/données privées
- [ ] Ajouter les textes complets des licences et notices tierces
- [ ] CI de lint et tests de base
- [ ] Premier prototype Luanti minimal et reproductible

## Phase 1 — Prototype jouable
- [ ] Jeu Luanti `gdo` chargeable
- [ ] Spawn, déplacement et première région
- [ ] Trois classes initiales : guerrier, mage, chasseur
- [ ] Combat PvE simple, inventaire et équipement
- [ ] PNJ et premières quêtes humoristiques
- [ ] Sauvegarde et persistance validées

## Phase 2 — Monde du Nawak
- [ ] Géographie et régions documentées
- [ ] Biomes, villages et points d'intérêt
- [ ] Bestiaire, boss et donjons
- [ ] Construction limitée et protection des zones
- [ ] Outils de création et validation des cartes

## Phase 3 — Comptes et services
- [ ] API Go et PostgreSQL
- [ ] Inscription et authentification sécurisées
- [ ] Liaison sûre entre compte web et identité Luanti
- [x] Guildes fondatrices, parcelles personnelles et maisons de départ (prototype local)\n- [x] Création de guildes au niveau 10, invitations et rôles de construction (prototype local)\n- [x] Villages de guildes avec bâtiments communs et croissance par effectif (prototype visuel)\n- [ ] Persistance centralisée des personnages, guildes et économie
- [ ] Sauvegardes, observabilité et procédures d'exploitation

## Phase 4 — Clients et accessibilité
- [ ] Interface PC
- [ ] Interface tactile Android
- [ ] Support manette
- [ ] Tests sur matériel ancien
- [ ] Prototype VR Meta Quest via OpenXR, sous réserve du portage client
- [ ] Options de confort VR et tests de cybersickness

## Phase 5 — Fediverse
- [ ] Modèle d'acteurs et de profils publics
- [ ] WebFinger et ActivityPub
- [ ] Profils de joueurs et guildes
- [ ] Publications de succès et événements avec consentement
- [ ] Modération, blocage et protection anti-abus
- [ ] Connecteurs Bluesky/Nostr éventuels, séparés d'ActivityPub

## Phase 6 — Communauté et fédération de mondes
- [ ] Guide d'auto-hébergement
- [ ] Serveurs communautaires indépendants
- [ ] Annuaire de serveurs
- [ ] Événements interserveurs
- [ ] Étude d'un protocole de transfert de personnages, sans supposer une compatibilité automatique
- [ ] Ouverture publique progressive et audit sécurité

## Hors périmètre initial

- Monde infini ou dépassement des limites natives Luanti
- Synchronisation automatique des inventaires entre serveurs arbitraires
- Compatibilité garantie avec tous les casques VR
- Client iOS avant étude de faisabilité
