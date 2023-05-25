/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// namecontract.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract NameContract {
    string private name;
    address public owner;

    constructor(string memory yourName) {
        owner = msg.sender;
        name = yourName;
    }

    function getName() public view returns (string memory) {
        return name;
    }
}

// fin namecontract.sol