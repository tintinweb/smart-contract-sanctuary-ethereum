/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT-0

pragma solidity 0.6.0;



// File: FundMe.sol

contract FundMe {
  address owner;

  constructor() public {
    owner = msg.sender;
  }

  function fund() public payable {

  }

  function refund() public {
    require(msg.sender == owner, "Must be owner.");
    payable(owner).transfer(address(this).balance);
  }
}