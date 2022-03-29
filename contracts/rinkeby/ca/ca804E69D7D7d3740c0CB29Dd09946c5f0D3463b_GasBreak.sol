// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GasBreak {

    uint256 public counter;
    mapping(uint256 => uint256) public counterMap;

    function breakMM() public {
        counter++;
        uint256 pick = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, counter))) % 2;
        if (pick == 0) {
            counterMap[0] += 1;
        } else {
            counterMap[counter] += 1;
        }
    }
}