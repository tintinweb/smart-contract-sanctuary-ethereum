/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.5.0;

contract JointSavings {
  address payable account_one = 0x1cdDa7824010B3E41B9Ad71D8dF8b9ffe9D513a0;
  address payable account_two = 0xbb62a8D67495AFEB8c3baa1Ae02B2EeB62D85E65;

  uint public balanceContract;
  
  function withdraw(uint amount, address payable recipient) public {
    recipient.transfer(amount);
    balanceContract = address(this).balance;
  }

  function withdraw_equal() public {
    uint amount = balanceContract / 2;
    account_one.transfer(amount);
    account_two.transfer(amount);
    balanceContract = address(this).balance;
  }

  function deposit() public payable {
    balanceContract = address(this).balance;
  }

  function() external payable {}

}