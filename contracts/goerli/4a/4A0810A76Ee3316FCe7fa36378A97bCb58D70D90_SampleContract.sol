// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SampleContract {
    uint256 public myInt = 13;
    string public myData;
    bool public isEnabled;

    constructor () {
        myData = "hello";
        isEnabled = true;
    }

    function toggle() public {
        isEnabled = !isEnabled;
    }

    function setData(string memory _input) public {
        myData = _input;
    }
}