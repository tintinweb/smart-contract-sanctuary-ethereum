/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract LoadTest  {

    uint256 internal GUARD = 1;

    modifier guard() {
        uint g = gasleft();
        uint i = GUARD;
        require(g - gasleft() > 1000);
        _;
    }

    function protectedFunction() guard public {

    }

    function testPass() public {
        protectedFunction();
    }

    function testFail() public {
        protectedFunction();
        protectedFunction();
    }
}