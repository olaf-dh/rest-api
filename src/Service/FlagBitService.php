<?php

declare(strict_types=1);

namespace App\Service;

use DateTimeImmutable;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Exception;
use RuntimeException;

readonly class FlagBitService
{
    public function __construct(private Connection $connection)
    {
    }

    /**
     * @param int $transId
     * @param int $datasetTypId
     * @return array<int, array<string, mixed>>
     * @throws Exception
     */
    public function getActiveFlagBitsForTransaction(int $transId, int $datasetTypId): array
    {
        $sql = '
            SELECT sfr.flagbit AS id, vf.beschreibung AS name
            FROM stamd_flagbit_ref sfr
            LEFT JOIN vorgaben_flagbit vf ON sfr.flagbit = vf.flagbit_id
            LEFT JOIN vorgaben_zeitraum vz ON sfr.zeitraum_id = vz.zeitraum_id
            WHERE sfr.datensatz_typ_id = :datasetTypId
            AND sfr.datensatz_id = :transId
            AND NOW() BETWEEN vz.von AND vz.bis
            ORDER BY sfr.flagbit
            ';

        return $this->connection->fetchAllAssociative($sql, ['datasetTypId' => $datasetTypId, 'transId' => $transId]);
    }

    /**
     * @throws Exception
     */
    public function enableFlagBitForTransaction(int $transId, int $flagBitId, int $editorId): void
    {
        $this->connection->executeStatement('
            CALL stamd_aendern_erstellen_flagbit_ref(
                :datensatz_typ_id,
                :datensatz_id,
                :flagbit,
                :modus,
                :bearbeiter_id,
                @out_error_code,
                @out_error_msg
            )
        ', [
            'datensatz_typ_id' => 2,
            'datensatz_id'     => $transId,
            'flagbit'          => $flagBitId,
            'modus'            => 1,
            'bearbeiter_id'    => $editorId,
        ]);

        /** @var int|null $errorCode */
        $errorCode = $this->connection->fetchOne('SELECT @out_error_code');

        /** @var string $errorMsg */
        $errorMsg  = $this->connection->fetchOne('SELECT @out_error_msg') ?: 'Unknown error';

        if ($errorCode !== null && $errorCode !== 0) {
            throw new RuntimeException(sprintf(
                'FlagBit could not be enabled (Error code %s: %s).',
                $errorCode,
                $errorMsg
            ));
        }

//        $now = new DateTimeImmutable();
//
//        $period = $this->connection->fetchAssociative('
//            SELECT zeitraum_id
//            FROM vorgaben_zeitraum
//            WHERE :date BETWEEN von AND bis
//            ORDER BY von DESC', ['date' => $now->format('Y-m-d H:i:s')]);
//
//        if (!$period) {
//            throw new \RuntimeException('No active period found.');
//        }
//
//        $this->connection->beginTransaction();
//        $this->connection->insert('stamd_flagbit_ref', [
//            'datensatz_typ_id' => 2,
//            'datensatz_id' => $transId,
//            'flagbit' => $flagBitId,
//            'zeitraum_id' => $period['zeitraum_id'],
//            'bearbeiter_id' => $editorId,
//        ]);
    }
}
