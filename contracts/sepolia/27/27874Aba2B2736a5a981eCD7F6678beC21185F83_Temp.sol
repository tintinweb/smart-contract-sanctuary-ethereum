/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Temp {
    mapping(address => string[]) public texts;
    
    function getTexts() public view returns(string[] memory) {
        return texts[msg.sender];
    }

    function addText(string memory _text) public {
        texts[msg.sender].push(_text);
    }
}