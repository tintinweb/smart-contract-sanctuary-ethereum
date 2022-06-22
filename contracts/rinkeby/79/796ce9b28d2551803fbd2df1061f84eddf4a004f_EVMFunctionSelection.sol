/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

contract EVMFunctionSelection {

    uint timesCalled;

    // function selector is c744c486
    function addOne(uint _a) public returns (uint) {
        timesCalled++;
        return _a + 1;
    }

    // function selector is bae98e5a
    function addOne(uint8 _a) public returns (uint8) {
        timesCalled++;
        return _a + uint8(1);
    }

}