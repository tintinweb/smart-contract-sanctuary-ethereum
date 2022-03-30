// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract GasBreak {

    uint256 public uint1 = 0;
    uint256 public uint2 = 10;

    function breakGasEstimate() public {

        uint256 path = uint256(keccak256(abi.encodePacked(block.difficulty, tx.gasprice))) % 2;

        if (path == 0) {
            uint1 += 1;
            uint1 -= 1;
        } else {
            uint2 += 1;
            uint2 -= 1;
        }
    }
}