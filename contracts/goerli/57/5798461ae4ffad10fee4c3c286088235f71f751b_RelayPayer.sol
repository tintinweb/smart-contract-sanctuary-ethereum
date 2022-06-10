/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RelayPayer {
  function payForRelay() public payable {
    block.coinbase.transfer(msg.value);
  }
}