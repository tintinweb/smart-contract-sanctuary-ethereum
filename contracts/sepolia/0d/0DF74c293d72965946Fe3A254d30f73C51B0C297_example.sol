/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract example {

    struct S {
        uint256 number;
        bytes32 bt;
    }

    S internal _s;

    constructor() {
        _s = S(12312321213, hex'dc4975c59cf834d33e9f94bb72ede36f80c22522101175ffe61af06791f0332f');
    }

    function getManyReturn() public view returns (S memory s, bool b) {
        s = _s;
        b = true;
    }
}