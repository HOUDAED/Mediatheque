CREATE OR REPLACE VIEW v_adherent_lyon AS 
SELECT
    id,
    nom,
    prenom,
    email,
    telephone,
    date_naissance,
    ville,
    date_inscription,
    actif
FROM adherent
WHERE ville = 'Lyon'
WITH CHECK OPTION;

CREATE INDEX idx_date_emprunt ON emprunt(date_emprunt);
CREATE INDEX idx_emprunt_retour ON emprunt(date_retour_reelle);
CREATE INDEX idx_emprunt_adherent_date ON emprunt(adherent_id, date_emprunt);