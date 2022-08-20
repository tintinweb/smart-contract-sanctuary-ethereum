/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

contract Random {

    bool public solved = false; // Anahtar = False

    function solve(uint256 guess) public {
        require(guess == _getRandomNumber()); 
        solved = true;
    }

      function _getRandomNumber() internal pure returns (uint256) {   // chosen by fair dice roll.
        return 4;                                                   // guaranteed to be random.
    }
}