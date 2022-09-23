/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: Unlicensed

  pragma solidity ^0.8.0;

  contract KingOfFoolsContract {
    address public kingAddress;
    uint256 public prevEthAmount;

    function deposit() external payable {
      require(msg.value > prevEthAmount * 15 / 10, "Error: Insufficent Fund");
      
      if (kingAddress != address(0)) {
        payable(kingAddress).transfer(msg.value);
      }
      prevEthAmount = msg.value;
      kingAddress = msg.sender;
    }
    receive() external payable {}
  }