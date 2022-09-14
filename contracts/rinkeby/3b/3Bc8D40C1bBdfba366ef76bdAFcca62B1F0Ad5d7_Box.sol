// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


//Box deployed at addre: 0x766aEd4025571C69D561958911C2F8FCFa71c76b
contract Box {
    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }
}