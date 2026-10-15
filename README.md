# TP1 — Sécuriser la base de la médiathèque

**Séance 1 · en binôme · sur machine · non noté**

## Objectif

Construire le plan de comptes de la médiathèque : trois rôles, quatre comptes, et la preuve — connexion à l'appui — que chacun peut exactement ce qu'il doit pouvoir, et rien de plus.

## Le contexte

La médiathèque municipale ouvre son application de gestion des prêts. Quatre acteurs vont travailler sur la même base :

| Qui | Ce qu'il doit pouvoir faire | Ce qu'il ne doit **pas** pouvoir faire |
|---|---|---|
| `app_media` — l'application web | Lire le catalogue, enregistrer et modifier des emprunts, des réservations et des pénalités, marquer un exemplaire comme sorti ou rentré | Supprimer quoi que ce soit, modifier le catalogue, lire les coordonnées des adhérents |
| `biblio_marie` — la bibliothécaire | Tout ce que fait l'application, plus la gestion complète des dossiers d'adhérents | Administrer le serveur, créer des comptes |
| `stagiaire` | Consulter le catalogue et la liste des adhérents | Voir un email, un téléphone ou une date de naissance ; écrire quoi que ce soit ; voir les emprunts |
| `analyste` | Lire les emprunts et le catalogue pour produire des statistiques | Lire la table `adherent`, écrire quoi que ce soit |

Trois de ces besoins se recoupent : c'est ce qui justifie des **rôles** plutôt que des privilèges accordés compte par compte.

## Point de départ

La base `mediatheque`, chargée avec les scripts du dossier `Base/` :

```
mysql -u root -p < Base/01-schema.sql
mysql -u root -p < Base/02-donnees.sql
```

Vérification : `SELECT COUNT(*) FROM mediatheque.adherent;` doit renvoyer 40.

## Ce qui vous est fourni

- `Base/01-schema.sql` — les sept tables de la médiathèque.
- `Base/02-donnees.sql` — le jeu de données : adhérents, ouvrages, emprunts en cours, retards, pénalités.
- `matrice-de-tests.md` — le tableau à remplir, une ligne par test.

Rien d'autre : les rôles, les comptes et les privilèges sont entièrement à écrire.

## Consignes

Tout tient dans **un seul fichier**, `01-roles-et-comptes.sql`, qui doit se rejouer du début à la fin. Commencez-le par les `DROP USER IF EXISTS` et `DROP ROLE IF EXISTS` : sans eux, la deuxième exécution s'arrête sur « compte déjà existant ».

**1. Les trois rôles**

Un rôle décrit un **métier**, pas une personne. Trois suffisent :

| Rôle | Ce qu'il porte |
|---|---|
| `role_catalogue` | `SELECT` sur `ouvrage`, `exemplaire`, `categorie` |
| `role_prets` | `SELECT`, `INSERT`, `UPDATE` sur `emprunt`, `reservation`, `penalite` — et **uniquement** `UPDATE` de la colonne `disponible` sur `exemplaire` |
| `role_adherents` | `SELECT`, `INSERT`, `UPDATE` sur `adherent` |

Aucun `DELETE` nulle part : un emprunt rendu reste dans l'historique, un adhérent parti est désactivé (`actif = 0`), il n'est pas effacé.

Le privilège sur une seule colonne s'écrit avec la liste des colonnes entre parenthèses, juste après le nom du privilège.

**2. Les quatre comptes**

Tous en `@'localhost'`. Des mots de passe qui passent la politique par défaut de MySQL : au moins 8 caractères, une majuscule, un chiffre, un caractère spécial.

Affectez ensuite les rôles, en suivant le tableau du contexte. Deux besoins ne sont couverts par aucun rôle et demandent un privilège accordé directement au compte :

- `app_media` doit lire `id`, `nom`, `prenom` et `actif` des adhérents — **et rien d'autre** de cette table ;
- `stagiaire` doit lire les adhérents **sans** `email`, `telephone` ni `date_naissance`.

Dans les deux cas, c'est un privilège de niveau colonne.

Enfin : un rôle accordé n'est pas un rôle actif. Ajoutez la ligne qui rend les rôles actifs **à chaque connexion** des comptes concernés — pas seulement pour la session en cours.

**Avec MariaDB**, un seul rôle peut être défini par défaut et la syntaxe est `SET DEFAULT ROLE role FOR 'compte'@'localhost'`. Le script active donc le rôle principal de chaque compte avec cette syntaxe et accorde directement à `app_media` et `biblio_marie` les droits complémentaires nécessaires à leurs autres missions. MySQL 8 utilise une syntaxe différente pour `SET DEFAULT ROLE`.

**3. Relire les droits, puis en retirer un**

Deux requêtes dont la sortie doit figurer dans votre rendu : `SHOW GRANTS` pour chacun des quatre comptes, puis les privilèges de niveau colonne de la base, lus dans `information_schema.column_privileges`.

Ensuite, le cycle complet sur un cas : la médiathèque décide que l'analyste n'a finalement pas besoin des réservations. Accordez-lui `SELECT` sur `reservation`, vérifiez avec `SHOW GRANTS`, retirez le privilège, vérifiez à nouveau. Les quatre commandes restent dans le script.

**4. Tester pour de vrai**

Ouvrez une connexion par compte et remplissez `matrice-de-tests.md` — douze tests. Chaque ligne attend un **OK** ou un **numéro d'erreur**, pas « ça marche ».

```
mysql -u stagiaire -p mediatheque
```

Quelques exemples de ce que vous allez y écrire :

```sql
-- en tant que stagiaire
SELECT email FROM adherent;                         -- attendu : ERROR 1143

-- en tant qu'app_media
UPDATE exemplaire SET disponible = 0 WHERE id = 1;  -- attendu : OK
UPDATE exemplaire SET etat = 'use'  WHERE id = 1;   -- attendu : ERROR 1143
```

**5. Bonus — si vous avez fini**

- L'analyste travaille depuis un poste du réseau, pas depuis le serveur. Créez `'analyste'@'192.168.1.%'` avec les mêmes privilèges, et expliquez en commentaire ce qui se passerait si `'analyste'@'%'` existait aussi.
- Le stage se termine. Écrivez les deux commandes possibles — verrouiller le compte, ou le supprimer — et indiquez en commentaire celle que vous choisiriez, et pourquoi.

## Points de vigilance

- **Un compte, c'est `'nom'@'machine'`.** `DROP USER 'stagiaire'` ne supprime pas `'stagiaire'@'localhost'` : ce sont deux comptes différents.
- **Un rôle accordé n'est pas actif.** Si un compte se connecte et ne voit rien alors que le `GRANT` est passé, c'est presque toujours ça. Vérifiez avec `SELECT CURRENT_ROLE();` dans sa session.
- **`SELECT *` cesse de fonctionner** dès qu'un compte n'a qu'un privilège de colonne. C'est normal, et c'est même le but : l'étoile inclurait les colonnes interdites.
- **`REVOKE` doit viser le même niveau que le `GRANT`.** Un privilège accordé sur `mediatheque.*` ne se retire pas table par table.
- **Pas de `FLUSH PRIVILEGES`.** C'est un réflexe hérité des anciennes versions : `GRANT` et `REVOKE` sont pris en compte immédiatement.
- **Ne travaillez jamais en root dans les tests.** Ouvrez une vraie connexion avec le compte testé, sinon vous testez les droits de root.

## Critères de réussite

- [ ] Les trois rôles existent et portent les privilèges du tableau
- [ ] Les quatre comptes existent, avec des mots de passe conformes
- [ ] Aucun `GRANT ALL`, aucun privilège au niveau `*.*`, aucun `DELETE` accordé
- [ ] Le privilège de colonne sur `exemplaire (disponible)` est en place, et le stagiaire ne peut lire ni `email`, ni `telephone`, ni `date_naissance`
- [ ] Les rôles sont actifs à la connexion, sans `SET ROLE` manuel
- [ ] Le cycle `GRANT` → vérification → `REVOKE` → vérification figure dans le script
- [ ] `matrice-de-tests.md` est remplie, avec les numéros d'erreur obtenus
- [ ] Le script se rejoue du début à la fin sans erreur, deux fois de suite

# TP2 — Vues de sécurité et chasse aux requêtes lentes

**Séance 2 · en binôme · sur machine · non noté**

## Objectif

Donner à la médiathèque les vues dont elle a besoin au quotidien, basculer les droits du stagiaire sur ces vues plutôt que sur les tables, puis rendre trois requêtes rapides — en prouvant le gain par un `EXPLAIN` avant et après.

## Point de départ

La base `mediatheque` et les comptes du TP1. Si vous repartez de zéro :

```
mysql -u root -p < Base/01-schema.sql
mysql -u root -p < Base/02-donnees.sql
mysql -u root -p < TP1 Corrige/01-roles-et-comptes.sql     # publié après la séance 1
```

Puis, **pour la partie B uniquement**, la mise en volume :

```
mysql -u root -p < Base/03-volume.sql
```

Ce dernier script ajoute 200 000 emprunts d'archive. Comptez une à deux minutes. Sans lui, toutes vos requêtes répondront en 0 ms et aucun index ne servira à rien : c'est la partie B entière qui perd son sens.

## Ce qui vous est fourni

- `Base/03-volume.sql` — la mise en volume de la table `emprunt`.
- `rapport-index.md` — le tableau avant / après à remplir.

Les vues et les index sont entièrement à écrire.

---

# Partie A — Les vues

**1. `01-vues.sql` — les quatre vues du quotidien**

| Vue | Ce qu'elle expose |
|---|---|
| `v_catalogue` | Un ouvrage par ligne : titre, auteur, année, libellé de la catégorie, nombre d'exemplaires et nombre d'exemplaires disponibles |
``
| `v_adherent_public` | Les adhérents **sans** `email`, `telephone` ni `date_naissance` |
| `v_emprunt_en_cours` | Les emprunts non rendus : identifiant, dates, jours de retard, nom complet de l'adhérent, titre de l'ouvrage, code-barres |
| `v_retard` | Les seuls emprunts en cours dont la date de retour prévue est dépassée — **construite sur `v_emprunt_en_cours`**, pas en recopiant ses jointures |

Pour `v_catalogue`, `nb_disponibles` se calcule sans sous-requête : `SUM(e.disponible = 1)` compte les lignes où la condition est vraie. Un ouvrage dont aucun exemplaire n'a été saisi doit quand même apparaître, avec 0 — pensez au type de jointure.

Pour `v_emprunt_en_cours`, les jours de retard se calculent avec `DATEDIFF(CURDATE(), date_retour_prevue)` : la valeur est négative quand l'emprunt est encore dans les temps, et c'est bien ce qu'on veut.

**2. Basculer les droits du stagiaire**

Au TP1, le stagiaire avait un privilège de colonne sur `adherent`. Retirez-le, et donnez-lui à la place l'accès aux vues `v_adherent_public`, `v_catalogue` et `v_emprunt_en_cours`.

Vérifiez ensuite, connecté en `stagiaire` :

```sql
SELECT * FROM v_adherent_public;   -- doit fonctionner, et l'étoile fonctionne à nouveau
SELECT * FROM adherent;            -- doit être refusé
```

Le stagiaire n'a **aucun** privilège sur `adherent`, `emprunt` ou `exemplaire`, et lit pourtant trois vues qui les interrogent. Expliquez en commentaire, en une phrase, pourquoi cela fonctionne.

**3. `02-vue-modifiable.sql` — une vue par laquelle on écrit**

Créez `v_adherent_lyon` : les adhérents dont la ville est `'Lyon'`, avec `WITH CHECK OPTION`.

Puis, dans le même script, les trois essais suivants — les deux derniers doivent échouer, et l'erreur fait partie du résultat attendu :

1. insérer un adhérent lyonnais par la vue : doit fonctionner, et la ligne doit apparaître dans `adherent` ;
2. insérer un adhérent de Bron par la vue : doit échouer ;
3. faire un `UPDATE` sur `v_catalogue` : doit échouer.

Relevez les deux numéros d'erreur et expliquez, pour chacun, ce que le serveur refuse exactement.

**4. Quelles vues sont modifiables ?**

Interrogez `information_schema.views` et relevez la colonne `is_updatable` pour vos cinq vues. Justifiez en commentaire, pour chaque `NO`, ce qui empêche la modification.

---

# Partie B — Les index

Tous les `EXPLAIN` de cette partie se font sur la table `emprunt` **après** la mise en volume.

**5. `03-index.sql` — mesurer avant**

Lancez `EXPLAIN` sur les trois requêtes suivantes et notez, dans `rapport-index.md`, les colonnes `type`, `key`, `rows` et `Extra` :

```sql
-- R1 : les emprunts d'une journée
SELECT * FROM emprunt WHERE date_emprunt = '2024-03-12';

-- R2 : les emprunts en cours (c'est la requête derrière v_emprunt_en_cours)
SELECT * FROM emprunt WHERE date_retour_reelle IS NULL;

-- R3 : l'historique récent d'un adhérent
SELECT id, date_emprunt FROM emprunt
 WHERE adherent_id = 12 AND date_emprunt >= '2025-01-01';
```

Comptez aussi, pour chacune, le nombre de lignes réellement renvoyées. C'est l'écart entre ce nombre et `rows` qui dit si un index a une chance de servir.

**6. Poser les index — un par requête, et justifié**

Créez l'index qui répond à R1, celui qui répond à R2, et l'index **composite** qui répond à R3. Pour ce dernier, l'ordre des colonnes n'est pas libre : justifiez-le en commentaire.

Après chaque création : `ANALYZE TABLE emprunt;`, puis relancez l'`EXPLAIN` et remplissez la colonne « après » du rapport.

**7. Le préfixe gauche**

Avec l'index composite en place, lancez :

```sql
EXPLAIN SELECT id FROM emprunt WHERE adherent_id = 12;
EXPLAIN SELECT id FROM emprunt WHERE date_emprunt >= '2025-01-01';
```

L'une des deux profite de l'index composite, l'autre non. Dites laquelle, et pourquoi.

**8. L'index couvrant**

Comparez ces deux requêtes :

```sql
EXPLAIN SELECT adherent_id, date_emprunt FROM emprunt WHERE adherent_id = 12;
EXPLAIN SELECT adherent_id, date_emprunt, exemplaire_id FROM emprunt WHERE adherent_id = 12;
```

Une mention disparaît de la colonne `Extra`. Laquelle, et qu'est-ce que le serveur doit faire en plus dans le second cas ?

**9. La requête qu'il faut réécrire**

```sql
SELECT COUNT(*) FROM emprunt WHERE YEAR(date_emprunt) = 2024;
```

Elle n'utilise pas correctement l'index sur `date_emprunt`. Réécrivez-la pour qu'elle donne **exactement le même résultat** en utilisant l'index, et montrez les deux `EXPLAIN`.

**10. Le prix payé**

Relevez le poids des données et celui des index de `emprunt` dans `information_schema.tables`, avant et après vos créations. Concluez en une phrase.

**11. Bonus — l'index qui résiste**

Essayez de supprimer l'index composite créé en 6. Que se passe-t-il ? Pourquoi ? Quelle propriété d'InnoDB explique ce refus ?

**12. Bonus — la vue lente**

`v_retard` est construite sur `v_emprunt_en_cours`. Lancez `EXPLAIN SELECT * FROM v_retard;` : quelles tables apparaissent ? Vos index de la partie B servent-ils ?

## Points de vigilance

- **Sans `ANALYZE TABLE`, l'optimiseur se trompe.** Après une grosse insertion ou un nouvel index, les statistiques sont périmées et le plan choisi peut être aberrant.
- **`rows` est une estimation**, pas un décompte. Elle suffit pour comparer un avant et un après, mais elle varie légèrement d'une exécution à l'autre.
- **Vos chiffres doivent être ceux du corrigé.** L'archive est générée avec un tirage aléatoire *initialisé* : tout le monde obtient la même base. Un `rows` qui s'écarte de quelques unités est normal (c'est une estimation) ; un ordre de grandeur différent veut dire que la mise en volume n'a pas été chargée.
- **Une clé étrangère est déjà indexée.** Inutile de créer un index sur `exemplaire_id` seul : regardez `information_schema.statistics` avant de poser quoi que ce soit.
- **Une vue ne s'indexe pas.** On indexe les colonnes des tables qu'elle interroge.
- **`CREATE OR REPLACE VIEW`** rend le script rejouable ; `CREATE INDEX` ne l'est pas. Prévoyez un `DROP INDEX … ON …` en tête de script, ou acceptez l'erreur « index déjà existant » à la deuxième exécution et dites-le en commentaire.
- **`SELECT *` dans une vue** est une mauvaise idée : le jour où une colonne est ajoutée à la table, elle apparaît dans la vue, y compris si elle est confidentielle.

## Critères de réussite

- [ ] Les cinq vues existent et renvoient des données cohérentes
- [ ] `v_retard` est construite sur `v_emprunt_en_cours`, sans recopier ses jointures
- [ ] Un ouvrage sans exemplaire apparaît dans `v_catalogue` avec 0
- [ ] Le stagiaire lit les trois vues et n'a plus aucun privilège sur `adherent`
- [ ] `WITH CHECK OPTION` refuse bien l'insertion hors périmètre, avec le numéro d'erreur relevé
- [ ] `is_updatable` est relevé pour les cinq vues, et chaque `NO` est justifié
- [ ] `rapport-index.md` est rempli : `type`, `key`, `rows`, `Extra`, avant et après
- [ ] Chaque index créé est justifié par une requête précise, en commentaire
- [ ] L'ordre des colonnes de l'index composite est expliqué
- [ ] La requête avec `YEAR()` est réécrite, et les deux `EXPLAIN` figurent au rendu
- [ ] Les scripts se rejouent du début à la fin


# TP3 — Faire vivre la médiathèque : emprunter et rendre

**Séance 3 · en binôme · sur machine · non noté**

## Objectif

Écrire les fonctions, les procédures et les triggers qui font fonctionner le prêt de la médiathèque, puis démontrer par un scénario de test que chaque règle métier est bien appliquée — y compris quand on essaie de la contourner.

## Le contexte

Jusqu'ici, emprunter un document se résume à un `INSERT` dans `emprunt`. Rien ne vérifie que l'adhérent existe, qu'il n'a pas déjà cinq documents chez lui, ni que l'exemplaire est disponible. Et rien ne met à jour `exemplaire.disponible`, qui est donc déjà faux dans la base dès qu'on écrit à la main.

Les règles de la médiathèque :

| Règle | Où elle doit vivre |
|---|---|
| L'adhérent existe et son inscription est active | procédure |
| L'exemplaire existe, est disponible et n'est pas hors service | procédure |
| Cinq documents maximum par adhérent | procédure |
| Pas plus de 10 € de pénalités impayées | procédure |
| Le prêt dure 14 jours | trigger (valeur calculée) |
| Un exemplaire sorti n'est pas disponible | trigger (invariant) |
| Retard facturé 0,20 € par jour | procédure (c'est un tarif, donc une décision) |
| Toute écriture sur `emprunt` est journalisée | trigger (traçabilité) |

La ligne de partage est le fil conducteur de la séance : **un invariant de données va dans un trigger, une opération métier va dans une procédure.**

## Point de départ

La base `mediatheque` avec les vues et les index du TP2. Si vous repartez de zéro :

```
mysql -u root -p < Base/01-schema.sql
mysql -u root -p < Base/02-donnees.sql
```

La mise en volume n'est pas nécessaire pour ce TP — et vous fera gagner du temps si vous l'omettez.

## Ce qui vous est fourni

- `scenario-de-test.md` — la trame du fichier de tests à produire.

Les fonctions, les procédures et les triggers sont entièrement à écrire.

## Consignes

**1. `01-fonctions.sql` — trois fonctions**

| Fonction | Renvoie |
|---|---|
| `f_nb_emprunts_en_cours(p_adherent_id)` | le nombre de documents non rendus |
| `f_penalites_dues(p_adherent_id)` | le total des pénalités non payées, **0.00 s'il n'y en a aucune** |
| `f_jours_de_retard(p_emprunt_id)` | le nombre de jours de retard, 0 si l'emprunt est dans les temps |

Trois points de syntaxe :

- une fonction déclare ce qu'elle fait au serveur : ces trois-là lisent des données, donc `READS SQL DATA` ;
- `SUM()` sur zéro ligne renvoie `NULL`, pas `0` — et `NULL > 10` n'est ni vrai ni faux : `f_penalites_dues` doit renvoyer un vrai zéro ;
- `f_jours_de_retard` doit fonctionner pour un emprunt rendu (comparaison avec `date_retour_reelle`) comme pour un emprunt en cours (comparaison avec `CURDATE()`).

Terminez par une requête qui liste les adhérents ayant au moins un emprunt en cours, avec leurs pénalités, en utilisant vos trois fonctions.

**2. `02-procedures.sql` — `p_emprunter`**

```sql
CALL p_emprunter(p_code_barre, p_adherent_id, @emprunt_id);
```

Les quatre règles de la procédure, dans l'ordre du tableau. Chaque refus lève une erreur avec `SIGNAL SQLSTATE '45000'` et un message que l'utilisateur de l'application pourra lire tel quel — pas « erreur 3 ».

La procédure doit aussi :

- être encadrée par `START TRANSACTION` / `COMMIT` ;
- installer un `EXIT HANDLER FOR SQLEXCEPTION` qui fait `ROLLBACK` puis `RESIGNAL` ;
- renvoyer l'identifiant du nouvel emprunt dans son paramètre `OUT` ;
- **ne pas** toucher à `exemplaire.disponible` : c'est le travail du trigger de la consigne 4.

Attention au cas « code-barres inconnu » : un `SELECT … INTO` qui ne trouve rien laisse la variable inchangée. Déclarez-la avec `DEFAULT NULL` et testez `IS NULL`.

**3. `02-procedures.sql` — `p_rendre` et `p_bilan_adherent`**

`p_rendre(p_code_barre)` : retrouve l'emprunt en cours de cet exemplaire, l'ancre à la date du jour, et crée une pénalité de 0,20 € par jour de retard s'il y a lieu. Si aucun emprunt n'est en cours pour ce code-barres, elle refuse avec un message explicite. Elle se termine par un `SELECT` qui renvoie l'identifiant de l'emprunt, les jours de retard et le montant facturé.

`p_bilan_adherent(p_adherent_id)` : renvoie **trois** jeux de résultats — la fiche de l'adhérent (avec vos fonctions), la liste de ses emprunts en cours, et son nombre total d'emprunts depuis l'inscription. C'est la démonstration de ce qu'une fonction ne sait pas faire.

**4. `03-triggers.sql` — trois triggers**

Créez d'abord la table d'audit :

```sql
CREATE TABLE IF NOT EXISTS journal_action (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  table_cible VARCHAR(40)     NOT NULL,
  operation   VARCHAR(10)     NOT NULL,
  cle         VARCHAR(40)     NOT NULL,
  auteur      VARCHAR(100)    NOT NULL,
  horodatage  DATETIME        NOT NULL,
  details     VARCHAR(255)        NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;
```

Puis :

| Trigger | Ce qu'il fait |
|---|---|
| `BEFORE INSERT ON emprunt` | remplit `date_emprunt` et `date_retour_prevue` si elles sont absentes (14 jours), et refuse une date de retour antérieure à la date d'emprunt |
| `AFTER INSERT ON emprunt` | passe l'exemplaire à indisponible et journalise |
| `AFTER UPDATE ON emprunt` | détecte le **passage** de `date_retour_reelle` de `NULL` à une date : rend l'exemplaire disponible et journalise |

Pour le troisième : comparez `OLD` et `NEW`. Sans cette comparaison, n'importe quelle modification de la ligne d'emprunt rendrait l'exemplaire disponible — même un simple changement de date.

**5. `04-tests.sql` — le scénario**

Reprenez `scenario-de-test.md` et écrivez le script correspondant. Les cas qui doivent échouer restent en commentaire dans le fichier livré, avec le message d'erreur obtenu juste en dessous — pour que le script se rejoue d'un bout à l'autre.

Le test T7 est le plus intéressant : un `INSERT` direct dans `emprunt`, sans passer par la procédure, doit quand même produire une date de retour à 14 jours et un exemplaire indisponible. C'est la démonstration de ce que le trigger apporte et que la procédure, seule, n'apporterait pas.

**6. Bonus — EXECUTE plutôt qu'INSERT**

Retirez à `app_media` les privilèges `INSERT` et `UPDATE` sur `emprunt`, et donnez-lui `EXECUTE` sur vos deux procédures. Vérifiez, connecté avec ce compte, que `CALL p_emprunter(...)` fonctionne et qu'un `INSERT` direct est refusé. Expliquez en commentaire pourquoi c'est possible.

**7. Bonus — le trigger qui coûte cher**

Chronométrez `Base/03-volume.sql` (200 000 insertions) avec vos triggers en place, puis après les avoir supprimés. Concluez.

## Points de vigilance

- **`DELIMITER` n'est pas du SQL.** C'est une instruction au client. Sans lui, le premier `;` interne coupe votre procédure en deux et vous obtenez une erreur de syntaxe incompréhensible.
- **Toutes les `DECLARE` en tête de bloc**, avant la première instruction, sinon erreur 1064.
- **Préfixez vos paramètres** (`p_`) et vos variables (`v_`). Un paramètre qui porte le même nom qu'une colonne fait silencieusement gagner la colonne : `WHERE adherent_id = adherent_id` est toujours vrai.
- **Un trigger ne peut pas écrire dans la table qui l'a déclenché.** Pour modifier la ligne en cours d'insertion, c'est `SET NEW.colonne` en `BEFORE`, jamais un `UPDATE`.
- **Un trigger ne peut pas modifier une table que l'instruction en cours est en train de lire.** `INSERT INTO emprunt (…) SELECT … FROM exemplaire …` échoue en erreur 1442, parce que le trigger veut écrire dans `exemplaire`. Le même `INSERT … VALUES (…)` passe sans problème.
- **Un trigger ne fait ni `COMMIT` ni `ROLLBACK`** : il fait partie de la transaction de l'ordre qui l'a déclenché. Un `SIGNAL` dans un trigger annule l'écriture d'origine.
- **Ne dupliquez pas une règle** entre la procédure et le trigger. Si le quota est vérifié aux deux endroits, vous aurez un jour deux réponses différentes.
- **`SIGNAL` sans `MESSAGE_TEXT`** produit un message vide : l'application ne saura pas quoi afficher.
- **Testez avec une connexion autre que root** pour le bonus 6 : sinon vous testez les droits de root.

## Critères de réussite

- [ ] Les trois fonctions existent, déclarent `READS SQL DATA`, et `f_penalites_dues` renvoie `0.00` et non `NULL`
- [ ] `p_emprunter` applique les quatre règles, dans un ordre justifié
- [ ] Chaque refus lève `SQLSTATE '45000'` avec un message lisible par un utilisateur
- [ ] `p_emprunter` gère sa transaction et son handler d'erreur
- [ ] `p_emprunter` renvoie l'identifiant créé dans un paramètre `OUT`
- [ ] `p_rendre` crée la pénalité au bon montant, et seulement en cas de retard
- [ ] `p_bilan_adherent` renvoie bien trois jeux de résultats
- [ ] Les trois triggers existent, avec le bon moment et le bon événement
- [ ] Le trigger `AFTER UPDATE` compare `OLD` et `NEW` et ne se déclenche que sur un vrai retour
- [ ] `exemplaire.disponible` est maintenu par le trigger, pas par la procédure
- [ ] Un `INSERT` direct dans `emprunt` produit malgré tout une date de retour et un exemplaire indisponible
- [ ] Le scénario de test couvre les neuf cas, avec les messages d'erreur obtenus
- [ ] Les scripts se rejouent du début à la fin
