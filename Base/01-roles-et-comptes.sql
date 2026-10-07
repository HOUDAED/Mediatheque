DROP USER IF EXISTS 'app media'@'localhost';
GRANT USAGE ON *.* TO 'app media'@'localhost';
GRANT role_catalogue TO 'app media'@'localhost';
GRANT role_prets TO 'app media'@'localhost';
GRANT role_adherents TO 'app media'@'localhost';
CREATE USER 'app media'@'localhost' IDENTIFIED BY 'TonMotDePasse1!';

DROP ROLE IF EXISTS role_catalogue;
DROP ROLE IF EXISTS role_prets;
DROP ROLE IF EXISTS role_adherents;

CREATE ROLE role_catalogue;
CREATE ROLE role_prets;
CREATE ROLE role_adherents;

GRANT SELECT ON mediatheque.ouvrage TO role_catalogue;
GRANT SELECT ON mediatheque.exemplaire TO role_catalogue;
GRANT SELECT ON mediatheque.categorie TO role_catalogue;

GRANT SELECT ON mediatheque.emprunt TO role_prets;
GRANT INSERT ON mediatheque.emprunt TO role_prets;
GRANT UPDATE ON mediatheque.emprunt TO role_prets;

GRANT SELECT ON mediatheque.reservation TO role_prets;
GRANT INSERT ON mediatheque.reservation TO role_prets;
GRANT UPDATE ON mediatheque.reservation TO role_prets;

GRANT SELECT ON mediatheque.penalite TO role_prets;
GRANT INSERT ON mediatheque.penalite TO role_prets;
GRANT UPDATE ON mediatheque.penalite TO role_prets;

GRANT UPDATE (disponible) ON mediatheque.exemplaire TO role_prets;

GRANT SELECT ON mediatheque.adherent TO role_adherents;
GRANT INSERT ON mediatheque.adherent TO role_adherents;
GRANT UPDATE ON mediatheque.adherent TO role_adherents;

