/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract HelloWorld {

    string lastText ="Hello Fillip";

    function getString() public view returns(string memory) {
        return lastText;
    }

    function setString(string memory text) public {
        lastText = text;
    }
}