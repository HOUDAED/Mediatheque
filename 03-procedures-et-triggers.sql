USE mediatheque;

CREATE TABLE IF NOT EXISTS journal_action (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  date_action DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  operation VARCHAR(30) NOT NULL,
  cle VARCHAR(40) NOT NULL,
  auteur VARCHAR(100) NOT NULL,
  details VARCHAR(255) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

DROP FUNCTION IF EXISTS f_nb_emprunts_en_cours;
DROP FUNCTION IF EXISTS f_penalites_dues;
DROP PROCEDURE IF EXISTS p_emprunter;
DROP PROCEDURE IF EXISTS p_rendre;
DROP TRIGGER IF EXISTS trg_emprunt_avant_insert;
DROP TRIGGER IF EXISTS trg_emprunt_apres_insert;

DELIMITER //

CREATE FUNCTION f_nb_emprunts_en_cours(p_adherent INT UNSIGNED) RETURNS INT
READS SQL DATA
BEGIN
  RETURN (SELECT COUNT(*) FROM emprunt WHERE adherent_id = p_adherent AND date_retour_reelle IS NULL);
END//

CREATE FUNCTION f_penalites_dues(p_adherent INT UNSIGNED) RETURNS DECIMAL(8,2)
READS SQL DATA
BEGIN
  RETURN (SELECT COALESCE(SUM(montant), 0) FROM penalite WHERE adherent_id = p_adherent AND payee = 0);
END//

CREATE TRIGGER trg_emprunt_avant_insert BEFORE INSERT ON emprunt
FOR EACH ROW
BEGIN
  IF NEW.date_emprunt IS NULL THEN
    SET NEW.date_emprunt = CURDATE();
  END IF;
  IF NEW.date_retour_prevue IS NULL THEN
    SET NEW.date_retour_prevue = NEW.date_emprunt + INTERVAL 14 DAY;
  END IF;
END//

CREATE TRIGGER trg_emprunt_apres_insert AFTER INSERT ON emprunt
FOR EACH ROW
BEGIN
  UPDATE exemplaire SET disponible = 0 WHERE id = NEW.exemplaire_id;
END//

CREATE PROCEDURE p_emprunter(IN p_code VARCHAR(20), IN p_adherent INT UNSIGNED, OUT p_emprunt_id INT UNSIGNED)
BEGIN
  DECLARE v_exemplaire INT UNSIGNED;
  DECLARE v_disponible TINYINT;
  DECLARE v_etat VARCHAR(20);
  DECLARE v_actif TINYINT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET p_emprunt_id = NULL;
  START TRANSACTION;

  SELECT id, disponible, etat INTO v_exemplaire, v_disponible, v_etat
  FROM exemplaire WHERE code_barre = p_code FOR UPDATE;
  IF v_exemplaire IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Code-barres inconnu';
  END IF;
  IF v_etat = 'hors_service' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Exemplaire hors service';
  END IF;
  IF v_disponible = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Exemplaire déjà emprunté';
  END IF;

  SELECT actif INTO v_actif FROM adherent WHERE id = p_adherent;
  IF v_actif IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Adhérent inconnu';
  END IF;
  IF v_actif = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inscription inactive';
  END IF;
  IF f_nb_emprunts_en_cours(p_adherent) >= 5 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quota de 5 emprunts atteint';
  END IF;
  IF f_penalites_dues(p_adherent) > 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pénalités impayées supérieures à 10 €';
  END IF;

  INSERT INTO emprunt (exemplaire_id, adherent_id, date_emprunt, date_retour_prevue)
  VALUES (v_exemplaire, p_adherent, NULL, NULL);
  SET p_emprunt_id = LAST_INSERT_ID();

  INSERT INTO journal_action (operation, cle, auteur, details)
  VALUES ('EMPRUNT', p_code, USER(), CONCAT('emprunt ', p_emprunt_id, ' - adhérent ', p_adherent));

  COMMIT;
END//

CREATE PROCEDURE p_rendre(IN p_code VARCHAR(20))
BEGIN
  DECLARE v_emprunt INT UNSIGNED;
  DECLARE v_exemplaire INT UNSIGNED;
  DECLARE v_adherent INT UNSIGNED;
  DECLARE v_retour_prevue DATE;
  DECLARE v_jours INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT em.id, em.exemplaire_id, em.adherent_id, em.date_retour_prevue
  INTO v_emprunt, v_exemplaire, v_adherent, v_retour_prevue
  FROM emprunt em JOIN exemplaire ex ON ex.id = em.exemplaire_id
  WHERE ex.code_barre = p_code AND em.date_retour_reelle IS NULL
  ORDER BY em.id DESC LIMIT 1 FOR UPDATE;
  IF v_emprunt IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Aucun emprunt en cours pour ce code-barres';
  END IF;

  UPDATE emprunt SET date_retour_reelle = CURDATE() WHERE id = v_emprunt;
  UPDATE exemplaire SET disponible = 1 WHERE id = v_exemplaire;

  SET v_jours = DATEDIFF(CURDATE(), v_retour_prevue);
  IF v_jours > 0 THEN
    INSERT INTO penalite (adherent_id, emprunt_id, montant, motif, date_creation)
    VALUES (v_adherent, v_emprunt, v_jours * 0.20, CONCAT('Retour avec ', v_jours, ' jour(s) de retard'), CURDATE());
  END IF;

  INSERT INTO journal_action (operation, cle, auteur, details)
  VALUES ('RETOUR', p_code, USER(), CONCAT('emprunt ', v_emprunt, ' - ', GREATEST(v_jours, 0), ' jour(s) de retard'));

  COMMIT;
END//

DELIMITER ;
