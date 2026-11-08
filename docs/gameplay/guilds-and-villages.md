# Guildes, parcelles et villages — règles de conception

## Principes

GDO combine la liberté de construction voxel de Minecraft, la progression et les quêtes d'un MMORPG, et le développement collectif de villages inspiré des jeux de stratégie.

### Quatre guildes fondatrices

Tout nouveau joueur choisit une des quatre guildes historiques au Château des Brumes :
- Les Bras Cassés
- Les Mages du Dimanche
- Les Rats de Bibliothèque
- Les Seigneurs du Navet

Ces quatre institutions sont permanentes. Leur village de départ possède des bâtiments communs préconstruits. L'inscription attribue au joueur une parcelle personnelle et une petite maison standardisée, modifiable par son propriétaire.

### Parcelles personnelles

- Une parcelle est attribuée automatiquement lors du choix de la guilde.
- Le propriétaire peut construire, modifier et démolir sur sa parcelle.
- Les autres joueurs ne peuvent pas y intervenir.
- La parcelle et la maison restent dans le village si le joueur quitte sa guilde ; il perd alors ses droits de modification.
- Les parcelles ne sont pas transférables dans ce prototype.

### Bâtiments communs

Les bâtiments communs sont construits avec le village et appartiennent à la guilde.
- Chef, officiers et bâtisseurs peuvent les modifier.
- Les membres ordinaires peuvent les utiliser, mais pas les modifier.
- Le chef attribue les rôles avec la commande de guilde.
- Les bâtiments visuels du prototype ne fournissent pas encore de production, stockage ou artisanat fonctionnels.

### Guildes créées par les joueurs

- Le niveau 10 débloque la fondation d'une guilde.
- Le joueur doit quitter sa guilde actuelle.
- Le fondateur devient chef et reçoit un nouveau village rudimentaire, avec bâtiments communs et sa propre parcelle.
- Les invitations sont envoyées à des joueurs connectés.
- Les rôles disponibles sont membre, bâtisseur et officier.
- Les guildes fondatrices ne peuvent pas être supprimées par leurs membres.

### Croissance du village

La première version fait évoluer visuellement le village d'une guilde de joueurs selon son effectif :
- 1 à 4 membres : noyau initial.
- 5 à 9 : première extension.
- 10 à 19 : seconde extension.
- 20 membres et plus : enceinte complète.

Les futures étapes ajouteront des ressources, des coûts de construction, des niveaux de bâtiments, des services et des décisions collectives.

### Protection du monde

- Les zones scénarisées restent en lecture seule.
- Les parcelles personnelles sont protégées contre les autres joueurs.
- Les zones de village sont réservées aux membres ; seuls les rôles autorisés peuvent modifier les bâtiments communs.
- Le monde sauvage hors villages et zones scénarisées reste libre et destructible.
- Les sièges et guerres de guildes ne sont pas encore implémentés.

## Commandes du prototype

| Commande | Fonction |
|---|---|
| `/maisons`, `/maison` | Présentation et choix d'une guilde fondatrice |
| `/gdo_guild` | Informations sur sa guilde |
| `/gdo_plot` | Coordonnées de sa parcelle |
| `/gdo_progression` | Niveau et expérience |
| `/gdo_guild_leave` | Quitter sa guilde |
| `/gdo_guild_create <nom>` | Fonder une guilde au niveau 10 |
| `/gdo_guild_invite <joueur>` | Inviter un joueur connecté |
| `/gdo_guild_join` | Accepter une invitation |
| `/gdo_guild_role <joueur> <member|builder|officer>` | Attribuer un rôle (chef uniquement) |

L'expérience est actuellement attribuée par la quête des trois navets (100 XP). Les autres quêtes pourront appeler `gdo_society.add_experience(player, amount)`.

## Limites techniques connues

Les données de guildes, invitations et parcelles sont conservées dans le mod storage du monde Luanti. Il n'y a pas encore de backend centralisé, de transfert entre serveurs, de système de suppression/renommage de guilde, ni d'outils de déménagement de parcelle. Les structures sont des prototypes en blocs avec textures de remplacement. Le chargement et le comportement doivent être validés dans Luanti avant une mise en production.
