/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract dcTest33 {
    uint256 public data;
    string public text;

    constructor(uint256 _data, string memory _text) {
        data = _data;
        text = _text;
    }

    function setData(uint256 _data) public {
        data = _data;
    }

    function setText(string memory _text) public {
        text = _text;
    }
}