/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract HelloWorld {
    string public name = "Lioloc";

    function print() external view returns (string memory) {
        return string(abi.encodePacked('Hello', name));
    }

    function updateName(string memory _name) external {
        name = _name;
    }
}