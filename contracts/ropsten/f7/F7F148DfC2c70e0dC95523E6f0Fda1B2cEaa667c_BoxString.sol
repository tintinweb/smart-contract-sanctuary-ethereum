//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;


contract BoxString{

    string value = "A";

    function getValue() public view returns (string memory) {
        return value;
    }

    function setValue(string memory _value) public{
        value = _value;
    }

}