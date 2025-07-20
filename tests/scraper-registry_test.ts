import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Reference Registration Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const refId = types.utf8('scrape-001');
        const hash = types.buff('0x1234');
        const version = types.utf8('v1.0');
        const metadata = types.some(types.utf8('Test scrape metadata'));

        const block = chain.mineBlock([
            Tx.contractCall('scraper-registry', 'register-reference', [refId, hash, version, metadata], deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Reference Update Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const refId = types.utf8('scrape-002');
        const hash = types.buff('0x1234');
        const version = types.utf8('v1.0');
        const metadata = types.some(types.utf8('Test scrape metadata'));
        const updatedHash = types.buff('0x5678');
        const updatedVersion = types.utf8('v1.1');

        const block = chain.mineBlock([
            Tx.contractCall('scraper-registry', 'register-reference', [refId, hash, version, metadata], deployer.address),
            Tx.contractCall('scraper-registry', 'update-reference', [refId, updatedHash, updatedVersion, metadata], deployer.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Reference Sharing Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const refId = types.utf8('scrape-003');
        const hash = types.buff('0x1234');
        const version = types.utf8('v1.0');

        const block = chain.mineBlock([
            Tx.contractCall('scraper-registry', 'register-reference', [refId, hash, version, types.none], deployer.address),
            Tx.contractCall('scraper-registry', 'share-reference', [refId, wallet1.address], deployer.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});