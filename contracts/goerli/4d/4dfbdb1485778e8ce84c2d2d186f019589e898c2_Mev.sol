/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mev {
  function bribe() external payable {
    block.coinbase.transfer(msg.value);
  }  
}