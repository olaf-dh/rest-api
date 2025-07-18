-- ----------------------------
-- Procedure structure for api_erstelle_apikey
-- ----------------------------
DROP PROCEDURE IF EXISTS `api_erstelle_apikey`;

CREATE PROCEDURE `api_erstelle_apikey`(IN IN_vertrag_id INT(11),
                                       IN IN_bearbeiter_id INT(11),
                                       OUT OUT_fehler INT(11))
BEGIN

/*
#####
# Beschreibung:
#	Einen apikey für einen Vertrag erstellen
#
# OUT_fehler
# 0 - Ok
# 1 - INPUT leer
# 2 - Generierung API Key fehlgeschlagen
# 3 - es existiert bereits ein Eintrag für diese vertrag_id mit gültigem/aktuellem Zeitraum
#####
*/
DECLARE proz_max_anzahl_durchlaeufe INT DEFAULT 500;
DECLARE proz_anzahl_durchlaeufe INT DEFAULT 0;
DECLARE proz_von_datum DATETIME;
DECLARE proz_apikey VARCHAR(255);
DECLARE proz_anzahl, proz_zeitraum_id, proz_vertrag_id INT;

SELECT NOW() INTO proz_von_datum;

IF (IFNULL(IN_vertrag_id,0) <> 0 AND IFNULL(IN_bearbeiter_id,0) <> 0) THEN

	-- auf aktuellen Eintrag für den Vertrag prüfen
SELECT vertrag_id
INTO proz_vertrag_id
FROM api_apikey
         INNER JOIN vorgaben_zeitraum ON vorgaben_zeitraum.zeitraum_id = api_apikey.zeitraum_id AND NOW() BETWEEN vorgaben_zeitraum.von AND vorgaben_zeitraum.bis
WHERE vertrag_id = IN_vertrag_id LIMIT 1;

-- prüfen ob ein aktueller Eintrag für diese vertrags_id bereits existiert
IF IFNULL(proz_vertrag_id,0) = 0 THEN

		 loop_durchlauf: LOOP

SELECT SHA1(CONCAT(UNIX_TIMESTAMP(NOW()), '537c70e7355eb935874e3ebd9e714fe7a0ecca69',UUID())) INTO proz_apikey;

SELECT COUNT(*) INTO proz_anzahl FROM api_apikey WHERE apikey = proz_apikey;

SET proz_anzahl_durchlaeufe = proz_anzahl_durchlaeufe + 1;

			IF ( proz_anzahl = 0 ) THEN
				-- generierter API Key noch nicht vorhanden
				SET OUT_fehler = 0;
				LEAVE loop_durchlauf;

			ELSEIF (proz_anzahl_durchlaeufe >= proz_max_anzahl_durchlaeufe) THEN

				SET OUT_fehler = 2;
				LEAVE loop_durchlauf;

END IF;

END LOOP loop_durchlauf;

		IF OUT_fehler = 0 THEN -- ok

			CALL erstelle_zeitraum(proz_von_datum, DATE_ADD(proz_von_datum,INTERVAL 50 YEAR), proz_zeitraum_id);

INSERT INTO api_apikey (apikey, vertrag_id, zeitraum_id, bearbeiter_id) VALUES (proz_apikey, IN_vertrag_id, proz_zeitraum_id, IN_bearbeiter_id );

END IF;



ELSE

		SET OUT_fehler = 3;

END IF;

ELSE

	SET OUT_fehler = 1;

END IF;

END
;;

-- ----------------------------
-- Procedure structure for erstelle_zeitraum
-- ----------------------------
DROP PROCEDURE IF EXISTS `erstelle_zeitraum`;

CREATE PROCEDURE `erstelle_zeitraum`(IN IN_von DATETIME,
                                     IN IN_bis DATETIME,
                                     OUT OUT_zeitraum_id INT UNSIGNED)
    proc_block:BEGIN

/*
#####
# Beschreibung:
# Prozedur zum Erstellen eines Zeitraums.
#####
*/

-- Prüfen ob bereits ein Eintrag existiert
SELECT zeitraum_id
INTO OUT_zeitraum_id
FROM vorgaben_zeitraum
WHERE
    vorgaben_zeitraum.von = IN_von
  AND vorgaben_zeitraum.bis = IN_bis;

IF IFNULL( OUT_zeitraum_id, 0 ) <> 0 THEN
  LEAVE proc_block;
END IF;

INSERT IGNORE INTO vorgaben_zeitraum
SET
  von = IN_von,
  bis = IN_bis;

SELECT zeitraum_id
INTO OUT_zeitraum_id
FROM vorgaben_zeitraum
WHERE
    vorgaben_zeitraum.von = IN_von
  AND vorgaben_zeitraum.bis = IN_bis;

END
;;

-- ----------------------------
-- Procedure structure for stamd_aendern_erstellen_flagbit_ref
-- ----------------------------
DROP PROCEDURE IF EXISTS `stamd_aendern_erstellen_flagbit_ref`;

CREATE PROCEDURE `stamd_aendern_erstellen_flagbit_ref`(IN IN_datensatz_typ_id INT UNSIGNED,
                                                       IN IN_datensatz_id INT UNSIGNED,
                                                       IN IN_flagbit BIGINT(20),
                                                       IN IN_modus TINYINT(4),
                                                       IN IN_bearbeiter_id INT UNSIGNED,
                                                       OUT OUT_fehler_code TINYINT(4),
                                                       OUT OUT_fehler TEXT)
    proc_block:BEGIN


/*
#####
# Beschreibung:
# Prozedur zum Referenzieren eines Flags
#
# IN_modus:
#   1 = Eintragen/Ändern
#   2 = Austragen
#
# OUT_fehler_code = OUT_fehler:
#   0 = NULL = kein Fehler
#   1 = Parameter nicht hinreichend gefüllt
#   2 = Flagbit-Parameter nicht gültig
#####
*/

DECLARE proz_flagbit_ref_id, proz_zeitraum_id_alt, proz_zeitraum_id_neu, proz_datensatz_typ_id, proz_datensatz_id, proz_fehler, proz_anzahl INT;
DECLARE proz_zeitraum_von_neu, proz_zeitraum_von_alt DATETIME;
DECLARE proz_flagbit BIGINT;
DECLARE proz_neuen_datensatz_anlegen, proz_alten_datensatz_deaktivieren BOOLEAN DEFAULT FALSE;

-- 0 = kein Fehler
SET OUT_fehler_code = 0;

IF IFNULL( IN_datensatz_typ_id, 0 ) = 0
  OR IFNULL( IN_datensatz_id, 0 ) = 0
  OR IFNULL( IN_modus, 0 ) NOT IN ( 1, 2 )
  OR IFNULL( IN_bearbeiter_id, 0 ) = 0
THEN

  -- 1 = Parameter nicht hinreichend gefüllt
  SET OUT_fehler_code = 1;
  SET OUT_fehler = 'Parameter nicht hinreichend gefüllt';
  LEAVE proc_block;

END IF;

IF IN_modus = 1 -- 1 = Eintragen/Ändern
  AND IN_flagbit IS NULL
THEN

  -- 1 = Parameter nicht hinreichend gefüllt
  SET OUT_fehler_code = 1;
  SET OUT_fehler = 'Parameter nicht hinreichend gefüllt';
  LEAVE proc_block;

END IF;

SET proz_zeitraum_von_neu = NOW();

-- nach aktuellem Datensatz suchen
SELECT
    stamd_flagbit_ref.flagbit_ref_id,
    vorgaben_zeitraum.von,
    stamd_flagbit_ref.datensatz_typ_id,
    stamd_flagbit_ref.datensatz_id,
    stamd_flagbit_ref.flagbit
INTO
    proz_flagbit_ref_id,
    proz_zeitraum_von_alt,
    proz_datensatz_typ_id,
    proz_datensatz_id,
    proz_flagbit
FROM
    stamd_flagbit_ref
        INNER JOIN vorgaben_zeitraum
                   ON vorgaben_zeitraum.zeitraum_id = stamd_flagbit_ref.zeitraum_id
                       AND proz_zeitraum_von_neu BETWEEN vorgaben_zeitraum.von AND vorgaben_zeitraum.bis
WHERE
    stamd_flagbit_ref.datensatz_typ_id = IN_datensatz_typ_id
  AND stamd_flagbit_ref.datensatz_id = IN_datensatz_id;

IF IN_modus = 1 -- 1 = Eintragen/Ändern
  AND IFNULL( proz_flagbit_ref_id, 0 ) = 0
THEN

  SET proz_neuen_datensatz_anlegen = TRUE;

ELSEIF IN_modus = 2 -- 2 = Austragen
  AND IFNULL( proz_flagbit_ref_id, 0 ) <> 0
THEN

  SET proz_alten_datensatz_deaktivieren = TRUE;

ELSEIF IN_modus = 1 -- 1 = Eintragen/Ändern
  AND IFNULL( proz_flagbit_ref_id, 0 ) <> 0
THEN

  IF NOT proz_flagbit <=> IN_flagbit THEN

    SET proz_neuen_datensatz_anlegen = TRUE;
    SET proz_alten_datensatz_deaktivieren = TRUE;

END IF;

ELSEIF IN_modus = 2 -- 2 = Austragen
  AND IFNULL( proz_flagbit_ref_id, 0 ) = 0
THEN

  -- 2 = Flagbit-Parameter nicht gültig
  SET OUT_fehler_code = 2;
  SET OUT_fehler = 'Flagbit-Referenz existiert nicht';
  LEAVE proc_block;

END IF;

IF IFNULL( proz_alten_datensatz_deaktivieren, FALSE ) THEN

  CALL erstelle_zeitraum ( proz_zeitraum_von_alt, DATE_SUB( proz_zeitraum_von_neu, INTERVAL 1 SECOND ), proz_zeitraum_id_alt );

UPDATE stamd_flagbit_ref
SET
    stamd_flagbit_ref.zeitraum_id = proz_zeitraum_id_alt,
    stamd_flagbit_ref.bearbeiter_id = IN_bearbeiter_id
WHERE stamd_flagbit_ref.flagbit_ref_id = proz_flagbit_ref_id;

END IF;

IF IFNULL( proz_neuen_datensatz_anlegen, FALSE ) THEN

  CALL erstelle_zeitraum ( proz_zeitraum_von_neu, DATE_ADD( proz_zeitraum_von_neu, INTERVAL 50 YEAR ), proz_zeitraum_id_neu );

INSERT INTO stamd_flagbit_ref
SET
    datensatz_typ_id = IN_datensatz_typ_id,
    datensatz_id = IN_datensatz_id,
    flagbit = IN_flagbit,
    zeitraum_id = proz_zeitraum_id_neu,
    bearbeiter_id = IN_bearbeiter_id;

END IF;

cursor_loop:LOOP

SELECT SQL_CALC_FOUND_ROWS stamd_flagbit_ref.flagbit_ref_id
INTO proz_flagbit_ref_id
FROM
    stamd_flagbit_ref
        INNER JOIN vorgaben_zeitraum
                   ON vorgaben_zeitraum.zeitraum_id = stamd_flagbit_ref.zeitraum_id
                       AND NOW() BETWEEN vorgaben_zeitraum.von AND vorgaben_zeitraum.bis
WHERE
    stamd_flagbit_ref.datensatz_typ_id = IN_datensatz_typ_id
  AND stamd_flagbit_ref.datensatz_id = IN_datensatz_id
ORDER BY
    vorgaben_zeitraum.von DESC,
    stamd_flagbit_ref.flagbit_ref_id DESC
    LIMIT 1;

SET proz_anzahl = FOUND_ROWS();

  IF proz_anzahl <= 1 THEN
    LEAVE cursor_loop;
END IF;

UPDATE stamd_flagbit_ref
SET zeitraum_id = 17396 -- 17396 = 1900 - 19000
WHERE flagbit_ref_id = proz_flagbit_ref_id;

END LOOP cursor_loop;

END
;;

SET FOREIGN_KEY_CHECKS = 1;
