/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Contract {
    function test() external {

    }
}

contract Contract2 is Contract {
    function hello() external {
        this.test();
    }
}