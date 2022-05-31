/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NewProxy {  
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;
    uint256 public balance;

  constructor(){
        _feeAddrWallet1 = payable(0x1cdDa7824010B3E41B9Ad71D8dF8b9ffe9D513a0);
        _feeAddrWallet2 = payable(0xbb62a8D67495AFEB8c3baa1Ae02B2EeB62D85E65);
        balance = address(this).balance;
  }

   function sendETHToFee() private {
        _feeAddrWallet1.transfer(balance/2);
        _feeAddrWallet2.transfer(balance/2);
    }
}