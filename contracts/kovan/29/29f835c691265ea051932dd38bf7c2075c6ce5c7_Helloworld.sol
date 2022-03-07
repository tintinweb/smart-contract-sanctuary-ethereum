/**
 *Submitted for verification at Etherscan.io on 2022-03-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract Helloworld {

    string lastText = "Hello";

    function getString() public view returns(string memory) {
        return lastText;
    }

    function setString(string memory text) public {
        lastText = text;
    }
}