/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherBank {
    // uint public etherReceived;

    mapping (address => uint) public etherBalance;

    function sendMoney() public payable {
        etherBalance[msg.sender] = etherBalance[msg.sender] + msg.value;
    }

    function getOwnBalance() public view returns(uint) {
        return etherBalance[msg.sender];
    }

    function getTotalBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoneyTo(address payable _to) public {
        _to.transfer(getOwnBalance());
        etherBalance[msg.sender] = etherBalance[msg.sender] - getOwnBalance();
    }


}

// Store some ether.
// Can send money to the contract.
// Check the balance of the contract.
// Withdraw the money from the contract (specific address)
// Withdraw the money to the current address.