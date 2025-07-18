# Backend REST API Project

Dieses Projekt wurde mit [Symfony](https://symfony.com/) entwickelt und dient als Grundlage zur 
Entwicklung und Prüfung einer REST-API. Das Projekt läuft vollständig in einer 
[DDEV](https://ddev.readthedocs.io/en/stable/) Umgebung und enthält neben den Datenbank-Testdaten sowie 
statische und automatische Tests auch Dummy-Daten für die reguläre Datenbank.

## 📦 Voraussetzungen

- Docker + DDEV
- PHP (über DDEV)
- Composer (über DDEV)
- MySQL (in DDEV explizit definieren)
- Postman oder ein anderer API-Client (optional, für manuelles Testen)

## 🚀 Projekt einrichten

```bash
ddev start
ddev exec composer install
ddev exec symfony console cache:clear
```

## Datenbank vorbereiten

Das Projekt verwendet MySQL. Ein vorbereiteter SQL-Dump ist in .zip-Datei enthalten.

```bash
ddev exec mysql < db_export.sql
```

Hinweis: Der Dump enthält Beispiel-API-Keys, Transaktionen und Zeiträume.

## Datenbank-Prozeduren

Dieses Projekt verwendet mehrere MySQL Stored Procedures, unter anderem:

- `api_erstelle_apikey`
- `erstelle_zeitraum`
- `stamd_aendern_erstellen_flagbit_ref`

Die Prozeduren sind im SQL-Dump (`db_export.sql`) enthalten und werden beim Import automatisch in der Datenbank angelegt.

Verwendung im Projekt:

- Aktivieren eines 'FlagBit' erfolgt über die Prozedur `stamd_aendern_erstellen_flagbit_ref`.

## API verwenden

Die API ist standardmäßig unter `https://<projektname>.ddev.site/api` erreichbar.

Beispiel-Endpunkte:

| Methode | Endpoint                                               | Beschreibung                               |
|---------|--------------------------------------------------------|--------------------------------------------|
| GET     | /server-time                                           | Gibt die aktuelle Serverzeit zurück        |
| POST    | /transaction/{trans_id}/flagbit/{flagbit_id}/enable | Aktiviert ein FlagBit für eine Transaktion |

Authentifizierung:  
Erfolgt per HTTP-Header:

X-API-KEY: <gültiger API-Key>

API-Keys befinden sich in der Tabelle `api_apikey`.

## Tests ausführen

### PHPUnit (Integrationstests & Unit-Tests)

```bash
ddev exec phpunit
```

### PHPStan (statische Code-Analyse)

```bash
ddev exec phpstan
```

## Weitere Hinweise

- Die Tests verwenden eine eigene Test-Datenbank (`db_test`).
- Der Datenbankzustand wird für Integrationstests automatisch per `schema.sql` und vorbereiteten 
Fixtures zurückgesetzt.
- Alle API-Endpunkte sind per Token gesichert.

## Technologien

- Symfony 7.x
- DDEV (Docker-basiert)
- MySQL
- PHPStan
- PHPUnit
- Postman (optional)

## Hinweise für Entwickler

Falls du die Datenbankstruktur ändern möchtest, passe die Datei `schema.sql` sowie die Test-Fixtures an (`DatabaseFixtures`-Klasse).
