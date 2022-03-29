// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract GasBreak {

    uint256 uint1;
    uint256 uint2;
    uint256 uint3;

    function breakGasEstimate() public {

        ++uint1;
        ++uint2;
        ++uint3;

        --uint1;
        --uint2;
        --uint3;
    }
}