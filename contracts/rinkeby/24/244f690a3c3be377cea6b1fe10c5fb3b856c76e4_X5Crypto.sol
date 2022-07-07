/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract X5Crypto {

    address payable public owner;
    string public message = "Hello X5";
    uint public minPayment = 0.001 ether;

    constructor() {
       owner = payable(msg.sender);
    }

    function setMessage(string calldata _newMessageValue) payable public {
        require(msg.value > minPayment, "Pay more!");
        message = _newMessageValue;
        minPayment = minPayment + 0.001 ether;    }

    function withdraw() public {
        require(msg.sender == owner, "You are not owner");
        owner.transfer(address(this).balance);
    }
}