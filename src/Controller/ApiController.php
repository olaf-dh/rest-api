<?php

declare(strict_types=1);

namespace App\Controller;

use App\Service\ApiAccessService;
use App\Service\FlagBitService;
use DateTimeImmutable;
use Exception;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api')]
final class ApiController extends AbstractController
{
    public function __construct(private readonly ApiAccessService $apiAccessService)
    {
    }

    #[Route('/server-time', name: 'app_api_server_time', methods: ['GET'])]
    public function serverTime(Request $request): JsonResponse
    {
        try {
            $this->apiAccessService->authorizeRequest($request);
        } catch (Exception $exception) {
            return $this->json(['error' => $exception->getMessage()], 401);
        }

        return $this->json([
            'server_time' => (new DateTimeImmutable())->format('Y-m-d H:i:s'),
        ]);
    }

    /**
     * @throws \Doctrine\DBAL\Exception
     */
    #[Route('/transaction/{trans_id}/flagbits', name: 'app_api_transaction_flagbits', methods: ['GET'])]
    public function getActiveFlagBits(Request $request, int $trans_id, FlagBitService $flagBitService): JsonResponse
    {
        try {
            $apiKey = $this->apiAccessService->authorizeRequest($request);
            $this->apiAccessService->checkTransactionAccess($trans_id, $apiKey);
        } catch (Exception $exception) {
            return $this->json(['error' => $exception->getMessage()], 401);
        }

        $flagBits = $flagBitService->getActiveFlagBitsForTransaction($trans_id, 2);

        return $this->json([$flagBits]);
    }

    #[Route('/transaction/{trans_id}/flagbit/{flagbit}/enable', name: 'app_api_enable_flagbit', methods: ['GET', 'POST'])]
    public function enableFlagBit(Request $request, int $trans_id, int $flagbit, FlagBitService $flagBitService): JsonResponse
    {
        try {
            $apiKey = $this->apiAccessService->authorizeMasterRequest($request);
            $this->apiAccessService->checkTransactionAccess($trans_id, $apiKey);

            /** @var int $editorId */
            $editorId =  $apiKey['bearbeiter_id'];

            $flagBitService->enableFlagBitForTransaction(
                $trans_id,
                $flagbit,
                $editorId,
            );

        } catch (Exception $e) {
            return $this->json(['error' => $e->getMessage()], 403);
        }

        return $this->json(['success' => true]);
    }
}
