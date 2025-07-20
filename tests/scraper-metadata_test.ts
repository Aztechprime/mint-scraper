import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Content Metadata Creation Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const contentId = types.utf8('content-001');
        const title = types.utf8('Web Scraping Result');
        const contentType = types.utf8('text/html');
        const sizeBytes = types.uint(1024);

        const block = chain.mineBlock([
            Tx.contractCall('scraper-metadata', 'create-content-metadata', [contentId, title, contentType, sizeBytes], deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Content Version Addition Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const contentId = types.utf8('content-002');
        const title = types.utf8('Advanced Scraping Result');
        const contentType = types.utf8('application/json');
        const sizeBytes = types.uint(2048);
        const hash = types.buff('0x1234');
        const deviceId = types.utf8('device-001');
        const changeDescription = types.utf8('Initial scrape');

        const block = chain.mineBlock([
            Tx.contractCall('scraper-metadata', 'create-content-metadata', [contentId, title, contentType, sizeBytes], deployer.address),
            Tx.contractCall('scraper-metadata', 'add-content-version', [contentId, hash, deviceId, changeDescription, sizeBytes], deployer.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Sync Status Update Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const contentId = types.utf8('content-003');
        const title = types.utf8('Synchronized Scraping Result');
        const contentType = types.utf8('text/plain');
        const sizeBytes = types.uint(512);
        const hash = types.buff('0x5678');
        const deviceId = types.utf8('device-002');
        const changeDescription = types.utf8('Updated version');
        const syncedVersion = types.uint(2);

        const block = chain.mineBlock([
            Tx.contractCall('scraper-metadata', 'create-content-metadata', [contentId, title, contentType, sizeBytes], deployer.address),
            Tx.contractCall('scraper-metadata', 'add-content-version', [contentId, hash, deviceId, changeDescription, sizeBytes], deployer.address),
            Tx.contractCall('scraper-metadata', 'update-sync-status', [contentId, deviceId, syncedVersion], deployer.address)
        ]);

        assertEquals(block.receipts.length, 3);
        block.receipts[2].result.expectOk().expectBool(true);
    }
});