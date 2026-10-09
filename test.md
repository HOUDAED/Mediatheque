# TP1 — Résultats des tests

Serveur : MariaDB 10.11 (Ubuntu 24.04). Base chargée avec `Base/01-schema.sql` et `Base/02-donnees.sql`,
puis `01-roles-et-comptes.sql` rejoué.

Vérification du jeu de données : `SELECT COUNT(*) FROM mediatheque.adherent;` → 40.

Chaque test a été fait **connecté avec le compte concerné** (jamais en root). Les lignes renvoyées
ne sont pas recopiées ici : seul le nombre de lignes est indiqué, pour ne pas exposer de données
personnelles d'adhérents.

## Rôle actif à la connexion

| Compte | `SELECT CURRENT_ROLE();` |
|---|---|
| `app_media` | `role_prets` |
| `biblio_marie` | `role_adherents` |
| `stagiaire` | `role_catalogue` |
| `analyste` | `role_catalogue` |

Aucun compte ne renvoie `NONE` : les rôles par défaut sont bien activés à chaque connexion.

## `app_media` — l'application web

| # | Commande | Attendu | Obtenu |
|---|---|---|---|
| 1 | `SELECT id, nom, prenom FROM adherent LIMIT 5;` | OK | OK (5 lignes) |
| 2 | `SELECT email FROM adherent LIMIT 1;` | refus | `ERROR 1143 (42000)` |
| 3 | `UPDATE exemplaire SET disponible = 0 WHERE id = 3;` | OK | OK (1 ligne modifiée) |
| 4 | `UPDATE exemplaire SET etat = 'use' WHERE id = 3;` | refus | `ERROR 1143 (42000)` |
| 5 | `DELETE FROM emprunt WHERE id = 1;` | refus | `ERROR 1142 (42000)` |

Les tests 3 et 4 portent sur la même table : seul `disponible` est modifiable, d'où le refus de
niveau colonne (1143) sur `etat`.

## `biblio_marie` — la bibliothécaire

| # | Commande | Attendu | Obtenu |
|---|---|---|---|
| 6 | `SELECT nom, email, telephone FROM adherent LIMIT 3;` | OK | OK (3 lignes) |
| 7 | `CREATE USER 'test'@'localhost' IDENTIFIED BY 'Test!2026';` | refus | `ERROR 1227 (42000)` |

## `stagiaire`

| # | Commande | Attendu | Obtenu |
|---|---|---|---|
| 8 | `SELECT nom, prenom, ville FROM adherent LIMIT 5;` | OK | OK (5 lignes) |
| 9 | `SELECT email FROM adherent LIMIT 1;` | refus | `ERROR 1143 (42000)` |
| 10 | `SELECT * FROM adherent LIMIT 1;` | refus | `ERROR 1142 (42000)` |

**Question :** les tests 9 et 10 échouent tous les deux, mais pas avec le même numéro d'erreur. Pourquoi ?

> Le stagiaire n'a sur `adherent` que des privilèges **de colonne**. Au test 9, la requête nomme une
> colonne précise : le serveur la vérifie colonne par colonne et refuse `email` → erreur 1143
> (refus au niveau colonne). Au test 10, `*` demande toutes les colonnes de la table, ce qui
> exige un `SELECT` sur la table entière, que le stagiaire n'a pas → erreur 1142 (refus au niveau
> table).

## `analyste`

| # | Commande | Attendu | Obtenu |
|---|---|---|---|
| 11 | `SELECT COUNT(*) FROM adherent;` | refus | `ERROR 1142 (42000)` |
| 12 | `SELECT COUNT(*) FROM reservation;` | après le `GRANT` : OK — après le `REVOKE` : refus | après le `REVOKE` : `ERROR 1142 (42000)` — après le `GRANT` : OK (1 ligne) |

Le cycle du script a été vérifié avec `SHOW GRANTS FOR 'analyste'@'localhost';` :
la ligne `GRANT SELECT ON mediatheque.reservation` apparaît après le `GRANT` et disparaît après
le `REVOKE`. Le test « après le `GRANT` » a été refait en root, à la main, une fois le script
terminé — il faut rejouer le script pour revenir à l'état sans `reservation`.

## Privilèges de colonne

Lus dans `information_schema.column_privileges` :

| Bénéficiaire | Table | Colonnes | Privilège |
|---|---|---|---|
| `app_media` | `adherent` | `id`, `nom`, `prenom`, `actif` | `SELECT` |
| `stagiaire` | `adherent` | `id`, `nom`, `prenom`, `ville`, `date_inscription`, `actif` | `SELECT` |
| `role_prets` | `exemplaire` | `disponible` | `UPDATE` |
| `biblio_marie` | `exemplaire` | `disponible` | `UPDATE` |

Aucune ligne n'ouvre `email`, `telephone` ni `date_naissance` au stagiaire ou à l'application.

## Conclusion

**Parmi les quatre comptes, lequel peut encore faire quelque chose qu'il ne fera jamais — et comment le lui retireriez-vous ?**

> `app_media` : `role_prets` lui donne `UPDATE` sur **toutes** les colonnes d'`emprunt`, de
> `reservation` et de `penalite`. Il peut donc réécrire une `date_emprunt` ou le `montant` d'une
> pénalité, alors que l'application ne fait que clôturer (`date_retour_reelle`, `statut`, `payee`).
> On le lui retire en remplaçant l'`UPDATE` de table par des `UPDATE` de colonne dans le rôle :
> `REVOKE UPDATE ON mediatheque.penalite FROM role_prets;` puis
> `GRANT UPDATE (payee) ON mediatheque.penalite TO role_prets;` — et de même pour les deux autres tables.
