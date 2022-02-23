/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;
contract ContractB {
    uint b;

    constructor(uint256 _b) {
        b = _b;
    }

    function getB() view external returns (uint256) {
        return b + 1;
    }
}
contract ContractA is ContractB {
    uint a;

    constructor(uint256 _a) ContractB(50) {
        a = _a;
    }

    function getA() view external returns (uint256) {
        return a + 1;
    }
}