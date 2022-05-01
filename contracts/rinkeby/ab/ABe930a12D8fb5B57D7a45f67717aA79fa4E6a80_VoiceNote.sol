/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VoiceNote {

    string message;

    function store(string memory _message) public returns (bool) {
        message = _message;
        
        return true;
    }

    function retrieve() public view returns (string memory) {
        return message;
    }
}