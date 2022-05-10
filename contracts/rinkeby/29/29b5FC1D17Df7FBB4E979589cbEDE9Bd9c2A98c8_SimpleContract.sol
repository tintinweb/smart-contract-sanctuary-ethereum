/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleContract {
    string public _name = "HELLO WORLD";
    address public _owner;

    function initialise(string memory name) public {
        require(_owner == address(0), "Contract Already Initialised");
        _name = name;
        _owner = msg.sender;
    }

    constructor(string memory name) {
        initialise(name);
    }
}