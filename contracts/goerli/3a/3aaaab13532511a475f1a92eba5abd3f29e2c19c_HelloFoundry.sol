// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract HelloFoundry {
    uint256 public number;
    string private _hello;
    bool public _isYes;

    function isYes() public view returns (bool) {
        return _isYes;
    }
    function getHello() public view returns( string memory ) {
        return _hello;
    }

    function setHello( string memory str ) public {
        _hello = str;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}