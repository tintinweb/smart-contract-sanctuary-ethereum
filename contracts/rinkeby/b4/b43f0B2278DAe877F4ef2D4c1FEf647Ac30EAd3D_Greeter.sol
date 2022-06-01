//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string public simpleStorage;

    function setStorage(string memory _value) public {
        simpleStorage = _value;
    }
}