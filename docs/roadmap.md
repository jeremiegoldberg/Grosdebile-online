# Feuille de route

Les étapes sont indicatives. Une fonctionnalité n'est considérée comme livrée qu'après tests et documentation.

## Phase 0 — Fondations
- [x] Dépôt public et identité du projet
- [x] Vision open source et principes de contribution
- [x] Architecture cible et séparation code/contenus/données privées
- [ ] Ajouter les textes complets des licences et notices tierces
- [ ] CI de lint et tests de base
- [x] Prototype Luanti minimal et reproductible

## Phase 1 — Prototype RPG (portage NLite)
- [x] Création de personnage et choix parmi 10 races et 3 classes
- [x] XP, niveaux, statistiques, mana et endurance
- [x] Capacités raciales avec coûts et recharge
- [x] Quatre sorts natifs et armes de départ
- [x] Trois créatures hostiles de test, spawn sauvage plafonné et récompenses XP/butin
- [x] Première quête de chasse et portefeuille local
- [x] Monture terrestre et monture volante de test
- [ ] Tests en jeu sous Luanti 5.17/5.18 et équilibrage multi-joueur
- [ ] UI RPG intégrée, équipement, raretés, affixes et arbres de compétences
- [ ] Animation de combat et feedback visuel final

## Phase 2 — Monde du Nawak
- [x] Générateur Sommières indépendant, sans supprimer le Château des Brumes ni les villages de guildes
- [x] Générateur Sommières : Vidourle, pont romain de 21 arches, rues, maisons mitoyennes, arcades, beffroi, château et textures dédiées
- [x] Apparition principale dans la ville et liaison de retour au château
- [x] Protection de la ville et exclusion du spawn naturel des monstres
- [ ] Vérifier en jeu l'altitude, les 21 arches, les raccords de rues, les façades et les accès au château
- [ ] Intérieurs accessibles, commerces, auberge et PNJ de quartier
- [ ] Géographie complète et régions documentées
- [ ] Biomes, villages, bestiaire étendu, élites, boss et donjons
- [ ] Outils de création et validation des cartes

## Phase 3 — Services et économie
- [ ] API Go et PostgreSQL
- [ ] Inscription et authentification sécurisées
- [ ] Liaison sûre entre compte web et identité Luanti
- [x] Guildes fondatrices, parcelles personnelles et maisons de départ (prototype local)
- [x] Création de guildes, invitations et rôles (prototype local)
- [x] Portefeuille local et transferts entre joueurs
- [ ] Marchands, hôtel des ventes, crafting avancé et économie persistante centralisée
- [ ] Persistance centralisée des personnages, guildes et économie
- [ ] Sauvegardes, observabilité et procédures d'exploitation

## Phase 4 — Import des contenus NLite
- [ ] Audit des droits et provenances pour les modèles, textures, animations et sons
- [ ] Convertisseur et pipeline de validation Geo/Bedrock vers glTF/GLB
- [ ] Import progressif des créatures et montures
- [ ] Animation, morphologie et optimisation mobile
- [ ] Vérification du budget mémoire et du coût réseau des médias

## Phase 5 — Clients et accessibilité
- [ ] Interface PC
- [ ] Interface tactile Android
- [ ] Support manette
- [ ] Tests sur matériel ancien
- [ ] Prototype VR Meta Quest via OpenXR, sous réserve du portage client
- [ ] Options de confort VR et tests de cybersickness

## Phase 6 — Fediverse
- [ ] Modèle d'acteurs et de profils publics
- [ ] WebFinger et ActivityPub
- [ ] Profils de joueurs et guildes
- [ ] Publications de succès et événements avec consentement
- [ ] Modération, blocage et protection anti-abus
- [ ] Connecteurs Bluesky/Nostr éventuels, séparés d'ActivityPub

## Phase 7 — Communauté et fédération de mondes
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
