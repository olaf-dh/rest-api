<?php

declare(strict_types=1);

namespace App\Tests\Service;

use App\Service\FlagBitService;
use App\Tests\Helper\TestDatabaseHelper;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception;
use RuntimeException;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class FlagBitServiceTest extends KernelTestCase
{
    private FlagBitService $flagBitService;
    private Connection $connection;

    /**
     * @throws Exception
     */
    public function setUp(): void
    {
        self::bootKernel();
        $container = static::getContainer();

        /** @var Connection $connection */
        $connection = $container->get(Connection::class);

        $this->connection = $connection;
        $this->flagBitService = new FlagBitService($connection);

        $helper = new TestDatabaseHelper($this->connection);
        $helper->resetSchema();
        $helper->loadFixtures();
    }

    /**
     * @throws Exception
     */
    public function testGetActiveFlagBitsReturnsExpectedResult(): void
    {
        // existing transaction wit flag bits
        $result = $this->flagBitService->getActiveFlagBitsForTransaction(1, 1);

        // optional: check, that result is not empty
        $this->assertGreaterThanOrEqual(0, count($result), 'Result is an array but empty.');

        foreach ($result as $flagBit) {
            $this->assertArrayHasKey('id', $flagBit);
            $this->assertArrayHasKey('name', $flagBit);

            $this->assertIsInt($flagBit['id']);
            $this->assertIsString($flagBit['name']);
        }
    }

    /**
     * @throws \PHPUnit\Framework\MockObject\Exception
     * @throws Exception
     */
    public function testEnableFlagBitForTransactionInsertsRecord(): void
    {
        // mock for Doctrine\DBAL\Connection
        $dbMock = $this->createMock(Connection::class);

        // simulate active period
        $dbMock->method('fetchAssociative')
            ->willReturn(['zeitraum_id' => 42]);

        // expected: INSERT will be executed one time
        $dbMock->expects($this->once())
            ->method('insert')
            ->with(
                'stamd_flagbit_ref',
                $this->callback(function ($data) {
                    /** @var array<string, mixed> $data */
                    return $data['datensatz_typ_id'] === 2
                        && $data['datensatz_id'] === 123
                        && $data['flagbit'] === 5
                        && $data['zeitraum_id'] === 42
                        && $data['bearbeiter_id'] === 7;
                })
            );

        $service = new FlagBitService($dbMock);

        // call method
        $service->enableFlagBitForTransaction(123, 5, 7);
    }

    /**
     * @throws Exception
     */
    public function testEnableFlagBitForTransactionInsertsInDatabase(): void
    {
        // example: transaction ID 1, flagbit 5, editor ID 1
        $this->flagBitService->enableFlagBitForTransaction(1, 5, 1);

        $count = $this->connection->fetchOne('
            SELECT COUNT(*)
            FROM stamd_flagbit_ref
            WHERE datensatz_typ_id = 2
              AND datensatz_id = 1
              AND flagbit = 5
        ');

        $this->assertGreaterThan(0, $count, 'FlagBit was not inserted into the database.');
    }

    /**
     * @throws \PHPUnit\Framework\MockObject\Exception
     * @throws Exception
     */
    public function testEnableFlagBitThrowsExceptionWhenNoTimeframe(): void
    {
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('No active period found.');

        $dbMock = $this->createMock(Connection::class);

        // simulate a period that not exist
        $dbMock->method('fetchAssociative')
            ->willReturn(false);

        $service = new FlagBitService($dbMock);

        // should throw exception
        $service->enableFlagBitForTransaction(123, 5, 7);
    }
}
