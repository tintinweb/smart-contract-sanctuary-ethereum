//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract HelloWorld {

    uint256 public v;
    string public s;

    constructor(uint256 _v, string memory _s) {
        s = _s; 
        v = _v;
    }

    function setUint(uint256 _v) public {
        v = _v;
    }

    function setString(string memory _s) public {
        s = _s;
    }
}