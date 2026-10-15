USE mediatheque;

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

DROP TRIGGER IF EXISTS bi_emprunt_valider_dates;
DROP TRIGGER IF EXISTS ai_emprunt_marquer_indisponible;
DROP TRIGGER IF EXISTS au_emprunt_enregistrer_retour;

DELIMITER $$

CREATE TRIGGER bi_emprunt_valider_dates
BEFORE INSERT ON emprunt
FOR EACH ROW
BEGIN
  IF NEW.date_emprunt IS NULL THEN
    SET NEW.date_emprunt = CURDATE();
  END IF;

  IF NEW.date_retour_prevue IS NULL THEN
    SET NEW.date_retour_prevue = DATE_ADD(NEW.date_emprunt, INTERVAL 14 DAY);
  END IF;

  IF NEW.date_retour_prevue < NEW.date_emprunt
     OR (
       NEW.date_retour_reelle IS NOT NULL
       AND NEW.date_retour_reelle < NEW.date_emprunt
     )
  THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Une date de retour ne peut pas précéder la date d''emprunt.';
  END IF;
END$$

CREATE TRIGGER ai_emprunt_marquer_indisponible
AFTER INSERT ON emprunt
FOR EACH ROW
BEGIN
  UPDATE exemplaire
     SET disponible = 0
   WHERE id = NEW.exemplaire_id;

  INSERT INTO journal_action (
    table_cible,
    operation,
    cle,
    auteur,
    horodatage,
    details
  )
  VALUES (
    'emprunt',
    'INSERT',
    CAST(NEW.id AS CHAR),
    USER(),
    NOW(),
    CONCAT('exemplaire_id=', NEW.exemplaire_id, '; adherent_id=', NEW.adherent_id)
  );
END$$

CREATE TRIGGER au_emprunt_enregistrer_retour
AFTER UPDATE ON emprunt
FOR EACH ROW
BEGIN
  IF OLD.date_retour_reelle IS NULL
     AND NEW.date_retour_reelle IS NOT NULL
  THEN
    UPDATE exemplaire
       SET disponible = 1
     WHERE id = NEW.exemplaire_id;
  END IF;

  INSERT INTO journal_action (
    table_cible,
    operation,
    cle,
    auteur,
    horodatage,
    details
  )
  VALUES (
    'emprunt',
    'UPDATE',
    CAST(NEW.id AS CHAR),
    USER(),
    NOW(),
    CONCAT(
      'date_retour_reelle: ',
      COALESCE(CAST(OLD.date_retour_reelle AS CHAR), 'NULL'),
      ' -> ',
      COALESCE(CAST(NEW.date_retour_reelle AS CHAR), 'NULL')
    )
  );
END$$

DELIMITER ;
