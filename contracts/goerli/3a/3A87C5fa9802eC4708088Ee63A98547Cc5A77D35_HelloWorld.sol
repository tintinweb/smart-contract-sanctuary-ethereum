//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract HelloWorld {

    uint256 public s;

    constructor(uint256 _s) {
        s = _s;
    }

    function set(uint256 _s) public {
        s = _s;
    }
}