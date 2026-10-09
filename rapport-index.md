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
| avant | | | | |
| après | | | | |

- Index créé : `                                                        `
- Lignes réellement renvoyées : `        `
- Une phrase de conclusion :

### R2 — les emprunts en cours

```sql
SELECT * FROM emprunt WHERE date_retour_reelle IS NULL;
```

| | `type` | `key` | `rows` | `Extra` |
|---|---|---|---|---|
| avant | | | | |
| après | | | | |

- Index créé : `                                                        `
- Lignes réellement renvoyées : `        `
- Une phrase de conclusion :

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
- Pourquoi les colonnes sont-elles dans cet ordre, et pas dans l'autre ?

## Le préfixe gauche (consigne 7)

| Requête | L'index composite sert-il ? | Pourquoi |
|---|---|---|
| `WHERE adherent_id = 12` | | |
| `WHERE date_emprunt >= '2025-01-01'` | | |

## L'index couvrant (consigne 8)

- Mention présente dans le premier `Extra` : `                    `
- Elle disparaît dans le second parce que :

## La requête réécrite (consigne 9)

```sql
-- version d'origine
SELECT COUNT(*) FROM emprunt WHERE YEAR(date_emprunt) = 2024;
-- type : ______   rows : ______

-- version réécrite


-- type : ______   rows : ______
```

Les deux renvoient bien le même nombre : `          `

## Le prix des index (consigne 10)

| | `donnees_mo` | `index_mo` |
|---|---|---|
| avant | | |
| après | | |

Conclusion :

## Bonus

- Consigne 11 — l'index qu'on ne peut pas supprimer : numéro d'erreur et explication.
- Consigne 12 — `EXPLAIN` sur `v_retard` : tables visitées, index utilisés.
