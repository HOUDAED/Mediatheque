# TP3 — Scénario de test

Serveur : MySQL 8.0. Base chargée avec `Base/01-schema.sql` et `Base/02-donnees.sql`, puis
`03-procedures-et-triggers.sql` (rejoué deux fois sans erreur). Les tests sont dans `03-tests.sql`,
lancé avec `mysql --force` pour que les cas qui doivent échouer n'arrêtent pas le script.

Valeurs choisies par la base : `@code` = `MED-00001`, `@adherent` = 9, autre adhérent = 14,
adhérent inactif = 7, `@mauvais_payeur` = 5 (12,00 € dus), `@code_retard` = `MED-00107`.

| # | Ce que je fais | Attendu | Obtenu |
|---|---|---|---|
| T1 | `CALL p_emprunter('MED-00001', 9, @id);` | un emprunt créé, `@id` renseigné, exemplaire indisponible, une ligne dans `journal_action` | OK : `@id` = 131, emprunt du jour avec retour prévu à +14 jours, `MED-00001` passe à `disponible = 0`, une ligne `EMPRUNT` dans `journal_action` |
| T2 | `CALL p_emprunter('MED-00001', 14, @id);` — **doit échouer** | exemplaire déjà emprunté | `ERROR 1644 (45000): Exemplaire déjà emprunté` |
| T3 | `CALL p_emprunter(<code disponible>, 7, @id);` — **doit échouer** | inscription inactive | `ERROR 1644 (45000): Inscription inactive` |
| T4 | `CALL p_emprunter('MED-99999', 1, @id);` — **doit échouer** | code-barres inconnu | `ERROR 1644 (45000): Code-barres inconnu` |
| T5 | Cinq emprunts pour l'adhérent 14, puis un sixième — **doit échouer** | quota de 5 atteint | les 5 premiers passent (`f_nb_emprunts_en_cours(14)` = 5), le 6e : `ERROR 1644 (45000): Quota de 5 emprunts atteint` |
| T6 | `CALL p_emprunter(<code disponible>, 5, @id);` — **doit échouer** | pénalités impayées | `ERROR 1644 (45000): Pénalités impayées supérieures à 10 €` (adhérent actif, 0 emprunt, 12,00 € dus) |
| T7 | `INSERT INTO emprunt (exemplaire_id, adherent_id, date_emprunt, date_retour_prevue) VALUES (12, 2, NULL, NULL);` | la ligne existe, `date_emprunt` = aujourd'hui, retour prévu à +14 jours, exemplaire indisponible | OK : emprunt 137, `date_emprunt` = 2026-10-15, `date_retour_prevue` = 2026-10-29, `MED-00012` passe à `disponible = 0` |
| T8 | `CALL p_rendre('MED-00107');` | emprunt clos, exemplaire disponible, pénalité créée au bon montant | OK : emprunt 130 clos le 2026-10-15, `MED-00107` repasse à `disponible = 1`, pénalité de 14,40 € pour l'adhérent 30 (72 jours × 0,20 €) |
| T9 | `CALL p_rendre('MED-00107');` — **doit échouer** | aucun emprunt en cours | `ERROR 1644 (45000): Aucun emprunt en cours pour ce code-barres` |

Contrôle après les tests : 137 emprunts (130 au départ + T1 + 5 pour T5 + T7), 7 lignes dans
`journal_action` (6 `EMPRUNT`, 1 `RETOUR`). Les appels refusés n'ont rien écrit : chaque procédure
fait un `ROLLBACK` avant de renvoyer l'erreur.

## Conclusion

**1.** Le test T7 passe par un `INSERT` direct, sans procédure. Qu'est-ce qui, malgré tout, reste garanti — et qu'est-ce qui ne l'est plus ?

> Les triggers s'exécutent quel que soit le chemin, donc les dates par défaut (aujourd'hui, retour à +14 jours) et le passage de l'exemplaire en indisponible restent garantis ; en revanche les contrôles métier (exemplaire déjà sorti, inscription active, quota de 5, pénalités) et la ligne dans `journal_action` ne sont faits que par `p_emprunter`, donc ils sautent : T7 a accordé un emprunt sans aucune vérification ni trace.

**2.** Une règle du tableau du sujet pourrait changer de camp (passer de la procédure au trigger, ou l'inverse). Laquelle, et qu'est-ce que cela changerait ?

> Le contrôle « exemplaire déjà emprunté » pourrait passer dans le trigger `BEFORE INSERT` sur `emprunt` : aucun chemin, même un `INSERT` direct comme T7, ne pourrait alors prêter deux fois le même exemplaire, mais l'erreur viendrait du trigger au lieu de la procédure, et la règle serait plus difficile à contourner pour un cas exceptionnel.
