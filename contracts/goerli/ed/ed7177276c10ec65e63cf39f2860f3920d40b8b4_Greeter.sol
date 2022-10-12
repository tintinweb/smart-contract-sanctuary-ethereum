/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Greeter {

    event Greet(address indexed from, string message);

    constructor() {  }

    function greet(string memory message) public {
        emit Greet(msg.sender, message);
    }

}