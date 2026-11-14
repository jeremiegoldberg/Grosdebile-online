# Lancer le prototype GDO sous Linux

Cette première ébauche est un **jeu Luanti autonome** : elle ne nécessite ni Minetest Game, ni framework de mobs externe, ni backend Go, ni serveur distant.

## 1. Prérequis

- Luanti 5.17 ou supérieur (5.18 recommandé).
- Git.

Sur Debian/Ubuntu, selon la version de ta distribution, le paquet peut s'appeler `luanti` ou `minetest`. Sur Debian, les dépôts peuvent fournir une version ancienne ; Flatpak ou le paquet officiel peut alors être préférable.

## 2. Récupérer et installer

```bash
git clone https://github.com/jeremiegoldberg/Grosdebile-online.git
cd Grosdebile-online
mkdir -p ~/.minetest/games
rm -rf ~/.minetest/games/gdo
cp -a game/gdo ~/.minetest/games/gdo
luanti
```

Dans le menu, crée un monde et sélectionne **Gros Débile Online** comme jeu. Si la commande `luanti` n'existe pas, essaie `minetest` selon le nom du paquet installé.

Sur un monde déjà existant, fais une sauvegarde avant la mise à jour. Le Sommières sera générée sur un site continental séparé ; le Château des Brumes et les villages de guildes ne seront pas reconstruits.

## 3. Première connexion : Sommières

Le jeu recherche d'abord un terrain continental assez plat, puis y reconstruit **Sommières** : Vidourle nord-sud, pont romain habité est-ouest de 21 arches, rues médiévales, arcades du marché, beffroi, Porte du Bourguet, église Saint-Pons, quais et château sur son éperon.

- Les nouveaux joueurs arrivent sur la petite place à l'est du canal.
- La pierre de passage permet de rejoindre le Château des Brumes.
- Utilise `/gdo_city` pour revenir au port depuis n'importe quelle région.
- Utilise `/gdo_castle` pour rejoindre directement le château.
- Le port est une zone scénarisée protégée.

Le terrain n'est modifié qu'après validation du sol sec. Si aucun site continental n'est trouvé, le joueur reste au château et le serveur réessaie plus tard ; il ne doit jamais apparaître au fond d'un lac.

## 4. Créer son personnage

À la première connexion, la fenêtre de création s'ouvre automatiquement. Choisis l'une des dix races et l'une des trois classes. Tu peux rouvrir les informations de ton personnage avec `/gdo_character`.

- **Races** : Centaure, Né-de-la-flamme, Endérien, Félin, Golem, Arachnide, Merling, Nain, Sang-dragon et Elfe.
- **Classes** : Guerrier (résistance), Mage (mana) et Rôdeur (mobilité).
- Les choix sont définitifs pour cette version.
- `/gdo_stats` affiche les statistiques ; `/gdo_ability` déclenche la capacité raciale.

## 5. Combat et magie

Le clic gauche permet d'attaquer avec l'arme tenue. Les armes de départ se fabriquent avec les ressources GDO :
- Épée en bois : deux bois.
- Épée de pierre : deux pierres et un bois.
- Bandage : deux navets héroïques.

Les quatre sorts disponibles sont `firebolt`, `heal`, `frostnova` et `arcane_burst`. Utilise `/gdo_spells` pour les détails et `/gdo_spell <nom>` pour lancer un sort. Le mana se régénère automatiquement.

## 6. Monstres, quêtes et montures

Le bestiaire contient trois créatures : gelée des marais, gobelin pillard et loup des brumes. Un spawn naturel limité est activé dans les terres sauvages, loin du Château des Brumes et de Sommières. Il peut être désactivé dans `minetest.conf` avec `gdo_bestiary_natural_spawn = false`. Les œufs d'apparition sont aussi disponibles en mode créatif.

La commande `/gdo_quests` ouvre le tableau des aventuriers : accepte la prime aux gobelins, élimine trois gobelins et réclame ton XP et tes pièces. `/gdo_wallet` affiche ton solde et `/gdo_pay <joueur> <montant>` transfère des pièces à un joueur connecté.

Les administrateurs peuvent faire apparaître un cheval ou un drake volant avec `/gdo_mount horse` ou `/gdo_mount dragon`. Clic droit pour monter ; ZQSD/WASD pour piloter. À cheval, Maj permet de descendre ; sur le drake, Espace fait monter, Maj fait descendre et Aux1 permet de descendre de monture. Un second clic droit permet aussi de descendre.

## 7. Le Château des Brumes et les villages de guildes

Le Château des Brumes est conservé à son emplacement historique :
- Depuis Sommières, utilise la pierre de passage sur la place ou la commande `/gdo_castle`.
- Traverse le pont et la grande porte.
- Dans la cour, cherche le **Bureau des Quêtes**.
- Visite la grande salle de banquet, la bibliothèque, la salle de cours et la galerie des trophées.
- Visite les quatre pavillons : Bras Cassés, Mages du Dimanche, Rats de Bibliothèque et Seigneurs du Navet.
- Gérard le Magnifique t'attend près de l'entrée de la cour. Clique droit sur lui pour accepter sa quête des trois navets héroïques.

Les quatre villages fondateurs restent présents autour de leurs coordonnées historiques. Les commandes `/gdo_guild`, `/gdo_plot`, `/gdo_guild_create`, `/gdo_guild_invite` et `/gdo_guild_join` gèrent les guildes.

## 8. Commandes de carte

| Commande | Action |
|---|---|
| `/gdo_city` | Téléportation vers Sommières |
| `/gdo_castle` | Téléportation vers le Château des Brumes |
| `/gdo_city_info` | État/version et coordonnées de la cité |
| `/gdo_city_rebuild` | Reconstruction de la seule emprise urbaine (admin) |
| `/gdo_site_info` | Altitudes du site du château |
| `/gdo_zone40_info` | État de la citadelle gothique |
| `/gdo_zones` | Liste des zones protégées et règles de construction |

**Attention :** `/gdo_city_rebuild` reconstruit l'emprise du Sommières au site déjà enregistré. Il ne déplace pas la ville et ne touche pas au château ni aux villages.

## 9. Limites connues

- Le Sommières est une reconstruction procédurale bâtiment par bâtiment à partir de sa géographie, de ses rues, de photographies, des vues Street View disponibles et de documents patrimoniaux. Les textures sont originales et ne recopient pas les photographies.
- Les rues, maisons et bâtiments sont construits en blocs Luanti ; l'architecture et les textures restent provisoires.
- Les créatures utilisent des formes cubiques et des textures temporaires ; les modèles et animations NLite ne sont pas encore importés.
- Le jeu est un prototype : les boss, donjons complets, marchands, équipement avancé, animations dédiées et économie centralisée restent à développer.
- Le code et la nouvelle carte doivent encore être parcourus et validés dans le client Luanti réel sur PC et Android.

## Dépannage

Si le jeu n'apparaît pas dans la liste, vérifie que le chemin est exactement `~/.minetest/games/gdo/game.conf`, puis ferme et relance Luanti. En cas d'erreur Lua, consulte `debug.txt` dans le répertoire de données Luanti et joins les lignes autour de l'erreur.
