// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract GasBreak {

    uint256 uint1;
    uint256 uint2;
    uint256 uint3;

    function breakGasEstimate() public {

        uint1 += 1;
        uint2 += 1;
        uint3 += 1;

        uint1 -= 1;
        uint2 -= 2;
        uint3 -= 3;
    }
}