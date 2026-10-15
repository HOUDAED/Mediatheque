DROP USER IF EXISTS 'app_media'@'localhost';
DROP USER IF EXISTS 'biblio_marie'@'localhost';
DROP USER IF EXISTS 'stagiaire'@'localhost';
DROP USER IF EXISTS 'analyste'@'localhost';

DROP ROLE IF EXISTS role_catalogue;
DROP ROLE IF EXISTS role_prets;
DROP ROLE IF EXISTS role_adherents;

USE mediatheque;

CREATE ROLE role_catalogue;
CREATE ROLE role_prets;
CREATE ROLE role_adherents;

GRANT SELECT ON mediatheque.ouvrage TO role_catalogue;
GRANT SELECT ON mediatheque.exemplaire TO role_catalogue;
GRANT SELECT ON mediatheque.categorie TO role_catalogue;

GRANT SELECT, INSERT, UPDATE ON mediatheque.emprunt TO role_prets;
GRANT SELECT, INSERT, UPDATE ON mediatheque.reservation TO role_prets;
GRANT SELECT, INSERT, UPDATE ON mediatheque.penalite TO role_prets;
GRANT UPDATE (disponible) ON mediatheque.exemplaire TO role_prets;

GRANT SELECT, INSERT, UPDATE ON mediatheque.adherent TO role_adherents;

CREATE USER 'app_media'@'localhost' IDENTIFIED BY 'App_media@2026';
CREATE USER 'biblio_marie'@'localhost' IDENTIFIED BY 'Biblio_marie@2026';
CREATE USER 'stagiaire'@'localhost' IDENTIFIED BY 'Stagiaire@2026';
CREATE USER 'analyste'@'localhost' IDENTIFIED BY 'Analyste@2026';

GRANT role_catalogue TO 'app_media'@'localhost';
GRANT role_prets TO 'app_media'@'localhost';
GRANT SELECT (id, nom, prenom, actif) ON mediatheque.adherent TO 'app_media'@'localhost';
GRANT SELECT ON mediatheque.ouvrage TO 'app_media'@'localhost';
GRANT SELECT ON mediatheque.exemplaire TO 'app_media'@'localhost';
GRANT SELECT ON mediatheque.categorie TO 'app_media'@'localhost';

GRANT role_catalogue TO 'biblio_marie'@'localhost';
GRANT role_prets TO 'biblio_marie'@'localhost';
GRANT role_adherents TO 'biblio_marie'@'localhost';
GRANT SELECT ON mediatheque.ouvrage TO 'biblio_marie'@'localhost';
GRANT SELECT ON mediatheque.exemplaire TO 'biblio_marie'@'localhost';
GRANT SELECT ON mediatheque.categorie TO 'biblio_marie'@'localhost';
GRANT SELECT, INSERT, UPDATE ON mediatheque.emprunt TO 'biblio_marie'@'localhost';
GRANT SELECT, INSERT, UPDATE ON mediatheque.reservation TO 'biblio_marie'@'localhost';
GRANT SELECT, INSERT, UPDATE ON mediatheque.penalite TO 'biblio_marie'@'localhost';
GRANT UPDATE (disponible) ON mediatheque.exemplaire TO 'biblio_marie'@'localhost';

GRANT role_catalogue TO 'stagiaire'@'localhost';
GRANT SELECT (id, nom, prenom, ville, date_inscription, actif) ON mediatheque.adherent TO 'stagiaire'@'localhost';

GRANT role_catalogue TO 'analyste'@'localhost';
GRANT SELECT ON mediatheque.emprunt TO 'analyste'@'localhost';

-- MariaDB supports one default role per account; the additional privileges
-- for app_media and biblio_marie are granted directly above.
SET DEFAULT ROLE role_prets FOR 'app_media'@'localhost';
SET DEFAULT ROLE role_adherents FOR 'biblio_marie'@'localhost';
SET DEFAULT ROLE role_catalogue FOR 'stagiaire'@'localhost';
SET DEFAULT ROLE role_catalogue FOR 'analyste'@'localhost';

SHOW GRANTS FOR 'app_media'@'localhost';
SHOW GRANTS FOR 'biblio_marie'@'localhost';
SHOW GRANTS FOR 'stagiaire'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';

SELECT GRANTEE, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, PRIVILEGE_TYPE 
FROM information_schema.column_privileges
WHERE TABLE_SCHEMA = 'mediatheque';

GRANT SELECT ON mediatheque.reservation TO 'analyste'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';


REVOKE SELECT ON mediatheque.reservation FROM 'analyste'@'localhost';
SHOW GRANTS FOR 'analyste'@'localhost';
