/*
 Navicat MySQL Dump SQL

 Target Server Type    : MySQL
 Target Server Version : 80404 (8.4.4-commercial)
 File Encoding         : 65001

 Date: 14/03/2025 11:14:56
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for api_apikey
-- ----------------------------
DROP TABLE IF EXISTS `api_apikey`;
CREATE TABLE `api_apikey`  (
  `apikey_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `apikey` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `vertrag_id` bigint UNSIGNED NOT NULL,
  `zeitraum_id` bigint UNSIGNED NOT NULL,
  `ist_masterkey` tinyint NOT NULL DEFAULT 0,
  `bearbeiter_id` bigint UNSIGNED NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`apikey_id`) USING BTREE,
  UNIQUE INDEX `apikey`(`apikey` ASC) USING BTREE,
  INDEX `vertrag_id`(`vertrag_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for stamd_flagbit_ref
-- ----------------------------
DROP TABLE IF EXISTS `stamd_flagbit_ref`;
CREATE TABLE `stamd_flagbit_ref`  (
  `flagbit_ref_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `datensatz_typ_id` int UNSIGNED NOT NULL,
  `datensatz_id` bigint UNSIGNED NOT NULL,
  `flagbit` bigint UNSIGNED NOT NULL,
  `zeitraum_id` bigint UNSIGNED NOT NULL,
  `bearbeiter_id` bigint UNSIGNED NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`flagbit_ref_id`) USING BTREE,
  INDEX `datensatz_typ_id`(`datensatz_typ_id` ASC) USING BTREE,
  INDEX `datensatz_id`(`datensatz_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 103 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for stamd_nutzerdetails
-- ----------------------------
DROP TABLE IF EXISTS `stamd_nutzerdetails`;
CREATE TABLE `stamd_nutzerdetails`  (
  `nutzerdetails_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '',
  `Bearbeiter` bigint UNSIGNED NULL DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`nutzerdetails_id`) USING BTREE,
  INDEX `stamd_nutzerdetails_FKIndex1`(`name` ASC) USING BTREE,
  INDEX `stamd_nutzerdetails_FKIndex6`(`timestamp` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for transaktion_transaktionen
-- ----------------------------
DROP TABLE IF EXISTS `transaktion_transaktionen`;
CREATE TABLE `transaktion_transaktionen`  (
  `trans_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `produkt_id` int NOT NULL,
  `vertrag_id` bigint UNSIGNED NOT NULL,
  `Betrag` bigint UNSIGNED NOT NULL,
  `beschreibung` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL,
  `waehrung_id` int UNSIGNED NOT NULL DEFAULT 1,
  `bearbeiter` bigint UNSIGNED NOT NULL,
  `erstelldatum` datetime NULL DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`trans_id`) USING BTREE,
  INDEX `ix_betrag`(`Betrag` ASC) USING BTREE,
  INDEX `ix_erstelldatum`(`erstelldatum` ASC) USING BTREE,
  INDEX `ix_produkt_id_erstelldatum`(`produkt_id` ASC, `erstelldatum` ASC) USING BTREE,
  INDEX `ix_timestamp_produkt_id`(`timestamp` ASC, `produkt_id` ASC) USING BTREE,
  INDEX `ix_vertrag_id_produkt_id_erstelldatum`(`vertrag_id` ASC, `produkt_id` ASC, `erstelldatum` ASC) USING BTREE,
  INDEX `ix_waehrung_id_erstelldatum`(`waehrung_id` ASC, `erstelldatum` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for vertragsverw_vertrag
-- ----------------------------
DROP TABLE IF EXISTS `vertragsverw_vertrag`;
CREATE TABLE `vertragsverw_vertrag`  (
  `vertrag_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `zeitraum_id` bigint UNSIGNED NOT NULL,
  `nutzer_id` bigint UNSIGNED NOT NULL,
  `Bearbeiter` bigint UNSIGNED NOT NULL,
  `erstelldatum` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `timestamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`vertrag_id`) USING BTREE,
  INDEX `nutzer_id`(`nutzer_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for vorgaben_datensatz_typ
-- ----------------------------
DROP TABLE IF EXISTS `vorgaben_datensatz_typ`;
CREATE TABLE `vorgaben_datensatz_typ`  (
  `datensatz_typ_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `beschreibung` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  PRIMARY KEY (`datensatz_typ_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 36 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for vorgaben_flagbit
-- ----------------------------
DROP TABLE IF EXISTS `vorgaben_flagbit`;
CREATE TABLE `vorgaben_flagbit`  (
  `flagbit_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `beschreibung` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `tabellen` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT 'nur als notiz, wird nicht ausgewertet',
  PRIMARY KEY (`flagbit_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for vorgaben_zeitraum
-- ----------------------------
DROP TABLE IF EXISTS `vorgaben_zeitraum`;
CREATE TABLE `vorgaben_zeitraum`  (
  `zeitraum_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `von` datetime NOT NULL,
  `bis` datetime NOT NULL,
  PRIMARY KEY (`zeitraum_id`) USING BTREE,
  UNIQUE INDEX `von_2`(`von` ASC, `bis` ASC) USING BTREE,
  INDEX `von`(`von` ASC) USING BTREE,
  INDEX `bis`(`bis` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;
