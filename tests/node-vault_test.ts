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
    
    // Verify node status
    let nodeData = chain.callReadOnlyFn(
      "node-vault",
      "get-node",
      [types.principal(wallet_1.address)],
      wallet_1.address
    );
    nodeData.result.expectOk().expectSome();
  }
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
  }
});

Clarinet.test({
  name: "Ensure only owner can update status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    
    // Register node first
    let block = chain.mineBlock([
      Tx.contractCall("node-vault", "register-node", 
        [types.uint(100000)], wallet_1.address)
    ]);
    
    // Try updating status as non-owner
    block = chain.mineBlock([
      Tx.contractCall("node-vault", "update-status",
        [types.principal(wallet_1.address), types.ascii("active")],
        wallet_1.address)
    ]);
    
    block.receipts[0].result.expectErr(100);
    
    // Update status as owner
    block = chain.mineBlock([
      Tx.contractCall("node-vault", "update-status",
        [types.principal(wallet_1.address), types.ascii("active")],
        deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
  }
});
