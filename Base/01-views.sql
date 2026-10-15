CREATE OR REPLACE VIEW v_catalogue AS
SELECT  o.titre, o.auteur, o.annee_publication,  c.libelle AS categorie,COUNT(e.id) AS nombre_exemplaires, SUM(e.disponible = 1) AS exemplaires_disponibles
FROM ouvrage  o 
JOIN categorie c 
ON c.id = o.categorie_id 
LEFT JOIN exemplaire  e 
ON e.ouvrage_id = o.id 
GROUP BY o.id, o.titre, o.auteur, o.annee_publication, c.libelle;

CREATE OR REPLACE VIEW v_adherent_public AS 
SELECT id, nom, prenom,ville,date_inscription, actif 
 from adherent;

 CREATE OR REPLACE VIEW v_emprunt_en_cours AS
  SELECT     e.id,     e.date_emprunt,     e.date_retour_prevue,     GREATEST(DATEDIFF(CURRENT_DATE(), e.date_retour_prevue), 0) AS jours_de_retard,    
  CONCAT(a.nom, ' ', a.prenom) AS nom_complet,  
  o.titre,     ex.code_barre 
  FROM emprunt AS e 
  JOIN adherent AS a ON a.id = e.adherent_id 
  JOIN exemplaire AS ex ON ex.id = e.exemplaire_id 
  JOIN ouvrage AS o ON o.id = ex.ouvrage_id 
  WHERE e.date_retour_reelle IS NULL;


CREATE OR REPLACE VIEW v_retard AS
SELECT v_emprunt_en_cours.* FROM v_emprunt_en_cours
  where v_emprunt_en_cours.date_retour_prevue < CURRENT_DATE();

-- stagiaire revoke 
REVOKE SELECT (id, nom, prenom, ville, date_inscription, actif) ON mediatheque.adherent FROM  'stagiaire'@'localhost';
GRANT SELECT ON mediatheque.v_adherent_public TO 'stagiaire'@'localhost';
GRANT SELECT ON mediatheque.v_catalogue TO 'stagiaire'@'localhost';
GRANT SELECT ON mediatheque.v_emprunt_en_cours TO 'stagiaire'@'localhost';
