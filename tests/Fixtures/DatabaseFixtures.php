<?php

declare(strict_types=1);

namespace App\Tests\Fixtures;

use DateTimeImmutable;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception;

readonly class DatabaseFixtures
{
    public function __construct(private Connection $connection)
    {
    }

    /**
     * @throws Exception
     */
    public function createValidTimeframe(): int
    {
        $now = new DateTimeImmutable();

        $this->connection->insert('vorgaben_zeitraum', [
            'von' => $now->modify('-1 day')->format('Y-m-d H:i:s'),
            'bis' => $now->modify('+1 day')->format('Y-m-d H:i:s'),
        ]);

        return (int) $this->connection->lastInsertId();
    }

    /**
     * @throws Exception
     */
    public function createApiKey(int $contractId, int $periodId, bool $isMaster = false): void
    {
        $this->connection->insert('api_apikey', [
            'apikey' => 'TEST_TOKEN',
            'vertrag_id' => $contractId,
            'zeitraum_id' => $periodId,
            'ist_masterkey' => $isMaster ? 1 : 0,
            'bearbeiter_id' => 1,
        ]);
    }

    /**
     * @throws Exception
     */
    public function createTestTransaction(int $contractId): int
    {
        $this->connection->insert('transaktion_transaktionen', [
            'produkt_id' => 1,
            'vertrag_id' => $contractId,
            'Betrag' => 1000,
            'beschreibung' => 'Test transaction',
            'waehrung_id' => 1,
            'bearbeiter' => 1,
            'erstelldatum' => (new DateTimeImmutable())->format('Y-m-d H:i:s'),
        ]);

        return (int) $this->connection->lastInsertId();
    }
}
