USE mediatheque;

DROP PROCEDURE IF EXISTS p_emprunter;
DROP PROCEDURE IF EXISTS p_rendre;
DROP PROCEDURE IF EXISTS p_bilan_adherent;

DELIMITER $$

CREATE PROCEDURE p_emprunter(
  IN p_code_barre VARCHAR(20),
  IN p_adherent_id INT UNSIGNED,
  OUT p_emprunt_id INT UNSIGNED
)
BEGIN
  DECLARE v_actif TINYINT DEFAULT NULL;
  DECLARE v_exemplaire_id INT UNSIGNED DEFAULT NULL;
  DECLARE v_disponible TINYINT DEFAULT NULL;
  DECLARE v_etat VARCHAR(20) DEFAULT NULL;
  DECLARE v_emprunts_en_cours INT DEFAULT 0;
  DECLARE v_penalites DECIMAL(10,2) DEFAULT 0.00;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET p_emprunt_id = NULL;
  START TRANSACTION;

  SELECT actif
    INTO v_actif
    FROM adherent
   WHERE id = p_adherent_id
   FOR UPDATE;

  IF v_actif IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cet adhérent n''existe pas.';
  ELSEIF v_actif = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'L''inscription de cet adhérent est inactive.';
  END IF;

  SELECT id, disponible, etat
    INTO v_exemplaire_id, v_disponible, v_etat
    FROM exemplaire
   WHERE code_barre = p_code_barre
   FOR UPDATE;

  IF v_exemplaire_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ce code-barres ne correspond à aucun exemplaire.';
  ELSEIF v_disponible = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cet exemplaire n''est pas disponible.';
  ELSEIF v_etat = 'hors_service' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cet exemplaire est hors service.';
  END IF;

  SET v_emprunts_en_cours = f_nb_emprunts_en_cours(p_adherent_id);
  IF v_emprunts_en_cours >= 5 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cet adhérent a déjà atteint la limite de cinq emprunts en cours.';
  END IF;

  SET v_penalites = f_penalites_dues(p_adherent_id);
  IF v_penalites > 10.00 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Les pénalités impayées de cet adhérent dépassent 10 euros.';
  END IF;

  INSERT INTO emprunt (
    exemplaire_id,
    adherent_id,
    date_emprunt,
    date_retour_prevue
  )
  VALUES (
    v_exemplaire_id,
    p_adherent_id,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 14 DAY)
  );

  SET p_emprunt_id = LAST_INSERT_ID();
  COMMIT;
END$$

CREATE PROCEDURE p_rendre(IN p_code_barre VARCHAR(20))
BEGIN
  DECLARE v_emprunt_id INT UNSIGNED DEFAULT NULL;
  DECLARE v_adherent_id INT UNSIGNED DEFAULT NULL;
  DECLARE v_date_retour_prevue DATE DEFAULT NULL;
  DECLARE v_jours_retard INT DEFAULT 0;
  DECLARE v_montant DECIMAL(6,2) DEFAULT 0.00;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT em.id, em.adherent_id, em.date_retour_prevue
    INTO v_emprunt_id, v_adherent_id, v_date_retour_prevue
    FROM emprunt AS em
    JOIN exemplaire AS ex ON ex.id = em.exemplaire_id
   WHERE ex.code_barre = p_code_barre
     AND em.date_retour_reelle IS NULL
   ORDER BY em.id
   LIMIT 1
   FOR UPDATE;

  IF v_emprunt_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Aucun emprunt en cours ne correspond à ce code-barres.';
  END IF;

  SET v_jours_retard = GREATEST(
    DATEDIFF(CURDATE(), v_date_retour_prevue),
    0
  );
  SET v_montant = v_jours_retard * 0.20;

  UPDATE emprunt
     SET date_retour_reelle = CURDATE()
   WHERE id = v_emprunt_id;

  IF v_jours_retard > 0 THEN
    INSERT INTO penalite (
      adherent_id,
      emprunt_id,
      montant,
      motif,
      date_creation,
      payee
    )
    VALUES (
      v_adherent_id,
      v_emprunt_id,
      v_montant,
      CONCAT('Retard de ', v_jours_retard, ' jour(s)'),
      CURDATE(),
      0
    );
  END IF;

  COMMIT;

  SELECT v_emprunt_id AS emprunt_id,
         v_jours_retard AS jours_de_retard,
         v_montant AS montant_facture;
END$$

CREATE PROCEDURE p_bilan_adherent(IN p_adherent_id INT UNSIGNED)
BEGIN
  DECLARE v_adherent_id INT UNSIGNED DEFAULT NULL;

  SELECT id
    INTO v_adherent_id
    FROM adherent
   WHERE id = p_adherent_id;

  IF v_adherent_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cet adhérent n''existe pas.';
  END IF;

  SELECT a.id,
         a.nom,
         a.prenom,
         a.actif,
         f_nb_emprunts_en_cours(a.id) AS emprunts_en_cours,
         f_penalites_dues(a.id) AS penalites_dues
    FROM adherent AS a
   WHERE a.id = p_adherent_id;

  SELECT em.id AS emprunt_id,
         em.date_emprunt,
         em.date_retour_prevue,
         f_jours_de_retard(em.id) AS jours_de_retard,
         ex.code_barre,
         o.titre
    FROM emprunt AS em
    JOIN exemplaire AS ex ON ex.id = em.exemplaire_id
    JOIN ouvrage AS o ON o.id = ex.ouvrage_id
   WHERE em.adherent_id = p_adherent_id
     AND em.date_retour_reelle IS NULL
   ORDER BY em.date_emprunt, em.id;

  SELECT COUNT(*) AS nombre_total_emprunts
    FROM emprunt
   WHERE adherent_id = p_adherent_id;
END$$

DELIMITER ;
