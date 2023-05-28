// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {

    string public myString = "Ethereum";

    function setMyString(string calldata _input) public {
        myString = _input;
    }

}