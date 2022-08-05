/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Contract {

    string private text;

    constructor(string memory initialText) {
        text = initialText;
    }

    // returning the current message
    function speak() public view returns (string memory) {
        return text;
    }

    // changing the message
    function changeText(string memory newText) public {
        text = newText;
    }
}