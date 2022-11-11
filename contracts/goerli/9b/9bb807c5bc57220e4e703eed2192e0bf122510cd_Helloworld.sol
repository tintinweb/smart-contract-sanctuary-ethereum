/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Helloworld {
    string text = "Hola perri!!";

    function getString() public view returns (string memory) {
        return text;
    }

    function setString(string memory _text) public {
        text = _text;
    }
}