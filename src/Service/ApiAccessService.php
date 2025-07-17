<?php

declare(strict_types=1);

namespace App\Service;

use DateTimeImmutable;
use Doctrine\DBAL\Connection;
use Exception;
use RuntimeException;
use Symfony\Component\HttpFoundation\Request;

readonly class ApiAccessService
{
    public function __construct(private Connection $connection)
    {
    }

    /**
     * @param Request $request
     * @return array<string, mixed>
     * @throws \Doctrine\DBAL\Exception
     * @throws Exception
     */
    public function authorizeRequest(Request $request): array
    {
        $token = $request->headers->get('X-Api-Key');

        if (!$token) {
            throw new Exception('No API Key provided.');
        }

        // check token
        $apiResult = $this->connection->fetchAssociative('SELECT * FROM api_apikey WHERE apikey = :token', ['token' => $token]);
        if (!$apiResult) {
            throw new Exception('Invalid API Key.');
        }

        // check for valid period
        $period = $this->connection->fetchAssociative('SELECT * FROM vorgaben_zeitraum WHERE zeitraum_id = :id', ['id' => $apiResult['zeitraum_id']]);
        if (!$period) {
            throw new Exception('No active period defined.');
        }

        if (!is_string($period['von']) || !is_string($period['bis'])) {
            throw new RuntimeException('Invalid period value.');
        }

        $now = new DateTimeImmutable();
        if ($now < new DateTimeImmutable($period['von']) || $now > new DateTimeImmutable($period['bis'])) {
            throw new Exception('API Key not valid in current period.');
        }

        return $apiResult;
    }

    /**
     * @param Request $request
     * @return array<string, mixed>
     * @throws \Doctrine\DBAL\Exception
     * @throws Exception
     */
    public function authorizeMasterRequest(Request $request): array
    {
        $apiKey = $this->authorizeRequest($request);

        if (($apiKey['ist_masterkey'] ?? 0) != 1) {
            throw new Exception('Master API Key required for this action.');
        }

        return $apiKey;
    }

    /**
     * @param int $transactionId
     * @param array<string, mixed> $apiResult
     * @return void
     * @throws \Doctrine\DBAL\Exception
     * @throws Exception
     */
    public function checkTransactionAccess(int $transactionId, array $apiResult): void
    {
        $contractId = $apiResult['vertrag_id'];

        if (!$contractId) {
            throw new Exception('Invalid API Key: no contract assigned.');
        }

        $transaction = $this->connection->fetchAssociative(
            'SELECT * FROM transaktion_transaktionen WHERE trans_id = :trans_id AND vertrag_id = :vertrag_id', ['trans_id' => $transactionId, 'vertrag_id' => $contractId]);

        if (!$transaction) {
            throw new Exception('Access denied: transaction does not belong to API user.');
        }
    }
}
