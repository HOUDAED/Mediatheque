USE mediatheque;

SET @code = (SELECT code_barre FROM exemplaire
              WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
SET @adherent = (SELECT a.id FROM adherent a
                  WHERE a.actif = 1
                    AND f_nb_emprunts_en_cours(a.id) = 0
                    AND f_penalites_dues(a.id) = 0
                  ORDER BY a.id LIMIT 1);
SET @autre_adherent = (SELECT a.id FROM adherent a
                        WHERE a.actif = 1
                          AND f_nb_emprunts_en_cours(a.id) = 0
                          AND f_penalites_dues(a.id) = 0
                          AND a.id <> @adherent
                        ORDER BY a.id LIMIT 1);
SET @inactif = (SELECT id FROM adherent WHERE actif = 0 ORDER BY id LIMIT 1);
SET @mauvais_payeur = (SELECT adherent_id FROM penalite
                        WHERE payee = 0 GROUP BY adherent_id
                       HAVING SUM(montant) > 10 LIMIT 1);
SET @code_retard = (SELECT ex.code_barre
                      FROM emprunt em JOIN exemplaire ex ON ex.id = em.exemplaire_id
                     WHERE em.date_retour_reelle IS NULL
                       AND em.date_retour_prevue < CURDATE()
                     ORDER BY em.date_retour_prevue LIMIT 1);
SELECT @code, @adherent, @autre_adherent, @inactif, @mauvais_payeur, @code_retard;

SELECT 'T1' AS test;
CALL p_emprunter(@code, @adherent, @id);
SELECT @id;
SELECT id, date_emprunt, date_retour_prevue FROM emprunt WHERE id = @id;
SELECT code_barre, disponible FROM exemplaire WHERE code_barre = @code;
SELECT operation, cle, auteur, details FROM journal_action ORDER BY id DESC LIMIT 1;

SELECT 'T2' AS test;
CALL p_emprunter(@code, @autre_adherent, @id);

SELECT 'T3' AS test;
SET @code = (SELECT code_barre FROM exemplaire
              WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code, @inactif, @id);

SELECT 'T4' AS test;
CALL p_emprunter('MED-99999', 1, @id);

SELECT 'T5' AS test;
SET @code = (SELECT code_barre FROM exemplaire WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code, @autre_adherent, @id);
SET @code = (SELECT code_barre FROM exemplaire WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code, @autre_adherent, @id);
SET @code = (SELECT code_barre FROM exemplaire WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code, @autre_adherent, @id);
SET @code = (SELECT code_barre FROM exemplaire WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code, @autre_adherent, @id);
SET @code = (SELECT code_barre FROM exemplaire WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code, @autre_adherent, @id);
SELECT f_nb_emprunts_en_cours(@autre_adherent);
SET @code = (SELECT code_barre FROM exemplaire WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
CALL p_emprunter(@code, @autre_adherent, @id);

SELECT 'T6' AS test;
SELECT actif, f_nb_emprunts_en_cours(id), f_penalites_dues(id) FROM adherent WHERE id = @mauvais_payeur;
CALL p_emprunter(@code, @mauvais_payeur, @id);

SELECT 'T7' AS test;
SET @libre = (SELECT id FROM exemplaire WHERE disponible = 1 AND etat <> 'hors_service' ORDER BY id LIMIT 1);
INSERT INTO emprunt (exemplaire_id, adherent_id, date_emprunt, date_retour_prevue) VALUES (@libre, 2, NULL, NULL);
SELECT id, exemplaire_id, adherent_id, date_emprunt, date_retour_prevue FROM emprunt WHERE id = LAST_INSERT_ID();
SELECT id, code_barre, disponible FROM exemplaire WHERE id = @libre;

SELECT 'T8' AS test;
SELECT em.id, em.date_retour_prevue, DATEDIFF(CURDATE(), em.date_retour_prevue) AS jours_retard
FROM emprunt em JOIN exemplaire ex ON ex.id = em.exemplaire_id
WHERE ex.code_barre = @code_retard AND em.date_retour_reelle IS NULL;
CALL p_rendre(@code_retard);
SELECT em.id, em.date_retour_reelle, ex.disponible
FROM emprunt em JOIN exemplaire ex ON ex.id = em.exemplaire_id
WHERE ex.code_barre = @code_retard ORDER BY em.id DESC LIMIT 1;
SELECT adherent_id, montant, motif FROM penalite ORDER BY id DESC LIMIT 1;
SELECT operation, cle, auteur, details FROM journal_action ORDER BY id DESC LIMIT 1;

SELECT 'T9' AS test;
CALL p_rendre(@code_retard);
