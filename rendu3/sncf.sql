-- A faire
--      INSERT : compléter si il y a besoin
--      VIEW : insérer des choses impossibles et vérifier que les vues renvoient une information permettant de régler le problème
--      SELECT avec GROUP BY (fichier séparé ?)
--          Statistiques sur le fonctionnement de la société :
--              taux de remplissage des trains,
--              gares les plus fréquentées,
--              les lignes les plus empruntées,
--              etc.


------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

-- CREATE

DROP TABLE IF EXISTS Gare;
DROP TABLE IF EXISTS Hotel;
DROP TABLE IF EXISTS DisposeHotel;
DROP TABLE IF EXISTS Taxi;
DROP TABLE IF EXISTS DisposeTaxi;
DROP TABLE IF EXISTS TransportPublic;
DROP TABLE IF EXISTS DisposeTransportPublic;
DROP TABLE IF EXISTS TypeTrain;
DROP TABLE IF EXISTS Train;
DROP TABLE IF EXISTS Ligne;
DROP TABLE IF EXISTS ArretLigne;
DROP TABLE IF EXISTS Calendrier;
DROP TABLE IF EXISTS DateException;
DROP TABLE IF EXISTS ConcerneCalendrier;
DROP TABLE IF EXISTS Voyage;
DROP TABLE IF EXISTS ArretVoyage;
DROP TABLE IF EXISTS Trajet;
DROP TABLE IF EXISTS ArretTrajet;
DROP TABLE IF EXISTS Voyageur;
DROP TABLE IF EXISTS Billet;
DROP TABLE IF EXISTS CompositionBillet;


DROP VIEW IF EXISTS v_DisposeHotel;


CREATE TABLE Gare (
    nom VARCHAR(20),
    ville VARCHAR(20),
    adresse VARCHAR(80) NOT NULL,
    pays VARCHAR(20) NOT NULL,
    PRIMARY KEY (nom, ville)
);

CREATE TABLE Hotel (
    nom VARCHAR(20),
    adresse VARCHAR(80),
    PRIMARY KEY (nom, adresse)
);

CREATE TABLE DisposeHotel (
    nom_gare VARCHAR(20),
    ville_gare VARCHAR(20),
    nom_hotel VARCHAR(20),
    adresse_hotel VARCHAR(80),
    PRIMARY KEY (nom_gare, ville_gare, nom_hotel, adresse_hotel),
    FOREIGN KEY (nom_gare, ville_gare) REFERENCES Gare(nom, ville),
    FOREIGN KEY (nom_hotel, adresse_hotel) REFERENCES Hotel(nom, adresse)
);

CREATE TABLE Taxi (
    num INT PRIMARY KEY,
    telephone VARCHAR(10) NOT NULL
);

CREATE TABLE DisposeTaxi (
    nom_gare VARCHAR(20),
    ville_gare VARCHAR(20),
    num_taxi INT REFERENCES Taxi(num),
    PRIMARY KEY (nom_gare, ville_gare, num_taxi),
    FOREIGN KEY (nom_gare, ville_gare) REFERENCES Gare(nom, ville)
);

CREATE TABLE TransportPublic (
    num INT PRIMARY KEY
);

CREATE TABLE DisposeTransportPublic (
    nom_gare VARCHAR(20),
    ville_gare VARCHAR(20),
    num_transport_public INT REFERENCES TransportPublic(num),
    PRIMARY KEY (nom_gare, ville_gare, num_transport_public),
    FOREIGN KEY (nom_gare, ville_gare) REFERENCES Gare(nom, ville)
);

CREATE TABLE TypeTrain (
    nom VARCHAR(20) PRIMARY KEY,
    nb_places INT NOT NULL,
    vitesse INT NOT NULL,
    première_classe BOOLEAN NOT NULL,
    CHECK (vitesse >= 0 AND nb_places >= 0)
);

CREATE TABLE Train (
    num INT PRIMARY KEY,
    type_train VARCHAR(20) NOT NULL REFERENCES TypeTrain(nom)
);

CREATE TABLE Ligne (
    num INT PRIMARY KEY,
    type_train VARCHAR(20) NOT NULL REFERENCES TypeTrain(nom)
);

CREATE TABLE ArretLigne (
    num_arret INT,
    ligne INT REFERENCES Ligne(num),
    arrive BOOLEAN,
    nom_gare VARCHAR(20),
    ville_gare VARCHAR(20),
    PRIMARY KEY (num_arret, ligne),
    FOREIGN KEY (nom_gare, ville_gare) REFERENCES Gare(nom, ville),
    CHECK (num_arret >= 1)
);

CREATE TABLE Calendrier (
    id_calendrier INT PRIMARY KEY,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    horaire TIME NOT NULL,
    lundi BOOLEAN NOT NULL,
    mardi BOOLEAN NOT NULL,
    mercredi BOOLEAN NOT NULL,
    jeudi BOOLEAN NOT NULL,
    vendredi BOOLEAN NOT NULL,
    samedi BOOLEAN NOT NULL,
    dimanche BOOLEAN NOT NULL
);

CREATE TABLE DateException (
    date_ DATE,
    ajout BOOLEAN,
    PRIMARY KEY (date_, ajout)
);

CREATE TABLE ConcerneCalendrier (
    date_exception DATE,
    ajout_exception BOOLEAN,
    calendrier INT REFERENCES Calendrier(id_calendrier),
    PRIMARY KEY (date_exception, ajout_exception, calendrier),
    FOREIGN KEY (date_exception, ajout_exception) REFERENCES DateException(date_, ajout)
);

CREATE TABLE Voyage (
    id_voyage INT PRIMARY KEY,
    ligne INT NOT NULL REFERENCES Ligne(num),
    train INT NOT NULL REFERENCES Train(num),
    calendrier INT NOT NULL REFERENCES Calendrier(id_calendrier)
);

CREATE TABLE ArretVoyage (
    num_arret INT,
    voyage INT REFERENCES Voyage(id_voyage),
    heure_depart TIME NOT NULL,
    heure_arrivee TIME NOT NULL,
    arret_ligne INT NOT NULL,
    ligne INT NOT NULL,
    PRIMARY KEY (num_arret, voyage),
    UNIQUE (arret_ligne, ligne, voyage),
    FOREIGN KEY (arret_ligne, ligne) REFERENCES ArretLigne(num_arret, ligne),
    CHECK (heure_depart > heure_arrivee)
);

CREATE TABLE Trajet (
    id_trajet INT PRIMARY KEY,
    num_place INT NOT NULL,
    date_ DATE NOT NULL
);

CREATE TABLE ArretTrajet (
    trajet INT REFERENCES Trajet(id_trajet),
    num_arret_voyage INT,
    voyage INT,
    depart BOOLEAN NOT NULL,
    PRIMARY KEY (trajet, num_arret_voyage, voyage),
    FOREIGN KEY (num_arret_voyage, voyage) REFERENCES ArretVoyage(num_arret, voyage)
);

CREATE TABLE Voyageur (
    nom VARCHAR(20),
    prenom VARCHAR(20),
    adresse VARCHAR(80),
    telephone VARCHAR(10) NOT NULL,
    paiement VARCHAR(7) NOT NULL,
    carte INT,
    statut VARCHAR(7),
    occasionnel BOOLEAN NOT NULL,
    PRIMARY KEY (nom, prenom, adresse),
    CHECK ((paiement = 'carte' OR paiement = 'cheque' OR paiement = 'monnaie') AND (statut = 'bronze' OR statut = 'silver' OR statut = 'gold' OR statut = 'platine')),
    CHECK ((occasionnel = FALSE AND carte IS NOT NULL AND statut IS NOT NULL) OR (occasionnel = true AND carte IS NULL AND statut IS NULL))
);

CREATE TABLE Billet (
    id_billet INT PRIMARY KEY,
    assurance BOOLEAN NOT NULL,
    prix FLOAT NOT NULL,
    voyageur_nom VARCHAR(20) NOT NULL,
    voyageur_prenom VARCHAR(20) NOT NULL,
    voyageur_adresse VARCHAR(80) NOT NULL,
    FOREIGN KEY (voyageur_nom, voyageur_prenom, voyageur_adresse) REFERENCES Voyageur(nom, prenom, adresse)
);

CREATE TABLE CompositionBillet (
    billet INT REFERENCES Billet(id_billet),
    trajet INT REFERENCES Trajet(id_trajet),
    PRIMARY KEY (billet, trajet)
);


------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

-- VIEW

CREATE VIEW v_DisposeHotel AS
SELECT h.nom, h.adresse
FROM DisposeHotel d RIGHT OUTER JOIN Hotel h
ON h.nom = d.nom_hotel
AND h.adresse = d.adresse_hotel
WHERE d.nom_hotel IS NULL;
-- Permet de vérifier
--      Projection(DisposeHotel, nom_hôtel, adresse_hôtel) = Projection(Hôtel, nom, adresse)
-- en donnant la liste des hotels ne respectant pas la contrainte

CREATE VIEW v_DisposeTaxi AS
SELECT t.num
FROM DisposeTaxi d RIGHT OUTER JOIN Taxi t
ON t.num = d.num_taxi
WHERE d.num_taxi IS NULL;
-- Permet de vérifier
--      Projection(DisposeTaxi, num_taxi) = Projection(Taxi, num)
-- en donnant la liste des taxis ne respectant pas la contrainte

CREATE VIEW v_DisposeTransportPublic AS
SELECT t.num
FROM DisposeTransportPublic d RIGHT OUTER JOIN TransportPublic t
ON t.num = d.num_transport_public
WHERE d.num_transport_public IS NULL;
-- Permet de vérifier
--      Projection(DisposeTransportPublic, num_transport_public) = Projection(TransportPublic, num)
-- en donnant la liste des transports publics ne respectant pas la contrainte

CREATE VIEW v_ArretLigne AS
SELECT COUNT(a.ligne), l.num
FROM ArretLigne a RIGHT OUTER JOIN Ligne l
ON l.num = a.ligne
GROUP BY (a.ligne, l.num)
HAVING COUNT(*) < 2;
-- Permet de vérifier
--      Projection(Ligne, num) = Projection(ArrêtLigne, ligne)
--      une ligne doit relier au moins deux arrêts
-- en donnant la liste des lignes ne respectant pas les contraintes

CREATE VIEW v_Voyage AS
SELECT l.num
FROM Voyage v RIGHT OUTER JOIN Ligne l
ON l.num = v.ligne
WHERE v.ligne IS NULL;
-- Permet de vérifier
--      Projection(Voyage, ligne) = Projection(Ligne, num)
-- en donnant la liste des lignes ne respectant pas la contrainte

CREATE VIEW v_ConcerneCalendrier AS
SELECT d.date_, d.ajout
FROM ConcerneCalendrier c RIGHT OUTER JOIN DateException d
ON d.date_ = c.date_exception
AND d.ajout = c.ajout_exception
WHERE c.date_exception IS NULL;
-- Permet de vérifier
--      Projection(ConcerneCalendrier, date_exception, ajout_exception) = Projection(DateException, date, ajout)
-- en donnant la liste des dates exceptions ne respectant pas la contrainte

CREATE VIEW v_ArretVoyage AS
SELECT COUNT(a.voyage), v.id_voyage
FROM ArretVoyage a RIGHT OUTER JOIN Voyage v
ON v.id_voyage = a.voyage
GROUP BY (v.id_voyage, a.voyage)
HAVING COUNT(*) < 2;
-- Permet de vérifier
--      Projection(ArrêtVoyage, voyage) = Projection(Voyage, id_voyage)
--      un voyage possède au moins deux arrêts
-- en donnant la liste des voyages ne respectant pas les contraintes

CREATE VIEW v_ArretVoyage2 AS
SELECT v.id_voyage, v.ligne
FROM ArretVoyage a RIGHT OUTER JOIN Voyage v
ON v.id_voyage = a.voyage
AND v.ligne = a.ligne
WHERE a.ligne IS NULL;
-- Permet de vérifier
--      Projection(ArrêtVoyage, ligne, voyage) = Projection(Voyage, ligne, id_voyage)
-- en donnant la liste des voyages et lignes ne respectant pas la contrainte

CREATE VIEW v_ArretTrajet AS
SELECT COUNT(a.trajet), t.id_trajet
FROM ArretTrajet a RIGHT OUTER JOIN Trajet t
ON t.id_trajet = a.trajet
GROUP BY (t.id_trajet, a.trajet)
HAVING COUNT(*) <> 2;
-- Permet de vérifier
--      Projection(ArrêtTrajet, trajet) = Projection(Trajet, id_trajet)
--      un trajet possède exactement deux arrêts de voyage
-- en donnant la liste des trajets ne respectant pas les contraintes

CREATE VIEW v_CompositionBillet AS
SELECT b.id_billet
FROM CompositionBillet c RIGHT OUTER JOIN Billet b
ON b.id_billet = c.billet
WHERE c.billet IS NULL;
-- Permet de vérifier
--      Projection(CompositionBillet, billet) = Projection(Billet, id_billet)
-- en donnant la liste des billets ne respectant pas la contrainte

CREATE VIEW v_LigneVoyageTypeTrain AS
SELECT t.type_train, v.id_voyage, v.ligne, v.train, l.type_train AS type_train_ligne
FROM Train t, Voyage v, Ligne l
WHERE t.num = v.train AND l.num = v.ligne AND l.type_train <> t.type_train;
-- Permet de vérifier
--      Projection(Jointure(Train, Voyage, Train.num = Voyage.train), type_train) = Projection(Ligne, type_train)
-- en donnant la liste voyages (avec les types_train, ligne, train) ne respectant pas la contrainte

CREATE VIEW v_CheckDate AS
SELECT t.date_ AS trajet_date, c.date_debut, c.date_fin, c.lundi, c.mardi, c.mercredi, c.jeudi, c.vendredi, c.samedi, c.dimanche, d.date_ AS date_exception, d.ajout
FROM Trajet t JOIN ArretTrajet a
ON t.id_trajet = a.trajet JOIN ArretVoyage av
ON a.num_arret_voyage = av.num_arret
AND a.voyage = av.voyage JOIN Voyage v
ON av.voyage = v.id_voyage JOIN Calendrier c
ON v.calendrier = c.id_calendrier LEFT OUTER JOIN ConcerneCalendrier cc
ON c.id_calendrier = cc.calendrier LEFT OUTER JOIN DateException d
ON cc.date_exception = d.date_
AND cc.ajout_exception = d.ajout;
-- La contrainte qu'on cherche à vérifier est
--      L'attribut date dans Trajet doit être une date présente dans le Calendrier du Voyage et non supprimée dans DateException, ou bien une date ajoutée dans DateException du Voyage.

CREATE VIEW v_CheckTime AS
SELECT c.horaire horaire_calendrier, a.heure_depart
FROM Calendrier c JOIN Voyage v
ON c.id_calendrier = v.calendrier JOIN ArretVoyage a
ON v.id_voyage = a.voyage WHERE a.num_arret = 1 AND c.horaire <> a.heure_depart;
-- La contrainte qu'on cherche à vérifier est
--      Il faut s'assurer que l'horaire de Voyage (présente dans Calendrier) est égale à l'heure de départ du premier ArretVoyage.

CREATE VIEW v_CheckPlace AS
SELECT tt.nb_places, t.id_trajet, COUNT(*)
FROM Billet b JOIN CompositionBillet cb
ON b.id_billet = cb.billet JOIN Trajet t
ON cb.trajet = t.id_trajet JOIN ArretTrajet a
ON t.id_trajet = a.trajet JOIN ArretVoyage av
ON a.num_arret_voyage = av.num_arret
AND a.voyage = av.voyage JOIN Voyage v
ON av.voyage = v.id_voyage JOIN Train tr
ON v.train = tr.num JOIN TypeTrain tt
ON tr.type_train = tt.nom WHERE a.depart GROUP BY (nb_places, id_trajet);
-- La contrainte qu'on cherche à vérifier est
--      Il faut s'assurer que le nombre de places réservées ne dépasse pas nb_places du TypeTrain pour chaque Voyage.
-- Pour savoir pour quel(s) trajet(s) le nombre de places est dépassé :
--      SELECT * FROM v_CheckPlace WHERE count > nb_places;
-- Vue utilisée pour calculer le taux de remplissage    


------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

-- INSERT

INSERT INTO Gare VALUES ('Gare ferroviaire', 'Compiegne', 'rue Ferdinand Bacs', 'France');
INSERT INTO Gare VALUES ('Gare du Nord', 'Paris', '18 rue de Dunkerque', 'France');
INSERT INTO Gare VALUES ('Gare de Lyon', 'Paris', 'place Louis-Armand', 'France');
INSERT INTO Gare VALUES ('Gare Montparnasse', 'Paris', '17 boulevard de Vaugirard', 'France');
INSERT INTO Gare VALUES ('Gare ferroviaire', 'Creil', 'rue Despinas', 'France');
INSERT INTO Gare VALUES ('Gare ferroviaire', 'Pont-Sainte-Maxence', 'rue de la Paix', 'France');
INSERT INTO Gare VALUES ('Gare ferroviaire', 'Amiens', '47 place Alphonse Fiquet,', 'France');
INSERT INTO Gare VALUES ('Gare Bruxelles-Midi', 'Bruxelles', '47B avenue Fonsny', 'Belgique');

INSERT INTO Hotel VALUES ('B&B', '10 avenue Marcellin Berthelot');
INSERT INTO Hotel VALUES ('Marriott', '70 avenue des Champs-Elysees');
INSERT INTO Hotel VALUES ('Ritz', '15 place Vendôme');

INSERT INTO DisposeHotel VALUES ('Gare ferroviaire', 'Compiegne', 'B&B', '10 avenue Marcellin Berthelot');
INSERT INTO DisposeHotel VALUES ('Gare du Nord', 'Paris', 'Marriott', '70 avenue des Champs-Elysees');
INSERT INTO DisposeHotel VALUES ('Gare de Lyon', 'Paris', 'Marriott', '70 avenue des Champs-Elysees');
INSERT INTO DisposeHotel VALUES ('Gare Montparnasse', 'Paris', 'Marriott', '70 avenue des Champs-Elysees');
INSERT INTO DisposeHotel VALUES ('Gare du Nord', 'Paris', 'Ritz', '15 place Vendôme');
INSERT INTO DisposeHotel VALUES ('Gare de Lyon', 'Paris', 'Ritz', '15 place Vendôme');
INSERT INTO DisposeHotel VALUES ('Gare Montparnasse', 'Paris', 'Ritz', '15 place Vendôme');

INSERT INTO Taxi VALUES (1096, '0654782945');
INSERT INTO Taxi VALUES (2003, '0751762378');

INSERT INTO DisposeTaxi VALUES ('Gare ferroviaire', 'Creil', '1096');
INSERT INTO DisposeTaxi VALUES ('Gare ferroviaire', 'Compiegne', '2003');

INSERT INTO TransportPublic VALUES (23);

INSERT INTO DisposeTransportPublic VALUES ('Gare ferroviaire', 'Pont-Sainte-Maxence', 23);

INSERT INTO TypeTrain VALUES ('TER', 204, 170, FALSE);
INSERT INTO TypeTrain VALUES ('TGV', 500, 190, TRUE);
INSERT INTO TypeTrain VALUES ('RER', 204, 100, FALSE);
INSERT INTO TypeTrain VALUES ('metro', 204, 80, FALSE);

INSERT INTO Train VALUES (1, 'metro');
INSERT INTO Train VALUES (2, 'metro');
INSERT INTO Train VALUES (3, 'metro');
INSERT INTO Train VALUES (4, 'metro');
INSERT INTO Train VALUES (5, 'metro');
INSERT INTO Train VALUES (9, 'TGV');
INSERT INTO Train VALUES (34, 'TGV');
INSERT INTO Train VALUES (45, 'TGV');
INSERT INTO Train VALUES (345, 'TER');
INSERT INTO Train VALUES (745, 'TER');
INSERT INTO Train VALUES (675, 'TER');
INSERT INTO Train VALUES (7, 'RER');

INSERT INTO Ligne VALUES (156, 'TGV');
INSERT INTO Ligne VALUES (27, 'TER');

INSERT INTO ArretLigne VALUES (1, 27, FALSE, 'Gare du Nord', 'Paris');
INSERT INTO ArretLigne VALUES (2, 27, FALSE, 'Gare ferroviaire', 'Creil');
INSERT INTO ArretLigne VALUES (3, 27, FALSE, 'Gare ferroviaire', 'Pont-Sainte-Maxence');
INSERT INTO ArretLigne VALUES (4, 27, FALSE, 'Gare ferroviaire', 'Compiegne');
INSERT INTO ArretLigne VALUES (5, 27, TRUE, 'Gare ferroviaire', 'Amiens');
INSERT INTO ArretLigne VALUES (1, 156, FALSE, 'Gare du Nord', 'Paris');
INSERT INTO ArretLigne VALUES (2, 156, TRUE, 'Gare Bruxelles-Midi', 'Bruxelles');

INSERT INTO Calendrier VALUES (1, '01/01/2020', '31/12/2022', '12:00:00', TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE);
INSERT INTO Calendrier VALUES (2, '24/11/1999', '14/02/2016', '18:00:00', TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE);
INSERT INTO Calendrier VALUES (3, '01/05/2017', '30/09/2025', '14:00:00', FALSE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE);

INSERT INTO DateException VALUES ('14/07/2021', FALSE);
INSERT INTO DateException VALUES ('07/05/2023', TRUE);

INSERT INTO ConcerneCalendrier VALUES ('14/07/2021', FALSE, 1);
INSERT INTO ConcerneCalendrier VALUES ('07/05/2023', TRUE, 3);

INSERT INTO Voyage VALUES (234, 27, 675, 1);
INSERT INTO Voyage VALUES (27, 156, 34, 2);

INSERT INTO ArretVoyage VALUES (1, 234, '12:00:00', '11:55:00', 1, 27);
INSERT INTO ArretVoyage VALUES (2, 234, '12:30:00', '12:28:00', 3, 27);
INSERT INTO ArretVoyage VALUES (3, 234, '13:05:00', '13:00:00', 4, 27);
INSERT INTO ArretVoyage VALUES (4, 234, '13:22:00', '13:20:00', 5, 27);
INSERT INTO ArretVoyage VALUES (1, 27, '18:00:00', '17:45:00', 1, 156);
INSERT INTO ArretVoyage VALUES (2, 27, '20:36:00', '20:27:00', 2, 156);

INSERT INTO Trajet VALUES (1, 23, '27/03/2021');
INSERT INTO Trajet VALUES (2, 57, '04/07/2020');
INSERT INTO Trajet VALUES (3, 567, '04/07/2020');

INSERT INTO ArretTrajet VALUES (1, 1, 234, TRUE);
INSERT INTO ArretTrajet VALUES (1, 3, 234, FALSE);
INSERT INTO ArretTrajet VALUES (2, 2, 234, TRUE);
INSERT INTO ArretTrajet VALUES (2, 4, 234, FALSE);
INSERT INTO ArretTrajet VALUES (3, 1, 27, TRUE);
INSERT INTO ArretTrajet VALUES (3, 2, 27, FALSE);

INSERT INTO Voyageur (nom, prenom, adresse, telephone, paiement, occasionnel) VALUES ('Beauchamp', 'Elisabeth', '45 rue de la République', '0765438729', 'carte', TRUE);
INSERT INTO Voyageur VALUES ('Smith', 'Henry', '288 avanue du Général de Gaulle', '0614263798', 'monnaie', 563, 'bronze', FALSE);

INSERT INTO Billet VALUES (1, FALSE, 34.70, 'Smith', 'Henry', '288 avanue du Général de Gaulle');
INSERT INTO Billet VALUES (2, TRUE, 9.45, 'Smith', 'Henry', '288 avanue du Général de Gaulle');

INSERT INTO CompositionBillet VALUES (1, 1);
INSERT INTO CompositionBillet VALUES (1, 2);
INSERT INTO CompositionBillet VALUES (2, 1);
