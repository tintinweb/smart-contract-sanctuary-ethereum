/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract SendMoneyExample {

    uint public balanceReceived;

    function receiveMoney() public payable {
        balanceReceived += msg.value;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function sendBalanceTo(address payable _address) public {
        _address.transfer(this.getBalance());
    }
}