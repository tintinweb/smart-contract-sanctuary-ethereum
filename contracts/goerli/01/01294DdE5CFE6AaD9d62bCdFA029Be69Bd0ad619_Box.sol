// SPDX-License-Idenitifer: MIT

pragma solidity ^0.8.0;

contract Box {
    uint256 private value;

    event ValueChanged(uint256 newVal);

    function store(uint256 _val) public {
        value = _val;
        emit ValueChanged(_val);
    }

    function retrieve() view public returns(uint256) {
        return value;
    }

}