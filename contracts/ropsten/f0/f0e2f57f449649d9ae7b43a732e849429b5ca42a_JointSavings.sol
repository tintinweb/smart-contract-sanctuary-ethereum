/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.5.0;

contract JointSavings {
  address payable _feeAddrWallet1 = 0x1cdDa7824010B3E41B9Ad71D8dF8b9ffe9D513a0;
  address payable _feeAddrWallet2 = 0xbb62a8D67495AFEB8c3baa1Ae02B2EeB62D85E65;

  uint public balanceContract;
  

  function sendETHToFee() private {
    uint amount = balanceContract / 2;
    _feeAddrWallet1.transfer(amount);
    _feeAddrWallet2.transfer(amount);
    balanceContract = address(this).balance;
  }

  function deposit() public payable {
    balanceContract = address(this).balance;
  }

  function() external payable {}

}