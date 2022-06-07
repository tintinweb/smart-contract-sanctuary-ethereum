/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract WrittingOnTheBlockchain {
    string text;

    function Write ( string calldata _text) public {
        text = _text;
    }

    function Read() public view returns (string memory) {
        return text;
    }
}