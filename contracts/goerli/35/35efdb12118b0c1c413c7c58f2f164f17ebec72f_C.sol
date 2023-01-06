/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract BInterface {
    function ca(uint x) virtual external returns (uint);

    function getValue() virtual public view returns (uint);
}


contract C {
    BInterface public b;

    constructor(BInterface _b){
        b = _b;
    }

    function setValue(uint num) external returns (uint){
        return b.ca(num);
    }

    function getValue() public view returns (uint){
        return b.getValue();
    }
}