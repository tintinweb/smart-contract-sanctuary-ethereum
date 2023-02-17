/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Foo {
    function foo() external pure returns (uint256) {
        return 123;
    }    
}

contract Factory {
    function deploy() external {
        new Foo();
    }
}