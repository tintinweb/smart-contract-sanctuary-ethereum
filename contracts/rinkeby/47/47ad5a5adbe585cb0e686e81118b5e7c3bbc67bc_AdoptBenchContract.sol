/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract AdoptBenchContract {

    address payable public owner;
    string public message = "Hello Ethereum";
    uint maxPayment = 0;

    constructor() {
       owner = payable(msg.sender);
    }

    function setMessage(string calldata _newValue) payable public {
        require(msg.value > maxPayment, "Pay more");
        message = _newValue;
        maxPayment = msg.value;
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not owner");
        owner.transfer(100000000);
    }


}