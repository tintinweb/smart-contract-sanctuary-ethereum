/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/HelloWorld.sol


pragma solidity ^0.8.10;

contract Helloworld {
    string public state;

    function setMessage(string memory _message) public {
        state = _message;
    }

    function viewMessage() public view returns(string memory) {
        return state;
    }
}