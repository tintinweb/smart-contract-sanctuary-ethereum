// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.26;
contract Test {
    uint public counter = 0;
    function A() public returns (uint256) {
        counter++;
        return counter;
    }

    function B() public view returns (uint256) {
        A();
        return 0;
    }
}