import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Device Registration Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const deviceId = types.utf8('device-001');
        const deviceName = types.utf8('Scraper Device #1');

        const block = chain.mineBlock([
            Tx.contractCall('scraper-permission', 'register-device', [deviceId, deviceName], deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.height, 2);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Device Ownership Transfer Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const deviceId = types.utf8('device-002');
        const deviceName = types.utf8('Scraper Device #2');

        const block = chain.mineBlock([
            Tx.contractCall('scraper-permission', 'register-device', [deviceId, deviceName], deployer.address),
            Tx.contractCall('scraper-permission', 'transfer-device-ownership', [deviceId, wallet1.address], deployer.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Device Revocation Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const deviceId = types.utf8('device-003');
        const deviceName = types.utf8('Scraper Device #3');

        const block = chain.mineBlock([
            Tx.contractCall('scraper-permission', 'register-device', [deviceId, deviceName], deployer.address),
            Tx.contractCall('scraper-permission', 'revoke-device', [deviceId], deployer.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});