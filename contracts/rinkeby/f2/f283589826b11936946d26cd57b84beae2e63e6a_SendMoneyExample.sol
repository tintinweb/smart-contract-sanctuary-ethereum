/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract SendMoneyExample {

    uint public balanceReceived;

    function receiveMoney() public payable {
        require(msg.value>0,"Value should not be 0");
        balanceReceived += msg.value;
    }

    function getBalance() public view  returns(uint) {
        return address(this).balance;
    }
}