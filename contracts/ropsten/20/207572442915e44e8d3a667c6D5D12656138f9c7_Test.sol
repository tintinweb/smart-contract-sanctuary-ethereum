/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Test {
    constructor() public{

    }

    function print () public pure returns ( string memory) {       
        return 'Hello World! First Simple Smart Contract';             
    }

    function add (int a, int b) public pure returns (int) {
        return a + b;
    }
}