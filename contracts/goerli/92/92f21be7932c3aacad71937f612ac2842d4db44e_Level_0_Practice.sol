// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface Isolution {
    function solution() external pure returns (uint8  anwser);
}

contract Level_0_Practice {

	uint8 answer;

	constructor() {
        answer = 42;
    }

    function completeLevel(address studentAddress) public returns(uint8) {
        uint8 n = Isolution(studentAddress).solution();
        if (n == answer) {
            return 2;
        } else {
            return 1;
        }
    }
}