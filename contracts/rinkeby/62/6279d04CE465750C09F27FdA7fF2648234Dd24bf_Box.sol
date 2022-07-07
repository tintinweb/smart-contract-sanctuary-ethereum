//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract Box {
    uint public val;
    bool private initialized;

    function initialize(uint _val) external {
        require(!initialized, "Contract has already beed initialized!");
        initialized = true;
        val = _val;
    }
}