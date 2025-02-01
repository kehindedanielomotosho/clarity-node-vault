import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register node with sufficient stake",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("node-vault", "register-node", 
        [types.uint(100000)], wallet_1.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk();
  },
});

Clarinet.test({
  name: "Ensure cannot register with insufficient stake",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("node-vault", "register-node", 
        [types.uint(1000)], wallet_1.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr(101);
  },
});
