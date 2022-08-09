/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

contract Print {
    string public message;
    address public owner;

    constructor() {
        message = "";
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public {
        assert(msg.sender == owner);
        owner = newOwner;
    }

    function sayHello() public {
        assert(msg.sender == owner);
        message = "Hello!";
    }

    function sayGoodBye() public {
        assert(msg.sender == owner);
        message = "Good bye!";
    }
}