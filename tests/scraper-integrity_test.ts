import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Data Hash Submission Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const dataId = types.utf8('data-001');
        const hash = types.buff('0x1234');
        const deviceId = types.utf8('device-001');

        const block = chain.mineBlock([
            Tx.contractCall('scraper-integrity', 'submit-data-hash', [dataId, hash, deviceId], deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Data Verification Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const dataId = types.utf8('data-002');
        const hash = types.buff('0x1234');
        const deviceId = types.utf8('device-001');
        const proof = types.buff('0x5678');

        const block = chain.mineBlock([
            Tx.contractCall('scraper-integrity', 'submit-data-hash', [dataId, hash, deviceId], deployer.address),
            Tx.contractCall('scraper-integrity', 'verify-data', [dataId, hash, proof], deployer.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Conflict Detection and Resolution Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const dataId = types.utf8('data-003');
        const hash1 = types.buff('0x1234');
        const hash2 = types.buff('0x5678');
        const deviceId1 = types.utf8('device-001');
        const deviceId2 = types.utf8('device-002');

        const block = chain.mineBlock([
            Tx.contractCall('scraper-integrity', 'submit-data-hash', [dataId, hash1, deviceId1], deployer.address),
            Tx.contractCall('scraper-integrity', 'detect-conflict', [dataId, hash2], deployer.address),
            Tx.contractCall('scraper-integrity', 'resolve-conflict', [dataId, hash1], deployer.address)
        ]);

        assertEquals(block.receipts.length, 3);
        block.receipts[2].result.expectOk().expectBool(true);
    }
});