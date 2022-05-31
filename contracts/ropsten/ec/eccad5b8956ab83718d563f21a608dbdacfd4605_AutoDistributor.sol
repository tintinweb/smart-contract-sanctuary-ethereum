/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
//contract auto-distribute recieving ETH to two addresses immediately

contract AutoDistributor {  
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;
    address payable private _feeAddrWallet3;
    uint public balance;

    constructor(){
        _feeAddrWallet1 = payable(0x3F831e6BBa6C06e60A819C92Dd5F180624da6771);
        _feeAddrWallet2 = payable(0x3F831e6BBa6C06e60A819C92Dd5F180624da6771);
        _feeAddrWallet3 = payable(0x3F831e6BBa6C06e60A819C92Dd5F180624da6771);
  }
    //immediately distributing
    receive() external payable {
        balance = address(this).balance;
        _feeAddrWallet1.transfer(balance/3);
        _feeAddrWallet2.transfer(balance/3);
        _feeAddrWallet3.transfer(balance/3);
        }
}