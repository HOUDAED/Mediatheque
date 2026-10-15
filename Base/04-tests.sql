USE mediatheque;

-- Les erreurs attendues restent commentées pour que le script se rejoue
-- intégralement. Lancer chaque CALL commenté séparément pour constater le refus.
SET @tp3_token = LEFT(REPLACE(UUID(), '-', ''), 12);

INSERT INTO adherent (
  nom, prenom, email, ville, date_inscription, actif
)
VALUES (
  'TP3', 'Emprunteur', CONCAT('tp3-', @tp3_token, '-a@example.invalid'),
  'Test', CURDATE(), 1
);
SET @tp3_adherent_1 = LAST_INSERT_ID();

INSERT INTO adherent (
  nom, prenom, email, ville, date_inscription, actif
)
VALUES (
  'TP3', 'Second', CONCAT('tp3-', @tp3_token, '-b@example.invalid'),
  'Test', CURDATE(), 1
);
SET @tp3_adherent_2 = LAST_INSERT_ID();

INSERT INTO adherent (
  nom, prenom, email, ville, date_inscription, actif
)
VALUES (
  'TP3', 'Inactif', CONCAT('tp3-', @tp3_token, '-c@example.invalid'),
  'Test', CURDATE(), 0
);
SET @tp3_adherent_inactif = LAST_INSERT_ID();

INSERT INTO adherent (
  nom, prenom, email, ville, date_inscription, actif
)
VALUES (
  'TP3', 'Debiteur', CONCAT('tp3-', @tp3_token, '-d@example.invalid'),
  'Test', CURDATE(), 1
);
SET @tp3_adherent_debiteur = LAST_INSERT_ID();

INSERT INTO adherent (
  nom, prenom, email, ville, date_inscription, actif
)
VALUES (
  'TP3', 'Quota', CONCAT('tp3-', @tp3_token, '-e@example.invalid'),
  'Test', CURDATE(), 1
);
SET @tp3_adherent_quota = LAST_INSERT_ID();

SET @tp3_code_1 = CONCAT('T3-', @tp3_token, '-01');
SET @tp3_code_2 = CONCAT('T3-', @tp3_token, '-02');
SET @tp3_code_3 = CONCAT('T3-', @tp3_token, '-03');
SET @tp3_code_4 = CONCAT('T3-', @tp3_token, '-04');
SET @tp3_code_5 = CONCAT('T3-', @tp3_token, '-05');
SET @tp3_code_6 = CONCAT('T3-', @tp3_token, '-06');
SET @tp3_code_7 = CONCAT('T3-', @tp3_token, '-07');
SET @tp3_code_8 = CONCAT('T3-', @tp3_token, '-08');
SET @tp3_code_9 = CONCAT('T3-', @tp3_token, '-09');
SET @tp3_code_10 = CONCAT('T3-', @tp3_token, '-10');
SET @tp3_code_11 = CONCAT('T3-', @tp3_token, '-11');

INSERT INTO exemplaire (
  ouvrage_id, code_barre, etat, disponible, date_acquisition
)
VALUES
  (1, @tp3_code_1,  'bon', 1, CURDATE()),
  (1, @tp3_code_2,  'bon', 1, CURDATE()),
  (1, @tp3_code_3,  'bon', 1, CURDATE()),
  (1, @tp3_code_4,  'bon', 1, CURDATE()),
  (1, @tp3_code_5,  'bon', 1, CURDATE()),
  (1, @tp3_code_6,  'bon', 1, CURDATE()),
  (1, @tp3_code_7,  'bon', 1, CURDATE()),
  (1, @tp3_code_8,  'bon', 1, CURDATE()),
  (1, @tp3_code_9,  'bon', 1, CURDATE()),
  (1, @tp3_code_10, 'bon', 1, CURDATE()),
  (1, @tp3_code_11, 'bon', 1, CURDATE());

SET @tp3_exemplaire_1 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_1);
SET @tp3_exemplaire_2 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_2);
SET @tp3_exemplaire_3 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_3);
SET @tp3_exemplaire_4 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_4);
SET @tp3_exemplaire_5 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_5);
SET @tp3_exemplaire_6 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_6);
SET @tp3_exemplaire_7 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_7);
SET @tp3_exemplaire_8 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_8);
SET @tp3_exemplaire_9 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_9);
SET @tp3_exemplaire_10 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_10);
SET @tp3_exemplaire_11 = (SELECT id FROM exemplaire WHERE code_barre = @tp3_code_11);

-- T1 — Le prêt réussit, met l'exemplaire à 0 et crée une trace d'audit.
CALL p_emprunter(@tp3_code_1, @tp3_adherent_1, @tp3_emprunt_1);
SELECT @tp3_emprunt_1 AS emprunt_cree;
SELECT code_barre, disponible
  FROM exemplaire
 WHERE id = @tp3_exemplaire_1;
SELECT operation, cle, auteur, details
  FROM journal_action
 WHERE cle = CAST(@tp3_emprunt_1 AS CHAR)
 ORDER BY id DESC
 LIMIT 1;
CALL p_bilan_adherent(@tp3_adherent_1);

-- T2 — À exécuter séparément : l'exemplaire du T1 est déjà emprunté.
-- CALL p_emprunter(@tp3_code_1, @tp3_adherent_2, @tp3_emprunt_refuse);
-- Obtenu attendu : ERROR 1644 (45000): Cet exemplaire n'est pas disponible.

-- T3 — À exécuter séparément : l'inscription est inactive.
-- CALL p_emprunter(@tp3_code_2, @tp3_adherent_inactif, @tp3_emprunt_refuse);
-- Obtenu attendu : ERROR 1644 (45000): L'inscription de cet adhérent est inactive.

-- T4 — À exécuter séparément : code-barres inconnu.
-- CALL p_emprunter('MED-99999', @tp3_adherent_2, @tp3_emprunt_refuse);
-- Obtenu attendu : ERROR 1644 (45000): Ce code-barres ne correspond à aucun exemplaire.

-- T5 — Cinq prêts sont autorisés pour ce compte de test.
CALL p_emprunter(@tp3_code_3, @tp3_adherent_quota, @tp3_emprunt_5_1);
CALL p_emprunter(@tp3_code_4, @tp3_adherent_quota, @tp3_emprunt_5_2);
CALL p_emprunter(@tp3_code_5, @tp3_adherent_quota, @tp3_emprunt_5_3);
CALL p_emprunter(@tp3_code_6, @tp3_adherent_quota, @tp3_emprunt_5_4);
CALL p_emprunter(@tp3_code_7, @tp3_adherent_quota, @tp3_emprunt_5_5);
SELECT @tp3_emprunt_5_1 AS pret_1,
       @tp3_emprunt_5_2 AS pret_2,
       @tp3_emprunt_5_3 AS pret_3,
       @tp3_emprunt_5_4 AS pret_4,
       @tp3_emprunt_5_5 AS pret_5;
-- À exécuter séparément : le sixième prêt doit être refusé.
-- CALL p_emprunter(@tp3_code_8, @tp3_adherent_quota, @tp3_emprunt_refuse);
-- Obtenu attendu : ERROR 1644 (45000): Cet adhérent a déjà atteint la limite de cinq emprunts en cours.

-- T6 — Le total impayé dépasse 10 euros : le prêt doit être refusé.
INSERT INTO penalite (
  adherent_id, emprunt_id, montant, motif, date_creation, payee
)
VALUES (
  @tp3_adherent_debiteur, NULL, 10.01, 'Test TP3', CURDATE(), 0
);
-- À exécuter séparément :
-- CALL p_emprunter(@tp3_code_9, @tp3_adherent_debiteur, @tp3_emprunt_refuse);
-- Obtenu attendu : ERROR 1644 (45000): Les pénalités impayées de cet adhérent dépassent 10 euros.

-- T7 — L'INSERT direct contourne la procédure, mais pas les triggers.
INSERT INTO emprunt (
  exemplaire_id, adherent_id, date_emprunt, date_retour_prevue
)
VALUES (
  @tp3_exemplaire_10, @tp3_adherent_2, NULL, NULL
);
SET @tp3_emprunt_7 = LAST_INSERT_ID();
SELECT id,
       date_emprunt,
       date_retour_prevue,
       DATEDIFF(date_retour_prevue, date_emprunt) AS duree_jours
  FROM emprunt
 WHERE id = @tp3_emprunt_7;
SELECT code_barre, disponible
  FROM exemplaire
 WHERE id = @tp3_exemplaire_10;
-- Contrôle complémentaire du BEFORE INSERT : la date de retour ne peut précéder le prêt.
-- INSERT INTO emprunt (exemplaire_id, adherent_id, date_emprunt, date_retour_prevue)
-- VALUES (@tp3_exemplaire_9, @tp3_adherent_2, CURDATE(), DATE_SUB(CURDATE(), INTERVAL 1 DAY));
-- Obtenu attendu : ERROR 1644 (45000): Une date de retour ne peut pas précéder la date d'emprunt.

-- T8 — Un prêt rendu avec un jour de retard facture 0,20 euro.
INSERT INTO emprunt (
  exemplaire_id, adherent_id, date_emprunt, date_retour_prevue
)
VALUES (
  @tp3_exemplaire_11, @tp3_adherent_2,
  DATE_SUB(CURDATE(), INTERVAL 20 DAY),
  DATE_SUB(CURDATE(), INTERVAL 1 DAY)
);
SET @tp3_emprunt_8 = LAST_INSERT_ID();
CALL p_rendre(@tp3_code_11);
SELECT adherent_id, emprunt_id, montant, motif
  FROM penalite
 WHERE emprunt_id = @tp3_emprunt_8;
SELECT code_barre, disponible
  FROM exemplaire
 WHERE id = @tp3_exemplaire_11;

-- T9 — À exécuter séparément : le prêt du T8 est déjà rendu.
-- CALL p_rendre(@tp3_code_11);
-- Obtenu attendu : ERROR 1644 (45000): Aucun emprunt en cours ne correspond à ce code-barres.

-- Nettoyage des seules données ajoutées par ce scénario.
DELETE FROM journal_action
 WHERE table_cible = 'emprunt'
   AND cle IN (
     SELECT CAST(em.id AS CHAR)
       FROM emprunt AS em
       JOIN exemplaire AS ex ON ex.id = em.exemplaire_id
      WHERE ex.code_barre LIKE CONCAT('T3-', @tp3_token, '-%')
   );

DELETE FROM penalite
 WHERE adherent_id IN (
   @tp3_adherent_1,
   @tp3_adherent_2,
   @tp3_adherent_inactif,
   @tp3_adherent_debiteur,
   @tp3_adherent_quota
);

DELETE FROM emprunt
 WHERE exemplaire_id IN (
   @tp3_exemplaire_1,
   @tp3_exemplaire_2,
   @tp3_exemplaire_3,
   @tp3_exemplaire_4,
   @tp3_exemplaire_5,
   @tp3_exemplaire_6,
   @tp3_exemplaire_7,
   @tp3_exemplaire_8,
   @tp3_exemplaire_9,
   @tp3_exemplaire_10,
   @tp3_exemplaire_11
);

DELETE FROM exemplaire
 WHERE id IN (
   @tp3_exemplaire_1,
   @tp3_exemplaire_2,
   @tp3_exemplaire_3,
   @tp3_exemplaire_4,
   @tp3_exemplaire_5,
   @tp3_exemplaire_6,
   @tp3_exemplaire_7,
   @tp3_exemplaire_8,
   @tp3_exemplaire_9,
   @tp3_exemplaire_10,
   @tp3_exemplaire_11
);

DELETE FROM adherent
 WHERE id IN (
   @tp3_adherent_1,
   @tp3_adherent_2,
   @tp3_adherent_inactif,
   @tp3_adherent_debiteur,
   @tp3_adherent_quota
);
