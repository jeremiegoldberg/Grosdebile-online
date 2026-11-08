# Backend Go

Le backend fournira les API web et les services persistants qui ne relèvent pas du moteur Luanti.

Principes :
- API versionnée sous `/v1`.
- Validation stricte des entrées.
- Hashage de mots de passe avec une fonction adaptée (Argon2id recommandé).
- Limitation de débit, vérification d'adresse e-mail et récupération de compte avant ouverture publique.
- Secrets uniquement via variables d'environnement ou gestionnaire de secrets.
- Aucun endpoint public ne doit permettre de modifier directement l'état du gameplay sans validation serveur.

L'API d'inscription seule ne constitue pas un système d'authentification complet.
