//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    function sub(uint64 _a, uint64 _i) public pure returns (uint8) {
        return uint8(_a / _i);
    }
}