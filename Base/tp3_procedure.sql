DELIMITER $$

CREATE PROCEDURE sp_adherent_exist_et_actif(IN p_id INT)
BEGIN
    -- On initialise la variable à NULL par défaut
    DECLARE v_actif TINYINT(1) DEFAULT NULL;

    -- Syntaxe correcte : une seule clause INTO à la fin
    SELECT actif INTO v_actif
    FROM adherent
    WHERE id = p_id;

    -- Si v_actif est toujours NULL, aucune ligne n'a été trouvée
    IF v_actif IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L''adhérent n''existe pas';
    ELSEIF v_actif = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L''adhérent n''est pas actif'; 
    END IF;
END$$


DELIMITER ;


CREATE PROCEDURE sp_exemplaire_disponible(IN p_id INT)
BEGIN
    DECLARE v_disponible TINYINT(1) DEFAULT NULL; 

    SELECT disponible INTO v_disponible 
    FROM exemplaire
    WHERE id = p_id;

    IF v_disponible IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L''exemplaire n''existe pas';
    ELSEIF v_disponible = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L''exemplaire n''est pas disponible';
    END IF;
END$$

DELIMITER ;

CREATE PROCEDURE sp_adherent_a_emprunt_maximum(IN ad_id INT)
BEGIN
    DECLARE v_count INT DEFAULT 0;
    select COUNT(*) INTO v_count
    FROM emprunt
    WHERE adherent_id = ad_id AND date_retour_reelle IS NULL;

    if v_count >= 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L''adhérent a déjà 5 emprunts en cours';
    END IF;

END$$


CREATE PROCEDURE sp_adherent_maximum_penalite(IN ad_id INT)
BEGIN
    DECLARE v_price DECIMAL(10,2) DEFAULT 0 .00;

    SELECT SUM(montant) INTO v_price
    FROM penalite
    WHERE adherent_id = ad_id AND payee = 0;

    IF v_price >= 10.00 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L''adhérent a déjà 10€ de pénalités impayées';
    END IF;

END$$