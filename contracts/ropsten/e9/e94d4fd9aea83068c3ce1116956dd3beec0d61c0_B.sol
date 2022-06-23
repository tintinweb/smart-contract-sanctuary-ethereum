/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.14;

contract A {
}

contract B {
    bytes code;
    constructor() {
        code = type(A).creationCode;
    }
}