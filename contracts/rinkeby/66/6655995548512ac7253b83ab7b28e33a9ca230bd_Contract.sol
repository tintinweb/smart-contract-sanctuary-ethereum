/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Contract {
    string private text;

    constructor(string memory initialText) {
        text = initialText;
    }

    function speak() public view returns (string memory) {
        return text;
    }

    function changeText(string memory newText) public {
        text = newText;
    }
}