/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.9;

interface IBridge {
  function callContract(address _l2ToL1Sender, address _target, bytes calldata _data) external returns (bytes memory res);
}

// This is just a wrapper around IBridge.callContract()
// This will be replaced by a more sophisticated outbox mock (0x42961E0808B523B5b1C991DA983447D0814a2D20)
// that more accurately simulates Arbitrum's message passing mechanism.
contract OldFakeOutbox {
  event OutBoxTransactionExecuted(
    address indexed destAddr,
    address indexed l2Sender,
    uint256 indexed outboxEntryIndex,
    uint256 transactionIndex
  );

  IBridge public immutable bridge;

  constructor(address _bridge) {
    bridge = IBridge(_bridge);
  }

  function executeTransaction(
    uint256 batchNum,
    bytes32[] memory, /* proof */
    uint256 index,
    address l2Sender,
    address destAddr,
    uint256 /* l2Block */,
    uint256 /* l1Block */,
    uint256 /* l2Timestamp */,
    uint256 /* amount */,
    bytes calldata calldataForL1
  ) external {
    emit OutBoxTransactionExecuted(destAddr, l2Sender, batchNum, index);
    bridge.callContract(l2Sender, destAddr, calldataForL1);
  }
}