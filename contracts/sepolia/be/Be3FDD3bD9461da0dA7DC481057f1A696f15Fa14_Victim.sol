/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

pragma solidity ^0.4.11;

contract Victim {
  uint withdrawableBalance;

  function withdraw() public {
    if (!msg.sender.call.value(withdrawableBalance)()) {
      revert();
    }

    withdrawableBalance = 0;
  }

  function deposit() public payable {
    withdrawableBalance = msg.value;
  }
}