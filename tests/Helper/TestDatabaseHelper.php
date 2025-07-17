<?php

declare(strict_types=1);

namespace App\Tests\Helper;

use App\Tests\Fixtures\DatabaseFixtures;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception;
use RuntimeException;

readonly class TestDatabaseHelper
{
    private DatabaseFixtures $fixtures;

    public function __construct(private Connection $connection)
    {
        $fixtures = new DatabaseFixtures($this->connection);
        $this->fixtures = $fixtures;
    }

    /**
     * @throws Exception
     */
    public function resetSchema(): void
    {
        $sql = file_get_contents(__DIR__ . '/../schema.sql');

        if ($sql === false) {
            throw new RuntimeException('Failed to read schema.sql file.');
        }
        $this->connection->executeStatement($sql);
    }

    /**
     * @throws Exception
     */
    public function loadFixtures(): void
    {
        $periodId = $this->fixtures->createValidTimeframe();
        $contractId = 42;

        $this->fixtures->createTestTransaction($contractId);
        $this->fixtures->createApiKey($contractId, $periodId, true);
    }
}
