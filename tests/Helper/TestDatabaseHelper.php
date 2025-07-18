<?php

declare(strict_types=1);

namespace App\Tests\Helper;

use App\Tests\Fixtures\DatabaseFixtures;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception;
use RuntimeException;

readonly class TestDatabaseHelper
{
    private string $testDir;

    public function __construct(private Connection $connection)
    {
        $this->testDir = realpath(__DIR__ . '/../');
    }

    /**
     * @throws Exception
     */
    public function resetSchema(): void
    {
        $sql = file_get_contents($this->testDir . '/schema.sql');

        if ($sql === false) {
            throw new RuntimeException('Failed to read schema.sql file.');
        }
        $this->connection->executeStatement($sql);

        $this->importStoredProcedures();
    }

    /**
     * @throws Exception
     */
    public function loadFixtures(): void
    {
        $fixtures = new DatabaseFixtures($this->connection);
        $periodId = $fixtures->createValidTimeframe();
        $contractId = 42;

        $fixtures->createTestTransaction($contractId);
        $fixtures->createApiKey($contractId, $periodId, true);
    }

    private function importStoredProcedures(): void
    {
        $procedureFile = $this->testDir . '/procedure.sql';

        if (!file_exists($procedureFile)) {
            throw new RuntimeException('Procedure file not found: ' . $procedureFile);
        }

        $content = file_get_contents($procedureFile);

        if ($content === false) {
            throw new RuntimeException('Failed to read procedure.sql file.');
        }

        $statements = explode(';;', $content);

        foreach ($statements as $statement) {
            $sql = trim($statement);

            if ($sql !== '') {
                $this->connection->executeStatement($sql);
            }
        }
    }
}
