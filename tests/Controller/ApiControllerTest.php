<?php

declare(strict_types=1);

namespace App\Tests\Controller;

use App\Tests\Helper\TestDatabaseHelper;
use DateTimeImmutable;
use Doctrine\DBAL\Exception;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Doctrine\DBAL\Connection;

class ApiControllerTest extends WebTestCase
{
    protected Connection $connection;
    protected static bool $isDatabaseInitialized = false;

    /**
     * @throws Exception
     */
    protected function setUp(): void
    {
        parent::setUp();

        if (!self::$isDatabaseInitialized) {
            self::bootKernel();
            $container = static::getContainer();

            // database connection
            /** @var Connection $connection */
            $connection = $container->get(Connection::class);
            $this->connection = $connection;

            $helper = new TestDatabaseHelper($this->connection);

            // create tables
            $helper->resetSchema();

            // load fixtures
            $helper->loadFixtures();
        }

        self::$isDatabaseInitialized = true;

        static::ensureKernelShutdown();
    }

    public function testServerTimeWithValidToken(): void
    {
        $client = static::createClient();
        $client->request('GET', '/api/server-time', [], [], [
            'HTTP_X_API_KEY' => 'TEST_TOKEN',
            'HTTP_ACCEPT' => 'application/json',
        ]);

        $this->assertResponseIsSuccessful();

        $content = $client->getResponse()->getContent();

        if ($content === false) {
            $this->fail('Response content is empty.');
        }
        $this->assertJson($content);

        $response = json_decode($content, true);
        $this->assertIsArray($response);
        $this->assertArrayHasKey('server_time', $response);

        /** @var string $serverTime */
        $serverTime = $response['server_time'];

        $data = DateTimeImmutable::createFromFormat('Y-m-d H:i:s', $serverTime);
        $this->assertInstanceOf(DateTimeImmutable::class, $data);
    }

    public function testServerTimeWithInvalidToken(): void
    {
        $client = static::createClient();
        $client->request('GET', '/api/server-time', [], [], [
            'HTTP_X_API_KEY' => 'INVALID_TOKEN',
        ]);

        $this->assertResponseStatusCodeSame(401);
    }
}
