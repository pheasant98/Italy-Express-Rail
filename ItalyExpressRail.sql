-- phpMyAdmin SQL Dump
-- version 4.8.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Creato il: Lug 09, 2019 alle 02:36
-- Versione del server: 10.1.37-MariaDB
-- Versione PHP: 7.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `p`
--

DELIMITER $$
--
-- Procedure
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `InfoTreni` (IN `tipo` VARCHAR(250))  NO SQL
BEGIN

	CREATE TEMPORARY TABLE IF NOT EXISTS NCarr AS
    SELECT compone2.Treno AS C2T, COUNT(compone2.Carrozza) AS NCarrozze
    FROM compone2 JOIN carrozza ON compone2.Carrozza=carrozza.ID
    GROUP BY C2T;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS NManC AS
    SELECT compone2.Treno AS IDC, COUNT(manutenzione.ID) AS NManCarr 
    FROM (compone2 JOIN carrozza ON compone2.Carrozza= carrozza.ID )JOIN manutenzione ON carrozza.ID=manutenzione.Carrozza
    GROUP BY IDC;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS NManM AS
    SELECT compone1.Treno AS IDM, COUNT(manutenzione.ID) AS NManMotr 
    FROM (compone1 JOIN motrice ON compone1.Motrice= motrice.ID )JOIN manutenzione ON motrice.ID=manutenzione.Motrice
    GROUP BY IDM;
       
    SELECT treno.ID, treno.Tipo, NManC.NManCarr, NManM.NManMotr, NCarr.NCarrozze
    FROM ((treno JOIN NManC ON treno.ID=NManc.IDC) JOIN NCarr ON treno.ID=NCarr.C2T ) JOIN NManM ON treno.ID=NManM.IDM
    WHERE treno.Tipo = tipo
    GROUP BY treno.ID, treno.Tipo, NManC.NManCarr, NManM.NManMotr, NCarr.NCarrozze;
    
	DROP TABLE NCarr;
    DROP TABLE NManC;
    DROP TABLE NManM;

  
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ServiziAquistati` (IN `Nserv` INT, IN `Imp` FLOAT)  NO SQL
BEGIN

	CREATE TEMPORARY TABLE IF NOT EXISTS VistaApp1 AS                                                                                              	SELECT cliente.Codice_Fiscale AS CF, SUM(servizio.Prezzo) AS importo
		FROM (cliente JOIN servizio ON cliente.Codice_Fiscale=servizio.Cliente)JOIN biglietto ON servizio.Codice=biglietto.Codice
		WHERE MONTH(biglietto.Data_Validita)='08'
		GROUP BY cliente.Codice_Fiscale
		HAVING importo>Imp;


	SELECT cliente.Codice_Fiscale, cliente.Nome, cliente.Cognome, cliente.Recapito_Telefonico, cliente.Email
	FROM cliente JOIN servizio ON cliente.Codice_Fiscale=servizio.Cliente
	WHERE cliente.Numero_Servizi>Nserv AND cliente.Codice_Fiscale IN (SELECT CF FROM VistaApp1)
	GROUP BY  cliente.Codice_Fiscale, cliente.Nome, cliente.Cognome, cliente.Recapito_Telefonico, cliente.Email
    HAVING COUNT(*)>Nserv;
	DROP TABLE VistaApp1;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Tabellone` (IN `NomeS` VARCHAR(100), IN `Tfiltro1` TIME, IN `Tfiltro2` TIME)  NO SQL
BEGIN
	SELECT treno.Tipo, treno.ID, tratta.Stazione_Arrivo, CalRitardoTreno(treno.ID) as ritardo, fermata.Binario, PercorsoTratta(fermata.Numero, fermata.Tratta) as Percorso
    FROM (fermata JOIN tratta ON fermata.Tratta=tratta.ID) JOIN treno ON tratta.ID=treno.Percorso
    WHERE fermata.Stazione=NomeS AND fermata.Ferma='True' AND fermata.Orario_previsto BETWEEN Tfiltro1 AND Tfiltro2;
END$$

--
-- Funzioni
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CalRitardoTreno` (`idtr` INT(11)) RETURNS INT(11) NO SQL
BEGIN
    DECLARE diff INT(100);
    
    DECLARE UltOE TIME;
    DECLARE UltOP TIME;
    SET diff = 0;

    SELECT MAX(posizione.Orario_Effettivo) into UltOE 
    FROM posizione
    WHERE idtr=posizione.Treno;
    
    SELECT posizione.Orario_Previsto into UltOP
    FROM posizione
    WHERE idtr=posizione.Treno AND UltOE=posizione.Orario_Effettivo;
    
    IF(UltOE>UltOP)
    THEN
    	SET diff = TIMESTAMPDIFF(MINUTE,UltOP,UltOE);
    END IF;
    
    RETURN diff;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `PercorsoTratta` (`Npart` INT(100), `IDTratta` INT) RETURNS TEXT CHARSET latin1 NO SQL
BEGIN
    DECLARE Nferm INT(100);
    DECLARE str varchar(100);
    DECLARE staz varchar(100);
    DECLARE orario TIME;
    DECLARE i INT(100);
    
    SET str=" ";
    SET i=Npart;
    
    SELECT COUNT(fermata.Stazione) INTO Nferm
    FROM fermata
    WHERE fermata.Tratta=IDTratta;
    
    WHILE i<Nferm+1 DO
   		SELECT  fermata.Stazione, fermata.Orario_previsto INTO staz, orario 
        FROM fermata
        WHERE fermata.Tratta = IDTratta AND fermata.Numero = i;
        SET i = i + 1;
        SET str = CONCAT(str, " ",staz, " ", orario);
   END WHILE;
   
   RETURN str;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `abbonamento`
--

CREATE TABLE `abbonamento` (
  `Codice` int(11) NOT NULL,
  `Data_Inizio` date NOT NULL,
  `Data_Fine` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `abbonamento`
--

INSERT INTO `abbonamento` (`Codice`, `Data_Inizio`, `Data_Fine`) VALUES
(277336664, '2019-05-01', '2019-06-30'),
(716296106, '2019-07-01', '2019-07-31');

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `app1`
-- (Vedi sotto per la vista effettiva)
--
CREATE TABLE `app1` (
`TID` int(11)
,`Numero_di_checkpoint` bigint(21)
);

-- --------------------------------------------------------

--
-- Struttura della tabella `biglietto`
--

CREATE TABLE `biglietto` (
  `Codice` int(11) NOT NULL,
  `Data_Validita` date NOT NULL,
  `Carrozza` int(11) DEFAULT NULL,
  `Numero_posto` varchar(11) COLLATE utf8_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `biglietto`
--

INSERT INTO `biglietto` (`Codice`, `Data_Validita`, `Carrozza`, `Numero_posto`) VALUES
(119653124, '2019-08-05', NULL, NULL),
(141883551, '2019-08-08', 104013153, 'C1'),
(715551713, '2019-08-15', 104013153, 'B1'),
(777081045, '2019-08-07', NULL, NULL),
(886487058, '2019-04-01', NULL, NULL),
(996458878, '2019-04-01', NULL, NULL);

--
-- Trigger `biglietto`
--
DELIMITER $$
CREATE TRIGGER `ControlloeCreaPrenotazione` BEFORE INSERT ON `biglietto` FOR EACH ROW BEGIN
	DECLARE type varchar(100);
    DECLARE P INT(100);
    DECLARE PO INT(100);
	DECLARE ErrorCode CONDITION FOR SQLSTATE '45000';
    SET @err_mess = 'ERRORE RENOTAZIONE NON VALIDA';
    SET @err_mess2 = 'ERRORE PRENOTAZIONE NON VALIDA POSTI ESAURITI';
    
    IF(NEW.Carrozza IS NOT NULL)
    THEN
    	SELECT carrozza.Tipo INTO type 
        FROM carrozza 
        WHERE carrozza.ID=new.Carrozza;
        IF(type<> 'AltaVelocita')
        THEN
         	SIGNAL ErrorCode SET MESSAGE_TEXT=@err_mess;
            SET NEW.Carrozza=NULL;
            ELSE
            	SELECT carrozza.Tipo, carrozza.Posti, compone2.Posti_Occupati INTO type, P, PO
        		FROM (biglietto JOIN carrozza ON NEW.Carrozza=carrozza.ID) JOIN compone2 ON carrozza.ID= 					compone2.Carrozza
        		WHERE NEW.Codice=biglietto.Codice;

        		IF(P=PO)
        		THEN
         		SIGNAL ErrorCode SET MESSAGE_TEXT=@err_mess2;
                SET NEW.Carrozza=NULL;
                ELSE
                    UPDATE compone2 SET compone2.Posti_Occupati=compone2.Posti_Occupati+1
                    WHERE compone2.Carrozza=NEW.Carrozza;
        		END IF; 
        END IF;      
    END IF;  
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `carrozza`
--

CREATE TABLE `carrozza` (
  `ID` int(11) NOT NULL,
  `Posti` int(11) DEFAULT NULL,
  `Tipo` enum('Regionale','AltaVelocita') COLLATE utf8_bin NOT NULL DEFAULT 'Regionale'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `carrozza`
--

INSERT INTO `carrozza` (`ID`, `Posti`, `Tipo`) VALUES
(104013153, 50, 'AltaVelocita'),
(104013154, 50, 'AltaVelocita'),
(104013155, 50, 'AltaVelocita'),
(104013156, 50, 'AltaVelocita'),
(104013157, 50, 'AltaVelocita'),
(104013158, 50, 'AltaVelocita'),
(104013159, 50, 'AltaVelocita'),
(104013160, 50, 'AltaVelocita'),
(104013161, 50, 'AltaVelocita'),
(104013162, 50, 'AltaVelocita'),
(104013163, 50, 'AltaVelocita'),
(104013164, 50, 'AltaVelocita'),
(798614505, NULL, 'Regionale'),
(798614506, NULL, 'Regionale'),
(798614507, NULL, 'Regionale'),
(798614508, NULL, 'Regionale'),
(798614509, NULL, 'Regionale'),
(798614510, NULL, 'Regionale'),
(798614511, NULL, 'Regionale'),
(798614512, NULL, 'Regionale'),
(798614513, NULL, 'Regionale'),
(798614514, NULL, 'Regionale'),
(798614515, NULL, 'Regionale'),
(798614516, NULL, 'Regionale'),
(798614517, NULL, 'Regionale'),
(798614518, NULL, 'Regionale'),
(798614519, NULL, 'Regionale'),
(798614520, NULL, 'Regionale'),
(798614521, NULL, 'Regionale'),
(798614522, NULL, 'Regionale'),
(798614523, NULL, 'Regionale'),
(798614524, NULL, 'Regionale');

--
-- Trigger `carrozza`
--
DELIMITER $$
CREATE TRIGGER `Controllo` BEFORE INSERT ON `carrozza` FOR EACH ROW BEGIN

    IF(NEW.Tipo='Regionale')
    THEN
    	
   		SET NEW.Posti=NULL;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `checkpoint`
--

CREATE TABLE `checkpoint` (
  `ID` int(11) NOT NULL,
  `Nome` varchar(250) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `checkpoint`
--

INSERT INTO `checkpoint` (`ID`, `Nome`) VALUES
(100000001, 'Udine-Codroipo'),
(100000002, 'Codroipo-Casarsa'),
(100000003, 'Casarsa-Pordenone'),
(100000004, 'Pordenone-Sacile'),
(100000005, 'Sacile-Conegliano'),
(100000006, 'Conegliano-Spresiano'),
(100000007, 'Spresiano-Treviso'),
(100000008, 'Treviso-Mogliano'),
(100000009, 'Mogliano-Mestre'),
(100000010, 'Mestre-Venezia'),
(100000011, 'Mestre-Padova'),
(100000012, 'Padova-Vicenza'),
(100000013, 'Vicenza-San Bonifacio'),
(100000014, 'San Bonifacio-Verona1'),
(100000015, 'Verona2-Garda'),
(100000016, 'Garda-Brescia'),
(100000017, 'Brescia-MilanoC'),
(100000018, 'Brescia-MilanoPG'),
(100000019, 'Brescia-MilanoL'),
(100000020, 'Milano-Novara'),
(100000021, 'Novara-Torino'),
(100000022, 'Trieste-Gorizia'),
(100000023, 'Gorizia-Udine');

-- --------------------------------------------------------

--
-- Struttura della tabella `cliente`
--

CREATE TABLE `cliente` (
  `Codice_Fiscale` varchar(16) COLLATE utf8_bin NOT NULL,
  `Nome` varchar(250) COLLATE utf8_bin NOT NULL,
  `Cognome` varchar(250) COLLATE utf8_bin NOT NULL,
  `Indirizzo` varchar(250) COLLATE utf8_bin NOT NULL,
  `Email` varchar(250) COLLATE utf8_bin NOT NULL,
  `Numero_Servizi` int(10) NOT NULL,
  `Data_di_Nascita` date NOT NULL,
  `Sesso` enum('M','F') COLLATE utf8_bin NOT NULL DEFAULT 'M',
  `Citta_di_Nascita` varchar(250) COLLATE utf8_bin NOT NULL,
  `Citta_di_Residenza` varchar(250) COLLATE utf8_bin NOT NULL,
  `Recapito_Telefonico` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `cliente`
--

INSERT INTO `cliente` (`Codice_Fiscale`, `Nome`, `Cognome`, `Indirizzo`, `Email`, `Numero_Servizi`, `Data_di_Nascita`, `Sesso`, `Citta_di_Nascita`, `Citta_di_Residenza`, `Recapito_Telefonico`) VALUES
('AV89095966', 'Selene ', 'Lucciano', 'Strada Statale, 57', 'SeleneLucciano@rhyta.com', 3, '1982-06-05', 'F', 'Venezia', 'Mestre', 3393715867),
('JY72772979', 'Gisella', 'Pisani', 'Via Partenope, 4', 'GisellaPisani@jourrapide.com', 2, '1982-09-14', 'F', 'San Vittore', 'Forlì', 3393222831),
('LA55295925', 'Cupido ', 'Fallaci', 'Via Acrone, 134', 'CupidoFallaci@rhyta.com', 1, '1989-02-15', 'M', 'Alessandria', 'Oviglio', 3772383708),
('WO33356241', 'Gavino ', 'Udinesi', 'Via Castelfidardo, 33', 'GavinoUdinesi@rhyta.com', 2, '1989-05-11', 'M', 'Cosenza', 'Camarda Di Aprigliano', 3766783708);

-- --------------------------------------------------------

--
-- Struttura della tabella `compone1`
--

CREATE TABLE `compone1` (
  `Motrice` int(11) NOT NULL,
  `Treno` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `compone1`
--

INSERT INTO `compone1` (`Motrice`, `Treno`) VALUES
(342435205, 520865067),
(342435205, 595563421),
(342435205, 630334870),
(342435206, 520865067),
(342435206, 595563421),
(342435206, 630334870),
(586388964, 172466360),
(586388964, 738857728),
(586388965, 172466360),
(586388965, 738857728),
(586388966, 271652385),
(586388967, 271652385),
(586388967, 686340101),
(586388968, 371547191),
(586388968, 686340101),
(586388969, 371547191),
(586388970, 636444181),
(586388971, 636444181);

--
-- Trigger `compone1`
--
DELIMITER $$
CREATE TRIGGER `MotriceLibera` BEFORE INSERT ON `compone1` FOR EACH ROW BEGIN 
  DECLARE pp TIME;
    DECLARE ap TIME;
    DECLARE flag INT(100);
    DECLARE ErrorCode CONDITION FOR SQLSTATE '45000';
    SET @err_mess = 'inserimento non valido orario già assegnato';
    SET flag = 0;
    
        SELECT  tratta.Partenza_Previsto, tratta.Arrivo_Previsto INTO pp, ap 
        FROM (compone1 JOIN treno ON NEW.Treno=treno.ID) JOIN tratta ON treno.Percorso=tratta.ID LIMIT 1;

        SELECT COUNT(compone1.Treno) AS n INTO flag 
        FROM (compone1 JOIN treno ON compone1.Treno=treno.ID) JOIN tratta ON treno.Percorso=tratta.ID
        WHERE compone1.Motrice=NEW.Motrice AND (pp BETWEEN tratta.Partenza_Previsto AND tratta.Arrivo_Previsto OR ap BETWEEN tratta.Partenza_Previsto AND tratta.Arrivo_Previsto);

        IF(flag>0)
        THEN
            SIGNAL ErrorCode SET MESSAGE_TEXT=@err_mess;
        END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `compone2`
--

CREATE TABLE `compone2` (
  `Carrozza` int(11) NOT NULL,
  `Treno` int(11) NOT NULL,
  `Posti_Occupati` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `compone2`
--

INSERT INTO `compone2` (`Carrozza`, `Treno`, `Posti_Occupati`) VALUES
(104013153, 520865067, 2),
(104013154, 520865067, 0),
(104013154, 595563421, 0),
(104013155, 520865067, 0),
(104013155, 595563421, 0),
(104013156, 520865067, 0),
(104013156, 630334870, 0),
(104013157, 520865067, 0),
(104013157, 630334870, 0),
(104013158, 520865067, 0),
(104013158, 630334870, 0),
(104013159, 520865067, 0),
(104013159, 630334870, 0),
(104013160, 595563421, 0),
(104013160, 630334870, 0),
(104013161, 595563421, 0),
(104013161, 630334870, 0),
(104013162, 595563421, 0),
(104013162, 630334870, 0),
(104013163, 595563421, 0),
(104013164, 595563421, 0),
(798614505, 172466360, 0),
(798614506, 172466360, 0),
(798614506, 686340101, 0),
(798614507, 172466360, 0),
(798614508, 686340101, 0),
(798614509, 271652385, 0),
(798614509, 738857728, 0),
(798614510, 271652385, 0),
(798614510, 686340101, 0),
(798614512, 738857728, 0),
(798614514, 636444181, 0),
(798614514, 738857728, 0),
(798614515, 636444181, 0),
(798614516, 636444181, 0),
(798614517, 636444181, 0),
(798614518, 371547191, 0),
(798614519, 371547191, 0),
(798614519, 738857728, 0),
(798614520, 371547191, 0),
(798614521, 371547191, 0),
(798614522, 271652385, 0),
(798614523, 271652385, 0),
(798614523, 686340101, 0),
(798614524, 172466360, 0);

--
-- Trigger `compone2`
--
DELIMITER $$
CREATE TRIGGER `CarrozzaLibera` BEFORE INSERT ON `compone2` FOR EACH ROW BEGIN 
DECLARE pp TIME;
    DECLARE ap TIME;
    DECLARE flag INT(100);
    DECLARE ErrorCode CONDITION FOR SQLSTATE '45000';
    SET @err_mess = 'carrozza già assegnata';
    SET flag = 0;
    
        SELECT  tratta.Partenza_Previsto, tratta.Arrivo_Previsto INTO pp, ap 
        FROM (compone2 JOIN treno ON NEW.Treno=treno.ID) JOIN tratta ON treno.Percorso=tratta.ID LIMIT 1;

        SELECT COUNT(compone2.Treno) AS n INTO flag 
        FROM (compone2 JOIN treno ON compone2.Treno=treno.ID) JOIN tratta ON treno.Percorso=tratta.ID
        WHERE compone2.Carrozza=NEW.Carrozza AND (pp BETWEEN tratta.Partenza_Previsto AND tratta.Arrivo_Previsto OR ap BETWEEN tratta.Partenza_Previsto AND tratta.Arrivo_Previsto);

        IF(flag>0)
        THEN
            SIGNAL ErrorCode SET MESSAGE_TEXT=@err_mess;
        END IF;  
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `controlla`
--

CREATE TABLE `controlla` (
  `Controllore` varchar(16) COLLATE utf8_bin NOT NULL,
  `Treno` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `controlla`
--

INSERT INTO `controlla` (`Controllore`, `Treno`) VALUES
('AV89095967', 520865067),
('AV89095967', 595563421),
('AV89095967', 630334870),
('CN10311895', 172466360),
('CN10311895', 271652385),
('CN10311895', 520865067),
('IR98278258', 371547191),
('IR98278258', 595563421),
('JL30093254', 636444181),
('JL30093254', 686340101),
('JY72772977', 738857728);

--
-- Trigger `controlla`
--
DELIMITER $$
CREATE TRIGGER `OrarioLibero` BEFORE INSERT ON `controlla` FOR EACH ROW BEGIN 
    DECLARE pp TIME;
    DECLARE ap TIME;
    DECLARE flag INT(100);
    DECLARE ErrorCode CONDITION FOR SQLSTATE '45000';
    SET @err_mess = 'inserimento non valido orario già assegnato';
    SET flag = 0;
    
        SELECT tratta.Partenza_Previsto, tratta.Arrivo_Previsto INTO pp, ap 
        FROM (controlla JOIN treno ON NEW.Treno=treno.ID) JOIN tratta ON treno.Percorso=tratta.ID LIMIT 1;

        SELECT COUNT(controlla.Treno) AS n INTO flag 
        FROM (controlla JOIN treno ON controlla.Treno=treno.ID) JOIN tratta ON treno.Percorso=tratta.ID
        WHERE controlla.Controllore=NEW.Controllore AND (pp BETWEEN tratta.Partenza_Previsto AND tratta.Arrivo_Previsto OR ap BETWEEN tratta.Partenza_Previsto AND tratta.Arrivo_Previsto);

        IF(flag>0)
        THEN
            SIGNAL ErrorCode SET MESSAGE_TEXT=@err_mess;
        END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `controllore`
--

CREATE TABLE `controllore` (
  `Codice_Fiscale` varchar(16) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `controllore`
--

INSERT INTO `controllore` (`Codice_Fiscale`) VALUES
('AV89095967'),
('CN10311895'),
('IR98278258'),
('JL30093254'),
('JY72772977');

-- --------------------------------------------------------

--
-- Struttura della tabella `dipendente`
--

CREATE TABLE `dipendente` (
  `Codice_Fiscale` varchar(16) COLLATE utf8_bin NOT NULL,
  `Nome` varchar(250) COLLATE utf8_bin NOT NULL,
  `Cognome` varchar(250) COLLATE utf8_bin NOT NULL,
  `Indirizzo` varchar(250) COLLATE utf8_bin NOT NULL,
  `Email` varchar(250) COLLATE utf8_bin DEFAULT NULL,
  `Badge` int(10) NOT NULL,
  `Data_di_Nascita` date NOT NULL,
  `Sesso` enum('M','F') COLLATE utf8_bin NOT NULL DEFAULT 'M',
  `Citta_di_Nascita` varchar(250) COLLATE utf8_bin NOT NULL,
  `Citta_di_Residenza` varchar(250) COLLATE utf8_bin NOT NULL,
  `Recapito_Telefonico` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `dipendente`
--

INSERT INTO `dipendente` (`Codice_Fiscale`, `Nome`, `Cognome`, `Indirizzo`, `Email`, `Badge`, `Data_di_Nascita`, `Sesso`, `Citta_di_Nascita`, `Citta_di_Residenza`, `Recapito_Telefonico`) VALUES
(' BJ99655077', 'Rosaria ', 'Milanesi', 'Via Roma 4', 'RosariaMilanesi@rhyta.com', 1234546, '1987-12-04', 'F', 'Padova', 'Legnaro', 3247957547),
(' VV86947180', 'Ermenegildo ', 'Lucchese', 'Piazza Guglielmo Pepe, 116', 'ErmenegildoLucchese@armyspy.com', 1328904, '1983-11-07', 'M', 'Macerata', 'Recanati ', 3393712434),
('AV89095967', 'Manuele ', 'Marchesi', 'Via Nizza, 21', 'ManueleMarchesi@armyspy.com', 5445687, '1982-06-20', 'M', 'Treviso', 'Semonzo', 3614151409),
('CN10311895', 'Girolamo ', 'Pinto', 'Via Tuscolana, 30', 'GirolamoPinto@libero.it', 2367989, '1973-10-12', 'M', 'Roma', 'Centocelle', 3635079844),
('IR98278258', 'Sandra ', 'Siciliano', 'Via Gaetano Donizetti, 75', 'SandraSiciliano@dayrep.com', 3486578, '1978-02-23', 'F', 'Verona', 'Mena\' Vallestrema', 3321433166),
('JL30093254', 'Pia ', 'Conti', 'Via Piave, 46', 'PiaConti@rhyta.com', 4635632, '1969-05-20', 'F', 'Chieti', 'Fallo', 3832354307),
('JY72772977', 'Aurelia ', 'Pisano', 'Via Adua, 98', '\r\nAureliaPisano@armyspy.com', 8976128, '1976-01-30', 'F', 'Terni', 'Vigne Di Narni ', 3498221431),
('LA5529592', 'Emma ', 'Manna', 'Corso Como 4', 'EmmaManna@rhyta.com', 3458972, '1986-03-16', 'F', 'Milano', 'Milano', 3777783708),
('NM37200903', 'Ermenegildo ', 'Lo Duca', 'Via delle Azalee, 89', 'ErmenegildoLoDuca@gmail.com', 6543480, '1982-09-11', 'M', 'Alessandria', 'Isola Sant\'Antonio', 3321009166),
('RB24957164', 'Edmondo ', 'Siciliano', 'Viale Augusto, 65', 'EdmondoSiciliano@teleworm.us', 7684540, '1985-05-06', 'M', 'Lecce', 'Bagnolo Del Salento', 3391095831),
('RP18764786', 'Adalgisa ', 'Lombardi', 'Piazza della Repubblica, 10', 'AdalgisaLombardi@dayrep.com', 8793414, '1984-06-30', 'F', 'Cosenza', 'Feroleto Antico', 3328699166),
('WO33356240', 'Aloisia ', 'Russo', 'Via Nazionale, 108', 'AloisiaRusso@outlook.it', 6780901, '1988-04-29', 'F', 'Bolzano', 'Tramin an der Weinstrasse ', 3942178251),
('WW59192009', 'Gianni ', 'Milanesi', 'Via Acrone, 108', 'GianniMilanesi@rhyta.com', 7965445, '1962-09-04', 'M', 'Alessandria', 'Ovada', 3393715831),
('XY60733275', 'Facondo', 'Ferrari', 'Via Torre di Mezzavia, 67', 'FacondoFerrari@jourrapide.com', 7895332, '1975-12-19', 'M', 'Como', 'Albese ', 3398342434),
('YF918067922', 'Samuele', 'Rossi', 'Via Stadera, 115\r\n', 'SamueleRossi@teleworm.us', 2124214, '1971-08-27', 'M', 'Perugia', 'Muraglione', 3220566216);

-- --------------------------------------------------------

--
-- Struttura della tabella `effettua`
--

CREATE TABLE `effettua` (
  `Operaio` varchar(16) COLLATE utf8_bin NOT NULL,
  `Manutenzione` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `effettua`
--

INSERT INTO `effettua` (`Operaio`, `Manutenzione`) VALUES
(' BJ99655077', 316821254),
(' BJ99655077', 316821255),
('WO33356240', 316821254),
('WW59192009', 316821263),
('XY60733275', 316821255);

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `elencooperai`
-- (Vedi sotto per la vista effettiva)
--
CREATE TABLE `elencooperai` (
`Codice_Fiscale` varchar(16)
,`Nome` varchar(250)
,`Cognome` varchar(250)
,`Recapito_Telefonico` double
,`Email` varchar(250)
,`Tratta` int(11)
);

-- --------------------------------------------------------

--
-- Struttura della tabella `fermata`
--

CREATE TABLE `fermata` (
  `Tratta` int(11) NOT NULL,
  `Stazione` varchar(250) COLLATE utf8_bin NOT NULL,
  `Ferma` enum('True','False') COLLATE utf8_bin NOT NULL,
  `Binario` int(11) NOT NULL,
  `Numero` int(11) NOT NULL,
  `Orario_previsto` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `fermata`
--

INSERT INTO `fermata` (`Tratta`, `Stazione`, `Ferma`, `Binario`, `Numero`, `Orario_previsto`) VALUES
(30000000, 'Venezia-Mestre', 'True', 1, 1, '13:20:00'),
(39124890, 'Carsarsa', 'False', 2, 2, '06:22:00'),
(39124890, 'Codroipo', 'False', 2, 1, '06:12:00'),
(39124890, 'Conegliano', 'True', 4, 5, '06:45:00'),
(39124890, 'Mogliano Veneto', 'False', 2, 8, '07:41:00'),
(39124890, 'Pordenone', 'True', 4, 3, '06:33:00'),
(39124890, 'Sacile', 'True', 3, 4, '06:40:00'),
(39124890, 'Spresiano', 'False', 2, 6, '07:02:00'),
(39124890, 'Treviso Centrale', 'True', 5, 7, '07:21:00'),
(39124890, 'Venezia-Mestre', 'True', 4, 9, '07:49:00'),
(40004890, 'Novara', 'True', 5, 1, '13:55:00'),
(40004890, 'Torino Porta Susa', 'True', 4, 2, '14:48:00'),
(40115801, 'Brescia', 'True', 7, 8, '20:38:00'),
(40115801, 'Padova', 'True', 2, 2, '19:22:00'),
(40115801, 'Peschiera del Garda', 'False', 1, 7, '20:19:00'),
(40115801, 'San Bonifacio', 'False', 1, 4, '19:46:00'),
(40115801, 'Venezia-Mestre', 'True', 6, 1, '19:13:00'),
(40115801, 'Verona Porta Nuova', 'True', 9, 6, '20:04:00'),
(40115801, 'Verona Porta Vescova', 'False', 2, 5, '19:58:00'),
(40115801, 'Vicenza', 'True', 2, 3, '19:34:00'),
(45658101, 'Carsarsa', 'True', 2, 2, '10:22:00'),
(45658101, 'Codroipo', 'True', 2, 1, '10:12:00'),
(45658101, 'Conegliano', 'True', 4, 5, '10:45:00'),
(45658101, 'Mogliano Veneto', 'True', 2, 8, '11:41:00'),
(45658101, 'Pordenone', 'True', 4, 3, '10:33:00'),
(45658101, 'Sacile', 'True', 3, 4, '10:40:00'),
(45658101, 'Spresiano', 'True', 2, 6, '11:02:00'),
(45658101, 'Treviso Centrale', 'True', 5, 7, '11:21:00'),
(45658101, 'Venezia-Mestre', 'True', 4, 9, '11:49:00'),
(47881601, 'Carsarsa', 'False', 2, 4, '11:30:00'),
(47881601, 'Codroipo', 'False', 2, 3, '11:23:00'),
(47881601, 'Conegliano', 'True', 3, 7, '12:02:00'),
(47881601, 'Gorizia Centrale', 'True', 3, 1, '10:50:00'),
(47881601, 'Mogliano Veneto', 'True', 2, 10, '12:31:00'),
(47881601, 'Pordenone', 'True', 3, 5, '11:46:00'),
(47881601, 'Sacile', 'True', 4, 6, '11:54:00'),
(47881601, 'Spresiano', 'False', 2, 8, '12:12:00'),
(47881601, 'Treviso Centrale', 'True', 4, 9, '12:22:00'),
(47881601, 'Udine', 'True', 4, 2, '11:15:00'),
(47881601, 'Venezia-Mestre', 'True', 6, 11, '12:41:00'),
(49644418, 'Carsarsa', 'True', 2, 2, '15:22:00'),
(49644418, 'Codroipo', 'True', 2, 1, '15:12:00'),
(49644418, 'Conegliano', 'True', 4, 5, '15:45:00'),
(49644418, 'Mogliano Veneto', 'True', 2, 8, '16:41:00'),
(49644418, 'Pordenone', 'True', 4, 3, '15:33:00'),
(49644418, 'Sacile', 'True', 3, 4, '15:40:00'),
(49644418, 'Spresiano', 'True', 2, 6, '16:02:00'),
(49644418, 'Treviso Centrale', 'True', 5, 7, '16:21:00'),
(60089610, 'Brescia', 'True', 7, 8, '21:19:00'),
(60089610, 'Padova', 'True', 2, 2, '18:28:00'),
(60089610, 'Peschiera del Garda', 'True', 1, 7, '20:51:00'),
(60089610, 'San Bonifacio', 'True', 1, 4, '19:06:00'),
(60089610, 'Venezia-Mestre', 'True', 6, 1, '18:18:00'),
(60089610, 'Verona Porta Nuova', 'True', 9, 6, '20:34:00'),
(60089610, 'Verona Porta Vescova', 'True', 2, 5, '20:22:00'),
(60089610, 'Vicenza', 'True', 2, 3, '18:40:00'),
(88226272, 'Carsarsa', 'False', 1, 8, '08:35:00'),
(88226272, 'Codroipo', 'False', 1, 9, '08:46:00'),
(88226272, 'Conegliano', 'True', 3, 5, '08:02:00'),
(88226272, 'Mogliano Veneto', 'True', 1, 2, '07:25:00'),
(88226272, 'Pordenone', 'True', 8, 7, '08:24:00'),
(88226272, 'Sacile', 'True', 5, 6, '08:12:00'),
(88226272, 'Spresiano', 'False', 1, 4, '07:48:00'),
(88226272, 'Treviso Centrale', 'True', 7, 3, '07:36:00'),
(88226272, 'Venezia-Mestre', 'True', 8, 1, '07:14:00');

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `grandistazioni`
-- (Vedi sotto per la vista effettiva)
--
CREATE TABLE `grandistazioni` (
`Nome` varchar(250)
,`Citta` varchar(250)
,`Indirizzo` varchar(250)
);

-- --------------------------------------------------------

--
-- Struttura della tabella `guida`
--

CREATE TABLE `guida` (
  `Macchinista` varchar(16) COLLATE utf8_bin NOT NULL,
  `Treno` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `guida`
--

INSERT INTO `guida` (`Macchinista`, `Treno`) VALUES
(' VV86947180', 686340101),
(' VV86947180', 738857728),
('LA5529592', 520865067),
('LA5529592', 595563421),
('NM37200903', 172466360),
('NM37200903', 271652385),
('NM37200903', 371547191),
('RB24957164', 636444181),
('RP18764786', 630334870);

--
-- Trigger `guida`
--
DELIMITER $$
CREATE TRIGGER `OrarioLibero2` BEFORE INSERT ON `guida` FOR EACH ROW BEGIN
DECLARE pp TIME;
    DECLARE ap TIME;
    DECLARE flag INT(100);
    DECLARE ErrorCode CONDITION FOR SQLSTATE '45000';
    SET @err_mess = 'inserimento non valido orario già assegnato';
    SET flag = 0;
    
        SELECT tratta.Partenza_Previsto, tratta.Arrivo_Previsto INTO pp, ap 
        FROM (guida JOIN treno ON NEW.Treno=treno.ID) JOIN tratta ON treno.Percorso=tratta.ID LIMIT 1;
        
        IF(0<(SELECT COUNT(guida.Treno)
        FROM (guida JOIN treno ON guida.Treno=treno.ID) JOIN tratta ON treno.Percorso=tratta.ID
        WHERE guida.Macchinista=NEW.Macchinista AND (pp BETWEEN tratta.Partenza_Previsto AND tratta.Arrivo_Previsto OR ap BETWEEN tratta.Partenza_Previsto AND tratta.Arrivo_Previsto)))
        THEN
            SIGNAL ErrorCode SET MESSAGE_TEXT=@err_mess;
        END IF;
       
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `macchinista`
--

CREATE TABLE `macchinista` (
  `Codice_Fiscale` varchar(16) COLLATE utf8_bin NOT NULL,
  `Anno_Scadenza_Patente` year(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `macchinista`
--

INSERT INTO `macchinista` (`Codice_Fiscale`, `Anno_Scadenza_Patente`) VALUES
(' VV86947180', 2020),
('LA5529592', 2024),
('NM37200903', 2022),
('RB24957164', 2023),
('RP18764786', 2020);

-- --------------------------------------------------------

--
-- Struttura della tabella `manutenzione`
--

CREATE TABLE `manutenzione` (
  `ID` int(11) NOT NULL,
  `DataR` date NOT NULL,
  `Descrizione` varchar(250) COLLATE utf8_bin NOT NULL,
  `Carrozza` int(11) DEFAULT NULL,
  `Motrice` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `manutenzione`
--

INSERT INTO `manutenzione` (`ID`, `DataR`, `Descrizione`, `Carrozza`, `Motrice`) VALUES
(316821254, '2019-05-21', 'Saldatura motore', NULL, 342435206),
(316821255, '2019-03-11', 'Cambio freni', NULL, 342435205),
(316821256, '2019-06-10', 'Cambio porte', 798614520, NULL),
(316821257, '2019-06-17', 'Cambio luci', 798614520, NULL),
(316821258, '2019-06-23', 'Cambio freni', 798614506, NULL),
(316821259, '2019-03-11', 'Cambio sedili', 798614509, NULL),
(316821260, '2019-06-14', 'Cambio finestrino', 104013163, NULL),
(316821261, '2019-04-08', 'Verniciatura', 104013159, NULL),
(316821262, '2019-06-05', 'Cambio freni', NULL, 586388966),
(316821263, '2019-04-09', 'Cambio luci', NULL, 586388968),
(316821264, '2019-07-02', 'Cambio spazzole', NULL, 586388970);

-- --------------------------------------------------------

--
-- Struttura della tabella `motrice`
--

CREATE TABLE `motrice` (
  `ID` int(11) NOT NULL,
  `Tipo_Motore` varchar(250) COLLATE utf8_bin NOT NULL,
  `Modello` varchar(250) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `motrice`
--

INSERT INTO `motrice` (`ID`, `Tipo_Motore`, `Modello`) VALUES
(342435205, 'Elettrico', 'Express'),
(342435206, 'Elettrico', 'Express'),
(586388964, 'Elettrico', 'Vivalto'),
(586388965, 'Elettrico', 'Vivalto'),
(586388966, 'Elettrico', 'Vivalto'),
(586388967, 'Elettrico', 'Vivalto'),
(586388968, 'Elettrico', 'Vivalto'),
(586388969, 'Elettrico', 'Vivalto'),
(586388970, 'Elettrico', 'Vivalto'),
(586388971, 'Elettrico', 'Vivalto');

-- --------------------------------------------------------

--
-- Struttura della tabella `operaio`
--

CREATE TABLE `operaio` (
  `Codice_Fiscale` varchar(16) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `operaio`
--

INSERT INTO `operaio` (`Codice_Fiscale`) VALUES
(' BJ99655077'),
('WO33356240'),
('WW59192009'),
('XY60733275'),
('YF918067922');

-- --------------------------------------------------------

--
-- Struttura della tabella `posizione`
--

CREATE TABLE `posizione` (
  `Treno` int(11) NOT NULL,
  `Check_Point` int(11) NOT NULL,
  `Orario_Effettivo` time DEFAULT NULL,
  `Orario_Previsto` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `posizione`
--

INSERT INTO `posizione` (`Treno`, `Check_Point`, `Orario_Effettivo`, `Orario_Previsto`) VALUES
(172466360, 100000001, NULL, '08:44:00'),
(172466360, 100000002, NULL, '08:39:00'),
(172466360, 100000003, NULL, '08:29:00'),
(172466360, 100000004, NULL, '08:16:00'),
(172466360, 100000005, NULL, '08:05:00'),
(172466360, 100000006, NULL, '07:54:00'),
(172466360, 100000007, NULL, '07:43:00'),
(172466360, 100000008, NULL, '07:29:00'),
(172466360, 100000009, NULL, '07:18:00'),
(172466360, 100000010, '07:12:00', '07:07:00'),
(271652385, 100000001, NULL, '15:10:00'),
(271652385, 100000002, NULL, '15:17:00'),
(271652385, 100000003, NULL, '15:28:00'),
(271652385, 100000004, NULL, '15:37:00'),
(271652385, 100000005, NULL, '15:43:00'),
(271652385, 100000006, NULL, '15:50:00'),
(271652385, 100000007, NULL, '16:10:00'),
(271652385, 100000008, NULL, '16:35:00'),
(271652385, 100000009, NULL, '16:45:00'),
(271652385, 100000010, NULL, '16:53:00'),
(371547191, 100000001, NULL, '11:20:00'),
(371547191, 100000002, NULL, '11:27:00'),
(371547191, 100000003, NULL, '11:40:00'),
(371547191, 100000004, NULL, '11:49:00'),
(371547191, 100000005, NULL, '11:58:00'),
(371547191, 100000006, NULL, '12:04:00'),
(371547191, 100000007, NULL, '12:12:00'),
(371547191, 100000008, NULL, '12:26:00'),
(371547191, 100000009, NULL, '12:35:00'),
(371547191, 100000010, NULL, '12:41:00'),
(371547191, 100000022, NULL, '10:45:00'),
(371547191, 100000023, NULL, '11:02:00'),
(520865067, 100000010, NULL, '19:10:00'),
(520865067, 100000011, NULL, '19:18:00'),
(520865067, 100000012, NULL, '19:30:00'),
(520865067, 100000013, NULL, '19:40:00'),
(520865067, 100000014, NULL, '19:50:00'),
(520865067, 100000015, NULL, '20:10:00'),
(520865067, 100000016, NULL, '20:30:00'),
(520865067, 100000017, NULL, '20:50:00'),
(595563421, 100000001, '06:10:00', '06:08:00'),
(595563421, 100000002, '06:15:00', '06:15:00'),
(595563421, 100000003, '06:26:00', '06:25:00'),
(595563421, 100000004, '06:39:00', '06:37:00'),
(595563421, 100000005, '06:44:00', '06:43:00'),
(595563421, 100000006, '07:01:00', '06:50:00'),
(595563421, 100000007, NULL, '07:10:00'),
(595563421, 100000008, NULL, '07:35:00'),
(595563421, 100000009, NULL, '07:45:00'),
(595563421, 100000010, NULL, '07:53:00'),
(630334870, 100000020, NULL, '13:05:00'),
(630334870, 100000021, NULL, '14:20:00'),
(636444181, 100000001, NULL, '10:10:00'),
(636444181, 100000002, NULL, '10:18:00'),
(636444181, 100000003, NULL, '10:26:00'),
(636444181, 100000004, NULL, '10:35:00'),
(636444181, 100000005, NULL, '10:43:00'),
(636444181, 100000006, NULL, '10:56:00'),
(636444181, 100000007, NULL, '11:10:00'),
(636444181, 100000008, NULL, '11:27:00'),
(636444181, 100000009, NULL, '11:47:00'),
(636444181, 100000010, NULL, '11:52:00'),
(686340101, 100000010, NULL, '18:11:00'),
(686340101, 100000011, NULL, '18:22:00'),
(686340101, 100000012, NULL, '18:31:00'),
(686340101, 100000013, NULL, '18:59:00'),
(686340101, 100000014, NULL, '20:02:00'),
(686340101, 100000015, NULL, '20:42:00'),
(686340101, 100000016, NULL, '21:03:00'),
(686340101, 100000019, NULL, '21:28:00'),
(738857728, 100000010, NULL, '13:25:00'),
(738857728, 100000011, NULL, '13:15:00');

-- --------------------------------------------------------

--
-- Struttura della tabella `servizio`
--

CREATE TABLE `servizio` (
  `Codice` int(11) NOT NULL,
  `Costo_per_km` double NOT NULL,
  `Numero_km_percorsi` int(11) NOT NULL,
  `Cliente` varchar(250) COLLATE utf8_bin NOT NULL,
  `Prezzo` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `servizio`
--

INSERT INTO `servizio` (`Codice`, `Costo_per_km`, `Numero_km_percorsi`, `Cliente`, `Prezzo`) VALUES
(119653124, 0.26, 57, 'JY72772979', 14.82),
(141883551, 1.2, 86, 'WO33356241', 103.2),
(277336664, 1.8, 50, 'AV89095966', 90),
(715551713, 0.2, 258, 'LA55295925', 51.6),
(716296106, 0.25, 214, 'WO33356241', 53.5),
(777081045, 0.4, 14, 'JY72772979', 5.6000000000000005),
(886487058, 0.3, 20, 'AV89095966', 6),
(996458878, 0.24, 50, 'AV89095966', 12);

--
-- Trigger `servizio`
--
DELIMITER $$
CREATE TRIGGER `CalcolaPrezzoUP` BEFORE UPDATE ON `servizio` FOR EACH ROW BEGIN
	SET new.Prezzo=new.Costo_per_km*new.Numero_km_percorsi;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `CalcoloPrezzoINS` BEFORE INSERT ON `servizio` FOR EACH ROW BEGIN 
	SET new.Prezzo=new.Costo_per_km*new.Numero_km_percorsi;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `stazione`
--

CREATE TABLE `stazione` (
  `Nome` varchar(250) COLLATE utf8_bin NOT NULL,
  `Citta` varchar(250) COLLATE utf8_bin NOT NULL,
  `Indirizzo` varchar(250) COLLATE utf8_bin NOT NULL,
  `Numero_Binari` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `stazione`
--

INSERT INTO `stazione` (`Nome`, `Citta`, `Indirizzo`, `Numero_Binari`) VALUES
('Brescia', 'Breascia', 'Viale Europa', 10),
('Carsarsa', 'Carsarsa', 'Via stazione', 2),
('Codroipo', 'Codroipo', 'Via stazione', 2),
('Conegliano', 'Conegliano', 'Via Europa', 5),
('Gorizia Centrale', 'Gorizia', 'viale stazione', 7),
('Milano Centrale', 'Milano', 'Piazzale Duca d\'Aosta', 24),
('Milano Lambrate', 'Milano', 'Viale Lambrate', 12),
('Milano Porta Garibaldi', 'Milano', 'Viale Porta Garibaldi', 20),
('Mogliano Veneto', 'Mogliano Veneto', 'Via stazione', 2),
('Novara', 'Novara', 'Vaile stazione', 5),
('Padova', 'Padova', 'Piazzale della stazione', 12),
('Peschiera del Garda', 'Peschiera del Garda', 'Via Garda', 5),
('Pordenone', 'Pordenone', 'Via Pola', 9),
('Sacile', 'Sacile', 'Via stazione', 6),
('San Bonifacio', 'San Bonifacio', 'Via stazione', 3),
('Spresiano', 'Spresiano', 'Via Tagliamento', 3),
('Torino Porta Nuova', 'Torino', 'Viale europa', 20),
('Torino Porta Susa', 'Torino', 'Viale stazione', 5),
('Treviso Centrale', 'Treviso', 'Viale Europa', 9),
('Trieste Centrale', 'Trieste', 'Piazzale della Liberta\'', 20),
('Udine', 'Udine', 'Viale Europa', 12),
('Venezia S. Lucia', 'Venezia', 'Viale Stazione', 21),
('Venezia-Mestre', 'Mestre', 'Viale Stazione', 12),
('Verona Porta Nuova', 'Verona', 'Via Stazione', 20),
('Verona Porta Vescova', 'Verona', 'Viale stazione porta vescovo', 5),
('Vicenza', 'Vicenza', 'Viale Europa', 8);

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `straordinariot`
-- (Vedi sotto per la vista effettiva)
--
CREATE TABLE `straordinariot` (
`ID` int(11)
,`Data_Inizio` date
,`Data_Fine` date
,`Numero_di_checkpoint` bigint(21)
,`Stazione_Partenza` varchar(250)
,`Partenza_Previsto` time
,`Percorso` text
,`Stazione_Arrivo` varchar(250)
,`Arrivo_Previsto` time
);

-- --------------------------------------------------------

--
-- Struttura della tabella `transito`
--

CREATE TABLE `transito` (
  `Stazione` varchar(250) COLLATE utf8_bin NOT NULL,
  `Servizio` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `transito`
--

INSERT INTO `transito` (`Stazione`, `Servizio`) VALUES
('Conegliano', 119653124),
('Conegliano', 716296106),
('Conegliano', 777081045),
('Milano Porta Garibaldi', 141883551),
('Milano Porta Garibaldi', 715551713),
('Padova', 277336664),
('Padova', 716296106),
('Padova', 996458878),
('Spresiano', 777081045),
('Treviso Centrale', 277336664),
('Treviso Centrale', 715551713),
('Treviso Centrale', 886487058),
('Treviso Centrale', 996458878),
('Venezia S. Lucia', 119653124),
('Venezia S. Lucia', 886487058),
('Venezia-Mestre', 141883551);

-- --------------------------------------------------------

--
-- Struttura della tabella `tratta`
--

CREATE TABLE `tratta` (
  `ID` int(11) NOT NULL,
  `Partenza_Previsto` time NOT NULL,
  `Arrivo_Previsto` time NOT NULL,
  `Data_Inizio` date DEFAULT NULL,
  `Data_Fine` date DEFAULT NULL,
  `Straordinario` enum('True','False','','') COLLATE utf8_bin NOT NULL DEFAULT 'False',
  `Binario_Partenza` int(11) NOT NULL,
  `Binario_Arrivo` int(11) NOT NULL,
  `Stazione_Partenza` varchar(250) COLLATE utf8_bin NOT NULL,
  `Stazione_Arrivo` varchar(250) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `tratta`
--

INSERT INTO `tratta` (`ID`, `Partenza_Previsto`, `Arrivo_Previsto`, `Data_Inizio`, `Data_Fine`, `Straordinario`, `Binario_Partenza`, `Binario_Arrivo`, `Stazione_Partenza`, `Stazione_Arrivo`) VALUES
(30000000, '13:02:00', '13:28:00', '2019-05-01', '2019-07-31', 'True', 7, 14, 'Padova', 'Venezia S. Lucia'),
(39124890, '06:00:00', '07:55:00', NULL, NULL, 'False', 4, 9, 'Udine', 'Venezia S. Lucia'),
(40004890, '12:07:00', '14:55:00', NULL, NULL, 'False', 16, 18, 'Milano Centrale', 'Torino Porta Nuova'),
(40115801, '19:06:00', '20:57:00', NULL, NULL, 'False', 15, 11, 'Venezia S. Lucia', 'Milano Porta Garibaldi'),
(45658101, '15:07:00', '16:55:00', NULL, NULL, 'False', 5, 3, 'Udine', 'Venezia S. Lucia'),
(47881601, '10:40:00', '12:46:00', NULL, NULL, 'False', 6, 8, 'Trieste Centrale', 'Venezia S. Lucia'),
(49644418, '10:07:00', '11:55:00', NULL, NULL, 'False', 2, 9, 'Udine', 'Venezia-Mestre'),
(60089610, '18:03:00', '21:35:00', NULL, NULL, 'False', 17, 9, 'Venezia S. Lucia', 'Milano Lambrate'),
(88226272, '07:04:00', '08:55:00', NULL, NULL, 'False', 8, 1, 'Venezia S. Lucia', 'Udine');

--
-- Trigger `tratta`
--
DELIMITER $$
CREATE TRIGGER `VerStraordinario` BEFORE INSERT ON `tratta` FOR EACH ROW BEGIN
    IF(NEW.Straordinario='False') 
    THEN
    	SET NEW.Data_Inizio=NULL;
    	SET NEW.Data_Fine=NULL;  
	END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `treno`
--

CREATE TABLE `treno` (
  `ID` int(11) NOT NULL,
  `Tipo` enum('Regionale','AltaVelocita') COLLATE utf8_bin NOT NULL,
  `Percorso` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `treno`
--

INSERT INTO `treno` (`ID`, `Tipo`, `Percorso`) VALUES
(172466360, 'Regionale', 88226272),
(271652385, 'Regionale', 45658101),
(371547191, 'Regionale', 47881601),
(520865067, 'AltaVelocita', 40115801),
(595563421, 'AltaVelocita', 39124890),
(630334870, 'AltaVelocita', 40004890),
(636444181, 'Regionale', 49644418),
(686340101, 'Regionale', 60089610),
(738857728, 'Regionale', 30000000);

-- --------------------------------------------------------

--
-- Struttura per vista `app1`
--
DROP TABLE IF EXISTS `app1`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `app1`  AS  select `tratta`.`ID` AS `TID`,count(`posizione`.`Check_Point`) AS `Numero_di_checkpoint` from ((`tratta` join `treno` on((`tratta`.`ID` = `treno`.`Percorso`))) join `posizione` on((`treno`.`ID` = `posizione`.`Treno`))) group by `tratta`.`ID` ;

-- --------------------------------------------------------

--
-- Struttura per vista `elencooperai`
--
DROP TABLE IF EXISTS `elencooperai`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `elencooperai`  AS  select `dipendente`.`Codice_Fiscale` AS `Codice_Fiscale`,`dipendente`.`Nome` AS `Nome`,`dipendente`.`Cognome` AS `Cognome`,`dipendente`.`Recapito_Telefonico` AS `Recapito_Telefonico`,`dipendente`.`Email` AS `Email`,`tratta`.`ID` AS `Tratta` from (((((((`dipendente` join `operaio` on((`dipendente`.`Codice_Fiscale` = `operaio`.`Codice_Fiscale`))) join `effettua` on((`operaio`.`Codice_Fiscale` = `effettua`.`Operaio`))) join `manutenzione` on((`effettua`.`Manutenzione` = `manutenzione`.`ID`))) join `motrice` on((`manutenzione`.`Motrice` = `motrice`.`ID`))) join `compone1` on((`motrice`.`ID` = `compone1`.`Motrice`))) join `treno` on((`compone1`.`Treno` = `treno`.`ID`))) join `tratta` on((`treno`.`Percorso` = `tratta`.`ID`))) where ((`manutenzione`.`Descrizione` = 'Saldatura motore') and (`tratta`.`ID` in (select `tratta`.`ID` from `tratta` where (`tratta`.`Stazione_Partenza` like 'Milano%')) or `tratta`.`ID` in (select `tratta`.`ID` from `tratta` where (`tratta`.`Stazione_Arrivo` like 'Milano%')) or `tratta`.`ID` in (select `tratta`.`ID` from (`tratta` join `fermata` on((`tratta`.`ID` = `fermata`.`Tratta`))) where (`fermata`.`Stazione` like 'Milano%')))) order by `dipendente`.`Cognome`,`dipendente`.`Nome` ;

-- --------------------------------------------------------

--
-- Struttura per vista `grandistazioni`
--
DROP TABLE IF EXISTS `grandistazioni`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `grandistazioni`  AS  select `stazione`.`Nome` AS `Nome`,`stazione`.`Citta` AS `Citta`,`stazione`.`Indirizzo` AS `Indirizzo` from `stazione` where (`stazione`.`Nome` in (select `stazione`.`Nome` from (`stazione` join `tratta` on((`stazione`.`Nome` = `tratta`.`Stazione_Partenza`))) group by `stazione`.`Nome` having (count(0) >= 2)) and `stazione`.`Nome` in (select `stazione`.`Nome` from (`stazione` join `tratta` on((`stazione`.`Nome` = `tratta`.`Stazione_Arrivo`))) group by `stazione`.`Nome` having (count(0) >= 3))) ;

-- --------------------------------------------------------

--
-- Struttura per vista `straordinariot`
--
DROP TABLE IF EXISTS `straordinariot`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `straordinariot`  AS  select `tratta`.`ID` AS `ID`,`tratta`.`Data_Inizio` AS `Data_Inizio`,`tratta`.`Data_Fine` AS `Data_Fine`,`app1`.`Numero_di_checkpoint` AS `Numero_di_checkpoint`,`tratta`.`Stazione_Partenza` AS `Stazione_Partenza`,`tratta`.`Partenza_Previsto` AS `Partenza_Previsto`,`PercorsoTratta`(1,`tratta`.`ID`) AS `Percorso`,`tratta`.`Stazione_Arrivo` AS `Stazione_Arrivo`,`tratta`.`Arrivo_Previsto` AS `Arrivo_Previsto` from (`tratta` join `app1` on((`tratta`.`ID` = `app1`.`TID`))) where (`tratta`.`Straordinario` = 'True') ;

--
-- Indici per le tabelle scaricate
--

--
-- Indici per le tabelle `abbonamento`
--
ALTER TABLE `abbonamento`
  ADD PRIMARY KEY (`Codice`);

--
-- Indici per le tabelle `biglietto`
--
ALTER TABLE `biglietto`
  ADD PRIMARY KEY (`Codice`),
  ADD KEY `FK_CARROZZA_CARROZZA_ID` (`Carrozza`);

--
-- Indici per le tabelle `carrozza`
--
ALTER TABLE `carrozza`
  ADD PRIMARY KEY (`ID`);

--
-- Indici per le tabelle `checkpoint`
--
ALTER TABLE `checkpoint`
  ADD PRIMARY KEY (`ID`);

--
-- Indici per le tabelle `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`Codice_Fiscale`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD UNIQUE KEY `Recapito Telefonico` (`Recapito_Telefonico`);

--
-- Indici per le tabelle `compone1`
--
ALTER TABLE `compone1`
  ADD PRIMARY KEY (`Motrice`,`Treno`),
  ADD KEY `FK_TRENO_TRENO_ID` (`Treno`);

--
-- Indici per le tabelle `compone2`
--
ALTER TABLE `compone2`
  ADD PRIMARY KEY (`Carrozza`,`Treno`),
  ADD KEY `FK_TRENO_TRENO_ID2` (`Treno`);

--
-- Indici per le tabelle `controlla`
--
ALTER TABLE `controlla`
  ADD PRIMARY KEY (`Controllore`,`Treno`),
  ADD KEY `FK_TRENO_TRENO_ID3` (`Treno`);

--
-- Indici per le tabelle `controllore`
--
ALTER TABLE `controllore`
  ADD PRIMARY KEY (`Codice_Fiscale`);

--
-- Indici per le tabelle `dipendente`
--
ALTER TABLE `dipendente`
  ADD PRIMARY KEY (`Codice_Fiscale`),
  ADD UNIQUE KEY `Badge` (`Badge`),
  ADD UNIQUE KEY `Recapito Telefonico` (`Recapito_Telefonico`);

--
-- Indici per le tabelle `effettua`
--
ALTER TABLE `effettua`
  ADD PRIMARY KEY (`Operaio`,`Manutenzione`),
  ADD KEY `FK_MAN_MAN_ID` (`Manutenzione`);

--
-- Indici per le tabelle `fermata`
--
ALTER TABLE `fermata`
  ADD PRIMARY KEY (`Tratta`,`Stazione`),
  ADD KEY `FK_STAZIONE_STAZIONE_NOME` (`Stazione`);

--
-- Indici per le tabelle `guida`
--
ALTER TABLE `guida`
  ADD PRIMARY KEY (`Macchinista`,`Treno`),
  ADD KEY `FK_TRENO_TRENO_ID4` (`Treno`);

--
-- Indici per le tabelle `macchinista`
--
ALTER TABLE `macchinista`
  ADD PRIMARY KEY (`Codice_Fiscale`);

--
-- Indici per le tabelle `manutenzione`
--
ALTER TABLE `manutenzione`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `FK_ID_CARR_ID` (`Carrozza`),
  ADD KEY `FK_ID_MOTR_ID` (`Motrice`);

--
-- Indici per le tabelle `motrice`
--
ALTER TABLE `motrice`
  ADD PRIMARY KEY (`ID`);

--
-- Indici per le tabelle `operaio`
--
ALTER TABLE `operaio`
  ADD PRIMARY KEY (`Codice_Fiscale`);

--
-- Indici per le tabelle `posizione`
--
ALTER TABLE `posizione`
  ADD PRIMARY KEY (`Treno`,`Check_Point`),
  ADD KEY `FK_CP_CP_ID` (`Check_Point`);

--
-- Indici per le tabelle `servizio`
--
ALTER TABLE `servizio`
  ADD PRIMARY KEY (`Codice`),
  ADD KEY `FK_CLIENTE_CLIENTE_CF` (`Cliente`);

--
-- Indici per le tabelle `stazione`
--
ALTER TABLE `stazione`
  ADD PRIMARY KEY (`Nome`);

--
-- Indici per le tabelle `transito`
--
ALTER TABLE `transito`
  ADD PRIMARY KEY (`Stazione`,`Servizio`),
  ADD KEY `FK_SERVIZIO_SERVIZIO_CODICE` (`Servizio`);

--
-- Indici per le tabelle `tratta`
--
ALTER TABLE `tratta`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `FK_SP_STAZIONE_NOME` (`Stazione_Partenza`),
  ADD KEY `FK_SA_STAZIONE_NOME` (`Stazione_Arrivo`);

--
-- Indici per le tabelle `treno`
--
ALTER TABLE `treno`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `Percorso` (`Percorso`);

--
-- Limiti per le tabelle scaricate
--

--
-- Limiti per la tabella `abbonamento`
--
ALTER TABLE `abbonamento`
  ADD CONSTRAINT `FK_CODICE_SERVIZIO_CODICE2` FOREIGN KEY (`Codice`) REFERENCES `servizio` (`Codice`);

--
-- Limiti per la tabella `biglietto`
--
ALTER TABLE `biglietto`
  ADD CONSTRAINT `FK_CARROZZA_CARROZZA_ID` FOREIGN KEY (`Carrozza`) REFERENCES `carrozza` (`ID`) ON DELETE SET NULL ON UPDATE SET NULL,
  ADD CONSTRAINT `FK_CODICE_SERVIZIO_CODICE` FOREIGN KEY (`Codice`) REFERENCES `servizio` (`Codice`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `compone1`
--
ALTER TABLE `compone1`
  ADD CONSTRAINT `FK_MOTR_MOTR_ID` FOREIGN KEY (`Motrice`) REFERENCES `motrice` (`ID`),
  ADD CONSTRAINT `FK_TRENO_TRENO_ID` FOREIGN KEY (`Treno`) REFERENCES `treno` (`ID`);

--
-- Limiti per la tabella `compone2`
--
ALTER TABLE `compone2`
  ADD CONSTRAINT `FK_CARR_CARR_ID` FOREIGN KEY (`Carrozza`) REFERENCES `carrozza` (`ID`),
  ADD CONSTRAINT `FK_TRENO_TRENO_ID2` FOREIGN KEY (`Treno`) REFERENCES `treno` (`ID`);

--
-- Limiti per la tabella `controlla`
--
ALTER TABLE `controlla`
  ADD CONSTRAINT `FK_CONT_CONT_CF` FOREIGN KEY (`Controllore`) REFERENCES `controllore` (`Codice_Fiscale`),
  ADD CONSTRAINT `FK_TRENO_TRENO_ID3` FOREIGN KEY (`Treno`) REFERENCES `treno` (`ID`);

--
-- Limiti per la tabella `controllore`
--
ALTER TABLE `controllore`
  ADD CONSTRAINT `FK_CONT_DIP_CODFISC` FOREIGN KEY (`Codice_Fiscale`) REFERENCES `dipendente` (`Codice_Fiscale`);

--
-- Limiti per la tabella `effettua`
--
ALTER TABLE `effettua`
  ADD CONSTRAINT `FK_MAN_MAN_ID` FOREIGN KEY (`Manutenzione`) REFERENCES `manutenzione` (`ID`),
  ADD CONSTRAINT `FK_OPE_DIP_CODFISC` FOREIGN KEY (`Operaio`) REFERENCES `operaio` (`Codice_Fiscale`);

--
-- Limiti per la tabella `fermata`
--
ALTER TABLE `fermata`
  ADD CONSTRAINT `FK_STAZIONE_STAZIONE_NOME` FOREIGN KEY (`Stazione`) REFERENCES `stazione` (`Nome`),
  ADD CONSTRAINT `FK_TRATTA_TRATTA_ID` FOREIGN KEY (`Tratta`) REFERENCES `tratta` (`ID`);

--
-- Limiti per la tabella `guida`
--
ALTER TABLE `guida`
  ADD CONSTRAINT `FK_MAC_MAC_CF` FOREIGN KEY (`Macchinista`) REFERENCES `macchinista` (`Codice_Fiscale`),
  ADD CONSTRAINT `FK_TRENO_TRENO_ID4` FOREIGN KEY (`Treno`) REFERENCES `treno` (`ID`);

--
-- Limiti per la tabella `macchinista`
--
ALTER TABLE `macchinista`
  ADD CONSTRAINT `FK_MAC_DIP_CODFISC` FOREIGN KEY (`Codice_Fiscale`) REFERENCES `dipendente` (`Codice_Fiscale`);

--
-- Limiti per la tabella `manutenzione`
--
ALTER TABLE `manutenzione`
  ADD CONSTRAINT `FK_ID_CARR_ID` FOREIGN KEY (`Carrozza`) REFERENCES `carrozza` (`ID`),
  ADD CONSTRAINT `FK_ID_MOTR_ID` FOREIGN KEY (`Motrice`) REFERENCES `motrice` (`ID`);

--
-- Limiti per la tabella `operaio`
--
ALTER TABLE `operaio`
  ADD CONSTRAINT `FK_OP_DIP_CODFISC` FOREIGN KEY (`Codice_Fiscale`) REFERENCES `dipendente` (`Codice_Fiscale`);

--
-- Limiti per la tabella `posizione`
--
ALTER TABLE `posizione`
  ADD CONSTRAINT `FK_CP_CP_ID` FOREIGN KEY (`Check_Point`) REFERENCES `checkpoint` (`ID`),
  ADD CONSTRAINT `FK_TRENO_TRENO_ID5` FOREIGN KEY (`Treno`) REFERENCES `treno` (`ID`);

--
-- Limiti per la tabella `servizio`
--
ALTER TABLE `servizio`
  ADD CONSTRAINT `FK_CLIENTE_CLIENTE_CF` FOREIGN KEY (`Cliente`) REFERENCES `cliente` (`Codice_Fiscale`);

--
-- Limiti per la tabella `transito`
--
ALTER TABLE `transito`
  ADD CONSTRAINT `FK_SERVIZIO_SERVIZIO_CODICE` FOREIGN KEY (`Servizio`) REFERENCES `servizio` (`Codice`),
  ADD CONSTRAINT `FK_STAZ_STAZ_NOME` FOREIGN KEY (`Stazione`) REFERENCES `stazione` (`Nome`);

--
-- Limiti per la tabella `tratta`
--
ALTER TABLE `tratta`
  ADD CONSTRAINT `FK_SA_STAZIONE_NOME` FOREIGN KEY (`Stazione_Arrivo`) REFERENCES `stazione` (`Nome`),
  ADD CONSTRAINT `FK_SP_STAZIONE_NOME` FOREIGN KEY (`Stazione_Partenza`) REFERENCES `stazione` (`Nome`);

--
-- Limiti per la tabella `treno`
--
ALTER TABLE `treno`
  ADD CONSTRAINT `FK_ID_TRATTA_ID` FOREIGN KEY (`Percorso`) REFERENCES `tratta` (`ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
