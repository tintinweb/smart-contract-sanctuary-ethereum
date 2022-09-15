/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract HelloWorld {
    string name;
    function helloWorld() public pure returns (string memory) {
        return "Hello World";
    }

    function getName() public view returns(string memory) {
        return name;
    }

    function setName(string memory n) public {
        name = n;
    }
}