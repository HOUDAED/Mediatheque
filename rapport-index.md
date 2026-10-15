# TP2 — Rapport d'optimisation

> Les chiffres attendus sont des **ordres de grandeur** : l'archive est générée
> aléatoirement, les vôtres seront proches sans être identiques.

## Avant / après

Pour chaque requête : le plan avant tout index, puis le plan après l'index que vous avez posé.

### R1 — les emprunts d'une journée

```sql
SELECT * FROM emprunt WHERE date_emprunt = '2024-03-12';
```

| | `type` | `key` | `rows` | `Extra` |
|---|---|---|---|---|
| avant | `ALL` | `NULL` | `199875` | `Using where` |
| après | à relever avec `EXPLAIN` après création de l'index | | | |

- Index créé : `                                                        `
- Lignes réellement renvoyées : `104`
- Une phrase de conclusion : Sans index, MariaDB parcourt environ 199875 lignes pour en renvoyer 104 correspondant à cette date.

### R2 — les emprunts en cours

```sql
SELECT * FROM emprunt WHERE date_retour_reelle IS NULL;
```

| | `type` | `key` | `rows` | `Extra` |
|---|---|---|---|---|
| avant | à relever avec `EXPLAIN` avant création de l'index | | | |
| après | à relever avec `EXPLAIN` après création de l'index | | | |

- Index créé : `à renseigner après sa création`
- Lignes réellement renvoyées : `30`
- Une phrase de conclusion : Sans index, MariaDB parcourt toute la table pour trouver les emprunts en cours.

### R3 — l'historique récent d'un adhérent

```sql
SELECT id, date_emprunt FROM emprunt
 WHERE adherent_id = 12 AND date_emprunt >= '2025-01-01';
```

| | `type` | `key` | `rows` | `Extra` |
|---|---|---|---|---|
| avant | | | | |
| après | | | | |

- Index créé : `                                                        `
- Lignes réellement renvoyées : `741`
- Pourquoi les colonnes sont-elles dans cet ordre, et pas dans l'autre ?

## Le préfixe gauche (consigne 7)

| Requête | L'index composite sert-il ? | Pourquoi |
|---|---|---|
| `WHERE adherent_id = 12` | Oui, le préfixe gauche est utilisable | Dans cet `EXPLAIN`, MariaDB choisit `fk_emprunt_adherent` (`ref`, environ 5070 lignes), pas l'index composite. |
| `WHERE date_emprunt >= '2025-01-01'` | Non | `date_emprunt` seule ne respecte pas le préfixe gauche du composite ; MariaDB utilise ici l'index séparé `idx_date_emprunt` (`range`, environ 58082 lignes). |

## L'index couvrant (consigne 8)

- Mention présente dans le premier `Extra` : aucune (`Extra` est vide dans le résultat obtenu).
- Dans les deux `EXPLAIN`, MariaDB choisit `fk_emprunt_adherent` et n'indique pas d'index couvrant. Avec l'index composite `(adherent_id, date_emprunt)`, la première requête pourrait être couverte (`Using index`) ; la seconde demande aussi `exemplaire_id`, absent de cet index, donc MariaDB doit lire les lignes de la table pour obtenir cette colonne.

## La requête réécrite (consigne 9)

```sql
-- version d'origine
SELECT COUNT(*) FROM emprunt WHERE YEAR(date_emprunt) = 2024;
-- EXPLAIN fourni : type = index, key = idx_date_emprunt,
-- rows = 199875, Extra = Using where; Using index

-- version réécrite
SELECT COUNT(*) FROM emprunt
 WHERE date_emprunt >= '2024-01-01'
   AND date_emprunt <  '2025-01-01';

-- EXPLAIN de cette requête COUNT(*) : à relever
```

Les deux renvoient bien le même nombre : `43015` (résultat observé pour la version d'origine).
La fonction YEAR() empêche une recherche par intervalle sur l'index. La comparaison directe des dates permet au moteur d'envisager un accès `range`. Le plan fourni pour `SELECT *` choisit toutefois un parcours complet (`type = ALL`, `key = NULL`) ; il ne s'agit pas du plan de la requête `COUNT(*)` réécrite.

## Le prix des index (consigne 10)

| | `donnees_mo` | `index_mo` |
|---|---|---|
| avant | | |
| après | `8.52` | `18.06` |

Pour mesurer les tailles en Mio, exécutez cette requête avant puis après la création des index et recopiez les valeurs :

```sql
SELECT
    ROUND(data_length / 1024 / 1024, 2) AS donnees_mo,
    ROUND(index_length / 1024 / 1024, 2) AS index_mo
FROM information_schema.tables
WHERE table_schema = 'mediatheque'
  AND table_name = 'emprunt';
```

Conclusion : Après la création des index, les index occupent `18.06 Mio` contre `8.52 Mio` pour les données ; il faut la mesure « avant » pour chiffrer précisément le surcoût ajouté.

## Bonus

- Consigne 11 — `DROP INDEX idx_emprunt_adherent_date ON emprunt` renvoie l'erreur `1091` (`Can't DROP INDEX ...; check that it exists`) : cet index n'existe pas sous ce nom dans la table au moment de la commande. Ce n'est pas le refus InnoDB lié à une clé étrangère. Vérifier les noms avec `SHOW INDEX FROM emprunt;`. Quand un index sert de support à une clé étrangère, InnoDB exige qu'un index commence par la colonne référencée et refuse sa suppression tant qu'aucun autre index convenable ne peut le remplacer (généralement erreur `1553`).
- Consigne 12 — `EXPLAIN` sur `v_retard` : tables visitées, index utilisés.
