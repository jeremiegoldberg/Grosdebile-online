# Backend Go

Le backend fournit les API web et les services persistants qui ne relèvent pas du moteur Luanti.

Principes :
- API versionnée sous `/v1`.
- Validation stricte des entrées.
- Hashage de mots de passe avec une fonction adaptée (Argon2id recommandé).
- Limitation de débit, vérification d'adresse e-mail et récupération de compte avant ouverture publique.
- Secrets uniquement via variables d'environnement ou gestionnaire de secrets.
- Aucun endpoint public ne doit permettre de modifier directement l'état du gameplay sans validation serveur.

## Économie — première tranche

Le service `cmd/gdo-api` expose le registre économique PostgreSQL :
- `GET /healthz` vérifie la disponibilité de PostgreSQL.
- `POST /v1/internal/economy/mob-reward` crédite une récompense après validation du serveur de jeu.
- `GET /v1/internal/economy/wallet/{player}` lit un solde.

Les deux routes économiques sont réservées au serveur de jeu via `Authorization: Bearer $GDO_GAME_SERVER_TOKEN`. Le montant n'est jamais accepté dans la requête : le backend choisit la récompense selon le type de monstre. Les identifiants d'événement rendent les nouvelles tentatives idempotentes.

Configuration : `DATABASE_URL`, `GDO_GAME_SERVER_TOKEN`, et optionnellement `HTTP_ADDR` (défaut `:8080`). Appliquer `migrations/001_economy.sql` avant le démarrage.

Cette première tranche implémente les portefeuilles joueurs et le journal des créations monétaires par monstres. Les transferts, trésoreries de guildes, marchés et authentification des joueurs restent à développer ; ne pas exposer ces routes internes à Internet.
