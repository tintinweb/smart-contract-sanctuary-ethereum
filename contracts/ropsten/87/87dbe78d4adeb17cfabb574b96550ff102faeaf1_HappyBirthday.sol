/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract HappyBirthday {
    string text;

    constructor() {
        text = "Nothing yet - input a name";
    }

    function askForName(string memory _text) public returns (string memory) {
        if (keccak256(bytes(_text)) == keccak256("EJ")) {
            text = "HAPPY BIRTHDAY EJ!!";
        } 
        else {
            text = string(abi.encodePacked("idk you ", _text));
        }
        
        return text;
    }

    function readMessage() public view returns (string memory) {
        return text;
    }


}